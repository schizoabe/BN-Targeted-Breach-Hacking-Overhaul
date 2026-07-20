

module BetterNetrunning.Core
import BetterNetrunning.Core.TimeUtils
import BetterNetrunningConfig.*

@addField(ScriptedPuppetPS)
public persistent let m_betterNetrunningWasDirectlyBreached: Bool;

@addField(SharedGameplayPS)
public persistent let m_betterNetrunningUnlockTimestampBasic: Float;

@addField(SharedGameplayPS)
public persistent let m_betterNetrunningUnlockTimestampCameras: Float;

@addField(SharedGameplayPS)
public persistent let m_betterNetrunningUnlockTimestampTurrets: Float;

@addField(SharedGameplayPS)
public persistent let m_betterNetrunningUnlockTimestampNPCs: Float;

@addField(SharedGameplayPS)
public persistent let m_betterNetrunningAPBreachFailedTimestamp: Float;

@addField(ScriptedPuppetPS)
public persistent let m_betterNetrunningNPCBreachFailedTimestamp: Float;

@addField(SharedGameplayPS)
public persistent let m_betterNetrunningRemoteBreachFailedTimestamp: Float;

@addField(SharedGameplayPS)
public persistent let m_bnNetworkVulnerability: Float;

@addField(SharedGameplayPS)
public persistent let m_bnNetworkHeat: Float;

@addField(SharedGameplayPS)
public persistent let m_bnNetworkLastActivityTimestamp: Float;

@addField(SharedGameplayPS)
public persistent let m_bnIceHitsRequired: Int32;

@addField(SharedGameplayPS)
public persistent let m_bnIceHitsApplied: Int32;

@addField(SharedGameplayPS)
public persistent let m_bnIceDefeated: Bool;

public class SetBreachedSubnet extends ActionBool {

  public let unlockTimestampBasic: Float;
  public let unlockTimestampNPCs: Float;
  public let unlockTimestampCameras: Float;
  public let unlockTimestampTurrets: Float;

  public final func SetProperties() -> Void {
    this.actionName = BNConstants.ACTION_SET_BREACHED_SUBNET();
    this.prop = DeviceActionPropertyFunctions.SetUpProperty_Bool(this.actionName, true, BNConstants.ACTION_SET_BREACHED_SUBNET(), BNConstants.ACTION_SET_BREACHED_SUBNET());
  }

  public func GetTweakDBChoiceRecord() -> String {
    return NameToString(BNConstants.ACTION_SET_BREACHED_SUBNET());
  }

  public final static func IsAvailable(device: ref<ScriptableDeviceComponentPS>) -> Bool {
    return true;
  }

  public final static func IsClearanceValid(clearance: ref<Clearance>) -> Bool {
    if Clearance.IsInRange(clearance, 2) {
      return true;
    };
    return false;
  }

  public final static func IsContextValid(const context: script_ref<GetActionsContext>) -> Bool {
    if Equals(Deref(context).requestType, gamedeviceRequestType.Direct) {
      return true;
    };
    return false;
  }

}

@addMethod(SharedGameplayPS)
public func OnSetBreachedSubnet(evt: ref<SetBreachedSubnet>) -> EntityNotificationType {

  this.m_betterNetrunningUnlockTimestampBasic = evt.unlockTimestampBasic;
  this.m_betterNetrunningUnlockTimestampNPCs = evt.unlockTimestampNPCs;
  this.m_betterNetrunningUnlockTimestampCameras = evt.unlockTimestampCameras;
  this.m_betterNetrunningUnlockTimestampTurrets = evt.unlockTimestampTurrets;

  return EntityNotificationType.DoNotNotifyEntity;
}

public abstract class BreachStatusUtils {

  public static func IsBreached(unlockTimestamp: Float) -> Bool {
    return unlockTimestamp > 0.0;
  }

  
  public static func IsBreachedWithExpiration(unlockTimestamp: Float, gameInstance: GameInstance) -> Bool {

    if unlockTimestamp <= 0.0 {
      return false;
    }

    let unlockDurationHours: Int32 = BetterNetrunningSettings.QuickhackUnlockDurationHours();

    if unlockDurationHours <= 0 {
      return true;
    }

    let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
    let elapsedTime: Float = currentTime - unlockTimestamp;
    let durationSeconds: Float = Cast<Float>(unlockDurationHours) * 3600.0;

    let isStillValid: Bool = elapsedTime <= durationSeconds;

    return isStillValid;
  }

  public static func IsBasicBreached(sharedPS: ref<SharedGameplayPS>) -> Bool {
    return BreachStatusUtils.IsBreached(sharedPS.m_betterNetrunningUnlockTimestampBasic);
  }

  public static func IsNPCsBreached(sharedPS: ref<SharedGameplayPS>) -> Bool {
    return BreachStatusUtils.IsBreached(sharedPS.m_betterNetrunningUnlockTimestampNPCs);
  }

  public static func IsCamerasBreached(sharedPS: ref<SharedGameplayPS>) -> Bool {
    return BreachStatusUtils.IsBreached(sharedPS.m_betterNetrunningUnlockTimestampCameras);
  }

  public static func IsTurretsBreached(sharedPS: ref<SharedGameplayPS>) -> Bool {
    return BreachStatusUtils.IsBreached(sharedPS.m_betterNetrunningUnlockTimestampTurrets);
  }
}

public func IsCustomRemoteBreachAction(action: ref<DeviceAction>) -> Bool {
  if !IsDefined(action) {
    return false;
  }
  return BNConstants.IsRemoteBreachAction(action.GetClassName());
}

public func IsCustomRemoteBreachAction(className: CName) -> Bool {
  return BNConstants.IsRemoteBreachAction(className);
}


