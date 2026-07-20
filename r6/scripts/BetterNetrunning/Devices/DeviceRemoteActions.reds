module BetterNetrunning.Devices

import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Systems.*
import BetterNetrunning.Breach.*
import BetterNetrunning.RemoteBreach.Core.*
import BetterNetrunning.RemoteBreach.Actions.*
import BetterNetrunning.RadialUnlock.*

@replaceMethod(ScriptableDeviceComponentPS)
public final func GetRemoteActions(out outActions: array<ref<DeviceAction>>, const context: script_ref<GetActionsContext>) -> Void {

  if this.m_disableQuickHacks || this.IsDisabled() {
    return;
  }

  this.GetQuickHackActions(outActions, context);

  let i: Int32 = ArraySize(outActions) - 1;
  let hasCustomRemoteBreach: Bool = false;

  while i >= 0 {
    let action: ref<DeviceAction> = outActions[i];

    if IsDefined(action) && Equals(action.actionName, BNConstants.ACTION_REMOTE_BREACH()) {
      let className: CName = action.GetClassName();

      if IsCustomRemoteBreachAction(className) {
        hasCustomRemoteBreach = true;
      } else {
        ArrayErase(outActions, i);
      }
    }
    i -= 1;
  }

  if !hasCustomRemoteBreach && !BetterNetrunningSettings.UnlockIfNoAccessPoint() {
    this.TryAddMissingCustomRemoteBreachWrapper(outActions);
  }

  this.RemoveCustomRemoteBreachIfUnlocked(outActions);

  let sharedPS: ref<SharedGameplayPS> = this;
  let hasAccessPoint: Bool = true;
  let apCount: Int32 = 0;
  if IsDefined(sharedPS) {
    let apControllers: array<ref<AccessPointControllerPS>> = sharedPS.GetAccessPoints();
    apCount = ArraySize(apControllers);
    hasAccessPoint = apCount > 0;
  }

  let isUnsecuredNetwork: Bool = !hasAccessPoint && BetterNetrunningSettings.UnlockIfNoAccessPoint();

  let isRemoteBreachLocked: Bool = BreachLockUtils.IsDeviceLockedByRemoteBreachFailure(this);

  if this.IsLockedViaSequencer() {

    if isRemoteBreachLocked {
      ScriptableDeviceComponentPS.SetActionsInactiveAll(outActions, BNConstants.LOCKEY_NO_NETWORK_ACCESS(), BNConstants.ACTION_REMOTE_BREACH());
    } else {
      ScriptableDeviceComponentPS.SetActionsInactiveAll(outActions, LocKeyToString(BNConstants.LOCKEY_QUICKHACKS_LOCKED()), BNConstants.ACTION_REMOTE_BREACH());
    }

    RemoteBreachRAMUtils.CheckAndLockRemoteBreachRAM(outActions);
  } else if !BetterNetrunningSettings.EnableClassicMode() && !isUnsecuredNetwork {

    this.SetActionsInactiveUnbreached(outActions);
  }

}

@replaceMethod(Device)
public const func CanRevealRemoteActionsWheel() -> Bool {
  let ps: ref<ScriptableDeviceComponentPS> = this.GetDevicePS();
  if !IsDefined(ps) { return false; }
  return this.ShouldRegisterToHUD() && !ps.IsDisabled() && ps.HasPlaystyle(EPlaystyle.NETRUNNER);
}

