module BetterNetrunning

import BetterNetrunning.Logging.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Integration.*
import BetterNetrunning.RemoteBreach.Core.*
import BetterNetrunning.RemoteBreach.Actions.*
import BetterNetrunning.Minigame.*
import BetterNetrunning.Systems.*
import BetterNetrunning.RadialUnlock.*
import BetterNetrunning.Marking.*
import BetterNetrunning.CounterBreach.*
import BetterNetrunningConfig.*
import BetterNetrunning.Network.*
import BetterNetrunning.Perks.*

@wrapMethod(MinigameGenerationRuleScalingPrograms)
public final func FilterPlayerPrograms(programs: script_ref<array<MinigameProgramData>>) -> Void {

  if IsDefined(this.m_entity) {
    this.m_blackboardSystem.Get(GetAllBlackboardDefs().HackingMinigame)
      .SetVariant(GetAllBlackboardDefs().HackingMinigame.Entity, ToVariant(this.m_entity));
  }

  let gameInstance: GameInstance;
  if IsDefined(this.m_entity as ScriptedPuppet) {
    gameInstance = (this.m_entity as ScriptedPuppet).GetGame();
  } else if IsDefined(this.m_entity as Device) {
    gameInstance = (this.m_entity as Device).GetGame();
  }

  let markingSystem: ref<MarkingStateSystem>;
  let hasMarks: Bool = false;
  if GameInstance.IsValid(gameInstance) {
    markingSystem = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    hasMarks = IsDefined(markingSystem) && markingSystem.HasAnyMarked();
  }

  if GameInstance.IsValid(gameInstance) {
    let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gameInstance);

    let npcRBSS: ref<NPCRemoteBreachStateSystem> =
      container.Get(BNConstants.CLASS_NPC_REMOTE_BREACH_STATE_SYSTEM()) as NPCRemoteBreachStateSystem;
    if IsDefined(npcRBSS) && IsDefined(npcRBSS.GetCurrentNPC()) {
      let puppet: ref<ScriptedPuppet> = this.m_entity as ScriptedPuppet;
      if IsDefined(puppet) && Equals(puppet.GetPS().GetID(), npcRBSS.GetCurrentNPC().GetID()) {
        if !IsDefined(markingSystem) || !markingSystem.IsScoutMode() {
          ArrayClear(Deref(programs));
          BNInfo("FilterPlayerPrograms", "NPC remote breach blocked — not in Scout mode");
          return;
        }
        BNDebug("FilterPlayerPrograms", "NPC remote breach board — preserving programs");
        return;
      }
    }

    let devRBSS: ref<DeviceRemoteBreachStateSystem> =
      container.Get(BNConstants.CLASS_DEVICE_REMOTE_BREACH_STATE_SYSTEM()) as DeviceRemoteBreachStateSystem;
    if IsDefined(devRBSS) && IsDefined(devRBSS.GetCurrentDevice()) && this.m_isRemoteBreach {
      let device: ref<Device> = this.m_entity as Device;
      if IsDefined(device) && Equals(device.GetDevicePS().GetID(), devRBSS.GetCurrentDevice().GetID()) {

        let perkSysRB: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gameInstance);
        if !IsDefined(perkSysRB) || perkSysRB.GetPerkLevel(BNPerk.IntrusionSuite) <= 0 {
          ArrayClear(Deref(programs));
          BNInfo("FilterPlayerPrograms", "Intrusion Suite not owned — device remote breach blocked");
          return;
        }
        if !IsDefined(markingSystem) || !markingSystem.IsScoutMode() {
          ArrayClear(Deref(programs));
          BNInfo("FilterPlayerPrograms", "Device remote breach blocked — not in Scout mode");
          return;
        }
        BNDebug("FilterPlayerPrograms", "Device remote breach board — preserving programs");
        return;
      }
    }

  }

  let npcPuppet: ref<ScriptedPuppet> = this.m_entity as ScriptedPuppet;
  if IsDefined(npcPuppet) && npcPuppet.IsIncapacitated() {
    if GameInstance.IsValid(gameInstance) {
      let perkSysNPC: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gameInstance);
      if IsDefined(perkSysNPC) && perkSysNPC.GetPerkLevel(BNPerk.NeuralTap) <= 0 {
        ArrayClear(Deref(programs));
        BNInfo("FilterPlayerPrograms", "Neural Tap not owned — unconscious NPC breach blocked");
        return;
      }
    }
    ArrayClear(Deref(programs));

    if IsDefined(markingSystem) && markingSystem.IsDefendMode() {
      let perkSysUNPC: ref<BNPerkSystem> = BNPerkSystem.GetInstance(this.m_player.GetGame());
      let offloadUnlockedNPC: Bool = IsDefined(perkSysUNPC) && perkSysUNPC.GetPerkLevel(BNPerk.OffloadProtocol) > 0;
      if offloadUnlockedNPC {
        let offloadNPC: MinigameProgramData;
        offloadNPC.actionID    = BNConstants.PROGRAM_BN_OFFLOAD_PROTOCOL();
        offloadNPC.programName = n"BN_OffloadProtocol";
        ArrayPush(Deref(programs), offloadNPC);
      }
      let exitNPC: MinigameProgramData;
      exitNPC.actionID    = BNConstants.PROGRAM_BN_EXIT_PROTOCOL();
      exitNPC.programName = n"BN_ExitProtocol";
      ArrayPush(Deref(programs), exitNPC);
      let ddNPC: ref<DisplayedDaemonsStateSystem> = GameInstance.GetScriptableSystemsContainer(this.m_player.GetGame())
        .Get(BNConstants.CLASS_DISPLAYED_DAEMONS_STATE_SYSTEM()) as DisplayedDaemonsStateSystem;
      if IsDefined(ddNPC) {
        let shownNPC: array<TweakDBID>;
        if offloadUnlockedNPC { ArrayPush(shownNPC, BNConstants.PROGRAM_BN_OFFLOAD_PROTOCOL()); }
        ArrayPush(shownNPC, BNConstants.PROGRAM_BN_EXIT_PROTOCOL());
        ddNPC.SetDisplayedDaemons(shownNPC);
      }
      BNInfo("FilterPlayerPrograms", "Defend mode — unconscious NPC board: Offload=" + ToString(offloadUnlockedNPC) + " + Exit Protocol");
      return;
    }

    if IsDefined(markingSystem) {
      if markingSystem.HasMarkedRoot() {
        let p0: MinigameProgramData;
        p0.actionID    = BNConstants.PROGRAM_UNLOCK_QUICKHACKS();
        p0.programName = n"BNRootSubnet";
        ArrayPush(Deref(programs), p0);
      }
      if markingSystem.HasMarkedCameras() {
        let p1: MinigameProgramData;
        p1.actionID    = BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS();
        p1.programName = n"BNSurveillanceSubnet";
        ArrayPush(Deref(programs), p1);
      }
      if markingSystem.HasMarkedDefense() {
        let p2: MinigameProgramData;
        p2.actionID    = BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS();
        p2.programName = n"BNDefenseSubnet";
        ArrayPush(Deref(programs), p2);
      }
    }

    let signalNoise: MinigameProgramData;
    signalNoise.actionID    = BNConstants.PROGRAM_SIGNAL_NOISE();
    signalNoise.programName = n"SignalNoiseProtocol";
    ArrayPush(Deref(programs), signalNoise);

    let exitProtoNPC: MinigameProgramData;
    exitProtoNPC.actionID    = BNConstants.PROGRAM_BN_EXIT_PROTOCOL();
    exitProtoNPC.programName = n"BN_ExitProtocol";
    ArrayPush(Deref(programs), exitProtoNPC);

    let perkSysP: ref<BNPerkSystem>;
    if GameInstance.IsValid(gameInstance) {
      perkSysP = BNPerkSystem.GetInstance(gameInstance);
    }
    if !IsDefined(perkSysP) || perkSysP.GetPerkLevel(BNPerk.Purge) > 0 {
      let purge: MinigameProgramData;
      purge.actionID    = BNConstants.PROGRAM_BN_ICEPICK_V2();
      purge.programName = n"PurgeProtocol";
      ArrayPush(Deref(programs), purge);
    }

    let displayedDaemons: array<TweakDBID>;
    let di: Int32 = 0;
    while di < ArraySize(Deref(programs)) {
      ArrayPush(displayedDaemons, Deref(programs)[di].actionID);
      di += 1;
    }
    let ddSS: ref<DisplayedDaemonsStateSystem> = GameInstance.GetScriptableSystemsContainer(this.m_player.GetGame())
      .Get(BNConstants.CLASS_DISPLAYED_DAEMONS_STATE_SYSTEM()) as DisplayedDaemonsStateSystem;
    if IsDefined(ddSS) { ddSS.SetDisplayedDaemons(displayedDaemons); }

    BNInfo("FilterPlayerPrograms", "Unconscious NPC breach — injected "
      + ToString(ArraySize(Deref(programs))) + " daemons (hasMarks=" + ToString(hasMarks) + ")");
    return;
  }

  if GameInstance.IsValid(gameInstance) {
    let breachDevicePS: ref<ScriptableDeviceComponentPS>;
    if IsDefined(this.m_entity as Device) {
      breachDevicePS = (this.m_entity as Device).GetDevicePS();
    }
    if IsDefined(breachDevicePS) {
      NetworkStateUtils.OnBreachEntered(breachDevicePS, gameInstance);
    }

    let cbs: ref<CounterBreachSystem> =
      GameInstance.GetScriptableSystemsContainer(gameInstance)
        .Get(BNConstants.CLASS_COUNTER_BREACH_SYSTEM()) as CounterBreachSystem;
    if IsDefined(cbs) {
      let isStandalone: Bool;
      if IsDefined(this.m_entity as AccessPoint) || (this.m_entity as GameObject).IsPuppet() {
        isStandalone = false;
      } else if IsDefined(this.m_entity as Device) {
        isStandalone = !(this.m_entity as Device).GetDevicePS().IsConnectedToPhysicalAccessPoint();
      }
      cbs.SetLastBreachWasStandalone(isStandalone);

      if isStandalone && IsDefined(breachDevicePS) {
        let netState: NetworkState = NetworkStateUtils.GetNetworkState(breachDevicePS, gameInstance);
        let sessionHeat: Float = IsDefined(markingSystem) ? markingSystem.GetSessionHeat() : 0.0;
        cbs.ShowWarning(NetworkStateUtils.FormatVulnerabilityMessage(netState, sessionHeat));
      }
    }
  }

  if IsDefined(markingSystem) && markingSystem.IsDefendMode() {
    ArrayClear(Deref(programs));
    let perkSysDef: ref<BNPerkSystem> = BNPerkSystem.GetInstance(this.m_player.GetGame());
    let offloadUnlocked: Bool = IsDefined(perkSysDef) && perkSysDef.GetPerkLevel(BNPerk.OffloadProtocol) > 0;
    if offloadUnlocked {
      let offloadProg: MinigameProgramData;
      offloadProg.actionID    = BNConstants.PROGRAM_BN_OFFLOAD_PROTOCOL();
      offloadProg.programName = n"BN_OffloadProtocol";
      ArrayPush(Deref(programs), offloadProg);
    }
    let exitProg: MinigameProgramData;
    exitProg.actionID    = BNConstants.PROGRAM_BN_EXIT_PROTOCOL();
    exitProg.programName = n"BN_ExitProtocol";
    ArrayPush(Deref(programs), exitProg);
    let ddSysDef: ref<DisplayedDaemonsStateSystem> = GameInstance.GetScriptableSystemsContainer(this.m_player.GetGame())
      .Get(BNConstants.CLASS_DISPLAYED_DAEMONS_STATE_SYSTEM()) as DisplayedDaemonsStateSystem;
    if IsDefined(ddSysDef) {
      let shownDef: array<TweakDBID>;
      if offloadUnlocked { ArrayPush(shownDef, BNConstants.PROGRAM_BN_OFFLOAD_PROTOCOL()); }
      ArrayPush(shownDef, BNConstants.PROGRAM_BN_EXIT_PROTOCOL());
      ddSysDef.SetDisplayedDaemons(shownDef);
    }
    BNInfo("FilterPlayerPrograms", "Defend mode — board override: Offload=" + ToString(offloadUnlocked) + " + Exit Protocol");
    return;
  }

  let protectedPrograms: array<MinigameProgramData>;
  this.ExtractBetterNetrunningDaemons(programs, protectedPrograms);

  BNTrace("FilterPlayerPrograms",
    "Extracted " + ToString(ArraySize(protectedPrograms)) + " BN daemons, "
    + ToString(ArraySize(Deref(programs))) + " remain, hasMarks=" + ToString(hasMarks));

  wrappedMethod(programs);

  if !hasMarks {
    ApplyNetworkConnectivityFilter(this.m_entity, protectedPrograms);
  } else {
    BNDebug("FilterPlayerPrograms", "Skipping ApplyNetworkConnectivityFilter — targeted breach");
  }

  this.RestoreBetterNetrunningDaemons(programs, protectedPrograms);

  BNTrace("FilterPlayerPrograms",
    "After restore: " + ToString(ArraySize(Deref(programs))) + " total programs");

  this.InjectBetterNetrunningPrograms(programs);

  BNTrace("FilterPlayerPrograms",
    "After injection: " + ToString(ArraySize(Deref(programs))) + " total programs");

  let initialProgramCount: Int32 = ArraySize(Deref(programs));

  let i: Int32 = ArraySize(Deref(programs)) - 1;
  while i >= 0 {
    let pid: TweakDBID = Deref(programs)[i].actionID;
    let subnetHasMarks: Bool = false;
    let allMarksUnlocked: Bool = false;
    if IsDefined(markingSystem) {
      if pid == BNConstants.PROGRAM_UNLOCK_QUICKHACKS() {
        subnetHasMarks = markingSystem.HasMarkedRoot();
        if subnetHasMarks { allMarksUnlocked = markingSystem.AllMarkedRootStamped(); }
      } else if pid == BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS() {
        subnetHasMarks = markingSystem.HasMarkedNPCs();
        if subnetHasMarks { allMarksUnlocked = markingSystem.AllMarkedNPCsStamped(); }
      } else if pid == BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS() {
        subnetHasMarks = markingSystem.HasMarkedCameras();
        if subnetHasMarks { allMarksUnlocked = markingSystem.AllMarkedCamerasStamped(); }
      } else if pid == BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS() {
        subnetHasMarks = markingSystem.HasMarkedDefense();
        if subnetHasMarks { allMarksUnlocked = markingSystem.AllMarkedTurretsStamped(); }
      }
    }
    if allMarksUnlocked || (!subnetHasMarks && ShouldRemoveBreachedPrograms(pid, this.m_entity as GameObject)) {
      ArrayErase(Deref(programs), i);
    }
    i -= 1;
  }

  let connectedToNetwork: Bool;
  let data: ConnectedClassTypes;
  let devPS: ref<SharedGameplayPS>;

  if (this.m_entity as GameObject).IsPuppet() {
    connectedToNetwork = true;
    data = (this.m_entity as ScriptedPuppet).GetMasterConnectedClassTypes();
    devPS = (this.m_entity as ScriptedPuppet).GetPS().GetDeviceLink();
  } else {
    let isAccessPoint: Bool = IsDefined(this.m_entity as AccessPoint);
    if isAccessPoint {
      connectedToNetwork = true;
    } else {
      connectedToNetwork = (this.m_entity as Device).GetDevicePS().IsConnectedToPhysicalAccessPoint();
    }
    data = (this.m_entity as Device).GetDevicePS().CheckMasterConnectedClassTypes();
    devPS = (this.m_entity as Device).GetDevicePS();
  }

  let removedPrograms: array<TweakDBID>;

  i = ArraySize(Deref(programs)) - 1;
  while i >= 0 {
    let actionID: TweakDBID = Deref(programs)[i].actionID;
    let miniGameActionRecord: wref<MinigameAction_Record> = TweakDBInterface.GetMinigameActionRecord(actionID);
    let programCountBefore: Int32 = ArraySize(Deref(programs));
    let shouldRemove: Bool = false;
    let filterName: String = "";

    if !hasMarks && ShouldRemoveNetworkPrograms(actionID, connectedToNetwork) {
      shouldRemove = true;
      filterName = "NetworkFilter";
    } else if !hasMarks && ShouldRemoveDeviceBackdoorPrograms(actionID, this.m_entity as GameObject) {
      shouldRemove = true;
      filterName = "DeviceBackdoorFilter";
    } else if ShouldRemoveAccessPointPrograms(actionID, miniGameActionRecord, this.m_isRemoteBreach) {
      shouldRemove = true;
      filterName = "AccessPointFilter";
    } else if ShouldRemoveNonNetrunnerPrograms(actionID, miniGameActionRecord, this.m_isRemoteBreach, this.m_entity as GameObject) {
      shouldRemove = true;
      filterName = "NonNetrunnerFilter";
    } else if !hasMarks && ShouldRemoveDeviceTypePrograms(actionID, miniGameActionRecord, data) {
      shouldRemove = true;
      filterName = "DeviceTypeFilter";
    } else if BonusDaemonUtils.IsDatamineDaemon(actionID) {
      shouldRemove = true;
      filterName = "DatamineFilter";
    } else if !hasMarks && ShouldRemoveOutOfRangeDevicePrograms(actionID, (this.m_entity as GameObject).GetGame(), this.GetBreachPositionForFiltering(), this.m_entity as GameObject) {
      shouldRemove = true;
      filterName = "PhysicalRangeFilter";
    }

    if shouldRemove {
      ArrayErase(Deref(programs), i);
      ArrayPush(removedPrograms, actionID);
      DebugUtils.LogProgramFilteringStep(filterName, programCountBefore, ArraySize(Deref(programs)), actionID, "[FilterPlayerPrograms]");
    }
    i -= 1;
  };

  ApplyDNRDaemonGating(programs, devPS, this.m_isRemoteBreach, this.m_player as PlayerPuppet, this.m_entity);

  let finalProgramCount: Int32 = ArraySize(Deref(programs));
  DebugUtils.LogFilteringSummary(initialProgramCount, finalProgramCount, removedPrograms, "[FilterPlayerPrograms]");

  BNTrace("FilterPlayerPrograms",
    "Before Icepick check: " + ToString(ArraySize(Deref(programs))) + " programs");

  this.EnsureIcepickFallback(programs);

  let displayedDaemons: array<TweakDBID>;
  let i_store: Int32 = 0;
  while i_store < ArraySize(Deref(programs)) {
    ArrayPush(displayedDaemons, Deref(programs)[i_store].actionID);
    i_store += 1;
  }
  let stateSystem: ref<DisplayedDaemonsStateSystem> = GameInstance.GetScriptableSystemsContainer(this.m_player.GetGame())
    .Get(BNConstants.CLASS_DISPLAYED_DAEMONS_STATE_SYSTEM()) as DisplayedDaemonsStateSystem;
  if IsDefined(stateSystem) {
    stateSystem.SetDisplayedDaemons(displayedDaemons);
  }
}

@addMethod(MinigameGenerationRuleScalingPrograms)
private final func EnsureIcepickFallback(programs: script_ref<array<MinigameProgramData>>) -> Void {
  if BetterNetrunningSettings.EnableClassicMode() {
    return;
  }

  if IsDefined(this.m_entity as AccessPoint) { return; }

  let giEI: GameInstance;
  if IsDefined(this.m_entity as Device) { giEI = (this.m_entity as Device).GetGame(); }
  else if IsDefined(this.m_entity as ScriptedPuppet) { giEI = (this.m_entity as ScriptedPuppet).GetGame(); }
  if GameInstance.IsValid(giEI) {
    let mssEI: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(giEI)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if IsDefined(mssEI) && mssEI.IsAttackMode() { return; }
  }

  let iceAlreadyBroken: Bool = false;
  if GameInstance.IsValid(giEI) {
    let devPS: ref<ScriptableDeviceComponentPS>;
    if IsDefined(this.m_entity as Device) { devPS = (this.m_entity as Device).GetDevicePS(); }
    if IsDefined(devPS) {
      let netState: NetworkState = NetworkStateUtils.GetNetworkState(devPS, giEI);
      iceAlreadyBroken = netState.hitsRequired > 0 && NetworkStateUtils.IsSubnetAccessible(netState);
    }
  }

  let k: Int32 = 0;
  while k < ArraySize(Deref(programs)) {
    let pid: TweakDBID = Deref(programs)[k].actionID;
    if pid == BNConstants.PROGRAM_UNLOCK_QUICKHACKS()
        || pid == BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS()
        || pid == BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS()
        || pid == BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS()
        || pid == BNConstants.PROGRAM_HIDE_PRESENCE()
        || pid == BNConstants.PROGRAM_DISARM_ICE()
        || pid == BNConstants.PROGRAM_SIGNAL_NOISE() {
      return;
    }
    k += 1;
  }

  let j: Int32 = ArraySize(Deref(programs)) - 1;
  while j >= 0 {
    let pid: TweakDBID = Deref(programs)[j].actionID;
    if pid == BNConstants.PROGRAM_UNLOCK_QUICKHACKS()
        || pid == BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS()
        || pid == BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS()
        || pid == BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS()
        || pid == t"MinigameAction.NetworkLowerICEMedium"
        || pid == BNConstants.PROGRAM_BN_ICEPICK_V1()
        || pid == BNConstants.PROGRAM_BN_ICEPICK_V2()
        || pid == BNConstants.PROGRAM_BN_ICEPICK_V3() {
      ArrayErase(Deref(programs), j);
    }
    j -= 1;
  }

  let gi: GameInstance;
  if IsDefined(this.m_entity as Device) {
    gi = (this.m_entity as Device).GetGame();
  } else if IsDefined(this.m_entity as ScriptedPuppet) {
    gi = (this.m_entity as ScriptedPuppet).GetGame();
  }
  let perkSysFB: ref<BNPerkSystem>;
  if GameInstance.IsValid(gi) {
    perkSysFB = BNPerkSystem.GetInstance(gi);
  }

  let hasPerkSys: Bool = IsDefined(perkSysFB);

  if !iceAlreadyBroken {
    let v1: MinigameProgramData;
    v1.actionID    = BNConstants.PROGRAM_BN_ICEPICK_V1();
    v1.programName = n"FractureProtocol";
    ArrayInsert(Deref(programs), 0, v1);
  }

  if !hasPerkSys || perkSysFB.GetPerkLevel(BNPerk.Purge) > 0 {
    let v2: MinigameProgramData;
    v2.actionID    = BNConstants.PROGRAM_BN_ICEPICK_V2();
    v2.programName = n"PurgeProtocol";
    ArrayInsert(Deref(programs), ArraySize(Deref(programs)), v2);
  }

  if (!hasPerkSys || perkSysFB.GetPerkLevel(BNPerk.Sunder) > 0) && !iceAlreadyBroken {
    let v3: MinigameProgramData;
    v3.actionID    = BNConstants.PROGRAM_BN_ICEPICK_V3();
    v3.programName = n"SunderProtocol";
    ArrayInsert(Deref(programs), ArraySize(Deref(programs)), v3);
  }

  BNDebug("FilterPlayerPrograms",
    "EnsureIcepickFallback:"
    + (!iceAlreadyBroken ? " Fracture" : " (ICE broken — Fracture/Sunder skipped)")
    + (!hasPerkSys || perkSysFB.GetPerkLevel(BNPerk.Purge) > 0 ? " + Purge" : "")
    + ((!hasPerkSys || perkSysFB.GetPerkLevel(BNPerk.Sunder) > 0) && !iceAlreadyBroken ? " + Sunder" : ""));
}

@addMethod(MinigameGenerationRuleScalingPrograms)
private final func InjectIcepickIfNoMarks(programs: script_ref<array<MinigameProgramData>>) -> Void {
  this.EnsureIcepickFallback(programs);
}

@addMethod(MinigameGenerationRuleScalingPrograms)
private final func ExtractBetterNetrunningDaemons(
  programs: script_ref<array<MinigameProgramData>>,
  protectedPrograms: script_ref<array<MinigameProgramData>>
) -> Void {
  let i: Int32 = ArraySize(Deref(programs)) - 1;
  while i >= 0 {
    let program: MinigameProgramData = Deref(programs)[i];
    if IsBetterNetrunningSubnetDaemon(program.actionID) {
      BNTrace("ExtractBetterNetrunningDaemons",
        "Extracting: " + TDBID.ToStringDEBUG(program.actionID));
      ArrayPush(Deref(protectedPrograms), program);
      ArrayErase(Deref(programs), i);
    }
    i -= 1;
  }
}

@addMethod(MinigameGenerationRuleScalingPrograms)
private final func RestoreBetterNetrunningDaemons(
  programs: script_ref<array<MinigameProgramData>>,
  protectedPrograms: array<MinigameProgramData>
) -> Void {
  let i: Int32 = 0;
  let count: Int32 = ArraySize(protectedPrograms);
  while i < count {
    BNTrace("RestoreBetterNetrunningDaemons",
      "Restoring: " + TDBID.ToStringDEBUG(protectedPrograms[i].actionID));
    ArrayPush(Deref(programs), protectedPrograms[i]);
    i += 1;
  }
}

@addMethod(MinigameGenerationRuleScalingPrograms)
private final func GetBreachPositionForFiltering() -> Vector4 {
  let targetEntity: wref<GameObject> = this.m_entity as GameObject;
  if IsDefined(targetEntity) {
    return targetEntity.GetWorldPosition();
  }
  let player: ref<PlayerPuppet> = this.m_player as PlayerPuppet;
  if IsDefined(player) {
    BNWarn("GetBreachPositionForFiltering", "Using player position as fallback");
    return player.GetWorldPosition();
  }
  BNError("GetBreachPositionForFiltering", "Could not get breach position");
  return Vector4(-999999.0, -999999.0, -999999.0, 1.0);
}
