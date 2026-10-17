module BetterNetrunning.Devices

import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Systems.*
import BetterNetrunning.Breach.*

@replaceMethod(ScriptableDeviceComponentPS)
public final func GetRemoteActions(out outActions: array<ref<DeviceAction>>, const context: script_ref<GetActionsContext>) -> Void {

  if this.m_disableQuickHacks || this.IsDisabled() {
    return;
  }

  this.GetQuickHackActions(outActions, context);

  let i: Int32 = ArraySize(outActions) - 1;
  while i >= 0 {
    let action: ref<DeviceAction> = outActions[i];
    if IsDefined(action) && Equals(action.actionName, BNConstants.ACTION_REMOTE_BREACH()) {
      ArrayErase(outActions, i);
    }
    i -= 1;
  }

  if this.IsLockedViaSequencer() {
    ScriptableDeviceComponentPS.SetActionsInactiveAll(outActions, LocKeyToString(BNConstants.LOCKEY_QUICKHACKS_LOCKED()));
  } else if !BetterNetrunningSettings.EnableClassicMode() {

    this.SetActionsInactiveUnbreached(outActions);
  }
}

@replaceMethod(Device)
public const func CanRevealRemoteActionsWheel() -> Bool {
  let ps: ref<ScriptableDeviceComponentPS> = this.GetDevicePS();
  if !IsDefined(ps) { return false; }
  return this.ShouldRegisterToHUD() && !ps.IsDisabled() && ps.HasPlaystyle(EPlaystyle.NETRUNNER);
}
