


















module BetterNetrunning.Devices


@wrapMethod(DoorControllerPS)
protected func ExposeQuickHakcsIfNotConnnectedToAP() -> Bool {
  let vanilla: Bool = wrappedMethod();
  if !vanilla {
    return true;
  }
  return vanilla;
}













@wrapMethod(ScriptableDeviceComponentPS)
protected final func FinalizeGetQuickHackActions(outActions: script_ref<array<ref<DeviceAction>>>, const context: script_ref<GetActionsContext>) -> Void {
  if Equals(this.GetDurabilityState(), EDeviceDurabilityState.NOMINAL)
      && !this.IsConnectedToBackdoorDevice()
      && !this.HasNetworkBackdoor() {
    let pingAction: ref<PingDevice> = new PingDevice();
    pingAction.clearanceLevel = 2;
    pingAction.SetUp(this);
    pingAction.SetProperties();
    pingAction.SetObjectActionID(t"DeviceAction.PingDevice");
    ArrayPush(Deref(outActions), pingAction);
  }
  wrappedMethod(outActions, context);
}

