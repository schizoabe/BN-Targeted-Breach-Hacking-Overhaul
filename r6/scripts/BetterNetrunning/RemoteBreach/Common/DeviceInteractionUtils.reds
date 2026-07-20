

















module BetterNetrunning.RemoteBreach.Common
import BetterNetrunning.Utils.*

public abstract class DeviceInteractionUtils {

  
  public static func EnableJackInInteractionForAccessPoint(devicePS: ref<ScriptableDeviceComponentPS>) -> Void {
    let masterController: ref<MasterControllerPS> = devicePS as MasterControllerPS;
    if !IsDefined(masterController) { return; }

    if BreachLockUtils.IsJackInLockedByAPBreachFailure(devicePS) { return; }

    masterController.SetHasPersonalLinkSlot(true);
  }

  
  public static func DisableJackInInteractionForAccessPoint(devicePS: ref<ScriptableDeviceComponentPS>) -> Void {

    let masterController: ref<MasterControllerPS> = devicePS as MasterControllerPS;
    if !IsDefined(masterController) { return; }


    masterController.SetHasPersonalLinkSlot(false);
  }
}

