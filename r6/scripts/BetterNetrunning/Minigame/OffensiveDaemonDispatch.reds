
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
  let deckID: ItemID = EquipmentSystem.GetData(playerPuppet).GetActiveItem(gamedataEquipmentArea.SystemReplacementCW);
  if !EquipmentSystem.IsItemCyberdeck(deckID) {
    if IsDefined(cbs) { cbs.ShowWarning("CASCADE: NO CYBERDECK"); }
    BNInfo("OffensiveDaemonDispatch", "Cascade: no cyberdeck equipped");
    return;
  }
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(gi);
  let deckData: ref<gameItemData> = ts.GetItemData(playerPuppet, deckID);
  if !IsDefined(deckData) {
    BNWarn("OffensiveDaemonDispatch", "Cascade: could not get cyberdeck item data");
    return;
  }
  let parts: array<InnerItemData>;
  deckData.GetItemParts(parts);
  BNInfo("OffensiveDaemonDispatch", "Cascade: cyberdeck has " + ToString(ArraySize(parts)) + " installed part(s)");
  let qhItem: ItemID;
  let pi: Int32 = 0;
  while pi < ArraySize(parts) {
    let candidate: ItemID = InnerItemData.GetItemID(parts[pi]);
    if ItemID.IsValid(candidate) {
      let partTDBID: TweakDBID = ItemID.GetTDBID(candidate);
      let partRecord: wref<Item_Record> = TweakDBInterface.GetItemRecord(partTDBID);
      if IsDefined(partRecord) && partRecord.GetObjectActionsCount() > 0
          && partTDBID != t"Items.GenericItemRoot" {
        qhItem = candidate;
        BNInfo("OffensiveDaemonDispatch", "Cascade: using part[" + ToString(pi) + "] as quickhack (actions=" + ToString(partRecord.GetObjectActionsCount()) + ")");
        pi = ArraySize(parts);
      } else {
        BNDebug("OffensiveDaemonDispatch", "Cascade: skipping part[" + ToString(pi) + "] — no ObjectActions");
      }
    }
    pi += 1;
  }
  if !ItemID.IsValid(qhItem) {
    if IsDefined(cbs) { cbs.ShowWarning("CASCADE: NO QUICKHACK IN SLOT 1"); }
    BNInfo("OffensiveDaemonDispatch", "Cascade: no valid quickhack found in cyberdeck parts");
    return;
  }

  let qhTDBID: TweakDBID = ItemID.GetTDBID(qhItem);
  let puppetActionID: TweakDBID;
  let actionResolved: Bool = false;

  let itemRecord: wref<Item_Record> = TweakDBInterface.GetItemRecord(qhTDBID);
  if IsDefined(itemRecord) {
    let ai: Int32 = 0;
    while ai < itemRecord.GetObjectActionsCount() && !actionResolved {
      let action: wref<ObjectAction_Record> = itemRecord.GetObjectActionsItem(ai);
      if IsDefined(action) {
        let actionType: wref<ObjectActionType_Record> = action.ObjectActionType();
        if IsDefined(actionType) && Equals(actionType.Type(), gamedataObjectActionType.PuppetQuickHack) {
          puppetActionID = action.GetID();
          actionResolved = true;
          BNInfo("OffensiveDaemonDispatch", "Cascade: PuppetQuickHack action found at index " + ToString(ai));
        }
      }
      ai += 1;
    }
  }

  if !actionResolved {
    if IsDefined(cbs) { cbs.ShowWarning("CASCADE: QUICKHACK NOT APPLICABLE"); }
    BNWarn("OffensiveDaemonDispatch", "Cascade: no PuppetQuickHack ObjectAction found for equipped quickhack");
    return;
  }

  let npcs: array<MarkEntry> = markingSystem.GetMarkedNPCEntries();
  let dispatched: Int32 = 0;
  let ni: Int32 = 0;
  while ni < ArraySize(npcs) {
    let puppet: ref<ScriptedPuppet> = GameInstance.FindEntityByID(gi, npcs[ni].entityID) as ScriptedPuppet;
    if IsDefined(puppet) && !puppet.IsDead() {
      let npcPS: ref<ScriptedPuppetPS> = puppet.GetPuppetPS();
      if IsDefined(npcPS) && npcPS.m_bnNPCIceDefeated {
        let act: ref<PuppetAction> = new PuppetAction();
        act.RegisterAsRequester(puppet.GetEntityID());
        act.SetExecutor(player);
        act.SetObjectActionID(puppetActionID);
        act.SetUp(npcPS);
        act.SetDisableSpread(true);
        act.ProcessRPGAction(gi);
        dispatched += 1;
      }
    }
    ni += 1;
  }

  markingSystem.AddSessionHeat(0.15);

  if dispatched > 0 {
    if IsDefined(cbs) { cbs.ShowWarning("CASCADE: QUICKHACK DISTRIBUTED"); }
    BNInfo("OffensiveDaemonDispatch", "Cascade Protocol: distributed to " + ToString(dispatched) + " NPC(s)");
  } else {
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
