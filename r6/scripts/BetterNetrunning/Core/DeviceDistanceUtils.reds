


















module BetterNetrunning.Core

public abstract class DeviceDistanceUtils {

  
  public static func GetDistanceSquared2D(pos1: Vector4, pos2: Vector4) -> Float {
    return Vector4.DistanceSquared2D(pos1, pos2);
  }

  
  public static func IsPositionWithinRadius(
    position: Vector4,
    centerPosition: Vector4,
    radiusMeters: Float
  ) -> Bool {
    let radiusSquared: Float = radiusMeters * radiusMeters;
    let distanceSquared: Float = DeviceDistanceUtils.GetDistanceSquared2D(position, centerPosition);
    return distanceSquared <= radiusSquared;
  }

  
  public static func GetDevicePosition(
    device: ref<DeviceComponentPS>,
    gameInstance: GameInstance
  ) -> Vector4 {

    if !IsDefined(device) {
      return Vector4(-999999.0, -999999.0, -999999.0, 1.0);
    }


    let deviceEntity: wref<GameObject> = device.GetOwnerEntityWeak() as GameObject;
    if IsDefined(deviceEntity) {
      return deviceEntity.GetWorldPosition();
    }


    let entityID: EntityID = PersistentID.ExtractEntityID(device.GetID());
    let deviceObject: ref<Device> = GameInstance.FindEntityByID(gameInstance, entityID) as Device;
    if IsDefined(deviceObject) {
      return deviceObject.GetWorldPosition();
    }


    return Vector4(-999999.0, -999999.0, -999999.0, 1.0);
  }




  public static func IsDeviceWithinRadius(
    device: ref<DeviceComponentPS>,
    centerPosition: Vector4,
    radiusMeters: Float,
    gameInstance: GameInstance
  ) -> Bool {
    let devicePosition: Vector4 = DeviceDistanceUtils.GetDevicePosition(device, gameInstance);


    if devicePosition.X <= -999000.0 {
      return true; // Fallback: allow if position unavailable
    }

    return DeviceDistanceUtils.IsPositionWithinRadius(devicePosition, centerPosition, radiusMeters);
  }
}

