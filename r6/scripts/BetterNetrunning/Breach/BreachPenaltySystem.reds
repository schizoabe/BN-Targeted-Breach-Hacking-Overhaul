




















module BetterNetrunning.Breach
import BetterNetrunning.Logging.*
import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Integration.*
import BetterNetrunning.RemoteBreach.Common.*
import BetterNetrunning.RemoteBreach.Core.*
import BetterNetrunning.Network.*


public enum BreachType {
  Unknown = 0,
  AccessPoint = 1,
  UnconsciousNPC = 2,
  RemoteBreach = 3
}


@wrapMethod(ScriptableDeviceComponentPS)
public func FinalizeNetrunnerDive(state: HackingMinigameState) -> Void {

  if NotEquals(state, HackingMinigameState.Failed) {
    wrappedMethod(state);
    return;
  }


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
    false  // Not looping
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

