





module BetterNetrunning.Utils

import BetterNetrunning.Core.*

public abstract class DaemonFilterUtils {





    
    public static func IsCamera(devicePS: ref<ScriptableDeviceComponentPS>) -> Bool {
        return IsDefined(devicePS as SurveillanceCameraControllerPS);
    }

    
    public static func IsTurret(devicePS: ref<ScriptableDeviceComponentPS>) -> Bool {
        return IsDefined(devicePS as SecurityTurretControllerPS);
    }

    
    public static func IsComputer(devicePS: ref<ScriptableDeviceComponentPS>) -> Bool {
        return IsDefined(devicePS as ComputerControllerPS);
    }

    
    public static func IsRegularDevice(entity: wref<GameObject>) -> Bool {
        return IsDefined(entity as Device)
            && !IsDefined(entity as AccessPoint)
            && !IsDefined((entity as Device).GetDevicePS() as ComputerControllerPS);
    }





    
    public static func IsConnectedToNetwork(entity: wref<GameObject>) -> Bool {

        if DaemonFilterUtils.IsRegularDevice(entity) {
            return true;
        }
        return false;
    }

    
    public static func IsConnectedToPhysicalAccessPoint(devicePS: ref<ScriptableDeviceComponentPS>) -> Bool {
        return devicePS.IsConnectedToPhysicalAccessPoint();
    }





    
    public static func IsCameraDaemon(actionID: TweakDBID) -> Bool {
        return Equals(actionID, BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS());
    }

    
    public static func IsTurretDaemon(actionID: TweakDBID) -> Bool {
        return Equals(actionID, BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS());
    }

    
    public static func IsNPCDaemon(actionID: TweakDBID) -> Bool {
        return Equals(actionID, BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS());
    }

    
    public static func IsBasicDaemon(actionID: TweakDBID) -> Bool {
        return Equals(actionID, BNConstants.PROGRAM_NETWORK_DEVICE_BASIC_ACTIONS());
    }

    
    public static func IsUnlockDaemon(actionID: TweakDBID) -> Bool {
        return DaemonFilterUtils.IsCameraDaemon(actionID)
            || DaemonFilterUtils.IsTurretDaemon(actionID)
            || DaemonFilterUtils.IsNPCDaemon(actionID)
            || DaemonFilterUtils.IsBasicDaemon(actionID);
    }





    
    public static func ExtractUnlockFlags(minigamePrograms: array<TweakDBID>) -> BreachUnlockFlags {
        let flags: BreachUnlockFlags;

        let i: Int32 = 0;
        while i < ArraySize(minigamePrograms) {
            let programID: TweakDBID = minigamePrograms[i];


            if Equals(programID, BNConstants.PROGRAM_UNLOCK_QUICKHACKS()) {
                flags.unlockBasic = true;
            } else if Equals(programID, BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS()) {
                flags.unlockNPCs = true;
            } else if Equals(programID, BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS()) {
                flags.unlockCameras = true;
            } else if Equals(programID, BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS()) {
                flags.unlockTurrets = true;
            }

            else if Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_BASIC()) {
                flags.unlockBasic = true;
            } else if Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_NPC()) {
                flags.unlockNPCs = true;
            } else if Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_CAMERA()) {
                flags.unlockCameras = true;
            } else if Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_TURRET()) {
                flags.unlockTurrets = true;
            }

            i += 1;
        }

        return flags;
    }





    
    public static func ShouldShowCameraDaemon(
        devicePS: ref<ScriptableDeviceComponentPS>,
        data: ConnectedClassTypes
    ) -> Bool {
        return DaemonFilterUtils.IsCamera(devicePS) || data.surveillanceCamera;
    }

    
    public static func ShouldShowTurretDaemon(
        devicePS: ref<ScriptableDeviceComponentPS>,
        data: ConnectedClassTypes
    ) -> Bool {
        return DaemonFilterUtils.IsTurret(devicePS) || data.securityTurret;
    }

    
    public static func ShouldShowNPCDaemon(data: ConnectedClassTypes) -> Bool {
        return data.puppet;
    }





    
    public static func GetDeviceTypeName(devicePS: ref<ScriptableDeviceComponentPS>) -> String {
        if DaemonFilterUtils.IsCamera(devicePS) {
            return "Camera";
        } else if DaemonFilterUtils.IsTurret(devicePS) {
            return "Turret";
        } else if DaemonFilterUtils.IsComputer(devicePS) {
            return "Computer";
        } else {
            return "Device";
        }
    }

    
    public static func GetDaemonTypeName(actionID: TweakDBID) -> String {
        if DaemonFilterUtils.IsCameraDaemon(actionID) {
            return "Camera";
        } else if DaemonFilterUtils.IsTurretDaemon(actionID) {
            return "Turret";
        } else if DaemonFilterUtils.IsNPCDaemon(actionID) {
            return "NPC";
        } else if DaemonFilterUtils.IsBasicDaemon(actionID) {
            return "Basic";
        } else {
            return "Unknown";
        }
    }





    
    public static func IsSubnetDaemon(programID: TweakDBID) -> Bool {
        if Equals(programID, BNConstants.PROGRAM_UNLOCK_QUICKHACKS()) { return true; }
        if Equals(programID, BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS()) { return true; }
        if Equals(programID, BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS()) { return true; }
        if Equals(programID, BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS()) { return true; }

        if Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_BASIC()) { return true; }
        if Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_CAMERA()) { return true; }
        if Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_TURRET()) { return true; }
        if Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_NPC()) { return true; }

        return false;
    }

    
    public static func GetDaemonDisplayName(programID: TweakDBID) -> String {
        let record: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(programID);
        if !IsDefined(record) {
            return TDBID.ToStringDEBUG(programID);
        }

        return GetLocalizedTextByKey(record.ObjectActionUI().Caption());
    }
}

