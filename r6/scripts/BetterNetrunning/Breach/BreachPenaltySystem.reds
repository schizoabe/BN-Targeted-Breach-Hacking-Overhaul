
module BetterNetrunning.Breach
import BetterNetrunning.Logging.*
import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Integration.*
import BetterNetrunning.Marking.*
import BetterNetrunning.RemoteBreach.Common.*
import BetterNetrunning.RemoteBreach.Core.*
import BetterNetrunning.Network.*
import BetterNetrunning.Minigame.*

public enum BreachType {
  Unknown = 0,
  AccessPoint = 1,
  UnconsciousNPC = 2,
  RemoteBreach = 3
}

@wrapMethod(ScriptableDeviceComponentPS)
public func FinalizeNetrunnerDive(state: HackingMinigameState) -> Void {

  if NotEquals(state, HackingMinigameState.Failed) && NotEquals(state, HackingMinigameState.Succeeded) {
    wrappedMethod(state);
    return;
  }

  if Equals(state, HackingMinigameState.Failed) {
    let breachType: BreachType = this.DetectBreachType();
    if !ShouldApplyBreachPenalty(breachType) {
      wrappedMethod(state);
      return;
    }
    let gameInstance: GameInstance = this.GetGameInstance();
    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
    if !IsDefined(player) {
      BNError("BreachPenalty", "Player not found, skipping penalty");
      wrappedMethod(state);
      return;
    }
    ApplyFailurePenalty(player, this, gameInstance, breachType);
    NetworkStateUtils.OnBreachFailed(this, gameInstance);
    BNDebug("NetworkState", "Breach failed — Heat spiked, Vulnerability reduced");
    wrappedMethod(state);
    return;
  }

  let gi: GameInstance = this.GetGameInstance();
  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gi);
  let markingSystem: ref<MarkingStateSystem> = container.Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;

  let bbHacking: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().HackingMinigame);
  let completedPrograms: array<TweakDBID> = FromVariant<array<TweakDBID>>(
    bbHacking.GetVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms)
  );
  let hasExitProtocol: Bool = false;
  let epi: Int32 = 0;
  while epi < ArraySize(completedPrograms) {
    if completedPrograms[epi] == BNConstants.PROGRAM_BN_EXIT_PROTOCOL() { hasExitProtocol = true; }
    epi += 1;
  }

  this.BNDispatchOffensiveDaemons();

  if hasExitProtocol {
    BNInfo("BreachLoop", "Exit Protocol completed — jacking out");
    wrappedMethod(state);
    return;
  }

  let heat: Float = IsDefined(markingSystem) ? markingSystem.GetSessionHeat() : 1.0;
  if heat >= 1.0 {
    BNInfo("BreachLoop", "Heat maxed — jacking out");
    wrappedMethod(state);
    return;
  }

  BNInfo("BreachLoop", "Board complete — looping (heat=" + ToString(heat) + ")");

  NetworkStateUtils.OnDaemonsCompleted(completedPrograms, this, gi);

  let unlockFlags: BreachUnlockFlags = DaemonFilterUtils.ExtractUnlockFlags(completedPrograms);
  if IsDefined(markingSystem) && markingSystem.HasAnyMarked() {
    let markedCount: Int32 = markingSystem.GetTotalCount();
    let loopPlayer: ref<PlayerPuppet> = GetPlayer(gi);
    if IsDefined(loopPlayer) && markedCount > 0 {
      let statPools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gi);
      let playerID: StatsObjectID = Cast<StatsObjectID>(loopPlayer.GetEntityID());
      let curRAM: Float = statPools.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
      statPools.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory,
        MaxF(0.0, curRAM - Cast<Float>(markedCount)), loopPlayer, false);
    }
    TargetedBreachUtils.UnlockMarkedEntities(markingSystem, unlockFlags, gi);
    BNInfo("BreachLoop", "Targeted breach unlock applied mid-loop");
  }

  this.BNReopenBreachBoard(gi);
}

public class BNReopenBoardEvent extends Event {}

@addMethod(ScriptableDeviceComponentPS)
private final func BNReopenBreachBoard(gi: GameInstance) -> Void {
  let bbMinigame: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().HackingMinigame);

  let emptyPrograms: array<TweakDBID>;
  bbMinigame.SetVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms, ToVariant(emptyPrograms), true);

  let reopenEvt: ref<BNReopenBoardEvent> = new BNReopenBoardEvent();
  GameInstance.GetDelaySystem(gi).DelayPSEvent(this.GetID(), this.GetClassName(), reopenEvt, 0.5, false);
}

@addMethod(ScriptableDeviceComponentPS)
public func OnBNReopenBoardEvent(evt: ref<BNReopenBoardEvent>) -> EntityNotificationType {
  let gi: GameInstance = this.GetGameInstance();

  let bbNetwork: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().NetworkBlackboard);
  bbNetwork.SetString(GetAllBlackboardDefs().NetworkBlackboard.NetworkName, "");
  this.BNReInitiateDive(gi);
  return EntityNotificationType.DoNotNotifyEntity;
}

@addField(ScriptableDeviceComponentPS)
let m_bnSJKILooping: Bool;

@addMethod(ScriptableDeviceComponentPS)
public final func BNHandleSJKIBoardComplete(gi: GameInstance, completedPrograms: array<TweakDBID>) -> Void {
  let markingSystem: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
    .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;

  let hasExitProtocol: Bool = false;
  let i: Int32 = 0;
  while i < ArraySize(completedPrograms) {
    if completedPrograms[i] == BNConstants.PROGRAM_BN_EXIT_PROTOCOL() { hasExitProtocol = true; }
    i += 1;
  }

  if hasExitProtocol {
    BNInfo("BreachLoop", "SJKI: Exit Protocol — jacking out");
    return;
  }

  let heat: Float = IsDefined(markingSystem) ? markingSystem.GetSessionHeat() : 1.0;
  if heat >= 1.0 {
    BNInfo("BreachLoop", "SJKI: Heat maxed — jacking out");
    return;
  }

  BNInfo("BreachLoop", "SJKI: Board complete — looping (heat=" + ToString(heat) + ")");
  this.m_bnSJKILooping = true;
  this.BNReopenBreachBoard(gi);
}

@if(ModuleExists("HackthePlanetForReal"))
@addMethod(ScriptableDeviceComponentPS)
public final func BNReInitiateDiveSJKI(gi: GameInstance) -> Void {
  this.m_bnSJKILooping = false;
  this.m_isSJKIStandaloneDevice = true;
  this.m_personalLinkStatus = EPersonalLinkConnectionStatus.CONNECTED;
  this.m_hackingMinigameState = HackingMinigameState.Unknown;
  let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().NetworkBlackboard);
  bb.SetInt    (GetAllBlackboardDefs().NetworkBlackboard.DevicesCount,  1);
  bb.SetBool   (GetAllBlackboardDefs().NetworkBlackboard.OfficerBreach, false);
  bb.SetBool   (GetAllBlackboardDefs().NetworkBlackboard.RemoteBreach,  false);
  bb.SetInt    (GetAllBlackboardDefs().NetworkBlackboard.Attempt,       this.m_minigameAttempt);
  bb.SetEntityID(GetAllBlackboardDefs().NetworkBlackboard.DeviceID,     this.GetMyEntityID());
  bb.SetVariant(GetAllBlackboardDefs().NetworkBlackboard.MinigameDef,   ToVariant(this.GetMinigameDefinition()));
  bb.SetString (GetAllBlackboardDefs().NetworkBlackboard.NetworkName,   this.GetDeviceName(), true);
  BNInfo("BreachLoop", "SJKI re-entry: re-armed standalone, HUD reopened");
}

@if(!ModuleExists("HackthePlanetForReal"))
@addMethod(ScriptableDeviceComponentPS)
public final func BNReInitiateDiveSJKI(gi: GameInstance) -> Void {}

@addMethod(ScriptableDeviceComponentPS)
public final func BNReInitiateDive(gi: GameInstance) -> Void {

  if this.m_bnSJKILooping {
    this.BNReInitiateDiveSJKI(gi);
    return;
  }

  let linked: Bool = this.IsPersonalLinkConnected();
  BNDebug("BreachLoop", "BNReInitiateDive: personalLinkConnected=" + ToString(linked));

  this.m_personalLinkStatus = EPersonalLinkConnectionStatus.CONNECTED;

  this.m_hackingMinigameState = HackingMinigameState.Unknown;

  let player: ref<GameObject> = this.GetPlayerMainObject();
  let diveAction: ref<ToggleNetrunnerDive> = this.ActionToggleNetrunnerDive(false);
  diveAction.SetExecutor(player);
  this.ExecutePSAction(diveAction);
  BNInfo("BreachLoop", "Dive re-triggered (wasLinked=" + ToString(linked) + ") — board spawn expected");
}

@wrapMethod(AccessPointControllerPS)
public func FinalizeNetrunnerDive(state: HackingMinigameState) -> Void {

  if Equals(state, HackingMinigameState.Succeeded) {
    wrappedMethod(state);
    return;
  }

  if Equals(state, HackingMinigameState.Failed) {

    this.m_minigameAttempt += 1;

    let player: ref<GameObject> = this.GetPlayerMainObject();
    let toggleAction: ref<ToggleNetrunnerDive> = this.ActionToggleNetrunnerDive(true);
    toggleAction.SetExecutor(player);
    this.ExecutePSAction(toggleAction);

    let playerPuppet: ref<PlayerPuppet> = player as PlayerPuppet;
    if IsDefined(playerPuppet) {
      let gameInstance: GameInstance = this.GetGameInstance();
      let breachType: BreachType = this.DetectBreachType();

      if ShouldApplyBreachPenalty(breachType) {
        ApplyFailurePenalty(playerPuppet, this, gameInstance, breachType);
      }

      NetworkStateUtils.OnBreachFailed(this, gameInstance);
      BNDebug("NetworkState", "AP breach failed — Heat spiked, Vulnerability reduced");
    }

    BNInfo("BreachPenalty", "AP breach failed - NPC alert suppressed (SendMinigameFailedToAllNPCs skipped)");
    return;
  }

  wrappedMethod(state);
}

@wrapMethod(AccessPointControllerPS)
public func OnNPCBreachEvent(evt: ref<NPCBreachEvent>) -> EntityNotificationType {

  if Equals(evt.state, HackingMinigameState.Succeeded) {
    this.SetIsBreached(true);
    this.RefreshSlaves_Event();
    return EntityNotificationType.DoNotNotifyEntity;
  }

  if Equals(evt.state, HackingMinigameState.Failed) {

    this.m_minigameAttempt += 1;

    BNInfo("BreachPenalty", "Unconscious NPC breach failed - NPC alert suppressed (SendMinigameFailedToAllNPCs skipped)");
    return EntityNotificationType.DoNotNotifyEntity;
  }

  return wrappedMethod(evt);
}

@addMethod(ScriptableDeviceComponentPS)
private func DetectBreachType() -> BreachType {

  if this.IsRemoteBreachingAnyDevice() {
    return BreachType.RemoteBreach;
  }

  if this.HasPersonalLinkSlot() {

    return BreachType.AccessPoint;
  }

  return BreachType.RemoteBreach;
}

@addMethod(ScriptableDeviceComponentPS)
private func IsRemoteBreachingAnyDevice() -> Bool {
  let gameInstance: GameInstance = this.GetGameInstance();
  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gameInstance);

  if !IsDefined(container) {
    return false;
  }

  let deviceSystem: ref<DeviceRemoteBreachStateSystem> = container.Get(BNConstants.CLASS_DEVICE_REMOTE_BREACH_STATE_SYSTEM()) as DeviceRemoteBreachStateSystem;
  if IsDefined(deviceSystem) {
    let currentDevice: wref<ScriptableDeviceComponentPS> = deviceSystem.GetCurrentDevice();
    if IsDefined(currentDevice) && currentDevice == this {
      return true;
    }
  }

  return false;
}

@addMethod(ScriptableDeviceComponentPS)
private func IsBreachPenaltyEnabledForType(breachType: BreachType) -> Bool {
  if Equals(breachType, BreachType.AccessPoint) {
    return BetterNetrunningSettings.APBreachFailurePenaltyEnabled();
  }
  if Equals(breachType, BreachType.UnconsciousNPC) {
    return BetterNetrunningSettings.NPCBreachFailurePenaltyEnabled();
  }
  if Equals(breachType, BreachType.RemoteBreach) {
    return BetterNetrunningSettings.RemoteBreachFailurePenaltyEnabled();
  }

  return BetterNetrunningSettings.RemoteBreachFailurePenaltyEnabled();
}

private static func ShouldApplyBreachPenalty(breachType: BreachType) -> Bool {

  if !BetterNetrunningSettings.BreachFailurePenaltyEnabled() {
    return false;
  }

  if Equals(breachType, BreachType.AccessPoint) {
    return BetterNetrunningSettings.APBreachFailurePenaltyEnabled();
  }
  if Equals(breachType, BreachType.UnconsciousNPC) {
    return BetterNetrunningSettings.NPCBreachFailurePenaltyEnabled();
  }
  if Equals(breachType, BreachType.RemoteBreach) {
    return BetterNetrunningSettings.RemoteBreachFailurePenaltyEnabled();
  }

  return BetterNetrunningSettings.RemoteBreachFailurePenaltyEnabled();
}

public static func ApplyFailurePenalty(
  player: ref<PlayerPuppet>,
  devicePS: ref<ScriptableDeviceComponentPS>,
  gameInstance: GameInstance,
  breachType: BreachType
) -> Void {

  ApplyBreachFailurePenaltyVFX(player, gameInstance);

  let deviceEntity: wref<GameObject> = devicePS.GetOwnerEntityWeak() as GameObject;
  if !IsDefined(deviceEntity) {
    BNDebug("BreachPenalty", "ApplyFailurePenalty: deviceEntity not resolved");
    TriggerTraceAttempt(player, gameInstance);
    return;
  }

  if Equals(breachType, BreachType.RemoteBreach) {

    RecordBreachFailureByType(player, devicePS, deviceEntity.GetWorldPosition(), gameInstance, breachType);
  } else if Equals(breachType, BreachType.AccessPoint) {

    if RecordBreachFailureTimestamp(devicePS, gameInstance) {

      DeviceInteractionUtils.DisableJackInInteractionForAccessPoint(devicePS);
      BNDebug("BreachPenalty", "Disabled JackIn interaction for failed AP breach");
    }
  }

  TriggerTraceAttempt(player, gameInstance);
}

public static func ApplyFailurePenalty(
  player: ref<PlayerPuppet>,
  npcPuppet: ref<ScriptedPuppet>,
  gameInstance: GameInstance
) -> Void {

  ApplyBreachFailurePenaltyVFX(player, gameInstance);

  if IsDefined(npcPuppet) {
    let npcPS: ref<ScriptedPuppetPS> = npcPuppet.GetPuppetPS();
    if RecordBreachFailureTimestamp(npcPS, gameInstance) {

      npcPuppet.DetermineInteractionStateByTask();
      BNDebug("BreachPenalty", "Queued interaction state refresh for NPC");
    }
  } else {
    BNDebug("BreachPenalty", "ApplyFailurePenalty(NPC overload): npcPuppet not defined");
  }

  TriggerTraceAttempt(player, gameInstance);
}

private static func ApplyBreachFailurePenaltyVFX(
  player: ref<PlayerPuppet>,
  gameInstance: GameInstance
) -> Void {
  GameObjectEffectHelper.StartEffectEvent(
    player,
    n"disabling_connectivity_glitch_red",
    false
  );
}

private static func RecordBreachFailureTimestamp(
  devicePS: ref<ScriptableDeviceComponentPS>,
  gameInstance: GameInstance
) -> Bool {
  let sharedPS: ref<SharedGameplayPS> = devicePS;
  if !IsDefined(sharedPS) {
    BNDebug("BreachPenalty", "RecordBreachFailureTimestamp(AP): SharedGameplayPS cast failed");
    return false;
  }

  let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
  sharedPS.m_betterNetrunningAPBreachFailedTimestamp = currentTime;
  BNDebug("BreachPenalty", "Recorded AP breach failure timestamp: " + ToString(currentTime));
  return true;
}

private static func RecordBreachFailureTimestamp(
  npcPS: ref<ScriptedPuppetPS>,
  gameInstance: GameInstance
) -> Bool {
  if !IsDefined(npcPS) {
    BNDebug("BreachPenalty", "RecordBreachFailureTimestamp(NPC): ScriptedPuppetPS not defined");
    return false;
  }

  let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
  npcPS.m_betterNetrunningNPCBreachFailedTimestamp = currentTime;
  BNDebug("BreachPenalty", "Recorded NPC breach failure timestamp: " + ToString(currentTime));
  return true;
}

private static func RecordBreachFailureByType(
  player: ref<PlayerPuppet>,
  devicePS: ref<ScriptableDeviceComponentPS>,
  failedPosition: Vector4,
  gameInstance: GameInstance,
  breachType: BreachType
) -> Void {

  if Equals(breachType, BreachType.RemoteBreach) {
    RemoteBreachLockSystem.RecordRemoteBreachFailure(player, devicePS, failedPosition, gameInstance);
    return;
  }

  if Equals(breachType, BreachType.AccessPoint) || Equals(breachType, BreachType.UnconsciousNPC) {
    BNError("BreachPenalty", "AP/NPC breach incorrectly routed to position recording");
    return;
  }

  BNWarn("BreachPenalty", "Unknown breach type - fallback to RemoteBreach recording");
  RemoteBreachLockSystem.RecordRemoteBreachFailure(player, devicePS, failedPosition, gameInstance);
}

private static func TriggerTraceAttempt(
  player: ref<PlayerPuppet>,
  gameInstance: GameInstance
) -> Void {

  if !IsDefined(player) {
    BNError("BreachPenalty", "Player not found, cannot trigger trace");
    return;
  }

  if player.IsBeingRevealed() {
    BNDebug("BreachPenalty", "Player already being traced, skipping duplicate trace");
    return;
  }

  if player.IsInCombat() {
    BNDebug("BreachPenalty", "Player in combat, trace would be interrupted immediately - skipping");
    return;
  }

  let searchRadius: Float = GetRadialBreachRange(gameInstance);
  let netrunner: wref<NPCPuppet> = TracePositionOverhaulGating.FindNearestValidTraceSource(player, gameInstance, searchRadius);
  if IsDefined(netrunner) {

    let result: Bool = NPCPuppet.RevealPlayerPositionIfNeeded(
      netrunner,
      player.GetEntityID(),
      false
    );
    if result {
      BNInfo("BreachPenalty", "Trace initiated via real netrunner (ID: " + ToString(netrunner.GetEntityID()) + ")");
      return;
    }
  }

  BNDebug("BreachPenalty", "No netrunner found - trace penalty skipped");
}

@wrapMethod(ScriptableDeviceComponentPS)
public func SetHasPersonalLinkSlot(isPersonalLinkSlotPresent: Bool) -> Void {

  if !isPersonalLinkSlotPresent {
    wrappedMethod(isPersonalLinkSlotPresent);
    return;
  }

  let isLocked: Bool = BreachLockUtils.IsJackInLockedByAPBreachFailure(this);
  BNDebug("BreachPenalty", "SetHasPersonalLinkSlot(true) called - Lock status: " + ToString(isLocked));

  if isLocked {

    wrappedMethod(false);
    BNInfo("BreachPenalty", "Prevented JackIn restoration on load (device locked by AP breach failure)");
    return;
  }

  wrappedMethod(isPersonalLinkSlotPresent);
}
