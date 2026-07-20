



















module BetterNetrunning.Core

import BetterNetrunning.Integration.*


public enum TargetType {
  NPC = 0,
  Camera = 1,
  Turret = 2,
  Basic = 3
}


public struct DeviceBreachInfo {
  public let isCamera: Bool;
  public let isTurret: Bool;
  public let isStandaloneDevice: Bool;
}


public struct DevicePermissions {
  public let allowCameras: Bool;
  public let allowTurrets: Bool;
  public let allowBasicDevices: Bool;
  public let allowPing: Bool;
  public let allowDistraction: Bool;
}


public struct NPCHackPermissions {
  public let isBreached: Bool;
  public let allowCovert: Bool;
  public let allowCombat: Bool;
  public let allowControl: Bool;
  public let allowUltimate: Bool;
  public let allowPing: Bool;
  public let allowWhistle: Bool;
}


public struct BreachUnlockFlags {
  public let unlockBasic: Bool;
  public let unlockNPCs: Bool;
  public let unlockCameras: Bool;
  public let unlockTurrets: Bool;
}

public abstract class DeviceTypeUtils {





  
  public static func GetDeviceType(device: ref<DeviceComponentPS>) -> TargetType {

    if IsDefined(device as PuppetDeviceLinkPS) || IsDefined(device as CommunityProxyPS) {
      return TargetType.NPC;
    }


    let entity: wref<GameObject> = device.GetOwnerEntityWeak() as GameObject;


    if IsDefined(entity as SurveillanceCamera) {
      return TargetType.Camera;
    }


    if IsDefined(entity as SecurityTurret) {
      return TargetType.Turret;
    }

    return TargetType.Basic;
  }

  
  public static func GetDeviceTypeFromEntity(entity: wref<GameObject>) -> TargetType {
    if IsDefined(entity as SurveillanceCamera) {
      return TargetType.Camera;
    }
    if IsDefined(entity as SecurityTurret) {
      return TargetType.Turret;
    }
    if IsDefined(entity as ScriptedPuppet) {
      return TargetType.NPC;
    }
    return TargetType.Basic;
  }

  
  public static func IsCameraDevice(device: ref<DeviceComponentPS>) -> Bool {
    return Equals(DeviceTypeUtils.GetDeviceType(device), TargetType.Camera);
  }

  
  public static func IsTurretDevice(device: ref<DeviceComponentPS>) -> Bool {
    return Equals(DeviceTypeUtils.GetDeviceType(device), TargetType.Turret);
  }

  
  public static func IsNPCDevice(device: ref<DeviceComponentPS>) -> Bool {
    return Equals(DeviceTypeUtils.GetDeviceType(device), TargetType.NPC);
  }

  
  public static func IsBasicDevice(device: ref<DeviceComponentPS>) -> Bool {
    return Equals(DeviceTypeUtils.GetDeviceType(device), TargetType.Basic);
  }





  
  public static func IsBreached(TargetType: TargetType, sharedPS: ref<SharedGameplayPS>) -> Bool {
    if !IsDefined(sharedPS) {
      return false;
    }

    switch TargetType {
      case TargetType.NPC:
        return BreachStatusUtils.IsNPCsBreached(sharedPS);
      case TargetType.Camera:
        return BreachStatusUtils.IsCamerasBreached(sharedPS);
      case TargetType.Turret:
        return BreachStatusUtils.IsTurretsBreached(sharedPS);
      default: // TargetType.Basic
        return BreachStatusUtils.IsBasicBreached(sharedPS);
    }
  }



  
  public static func ShouldUnlockByFlags(TargetType: TargetType, flags: BreachUnlockFlags) -> Bool {
    switch TargetType {
      case TargetType.NPC:
        return flags.unlockNPCs;
      case TargetType.Camera:
        return flags.unlockCameras;
      case TargetType.Turret:
        return flags.unlockTurrets;
      default: // TargetType.Basic
        return flags.unlockBasic;
    }
  }




  public static func IsNPC(TargetType: TargetType) -> Bool {
    return Equals(TargetType, TargetType.NPC);
  }

  public static func IsCamera(TargetType: TargetType) -> Bool {
    return Equals(TargetType, TargetType.Camera);
  }

  public static func IsTurret(TargetType: TargetType) -> Bool {
    return Equals(TargetType, TargetType.Turret);
  }

  public static func IsBasicDevice(TargetType: TargetType) -> Bool {
    return Equals(TargetType, TargetType.Basic);
  }




  public static func DeviceTypeToString(TargetType: TargetType) -> String {
    switch TargetType {
      case TargetType.NPC: return "NPC";
      case TargetType.Camera: return "Camera";
      case TargetType.Turret: return "Turret";
      default: return "Basic";
    }
  }
}

