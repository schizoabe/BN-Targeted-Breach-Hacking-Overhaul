


























module BetterNetrunning.Minigame

import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Marking.*
import BetterNetrunning.Network.*
import BetterNetrunning.Integration.*
import BetterNetrunning.Perks.*

@addMethod(MinigameGenerationRuleScalingPrograms)
public final func InjectBetterNetrunningPrograms(programs: script_ref<array<MinigameProgramData>>) -> Void {

  if BetterNetrunningSettings.EnableClassicMode() {
    return;
  }



  let device: ref<SharedGameplayPS>;
  let devicePS: ref<ScriptableDeviceComponentPS>;
  let gameInstance: GameInstance;

  if IsDefined(this.m_entity as ScriptedPuppet) {
    let puppet: ref<ScriptedPuppet> = this.m_entity as ScriptedPuppet;
    device       = puppet.GetPS().GetDeviceLink();
    gameInstance = puppet.GetGame();
  } else {
    let gameDevice: ref<Device> = this.m_entity as Device;
    if !IsDefined(gameDevice) {
      BNError("ProgramInjection", "m_entity is neither ScriptedPuppet nor Device — cannot inject");
      return;
    }
    devicePS     = gameDevice.GetDevicePS();



    let implicitCast: ref<SharedGameplayPS> = devicePS;
    device       = implicitCast;
    gameInstance = gameDevice.GetGame();
  }

  if !IsDefined(device) {
    BNError("ProgramInjection", "SharedGameplayPS is null — skipping injection");
    return;
  }



  let markingSystem: ref<MarkingStateSystem> =
    GameInstance.GetScriptableSystemsContainer(gameInstance).Get(
      BNConstants.CLASS_MARKING_STATE_SYSTEM()
    ) as MarkingStateSystem;

  let hasMarks: Bool = IsDefined(markingSystem) && markingSystem.HasAnyMarked();
  let sessionHeat: Float = IsDefined(markingSystem) ? markingSystem.GetSessionHeat() : 0.0;





  if IsDefined(this.m_entity as AccessPoint) {
    let perkSysAP: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gameInstance);

    let noiseProg: MinigameProgramData;
    noiseProg.actionID    = BNConstants.PROGRAM_SIGNAL_NOISE();
    noiseProg.programName = n"SignalNoiseProtocol";
    ArrayInsert(Deref(programs), 0, noiseProg);

    if !IsDefined(perkSysAP) || perkSysAP.GetPerkLevel(BNPerk.DisarmICE) > 0 {
      let disarmProg: MinigameProgramData;
      disarmProg.actionID    = BNConstants.PROGRAM_DISARM_ICE();
      disarmProg.programName = n"LocKey#Better-Netrunning-DisarmICE-Name";
      ArrayInsert(Deref(programs), 0, disarmProg);
    }

    if !IsDefined(perkSysAP) || perkSysAP.GetPerkLevel(BNPerk.HidePresence) > 0 {
      let hideProg: MinigameProgramData;
      hideProg.actionID    = BNConstants.PROGRAM_HIDE_PRESENCE();
      hideProg.programName = n"LocKey#Better-Netrunning-HidePresence-Name";
      ArrayInsert(Deref(programs), 0, hideProg);
    }

    BNDebug("ProgramInjection", "AP daemons injected: SignalNoise"
      + (!IsDefined(perkSysAP) || perkSysAP.GetPerkLevel(BNPerk.HidePresence) > 0 ? " + HidePresence" : "")
      + (!IsDefined(perkSysAP) || perkSysAP.GetPerkLevel(BNPerk.DisarmICE) > 0 ? " + DisarmICE" : ""));
  }


  if !hasMarks {
    BNDebug("ProgramInjection", "No marks — deferring to post-filter Icepick injection");
    return;
  }








  let networkState: NetworkState;
  if IsDefined(devicePS) {
    networkState = NetworkStateUtils.GetNetworkState(devicePS, gameInstance);
  }



  let subnetOpen: Bool = IsDefined(this.m_entity as AccessPoint)
    || NetworkStateUtils.IsSubnetAccessible(networkState)
    || (IsDefined(markingSystem) && markingSystem.GetDisarmICETimer() > 0.0);



  let turretAdded: Bool = false;
  let cameraAdded: Bool = false;
  let npcAdded:    Bool = false;
  let basicAdded:  Bool = false;


  if markingSystem.HasMarkedDefense() && subnetOpen {
    let prog: MinigameProgramData;
    prog.actionID    = BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS();
    prog.programName = BNConstants.LOCKEY_ACCESS();
    ArrayInsert(Deref(programs), 0, prog);
    turretAdded = true;
  }


  if markingSystem.HasMarkedCameras() && subnetOpen {
    let prog: MinigameProgramData;
    prog.actionID    = BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS();
    prog.programName = BNConstants.LOCKEY_ACCESS();
    ArrayInsert(Deref(programs), 0, prog);
    cameraAdded = true;
  }


  if markingSystem.HasMarkedNPCs() && subnetOpen {
    let prog: MinigameProgramData;
    prog.actionID    = BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS();
    prog.programName = BNConstants.LOCKEY_ACCESS();
    ArrayInsert(Deref(programs), 0, prog);
    npcAdded = true;
  }


  if markingSystem.HasMarkedRoot() && subnetOpen {
    let prog: MinigameProgramData;
    prog.actionID    = BNConstants.PROGRAM_UNLOCK_QUICKHACKS();
    prog.programName = BNConstants.LOCKEY_ACCESS();
    ArrayInsert(Deref(programs), 0, prog);
    basicAdded = true;
  }

  BNDebug("ProgramInjection",
    "Targeted injection complete — programs now: " + ToString(ArraySize(Deref(programs)))
    + " SubnetOpen=" + ToString(subnetOpen)
    + " ICEHits=" + ToString(networkState.hitsApplied) + "/" + ToString(networkState.hitsRequired)
    + " Turret=" + ToString(turretAdded)
    + " Camera=" + ToString(cameraAdded)
    + " NPC="    + ToString(npcAdded)
    + " Basic="  + ToString(basicAdded));
}


