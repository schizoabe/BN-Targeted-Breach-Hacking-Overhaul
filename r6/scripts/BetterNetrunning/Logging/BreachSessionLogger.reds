
module BetterNetrunning.Logging

import BetterNetrunning.Core.*
import BetterNetrunning.Minigame.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Logging.*

public class BreachSessionStats {

  public let breachType: String;
  public let breachTarget: String;
  public let timestamp: Float;

  public let minigameSuccess: Bool;
  public let programsInjected: Int32;
  public let programsFiltered: Int32;
  public let programsRemoved: Int32;

  public let networkDeviceCount: Int32;
  public let devicesUnlocked: Int32;
  public let devicesFailed: Int32;
  public let devicesSkipped: Int32;

  public let basicCount: Int32;
  public let cameraCount: Int32;
  public let turretCount: Int32;
  public let npcNetworkCount: Int32;

  public let basicUnlocked: Int32;
  public let basicSkipped: Int32;
  public let cameraUnlocked: Int32;
  public let cameraSkipped: Int32;
  public let turretUnlocked: Int32;
  public let turretSkipped: Int32;
  public let npcNetworkUnlocked: Int32;
  public let npcNetworkSkipped: Int32;

  public let unlockBasic: Bool;
  public let unlockCameras: Bool;
  public let unlockTurrets: Bool;
  public let unlockNPCs: Bool;

  public let displayedSubnetDaemons: array<TweakDBID>;
  public let executedSubnetDaemons: array<TweakDBID>;
  public let displayedNormalDaemons: array<TweakDBID>;
  public let executedNormalDaemons: array<TweakDBID>;
  public let executedBonusDaemons: array<TweakDBID>;

  public let processingTimeMs: Float;

  public static func Create(breachType: String, breachTarget: String) -> ref<BreachSessionStats> {
    let stats: ref<BreachSessionStats> = new BreachSessionStats();
    stats.breachType = breachType;
    stats.breachTarget = breachTarget;
    stats.timestamp = EngineTime.ToFloat(GameInstance.GetSimTime(GetGameInstance()));
    return stats;
  }

  public func Finalize() -> Void {
    let currentTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(GetGameInstance()));
    this.processingTimeMs = (currentTime - this.timestamp) * 1000.0;
  }
}

public static func LogBreachSummary(stats: ref<BreachSessionStats>) -> Void {
  BNInfo("BreachStats", "");
  BNInfo("BreachStats", "╔═══════════════════════════════════════════════════════════╗");
  BNInfo("BreachStats", "║         BREACH SESSION SUMMARY                           ║");
  BNInfo("BreachStats", "╚═══════════════════════════════════════════════════════════╝");
  BNInfo("BreachStats", "");

  BNInfo("BreachStats", "┌─ BASIC INFO ──────────────────────────────────────────────┐");
  BNInfo("BreachStats", "│ Type         : " + stats.breachType);
  BNInfo("BreachStats", "│ Target       : " + GetLocalizedTextByKey(StringToName(stats.breachTarget)) + " (" + DebugUtils.CleanDeviceName(stats.breachTarget) + ")");
  BNInfo("BreachStats", "│ Result       : " + (stats.minigameSuccess ? "SUCCESS" : "FAILED"));

  let timeStr: String = FloatToStringPrec(stats.processingTimeMs, 1);
  BNInfo("BreachStats", "│ Processing   : " + timeStr + " ms");
  BNInfo("BreachStats", "└───────────────────────────────────────────────────────────┘");
  BNInfo("BreachStats", "");

  BNInfo("BreachStats", "┌─ EXECUTED DAEMONS ─────────────────────────────────────────┐");

  let subnetExecuted: Int32 = ArraySize(stats.executedSubnetDaemons);
  let subnetTotal: Int32 = ArraySize(stats.displayedSubnetDaemons);

  BNInfo("BreachStats", "│ Subnet System (" + ToString(subnetExecuted) + "/" + ToString(subnetTotal) + "):");
  LogDaemonList(
    stats.displayedSubnetDaemons,
    stats.executedSubnetDaemons,
    "(None executed)",
    true,
    true,
    ""
  );

  if ArraySize(stats.displayedNormalDaemons) > 0 {
    BNInfo("BreachStats", "│");
    let normalTotal: Int32 = ArraySize(stats.displayedNormalDaemons);
    let normalActuallyExecuted: Int32 = ArraySize(stats.executedNormalDaemons);
    BNInfo("BreachStats", "│ Normal Daemons (" + ToString(normalActuallyExecuted) + "/" + ToString(normalTotal) + "):");
    LogDaemonList(
      stats.displayedNormalDaemons,
      stats.executedNormalDaemons,
      "(None executed)",
      true,
      false,
      ""
    );
  }

  if ArraySize(stats.executedBonusDaemons) > 0 {
    BNInfo("BreachStats", "│");
    let bonusCount: Int32 = ArraySize(stats.executedBonusDaemons);
    BNInfo("BreachStats", "│ Bonus Daemons (" + ToString(bonusCount) + "):");
    LogDaemonList(
      stats.executedBonusDaemons,
      stats.executedBonusDaemons,
      "(None)",
      false,
      false,
      "(auto-added)"
    );
  }

  BNInfo("BreachStats", "└────────────────────────────────────────────────────────────┘");
  BNInfo("BreachStats", "");

  if stats.networkDeviceCount > 0 {
    let unlockPercent: Int32 = (stats.devicesUnlocked * 100) / stats.networkDeviceCount;
    BNInfo("BreachStats", "┌─ NETWORK UNLOCK RESULTS ──────────────────────────────────┐");
    BNInfo("BreachStats", "│ Total Devices   : " + ToString(stats.networkDeviceCount));
    BNInfo("BreachStats", "│ ├─ Unlocked     : " + ToString(stats.devicesUnlocked) + " (" + ToString(unlockPercent) + "%)");
    BNInfo("BreachStats", "│ ├─ Skipped      : " + ToString(stats.devicesSkipped));
    BNInfo("BreachStats", "│ └─ Failed       : " + ToString(stats.devicesFailed));
    BNInfo("BreachStats", "└───────────────────────────────────────────────────────────┘");
    BNInfo("BreachStats", "");
  }

  let hasDevices: Bool = stats.basicCount > 0 || stats.cameraCount > 0 || stats.turretCount > 0 || stats.npcNetworkCount > 0;
  if hasDevices {
    BNInfo("BreachStats", "┌─ NETWORK DEVICES (Via Access Point) ──────────────────────┐");
    LogDeviceTypeBreakdown(
      stats.basicCount, stats.basicUnlocked, stats.basicSkipped,
      "Basic", BNConstants.PROGRAM_UNLOCK_QUICKHACKS()
    );
    LogDeviceTypeBreakdown(
      stats.cameraCount, stats.cameraUnlocked, stats.cameraSkipped,
      "Cameras", BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS()
    );
    LogDeviceTypeBreakdown(
      stats.turretCount, stats.turretUnlocked, stats.turretSkipped,
      "Turrets", BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS()
    );
    LogDeviceTypeBreakdown(
      stats.npcNetworkCount, stats.npcNetworkUnlocked, stats.npcNetworkSkipped,
      "NPCs", BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS()
    );
    BNInfo("BreachStats", "└───────────────────────────────────────────────────────────┘");
    BNInfo("BreachStats", "");
  }

  BNInfo("BreachStats", "═══════════════════════════════════════════════════════════");
}

private static func LogDeviceTypeBreakdown(
  deviceCount: Int32,
  unlockedCount: Int32,
  skippedCount: Int32,
  label: String,
  iconProgram: TweakDBID
) -> Void {
  if deviceCount == 0 {
    return;
  }

  let icon: String = GetSubnetDaemonIcon(iconProgram);
  let paddedLabel: String = label;

  while StrLen(paddedLabel) < 8 {
    paddedLabel += " ";
  }

  if unlockedCount > 0 {
    BNInfo("BreachStats", "│ " + icon + " " + paddedLabel + ": ✓" + ToString(unlockedCount));
  } else {
    BNInfo("BreachStats", "│ " + icon + " " + paddedLabel + ": ⊘" + ToString(skippedCount));
  }
}

private static func LogDaemonList(
  daemons: array<TweakDBID>,
  executedDaemons: array<TweakDBID>,
  emptyMessage: String,
  showStatusIcon: Bool,
  showIcon: Bool,
  additionalSuffix: String
) -> Void {

  if ArraySize(daemons) == 0 {
    BNInfo("BreachStats", "│   " + emptyMessage);
    return;
  }

  let i: Int32 = 0;
  while i < ArraySize(daemons) {
    let programID: TweakDBID = daemons[i];
    let daemonName: String = DaemonFilterUtils.GetDaemonDisplayName(programID);

    let statusPrefix: String = "";
    if showStatusIcon {
      let wasExecuted: Bool = ArrayContains(executedDaemons, programID);
      statusPrefix = wasExecuted ? "✓ " : "⊘ ";
    } else {
      statusPrefix = "✓ ";
    }

    let iconStr: String = "";
    if showIcon {
      iconStr = GetSubnetDaemonIcon(programID) + " ";
    }

    let suffix: String = NotEquals(additionalSuffix, "") ? " " + additionalSuffix : "";

    BNInfo("BreachStats", "│   " + statusPrefix + iconStr + daemonName + " (" + TDBID.ToStringDEBUG(programID) + ")" + suffix);
    i += 1;
  }
}

private static func GetSubnetDaemonIcon(programID: TweakDBID) -> String {

  if Equals(programID, BNConstants.PROGRAM_UNLOCK_QUICKHACKS())
      || Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_BASIC()) {
    return "🔌";
  }

  else if Equals(programID, BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS())
      || Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_CAMERA()) {
    return "📷";
  }

  else if Equals(programID, BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS())
      || Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_TURRET()) {
    return "🔫";
  }

  else if Equals(programID, BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS())
      || Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_NPC()) {
    return "👤";
  }

  else if Equals(programID, BNConstants.PROGRAM_ACTION_BN_UNLOCK_VEHICLE()) {
    return "🚗";
  }

  else {
    return "";
  }
}
