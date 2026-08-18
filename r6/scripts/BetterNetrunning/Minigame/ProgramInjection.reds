
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

  let exitProg: MinigameProgramData;
  exitProg.actionID    = BNConstants.PROGRAM_BN_EXIT_PROTOCOL();
  exitProg.programName = n"BN_ExitProtocol";
  ArrayInsert(Deref(programs), 0, exitProg);

  let markingSystem: ref<MarkingStateSystem> =
    GameInstance.GetScriptableSystemsContainer(gameInstance).Get(
      BNConstants.CLASS_MARKING_STATE_SYSTEM()
    ) as MarkingStateSystem;

  let hasMarks: Bool = IsDefined(markingSystem) && markingSystem.HasAnyMarked();
  let sessionHeat: Float = IsDefined(markingSystem) ? markingSystem.GetSessionHeat() : 0.0;

  if IsDefined(this.m_entity as AccessPoint) {
    let perkSysAP: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gameInstance);

    let isAttack: Bool = IsDefined(markingSystem) && markingSystem.IsAttackMode();
    if isAttack {
      BNDebug("ProgramInjection", "Attack mode — AP stealth daemons suppressed (Ghost/Null/Raven)");
    } else {
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

  if markingSystem.HasMarkedDefense() && subnetOpen && markingSystem.IsScoutMode() {
    let prog: MinigameProgramData;
    prog.actionID    = BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS();
    prog.programName = BNConstants.LOCKEY_ACCESS();
    ArrayInsert(Deref(programs), 0, prog);
    turretAdded = true;
  }

  if markingSystem.HasMarkedCameras() && subnetOpen && markingSystem.IsScoutMode() {
    let prog: MinigameProgramData;
    prog.actionID    = BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS();
    prog.programName = BNConstants.LOCKEY_ACCESS();
    ArrayInsert(Deref(programs), 0, prog);
    cameraAdded = true;
  }

  BNDebug("ProgramInjection", "OffensiveDaemonsEnabled=" + ToString(BetterNetrunningSettings.OffensiveDaemonsEnabled())
    + " isNotPuppet=" + ToString(!IsDefined(this.m_entity as ScriptedPuppet))
    + " HasMarkedCameras=" + ToString(markingSystem.HasMarkedCameras())
    + " AnyStamped=" + ToString(markingSystem.AnyMarkedCameraStamped()));
  if BetterNetrunningSettings.OffensiveDaemonsEnabled()
      && markingSystem.IsAttackMode()
      && !IsDefined(this.m_entity as ScriptedPuppet)
      && markingSystem.HasMarkedCameras()
      && markingSystem.AnyMarkedCameraStamped() {
    let hasShutdown:    Bool = false;
    let hasMalfunction: Bool = false;
    let dp: Int32 = 0;
    while dp < ArraySize(Deref(programs)) {
      let dpid: TweakDBID = Deref(programs)[dp].actionID;
      if dpid == BNConstants.PROGRAM_NETWORK_CAMERA_SHUTDOWN()    { hasShutdown    = true; }
      if dpid == BNConstants.PROGRAM_NETWORK_CAMERA_MALFUNCTION() { hasMalfunction = true; }
      dp += 1;
    }
    if !hasShutdown {
      let shutdownProg: MinigameProgramData;
      shutdownProg.actionID    = BNConstants.PROGRAM_NETWORK_CAMERA_SHUTDOWN();
      shutdownProg.programName = n"NetworkCameraShutdown";
      ArrayInsert(Deref(programs), 0, shutdownProg);
    }
    if !hasMalfunction {
      let malfProg: MinigameProgramData;
      malfProg.actionID    = BNConstants.PROGRAM_NETWORK_CAMERA_MALFUNCTION();
      malfProg.programName = n"NetworkCameraMalfunction";
      ArrayInsert(Deref(programs), 0, malfProg);
    }
    BNInfo("ProgramInjection", "Camera offensive daemons: Shutdown="
      + (hasShutdown    ? "already present" : "injected")
      + " Malfunction=" + (hasMalfunction ? "already present" : "injected"));
  }

  BNDebug("ProgramInjection", "TurretOffensive check: HasMarkedDefense=" + ToString(markingSystem.HasMarkedDefense())
    + " AnyTurretStamped=" + ToString(markingSystem.AnyMarkedTurretStamped()));
  if BetterNetrunningSettings.OffensiveDaemonsEnabled()
      && markingSystem.IsAttackMode()
      && !IsDefined(this.m_entity as ScriptedPuppet)
      && markingSystem.HasMarkedDefense()
      && markingSystem.AnyMarkedTurretStamped() {
    let hasTurretShutdown: Bool = false;
    let hasTurretFriendly: Bool = false;
    let tp: Int32 = 0;
    while tp < ArraySize(Deref(programs)) {
      let tpid: TweakDBID = Deref(programs)[tp].actionID;
      if tpid == BNConstants.PROGRAM_NETWORK_TURRET_SHUTDOWN() { hasTurretShutdown = true; }
      if tpid == BNConstants.PROGRAM_NETWORK_TURRET_FRIENDLY() { hasTurretFriendly = true; }
      tp += 1;
    }
    if !hasTurretShutdown {
      let shutdownProg: MinigameProgramData;
      shutdownProg.actionID    = BNConstants.PROGRAM_NETWORK_TURRET_SHUTDOWN();
      shutdownProg.programName = n"NetworkTurretShutdown";
      ArrayInsert(Deref(programs), 0, shutdownProg);
    }
    if !hasTurretFriendly {
      let friendlyProg: MinigameProgramData;
      friendlyProg.actionID    = BNConstants.PROGRAM_NETWORK_TURRET_FRIENDLY();
      friendlyProg.programName = n"NetworkTurretFriendly";
      ArrayInsert(Deref(programs), 0, friendlyProg);
    }
    BNInfo("ProgramInjection", "Turret offensive daemons: Shutdown="
      + (hasTurretShutdown ? "already present" : "injected")
      + " Friendly=" + (hasTurretFriendly ? "already present" : "injected"));
  }

  let perkSysNPC: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gameInstance);
  let epLevel: Int32 = IsDefined(perkSysNPC) ? perkSysNPC.GetPerkLevel(BNPerk.EntropyProtocol) : 0;
  BNDebug("ProgramInjection", "NPCOffensive check: HasMarkedNPCs=" + ToString(markingSystem.HasMarkedNPCs())
    + " AnyNPCStamped=" + ToString(markingSystem.AnyMarkedNPCStamped())
    + " EntropyProtocolPerk=" + ToString(epLevel));
  if BetterNetrunningSettings.OffensiveDaemonsEnabled()
      && markingSystem.IsAttackMode()
      && !IsDefined(this.m_entity as ScriptedPuppet)
      && markingSystem.HasMarkedNPCs()
      && markingSystem.AnyMarkedNPCStamped()
      && epLevel > 0 {
    let hasEntropyProtocol: Bool = false;
    let np: Int32 = 0;
    while np < ArraySize(Deref(programs)) {
      if Deref(programs)[np].actionID == BNConstants.PROGRAM_BN_ENTROPY_PROTOCOL() { hasEntropyProtocol = true; }
      np += 1;
    }
    if !hasEntropyProtocol {
      let mvProg: MinigameProgramData;
      mvProg.actionID    = BNConstants.PROGRAM_BN_ENTROPY_PROTOCOL();
      mvProg.programName = n"BN_EntropyProtocol";
      ArrayInsert(Deref(programs), 0, mvProg);
    }
    BNInfo("ProgramInjection", "NPC offensive daemons: EntropyProtocol="
      + (hasEntropyProtocol ? "already present" : "injected"));
  }

  let cpLevel: Int32 = IsDefined(perkSysNPC) ? perkSysNPC.GetPerkLevel(BNPerk.CascadeProtocol) : 0;
  if BetterNetrunningSettings.OffensiveDaemonsEnabled()
      && markingSystem.IsAttackMode()
      && !IsDefined(this.m_entity as ScriptedPuppet)
      && markingSystem.HasMarkedNPCs()
      && markingSystem.AnyMarkedNPCStamped()
      && cpLevel > 0 {
    let hasCascade: Bool = false;
    let cp: Int32 = 0;
    while cp < ArraySize(Deref(programs)) {
      if Deref(programs)[cp].actionID == BNConstants.PROGRAM_CASCADE_PROTOCOL() { hasCascade = true; }
      cp += 1;
    }
    if !hasCascade {
      let cascadeProg: MinigameProgramData;
      cascadeProg.actionID    = BNConstants.PROGRAM_CASCADE_PROTOCOL();
      cascadeProg.programName = n"BN_CascadeProtocol";
      ArrayInsert(Deref(programs), 0, cascadeProg);
    }
    BNInfo("ProgramInjection", "NPC offensive daemons: CascadeProtocol="
      + (hasCascade ? "already present" : "injected"));
  }

  if markingSystem.HasMarkedNPCs() && subnetOpen && markingSystem.IsScoutMode() {
    let prog: MinigameProgramData;
    prog.actionID    = BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS();
    prog.programName = BNConstants.LOCKEY_ACCESS();
    ArrayInsert(Deref(programs), 0, prog);
    npcAdded = true;
  }

  if markingSystem.HasMarkedRoot() && subnetOpen && markingSystem.IsScoutMode() {
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

