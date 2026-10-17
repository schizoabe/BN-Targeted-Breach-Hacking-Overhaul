module BetterNetrunning.Localization

import Codeware.Localization.*

public class BNLocEnglish extends ModLocalizationPackage {
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
  }
}
