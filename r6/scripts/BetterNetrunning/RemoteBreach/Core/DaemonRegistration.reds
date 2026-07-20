


















module BetterNetrunning.RemoteBreach.Core

import BetterNetrunning.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*

@if(ModuleExists("HackingExtensions"))
import HackingExtensions.*

@if(ModuleExists("HackingExtensions.Programs"))
import HackingExtensions.Programs.*





@if(ModuleExists("HackingExtensions"))

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
    wrappedMethod();

    this.RegisterBetterNetrunningDaemons();

    return true;
}

@if(ModuleExists("HackingExtensions"))
@addMethod(PlayerPuppet)
private func RegisterBetterNetrunningDaemons() -> Void {
    let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(this.GetGame());
    let hackingSystem: ref<CustomHackingSystem> = container.Get(BNConstants.CLASS_CUSTOM_HACKING_SYSTEM()) as CustomHackingSystem;

    if !IsDefined(hackingSystem) {
        return;
    }



    let unlockBasicAction: ref<DeviceDaemonAction> = new DeviceDaemonAction();
    unlockBasicAction.SetDaemonType(DaemonTypes.Basic());
    hackingSystem.AddProgramAction(BNConstants.PROGRAM_ACTION_BN_UNLOCK_BASIC(), unlockBasicAction);

    let unlockNPCAction: ref<DeviceDaemonAction> = new DeviceDaemonAction();
    unlockNPCAction.SetDaemonType(DaemonTypes.NPC());
    hackingSystem.AddProgramAction(BNConstants.PROGRAM_ACTION_BN_UNLOCK_NPC(), unlockNPCAction);

    let unlockCameraAction: ref<DeviceDaemonAction> = new DeviceDaemonAction();
    unlockCameraAction.SetDaemonType(DaemonTypes.Camera());
    hackingSystem.AddProgramAction(BNConstants.PROGRAM_ACTION_BN_UNLOCK_CAMERA(), unlockCameraAction);

    let unlockTurretAction: ref<DeviceDaemonAction> = new DeviceDaemonAction();
    unlockTurretAction.SetDaemonType(DaemonTypes.Turret());
    hackingSystem.AddProgramAction(BNConstants.PROGRAM_ACTION_BN_UNLOCK_TURRET(), unlockTurretAction);







    let rbIcepickV1: ref<RemoteBreachIcepickV1Action> = new RemoteBreachIcepickV1Action();
    hackingSystem.AddProgramAction(BNConstants.PROGRAM_ACTION_BN_RB_ICEPICK_V1(), rbIcepickV1);

    let rbIcepickV2: ref<RemoteBreachIcepickV2Action> = new RemoteBreachIcepickV2Action();
    hackingSystem.AddProgramAction(BNConstants.PROGRAM_ACTION_BN_RB_ICEPICK_V2(), rbIcepickV2);

    let rbIcepickV3: ref<RemoteBreachIcepickV3Action> = new RemoteBreachIcepickV3Action();
    hackingSystem.AddProgramAction(BNConstants.PROGRAM_ACTION_BN_RB_ICEPICK_V3(), rbIcepickV3);




    let vehicleUnlockBasicAction: ref<DeviceDaemonAction> = new DeviceDaemonAction();
    vehicleUnlockBasicAction.SetDaemonType(DaemonTypes.Basic());
    hackingSystem.AddProgramAction(BNConstants.PROGRAM_ACTION_BN_UNLOCK_VEHICLE(), vehicleUnlockBasicAction);
}

