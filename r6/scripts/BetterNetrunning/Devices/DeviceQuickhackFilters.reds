





















module BetterNetrunning.Devices
import BetterNetrunning.Logging.*

import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Systems.*
import BetterNetrunning.Breach.*
import BetterNetrunning.RemoteBreach.Core.*
import BetterNetrunning.RemoteBreach.Actions.*
import BetterNetrunning.RadialUnlock.*







@if(ModuleExists("HackingExtensions"))
@addMethod(ScriptableDeviceComponentPS)
private final func ApplyBetterNetrunningDeviceFilters(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {

  this.ReplaceVanillaRemoteBreachWithCustom(outActions);


  this.RemoveRemoteBreachIfUnlocked(outActions);
}


@if(!ModuleExists("HackingExtensions"))
@addMethod(ScriptableDeviceComponentPS)
private final func ApplyBetterNetrunningDeviceFilters(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {

  this.RemoveRemoteBreachIfUnlocked(outActions);
}


@if(ModuleExists("HackingExtensions"))
@addMethod(ScriptableDeviceComponentPS)
private final func ReplaceVanillaRemoteBreachWithCustom(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {

  if this.IsBreached() {
    this.RemoveVanillaRemoteBreachActions(outActions);
    return;
  }


  if BreachLockUtils.IsDeviceLockedByRemoteBreachFailure(this) {


    return;
  }


  let actionCountBefore: Int32 = ArraySize(Deref(outActions));
  this.RemoveVanillaRemoteBreachActions(outActions);
  let actionCountAfter: Int32 = ArraySize(Deref(outActions));
  let vanillaRemoteBreachFound: Bool = actionCountBefore > actionCountAfter;


  if vanillaRemoteBreachFound && this.IsConnectedToBackdoorDevice() {
    let beforeSize: Int32 = ArraySize(Deref(outActions));
    BNTrace("ReplaceVanillaRemoteBreachWithCustom", "Before TryAddCustomRemoteBreach: " + IntToString(beforeSize) + " actions");

    this.TryAddCustomRemoteBreach(outActions);

    let afterSize: Int32 = ArraySize(Deref(outActions));
    BNTrace("ReplaceVanillaRemoteBreachWithCustom", "After TryAddCustomRemoteBreach: " + IntToString(afterSize) + " actions");

    if afterSize > beforeSize {
      BNTrace("ReplaceVanillaRemoteBreachWithCustom", "Added BetterNetrunning RemoteBreach (RemoteBreachAction/VehicleRemoteBreachAction/DeviceRemoteBreachAction)");
    } else {
      BNTrace("ReplaceVanillaRemoteBreachWithCustom", "BetterNetrunning RemoteBreach NOT added (locked or other reason)");
    }
  }
}


@if(ModuleExists("HackingExtensions"))
@addMethod(ScriptableDeviceComponentPS)
private final func RemoveRemoteBreachIfUnlocked(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {

  if !this.IsBreached() {
    return; // Device not yet breached, keep RemoteBreach action
  }


  let i: Int32 = ArraySize(Deref(outActions)) - 1;
  while i >= 0 {
    let action: ref<DeviceAction> = Deref(outActions)[i];

    if IsDefined(action as RemoteBreach) {
      ArrayErase(Deref(outActions), i);
    } else {
      let customBreachAction: ref<CustomAccessBreach> = action as CustomAccessBreach;
      if IsDefined(customBreachAction) {
        ArrayErase(Deref(outActions), i);
        BNTrace("RemoveRemoteBreachIfUnlocked", "Removed CustomAccessBreach (device already breached)");
      }
    }

    i -= 1;
  }
}


@if(!ModuleExists("HackingExtensions"))
@addMethod(ScriptableDeviceComponentPS)
private final func RemoveRemoteBreachIfUnlocked(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {

  if !this.IsBreached() {
    return; // Device not yet breached, keep RemoteBreach action
  }


  let i: Int32 = ArraySize(Deref(outActions)) - 1;
  while i >= 0 {
    let action: ref<DeviceAction> = Deref(outActions)[i];


    if IsDefined(action as RemoteBreach) {
      ArrayErase(Deref(outActions), i);
    }

    i -= 1;
  }
}




@if(ModuleExists("HackingExtensions"))
@addMethod(ScriptableDeviceComponentPS)
private final func TryAddMissingCustomRemoteBreachWrapper(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {
  this.TryAddMissingCustomRemoteBreach(outActions);
}


@if(!ModuleExists("HackingExtensions"))
@addMethod(ScriptableDeviceComponentPS)
private final func TryAddMissingCustomRemoteBreachWrapper(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {

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


@if(ModuleExists("HackingExtensions"))
@wrapMethod(ScriptableDeviceComponentPS)
protected final func MarkActionsAsQuickHacks(actionsToMark: script_ref<array<ref<DeviceAction>>>) -> Void {

  wrappedMethod(actionsToMark);


  let i: Int32 = 0;
  while i < ArraySize(Deref(actionsToMark)) {


    let customBreachAction: ref<CustomAccessBreach> = Deref(actionsToMark)[i] as CustomAccessBreach;
    if IsDefined(customBreachAction) {

      customBreachAction.SetAsQuickHack();
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



  this.RemoveCustomRemoteBreachIfUnlocked(outActions);
}


