

module BetterNetrunning.Breach

import BetterNetrunning.*
import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Utils.*
import BetterNetrunning.RadialUnlock.*
import BetterNetrunning.Marking.*
import BetterNetrunning.Network.*

@wrapMethod(AccessPointControllerPS)
private final func RefreshSlaves(const devices: script_ref<array<ref<DeviceComponentPS>>>) -> Void {

  let isUnconsciousNPCBreach: Bool = this.IsUnconsciousNPCBreach();

  if !isUnconsciousNPCBreach {
    DebugUtils.LogAccessPointBreachTarget(this, "BreachStart");
  }

  let breachType: String = isUnconsciousNPCBreach ? "UnconsciousNPC" : "AccessPoint";
  let stats: ref<BreachSessionStats> = BreachSessionStats.Create(
    breachType,
    this.GetDeviceName()
  );

  if isUnconsciousNPCBreach {
    this.MarkUnconsciousNPCAsDirectlyBreached();
  }

  let stateSystem: ref<DisplayedDaemonsStateSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGameInstance())
    .Get(BNConstants.CLASS_DISPLAYED_DAEMONS_STATE_SYSTEM()) as DisplayedDaemonsStateSystem;
  if IsDefined(stateSystem) {
    let displayedDaemons: array<TweakDBID> = stateSystem.GetDisplayedDaemons();
    BreachStatisticsCollector.CollectDisplayedDaemons(displayedDaemons, stats);
  }

  let minigamePrograms: array<TweakDBID> = FromVariant<array<TweakDBID>>(
    this.GetMinigameBlackboard().GetVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms)
  );
  stats.programsInjected = ArraySize(minigamePrograms);

  let unlockFlags: BreachUnlockFlags = DaemonFilterUtils.ExtractUnlockFlags(minigamePrograms);
  stats.unlockBasic = unlockFlags.unlockBasic;
  stats.unlockCameras = unlockFlags.unlockCameras;
  stats.unlockTurrets = unlockFlags.unlockTurrets;
  stats.unlockNPCs = unlockFlags.unlockNPCs;

  let ms: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGameInstance())
    .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if IsDefined(ms) { ms.SetApBreachFinalizing(true); }
  wrappedMethod(devices);
  if IsDefined(ms) { ms.SetApBreachFinalizing(false); }
  stats.minigameSuccess = true; // RefreshSlaves only called on success

  this.ApplyBetterNetrunningExtensionsWithStats(devices, unlockFlags, stats, isUnconsciousNPCBreach, minigamePrograms);

  stats.Finalize();
  LogBreachSummary(stats);

  this.ShowBreachResultInWidget(unlockFlags, isUnconsciousNPCBreach);
}

@addMethod(AccessPointControllerPS)
private final func IsUnconsciousNPCBreach() -> Bool {
  let entity: wref<Entity> = FromVariant<wref<Entity>>(
    this.GetMinigameBlackboard().GetVariant(GetAllBlackboardDefs().HackingMinigame.Entity)
  );
  return IsDefined(entity as ScriptedPuppet);
}

@addMethod(AccessPointControllerPS)
private final func MarkUnconsciousNPCAsDirectlyBreached() -> Void {
  let entity: wref<Entity> = FromVariant<wref<Entity>>(
    this.GetMinigameBlackboard().GetVariant(GetAllBlackboardDefs().HackingMinigame.Entity)
  );
  let npcPuppet: wref<ScriptedPuppet> = entity as ScriptedPuppet;
  if !IsDefined(npcPuppet) { return; }
  let npcPS: ref<ScriptedPuppetPS> = npcPuppet.GetPuppetPS();
  if IsDefined(npcPS) {
    npcPS.m_betterNetrunningWasDirectlyBreached = true;
    DebugUtils.LogUnconsciousNPCBreachTarget(npcPuppet, npcPS, "BreachStart");
  }
}

@addMethod(AccessPointControllerPS)
private final func ApplyBetterNetrunningExtensionsWithStats(
  const devices: script_ref<array<ref<DeviceComponentPS>>>,
  unlockFlags: BreachUnlockFlags,
  stats: ref<BreachSessionStats>,
  isUnconsciousNPCBreach: Bool,
  minigamePrograms: array<TweakDBID>
) -> Void {
  BNTrace("BreachProcessing", s"ApplyBetterNetrunningExtensions - isUnconsciousNPCBreach: \(ToString(isUnconsciousNPCBreach))");

  BreachStatisticsCollector.CollectExecutedDaemons(minigamePrograms, stats);

  NetworkStateUtils.OnDaemonsCompleted(minigamePrograms, this, this.GetGameInstance());

  this.RollbackIncorrectVanillaUnlocks(devices, unlockFlags);

  this.ApplyBreachUnlockToDevicesWithStats(devices, unlockFlags, stats);

  this.ExecuteNPCBreachPingIfNeeded(minigamePrograms);

  let logSys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGameInstance())
    .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
  if IsDefined(logSys) { logSys.Refresh(); }
}

@addMethod(AccessPointControllerPS)
private final func RollbackIncorrectVanillaUnlocks(const devices: script_ref<array<ref<DeviceComponentPS>>>, unlockFlags: BreachUnlockFlags) -> Void {
  let i: Int32 = 0;
  while i < ArraySize(Deref(devices)) {
    let device: ref<DeviceComponentPS> = Deref(devices)[i];
    let sharedPS: ref<SharedGameplayPS> = device as SharedGameplayPS;

    if IsDefined(sharedPS) {
      let TargetType: TargetType = DeviceTypeUtils.GetDeviceType(device);

      if !DeviceTypeUtils.ShouldUnlockByFlags(TargetType, unlockFlags) {

        let currentTimestamp: Float = 0.0;
        switch TargetType {
          case TargetType.NPC:
            currentTimestamp = sharedPS.m_betterNetrunningUnlockTimestampNPCs;
            break;
          case TargetType.Camera:
            currentTimestamp = sharedPS.m_betterNetrunningUnlockTimestampCameras;
            break;
          case TargetType.Turret:
            currentTimestamp = sharedPS.m_betterNetrunningUnlockTimestampTurrets;
            break;
          default: // TargetType.Basic
            currentTimestamp = sharedPS.m_betterNetrunningUnlockTimestampBasic;
            break;
        }

        if currentTimestamp == 0.0 {
          switch TargetType {
            case TargetType.NPC:
              sharedPS.m_betterNetrunningUnlockTimestampNPCs = 0.0;
              break;
            case TargetType.Camera:
              sharedPS.m_betterNetrunningUnlockTimestampCameras = 0.0;
              break;
            case TargetType.Turret:
              sharedPS.m_betterNetrunningUnlockTimestampTurrets = 0.0;
              break;
            default: // TargetType.Basic
              sharedPS.m_betterNetrunningUnlockTimestampBasic = 0.0;
              break;
          }

          BNDebug("RollbackUnlock", "Reverted vanilla unlock for device (Type: " +
            DeviceTypeUtils.DeviceTypeToString(TargetType) + ")");
        } else {
          BNDebug("RollbackUnlock", "Preserved existing unlock for device (Type: " +
            DeviceTypeUtils.DeviceTypeToString(TargetType) +
            ", Timestamp: " + ToString(currentTimestamp) + ")");
        }
      }
    }

    i += 1;
  }
}

@addMethod(AccessPointControllerPS)
private final func ExecuteNPCBreachPingIfNeeded(minigamePrograms: array<TweakDBID>) -> Void {

}

@addMethod(AccessPointControllerPS)
private final func GetMinigameBlackboard() -> ref<IBlackboard> {
  return GameInstance.GetBlackboardSystem(this.GetGameInstance()).Get(GetAllBlackboardDefs().HackingMinigame);
}

@addMethod(AccessPointControllerPS)
private final func ApplyBreachUnlockToDevicesWithStats(
    const devices:   script_ref<array<ref<DeviceComponentPS>>>,
    unlockFlags:     BreachUnlockFlags,
    stats:           ref<BreachSessionStats>
) -> Void {
    let gameInstance: GameInstance = this.GetGameInstance();
    let markingSystem: ref<MarkingStateSystem> =
        GameInstance.GetScriptableSystemsContainer(gameInstance).Get(
            BNConstants.CLASS_MARKING_STATE_SYSTEM()
        ) as MarkingStateSystem;

    if IsDefined(markingSystem) && markingSystem.HasAnyMarked() {

        BNInfo("BreachProcessing", "Targeted breach — propagating only to marked entities");

        this.DeductRAMForMarkedEntities(markingSystem, gameInstance);
        this.ApplyTargetedBreachUnlock(markingSystem, unlockFlags, gameInstance);

    } else {

        BreachStatisticsCollector.CollectNetworkDeviceStats(Deref(devices), unlockFlags, stats);
        let i: Int32 = 0;
        while i < ArraySize(Deref(devices)) {
            let device: ref<DeviceComponentPS> = Deref(devices)[i];
            if IsDefined(device) {
                this.UnlockDevice(device, unlockFlags);
            }
            i += 1;
        }
    }
}

@addMethod(AccessPointControllerPS)
private final func ApplyTargetedBreachUnlock(
    markingSystem: ref<MarkingStateSystem>,
    unlockFlags:   BreachUnlockFlags,
    gameInstance:  GameInstance
) -> Void {
    TargetedBreachUtils.UnlockMarkedEntities(markingSystem, unlockFlags, gameInstance);
}

@addMethod(AccessPointControllerPS)
private final func UnlockDevice(
  device: ref<DeviceComponentPS>,
  unlockFlags: BreachUnlockFlags
) -> Void {
  let sharedPS: ref<SharedGameplayPS> = device as SharedGameplayPS;
  if !IsDefined(sharedPS) {
    return;
  }

  let TargetType: TargetType = DeviceTypeUtils.GetDeviceType(device);

  if !DeviceTypeUtils.ShouldUnlockByFlags(TargetType, unlockFlags) {
    return;
  }

  let gameInstance: GameInstance = this.GetGameInstance();
  DeviceUnlockUtils.ApplyTimestampUnlock(
    device,
    gameInstance,
    unlockFlags.unlockBasic,
    unlockFlags.unlockNPCs,
    unlockFlags.unlockCameras,
    unlockFlags.unlockTurrets
  );

  if sharedPS.m_bnIceHitsRequired <= 0 { sharedPS.m_bnIceHitsRequired = 1; }
  sharedPS.m_bnIceHitsApplied = sharedPS.m_bnIceHitsRequired;
  sharedPS.m_bnIceDefeated = true;
}

@addMethod(AccessPointControllerPS)
public final func ApplyDeviceTypeUnlock(device: ref<DeviceComponentPS>, unlockFlags: BreachUnlockFlags) -> Void {
  let sharedPS: ref<SharedGameplayPS> = device as SharedGameplayPS;
  if !IsDefined(sharedPS) {
    return;
  }

  let TargetType: TargetType = DeviceTypeUtils.GetDeviceType(device);

  if !DeviceTypeUtils.ShouldUnlockByFlags(TargetType, unlockFlags) {
    return;
  }

  this.QueuePSEvent(device, this.ActionSetExposeQuickHacks());

  let currentTime: Float = TimeUtils.GetCurrentTimestamp(this.GetGameInstance());
  TimeUtils.SetDeviceUnlockTimestamp(sharedPS, TargetType, currentTime);
}

@addMethod(AccessPointControllerPS)
private final func ShowBreachResultInWidget(unlockFlags: BreachUnlockFlags, isUnconsciousNPCBreach: Bool) -> Void {
  let gi: GameInstance = this.GetGameInstance();
  let ms: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
    .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if !IsDefined(ms) { return; }

  let targetName: String = "ACCESS POINT";
  let apEntity: wref<GameObject> = this.GetOwnerEntityWeak() as GameObject;
  if IsDefined(apEntity) {
    let raw: String = GetLocalizedText(apEntity.GetDisplayName());
    if NotEquals(raw, s"") { targetName = raw; }
  }

  if isUnconsciousNPCBreach {
    let entity: wref<Entity> = FromVariant<wref<Entity>>(
      this.GetMinigameBlackboard().GetVariant(GetAllBlackboardDefs().HackingMinigame.Entity));
    let puppet: wref<ScriptedPuppet> = entity as ScriptedPuppet;
    if IsDefined(puppet) {
      let raw: String = GetLocalizedText(puppet.GetDisplayName());
      if NotEquals(raw, s"") { targetName = raw; }
    }
  }

  let targetType: String = "device";
  if isUnconsciousNPCBreach || unlockFlags.unlockNPCs { targetType = "personnel"; }
  else if unlockFlags.unlockCameras { targetType = "camera"; }
  else if unlockFlags.unlockTurrets { targetType = "turret"; }

  ms.RecordRemoteBreachTarget(targetName, targetType);
  ms.RecordBreachICEState(1, 1);  // 1/1 = shows "FULLY COMPROMISED" for a successful breach
  ms.ShowRemoteBreachStatus();
}

@addMethod(AccessPointControllerPS)
private final func DeductRAMForMarkedEntities(markingSystem: ref<MarkingStateSystem>, gameInstance: GameInstance) -> Void {
    let markedCount: Int32 = markingSystem.GetTotalCount();
    if markedCount <= 0 { return; }

    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
    if !IsDefined(player) { return; }

    let statPoolSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gameInstance);
    let playerID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
    let currentRAM: Float = statPoolSystem.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
    let newRAM: Float = MaxF(0.0, currentRAM - Cast<Float>(markedCount));
    statPoolSystem.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory, newRAM, player, false);
    BNInfo("BreachProcessing", "Targeted breach RAM cost: -" + ToString(markedCount) + " (" + ToString(markedCount) + " marked entities)");
}
