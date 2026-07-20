

module BetterNetrunning.RemoteBreach.Common

import BetterNetrunning.Core.TimeUtils
import BetterNetrunning.Utils.*
import BetterNetrunningConfig.*

public struct UnlockExpirationResult {
  public let isUnlocked: Bool;
  public let wasExpired: Bool;
  public let expiredDeviceType: CName;
}

public abstract class UnlockExpirationUtils {

  
  public static func CheckUnlockExpiration(devicePS: ref<ScriptableDeviceComponentPS>) -> UnlockExpirationResult {
    let result: UnlockExpirationResult;
    result.isUnlocked = false;
    result.wasExpired = false;
    result.expiredDeviceType = n"";

    let unlockDurationHours: Int32 = BetterNetrunningSettings.QuickhackUnlockDurationHours();
    let gameInstance: GameInstance = devicePS.GetGameInstance();

    if IsDefined(devicePS as VehicleComponentPS) {
      UnlockExpirationUtils.CheckVehicleExpiration(devicePS, unlockDurationHours, gameInstance, result);
    }

    else if DaemonFilterUtils.IsCamera(devicePS) {
      UnlockExpirationUtils.CheckCameraExpiration(devicePS, unlockDurationHours, gameInstance, result);
    }

    else if DaemonFilterUtils.IsTurret(devicePS) {
      UnlockExpirationUtils.CheckTurretExpiration(devicePS, unlockDurationHours, gameInstance, result);
    }

    else {
      UnlockExpirationUtils.CheckBasicDeviceExpiration(devicePS, unlockDurationHours, gameInstance, result);
    }

    return result;
  }

  
  private static func CheckVehicleExpiration(
    devicePS: ref<ScriptableDeviceComponentPS>,
    unlockDurationHours: Int32,
    gameInstance: GameInstance,
    out result: UnlockExpirationResult
  ) -> Void {
    let timestamp: Float = devicePS.m_betterNetrunningUnlockTimestampBasic;

    if timestamp == 0.0 { return; }

    if unlockDurationHours == 0 {
      result.isUnlocked = true;
      return;
    }

    let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
    let elapsedTime: Float = currentTime - timestamp;
    let durationSeconds: Float = Cast<Float>(unlockDurationHours) * 3600.0;

    if elapsedTime > durationSeconds {

      devicePS.m_betterNetrunningUnlockTimestampBasic = 0.0;
      result.wasExpired = true;
      result.expiredDeviceType = n"Vehicle";
    } else {
      result.isUnlocked = true;
    }
  }

  
  private static func CheckCameraExpiration(
    devicePS: ref<ScriptableDeviceComponentPS>,
    unlockDurationHours: Int32,
    gameInstance: GameInstance,
    out result: UnlockExpirationResult
  ) -> Void {
    let timestamp: Float = devicePS.m_betterNetrunningUnlockTimestampCameras;

    if timestamp == 0.0 { return; }

    if unlockDurationHours == 0 {
      result.isUnlocked = true;
      return;
    }

    let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
    let elapsedTime: Float = currentTime - timestamp;
    let durationSeconds: Float = Cast<Float>(unlockDurationHours) * 3600.0;

    if elapsedTime > durationSeconds {

      devicePS.m_betterNetrunningUnlockTimestampCameras = 0.0;
      result.wasExpired = true;
      result.expiredDeviceType = n"Camera";
    } else {
      result.isUnlocked = true;
    }
  }

  
  private static func CheckTurretExpiration(
    devicePS: ref<ScriptableDeviceComponentPS>,
    unlockDurationHours: Int32,
    gameInstance: GameInstance,
    out result: UnlockExpirationResult
  ) -> Void {
    let timestamp: Float = devicePS.m_betterNetrunningUnlockTimestampTurrets;

    if timestamp == 0.0 { return; }

    if unlockDurationHours == 0 {
      result.isUnlocked = true;
      return;
    }

    let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
    let elapsedTime: Float = currentTime - timestamp;
    let durationSeconds: Float = Cast<Float>(unlockDurationHours) * 3600.0;

    if elapsedTime > durationSeconds {

      devicePS.m_betterNetrunningUnlockTimestampTurrets = 0.0;
      result.wasExpired = true;
      result.expiredDeviceType = n"Turret";
    } else {
      result.isUnlocked = true;
    }
  }

  
  private static func CheckBasicDeviceExpiration(
    devicePS: ref<ScriptableDeviceComponentPS>,
    unlockDurationHours: Int32,
    gameInstance: GameInstance,
    out result: UnlockExpirationResult
  ) -> Void {
    let timestamp: Float = devicePS.m_betterNetrunningUnlockTimestampBasic;

    if timestamp == 0.0 { return; }

    if unlockDurationHours == 0 {
      result.isUnlocked = true;
      return;
    }

    let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
    let elapsedTime: Float = currentTime - timestamp;
    let durationSeconds: Float = Cast<Float>(unlockDurationHours) * 3600.0;

    if elapsedTime > durationSeconds {

      devicePS.m_betterNetrunningUnlockTimestampBasic = 0.0;
      result.wasExpired = true;
      result.expiredDeviceType = n"Basic";
    } else {
      result.isUnlocked = true;
    }
  }
}

