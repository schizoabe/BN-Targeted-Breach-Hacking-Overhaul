

module BetterNetrunning.RemoteBreach.Core

import BetterNetrunning.Logging.*
import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Integration.*
import BetterNetrunning.Breach.*

public class RemoteBreachLockSystem {

  public static func GetNetworkDevices(
    sourceDevicePS: ref<ScriptableDeviceComponentPS>,
    excludeSource: Bool
  ) -> array<ref<ScriptableDeviceComponentPS>> {
    let result: array<ref<ScriptableDeviceComponentPS>>;

    if !IsDefined(sourceDevicePS) {
      return result;
    }

    let sharedPS: ref<SharedGameplayPS> = sourceDevicePS;

    if IsDefined(sharedPS) {
      let apControllers: array<ref<AccessPointControllerPS>> = sharedPS.GetAccessPoints();

      if ArraySize(apControllers) > 0 {

        let i: Int32 = 0;
        while i < ArraySize(apControllers) {
          let apPS: ref<AccessPointControllerPS> = apControllers[i];
          if IsDefined(apPS) {
            let networkDevices: array<ref<DeviceComponentPS>>;
            apPS.GetChildren(networkDevices);

            let j: Int32 = 0;
            while j < ArraySize(networkDevices) {
              let devicePS: ref<ScriptableDeviceComponentPS> = networkDevices[j] as ScriptableDeviceComponentPS;

              if !IsDefined(devicePS) {
                j += 1;
              } else if excludeSource && devicePS == sourceDevicePS {

                j += 1;
              } else {
                ArrayPush(result, devicePS);
                j += 1;
              }
            }
          }
          i += 1;
        }
      } else {

        let masterPS: ref<MasterControllerPS> = sourceDevicePS as MasterControllerPS;
        if IsDefined(masterPS) {

          let networkDevices: array<ref<DeviceComponentPS>>;
          masterPS.GetChildren(networkDevices);

          let k: Int32 = 0;
          while k < ArraySize(networkDevices) {
            let devicePS: ref<ScriptableDeviceComponentPS> = networkDevices[k] as ScriptableDeviceComponentPS;

            if IsDefined(devicePS) {
              ArrayPush(result, devicePS);
            }

            k += 1;
          }
        }
      }
    }

    return result;
  }

  
  public static func IsRemoteBreachLockedByTimestamp(
    devicePS: ref<ScriptableDeviceComponentPS>,
    gameInstance: GameInstance
  ) -> Bool {
    if !IsDefined(devicePS) {
      return false;
    }

    let shouldClear: Bool;
    let isLocked: Bool = BreachLockSystem.IsLockedByTimestamp(
      devicePS.m_betterNetrunningRemoteBreachFailedTimestamp,
      gameInstance,
      shouldClear
    );

    if shouldClear {
      devicePS.m_betterNetrunningRemoteBreachFailedTimestamp = 0.0;
    }

    return isLocked;
  }

  
  public static func RecordRemoteBreachFailure(
    player: ref<PlayerPuppet>,
    failedDevicePS: ref<ScriptableDeviceComponentPS>,
    failedPosition: Vector4,
    gameInstance: GameInstance
  ) -> Void {

    if !IsDefined(failedDevicePS) {
      BNError("RemoteBreachLock", "RecordRemoteBreachFailure called with null device PS");
      return;
    }

    let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
    let failedDeviceID: PersistentID = failedDevicePS.GetID();

    if IsDefined(failedDevicePS) {
      failedDevicePS.m_betterNetrunningRemoteBreachFailedTimestamp = currentTime;
      let entityID: EntityID = PersistentID.ExtractEntityID(failedDeviceID);
      BNDebug("RemoteBreachLock", "Step 1: Locked failed device: " + EntityID.ToDebugString(entityID));
    } else {
      BNError("RemoteBreachLock", "Failed device is not SharedGameplayPS - cannot lock");
      return;
    }

    let radiusMeters: Float = GetRadialBreachRange(gameInstance);
    let networkLockedCount: Int32 = 0;
    let standaloneLockedCount: Int32 = 0;

    let networkDevices: array<ref<ScriptableDeviceComponentPS>> = RemoteBreachLockSystem.GetNetworkDevices(
      failedDevicePS,
      true  // excludeSource: Failed device is locked separately in Step 1
    );

    let i: Int32 = 0;
    while i < ArraySize(networkDevices) {
      let devicePS: ref<ScriptableDeviceComponentPS> = networkDevices[i];

      if IsDefined(devicePS) {
        devicePS.m_betterNetrunningRemoteBreachFailedTimestamp = currentTime;
        networkLockedCount += 1;
      }

      i += 1;
    }

    let targetingSystem: ref<TargetingSystem> = GameInstance.GetTargetingSystem(gameInstance);
    if IsDefined(targetingSystem) {
      let nearbyDevices: array<ref<ScriptableDeviceComponentPS>> = player.FindNearbyDevices(targetingSystem);

      let j: Int32 = 0;
      while j < ArraySize(nearbyDevices) {
        let devicePS: ref<ScriptableDeviceComponentPS> = nearbyDevices[j];
        let sharedPS: ref<SharedGameplayPS> = devicePS;

        if IsDefined(sharedPS) {
          let apControllers: array<ref<AccessPointControllerPS>> = sharedPS.GetAccessPoints();

          if ArraySize(apControllers) == 0 {

            if NotEquals(devicePS.GetID(), failedDeviceID) {
              sharedPS.m_betterNetrunningRemoteBreachFailedTimestamp = currentTime;
              standaloneLockedCount += 1;
            }
          } else {

            if NotEquals(devicePS.GetID(), failedDeviceID) {
              sharedPS.m_betterNetrunningRemoteBreachFailedTimestamp = currentTime;
              networkLockedCount += 1;
            }
          }
        }

        j += 1;
      }
    }

    let vehicleLockedCount: Int32 = 0;
    if IsDefined(targetingSystem) {
      let nearbyVehicles: array<ref<VehicleComponentPS>> = player.FindNearbyVehicles(targetingSystem);

      let k: Int32 = 0;
      while k < ArraySize(nearbyVehicles) {
        let vehiclePS: ref<VehicleComponentPS> = nearbyVehicles[k];

        if IsDefined(vehiclePS) {

          if NotEquals(vehiclePS.GetID(), failedDeviceID) {
            vehiclePS.m_betterNetrunningRemoteBreachFailedTimestamp = currentTime;
            vehicleLockedCount += 1;
          }
        }

        k += 1;
      }
    }

    let totalLocked: Int32 = 1 + networkLockedCount + standaloneLockedCount + vehicleLockedCount; // 1 = failed device
    BNInfo("RemoteBreachLock", "Locked " + IntToString(totalLocked) + " devices " +
           "(Network: " + IntToString(networkLockedCount) + " [connected network], " +
           "Standalone: " + IntToString(standaloneLockedCount) + " [" + FloatToString(radiusMeters) + "m], " +
           "Vehicles: " + IntToString(vehicleLockedCount) + " [" + FloatToString(radiusMeters) + "m])");
  }
}

