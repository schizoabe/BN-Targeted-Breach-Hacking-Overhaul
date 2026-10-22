
module BetterNetrunning.Minigame

import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Marking.*
import BetterNetrunning.Perks.*
import BetterNetrunning.CounterBreach.*

@addMethod(ScriptableDeviceComponentPS)
public final func BNDispatchOffensiveDaemons() -> Void {
  if !BetterNetrunningSettings.OffensiveDaemonsEnabled() { return; }

  let gi: GameInstance = this.GetGameInstance();
  let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().HackingMinigame);
  let programs: array<TweakDBID> = FromVariant<array<TweakDBID>>(
    bb.GetVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms)
  );

  let hasCamShutdown:    Bool = false;
  let hasCamMalfunction: Bool = false;
  let hasTurretShutdown: Bool = false;
  let hasTurretFriendly: Bool = false;
  let hasEntropyProtocol: Bool = false;
  let hasCascade:         Bool = false;
  let i: Int32 = 0;
  while i < ArraySize(programs) {
    if programs[i] == BNConstants.PROGRAM_NETWORK_CAMERA_SHUTDOWN()    { hasCamShutdown    = true; }
    if programs[i] == BNConstants.PROGRAM_NETWORK_CAMERA_MALFUNCTION() { hasCamMalfunction = true; }
    if programs[i] == BNConstants.PROGRAM_NETWORK_TURRET_SHUTDOWN()    { hasTurretShutdown = true; }
    if programs[i] == BNConstants.PROGRAM_NETWORK_TURRET_FRIENDLY()    { hasTurretFriendly = true; }
    if programs[i] == BNConstants.PROGRAM_BN_ENTROPY_PROTOCOL()        { hasEntropyProtocol = true; }
    if programs[i] == BNConstants.PROGRAM_CASCADE_PROTOCOL()           { hasCascade         = true; }
    i += 1;
  }

  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gi);
  let markingSystem: ref<MarkingStateSystem> = container.Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;

  if (hasCamShutdown || hasCamMalfunction) && IsDefined(markingSystem) && markingSystem.HasMarkedCameras() {
    this.BNDispatchCameraOffensiveDaemons(markingSystem, hasCamShutdown, hasCamMalfunction, gi);
  }

  if (hasTurretShutdown || hasTurretFriendly) && IsDefined(markingSystem) && markingSystem.HasMarkedDefense() {
    this.BNDispatchTurretOffensiveDaemons(markingSystem, hasTurretShutdown, hasTurretFriendly, gi);
  }

  if hasEntropyProtocol && IsDefined(markingSystem) && markingSystem.HasMarkedNPCs() {
    this.BNDispatchNPCOffensiveDaemons(markingSystem, gi);
  }
  if hasCascade && IsDefined(markingSystem) && markingSystem.HasMarkedNPCs() {
    this.BNDispatchCascadeProtocol(markingSystem, gi);
  }
}

@addMethod(ScriptableDeviceComponentPS)
private final func BNDispatchCameraOffensiveDaemons(
  markingSystem: ref<MarkingStateSystem>,
  hasShutdown:    Bool,
  hasMalfunction: Bool,
  gi:             GameInstance
) -> Void {
  let cameras: array<MarkEntry> = markingSystem.GetMarkedCameraEntries();
  let player:   ref<GameObject> = this.GetPlayerMainObject();
  let dispatched: Int32 = 0;
  let ci: Int32 = 0;

  while ci < ArraySize(cameras) {
    let entity: ref<Device> = GameInstance.FindEntityByID(gi, cameras[ci].entityID) as Device;
    if IsDefined(entity) {
      let ps: ref<ScriptableDeviceComponentPS> = entity.GetDevicePS();
      let sharedPS: ref<SharedGameplayPS> = ps;
      if IsDefined(ps) && IsDefined(sharedPS)
          && sharedPS.m_betterNetrunningUnlockTimestampCameras > 0.0 {

        if hasShutdown {
          let action: ref<ScriptableDeviceAction> = ps.ActionProgramSetDeviceOff();
          action.RegisterAsRequester(entity.GetEntityID());
          action.SetExecutor(player);
          action.SetObjectActionID(BNConstants.PROGRAM_NETWORK_CAMERA_SHUTDOWN());
          action.ProcessRPGAction(gi);
        }

        if hasMalfunction {
          let action: ref<ScriptableDeviceAction> = ps.ActionProgramSetDeviceAttitude();
          action.RegisterAsRequester(entity.GetEntityID());
          action.SetExecutor(player);
          action.SetObjectActionID(BNConstants.PROGRAM_NETWORK_CAMERA_MALFUNCTION());
          action.ProcessRPGAction(gi);
        }

        dispatched += 1;
      }
    }
    ci += 1;
  }

  if dispatched > 0 {
    BNInfo("OffensiveDaemonDispatch", "Camera daemons dispatched to " + ToString(dispatched)
      + " camera(s). Shutdown=" + ToString(hasShutdown)
      + " Malfunction=" + ToString(hasMalfunction));
  } else {
    BNDebug("OffensiveDaemonDispatch", "Camera daemons found but no stamped marked cameras reachable");
  }
}

@addMethod(ScriptableDeviceComponentPS)
private final func BNDispatchTurretOffensiveDaemons(
  markingSystem: ref<MarkingStateSystem>,
  hasShutdown:   Bool,
  hasFriendly:   Bool,
  gi:            GameInstance
) -> Void {
  let turrets:    array<MarkEntry> = markingSystem.GetMarkedDefenseEntries();
  let player:     ref<GameObject>  = this.GetPlayerMainObject();
  let dispatched: Int32 = 0;
  let ti: Int32 = 0;

  while ti < ArraySize(turrets) {
    let entity: ref<Device> = GameInstance.FindEntityByID(gi, turrets[ti].entityID) as Device;
    if IsDefined(entity) {
      let ps: ref<ScriptableDeviceComponentPS> = entity.GetDevicePS();
      if IsDefined(ps) && ps.m_betterNetrunningUnlockTimestampTurrets > 0.0 {
        if hasShutdown {
          let action: ref<ScriptableDeviceAction> = ps.ActionProgramSetDeviceOff();
          action.RegisterAsRequester(entity.GetEntityID());
          action.SetExecutor(player);
          action.SetObjectActionID(BNConstants.PROGRAM_NETWORK_TURRET_SHUTDOWN());
          action.ProcessRPGAction(gi);
        }
        if hasFriendly {
          let action: ref<ScriptableDeviceAction> = ps.ActionProgramSetDeviceAttitude();
          action.RegisterAsRequester(entity.GetEntityID());
          action.SetExecutor(player);
          action.SetObjectActionID(BNConstants.PROGRAM_NETWORK_TURRET_FRIENDLY());
          action.ProcessRPGAction(gi);
        }
        dispatched += 1;
      }
    }
    ti += 1;
  }

  if dispatched > 0 {
    BNInfo("OffensiveDaemonDispatch", "Turret daemons dispatched to " + ToString(dispatched)
      + " turret(s). Shutdown=" + ToString(hasShutdown)
      + " Friendly=" + ToString(hasFriendly));
  } else {
    BNDebug("OffensiveDaemonDispatch", "Turret daemons found but no stamped marked turrets reachable");
  }
}

@addMethod(ScriptableDeviceComponentPS)
private final func BNDispatchNPCOffensiveDaemons(
  markingSystem: ref<MarkingStateSystem>,
  gi:            GameInstance
) -> Void {
  let perkSys:   ref<BNPerkSystem> = BNPerkSystem.GetInstance(gi);
  let perkLevel: Int32 = IsDefined(perkSys) ? perkSys.GetPerkLevel(BNPerk.EntropyProtocol) : 0;
  if perkLevel <= 0 { return; }

  let effectID: TweakDBID;
  if perkLevel >= 3      { effectID = t"BaseStatusEffect.BN_EntropyProtocol_III"; }
  else if perkLevel >= 2 { effectID = t"BaseStatusEffect.BN_EntropyProtocol_II";  }
  else                   { effectID = t"BaseStatusEffect.BN_EntropyProtocol_I";   }

  let npcs:       array<MarkEntry> = markingSystem.GetMarkedNPCEntries();
  let player:     ref<GameObject>  = this.GetPlayerMainObject();
  let dispatched: Int32 = 0;
  let ni: Int32 = 0;

  while ni < ArraySize(npcs) {
    let puppet: ref<ScriptedPuppet> = GameInstance.FindEntityByID(gi, npcs[ni].entityID) as ScriptedPuppet;
    if IsDefined(puppet) {
      let npcPS: ref<ScriptedPuppetPS> = puppet.GetPuppetPS();
      if IsDefined(npcPS) && npcPS.m_bnNPCIceDefeated {
        StatusEffectHelper.ApplyStatusEffect(puppet, effectID, player.GetEntityID());
        dispatched += 1;
        BNDebug("OffensiveDaemonDispatch", "EntropyProtocol Tier " + ToString(perkLevel) + " applied to NPC[" + ToString(ni) + "]");
      }
    }
    ni += 1;
  }

  if dispatched > 0 {
    BNInfo("OffensiveDaemonDispatch", "NPC EntropyProtocol Tier " + ToString(perkLevel) + " applied to " + ToString(dispatched) + " NPC(s)");
  } else {
    BNDebug("OffensiveDaemonDispatch", "EntropyProtocol found but no stamped marked NPCs reachable");
  }
}

@addMethod(ScriptableDeviceComponentPS)
private final func BNDispatchCascadeProtocol(
  markingSystem: ref<MarkingStateSystem>,
  gi:            GameInstance
) -> Void {
  let player: ref<GameObject> = this.GetPlayerMainObject();
  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gi);
  let cbs: ref<CounterBreachSystem> = container.Get(BNConstants.CLASS_COUNTER_BREACH_SYSTEM()) as CounterBreachSystem;

  let playerPuppet: ref<PlayerPuppet> = player as PlayerPuppet;
  if !IsDefined(playerPuppet) {
    BNWarn("OffensiveDaemonDispatch", "Cascade: could not get player puppet");
    return;
  }

  let selectedAction: wref<ObjectAction_Record> = BNCascadeDispatchUtils.ResolveSelectedAction(gi, playerPuppet, cbs, markingSystem);
  if !IsDefined(selectedAction) { return; }
  let resolvedActionName: String = NameToString(selectedAction.ActionName());
  BNInfo("OffensiveDaemonDispatch", "Cascade: dispatching " + resolvedActionName + " via real upload pipeline");

  let uiFlatID: TweakDBID = selectedAction.GetID();
  TDBID.Append(uiFlatID, t"objectActionUI");
  let uiID: TweakDBID = FromVariant<TweakDBID>(TweakDBInterface.GetFlat(uiFlatID));
  TDBID.Append(uiID, t"caption");
  let captionCN: CName = FromVariant<CName>(TweakDBInterface.GetFlat(uiID));
  let qhDisplayName: String = IsNameValid(captionCN) ? GetLocalizedTextByKey(captionCN) : resolvedActionName;

  let npcs: array<MarkEntry> = markingSystem.GetMarkedNPCEntries();
  let nextDelay: Float = 0.0;
  let dispatched: Int32 = 0;
  let ni: Int32 = 0;
  while ni < ArraySize(npcs) {
    let puppet: ref<ScriptedPuppet> = GameInstance.FindEntityByID(gi, npcs[ni].entityID) as ScriptedPuppet;
    if IsDefined(puppet) && !puppet.IsDead() {
      let npcPS: ref<ScriptedPuppetPS> = puppet.GetPuppetPS();
      if IsDefined(npcPS) && npcPS.m_bnNPCIceDefeated {
        let data: ref<QuickhackData> = RPGManager.CreateSimpleQuickhackData(playerPuppet, puppet, selectedAction);
        if IsDefined(data) {
          if dispatched == 0 {
            BNCascadeDispatchUtils.TriggerQuickhackUpload(playerPuppet, data);
          } else {
            GameInstance.GetDelaySystem(gi).DelayCallback(BNCascadeSecondUploadCallback.Create(playerPuppet, puppet, data), nextDelay);
          }
          nextDelay += data.m_uploadTime + 0.1;
          dispatched += 1;
          BNDebug("OffensiveDaemonDispatch", "Cascade: queued upload " + ToString(dispatched) + " → " + puppet.GetDisplayName() + " (delay=" + ToString(nextDelay) + ")");
        }
      }
    }
    ni += 1;
  }

  markingSystem.AddSessionHeat(0.15);

  if dispatched > 0 {
    let summary: String = StrLen(qhDisplayName) > 0 ? qhDisplayName : resolvedActionName;
    if IsDefined(cbs) { cbs.ShowWarning(GetLocalizedTextByKey(n"Better-Netrunning-Alert-CascadeBroadcastPrefix") + summary + GetLocalizedTextByKey(n"Better-Netrunning-Alert-CascadeBroadcastSuffix")); }
    BNInfo("OffensiveDaemonDispatch", "Cascade Protocol: " + summary + " queued for " + ToString(dispatched) + " NPC(s)");
  } else {
    if IsDefined(cbs) { cbs.ShowWarning(GetLocalizedTextByKey(n"Better-Netrunning-Alert-CascadeNoStampedNPCs")); }
    BNDebug("OffensiveDaemonDispatch", "Cascade: no stamped marked NPCs reachable");
  }
}

@wrapMethod(NPCPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.BN_EntropyProtocol_I");
  StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.BN_EntropyProtocol_II");
  StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.BN_EntropyProtocol_III");
  return wrappedMethod(evt);
}

@wrapMethod(ScriptedPuppet)
protected cb func OnDefeated(evt: ref<DefeatedEvent>) -> Bool {
  StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.BN_EntropyProtocol_I");
  StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.BN_EntropyProtocol_II");
  StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.BN_EntropyProtocol_III");
  return wrappedMethod(evt);
}
