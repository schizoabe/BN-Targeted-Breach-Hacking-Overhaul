module BetterNetrunning.Minigame

import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Integration.*
import BetterNetrunning.Logging.*




























public func ShouldRemoveBreachedPrograms(actionID: TweakDBID, entity: wref<GameObject>) -> Bool {

  if !IsDefined(entity as Device) {
    return false;
  }

  let devicePS: ref<DeviceComponentPS> = (entity as Device).GetDevicePS();
  let sharedPS: ref<SharedGameplayPS> = devicePS as SharedGameplayPS;

  if !IsDefined(sharedPS) {
    return false;
  }


  let unlockDurationHours: Int32 = BetterNetrunningSettings.QuickhackUnlockDurationHours();
  let currentTime: Float = TimeUtils.GetCurrentTimestamp(devicePS.GetGameInstance());


  let unlockDurationSeconds: Float = Cast<Float>(unlockDurationHours) * 3600.0;

  BNTrace("CheckBreachedStatus", "unlockDurationHours=" + ToString(unlockDurationHours) + ", currentTime=" + ToString(currentTime));


  if actionID == BNConstants.PROGRAM_UNLOCK_QUICKHACKS() {
    return HandleTemporaryUnlock(
      sharedPS.m_betterNetrunningUnlockTimestampBasic,
      currentTime,
      unlockDurationSeconds,
      unlockDurationHours,
      sharedPS,
      TargetType.Basic
    );
  }

  if actionID == BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS() {
    return HandleTemporaryUnlock(
      sharedPS.m_betterNetrunningUnlockTimestampNPCs,
      currentTime,
      unlockDurationSeconds,
      unlockDurationHours,
      sharedPS,
      TargetType.NPC
    );
  }

  if actionID == BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS() {
    return HandleTemporaryUnlock(
      sharedPS.m_betterNetrunningUnlockTimestampCameras,
      currentTime,
      unlockDurationSeconds,
      unlockDurationHours,
      sharedPS,
      TargetType.Camera
    );
  }

  if actionID == BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS() {
    return HandleTemporaryUnlock(
      sharedPS.m_betterNetrunningUnlockTimestampTurrets,
      currentTime,
      unlockDurationSeconds,
      unlockDurationHours,
      sharedPS,
      TargetType.Turret
    );
  }

  return false;
}


private func HandleTemporaryUnlock(
  unlockTimestamp: Float,
  currentTime: Float,
  durationSeconds: Float,
  durationHours: Int32,
  sharedPS: ref<SharedGameplayPS>,
  TargetType: TargetType
) -> Bool {

  if !BreachStatusUtils.IsBreached(unlockTimestamp) {
    return false; // Not breached - show program
  }


  if durationHours <= 0 {
    return true; // Remove program permanently
  }


  let elapsedTime: Float = currentTime - unlockTimestamp;

  if elapsedTime > durationSeconds {

    ResetDeviceTimestamp(sharedPS, TargetType);
    return false; // Show program (allow re-breach)
  }


  return true; // Remove program
}


private func ResetDeviceTimestamp(sharedPS: ref<SharedGameplayPS>, TargetType: TargetType) -> Void {
  if Equals(TargetType, TargetType.Basic) {
    sharedPS.m_betterNetrunningUnlockTimestampBasic = 0.0;
  } else if Equals(TargetType, TargetType.NPC) {
    sharedPS.m_betterNetrunningUnlockTimestampNPCs = 0.0;
  } else if Equals(TargetType, TargetType.Camera) {
    sharedPS.m_betterNetrunningUnlockTimestampCameras = 0.0;
  } else if Equals(TargetType, TargetType.Turret) {
    sharedPS.m_betterNetrunningUnlockTimestampTurrets = 0.0;
  }
}




public func ShouldRemoveDeviceTypePrograms(actionID: TweakDBID, miniGameActionRecord: wref<MinigameAction_Record>, data: ConnectedClassTypes) -> Bool {

  if !BetterNetrunningSettings.UnlockIfNoAccessPoint() {
    return false;
  }



  if (Equals(miniGameActionRecord.Category().Type(), gamedataMinigameCategory.CameraAccess) || actionID == BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS()) && !data.surveillanceCamera {
    return true;
  }

  if (Equals(miniGameActionRecord.Category().Type(), gamedataMinigameCategory.TurretAccess) || actionID == BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS()) && !data.securityTurret {
    return true;
  }

  if (Equals(miniGameActionRecord.Type().Type(), gamedataMinigameActionType.NPC) || actionID == BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS()) && !data.puppet {
    return true;
  }
  return false;
}




public func ShouldRemoveOutOfRangeDevicePrograms(actionID: TweakDBID, gameInstance: GameInstance, breachPosition: Vector4, breachEntity: wref<GameObject>) -> Bool {

  if breachPosition.X < -999000.0 {
    return false;
  }


  let devicesInRange: DeviceTypesInRange = ScanDeviceTypesInNetwork(gameInstance, breachPosition, breachEntity);


  if actionID == BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS() && !devicesInRange.hasCameras {
    return true;
  }


  if actionID == BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS() && !devicesInRange.hasTurrets {
    return true;
  }


  if actionID == BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS() && !devicesInRange.hasNPCs {
    return true;
  }



  if actionID == BNConstants.PROGRAM_UNLOCK_QUICKHACKS() && !devicesInRange.hasBasicDevices {
    return true;
  }

  return false;
}


public struct DeviceTypesInRange {
  let hasCameras: Bool;
  let hasTurrets: Bool;
  let hasNPCs: Bool;
  let hasBasicDevices: Bool;
}


private func ScanDeviceTypesInNetwork(
  gameInstance: GameInstance,
  breachPosition: Vector4,
  breachEntity: wref<GameObject>
) -> DeviceTypesInRange {
  let result: DeviceTypesInRange;
  result.hasCameras = false;
  result.hasTurrets = false;
  result.hasNPCs = false;
  result.hasBasicDevices = false;


  let accessPoint: ref<AccessPoint> = breachEntity as AccessPoint;

  if !IsDefined(accessPoint) {
    result.hasCameras = true;
    result.hasTurrets = true;
    result.hasNPCs = true;
    result.hasBasicDevices = true;
    return result;
  }

  let accessPointPS: ref<AccessPointControllerPS> = accessPoint.GetDevicePS() as AccessPointControllerPS;

  if !IsDefined(accessPointPS) {
    result.hasCameras = true;
    result.hasTurrets = true;
    result.hasNPCs = true;
    result.hasBasicDevices = true;
    return result;
  }


  ScanNetworkDevices(accessPointPS, result);


  ScanRadialDevices(accessPointPS, result);

  return result;
}


private func ScanNetworkDevices(
  accessPointPS: ref<AccessPointControllerPS>,
  out result: DeviceTypesInRange
) -> Void {
  let networkDevices: array<ref<DeviceComponentPS>>;
  accessPointPS.GetChildren(networkDevices);

  let i: Int32 = 0;
  while i < ArraySize(networkDevices) {
    let devicePS: ref<DeviceComponentPS> = networkDevices[i];

    if IsDefined(devicePS) {
      ClassifyDeviceByType(devicePS as ScriptableDeviceComponentPS, result);
    }

    i += 1;
  }
}


@if(ModuleExists("RadialBreach"))
private func ScanRadialDevices(
  accessPointPS: ref<AccessPointControllerPS>,
  out result: DeviceTypesInRange
) -> Void {
  let radialObjects: array<wref<GameObject>> = accessPointPS.GetAllNearbyObjects();

  let i: Int32 = 0;
  while i < ArraySize(radialObjects) {
    let obj: wref<GameObject> = radialObjects[i];

    if IsDefined(obj) {

      let npc: ref<NPCPuppet> = obj as NPCPuppet;
      if IsDefined(npc) {
        result.hasNPCs = true;
      } else {

        let device: ref<Device> = obj as Device;
        if IsDefined(device) {
          let devicePS: ref<ScriptableDeviceComponentPS> = device.GetDevicePS();
          if IsDefined(devicePS) {
            ClassifyDeviceByType(devicePS, result);
          }
        }
      }
    }

    i += 1;
  }
}


@if(!ModuleExists("RadialBreach"))
private func ScanRadialDevices(
  accessPointPS: ref<AccessPointControllerPS>,
  out result: DeviceTypesInRange
) -> Void {

  result.hasNPCs = true;
}


private func ClassifyDeviceByType(
  devicePS: ref<ScriptableDeviceComponentPS>,
  out result: DeviceTypesInRange
) -> Void {
  if !IsDefined(devicePS) {
    return;
  }


  if IsDefined(devicePS as SurveillanceCameraControllerPS) {
    result.hasCameras = true;
  }

  else if IsDefined(devicePS as SecurityTurretControllerPS) {
    result.hasTurrets = true;
  }

  else {
    result.hasBasicDevices = true;
  }
}




public static func IsBetterNetrunningSubnetDaemon(actionID: TweakDBID) -> Bool {
  if Equals(actionID, BNConstants.PROGRAM_UNLOCK_QUICKHACKS()) { return true; }
  if Equals(actionID, BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS()) { return true; }
  if Equals(actionID, BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS()) { return true; }
  if Equals(actionID, BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS()) { return true; }
  return false;
}


public static func ApplyNetworkConnectivityFilter(
  entity: wref<Entity>,
  programs: script_ref<array<MinigameProgramData>>
) -> Void {

  let networkInfo: ConnectedClassTypes = GetNetworkTopology(entity);

  BNDebug("ApplyNetworkConnectivityFilter",
    "Network topology - Camera: " + ToString(networkInfo.surveillanceCamera) +
    ", Turret: " + ToString(networkInfo.securityTurret) +
    ", NPC: " + ToString(networkInfo.puppet));


  let i: Int32 = ArraySize(Deref(programs)) - 1;
  while i >= 0 {
    let program: MinigameProgramData = Deref(programs)[i];
    let shouldRemove: Bool = ShouldRemoveByNetworkConnectivity(program, networkInfo);

    if shouldRemove {
      BNDebug("ApplyNetworkConnectivityFilter",
        "Removing daemon (no network connectivity): " + TDBID.ToStringDEBUG(program.actionID));
      ArrayErase(Deref(programs), i);
    }

    i -= 1;
  }
}


private static func GetNetworkTopology(entity: wref<Entity>) -> ConnectedClassTypes {
  let result: ConnectedClassTypes;

  let gameObject: ref<GameObject> = entity as GameObject;
  if !IsDefined(gameObject) {
    BNWarn("GetNetworkTopology", "Entity is not GameObject");
    return result;
  }


  if gameObject.IsPuppet() {
    let puppet: ref<ScriptedPuppet> = entity as ScriptedPuppet;
    if IsDefined(puppet) {
      result = puppet.GetMasterConnectedClassTypes();
    }
  } else {

    let device: ref<Device> = entity as Device;
    if IsDefined(device) {
      result = device.GetDevicePS().CheckMasterConnectedClassTypes();
    }
  }

  return result;
}


private static func ShouldRemoveByNetworkConnectivity(
  program: MinigameProgramData,
  networkInfo: ConnectedClassTypes
) -> Bool {
  let category: CName = TweakDBInterface.GetCName(program.actionID + t".category", n"");


  if Equals(category, n"MinigameAction.CameraAccess") {
    if !networkInfo.surveillanceCamera {
      BNTrace("ShouldRemoveByNetworkConnectivity",
        "Removing CameraAccess daemon (no cameras): " + TDBID.ToStringDEBUG(program.actionID));
      return true;
    }
  }


  if Equals(category, n"MinigameAction.TurretAccess") {
    if !networkInfo.securityTurret {
      BNTrace("ShouldRemoveByNetworkConnectivity",
        "Removing TurretAccess daemon (no turrets): " + TDBID.ToStringDEBUG(program.actionID));
      return true;
    }
  }



  if Equals(category, n"MinigameAction.NPC") {
    if !networkInfo.puppet {
      BNTrace("ShouldRemoveByNetworkConnectivity",
        "Removing NPC daemon (no active NPCs): " + TDBID.ToStringDEBUG(program.actionID));
      return true;
    }
  }


  return false;
}


