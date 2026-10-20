
module BetterNetrunning.Integration

import BetterNetrunning.Logging.*
import BetterNetrunningConfig.*

@addField(ScriptableDeviceComponentPS)
public let m_isSJKIStandaloneDevice: Bool;

private func SJKI_IsTargetDevice(name: String) -> Bool {
  return
    Equals(name, "Computer")                                 ||
    Equals(name, "Spontaneous Craving Satisfaction Machine") ||
    Equals(name, "Weapon Vending Machine")                   ||
    Equals(name, "Confession Booth")                         ||
    Equals(name, "Ice Machine")                              ||
    Equals(name, "Arcade Machine")                           ||
    Equals(name, "Pachinko Machine")                         ||
    Equals(name, "Terminal")                                 ||
    Equals(name, "Laptop")                                   ||
    Equals(name, "Server");
}

private func SJKI_OpenBreachHUD(ps: ref<ScriptableDeviceComponentPS>) -> Void {
  let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(ps.GetGameInstance())
                               .Get(GetAllBlackboardDefs().NetworkBlackboard);
  let minigameDef: TweakDBID = ps.GetMinigameDefinition();
  bb.SetInt     (GetAllBlackboardDefs().NetworkBlackboard.DevicesCount,  1);
  bb.SetBool    (GetAllBlackboardDefs().NetworkBlackboard.OfficerBreach, false);
  bb.SetBool    (GetAllBlackboardDefs().NetworkBlackboard.RemoteBreach,  false);
  bb.SetInt     (GetAllBlackboardDefs().NetworkBlackboard.Attempt,       ps.m_minigameAttempt);
  bb.SetEntityID(GetAllBlackboardDefs().NetworkBlackboard.DeviceID,      ps.GetMyEntityID());
  bb.SetVariant(GetAllBlackboardDefs().NetworkBlackboard.MinigameDef,  ToVariant(minigameDef));
  bb.SetString  (GetAllBlackboardDefs().NetworkBlackboard.NetworkName,   ps.GetDeviceName(), true);
}

@replaceMethod(ScriptableDeviceComponentPS)
protected const func ShouldExposePersonalLinkAction() -> Bool {

  if this.IsPersonalLinkConnecting()                                                                      { return false; }
  if TDBID.IsValid(this.m_personalLinkCustomInteraction) && this.IsPersonalLinkConnected()                { return false; }
  if Equals(this.m_personalLinkStatus, EPersonalLinkConnectionStatus.CONNECTED) || this.m_personalLinkForced { return true; }
  if this.IsHackingSkillCheckActive()                                                                     { return false; }
  if this.IsGlitching() || this.IsDistracting()                                                           { return false; }

  if BetterNetrunningSettings.HackThePlanetEnabled() {
    let accessPoint: ref<AccessPointControllerPS> = this as AccessPointControllerPS;
    if IsDefined(accessPoint) {
      this.m_hasNetworkBackdoor = true;
      this.SetHasPersonalLinkSlot(true);
    };
  }

  if this.HasNetworkBackdoor() {
    if BetterNetrunningSettings.HackThePlanetReinitializeAccessPoints() && this.IsON() {
      this.SetMinigameState(HackingMinigameState.Unknown);
      this.TurnAuthorizationModuleON();
      this.m_skillCheckContainer.GetHackingSlot().SetIsPassed(false);
      this.m_skillCheckContainer.GetHackingSlot().CheckPerformed();
      this.ResolveOtherSkillchecks();
    }
    return !this.WasHackingMinigameSucceeded();
  }

  if BetterNetrunningSettings.HackThePlanetEnabled() {
    let disabledAP: ref<AccessPointControllerPS> = this as AccessPointControllerPS;
    if IsDefined(disabledAP) {
      BNDebug("HackThePlanet", "ShouldExposePersonalLinkAction: bypassing DISABLED/UNPOWERED gate on access point ["
        + GetLocalizedText(this.GetDeviceName()) + "]");
      return !this.WasHackingMinigameSucceeded();
    };
  }

  if BetterNetrunningSettings.HackThePlanetEnabled() {
    let isJackable: Bool = false;
    let action: ref<ScriptableDeviceAction>;
    let actions: array<ref<DeviceAction>>;
    let context: GetActionsContext;
    this.GetQuickHackActions(actions, context);
    let i: Int32 = 0;
    while i < ArraySize(actions) {
      action = actions[i] as ScriptableDeviceAction;
      if IsDefined(action) && action.GetObjectActionID() == t"Items.PingDevice" {
        isJackable = true;
      }
      i += 1;
    }
    if isJackable {
      this.m_hasNetworkBackdoor = true;
      this.SetHasPersonalLinkSlot(true);
      return !this.WasHackingMinigameSucceeded();
    }
  }

  if !BetterNetrunningSettings.HackThePlanetEnabled() { return false; }

  let standaloneName: String = GetLocalizedText(this.GetDeviceName());
  if SJKI_IsTargetDevice(standaloneName) && this.IsON() {
    this.m_hasNetworkBackdoor = true;
    this.SetHasPersonalLinkSlot(true);
    this.SetMinigameState(HackingMinigameState.Unknown);
    this.TurnAuthorizationModuleON();
    this.m_skillCheckContainer.GetHackingSlot().SetIsPassed(false);
    this.m_skillCheckContainer.GetHackingSlot().CheckPerformed();
    if !this.m_isSJKIStandaloneDevice {
      this.m_isSJKIStandaloneDevice = true;
      BNDebug("HackThePlanet", "ShouldExposePersonalLinkAction: arming [" + standaloneName + "]");
    }
    return true;
  }

  return false;
}

@replaceMethod(ScriptableDeviceComponentPS)
protected func ResolvePersonalLinkConnection(evt: ref<TogglePersonalLink>, abortOperations: Bool) -> Void {

  let isStandalone: Bool = this.m_isSJKIStandaloneDevice;

  BNDebug("HackThePlanet", "ResolvePersonalLinkConnection: isStandalone=" + ToString(isStandalone)
    + " abort=" + ToString(abortOperations)
    + " linkStatus=" + ToString(EnumInt(this.m_personalLinkStatus)));

  if isStandalone {
    if abortOperations {
      BNDebug("HackThePlanet", "ResolvePersonalLinkConnection: abort — clearing flag");
      this.m_isSJKIStandaloneDevice = false;
      return;
    }
    if Equals(this.m_personalLinkStatus, EPersonalLinkConnectionStatus.CONNECTED) {
      BNDebug("HackThePlanet", "ResolvePersonalLinkConnection: opening HUD");
      SJKI_OpenBreachHUD(this);
    } else {
      BNDebug("HackThePlanet", "ResolvePersonalLinkConnection: not CONNECTED — no action");
    }
    return;
  }

  let hasNetworkBackdoor: Bool = this.HasNetworkBackdoor();
  if Equals(this.m_personalLinkStatus, EPersonalLinkConnectionStatus.CONNECTING) { return; }
  if Equals(this.m_personalLinkStatus, EPersonalLinkConnectionStatus.CONNECTED) {
    if this.m_shouldSkipNetrunnerMinigame || !hasNetworkBackdoor {
      this.SetMinigameState(HackingMinigameState.Succeeded);
    }
    if hasNetworkBackdoor && !this.WasHackingMinigameSucceeded() {
      let dive: ref<ToggleNetrunnerDive> = this.ActionToggleNetrunnerDive(abortOperations, evt.m_shouldSkipMiniGame);
      dive.SetExecutor(evt.GetExecutor());
      this.ExecutePSAction(dive, evt.GetInteractionLayer());
    } else {
      this.ResolveOtherSkillchecks();
    }
  } else {
    if hasNetworkBackdoor {
      let dive: ref<ToggleNetrunnerDive> = this.ActionToggleNetrunnerDive(true);
      dive.SetExecutor(evt.GetExecutor());
      this.ExecutePSAction(dive, evt.GetInteractionLayer());
    }
  }
}

@wrapMethod(ScriptableDeviceComponentPS)
public func FinalizeNetrunnerDive(state: HackingMinigameState) -> Void {

  BNDebug("HackThePlanet", "FinalizeNetrunnerDive: isStandalone=" + ToString(this.m_isSJKIStandaloneDevice)
    + " state=" + ToString(EnumInt(state)));

  if !this.m_isSJKIStandaloneDevice {
    wrappedMethod(state);
    return;
  }

  let gi: GameInstance = this.GetGameInstance();

  if Equals(state, HackingMinigameState.Succeeded) {

    this.BN_SJKIHandleSuccess(gi);
  } else if Equals(state, HackingMinigameState.Failed) {
    let currentTime: Float = GameInstance.GetTimeSystem(gi).GetGameTimeStamp();
    this.m_betterNetrunningAPBreachFailedTimestamp = currentTime;
    BNDebug("HackThePlanet", "FinalizeNetrunnerDive: stamped AP failure timestamp=" + ToString(currentTime));
  }

  this.m_isSJKIStandaloneDevice = false;
  this.SetMinigameState(HackingMinigameState.Unknown);
  let player: ref<GameObject> = this.GetPlayerMainObject();
  let jackOut: ref<ToggleNetrunnerDive> = this.ActionToggleNetrunnerDive(true);
  jackOut.SetExecutor(player);
  this.ExecutePSAction(jackOut);
  BNDebug("HackThePlanet", "FinalizeNetrunnerDive: done state=" + ToString(EnumInt(state)));
}

@wrapMethod(ScriptableDeviceComponentPS)
public func SetHasPersonalLinkSlot(isPersonalLinkSlotPresent: Bool) -> Void {
  if !isPersonalLinkSlotPresent {
    let ownerDevice: ref<Device> = this.GetOwnerEntityWeak() as Device;
    let isStandalone: Bool = this.m_isSJKIStandaloneDevice
      || (IsDefined(ownerDevice) && SJKI_IsTargetDevice(GetLocalizedText(ownerDevice.GetDeviceName())));
    if isStandalone {
      BNDebug("HackThePlanet", "SetHasPersonalLinkSlot: blocked disable on standalone");
      return;
    }
  }
  wrappedMethod(isPersonalLinkSlotPresent);
}
