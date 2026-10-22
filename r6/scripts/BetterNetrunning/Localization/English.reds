
module BetterNetrunning.Localization
import Codeware.Localization.*

public class English extends ModLocalizationPackage {
  protected func DefineTexts() -> Void {

    this.Text("Better-Netrunning-Quickhacks-Locked", "Breach Required");

    this.Text("Better-Netrunning-Basic-Access-Name", "Breach Root Network");
    this.Text("Better-Netrunning-Basic-Access-Description", "Unlocks quickhacks on marked basic devices.");
    this.Text("Better-Netrunning-NPC-Access-Name", "Breach Personnel System");
    this.Text("Better-Netrunning-NPC-Access-Description", "Unlocks quickhacks on marked personnel.");
    this.Text("Better-Netrunning-Camera-Access-Name", "Breach Surveillance System");
    this.Text("Better-Netrunning-Camera-Access-Description", "Unlocks quickhacks on marked surveillance cameras.");
    this.Text("Better-Netrunning-Turret-Access-Name", "Breach Defense System");
    this.Text("Better-Netrunning-Turret-Access-Description", "Unlocks quickhacks on marked turrets.");

    this.Text("Better-Netrunning-Counter-Breach-ICE-Name", "Deadlock Protocol");
    this.Text("Better-Netrunning-Counter-Breach-ICE-Description", "Counter the ICE. Lowers heat.");
    this.Text("Better-Netrunning-Firewall-ICE-Name", "Firewall Protocol");
    this.Text("Better-Netrunning-Firewall-ICE-Description", "Intercepts and reflects the hack.");

    this.Text("Better-Netrunning-Icepick-V1-Name", "Fracture Protocol");
    this.Text("Better-Netrunning-Icepick-V1-Description", "Deals weak hits to device ICE. Raises network heat.");
    this.Text("Better-Netrunning-Icepick-V2-Name", "Purge Protocol");
    this.Text("Better-Netrunning-Icepick-V2-Description", "Reduces network heat. Does not damage ICE.");
    this.Text("Better-Netrunning-Icepick-V3-Name", "Sunder Protocol");
    this.Text("Better-Netrunning-Icepick-V3-Description", "Deals severe hits to device ICE. No heat penalty.");

    this.Text("Better-Netrunning-HidePresence-Name", "Ghost Protocol");
    this.Text("Better-Netrunning-HidePresence-Description", "Masks all network activity.");
    this.Text("Better-Netrunning-DisarmICE-Name", "Null Protocol");
    this.Text("Better-Netrunning-DisarmICE-Description", "Disables ICE across the network.");
    this.Text("Better-Netrunning-SignalNoise-Name", "Raven Protocol");
    this.Text("Better-Netrunning-SignalNoise-Description", "Halves Heat generation of any quickhack interaction.");

    this.Text("Better-Netrunning-Mark-Name", "Mark");
    this.Text("Better-Netrunning-Mark-Description", "Tag this target for Network Diagnostics.");
    this.Text("Better-Netrunning-Unmark-Name", "Unmark");
    this.Text("Better-Netrunning-Unmark-Description", "Remove Network Diagnostics tag from this target.");

    this.Text("Better-Netrunning-EntropyProtocol-Name", "Entropy Protocol");
    this.Text("Better-Netrunning-EntropyProtocol-Description", "Degrades all resistance systems on marked personnel.");
    this.Text("Better-Netrunning-ExitProtocol-Name", "Exit Protocol");
    this.Text("Better-Netrunning-ExitProtocol-Description", "Initiates a clean disconnect from the device.");
    this.Text("Better-Netrunning-OffloadProtocol-Name", "Offload Protocol");
    this.Text("Better-Netrunning-OffloadProtocol-Description", "Recovers RAM on upload.");
    this.Text("Better-Netrunning-CascadeProtocol-Name", "Cascade Protocol");
    this.Text("Better-Netrunning-CascadeProtocol-Description", "Broadcasts equipped quickhack across all marked personnel.");

    this.Text("Better-Netrunning-RemoteBreach-Name", "Remote Breach");
    this.Text("Better-Netrunning-RemoteBreach-Description", "Attempts a breach without physical access. Weakens ICE on success. Requires the Intrusion Suite upgrade.");

    this.Text("Better-Netrunning-DataMine-Name", "DataMine Protocol");
    this.Text("Better-Netrunning-DataMine-Description", "Siphons data from marked targets");
    this.Text("Better-Netrunning-DataMine-Notify-Gained", "DataMine Protocol: +");
    this.Text("Better-Netrunning-DataMine-Notify-GhostNET", " data — check GhostNET's Data Exchange");
    this.Text("Better-Netrunning-DataMine-Notify-Empty", "DataMine Protocol: no usable data recovered");
    this.Text("Better-Netrunning-DataMine-Type-0", "Personnel");
    this.Text("Better-Netrunning-DataMine-Type-1", "Financial");
    this.Text("Better-Netrunning-DataMine-Type-2", "Operational");
    this.Text("Better-Netrunning-DataMine-Type-3", "Research");
    this.Text("Better-Netrunning-DataMine-Type-4", "Executive");

    this.Text("Better-Netrunning-UI-Boot-Title", "BOOTING");

    this.Text("Better-Netrunning-UI-ICEScoutLog-Title", "Diagnostic Feed");
    this.Text("Better-Netrunning-UI-ICEScoutLog-Footer", "ICE Diagnostic System v1.4");
    this.Text("Better-Netrunning-UI-ICEScoutLog-TierUnknown", "UNKNOWN ICE");
    this.Text("Better-Netrunning-UI-ICEScoutLog-TierLegacy", "LEGACY ICE");
    this.Text("Better-Netrunning-UI-ICEScoutLog-TierHardened", "HARDENED ICE");
    this.Text("Better-Netrunning-UI-ICEScoutLog-TierCorporate", "CORPORATE ICE");
    this.Text("Better-Netrunning-UI-ICEScoutLog-StatusUnknown", "UNKNOWN");
    this.Text("Better-Netrunning-UI-ICEScoutLog-StatusIntact", "INTACT");
    this.Text("Better-Netrunning-UI-ICEScoutLog-StatusCompromised", "FULLY COMPROMISED");
    this.Text("Better-Netrunning-UI-ICEScoutLog-StatusDegradedSuffix", "% DEGRADED");

    this.Text("Better-Netrunning-UI-TestPanel-CyberdeckPlaceholder", "CYBERDECK");
    this.Text("Better-Netrunning-UI-TestPanel-CascadePrefix", "CASCADE ... ");
    this.Text("Better-Netrunning-UI-TestPanel-None", "NONE");
    this.Text("Better-Netrunning-UI-TestPanel-ModeScout", "MODE ... SCOUT");
    this.Text("Better-Netrunning-UI-TestPanel-ModeAttack", "MODE ... ATTACK");
    this.Text("Better-Netrunning-UI-TestPanel-ModeDefend", "MODE ... DEFEND");
    this.Text("Better-Netrunning-UI-TestPanel-IceNominal", "ICE INTEGRITY ... NOMINAL");
    this.Text("Better-Netrunning-UI-TestPanel-IceBreached", "ICE INTEGRITY ... BREACHED");
    this.Text("Better-Netrunning-UI-TestPanel-IceDegraded", "ICE INTEGRITY ... DEGRADED");
    this.Text("Better-Netrunning-UI-TestPanel-FirewallStandby", "FIREWALL ... STANDBY");
    this.Text("Better-Netrunning-UI-TestPanel-FirewallDepleted", "FIREWALL ... DEPLETED");
    this.Text("Better-Netrunning-UI-TestPanel-FirewallPrefix", "FIREWALL ... ");
    this.Text("Better-Netrunning-UI-TestPanel-ChargeSingular", " CHARGE");
    this.Text("Better-Netrunning-UI-TestPanel-ChargePlural", " CHARGES");
    this.Text("Better-Netrunning-UI-TestPanel-HeatPrefix", "NETWORK HEAT ... ");
    this.Text("Better-Netrunning-UI-TestPanel-HeatCold", "COLD");
    this.Text("Better-Netrunning-UI-TestPanel-HeatWarm", "WARM");
    this.Text("Better-Netrunning-UI-TestPanel-HeatHot", "HOT");
    this.Text("Better-Netrunning-UI-TestPanel-HeatCritical", "CRITICAL");
    this.Text("Better-Netrunning-UI-TestPanel-HeatPeak", "PEAK");
    this.Text("Better-Netrunning-UI-TestPanel-HeatMaximum", "MAXIMUM");
    this.Text("Better-Netrunning-UI-TestPanel-RavenPrefix", "RAVEN ... ");
    this.Text("Better-Netrunning-UI-TestPanel-GhostPrefix", "GHOST ... ");
    this.Text("Better-Netrunning-UI-TestPanel-NullPrefix", "NULL ... ");
    this.Text("Better-Netrunning-UI-TestPanel-Ready", "READY");
    this.Text("Better-Netrunning-UI-TestPanel-Offline", "OFFLINE");
    this.Text("Better-Netrunning-UI-TestPanel-CounterIncoming", "ICE BREACH ... INCOMING");

    this.Text("Better-Netrunning-RCF-HubTitle", "Netrunning Overhaul");
    this.Text("Better-Netrunning-RCF-HubDescription", "Configure Netrunning Overhaul.");

    this.Text("Better-Netrunning-RCF-Tab-Controls", "Controls");
    this.Text("Better-Netrunning-RCF-Tab-Breaching", "Breaching");
    this.Text("Better-Netrunning-RCF-Tab-BreachPenalty", "Breach Penalty");
    this.Text("Better-Netrunning-RCF-Tab-Debug", "Debug");

    this.Text("Better-Netrunning-RCF-Section-UnconsciousBreach", "Unconscious Breach");
    this.Text("Better-Netrunning-RCF-Section-Hotkeys", "Hotkeys");
    this.Text("Better-Netrunning-RCF-Section-General", "General");
    this.Text("Better-Netrunning-RCF-Section-HackThePlanet", "Hack The Planet");
    this.Text("Better-Netrunning-RCF-Section-FailurePenalties", "Failure Penalties");
    this.Text("Better-Netrunning-RCF-Section-Logging", "Logging");
    this.Text("Better-Netrunning-RCF-Section-PerksDev", "Perks (Dev)");
    this.Text("Better-Netrunning-RCF-Section-HeatDev", "Network Heat (Dev)");

    this.Text("Better-Netrunning-RCF-ChoiceSlot1", "Choice 1");
    this.Text("Better-Netrunning-RCF-ChoiceSlot2", "Choice 2");
    this.Text("Better-Netrunning-RCF-ChoiceSlot3", "Choice 3");
    this.Text("Better-Netrunning-RCF-ChoiceSlot4", "Choice 4");

    this.Text("Better-Netrunning-RCF-UnconsciousBreachChoiceSlot-Label", "Unconscious Breaching Hotkey Slot");
    this.Text("Better-Netrunning-RCF-UnconsciousBreachChoiceSlot-Tip", "Which interaction-choice slot the \"Breach\" prompt occupies on an unconscious NPC's body. Change this if it conflicts with another mod's prompt on the same slot.");

    this.Text("Better-Netrunning-RCF-ClearMarks-Label", "Clear All Marks");
    this.Text("Better-Netrunning-RCF-ClearMarks-Tip", "Clears all breach marks and hides the HUD panels.");
    this.Text("Better-Netrunning-RCF-ForceJackOut-Label", "Force Jack-Out");
    this.Text("Better-Netrunning-RCF-ForceJackOut-Tip", "Emergency escape from a stuck breach board.");
    this.Text("Better-Netrunning-RCF-CycleBreachMode-Label", "Cycle Breach Mode");
    this.Text("Better-Netrunning-RCF-CycleBreachMode-Tip", "Cycles between Scout, Attack, and Defend modes (requires cyberdeck).");
    this.Text("Better-Netrunning-RCF-ToggleHUDPanels-Label", "Toggle HUD Panels");
    this.Text("Better-Netrunning-RCF-ToggleHUDPanels-Tip", "Shows or hides the Network Status and ICE Log panels.");
    this.Text("Better-Netrunning-RCF-CycleCascadeQH-Label", "Cycle Cascade Quickhack");
    this.Text("Better-Netrunning-RCF-CycleCascadeQH-Tip", "Cycles which installed quickhack the Cascade Protocol daemon broadcasts.");
    this.Text("Better-Netrunning-RCF-DumpRAMForICE-Label", "Dump RAM -> ICE");
    this.Text("Better-Netrunning-RCF-DumpRAMForICE-Tip", "Converts all current RAM into ICE hits (Defend mode only). Sacrifice offense for defense mid-fight.");

    this.Text("Better-Netrunning-RCF-EnableClassicMode-Label", "Enable Classic Mode");
    this.Text("Better-Netrunning-RCF-EnableClassicMode-Tip", "If enabled, the entire network can be breached by uploading any daemon. Disables the subnet system and its breach daemons.");
    this.Text("Better-Netrunning-RCF-AllowBreachUnconsciousNPCs-Label", "Allow Breaching Unconscious NPCs");
    this.Text("Better-Netrunning-RCF-AllowBreachUnconsciousNPCs-Tip", "Allows breaching unconscious NPCs connected to a network.");
    this.Text("Better-Netrunning-RCF-QuickhackUnlockDurationHours-Label", "Quickhack Unlock Duration (Hours)");
    this.Text("Better-Netrunning-RCF-QuickhackUnlockDurationHours-Tip", "How long quickhacks stay unlocked after a successful breach (in-game time). 0 = permanent (never re-locks).");
    this.Text("Better-Netrunning-RCF-OffensiveDaemonsEnabled-Label", "Offensive Daemons");
    this.Text("Better-Netrunning-RCF-OffensiveDaemonsEnabled-Tip", "When all marked cameras have their ICE compromised, adds camera shutdown and malfunction daemons to the breach board.");
    this.Text("Better-Netrunning-RCF-MarkBeamsEnabled-Label", "Mark Beams");
    this.Text("Better-Netrunning-RCF-MarkBeamsEnabled-Tip", "Draws a network beam from V to each marked entity. Beams appear on mark and disappear on unmark.");

    this.Text("Better-Netrunning-RCF-HackThePlanetEnabled-Label", "Enable Standalone Device Jacking");
    this.Text("Better-Netrunning-RCF-HackThePlanetEnabled-Tip", "Forces jack-in/breach actions onto devices and access points that vanilla wouldn't normally expose one on (vending machines, terminals, confession booths, etc.) and bypasses the DISABLED/UNPOWERED device-state gate on access points.");
    this.Text("Better-Netrunning-RCF-HackThePlanetReinitializeAccessPoints-Label", "Reinitialize Access Points");
    this.Text("Better-Netrunning-RCF-HackThePlanetReinitializeAccessPoints-Tip", "Resets an access point's hacking-minigame state so it can be re-attempted after certain quest/script state changes. CAUTION: also fires on every normal powered-on device the player approaches, not just disabled quest access points — this can prematurely expose a whole network's devices/NPCs without an actual breach. Only enable if you're hitting a specific stuck quest access point.");

    this.Text("Better-Netrunning-RCF-BreachFailurePenaltyEnabled-Label", "Enable Breach Failure Penalty");
    this.Text("Better-Netrunning-RCF-BreachFailurePenaltyEnabled-Tip", "Applies penalties when a breach protocol fails: disconnection VFX, type-specific lockout, and a trace attempt.");
    this.Text("Better-Netrunning-RCF-APBreachFailurePenaltyEnabled-Label", "Access Point Breach Penalty");
    this.Text("Better-Netrunning-RCF-APBreachFailurePenaltyEnabled-Tip", "Locks Jack In on the failed Access Point target for a duration (other targets remain accessible).");
    this.Text("Better-Netrunning-RCF-NPCBreachFailurePenaltyEnabled-Label", "NPC Breach Penalty");
    this.Text("Better-Netrunning-RCF-NPCBreachFailurePenaltyEnabled-Tip", "Locks Breach on the failed unconscious NPC for a duration (other NPCs remain breachable).");
    this.Text("Better-Netrunning-RCF-BreachPenaltyDurationMinutes-Label", "Breach Penalty Duration (Minutes)");
    this.Text("Better-Netrunning-RCF-BreachPenaltyDurationMinutes-Tip", "How long a target stays locked out after a failed breach attempt before it can be re-attempted.");

    this.Text("Better-Netrunning-RCF-EnableDebugLog-Label", "Enable Debug Logging");
    this.Text("Better-Netrunning-RCF-EnableDebugLog-Tip", "Enables debug log output.");
    this.Text("Better-Netrunning-RCF-DebugLogLevel-Label", "Log Level");
    this.Text("Better-Netrunning-RCF-DebugLogLevel-Tip", "Verbosity of debug logs. Only applies when Debug Logging is enabled.");
    this.Text("Better-Netrunning-RCF-LogLevel-Error", "ERROR (Errors Only)");
    this.Text("Better-Netrunning-RCF-LogLevel-Warning", "WARNING (Errors + Warnings)");
    this.Text("Better-Netrunning-RCF-LogLevel-Info", "INFO (Default)");
    this.Text("Better-Netrunning-RCF-LogLevel-Debug", "DEBUG (Detailed)");
    this.Text("Better-Netrunning-RCF-LogLevel-Trace", "TRACE (Very Detailed)");

    this.Text("Better-Netrunning-RCF-DevPerks-Max", "Max All");
    this.Text("Better-Netrunning-RCF-DevPerks-Zero", "Zero All");
    this.Text("Better-Netrunning-RCF-DevPerks-GroupLabel", "Dev: All Perks");
    this.Text("Better-Netrunning-RCF-DevPerks-Tip", "Instantly sets every BN perk to max rank, or zeroes them all. For in-game testing only.");
    this.Text("Better-Netrunning-RCF-DevHeat-Max", "Max (100%)");
    this.Text("Better-Netrunning-RCF-DevHeat-Zero", "Zero (0%)");
    this.Text("Better-Netrunning-RCF-DevHeat-GroupLabel", "Dev: Session Heat");
    this.Text("Better-Netrunning-RCF-DevHeat-Tip", "Forces session Heat to 100% or 0% instantly, bypassing Hide Presence/mode suppression. For testing Counter-Breach without waiting for Heat to climb naturally.");

    this.Text("Better-Netrunning-Alert-CounterBreachDefeated", "COUNTER-BREACH DEFEATED!");
    this.Text("Better-Netrunning-Alert-ICERetaliating", "ICE IS RETALIATING, BREACH INCOMING!");
    this.Text("Better-Netrunning-Alert-HostileICEPrefix", "HOSTILE ICE SUCCESSFUL — ");
    this.Text("Better-Netrunning-Alert-HostileICESuffix", " DEPLOYED");
    this.Text("Better-Netrunning-Alert-Hack-Overheat", "OVERHEAT");
    this.Text("Better-Netrunning-Alert-Hack-Biohazard", "BIOHAZARD PAYLOAD");
    this.Text("Better-Netrunning-Alert-Hack-ShortCircuit", "SHORT-CIRCUIT");
    this.Text("Better-Netrunning-Alert-Hack-OpticsBreach", "OPTICS BREACH");
    this.Text("Better-Netrunning-Alert-Hack-WeaponMalfunction", "WEAPON MALFUNCTION");
    this.Text("Better-Netrunning-Alert-Hack-MovementLockdown", "MOVEMENT LOCKDOWN");
    this.Text("Better-Netrunning-Alert-NoCyberdeckScoutOnly", "NO CYBERDECK — SCOUT MODE ONLY");
    this.Text("Better-Netrunning-Alert-BreachModePrefix", "BREACH MODE: ");
    this.Text("Better-Netrunning-Alert-Mode-Scout", "SCOUT");
    this.Text("Better-Netrunning-Alert-Mode-Attack", "ATTACK");
    this.Text("Better-Netrunning-Alert-Mode-Defend", "DEFEND");
    this.Text("Better-Netrunning-Alert-CascadeNoCyberdeck", "CASCADE: NO CYBERDECK");
    this.Text("Better-Netrunning-Alert-CascadeNoQuickhack", "CASCADE: NO QUICKHACK AVAILABLE");
    this.Text("Better-Netrunning-Alert-CascadeQuickhackNotApplicable", "CASCADE: QUICKHACK NOT APPLICABLE");
    this.Text("Better-Netrunning-Alert-CascadeBroadcastPrefix", "CASCADE: ");
    this.Text("Better-Netrunning-Alert-CascadeBroadcastSuffix", " broadcasted.");
    this.Text("Better-Netrunning-Alert-CascadeNoStampedNPCs", "CASCADE: NO STAMPED MARKED NPCS");
  }
}
