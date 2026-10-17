
module BetterNetrunning.Devices
import BetterNetrunning.Logging.*

import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Breach.*

@addMethod(ScriptableDeviceComponentPS)
public final func IsBreached() -> Bool {
  let sharedPS: ref<SharedGameplayPS> = this;
  if !IsDefined(sharedPS) {
    return false;
  }

  let gameInstance: GameInstance = this.GetGameInstance();

  if BreachStatusUtils.IsBreachedWithExpiration(sharedPS.m_betterNetrunningUnlockTimestampBasic, gameInstance) {
    return true;
  }

  if BreachStatusUtils.IsBreachedWithExpiration(sharedPS.m_betterNetrunningUnlockTimestampCameras, gameInstance) {
    return true;
  }

  if BreachStatusUtils.IsBreachedWithExpiration(sharedPS.m_betterNetrunningUnlockTimestampTurrets, gameInstance) {
    return true;
  }

  if BreachStatusUtils.IsBreachedWithExpiration(sharedPS.m_betterNetrunningUnlockTimestampNPCs, gameInstance) {
    return true;
  }

  return false;
}

@addMethod(ScriptableDeviceComponentPS)
public final func SetActionsInactiveUnbreached(actions: script_ref<array<ref<DeviceAction>>>) -> Void {

  let deviceInfo: DeviceBreachInfo = this.GetDeviceBreachInfo();

  let permissions: DevicePermissions = this.CalculateDevicePermissions(deviceInfo);

  this.ApplyPermissionsToActions(actions, deviceInfo, permissions);
}

@addMethod(ScriptableDeviceComponentPS)
private final func GetDeviceBreachInfo() -> DeviceBreachInfo {
  let info: DeviceBreachInfo;
  info.isCamera = DaemonFilterUtils.IsCamera(this);
  info.isTurret = DaemonFilterUtils.IsTurret(this);

  let sharedPS: ref<SharedGameplayPS> = this;
  if IsDefined(sharedPS) {
    let apControllers: array<ref<AccessPointControllerPS>> = sharedPS.GetAccessPoints();
    info.isStandaloneDevice = ArraySize(apControllers) == 0;
  }

  let isVehicle: Bool = IsDefined(this as VehicleComponentPS);
  if isVehicle {
    BNDebug("SetActionsInactiveUnbreached", "Vehicle detected - breachedBasic: " + ToString(BreachStatusUtils.IsBasicBreached(sharedPS)));
  }

  return info;
}

@addMethod(ScriptableDeviceComponentPS)
private final func CalculateDevicePermissions(deviceInfo: DeviceBreachInfo) -> DevicePermissions {
  let permissions: DevicePermissions;
  let sharedPS: ref<SharedGameplayPS> = this;

  permissions.allowCameras = BreachStatusUtils.IsCamerasBreached(sharedPS);
  permissions.allowTurrets = BreachStatusUtils.IsTurretsBreached(sharedPS);
  permissions.allowBasicDevices = BreachStatusUtils.IsBasicBreached(sharedPS);

  return permissions;
}

@addMethod(ScriptableDeviceComponentPS)
private final func ApplyPermissionsToActions(actions: script_ref<array<ref<DeviceAction>>>, deviceInfo: DeviceBreachInfo, permissions: DevicePermissions) -> Void {
  let i: Int32 = 0;
  while i < ArraySize(Deref(actions)) {
    let sAction: ref<ScriptableDeviceAction> = (Deref(actions)[i] as ScriptableDeviceAction);

    if IsDefined(sAction) {
      if !this.ShouldAllowAction(sAction, deviceInfo.isCamera, deviceInfo.isTurret, permissions.allowCameras, permissions.allowTurrets, permissions.allowBasicDevices) {
        sAction.SetInactive();
        sAction.SetInactiveReason(LocKeyToString(BNConstants.LOCKEY_QUICKHACKS_LOCKED()));
      } else {

        sAction.SetActive();
      }
    }

    i += 1;
  }
}

@addMethod(ScriptableDeviceComponentPS)
private final func ShouldAllowAction(action: ref<ScriptableDeviceAction>, isCamera: Bool, isTurret: Bool, allowCameras: Bool, allowTurrets: Bool, allowBasicDevices: Bool) -> Bool {

  if isCamera && allowCameras {
    return true;
  }
  if isTurret && allowTurrets {
    return true;
  }
  if !isCamera && !isTurret && allowBasicDevices {
    return true;
  }

  return false;
}

@addMethod(ScriptableDeviceComponentPS)
private final func RemoveVanillaRemoteBreachActions(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {
  let i: Int32 = ArraySize(Deref(outActions)) - 1;

  while i >= 0 {
    let action: ref<DeviceAction> = Deref(outActions)[i];

    if IsDefined(action as RemoteBreach) {
      ArrayErase(Deref(outActions), i);
      BNDebug("RemoveVanillaRemoteBreachActions", "Removed vanilla RemoteBreach");
    }

    i -= 1;
  }
}

@wrapMethod(ScriptableDeviceComponentPS)
protected final func FinalizeGetQuickHackActions(outActions: script_ref<array<ref<DeviceAction>>>, const context: script_ref<GetActionsContext>) -> Void {

  if !this.ShouldProcessQuickHackActions(outActions) {
    return;
  }

  wrappedMethod(outActions, context);

  this.ApplyBetterNetrunningDeviceFilters(outActions);
}
