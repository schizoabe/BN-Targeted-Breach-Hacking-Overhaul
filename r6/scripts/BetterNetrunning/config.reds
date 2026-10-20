
module BetterNetrunningConfig

import BetterNetrunning.Core.*

public class BetterNetrunningSettings {

    public static func EnableClassicMode() -> Bool {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.enableClassicMode : false;
    }

    public static func AllowBreachingUnconsciousNPCs() -> Bool {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.allowBreachUnconsciousNPCs : true;
    }

    public static func QuickhackUnlockDurationHours() -> Int32 {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.quickhackUnlockDurationHours : 6;
    }

    public static func MarkBeamsEnabled() -> Bool {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.markBeamsEnabled : true;
    }

    public static func HackThePlanetEnabled() -> Bool {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.hackThePlanetEnabled : true;
    }

    public static func HackThePlanetReinitializeAccessPoints() -> Bool {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.hackThePlanetReinitializeAccessPoints : true;
    }

    public static func OffensiveDaemonsEnabled() -> Bool {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.offensiveDaemonsEnabled : true;
    }

    public static func BreachFailurePenaltyEnabled() -> Bool {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.breachFailurePenaltyEnabled : true;
    }

    public static func APBreachFailurePenaltyEnabled() -> Bool {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.apBreachFailurePenaltyEnabled : true;
    }

    public static func NPCBreachFailurePenaltyEnabled() -> Bool {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.npcBreachFailurePenaltyEnabled : true;
    }

    public static func BreachPenaltyDurationMinutes() -> Int32 {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.breachPenaltyDurationMinutes : 10;
    }

    public static func EnableDebugLog() -> Bool {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.enableDebugLog : false;
    }

    public static func DebugLogLevel() -> Int32 {
        let cfg: ref<BNConfig> = BNConfig.GetInstance(GetGameInstance());
        return IsDefined(cfg) ? cfg.debugLogLevel : 2;
    }
}