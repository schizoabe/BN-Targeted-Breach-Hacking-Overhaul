
module BetterNetrunning.Devices
import BetterNetrunning.Logging.*

import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Systems.*
import BetterNetrunning.Breach.*

@addMethod(ScriptableDeviceComponentPS)
private final func ApplyBetterNetrunningDeviceFilters(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {
  this.RemoveVanillaRemoteBreachActions(outActions);
}

@addMethod(ScriptableDeviceComponentPS)
private final func ShouldProcessQuickHackActions(outActions: script_ref<array<ref<DeviceAction>>>) -> Bool {

  if NotEquals(this.GetDurabilityState(), EDeviceDurabilityState.NOMINAL) {
    return false;
  }

  if this.m_disableQuickHacks {
    if ArraySize(Deref(outActions)) > 0 {
      ArrayClear(Deref(outActions));
    }
    return false;
  }
  return true;
}

@wrapMethod(ScriptableDeviceComponentPS)
protected final func MarkActionsAsQuickHacks(actionsToMark: script_ref<array<ref<DeviceAction>>>) -> Void {

  wrappedMethod(actionsToMark);

  let i: Int32 = 0;
  while i < ArraySize(Deref(actionsToMark)) {
    let puppetBreachAction: ref<PuppetAction> = Deref(actionsToMark)[i] as PuppetAction;
    if IsDefined(puppetBreachAction) {
      puppetBreachAction.SetAsQuickHack();
    }

    i += 1;
  }
}

@addMethod(ScriptableDeviceComponentPS)
private final func ApplyCommonQuickHackRestrictions(outActions: script_ref<array<ref<DeviceAction>>>, const context: script_ref<GetActionsContext>) -> Void {

  if this.IsUnpowered() {
    ScriptableDeviceComponentPS.SetActionsInactiveAll(outActions, BNConstants.LOCKEY_NOT_POWERED());
  }

  this.EvaluateActionsRPGAvailabilty(outActions, context);
  this.SetActionIllegality(outActions, this.m_illegalActions.quickHacks);
  this.MarkActionsAsQuickHacks(outActions);
  this.SetActionsQuickHacksExecutioner(outActions);
}

