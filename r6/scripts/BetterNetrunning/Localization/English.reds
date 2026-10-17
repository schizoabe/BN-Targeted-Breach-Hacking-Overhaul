
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
  }
}
