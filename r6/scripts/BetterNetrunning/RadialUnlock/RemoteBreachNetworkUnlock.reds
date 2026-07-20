




















module BetterNetrunning.RadialUnlock
import BetterNetrunning.Logging.*

import BetterNetrunning.Core.*
import BetterNetrunning.Integration.*
import BetterNetrunning.Utils.*
import BetterNetrunning.RemoteBreach.Core.*
import BetterNetrunning.RemoteBreach.Actions.*
import BetterNetrunningConfig.*









public struct RadialUnlockResult {
    public let basicCount: Int32;
    public let cameraCount: Int32;
    public let turretCount: Int32;
    public let npcCount: Int32;
    public let basicUnlocked: Int32;
    public let cameraUnlocked: Int32;
    public let turretUnlocked: Int32;
    public let npcUnlocked: Int32;
}






@addMethod(PlayerPuppet)
private func ApplyUnconsciousNPCNetworkUnlockWithStats(
  networkDevices: array<ref<DeviceComponentPS>>,
  unlockFlags: BreachUnlockFlags,
  stats: ref<BreachSessionStats>
) -> Void {

  BreachStatisticsCollector.CollectNetworkDeviceStats(networkDevices, unlockFlags, stats);


  let i: Int32 = 0;
  while i < ArraySize(networkDevices) {
    let device: ref<DeviceComponentPS> = networkDevices[i];
    if IsDefined(device) {
      let TargetType: TargetType = DeviceTypeUtils.GetDeviceType(device);


      if DeviceTypeUtils.ShouldUnlockByFlags(TargetType, unlockFlags) {
        let sharedPS: ref<SharedGameplayPS> = device as SharedGameplayPS;
        if IsDefined(sharedPS) {

          let currentTime: Float = TimeUtils.GetCurrentTimestamp(this.GetGame());
          TimeUtils.SetDeviceUnlockTimestamp(sharedPS, TargetType, currentTime);


          BNTrace("UnconsciousNPCUnlock", "Applied unlock timestamp: " +
            ToString(currentTime) + " to device type: " +
            EnumValueToString("TargetType", Cast<Int64>(EnumInt(TargetType))));
        }
      }
    }
    i += 1;
  }
}






@addMethod(PlayerPuppet)
private func ApplyRemoteBreachNetworkUnlockWithStats(
  targetDevice: ref<ScriptableDeviceComponentPS>,
  networkDevices: array<ref<DeviceComponentPS>>,
  unlockFlags: BreachUnlockFlags,
  stats: ref<BreachSessionStats>
) -> Void {

  BreachStatisticsCollector.CollectNetworkDeviceStats(networkDevices, unlockFlags, stats);


  let i: Int32 = 0;
  while i < ArraySize(networkDevices) {
    let device: ref<DeviceComponentPS> = networkDevices[i];
    if IsDefined(device) {
      let scriptableDevice: ref<ScriptableDeviceComponentPS> = device as ScriptableDeviceComponentPS;
      if IsDefined(scriptableDevice) {
        let TargetType: TargetType = DeviceTypeUtils.GetDeviceType(scriptableDevice);


        if DeviceTypeUtils.ShouldUnlockByFlags(TargetType, unlockFlags) {
          let sharedPS: ref<SharedGameplayPS> = scriptableDevice;
          if IsDefined(sharedPS) {

            let currentTime: Float = TimeUtils.GetCurrentTimestamp(this.GetGame());
            TimeUtils.SetDeviceUnlockTimestamp(sharedPS, TargetType, currentTime);
          }
        }
      }
    }
    i += 1;
  }
}






@addMethod(PlayerPuppet)
private func ParseRemoteBreachUnlockFlags(activePrograms: array<TweakDBID>) -> BreachUnlockFlags {
  let flags: BreachUnlockFlags;

  let i: Int32 = 0;
  while i < ArraySize(activePrograms) {
    let programID: TweakDBID = activePrograms[i];

    if Equals(programID, BNConstants.PROGRAM_UNLOCK_QUICKHACKS()) {
      flags.unlockBasic = true;
    } else if Equals(programID, BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS()) {
      flags.unlockNPCs = true;
    } else if Equals(programID, BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS()) {
      flags.unlockCameras = true;
    } else if Equals(programID, BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS()) {
      flags.unlockTurrets = true;
    }

    i += 1;
  }

  return flags;
}







@addMethod(PlayerPuppet)
private func GetRemoteBreachTargetDevice() -> ref<ScriptableDeviceComponentPS> {
  let gameInstance: GameInstance = this.GetGame();
  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gameInstance);

  let deviceSystem: ref<DeviceRemoteBreachStateSystem> = container.Get(BNConstants.CLASS_DEVICE_REMOTE_BREACH_STATE_SYSTEM()) as DeviceRemoteBreachStateSystem;
  if IsDefined(deviceSystem) {
    return deviceSystem.GetCurrentDevice();
  }

  return null;
}






@addMethod(PlayerPuppet)
private func GetRemoteBreachNetworkDevices(
  targetDevice: ref<ScriptableDeviceComponentPS>
) -> array<ref<DeviceComponentPS>> {
  let networkDevices: array<ref<DeviceComponentPS>>;


  let sharedPS: ref<SharedGameplayPS> = targetDevice;
  if !IsDefined(sharedPS) {
    return networkDevices;
  }


  let apControllers: array<ref<AccessPointControllerPS>> = sharedPS.GetAccessPoints();
  if ArraySize(apControllers) == 0 {
    return networkDevices;
  }


  let i: Int32 = 0;
  while i < ArraySize(apControllers) {
    this.CollectAccessPointDevices(apControllers[i], i, networkDevices);
    i += 1;
  }

  return networkDevices;
}


@addMethod(PlayerPuppet)
private func CollectAccessPointDevices(
  apPS: ref<AccessPointControllerPS>,
  apIndex: Int32,
  out networkDevices: array<ref<DeviceComponentPS>>
) -> Void {
  if !IsDefined(apPS) {
    return;
  }

  let apDevices: array<ref<DeviceComponentPS>>;
  apPS.GetChildren(apDevices);


  let j: Int32 = 0;
  while j < ArraySize(apDevices) {
    ArrayPush(networkDevices, apDevices[j]);
    j += 1;
  }
}






@addMethod(PlayerPuppet)
private func ApplyRemoteBreachDeviceUnlockWithStats(
  targetDevice: ref<ScriptableDeviceComponentPS>,
  unlockFlags: BreachUnlockFlags,
  stats: ref<BreachSessionStats>
) -> Void {

  if !IsDefined(targetDevice) {
    BNError("[RemoteBreach]", "Target device is not defined, cannot unlock");
    return;
  }


  let TargetType: TargetType = DeviceTypeUtils.GetDeviceType(targetDevice);


  if !DeviceTypeUtils.ShouldUnlockByFlags(TargetType, unlockFlags) {
    stats.devicesSkipped += 1;
    return;
  }


  let dummyAPPS: ref<AccessPointControllerPS> = new AccessPointControllerPS();
  dummyAPPS.QueuePSEvent(targetDevice, dummyAPPS.ActionSetExposeQuickHacks());


  let currentTime: Float = TimeUtils.GetCurrentTimestamp(this.GetGame());
  TimeUtils.SetDeviceUnlockTimestamp(targetDevice, TargetType, currentTime);


  let setBreachedSubnetEvent: ref<SetBreachedSubnet> = new SetBreachedSubnet();
  setBreachedSubnetEvent.unlockTimestampBasic = unlockFlags.unlockBasic ? currentTime : 0.0;
  setBreachedSubnetEvent.unlockTimestampNPCs = unlockFlags.unlockNPCs ? currentTime : 0.0;
  setBreachedSubnetEvent.unlockTimestampCameras = unlockFlags.unlockCameras ? currentTime : 0.0;
  setBreachedSubnetEvent.unlockTimestampTurrets = unlockFlags.unlockTurrets ? currentTime : 0.0;
  GameInstance.GetPersistencySystem(this.GetGame()).QueuePSEvent(targetDevice.GetID(), targetDevice.GetClassName(), setBreachedSubnetEvent);


  stats.devicesUnlocked += 1;
  if Equals(TargetType, TargetType.Camera) {
    stats.cameraCount += 1;
  } else if Equals(TargetType, TargetType.Turret) {
    stats.turretCount += 1;
  } else if Equals(TargetType, TargetType.NPC) {
    stats.npcNetworkCount += 1;
  } else {
    stats.basicCount += 1;
  }
}






@addMethod(PlayerPuppet)
public func FindNearbyDevices(
  targetingSystem: ref<TargetingSystem>
) -> array<ref<ScriptableDeviceComponentPS>> {
  let devices: array<ref<ScriptableDeviceComponentPS>>;


  let setup: TargetingSetup = DeviceUnlockUtils.SetupDeviceTargeting(this, this.GetGame());
  if !setup.isValid {
    return devices;
  }


  setup.query.searchFilter = TSF_All(TSFMV.Obj_Device);

  let parts: array<TS_TargetPartInfo>;
  targetingSystem.GetTargetParts(this, setup.query, parts);


  let i: Int32 = 0;
  while i < ArraySize(parts) {
    let entity: wref<GameObject> = TS_TargetPartInfo.GetComponent(parts[i]).GetEntity() as GameObject;

    if IsDefined(entity) {
      let device: ref<Device> = entity as Device;
      if IsDefined(device) {
        let devicePS: ref<ScriptableDeviceComponentPS> = device.GetDevicePS();
        if IsDefined(devicePS) {
          ArrayPush(devices, devicePS);
        }
      }
    }

    i += 1;
  }

  return devices;
}


@addMethod(PlayerPuppet)
public func FindNearbyVehicles(
  targetingSystem: ref<TargetingSystem>
) -> array<ref<VehicleComponentPS>> {
  let vehicles: array<ref<VehicleComponentPS>>;


  let setup: TargetingSetup = DeviceUnlockUtils.SetupDeviceTargeting(this, this.GetGame());
  if !setup.isValid {
    return vehicles;
  }


  let parts: array<TS_TargetPartInfo>;
  targetingSystem.GetTargetParts(this, setup.query, parts);


  let i: Int32 = 0;
  while i < ArraySize(parts) {
    let entity: wref<GameObject> = TS_TargetPartInfo.GetComponent(parts[i]).GetEntity() as GameObject;

    if IsDefined(entity) {
      let vehicle: ref<VehicleObject> = entity as VehicleObject;
      if IsDefined(vehicle) {
        let vehiclePS: ref<VehicleComponentPS> = vehicle.GetVehiclePS();
        if IsDefined(vehiclePS) {
          ArrayPush(vehicles, vehiclePS);
        }
      }
    }

    i += 1;
  }

  return vehicles;
}

