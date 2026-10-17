
module BetterNetrunning.Core

public abstract class DeviceUnlockUtils {

    public static func ApplyTimestampUnlock(
        device: ref<DeviceComponentPS>,
        gameInstance: GameInstance,
        unlockBasic: Bool,
        unlockNPCs: Bool,
        unlockCameras: Bool,
        unlockTurrets: Bool
    ) -> Void {
        let sharedPS: ref<SharedGameplayPS> = device as SharedGameplayPS;
        if !IsDefined(sharedPS) {
            return;
        }

        let deviceType: TargetType = DeviceTypeUtils.GetDeviceType(device);
        let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);

        switch deviceType {
            case TargetType.NPC:
                if unlockNPCs {
                    sharedPS.m_betterNetrunningUnlockTimestampNPCs = currentTime;
                }
                break;
            case TargetType.Camera:
                if unlockCameras {
                    sharedPS.m_betterNetrunningUnlockTimestampCameras = currentTime;
                }
                break;
            case TargetType.Turret:
                if unlockTurrets {
                    sharedPS.m_betterNetrunningUnlockTimestampTurrets = currentTime;
                }
                break;
            default:
                if unlockBasic {
                    sharedPS.m_betterNetrunningUnlockTimestampBasic = currentTime;
                }
                break;
        }
    }
}
