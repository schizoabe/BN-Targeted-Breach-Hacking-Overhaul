

module BetterNetrunning.Marking

import BetterNetrunning.Core.*
import BetterNetrunning.Network.*
import BetterNetrunning.Logging.*

@wrapMethod(Device)
protected cb func OnActionPing(evt: ref<PingDevice>) -> Bool {
  evt.SetShouldForward(false);
  let result: Bool = wrappedMethod(evt);

  let gi: GameInstance = this.GetGame();
  let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
    .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if !IsDefined(mss) { return result; }

  let targetType: TargetType = DeviceTypeUtils.GetDeviceTypeFromEntity(this);
  let subnetType: MarkedSubnetType;
  if Equals(targetType, TargetType.Camera) {
    subnetType = MarkedSubnetType.Camera;
  } else if Equals(targetType, TargetType.Turret) {
    subnetType = MarkedSubnetType.Defense;
  } else {
    subnetType = MarkedSubnetType.Root;
  }

  let logSys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;

  if mss.IsMark(this.GetEntityID(), subnetType) {
    mss.RemoveMarkAny(this.GetEntityID());
    if IsDefined(logSys) { logSys.Refresh(); }
    return result;
  }

  let sharedPS: ref<SharedGameplayPS> = this.GetDevicePS() as SharedGameplayPS;
  if IsDefined(sharedPS) && sharedPS.m_bnIceHitsRequired == 0 {
    sharedPS.m_bnIceHitsRequired = NetworkStateUtils.GetHeatScaledICEHits(gi);
    BNInfo("PingMark", "Device ICE initialized: " + ToString(sharedPS.m_bnIceHitsRequired) + " hits required");
  }
  let iceHitsRequired: Int32 = IsDefined(sharedPS) ? sharedPS.m_bnIceHitsRequired : 0;

  let displayName: String = GetLocalizedText(this.GetDisplayName());
  if Equals(displayName, s"") {
    displayName = DeviceTypeUtils.DeviceTypeToString(targetType);
  }

  mss.AddMarkNamed(this.GetEntityID(), subnetType, displayName, iceHitsRequired);
  BNInfo("PingMark", "Device ping: " + displayName + " (" + DeviceTypeUtils.DeviceTypeToString(targetType) + ") ICE=" + ToString(iceHitsRequired));

  if IsDefined(logSys) { logSys.ShowIfNew(); }

  return result;
}

@addMethod(VehicleObject)
protected cb func OnActionPing(evt: ref<PingDevice>) -> Bool {
  let gi: GameInstance = this.GetGame();
  let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
    .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if !IsDefined(mss) { return false; }

  let logSys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;

  if mss.IsMark(this.GetEntityID(), MarkedSubnetType.Root) {
    mss.RemoveMarkAny(this.GetEntityID());
    if IsDefined(logSys) { logSys.Refresh(); }
    return false;
  }

  mss.AddMarkFromEntity(this.GetEntityID(), MarkedSubnetType.Root);
  BNInfo("PingMark", "Vehicle ping: " + GetLocalizedText(this.GetDisplayName()));

  if IsDefined(logSys) { logSys.ShowIfNew(); }

  return false;
}

func BNUnmarkEntity(gi: GameInstance, entityID: EntityID, reason: String) -> Void {
  let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
    .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if !IsDefined(mss) { return; }
  mss.RemoveMarkAny(entityID);
  BNInfo("PingMark", "Unmarked entity — " + reason);

  let logSys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(gi)
    .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
  if IsDefined(logSys) { logSys.Refresh(); }
}

@wrapMethod(ScriptedPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  BNUnmarkEntity(this.GetGame(), this.GetEntityID(), "NPC death");
  return result;
}

@wrapMethod(ScriptedPuppet)
protected cb func OnDefeated(evt: ref<DefeatedEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  BNUnmarkEntity(this.GetGame(), this.GetEntityID(), "NPC defeated");
  return result;
}

@wrapMethod(Device)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  BNUnmarkEntity(this.GetGame(), this.GetEntityID(), "Device destroyed");
  return result;
}

@addMethod(VehicleObject)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  BNUnmarkEntity(this.GetGame(), this.GetEntityID(), "Vehicle destroyed");
  return false;
}

