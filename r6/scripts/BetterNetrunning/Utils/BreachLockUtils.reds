

















module BetterNetrunning.Utils

import BetterNetrunningConfig.*
import BetterNetrunning.Breach.*
import BetterNetrunning.RemoteBreach.Core.*




public abstract class BreachLockUtils {

  
  public static func IsDeviceLockedByRemoteBreachFailure(
    devicePS: ref<ScriptableDeviceComponentPS>
  ) -> Bool {
    if !BetterNetrunningSettings.BreachFailurePenaltyEnabled() {
      return false;
    }


    return RemoteBreachLockSystem.IsRemoteBreachLockedByTimestamp(devicePS, devicePS.GetGameInstance());
  }

  
  public static func IsNPCLockedByRemoteBreachFailure(
    npcPS: ref<ScriptedPuppetPS>
  ) -> Bool {
    if !BetterNetrunningSettings.BreachFailurePenaltyEnabled() {
      return false;
    }

    let puppet: wref<ScriptedPuppet> = npcPS.GetOwnerEntity() as ScriptedPuppet;
    if !IsDefined(puppet) {
      return false;
    }

    let player: ref<PlayerPuppet> = GetPlayer(npcPS.GetGameInstance());
    if !IsDefined(player) {
      return false;
    }



    return false;
  }

  
  public static func IsNPCLockedByUnconsciousNPCBreachFailure(
    npcPS: ref<ScriptedPuppetPS>
  ) -> Bool {
    if !BetterNetrunningSettings.BreachFailurePenaltyEnabled() {
      return false;
    }

    if !BetterNetrunningSettings.NPCBreachFailurePenaltyEnabled() {
      return false;
    }

    return BreachLockSystem.IsNPCBreachLockedByTimestamp(npcPS, npcPS.GetGameInstance());
  }

  
  public static func IsJackInLockedByAPBreachFailure(
    devicePS: ref<ScriptableDeviceComponentPS>
  ) -> Bool {
    if !BetterNetrunningSettings.BreachFailurePenaltyEnabled() {
      return false;
    }

    if !BetterNetrunningSettings.APBreachFailurePenaltyEnabled() {
      return false;
    }

    let sharedPS: ref<SharedGameplayPS> = devicePS;
    return BreachLockSystem.IsAPBreachLockedByTimestamp(sharedPS, devicePS.GetGameInstance());
  }
}
