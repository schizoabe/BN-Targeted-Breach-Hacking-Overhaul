
























module BetterNetrunning.Integration

import BetterNetrunning.Logging.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*


@if(ModuleExists("RadialBreach"))
import RadialBreach.Config.*






@if(ModuleExists("RadialBreach"))
public static func GetRadialBreachRange(gameInstance: GameInstance) -> Float {
  let config: ref<RadialBreachSettings> = new RadialBreachSettings();


  if config.enabled && config.breachRange > 0.0 {
    return config.breachRange;
  }


  return 50.0;
}


@if(!ModuleExists("RadialBreach"))
public static func GetRadialBreachRange(gameInstance: GameInstance) -> Float {
  return 50.0;
}






@addMethod(AccessPointControllerPS)
public final func GetBreachPosition() -> Vector4 {

  let apEntity: wref<GameObject> = this.GetOwnerEntityWeak() as GameObject;
  if IsDefined(apEntity) {
    return apEntity.GetWorldPosition();
  }


  let player: ref<PlayerPuppet> = GetPlayer(this.GetGameInstance());
  if IsDefined(player) {
    return player.GetWorldPosition();
  }


  BNError("RadialBreach", "Could not get breach position - returning error signal");
  return Vector4(-999999.0, -999999.0, -999999.0, 1.0);
}






@if(ModuleExists("RadialBreach"))
@addMethod(AccessPointControllerPS)
public final func ApplyBreachUnlockToDevices(const devices: script_ref<array<ref<DeviceComponentPS>>>, unlockFlags: BreachUnlockFlags) -> Void {

  let breachPosition: Vector4 = this.GetBreachPosition();
  let maxDistance: Float = GetRadialBreachRange(this.GetGameInstance());
  let shouldUseRadialFiltering: Bool = breachPosition.X >= -999000.0;

  let i: Int32 = 0;
  while i < ArraySize(Deref(devices)) {
    let device: ref<DeviceComponentPS> = Deref(devices)[i];


    let withinRadius: Bool = !shouldUseRadialFiltering ||
                             DeviceDistanceUtils.IsDeviceWithinRadius(device, breachPosition, maxDistance, this.GetGameInstance());

    if withinRadius {

      this.ProcessSingleDeviceUnlock(device, unlockFlags);
    }
    i += 1;
  }
}


@if(!ModuleExists("RadialBreach"))
@addMethod(AccessPointControllerPS)
public final func ApplyBreachUnlockToDevices(const devices: script_ref<array<ref<DeviceComponentPS>>>, unlockFlags: BreachUnlockFlags) -> Void {

  let i: Int32 = 0;
  while i < ArraySize(Deref(devices)) {
    let device: ref<DeviceComponentPS> = Deref(devices)[i];
    this.ProcessSingleDeviceUnlock(device, unlockFlags);
    i += 1;
  }
}


@addMethod(AccessPointControllerPS)
private final func ProcessSingleDeviceUnlock(device: ref<DeviceComponentPS>, unlockFlags: BreachUnlockFlags) -> Void {

  this.ApplyDeviceTypeUnlock(device, unlockFlags);







  let currentTime: Float = TimeUtils.GetCurrentTimestamp(this.GetGameInstance());

  let evt: ref<SetBreachedSubnet> = new SetBreachedSubnet();
  evt.unlockTimestampBasic = unlockFlags.unlockBasic ? currentTime : 0.0;
  evt.unlockTimestampNPCs = unlockFlags.unlockNPCs ? currentTime : 0.0;
  evt.unlockTimestampCameras = unlockFlags.unlockCameras ? currentTime : 0.0;
  evt.unlockTimestampTurrets = unlockFlags.unlockTurrets ? currentTime : 0.0;
  this.GetPersistencySystem().QueuePSEvent(device.GetID(), device.GetClassName(), evt);
}






@addMethod(PlayerPuppet)
private final func ApplyRemoteBreachDeviceUnlockInternal(
  device: ref<DeviceComponentPS>,
  unlockFlags: BreachUnlockFlags
) -> Bool {
  let sharedPS: ref<SharedGameplayPS> = device as SharedGameplayPS;
  if !IsDefined(sharedPS) {
    return false;
  }

  let TargetType: TargetType = DeviceTypeUtils.GetDeviceType(device);


  if !DeviceTypeUtils.ShouldUnlockByFlags(TargetType, unlockFlags) {
    return false;
  }


  let dummyAPPS: ref<AccessPointControllerPS> = new AccessPointControllerPS();
  dummyAPPS.QueuePSEvent(device, dummyAPPS.ActionSetExposeQuickHacks());


  let currentTime: Float = TimeUtils.GetCurrentTimestamp(this.GetGame());
  TimeUtils.SetDeviceUnlockTimestamp(sharedPS, TargetType, currentTime);


  let setBreachedSubnetEvent: ref<SetBreachedSubnet> = new SetBreachedSubnet();
  setBreachedSubnetEvent.unlockTimestampBasic = unlockFlags.unlockBasic ? currentTime : 0.0;
  setBreachedSubnetEvent.unlockTimestampNPCs = unlockFlags.unlockNPCs ? currentTime : 0.0;
  setBreachedSubnetEvent.unlockTimestampCameras = unlockFlags.unlockCameras ? currentTime : 0.0;
  setBreachedSubnetEvent.unlockTimestampTurrets = unlockFlags.unlockTurrets ? currentTime : 0.0;
  GameInstance.GetPersistencySystem(this.GetGame()).QueuePSEvent(device.GetID(), device.GetClassName(), setBreachedSubnetEvent);

  return true;
}


@if(ModuleExists("RadialBreach"))
@addMethod(PlayerPuppet)
public final func ApplyRemoteBreachNetworkUnlock(
  targetDevice: ref<ScriptableDeviceComponentPS>,
  networkDevices: array<ref<DeviceComponentPS>>,
  unlockFlags: BreachUnlockFlags
) -> Void {
  let unlockedCount: Int32 = 0;
  let skippedCount: Int32 = 0;
  let filteredCount: Int32 = 0;


  let targetEntity: wref<GameObject> = targetDevice.GetOwnerEntityWeak() as GameObject;
  if !IsDefined(targetEntity) {
    BNError("RadialBreach", "Target entity not found for RadialBreach filtering");
    return;
  }

  let breachPosition: Vector4 = targetEntity.GetWorldPosition();
  let maxDistance: Float = GetRadialBreachRange(this.GetGame());
  let shouldUseRadialFiltering: Bool = breachPosition.X >= -999000.0;

  let i: Int32 = 0;
  while i < ArraySize(networkDevices) {
    let device: ref<DeviceComponentPS> = networkDevices[i];

    if IsDefined(device) {

      let withinRadius: Bool = !shouldUseRadialFiltering ||
                               DeviceDistanceUtils.IsDeviceWithinRadius(device, breachPosition, maxDistance, this.GetGame());

      if withinRadius {

        if this.ApplyRemoteBreachDeviceUnlockInternal(device, unlockFlags) {
          unlockedCount += 1;
        } else {
          skippedCount += 1;
        }
      } else {
        filteredCount += 1;
      }
    }

    i += 1;
  }
}


@if(!ModuleExists("RadialBreach"))
@addMethod(PlayerPuppet)
public final func ApplyRemoteBreachNetworkUnlock(
  targetDevice: ref<ScriptableDeviceComponentPS>,
  networkDevices: array<ref<DeviceComponentPS>>,
  unlockFlags: BreachUnlockFlags
) -> Void {
  let unlockedCount: Int32 = 0;
  let skippedCount: Int32 = 0;

  let i: Int32 = 0;
  while i < ArraySize(networkDevices) {
    let device: ref<DeviceComponentPS> = networkDevices[i];

    if IsDefined(device) {

      if this.ApplyRemoteBreachDeviceUnlockInternal(device, unlockFlags) {
        unlockedCount += 1;
      } else {
        skippedCount += 1;
      }
    }

    i += 1;
  }
}

