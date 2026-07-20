

module BetterNetrunning.Marking

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Network.*
import BetterNetrunning.Utils.*

@if(ModuleExists("HackingExtensions"))
import HackingExtensions.*

@if(ModuleExists("HackingExtensions"))
public class BNMarkNPCAction extends CustomAccessBreach {
  private let m_npcPS:   ref<ScriptedPuppetPS>;
  private let m_ramCost: Int32;

  public func SetNPC(npcPS: ref<ScriptedPuppetPS>, ramCost: Int32) -> Void {
    this.m_npcPS   = npcPS;
    this.m_ramCost = ramCost;
  }

  public func GetTweakDBChoiceRecord() -> String { return "BNMarkNPC"; }
  public func GetCost() -> Int32 { return this.m_ramCost; }

  public func CanPayCost(opt user: ref<GameObject>, opt checkOverclock: Bool) -> Bool {
    let executor: ref<GameObject>;
    if IsDefined(user) { executor = user; } else { executor = this.GetExecutor(); }
    if !IsDefined(executor) { return false; }
    let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(executor.GetGame());
    let ram: Float = pool.GetStatPoolValue(Cast<StatsObjectID>(executor.GetEntityID()), gamedataStatPoolType.Memory, false);
    return ram >= Cast<Float>(this.m_ramCost);
  }

  public func PayCost(opt checkOverclock: Bool) -> Bool { return true; }

  private func CompleteAction(gameInstance: GameInstance) -> Void {
    if !IsDefined(this.m_npcPS) {
      BNError("NetworkScan", "BNMarkNPCAction: no NPC PS");
      return;
    }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if !IsDefined(mss) { return; }

    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
    if IsDefined(player) && this.m_ramCost > 0 {
      let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gameInstance);
      let playerID: StatsObjectID   = Cast<StatsObjectID>(player.GetEntityID());
      let currentRAM: Float         = pool.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
      pool.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory,
        currentRAM - Cast<Float>(this.m_ramCost), player, false);
    }

    mss.AddMarkFromEntity(this.m_npcPS.GetMyEntityID(), MarkedSubnetType.NPC);
    BNInfo("NetworkScan", "NPC marked: " + EntityID.ToDebugString(this.m_npcPS.GetMyEntityID()));

    let logSys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
    if IsDefined(logSys) { logSys.ShowIfNew(); }
  }
}

@if(ModuleExists("HackingExtensions"))
public class BNUnmarkNPCAction extends CustomAccessBreach {
  private let m_npcPS:   ref<ScriptedPuppetPS>;
  private let m_ramCost: Int32;

  public func SetNPC(npcPS: ref<ScriptedPuppetPS>, ramCost: Int32) -> Void {
    this.m_npcPS   = npcPS;
    this.m_ramCost = ramCost;
  }

  public func GetTweakDBChoiceRecord() -> String { return "BNUnmarkNPC"; }
  public func GetCost() -> Int32 { return this.m_ramCost; }

  public func CanPayCost(opt user: ref<GameObject>, opt checkOverclock: Bool) -> Bool {
    let executor: ref<GameObject>;
    if IsDefined(user) { executor = user; } else { executor = this.GetExecutor(); }
    if !IsDefined(executor) { return false; }
    let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(executor.GetGame());
    let ram: Float = pool.GetStatPoolValue(Cast<StatsObjectID>(executor.GetEntityID()), gamedataStatPoolType.Memory, false);
    return ram >= Cast<Float>(this.m_ramCost);
  }

  public func PayCost(opt checkOverclock: Bool) -> Bool { return true; }

  private func CompleteAction(gameInstance: GameInstance) -> Void {
    if !IsDefined(this.m_npcPS) {
      BNError("NetworkScan", "BNUnmarkNPCAction: no NPC PS");
      return;
    }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if !IsDefined(mss) { return; }

    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
    if IsDefined(player) && this.m_ramCost > 0 {
      let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gameInstance);
      let playerID: StatsObjectID   = Cast<StatsObjectID>(player.GetEntityID());
      let currentRAM: Float         = pool.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
      pool.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory,
        currentRAM - Cast<Float>(this.m_ramCost), player, false);
    }

    mss.RemoveMarkAny(this.m_npcPS.GetMyEntityID());
    BNInfo("NetworkScan", "NPC unmarked: " + EntityID.ToDebugString(this.m_npcPS.GetMyEntityID()));

    let logSys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
    if IsDefined(logSys) { logSys.Refresh(); }
  }
}

@if(ModuleExists("HackingExtensions"))
@wrapMethod(ScriptedPuppet)
private final func TranslateChoicesIntoQuickSlotCommands(
  const puppetActions: script_ref<array<ref<PuppetAction>>>,
  commands:            script_ref<array<ref<QuickhackData>>>
) -> Void {
  wrappedMethod(puppetActions, commands);

  if this.IsDead() { return; }

  let gi: GameInstance = this.GetGame();

  let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
    .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if !IsDefined(mss) { return; }

  let player: ref<PlayerPuppet> = GetPlayer(gi);
  if !IsDefined(player) { return; }

  let npcPS: ref<ScriptedPuppetPS> = this.GetPS() as ScriptedPuppetPS;
  if !IsDefined(npcPS) { return; }

  let ramCost: Int32 = 2;
  let isMarked: Bool = mss.IsMark(this.GetEntityID(), MarkedSubnetType.NPC);

  let entry: ref<QuickhackData> = new QuickhackData();
  entry.m_itemID              = ItemID.None();
  entry.m_actionOwnerName     = StringToName(this.GetDisplayName());
  entry.m_actionOwner         = this.GetEntityID();
  entry.m_cost                = ramCost;
  entry.m_costRaw             = ramCost;
  entry.m_ICELevel            = 0.0;
  entry.m_ICELevelVisible     = false;
  entry.m_networkBreached     = false;
  entry.m_actionMatchesTarget = true;

  if isMarked {
    let action: ref<BNUnmarkNPCAction> = new BNUnmarkNPCAction();
    action.SetNPC(npcPS, ramCost);
    action.SetExecutor(player);

    let rec: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(t"QuickHack.BNUnmark");
    entry.m_title       = LocKeyToString(rec.ObjectActionUI().Caption());
    entry.m_description = LocKeyToString(rec.ObjectActionUI().Description());
    entry.m_icon        = rec.ObjectActionUI().CaptionIcon().TexturePartID().GetID();

    if action.CanPayCost(player, false) {
      entry.m_action      = action;
      entry.m_actionState = EActionInactivityReson.Ready;
      entry.m_isLocked    = false;
    } else {
      entry.m_isLocked       = true;
      entry.m_inactiveReason = BNConstants.LOCKEY_RAM_INSUFFICIENT();
      entry.m_actionState    = EActionInactivityReson.OutOfMemory;
    }
  } else {
    let action: ref<BNMarkNPCAction> = new BNMarkNPCAction();
    action.SetNPC(npcPS, ramCost);
    action.SetExecutor(player);

    let rec: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(t"QuickHack.BNMark");
    entry.m_title       = LocKeyToString(rec.ObjectActionUI().Caption());
    entry.m_description = LocKeyToString(rec.ObjectActionUI().Description());
    entry.m_icon        = rec.ObjectActionUI().CaptionIcon().TexturePartID().GetID();

    if action.CanPayCost(player, false) {
      entry.m_action      = action;
      entry.m_actionState = EActionInactivityReson.Ready;
      entry.m_isLocked    = false;
    } else {
      entry.m_isLocked       = true;
      entry.m_inactiveReason = BNConstants.LOCKEY_RAM_INSUFFICIENT();
      entry.m_actionState    = EActionInactivityReson.OutOfMemory;
    }
  }

  ArrayPush(Deref(commands), entry);
}

@if(ModuleExists("HackingExtensions"))
public class BNMarkDeviceAction extends CustomAccessBreach {
  private let m_devicePS: ref<ScriptableDeviceComponentPS>;
  private let m_ramCost: Int32;

  public func SetDevicePS(devicePS: ref<ScriptableDeviceComponentPS>, ramCost: Int32) -> Void {
    this.m_devicePS = devicePS;
    this.m_ramCost = ramCost;
  }

  public func GetTweakDBChoiceRecord() -> String { return "BNMark"; }
  public func GetInteractionDescription() -> String {
    let rec: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(t"QuickHack.BNMark");
    if IsDefined(rec) { return LocKeyToString(rec.ObjectActionUI().Caption()); }
    return "Mark";
  }
  public func GetCost() -> Int32 { return this.m_ramCost; }

  public func CanPayCost(opt user: ref<GameObject>, opt checkOverclock: Bool) -> Bool {
    let executor: ref<GameObject>;
    if IsDefined(user) { executor = user; } else { executor = this.GetExecutor(); }
    if !IsDefined(executor) { return false; }
    let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(executor.GetGame());
    let ram: Float = pool.GetStatPoolValue(Cast<StatsObjectID>(executor.GetEntityID()), gamedataStatPoolType.Memory, false);
    return ram >= Cast<Float>(this.m_ramCost);
  }

  public func PayCost(opt checkOverclock: Bool) -> Bool { return true; }

  private func CompleteAction(gameInstance: GameInstance) -> Void {
    if !IsDefined(this.m_devicePS) {
      BNError("NetworkScan", "BNMarkDeviceAction: no device PS");
      return;
    }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if !IsDefined(mss) { return; }

    let deviceEntity: wref<GameObject> = this.m_devicePS.GetOwnerEntityWeak() as GameObject;
    if !IsDefined(deviceEntity) { return; }

    let subnetType: MarkedSubnetType;
    if DaemonFilterUtils.IsCamera(this.m_devicePS) {
      subnetType = MarkedSubnetType.Camera;
    } else if DaemonFilterUtils.IsTurret(this.m_devicePS) {
      subnetType = MarkedSubnetType.Defense;
    } else {
      subnetType = MarkedSubnetType.Root;
    }

    let sharedPS: ref<SharedGameplayPS> = this.m_devicePS as SharedGameplayPS;
    if IsDefined(sharedPS) && sharedPS.m_bnIceHitsRequired == 0 {
      sharedPS.m_bnIceHitsRequired = NetworkStateUtils.GetHeatScaledICEHits(gameInstance);
    }
    let iceHitsRequired: Int32 = IsDefined(sharedPS) ? sharedPS.m_bnIceHitsRequired : 0;

    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
    if IsDefined(player) && this.m_ramCost > 0 {
      let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gameInstance);
      let playerID: StatsObjectID   = Cast<StatsObjectID>(player.GetEntityID());
      let currentRAM: Float         = pool.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
      pool.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory,
        currentRAM - Cast<Float>(this.m_ramCost), player, false);
    }

    let displayName: String = this.m_devicePS.GetDeviceName();
    mss.AddMarkNamed(deviceEntity.GetEntityID(), subnetType, displayName, iceHitsRequired);
    BNInfo("NetworkScan", "Device marked: " + displayName);

    let logSys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
    if IsDefined(logSys) { logSys.ShowIfNew(); }
  }
}

@if(ModuleExists("HackingExtensions"))
public class BNUnmarkDeviceAction extends CustomAccessBreach {
  private let m_devicePS: ref<ScriptableDeviceComponentPS>;
  private let m_ramCost: Int32;

  public func SetDevicePS(devicePS: ref<ScriptableDeviceComponentPS>, ramCost: Int32) -> Void {
    this.m_devicePS = devicePS;
    this.m_ramCost = ramCost;
  }

  public func GetTweakDBChoiceRecord() -> String { return "BNUnmark"; }
  public func GetInteractionDescription() -> String {
    let rec: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(t"QuickHack.BNUnmark");
    if IsDefined(rec) { return LocKeyToString(rec.ObjectActionUI().Caption()); }
    return "Unmark";
  }
  public func GetCost() -> Int32 { return this.m_ramCost; }

  public func CanPayCost(opt user: ref<GameObject>, opt checkOverclock: Bool) -> Bool {
    let executor: ref<GameObject>;
    if IsDefined(user) { executor = user; } else { executor = this.GetExecutor(); }
    if !IsDefined(executor) { return false; }
    let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(executor.GetGame());
    let ram: Float = pool.GetStatPoolValue(Cast<StatsObjectID>(executor.GetEntityID()), gamedataStatPoolType.Memory, false);
    return ram >= Cast<Float>(this.m_ramCost);
  }

  public func PayCost(opt checkOverclock: Bool) -> Bool { return true; }

  private func CompleteAction(gameInstance: GameInstance) -> Void {
    if !IsDefined(this.m_devicePS) {
      BNError("NetworkScan", "BNUnmarkDeviceAction: no device PS");
      return;
    }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if !IsDefined(mss) { return; }

    let deviceEntity: wref<GameObject> = this.m_devicePS.GetOwnerEntityWeak() as GameObject;
    if !IsDefined(deviceEntity) { return; }

    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
    if IsDefined(player) && this.m_ramCost > 0 {
      let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gameInstance);
      let playerID: StatsObjectID   = Cast<StatsObjectID>(player.GetEntityID());
      let currentRAM: Float         = pool.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
      pool.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory,
        currentRAM - Cast<Float>(this.m_ramCost), player, false);
    }

    let displayName: String = this.m_devicePS.GetDeviceName();
    mss.RemoveMarkAny(deviceEntity.GetEntityID());
    BNInfo("NetworkScan", "Device unmarked: " + displayName);

    let logSys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
    if IsDefined(logSys) { logSys.Refresh(); }
  }
}

@if(ModuleExists("HackingExtensions"))
@wrapMethod(ScriptableDeviceComponentPS)
public final func GetRemoteActions(out outActions: array<ref<DeviceAction>>, const context: script_ref<GetActionsContext>) -> Void {
  wrappedMethod(outActions, context);

  if IsDefined(this as AccessPointControllerPS) { return; }

  let gi: GameInstance = this.GetGameInstance();

  let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
    .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if !IsDefined(mss) { return; }

  let deviceEntity: wref<GameObject> = this.GetOwnerEntityWeak() as GameObject;
  if !IsDefined(deviceEntity) { return; }

  let subnetType: MarkedSubnetType;
  if DaemonFilterUtils.IsCamera(this) {
    subnetType = MarkedSubnetType.Camera;
  } else if DaemonFilterUtils.IsTurret(this) {
    subnetType = MarkedSubnetType.Defense;
  } else {
    subnetType = MarkedSubnetType.Root;
  }

  let ramCost: Int32 = 2;
  let isMarked: Bool = mss.IsMark(deviceEntity.GetEntityID(), subnetType);
  let player: ref<PlayerPuppet> = GetPlayer(gi);

  let hackSystem: ref<CustomHackingSystem> =
    GameInstance.GetScriptableSystemsContainer(gi).Get(BNConstants.CLASS_CUSTOM_HACKING_SYSTEM()) as CustomHackingSystem;

  if IsDefined(hackSystem) {
    let scanBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().HackingMinigame);
    let scanEntity: wref<Entity> = this.GetOwnerEntityWeak() as Entity;
    if IsDefined(scanBB) && IsDefined(scanEntity) {
      scanBB.SetVariant(GetAllBlackboardDefs().HackingMinigame.Entity, ToVariant(scanEntity));
    }
  }

  if isMarked {
    let action: ref<BNUnmarkDeviceAction> = new BNUnmarkDeviceAction();
    action.SetDevicePS(this, ramCost);
    if IsDefined(player) { action.SetExecutor(player); }
    if !action.CanPayCost(player, false) {
      action.SetInactiveWithReason(false, BNConstants.LOCKEY_RAM_INSUFFICIENT());
    }
    if IsDefined(hackSystem) { hackSystem.RegisterDeviceAction(action); }
    ArrayPush(outActions, action);
  } else {
    let action: ref<BNMarkDeviceAction> = new BNMarkDeviceAction();
    action.SetDevicePS(this, ramCost);
    if IsDefined(player) { action.SetExecutor(player); }
    if !action.CanPayCost(player, false) {
      action.SetInactiveWithReason(false, BNConstants.LOCKEY_RAM_INSUFFICIENT());
    }
    if IsDefined(hackSystem) { hackSystem.RegisterDeviceAction(action); }
    ArrayPush(outActions, action);
  }
}

