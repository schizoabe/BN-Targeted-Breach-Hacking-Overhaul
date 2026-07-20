























module BetterNetrunning.Logging

import BetterNetrunning.Core.*
import BetterNetrunning.Minigame.*
import BetterNetrunning.Utils.*
import BetterNetrunningConfig.*
import BetterNetrunning.Logging.*





public abstract class DebugUtils {







  public static func CleanDeviceName(rawName: String) -> String {
    let prefix: String = BNConstants.DEVICE_NAME_PREFIX();
    let cleaned: String = rawName;


    if StrBeginsWith(rawName, prefix) {
      cleaned = StrMid(rawName, StrLen(prefix));
    }


    if StrBeginsWith(cleaned, "LocKey#") {
      return GetLocalizedText(cleaned);
    }

    return cleaned;
  }





  
  private static func LogQuickhackListFromDeviceActions(
    actions: array<ref<DeviceAction>>,
    logContext: String
  ) -> Void {
    BNDebug(logContext, "--- Available Quickhacks (" + ToString(ArraySize(actions)) + ") ---");

    let i: Int32 = 0;
    while i < ArraySize(actions) {
      let action: ref<DeviceAction> = actions[i];
      if IsDefined(action) {
        let baseAction: ref<BaseScriptableAction> = action as BaseScriptableAction;
        if IsDefined(baseAction) {
          let isInactive: Bool = baseAction.IsInactive();
          let status: String = isInactive ? "[LOCKED]" : "[AVAILABLE]";

          let record: ref<ObjectAction_Record> = baseAction.GetObjectActionRecord();
          if IsDefined(record) {
            let displayName: String = GetLocalizedTextByKey(record.ObjectActionUI().Caption());
            let actionName: CName = record.ActionName();

            BNDebug(logContext, "  " + status + " " + displayName + " (" + NameToString(actionName) + ")");
          }
        }
      }
      i += 1;
    }
  }





  
  public static func LogDeviceQuickhackStateOnScan(devicePS: ref<ScriptableDeviceComponentPS>, actions: array<ref<DeviceAction>>) -> Void {
    if !BetterNetrunningSettings.EnableDebugLog() {
      return;
    }

    let sharedPS: ref<SharedGameplayPS> = devicePS;
    if !IsDefined(sharedPS) {
      BNWarn("[SCAN]", "Device is not SharedGameplayPS, skipping scan log");
      return;
    }


    let deviceType: String = DaemonFilterUtils.GetDeviceTypeName(devicePS);
    let rawDeviceName: String = devicePS.GetDeviceName();
    let deviceName: String = DebugUtils.CleanDeviceName(rawDeviceName);

    BNInfo("[SCAN]", "===== DEVICE SCANNED =====");
    BNInfo("[SCAN]", "Device: " + deviceName + " (" + deviceType + ")");


    let deviceEntity: ref<GameObject> = devicePS.GetOwnerEntityWeak() as GameObject;
    if IsDefined(deviceEntity) {
      let position: Vector4 = deviceEntity.GetWorldPosition();
      BNDebug("[SCAN]", "Location: X=" + ToString(position.X) + " Y=" + ToString(position.Y) + " Z=" + ToString(position.Z));
    }


    BNDebug("[SCAN]", "--- Breach State ---");
    BNDebug("[SCAN]", "Basic Breached: " + ToString(BreachStatusUtils.IsBasicBreached(sharedPS)));
    BNDebug("[SCAN]", "Camera Breached: " + ToString(BreachStatusUtils.IsCamerasBreached(sharedPS)));
    BNDebug("[SCAN]", "Turret Breached: " + ToString(BreachStatusUtils.IsTurretsBreached(sharedPS)));
    BNDebug("[SCAN]", "NPC Breached: " + ToString(BreachStatusUtils.IsNPCsBreached(sharedPS)));


    let isConnected: Bool = sharedPS.IsConnectedToPhysicalAccessPoint();
    let hasBackdoor: Bool = sharedPS.HasNetworkBackdoor();
    let isStandalone: Bool = !isConnected && !hasBackdoor;
    BNDebug("[SCAN]", "Network: " + (isConnected ? "Connected" : (hasBackdoor ? "Backdoor" : "Standalone")));


    DebugUtils.LogQuickhackListFromDeviceActions(actions, "[SCAN]");

    BNInfo("[SCAN]", "==========================");
  }





  
  public static func LogNPCQuickhackState(
    npcPS: ref<ScriptedPuppetPS>,
    puppetActions: script_ref<array<ref<PuppetAction>>>,
    opt logContext: String
  ) -> Void {
    if !BetterNetrunningSettings.EnableDebugLog() {
      return;
    }

    let context: String = NotEquals(logContext, "") ? logContext : "[Debug]";



    if !npcPS.IsConnectedToAccessPoint() {
      return;  // Normal state - no warning needed
    }

    let deviceLinkPS: ref<SharedGameplayPS> = npcPS.GetDeviceLink();

    if !IsDefined(deviceLinkPS) {

      BNWarn(context, "NPC is connected to AP but DeviceLink is null (unexpected timing issue)");
      return;
    }

    BNInfo(context, "===== NPC QUICKHACK STATE =====");


    let npcEntity: ref<GameObject> = npcPS.GetOwnerEntityWeak() as GameObject;
    if IsDefined(npcEntity) {
      let position: Vector4 = npcEntity.GetWorldPosition();
      BNDebug(context, "--- Location ---");
      BNDebug(context, "x = " + ToString(position.X) + ", y = " + ToString(position.Y) + ", z = " + ToString(position.Z));
    }


    BNDebug(context, "--- Breach State (Timestamp) ---");
    BNDebug(context, "NPC Subnet Breached: " + ToString(BreachStatusUtils.IsNPCsBreached(deviceLinkPS)) + " (ts: " + ToString(deviceLinkPS.m_betterNetrunningUnlockTimestampNPCs) + ")");


    BNDebug(context, "--- Network State ---");
    BNDebug(context, "Connected to Network: " + ToString(npcPS.IsConnectedToAccessPoint()));
    BNDebug(context, "Connected to AP: " + ToString(deviceLinkPS.IsConnectedToPhysicalAccessPoint()));


    let isStandaloneNPC: Bool = !npcPS.IsConnectedToAccessPoint() && !deviceLinkPS.IsConnectedToPhysicalAccessPoint() && !deviceLinkPS.HasNetworkBackdoor();
    BNDebug(context, "Is Standalone: " + ToString(isStandaloneNPC));


    let deviceActions: array<ref<DeviceAction>>;
    let i: Int32 = 0;
    while i < ArraySize(Deref(puppetActions)) {
      let puppetAction: ref<PuppetAction> = Deref(puppetActions)[i];
      if IsDefined(puppetAction) {
        ArrayPush(deviceActions, puppetAction);
      }
      i += 1;
    }

    DebugUtils.LogQuickhackListFromDeviceActions(deviceActions, context);

    BNInfo(context, "===============================");
  }






  public static func LogAccessPointBreachTarget(apPS: ref<AccessPointControllerPS>, opt logContext: String) -> Void {
    if !BetterNetrunningSettings.EnableDebugLog() {
      return;
    }

    let context: String = NotEquals(logContext, "") ? logContext : "[AccessPoint]";

    BNInfo(context, "===== BREACH TARGET INFORMATION =====");
    BNInfo(context, "Breach Method: Access Point Breach");
    BNInfo(context, "Target Device: " + DebugUtils.CleanDeviceName(apPS.GetDeviceName()));
    BNInfo(context, "Device Type: Access Point");

    let apEntity: ref<GameObject> = apPS.GetOwnerEntityWeak() as GameObject;
    if IsDefined(apEntity) {
      let apPosition: Vector4 = apEntity.GetWorldPosition();
      BNDebug(context, "x = " + ToString(apPosition.X) + ", y = " + ToString(apPosition.Y) + ", z = " + ToString(apPosition.Z));
    }

    BNInfo(context, "Network Name: " + apPS.GetNetworkName());

    let data: ConnectedClassTypes = apPS.CheckMasterConnectedClassTypes();
    BNDebug(context, "--- Network Device Types ---");
    BNDebug(context, "Cameras Connected: " + ToString(data.surveillanceCamera));
    BNDebug(context, "Turrets Connected: " + ToString(data.securityTurret));
    BNDebug(context, "NPCs Connected: " + ToString(data.puppet));

    BNInfo(context, "=====================================");
  }


  public static func LogRemoteBreachTarget(devicePS: ref<ScriptableDeviceComponentPS>, opt logContext: String) -> Void {
    if !BetterNetrunningSettings.EnableDebugLog() {
      return;
    }

    let context: String = NotEquals(logContext, "") ? logContext : "[RemoteBreach]";

    BNInfo(context, "===== BREACH TARGET INFORMATION =====");
    BNInfo(context, "Breach Method: Remote Breach (CustomHackingSystem)");
    BNInfo(context, "Target Device: " + DebugUtils.CleanDeviceName(devicePS.GetDeviceName()));
    BNInfo(context, "Device Type: " + DaemonFilterUtils.GetDeviceTypeName(devicePS));

    let deviceEntity: ref<GameObject> = devicePS.GetOwnerEntityWeak() as GameObject;
    if IsDefined(deviceEntity) {
      let devicePosition: Vector4 = deviceEntity.GetWorldPosition();
      BNDebug(context, "x = " + ToString(devicePosition.X) + ", y = " + ToString(devicePosition.Y) + ", z = " + ToString(devicePosition.Z));
    }


    let sharedPS: ref<SharedGameplayPS> = devicePS;
    if IsDefined(sharedPS) {
      BNDebug(context, "Network Name: " + sharedPS.GetNetworkName());
      BNDebug(context, "Connected to AP: " + ToString(sharedPS.IsConnectedToPhysicalAccessPoint()));
    }
    BNInfo(context, "=====================================");
  }


  public static func LogUnconsciousNPCBreachTarget(npc: ref<ScriptedPuppet>, npcPS: ref<ScriptedPuppetPS>, opt logContext: String) -> Void {
    if !BetterNetrunningSettings.EnableDebugLog() {
      return;
    }

    let context: String = NotEquals(logContext, "") ? logContext : "[UnconsciousNPC]";

    BNInfo(context, "===== BREACH TARGET INFORMATION =====");
    BNInfo(context, "Breach Method: Unconscious NPC Breach");

    let npcDisplayName: String = npc.GetDisplayName();
    if NotEquals(npcDisplayName, "") {
      BNInfo(context, "Target NPC: " + npcDisplayName);
    } else {
      BNWarn(context, "Target NPC: [Unknown]");
    }

    let npcPosition: Vector4 = npc.GetWorldPosition();
    BNDebug(context, "x = " + ToString(npcPosition.X) + ", y = " + ToString(npcPosition.Y) + ", z = " + ToString(npcPosition.Z));

    let deviceLinkPS: ref<SharedGameplayPS> = npcPS.GetDeviceLink();
    if IsDefined(deviceLinkPS) {
      BNDebug(context, "Connected to Network: " + ToString(npcPS.IsConnectedToAccessPoint()));
      if npcPS.IsConnectedToAccessPoint() {
        BNDebug(context, "Network Name: " + deviceLinkPS.GetNetworkName());
      }
    }
    BNInfo(context, "=====================================");
  }






  public static func LogProgramFilteringStep(
    filterName: String,
    programsBefore: Int32,
    programsAfter: Int32,
    removedProgram: TweakDBID,
    opt logContext: String
  ) -> Void {
    if !BetterNetrunningSettings.EnableDebugLog() {
      return;
    }

    let context: String = NotEquals(logContext, "") ? logContext : "[Filter]";

    if programsBefore != programsAfter {
      let programName: String = DaemonFilterUtils.GetDaemonDisplayName(removedProgram);
      BNDebug(context, filterName + ": Removed " + programName +
            " (" + ToString(programsBefore) + " → " + ToString(programsAfter) + " programs)");
    }
  }


  public static func LogFilteringSummary(
    initialCount: Int32,
    finalCount: Int32,
    removedPrograms: array<TweakDBID>,
    opt logContext: String
  ) -> Void {
    if !BetterNetrunningSettings.EnableDebugLog() {
      return;
    }

    let context: String = NotEquals(logContext, "") ? logContext : "[Filter]";
    let removedCount: Int32 = initialCount - finalCount;

    BNInfo(context, "===== FILTERING SUMMARY =====");
    BNInfo(context, "Initial programs: " + ToString(initialCount));
    BNInfo(context, "Final programs: " + ToString(finalCount));
    BNInfo(context, "Removed programs: " + ToString(removedCount));

    if removedCount > 0 {
      BNDebug(context, "--- Removed Program List ---");
      let i: Int32 = 0;
      while i < ArraySize(removedPrograms) {
        let programName: String = DaemonFilterUtils.GetDaemonDisplayName(removedPrograms[i]);
        BNDebug(context, ToString(i + 1) + ". " + programName +
              " (" + TDBID.ToStringDEBUG(removedPrograms[i]) + ")");
        i += 1;
      }
    }

    BNInfo(context, "=============================");
  }





  
  public static func LogRemoteBreachRAMCheck(
    actionClassName: CName,
    ramCost: Int32,
    currentRAM: Float,
    maxRAM: Float,
    canPay: Bool,
    opt logContext: String
  ) -> Void {
    if !BetterNetrunningSettings.EnableDebugLog() {
      return;
    }

    let context: String = NotEquals(logContext, "") ? logContext : "[RemoteBreach]";

    BNInfo(context, "===== REMOTEBREACH RAM CHECK =====");
    BNInfo(context, "Action: " + NameToString(actionClassName));
    BNDebug(context, "--- RAM Status ---");
    BNDebug(context, "Cost: " + ToString(ramCost));
    BNDebug(context, "Current: " + ToString(currentRAM));
    BNDebug(context, "Max: " + ToString(maxRAM));
    BNDebug(context, "Can Pay: " + ToString(canPay));
    BNInfo(context, "==================================");
  }

}






@wrapMethod(Device)
protected cb func OnScanningActionFinishedEvent(evt: ref<ScanningActionFinishedEvent>) -> Void {
  wrappedMethod(evt);


  if BetterNetrunningSettings.EnableDebugLog() {
    let devicePS: ref<ScriptableDeviceComponentPS> = this.GetDevicePS();
    if !IsDefined(devicePS) {
      return;
    }


    let player: ref<GameObject> = GetPlayer(this.GetGame());
    if !IsDefined(player) {
      return;
    }

    let context: GetActionsContext = devicePS.GenerateContext(
      gamedeviceRequestType.Remote,
      Device.GetInteractionClearance(),
      player,
      player.GetEntityID()
    );


    let actions: array<ref<DeviceAction>>;
    devicePS.GetQuickHackActions(actions, context);


    DebugUtils.LogDeviceQuickhackStateOnScan(devicePS, actions);
  }
}

