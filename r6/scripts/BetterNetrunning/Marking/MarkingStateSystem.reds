

module BetterNetrunning.Marking

import BetterNetrunning.Logging.*
import BetterNetrunning.Core.*
import BetterNetrunning.Network.*
import BetterNetrunning.Perks.*

@if(ModuleExists("DarkFuture.Needs"))
import DarkFuture.Needs.{DFNerveSystem, DFChangeNeedValueProps}

public struct MarkEntry {
  public let entityID:          EntityID;
  public let creationTimestamp: Float;   // TimeSystem.GetGameTimeStamp() at mark time
  public let displayName:       String;  // localized entity name, captured at first diagnostic
  public let iceHitsRequired:   Int32;   // stamped by first diagnostic (Ping/jack-in/breach); 0 = unscanned
}

public enum MarkedSubnetType {
  Root     = 0,   // Basic devices: doors, terminals, vending, etc.
  NPC      = 1,   // Human targets (UnlockNPCQuickhacks)
  Camera   = 2,   // Surveillance cameras (UnlockCameraQuickhacks)
  Defense  = 3    // Security turrets (UnlockTurretQuickhacks)
}

public class MarkingStateSystem extends ScriptableSystem {

  private let m_markedRoot:    array<MarkEntry>;
  private let m_markedNPCs:    array<MarkEntry>;
  private let m_markedCameras: array<MarkEntry>;
  private let m_markedDefense: array<MarkEntry>;

  private let m_sessionHeat: Float;

  private let m_hidePresenceTimer: Float;
  private let m_disarmICETimer: Float;
  private let m_signalNoiseTimer: Float;

  private let m_heatICEBonus:  Int32;
  private let m_lastHeatBand:  Int32; // highest band reached so far (0-5)

  private let m_apBreachFinalizing: Bool;

  private func OnAttach() -> Void {
    ArrayClear(this.m_markedRoot);
    ArrayClear(this.m_markedNPCs);
    ArrayClear(this.m_markedCameras);
    ArrayClear(this.m_markedDefense);
    this.m_sessionHeat          = 0.0;
    this.m_hidePresenceTimer     = 0.0;
    this.m_disarmICETimer        = 0.0;
    this.m_signalNoiseTimer      = 0.0;
    this.m_heatICEBonus          = 0;
    this.m_lastHeatBand          = 0;
    this.m_lastBreachTargetType  = "device";
  }

  
  private func GetMarkDurationSeconds() -> Float {
    let gi: GameInstance = this.GetGameInstance();
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
    let player: ref<PlayerPuppet> = GetPlayer(gi);

    if !IsDefined(statsSystem) || !IsDefined(player) {
      return 180.0; // Safe fallback: 3 minutes
    }

    let intelligence: Float = statsSystem.GetStatValue(
      Cast<StatsObjectID>(player.GetEntityID()),
      gamedataStatType.Intelligence
    );

    if intelligence < 3.0 { intelligence = 3.0; }

    return intelligence * 60.0;
  }

  
  private func GetMaxMarks() -> Int32 {
    let gi: GameInstance              = this.GetGameInstance();
    let player: ref<PlayerPuppet>     = GetPlayer(gi);
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
    if !IsDefined(player) || !IsDefined(statsSystem) { return 3; }

    let maxRAM: Float = statsSystem.GetStatValue(
      Cast<StatsObjectID>(player.GetEntityID()),
      gamedataStatType.Memory
    );
    let baseMarks: Int32 = Cast<Int32>(maxRAM) / 3;

    let perkSys: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gi);
    let trackLevel: Int32 = IsDefined(perkSys) ? perkSys.GetPerkLevel(BNPerk.TrackingProtocol) : 0;
    let perkBonus: Int32;
    if      trackLevel >= 3 { perkBonus = 5; }
    else if trackLevel == 2 { perkBonus = 3; }
    else if trackLevel == 1 { perkBonus = 1; }
    else                    { perkBonus = 0; }

    return Max(1, baseMarks) + perkBonus;
  }

  
  private func GetCurrentTimestamp() -> Float {
    let gi: GameInstance = this.GetGameInstance();
    let timeSystem: ref<TimeSystem> = GameInstance.GetTimeSystem(gi);
    if !IsDefined(timeSystem) { return 0.0; }
    return timeSystem.GetGameTimeStamp();
  }

  
  private func IsExpired(entry: MarkEntry, currentTime: Float, duration: Float) -> Bool {
    if entry.creationTimestamp <= 0.0 { return false; } // 0 = never decays (legacy)
    return (currentTime - entry.creationTimestamp) > duration;
  }

  public func SetApBreachFinalizing(v: Bool) -> Void { this.m_apBreachFinalizing = v; }
  public func IsApBreachFinalizing() -> Bool { return this.m_apBreachFinalizing; }

  public func IsAPBreachActive() -> Bool {
    let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGameInstance())
      .Get(GetAllBlackboardDefs().HackingMinigame);
    if !IsDefined(bb) { return false; }
    return Equals(
      IntEnum<HackingMinigameState>(bb.GetInt(GetAllBlackboardDefs().HackingMinigame.State)),
      HackingMinigameState.InProgress
    );
  }

  public func GetSessionHeat() -> Float { return this.m_sessionHeat; }

  public func AddSessionHeat(delta: Float) -> Void {

    if delta > 0.0 && this.m_hidePresenceTimer > 0.0 { return; }
    let wasMaxed = this.m_sessionHeat >= 1.0;
    this.m_sessionHeat += delta;
    if this.m_sessionHeat < 0.0 { this.m_sessionHeat = 0.0; }
    if this.m_sessionHeat > 1.0 { this.m_sessionHeat = 1.0; }
    if !wasMaxed && this.m_sessionHeat >= 1.0 { this.ReduceNerve(8.0); }

    let newBand: Int32 = MarkingStateSystem.HeatBand(this.m_sessionHeat);
    if newBand > this.m_lastHeatBand {
      this.m_lastHeatBand = newBand;
      let rolled: Int32 = MarkingStateSystem.RollBonusForBand(newBand);
      if rolled > this.m_heatICEBonus {
        this.m_heatICEBonus = rolled;
        BNInfo("MarkingState", "Heat band " + ToString(newBand)
          + " — ICE bonus raised to +" + ToString(this.m_heatICEBonus));
      } else {
        BNInfo("MarkingState", "Heat band " + ToString(newBand)
          + " — rolled " + ToString(rolled) + ", keeping current bonus +"
          + ToString(this.m_heatICEBonus));
      }
    }
  }

  public func GetHeatICEBonus() -> Int32 { return this.m_heatICEBonus; }

  private static func HeatBand(heat: Float) -> Int32 {
    if heat >= 0.95 { return 5; }
    if heat >= 0.80 { return 4; }
    if heat >= 0.60 { return 3; }
    if heat >= 0.40 { return 2; }
    if heat >= 0.20 { return 1; }
    return 0;
  }

  private static func RollBonusForBand(band: Int32) -> Int32 {
    if band == 5 { return RandRange(8, 11); } // 8-10
    if band == 4 { return RandRange(7, 10); } // 7-9
    if band == 3 { return RandRange(6,  9); } // 6-8  ← Critical
    if band == 2 { return RandRange(2,  5); } // 2-4
    if band == 1 { return RandRange(1,  4); } // 1-3
    return 0;
  }

  @if(ModuleExists("DarkFuture.Needs"))
  private func ReduceNerve(amount: Float) -> Void {
    let sys = DFNerveSystem.Get();
    if IsDefined(sys) { sys.ChangeNeedValue(-amount); };
  }

  @if(!ModuleExists("DarkFuture.Needs"))
  private func ReduceNerve(amount: Float) -> Void {}

  public func GetHidePresenceTimer() -> Float { return this.m_hidePresenceTimer; }
  public func SetHidePresenceTimer(t: Float) -> Void {
    this.m_hidePresenceTimer = t > 0.0 ? t : 0.0;
  }

  public func GetDisarmICETimer() -> Float { return this.m_disarmICETimer; }
  public func SetDisarmICETimer(t: Float) -> Void {
    this.m_disarmICETimer = t > 0.0 ? t : 0.0;
  }

  public func GetSignalNoiseTimer() -> Float { return this.m_signalNoiseTimer; }
  public func SetSignalNoiseTimer(t: Float) -> Void {
    this.m_signalNoiseTimer = t > 0.0 ? t : 0.0;
  }

  private let m_debugLastICERequired: Int32;
  private let m_debugLastICEApplied:  Int32;
  private let m_debugLastDeviceName:  String;

  private let m_lastBreachTargetType: String;

  public func RecordBreachICEState(required: Int32, applied: Int32) -> Void {
    this.m_debugLastICERequired = required;
    this.m_debugLastICEApplied  = applied;

    let logSys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGameInstance())
        .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
    if IsDefined(logSys) { logSys.Refresh(); }
  }

  public func RecordBreachDeviceName(name: String) -> Void {
    this.m_debugLastDeviceName = name;
  }

  public func RecordRemoteBreachTarget(name: String, targetType: String) -> Void {
    this.m_debugLastDeviceName  = name;
    this.m_lastBreachTargetType = targetType;
  }

  public func ShowRemoteBreachStatus() -> Void {}

  public func ShowPropagationResult(unlockedNames: array<String>, failedCount: Int32) -> Void {}

  public func GetEquippedCyberdeckName() -> String {
    let gi: GameInstance = this.GetGameInstance();
    let player: ref<PlayerPuppet> = GetPlayer(gi);
    if !IsDefined(player) { return s"CYBERDECK"; }
    let equipSys: ref<EquipmentSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(n"EquipmentSystem") as EquipmentSystem;
    if !IsDefined(equipSys) { return s"CYBERDECK"; }
    let playerData: ref<EquipmentSystemPlayerData> = equipSys.GetPlayerData(player);
    if !IsDefined(playerData) { return s"CYBERDECK"; }
    let deckID: ItemID = playerData.GetActiveItem(gamedataEquipmentArea.SystemReplacementCW);
    if !ItemID.IsValid(deckID) { return s"CYBERDECK"; }
    let record: ref<Item_Record> = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(deckID));
    if !IsDefined(record) { return s"CYBERDECK"; }
    return GetLocalizedTextByKey(record.DisplayName());
  }

  public func GetDebugICEString() -> String {
    if this.m_debugLastICERequired <= 0 {
      return "ICE: not initialized";
    }
    let status: String = this.m_debugLastICEApplied >= this.m_debugLastICERequired
      ? " [BROKEN]" : " [INTACT]";
    return "ICE: " + ToString(this.m_debugLastICEApplied)
      + "/" + ToString(this.m_debugLastICERequired) + status;
  }

  
  public func PruneExpiredMarks() -> Int32 {
    let currentTime: Float = this.GetCurrentTimestamp();
    let duration: Float    = this.GetMarkDurationSeconds();
    let removed: Int32     = 0;
    removed += this.PruneArray(this.m_markedRoot,    currentTime, duration);
    removed += this.PruneArray(this.m_markedNPCs,    currentTime, duration);
    removed += this.PruneArray(this.m_markedCameras, currentTime, duration);
    removed += this.PruneArray(this.m_markedDefense, currentTime, duration);
    return removed;
  }

  public func PruneExpiredMarksWithHeat(maxHeat: Float) -> Int32 {
    return this.PruneExpiredMarks();
  }

  
  public func GetOldestMarkRemainingSeconds() -> Float {
    let currentTime: Float = this.GetCurrentTimestamp();
    let duration: Float    = this.GetMarkDurationSeconds();
    let oldest: Float      = -1.0;

    oldest = this.GetOldestRemaining(this.m_markedRoot,    currentTime, duration, oldest);
    oldest = this.GetOldestRemaining(this.m_markedNPCs,    currentTime, duration, oldest);
    oldest = this.GetOldestRemaining(this.m_markedCameras, currentTime, duration, oldest);
    oldest = this.GetOldestRemaining(this.m_markedDefense, currentTime, duration, oldest);

    return oldest;
  }

  
  public func GetMarkDurationSecondsPublic() -> Float {
    return this.GetMarkDurationSeconds();
  }

  
  public func AddMark(entityID: EntityID, subnetType: MarkedSubnetType) -> Void {
    let maxMarks: Int32 = this.GetMaxMarks();
    if !this.ContainsInAny(entityID) && this.GetTotalCount() >= maxMarks {
      BNInfo("MarkingSystem", "Mark limit (" + ToString(maxMarks) + ") reached — new mark ignored");
      return;
    }
    let entry: MarkEntry;
    entry.entityID          = entityID;
    entry.creationTimestamp = this.GetCurrentTimestamp();

    if Equals(subnetType, MarkedSubnetType.Root) {
      if !this.ContainsID(this.m_markedRoot, entityID) {
        ArrayPush(this.m_markedRoot, entry);
        BNDebug("MarkingSystem", "Marked Root:    " + EntityID.ToDebugString(entityID));
      } else {
        this.RefreshTimestamp(this.m_markedRoot, entityID, entry.creationTimestamp);
      }
    } else if Equals(subnetType, MarkedSubnetType.NPC) {
      if !this.ContainsID(this.m_markedNPCs, entityID) {
        ArrayPush(this.m_markedNPCs, entry);
        BNDebug("MarkingSystem", "Marked NPC:     " + EntityID.ToDebugString(entityID));
      } else {
        this.RefreshTimestamp(this.m_markedNPCs, entityID, entry.creationTimestamp);
      }
    } else if Equals(subnetType, MarkedSubnetType.Camera) {
      if !this.ContainsID(this.m_markedCameras, entityID) {
        ArrayPush(this.m_markedCameras, entry);
        BNDebug("MarkingSystem", "Marked Camera:  " + EntityID.ToDebugString(entityID));
      } else {
        this.RefreshTimestamp(this.m_markedCameras, entityID, entry.creationTimestamp);
      }
    } else if Equals(subnetType, MarkedSubnetType.Defense) {
      if !this.ContainsID(this.m_markedDefense, entityID) {
        ArrayPush(this.m_markedDefense, entry);
        BNDebug("MarkingSystem", "Marked Defense: " + EntityID.ToDebugString(entityID));
      } else {
        this.RefreshTimestamp(this.m_markedDefense, entityID, entry.creationTimestamp);
      }
    }
  }

  
  public func AddMarkNamed(entityID: EntityID, subnetType: MarkedSubnetType, displayName: String, iceHitsRequired: Int32) -> Void {
    let maxMarks: Int32 = this.GetMaxMarks();
    if !this.ContainsInAny(entityID) && this.GetTotalCount() >= maxMarks {
      BNInfo("MarkingSystem", "Mark limit (" + ToString(maxMarks) + ") reached — " + displayName + " not added");
      return;
    }
    let entry: MarkEntry;
    entry.entityID          = entityID;
    entry.creationTimestamp = this.GetCurrentTimestamp();
    entry.displayName       = displayName;
    entry.iceHitsRequired   = iceHitsRequired;

    if Equals(subnetType, MarkedSubnetType.Root) {
      if !this.ContainsID(this.m_markedRoot, entityID) {
        ArrayPush(this.m_markedRoot, entry);
        BNDebug("MarkingSystem", "Root marked: " + displayName + " ICE=" + ToString(iceHitsRequired));
      } else {
        this.RefreshTimestamp(this.m_markedRoot, entityID, entry.creationTimestamp);
      }
    } else if Equals(subnetType, MarkedSubnetType.NPC) {
      if !this.ContainsID(this.m_markedNPCs, entityID) {
        ArrayPush(this.m_markedNPCs, entry);
        BNDebug("MarkingSystem", "NPC marked: " + displayName + " ICE=" + ToString(iceHitsRequired));
      } else {
        this.RefreshTimestamp(this.m_markedNPCs, entityID, entry.creationTimestamp);
      }
    } else if Equals(subnetType, MarkedSubnetType.Camera) {
      if !this.ContainsID(this.m_markedCameras, entityID) {
        ArrayPush(this.m_markedCameras, entry);
        BNDebug("MarkingSystem", "Camera marked: " + displayName + " ICE=" + ToString(iceHitsRequired));
      } else {
        this.RefreshTimestamp(this.m_markedCameras, entityID, entry.creationTimestamp);
      }
    } else if Equals(subnetType, MarkedSubnetType.Defense) {
      if !this.ContainsID(this.m_markedDefense, entityID) {
        ArrayPush(this.m_markedDefense, entry);
        BNDebug("MarkingSystem", "Defense marked: " + displayName + " ICE=" + ToString(iceHitsRequired));
      } else {
        this.RefreshTimestamp(this.m_markedDefense, entityID, entry.creationTimestamp);
      }
    }
  }

  
  public func AddMarkFromEntity(entityID: EntityID, subnetType: MarkedSubnetType) -> Void {
    let gi: GameInstance = this.GetGameInstance();
    let entity: ref<GameObject> = GameInstance.FindEntityByID(gi, entityID) as GameObject;
    if !IsDefined(entity) { this.AddMark(entityID, subnetType); return; }

    let displayName: String     = GetLocalizedText(entity.GetDisplayName());
    let iceHitsRequired: Int32  = 0;

    let vehicle: ref<VehicleObject> = entity as VehicleObject;
    if IsDefined(vehicle) {
      let sharedPS: ref<SharedGameplayPS> = vehicle.GetVehiclePS() as SharedGameplayPS;
      if IsDefined(sharedPS) {
        if sharedPS.m_bnIceHitsRequired == 0 {
          sharedPS.m_bnIceHitsRequired = NetworkStateUtils.GetHeatScaledICEHits(gi);
        }
        iceHitsRequired = sharedPS.m_bnIceHitsRequired;
      }
      if Equals(displayName, s"") { displayName = s"VEHICLE"; }
    } else {
      let device: ref<Device> = entity as Device;
      if IsDefined(device) {
        let ps: ref<ScriptableDeviceComponentPS> = device.GetDevicePS();
        if IsDefined(ps) {
          if ps.m_bnIceHitsRequired == 0 {
            ps.m_bnIceHitsRequired = NetworkStateUtils.GetHeatScaledICEHits(gi);
          }
          iceHitsRequired = ps.m_bnIceHitsRequired;
        }
        if Equals(displayName, s"") {
          displayName = DeviceTypeUtils.DeviceTypeToString(DeviceTypeUtils.GetDeviceTypeFromEntity(device));
        }
      } else {
        let puppet: ref<ScriptedPuppet> = entity as ScriptedPuppet;
        if IsDefined(puppet) {
          let npcPS: ref<ScriptedPuppetPS> = puppet.GetPuppetPS() as ScriptedPuppetPS;
          if IsDefined(npcPS) {
            if npcPS.m_bnNPCIceHitsRequired == 0 {
              npcPS.m_bnNPCIceHitsRequired = NetworkStateUtils.GetHeatScaledICEHits(gi);
            }
            iceHitsRequired = npcPS.m_bnNPCIceHitsRequired;
          }
          if Equals(displayName, s"") { displayName = s"PERSONNEL"; }
        }
      }
    }

    this.AddMarkNamed(entityID, subnetType, displayName, iceHitsRequired);
  }

  
  public func RemoveMark(entityID: EntityID, subnetType: MarkedSubnetType) -> Void {
    if Equals(subnetType, MarkedSubnetType.Root)    { this.RemoveID(this.m_markedRoot,    entityID); }
    if Equals(subnetType, MarkedSubnetType.NPC)     { this.RemoveID(this.m_markedNPCs,    entityID); }
    if Equals(subnetType, MarkedSubnetType.Camera)  { this.RemoveID(this.m_markedCameras, entityID); }
    if Equals(subnetType, MarkedSubnetType.Defense) { this.RemoveID(this.m_markedDefense, entityID); }
  }

  
  public func RemoveMarkAny(entityID: EntityID) -> Void {
    this.RemoveID(this.m_markedRoot,    entityID);
    this.RemoveID(this.m_markedNPCs,    entityID);
    this.RemoveID(this.m_markedCameras, entityID);
    this.RemoveID(this.m_markedDefense, entityID);
  }

  public func IsMark(entityID: EntityID, subnetType: MarkedSubnetType) -> Bool {
    if Equals(subnetType, MarkedSubnetType.Root)    { return this.ContainsID(this.m_markedRoot,    entityID); }
    if Equals(subnetType, MarkedSubnetType.NPC)     { return this.ContainsID(this.m_markedNPCs,    entityID); }
    if Equals(subnetType, MarkedSubnetType.Camera)  { return this.ContainsID(this.m_markedCameras, entityID); }
    if Equals(subnetType, MarkedSubnetType.Defense) { return this.ContainsID(this.m_markedDefense, entityID); }
    return false;
  }

  public func HasMarkedRoot()    -> Bool { return ArraySize(this.m_markedRoot)    > 0; }
  public func HasMarkedNPCs()    -> Bool { return ArraySize(this.m_markedNPCs)    > 0; }
  public func HasMarkedCameras() -> Bool { return ArraySize(this.m_markedCameras) > 0; }
  public func HasMarkedDefense() -> Bool { return ArraySize(this.m_markedDefense) > 0; }

  public func HasAnyMarked() -> Bool {
    return this.HasMarkedRoot()
        || this.HasMarkedNPCs()
        || this.HasMarkedCameras()
        || this.HasMarkedDefense();
  }

  public func GetMarkedRootCount()    -> Int32 { return ArraySize(this.m_markedRoot); }
  public func GetMarkedNPCCount()     -> Int32 { return ArraySize(this.m_markedNPCs); }
  public func GetMarkedCameraCount()  -> Int32 { return ArraySize(this.m_markedCameras); }
  public func GetMarkedDefenseCount() -> Int32 { return ArraySize(this.m_markedDefense); }

  public func GetTotalCount() -> Int32 {
    return ArraySize(this.m_markedRoot)
        + ArraySize(this.m_markedNPCs)
        + ArraySize(this.m_markedCameras)
        + ArraySize(this.m_markedDefense);
  }

  public func GetMarkedRootEntries()    -> array<MarkEntry> { return this.m_markedRoot; }
  public func GetMarkedNPCEntries()     -> array<MarkEntry> { return this.m_markedNPCs; }
  public func GetMarkedCameraEntries()  -> array<MarkEntry> { return this.m_markedCameras; }
  public func GetMarkedDefenseEntries() -> array<MarkEntry> { return this.m_markedDefense; }

  public func GetMarkedRoot() -> array<EntityID> {
    return this.ExtractIDs(this.m_markedRoot);
  }
  public func GetMarkedNPCs() -> array<EntityID> {
    return this.ExtractIDs(this.m_markedNPCs);
  }
  public func GetMarkedCameras() -> array<EntityID> {
    return this.ExtractIDs(this.m_markedCameras);
  }
  public func GetMarkedDefense() -> array<EntityID> {
    return this.ExtractIDs(this.m_markedDefense);
  }

  public func ClearAll() -> Void {
    ArrayClear(this.m_markedRoot);
    ArrayClear(this.m_markedNPCs);
    ArrayClear(this.m_markedCameras);
    ArrayClear(this.m_markedDefense);
    BNInfo("MarkingSystem", "All breach marks cleared");
  }

  public func ClearType(subnetType: MarkedSubnetType) -> Void {
    if Equals(subnetType, MarkedSubnetType.Root)    { ArrayClear(this.m_markedRoot); }
    if Equals(subnetType, MarkedSubnetType.NPC)     { ArrayClear(this.m_markedNPCs); }
    if Equals(subnetType, MarkedSubnetType.Camera)  { ArrayClear(this.m_markedCameras); }
    if Equals(subnetType, MarkedSubnetType.Defense) { ArrayClear(this.m_markedDefense); }
  }

  private func RaiseMarkHeat(entityID: EntityID) -> Void {
    let gi: GameInstance = this.GetGameInstance();
    let entity: ref<Entity> = GameInstance.FindEntityByID(gi, entityID);
    let device: ref<Device> = entity as Device;
    if IsDefined(device) {
      let devicePS: ref<ScriptableDeviceComponentPS> = device.GetDevicePS();
      if IsDefined(devicePS) {
        NetworkStateUtils.OnEntityMarked(devicePS, gi);
      }
    }
  }

  private func ContainsInAny(entityID: EntityID) -> Bool {
    return this.ContainsID(this.m_markedRoot,    entityID)
        || this.ContainsID(this.m_markedNPCs,    entityID)
        || this.ContainsID(this.m_markedCameras, entityID)
        || this.ContainsID(this.m_markedDefense, entityID);
  }

  private func ContainsID(arr: array<MarkEntry>, entityID: EntityID) -> Bool {
    let i: Int32 = 0;
    while i < ArraySize(arr) {
      if Equals(arr[i].entityID, entityID) { return true; }
      i += 1;
    }
    return false;
  }

  private func RemoveID(arr: script_ref<array<MarkEntry>>, entityID: EntityID) -> Void {
    let i: Int32 = ArraySize(Deref(arr)) - 1;
    while i >= 0 {
      if Equals(Deref(arr)[i].entityID, entityID) {
        ArrayErase(Deref(arr), i);
      }
      i -= 1;
    }
  }

  private func RefreshTimestamp(arr: script_ref<array<MarkEntry>>, entityID: EntityID, newTimestamp: Float) -> Void {
    let i: Int32 = 0;
    while i < ArraySize(Deref(arr)) {
      if Equals(Deref(arr)[i].entityID, entityID) {
        Deref(arr)[i].creationTimestamp = newTimestamp;
        return;
      }
      i += 1;
    }
  }

  private func PruneArray(arr: script_ref<array<MarkEntry>>, currentTime: Float, duration: Float) -> Int32 {
    let removed: Int32 = 0;
    let i: Int32 = ArraySize(Deref(arr)) - 1;
    while i >= 0 {
      if this.IsExpired(Deref(arr)[i], currentTime, duration) {
        BNDebug("MarkDecay",
          "Mark expired: " + EntityID.ToDebugString(Deref(arr)[i].entityID));
        ArrayErase(Deref(arr), i);
        removed += 1;
      }
      i -= 1;
    }
    return removed;
  }

  private func GetOldestRemaining(
    arr: array<MarkEntry>,
    currentTime: Float,
    duration: Float,
    currentOldest: Float
  ) -> Float {
    let i: Int32 = 0;
    while i < ArraySize(arr) {
      let elapsed: Float   = currentTime - arr[i].creationTimestamp;
      let remaining: Float = duration - elapsed;
      if remaining < 0.0 { remaining = 0.0; }

      if currentOldest < 0.0 || remaining < currentOldest {
        currentOldest = remaining;
      }
      i += 1;
    }
    return currentOldest;
  }

  private func ExtractIDs(arr: array<MarkEntry>) -> array<EntityID> {
    let ids: array<EntityID>;
    let i: Int32 = 0;
    while i < ArraySize(arr) {
      ArrayPush(ids, arr[i].entityID);
      i += 1;
    }
    return ids;
  }
}

