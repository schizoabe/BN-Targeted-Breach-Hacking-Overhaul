





















module BetterNetrunning.Minigame

import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Integration.*






public func ShouldRemoveNetworkPrograms(actionID: TweakDBID, connectedToNetwork: Bool) -> Bool {
  if connectedToNetwork {
    return false;
  }
  return IsUnlockQuickhackAction(actionID);
}


public func ShouldRemoveDeviceBackdoorPrograms(actionID: TweakDBID, entity: wref<GameObject>) -> Bool {

  if !DaemonFilterUtils.IsRegularDevice(entity) {
    return false;
  }
  return actionID == BNConstants.PROGRAM_DATAMINE_MASTER()
      || actionID == BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS()
      || actionID == BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS();
}






public func ShouldRemoveAccessPointPrograms(actionID: TweakDBID, miniGameActionRecord: wref<MinigameAction_Record>, isRemoteBreach: Bool) -> Bool {

  if isRemoteBreach {
    return false;
  }

  return NotEquals(miniGameActionRecord.Type().Type(), gamedataMinigameActionType.AccessPoint)
      && !IsUnlockQuickhackAction(actionID);
}




public func ShouldRemoveNonNetrunnerPrograms(actionID: TweakDBID, miniGameActionRecord: wref<MinigameAction_Record>, isRemoteBreach: Bool, entity: wref<GameObject>) -> Bool {

  if !IsRemoteNonNetrunner(isRemoteBreach, entity) {
    return false;
  }

  return Equals(miniGameActionRecord.Type().Type(), gamedataMinigameActionType.AccessPoint)
      || actionID == BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS()
      || actionID == BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS();
}


public func IsRemoteNonNetrunner(isRemoteBreach: Bool, entity: wref<GameObject>) -> Bool {
  if !isRemoteBreach {
    return false;
  }
  let puppet: wref<ScriptedPuppet> = entity as ScriptedPuppet;
  return IsDefined(puppet) && !puppet.IsNetrunnerPuppet();
}





private func IsUnlockQuickhackAction(actionID: TweakDBID) -> Bool {
  return actionID == BNConstants.PROGRAM_UNLOCK_QUICKHACKS()
      || actionID == BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS()
      || actionID == BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS()
      || actionID == BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS();
}

