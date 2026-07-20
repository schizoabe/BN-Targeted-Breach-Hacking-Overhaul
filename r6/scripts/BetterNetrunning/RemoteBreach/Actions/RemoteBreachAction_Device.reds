

module BetterNetrunning.RemoteBreach.Actions

import BetterNetrunning.*
import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.RemoteBreach.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Breach.*
import BetterNetrunning.Network.*
import BetterNetrunning.Perks.*
import BetterNetrunning.Marking.*

@if(ModuleExists("HackingExtensions"))
import HackingExtensions.*

@if(ModuleExists("HackingExtensions.Programs"))
import HackingExtensions.Programs.*

@if(ModuleExists("HackingExtensions"))
public class DeviceRemoteBreachAction extends BaseRemoteBreachAction {
    private let m_devicePS: ref<ScriptableDeviceComponentPS>;

    public func GetInteractionDescription() -> String {
        return "Remote Breach";
    }

    public func GetTweakDBChoiceRecord() -> String {
        return "Remote Breach";
    }

    public func SetDevicePS(devicePS: ref<ScriptableDeviceComponentPS>) -> Void {
        this.m_devicePS = devicePS;
    }

    public func InitializePrograms() -> Void {

        if !IsDefined(this.m_devicePS) {
            return;
        }

        let gameInstance: GameInstance = this.m_devicePS.GetGameInstance();
        let stateSystem: ref<DeviceRemoteBreachStateSystem> = StateSystemUtils.GetDeviceStateSystem(gameInstance);

        if IsDefined(stateSystem) {
            let availableDaemons: String = this.GetAvailableDaemonsForDevice();
            stateSystem.SetCurrentDevice(this.m_devicePS, availableDaemons);
        }
    }

    private func GetAvailableDaemonsForDevice() -> String {
        if IsDefined(this.m_devicePS as ComputerControllerPS) { return "basic,camera"; }
        if DaemonFilterUtils.IsCamera(this.m_devicePS) { return "basic,camera"; }
        if DaemonFilterUtils.IsTurret(this.m_devicePS) { return "basic,turret"; }
        if IsDefined(this.m_devicePS as TerminalControllerPS) { return "basic,npc"; }
        return "basic";
    }
}

@if(ModuleExists("HackingExtensions"))
@addMethod(ScriptableDeviceComponentPS)
private final func ActionCustomDeviceRemoteBreach() -> ref<DeviceRemoteBreachAction> {
    let action: ref<DeviceRemoteBreachAction> = new DeviceRemoteBreachAction();
    action.SetDevicePS(this);
    RemoteBreachActionHelper.Initialize(action, this, n"DeviceRemoteBreach");

    let gi: GameInstance = this.GetGameInstance();
    let sharedPS: ref<SharedGameplayPS> = this;
    if IsDefined(sharedPS) && sharedPS.m_bnIceHitsRequired == 0 {
        sharedPS.m_bnIceHitsRequired = StateSystemUtils.GetHeatScaledICEHits(gi);
        BNInfo("RemoteBreachDevice", "ICE initialized: " + ToString(sharedPS.m_bnIceHitsRequired) + " hits required");
    }

    let ms: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi).Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    let netState: NetworkState = NetworkStateUtils.GetNetworkState(this, gi);
    if IsDefined(ms) && ms.GetDisarmICETimer() > 0.0 && netState.hitsRequired > 0 {
        netState.hitsRequired = 1;
        netState.globalBonus  = 0;
    }

    if !IsDefined(sharedPS) || !NetworkStateUtils.IsSubnetAccessible(netState) {

        action.m_isICEBoard = true;
        action.SetProperties(
            this.GetDeviceName(),
            1,
            0,
            true,
            false,
            BNPerkData.GetRemoteBreachICEBoard(gi),
            this
        );
        BNInfo("RemoteBreachDevice",
            "ICE intact (" + ToString(netState.hitsApplied) + "/" + ToString(netState.hitsRequired) + ") — showing ICE board");
    } else {

        let difficulty: GameplayDifficulty = RemoteBreachActionHelper.GetCurrentDifficulty();
        let targetType: MinigameTargetType;
        if IsDefined(this as ComputerControllerPS) { targetType = MinigameTargetType.Computer; }
        else if IsDefined(this as VehicleComponentPS) { targetType = MinigameTargetType.Vehicle; }
        else { targetType = MinigameTargetType.Device; }
        RemoteBreachActionHelper.SetMinigameDefinition(action, targetType, difficulty, this);
        BNInfo("RemoteBreachDevice", "ICE compromised — showing subnet board");
    }

    let player: ref<PlayerPuppet> = GetPlayer(this.GetGameInstance());
    let canExecute: Bool;
    let inactiveReason: String = RemoteBreachLockUtils.GetRemoteBreachInactiveReason(action, this, player, canExecute);

    if !canExecute {
      action.SetInactiveWithReason(false, inactiveReason);
    }

    action.InitializePrograms();

    let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(this.GetGameInstance());
    if IsDefined(container) {
        let hackSystem: ref<CustomHackingSystem> = container.Get(BNConstants.CLASS_CUSTOM_HACKING_SYSTEM()) as CustomHackingSystem;
        if IsDefined(hackSystem) {

            let scanBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().HackingMinigame);
            let scanEntity: wref<Entity> = this.GetOwnerEntityWeak() as Entity;
            if IsDefined(scanBB) && IsDefined(scanEntity) {
                scanBB.SetVariant(GetAllBlackboardDefs().HackingMinigame.Entity, ToVariant(scanEntity));
            }
            hackSystem.RegisterDeviceAction(action);
        }
    }

    return action;
}

@if(ModuleExists("HackingExtensions"))
@wrapMethod(ScriptableDeviceComponentPS)
protected func GetQuickHackActions(out actions: array<ref<DeviceAction>>, const context: script_ref<GetActionsContext>) -> Void {
    let gi: GameInstance = this.GetGameInstance();
    wrappedMethod(actions, context);

    RemoteBreachActionHelper.RemoveTweakDBRemoteBreach(actions, n"DeviceRemoteBreachAction");
    RemoteBreachActionHelper.RemoveTweakDBRemoteBreach(actions, n"RemoteBreachAction");
    RemoteBreachActionHelper.RemoveTweakDBRemoteBreach(actions, n"VehicleRemoteBreachAction");

    if IsDefined(this as AccessPointControllerPS) { return; }

    if BetterNetrunningSettings.UnlockIfNoAccessPoint() {
        return;
    }

    let isCamera: Bool = DeviceTypeUtils.IsCameraDevice(this);
    let isTurret: Bool = DeviceTypeUtils.IsTurretDevice(this);
    let isComputer: Bool = IsDefined(this as ComputerControllerPS);
    let isVehicle: Bool = IsDefined(this as VehicleComponentPS);

    if isCamera { if !BetterNetrunningSettings.RemoteBreachEnabledCamera() { return; } }
    else if isTurret { if !BetterNetrunningSettings.RemoteBreachEnabledTurret() { return; } }
    else if isComputer { if !BetterNetrunningSettings.RemoteBreachEnabledComputer() { return; } }
    else if isVehicle { if !BetterNetrunningSettings.RemoteBreachEnabledVehicle() { return; } }
    else { if !BetterNetrunningSettings.RemoteBreachEnabledDevice() { return; } }

    if BreachLockUtils.IsDeviceLockedByRemoteBreachFailure(this) {
        return;
    }

    let deviceEntity: wref<GameObject> = this.GetOwnerEntityWeak() as GameObject;
    if !IsDefined(deviceEntity) {
        return;
    }

    let deviceID: EntityID = deviceEntity.GetEntityID();
    let stateSystem: ref<DeviceRemoteBreachStateSystem> = StateSystemUtils.GetDeviceStateSystem(gi);

    if IsDefined(stateSystem) && stateSystem.IsDeviceBreached(deviceID) {
        return;
    }

    let perkSysD: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gi);
    if !IsDefined(perkSysD) || perkSysD.GetPerkLevel(BNPerk.IntrusionSuite) <= 0 {
        return;
    }

    let breachAction: ref<DeviceRemoteBreachAction> = this.ActionCustomDeviceRemoteBreach();
    ArrayPush(actions, breachAction);
}

