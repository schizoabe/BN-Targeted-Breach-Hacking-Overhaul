
















module BetterNetrunning.Core

import BetterNetrunning.Core.*

public abstract class TimeUtils {

    
    public static func GetCurrentTimestamp(gameInstance: GameInstance) -> Float {
        let timeSystem: ref<TimeSystem> = GameInstance.GetTimeSystem(gameInstance);
        return timeSystem.GetGameTimeStamp();
    }

    
    public static func SetDeviceUnlockTimestamp(
        sharedPS: ref<SharedGameplayPS>,
        TargetType: TargetType,
        timestamp: Float
    ) -> Void {
        switch TargetType {
            case TargetType.NPC:
                sharedPS.m_betterNetrunningUnlockTimestampNPCs = timestamp;
                break;
            case TargetType.Camera:
                sharedPS.m_betterNetrunningUnlockTimestampCameras = timestamp;
                break;
            case TargetType.Turret:
                sharedPS.m_betterNetrunningUnlockTimestampTurrets = timestamp;
                break;
            default: // TargetType.Basic
                sharedPS.m_betterNetrunningUnlockTimestampBasic = timestamp;
                break;
        }
    }
}

