

module BetterNetrunning.Devices
import BetterNetrunning.Logging.*

import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Systems.*
import BetterNetrunning.Breach.*
import BetterNetrunning.RemoteBreach.Core.*
import BetterNetrunning.RadialUnlock.*

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
  let gameInstance: GameInstance = this.GetGameInstance();
  let sharedPS: ref<SharedGameplayPS> = this;

  permissions.allowCameras = BreachStatusUtils.IsCamerasBreached(sharedPS) || ShouldUnlockHackDevice(gameInstance, BetterNetrunningSettings.AlwaysCameras(), BetterNetrunningSettings.ProgressionCyberdeckCameras(), BetterNetrunningSettings.ProgressionIntelligenceCameras());
  permissions.allowTurrets = BreachStatusUtils.IsTurretsBreached(sharedPS) || ShouldUnlockHackDevice(gameInstance, BetterNetrunningSettings.AlwaysTurrets(), BetterNetrunningSettings.ProgressionCyberdeckTurrets(), BetterNetrunningSettings.ProgressionIntelligenceTurrets());
  permissions.allowBasicDevices = BreachStatusUtils.IsBasicBreached(sharedPS) || ShouldUnlockHackDevice(gameInstance, BetterNetrunningSettings.AlwaysBasicDevices(), BetterNetrunningSettings.ProgressionCyberdeckBasicDevices(), BetterNetrunningSettings.ProgressionIntelligenceBasicDevices());

  permissions.allowPing = BetterNetrunningSettings.AlwaysAllowPing();
  permissions.allowDistraction = BetterNetrunningSettings.AlwaysAllowDistract();

  return permissions;
}

@addMethod(ScriptableDeviceComponentPS)
private final func ApplyPermissionsToActions(actions: script_ref<array<ref<DeviceAction>>>, deviceInfo: DeviceBreachInfo, permissions: DevicePermissions) -> Void {

  let isRemoteBreachLocked: Bool = BreachLockUtils.IsDeviceLockedByRemoteBreachFailure(this);

  RemoteBreachRAMUtils.CheckAndLockRemoteBreachRAM(actions);

  let i: Int32 = 0;
  while i < ArraySize(Deref(actions)) {
    let sAction: ref<ScriptableDeviceAction> = (Deref(actions)[i] as ScriptableDeviceAction);

    if IsDefined(sAction) {
      if !this.ShouldAllowAction(sAction, deviceInfo.isCamera, deviceInfo.isTurret, permissions.allowCameras, permissions.allowTurrets, permissions.allowBasicDevices, permissions.allowPing, permissions.allowDistraction) {
        sAction.SetInactive();

        if isRemoteBreachLocked {
          sAction.SetInactiveReason(BNConstants.LOCKEY_NO_NETWORK_ACCESS());
        } else {
          sAction.SetInactiveReason(LocKeyToString(BNConstants.LOCKEY_QUICKHACKS_LOCKED()));
        }
      } else {

        sAction.SetActive();
      }
    }

    i += 1;
  }
}

@addMethod(ScriptableDeviceComponentPS)
private final func ShouldAllowAction(action: ref<ScriptableDeviceAction>, isCamera: Bool, isTurret: Bool, allowCameras: Bool, allowTurrets: Bool, allowBasicDevices: Bool, allowPing: Bool, allowDistraction: Bool) -> Bool {
  let className: CName = action.GetClassName();

  if IsCustomRemoteBreachAction(className) {
    return true;
  }

  if Equals(className, BNConstants.ACTION_PING_DEVICE()) && allowPing {
    return true;
  }
  if Equals(className, BNConstants.ACTION_DISTRACTION()) && allowDistraction {
    return true;
  }

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
      BNDebug("RemoveVanillaRemoteBreachActions", "Removed vanilla RemoteBreach (device already breached)");
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

