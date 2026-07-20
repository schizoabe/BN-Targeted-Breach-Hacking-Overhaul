

















module BetterNetrunningConfig





public class BetterNetrunningSettings {





    public static func BreachingHotkey() -> String { return "Choice3"; }





    public static func EnableClassicMode() -> Bool { return false; }
    public static func AllowBreachingUnconsciousNPCs() -> Bool { return true; }
    public static func RadialUnlockCrossNetwork() -> Bool { return true; }
    public static func QuickhackUnlockDurationHours() -> Int32 { return 6; }





    public static func RemoteBreachEnabledDevice() -> Bool { return true; }
    public static func RemoteBreachEnabledComputer() -> Bool { return false; }
    public static func RemoteBreachEnabledCamera() -> Bool { return true; }
    public static func RemoteBreachEnabledTurret() -> Bool { return true; }
    public static func RemoteBreachEnabledVehicle() -> Bool { return true; }
    public static func RemoteBreachEnabledNPC() -> Bool { return true; }
    public static func RemoteBreachRAMCostPercent() -> Int32 { return 15; }





    public static func BreachFailurePenaltyEnabled() -> Bool { return true; }
    public static func APBreachFailurePenaltyEnabled() -> Bool { return true; }
    public static func NPCBreachFailurePenaltyEnabled() -> Bool { return true; }
    public static func RemoteBreachFailurePenaltyEnabled() -> Bool { return true; }
    public static func BreachPenaltyDurationMinutes() -> Int32 { return 10; }





    public static func UnlockIfNoAccessPoint() -> Bool { return false; }





    public static func AlwaysAllowPing() -> Bool { return true; }
    public static func AlwaysAllowWhistle() -> Bool { return false; }
    public static func AlwaysAllowDistract() -> Bool { return false; }
    public static func AlwaysBasicDevices() -> Bool { return false; }
    public static func AlwaysCameras() -> Bool { return false; }
    public static func AlwaysTurrets() -> Bool { return false; }
    public static func AlwaysNPCsCovert() -> Bool { return false; }
    public static func AlwaysNPCsCombat() -> Bool { return false; }
    public static func AlwaysNPCsControl() -> Bool { return false; }
    public static func AlwaysNPCsUltimate() -> Bool { return false; }





    public static func ProgressionRequireAll() -> Bool { return true; }
    public static func ProgressionCyberdeckEnabled() -> Bool { return false; }
    public static func ProgressionIntelligenceEnabled() -> Bool { return false; }
    public static func ProgressionEnemyRarityEnabled() -> Bool { return false; }





    public static func ProgressionCyberdeckBasicDevices() -> Int32 { return 1; }
    public static func ProgressionCyberdeckCameras() -> Int32 { return 1; }
    public static func ProgressionCyberdeckTurrets() -> Int32 { return 1; }
    public static func ProgressionCyberdeckNPCsCovert() -> Int32 { return 1; }
    public static func ProgressionCyberdeckNPCsCombat() -> Int32 { return 1; }
    public static func ProgressionCyberdeckNPCsControl() -> Int32 { return 1; }
    public static func ProgressionCyberdeckNPCsUltimate() -> Int32 { return 1; }





    public static func ProgressionIntelligenceBasicDevices() -> Int32 { return 3; }
    public static func ProgressionIntelligenceCameras() -> Int32 { return 3; }
    public static func ProgressionIntelligenceTurrets() -> Int32 { return 3; }
    public static func ProgressionIntelligenceNPCsCovert() -> Int32 { return 3; }
    public static func ProgressionIntelligenceNPCsCombat() -> Int32 { return 3; }
    public static func ProgressionIntelligenceNPCsControl() -> Int32 { return 3; }
    public static func ProgressionIntelligenceNPCsUltimate() -> Int32 { return 3; }





    public static func ProgressionEnemyRarityNPCsCovert() -> Int32 { return 8; }
    public static func ProgressionEnemyRarityNPCsCombat() -> Int32 { return 8; }
    public static func ProgressionEnemyRarityNPCsControl() -> Int32 { return 8; }
    public static func ProgressionEnemyRarityNPCsUltimate() -> Int32 { return 8; }





    public static func EnableDebugLog() -> Bool { return false; }
    public static func DebugLogLevel() -> Int32 { return 2; } // 0=ERROR, 1=WARNING, 2=INFO, 3=DEBUG, 4=TRACE
}
