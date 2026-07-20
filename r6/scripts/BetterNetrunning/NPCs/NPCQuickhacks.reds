



















module BetterNetrunning.NPCs
import BetterNetrunning.Logging.*

import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Systems.*
import BetterNetrunning.Breach.*



@wrapMethod(ScriptedPuppetPS)
public func OnSetExposeQuickHacks(evt: ref<SetExposeQuickHacks>) -> EntityNotificationType {

  if !this.IsConnectedToAccessPoint() {
    BNInfo("NPCQuickhacks", "OnSetExposeQuickHacks: standalone NPC — allowing vanilla");
    return wrappedMethod(evt);
  }


  let deviceLink: ref<SharedGameplayPS> = this.GetDeviceLink();
  if !IsDefined(deviceLink) {
    BNInfo("NPCQuickhacks", "OnSetExposeQuickHacks: no device link — allowing vanilla");
    return wrappedMethod(evt);
  }


  let npcUnlockTime: Float = deviceLink.m_betterNetrunningUnlockTimestampNPCs;
  if npcUnlockTime > 0.0 {
    BNInfo("NPCQuickhacks", "OnSetExposeQuickHacks: timestamp set (" + ToString(npcUnlockTime) + ") — allowing vanilla");
    return wrappedMethod(evt);
  }


  BNInfo("NPCQuickhacks", "OnSetExposeQuickHacks: BLOCKED (timestamp=0, connectedToAP=true)");
  return EntityNotificationType.DoNotNotifyEntity;
}


@wrapMethod(ScriptedPuppetPS)
public final const func GetAllChoices(const actions: script_ref<array<wref<ObjectAction_Record>>>, const context: script_ref<GetActionsContext>, puppetActions: script_ref<array<ref<PuppetAction>>>) -> Void {

  let permissions: NPCHackPermissions = this.CalculateNPCHackPermissions();


  wrappedMethod(actions, context, puppetActions);


  let ownerPuppet: wref<ScriptedPuppet> = this.GetOwnerEntity() as ScriptedPuppet;
  if IsDefined(ownerPuppet) && ownerPuppet.IsDead() {
    ArrayClear(Deref(puppetActions));
    return;
  }


  let ownerEntity: wref<GameObject> = this.GetOwnerEntity();
  let localPlayer: ref<PlayerPuppet> = GetPlayer(this.GetGameInstance());
  let attiudeTowardsPlayer: EAIAttitude = IsDefined(ownerEntity) && IsDefined(localPlayer)
    ? ownerEntity.GetAttitudeTowards(localPlayer)
    : EAIAttitude.AIA_Neutral;
  this.ApplyBetterNetrunningQuickhackFilter(puppetActions, permissions, attiudeTowardsPlayer);


  DebugUtils.LogNPCQuickhackState(this, puppetActions, "NPCQuickhacks");
}


@addMethod(ScriptedPuppetPS)
private final func ApplyBetterNetrunningQuickhackFilter(
  puppetActions: script_ref<array<ref<PuppetAction>>>,
  permissions: NPCHackPermissions,
  attiudeTowardsPlayer: EAIAttitude
) -> Void {
  let i: Int32 = ArraySize(Deref(puppetActions)) - 1;

  while i >= 0 {
    let action: ref<PuppetAction> = Deref(puppetActions)[i];


    if IsDefined(action as AccessBreach) {
      ArrayErase(Deref(puppetActions), i);
    } else {

      if this.ShouldQuickhackBeInactive(action, permissions) {

        this.SetQuickhackInactiveReason(action, attiudeTowardsPlayer);
      } else {

        action.SetActive();
      }
    }

    i -= 1;
  }

}




@addMethod(ScriptedPuppetPS)
private final func CalculateNPCHackPermissions() -> NPCHackPermissions {
  let permissions: NPCHackPermissions;
  let gameInstance: GameInstance = this.GetGameInstance();
  let npc: wref<GameObject> = this.GetOwnerEntityWeak() as GameObject;


  permissions.isBreached = this.m_quickHacksExposed;


  let isConnectedToNetwork: Bool = this.IsConnectedToAccessPoint();


  if !isConnectedToNetwork {
    permissions.isBreached = true;
  }


  permissions.allowCovert = ShouldUnlockHackNPC(gameInstance, npc, BetterNetrunningSettings.AlwaysNPCsCovert(), BetterNetrunningSettings.ProgressionCyberdeckNPCsCovert(), BetterNetrunningSettings.ProgressionIntelligenceNPCsCovert(), BetterNetrunningSettings.ProgressionEnemyRarityNPCsCovert());
  permissions.allowCombat = ShouldUnlockHackNPC(gameInstance, npc, BetterNetrunningSettings.AlwaysNPCsCombat(), BetterNetrunningSettings.ProgressionCyberdeckNPCsCombat(), BetterNetrunningSettings.ProgressionIntelligenceNPCsCombat(), BetterNetrunningSettings.ProgressionEnemyRarityNPCsCombat());
  permissions.allowControl = ShouldUnlockHackNPC(gameInstance, npc, BetterNetrunningSettings.AlwaysNPCsControl(), BetterNetrunningSettings.ProgressionCyberdeckNPCsControl(), BetterNetrunningSettings.ProgressionIntelligenceNPCsControl(), BetterNetrunningSettings.ProgressionEnemyRarityNPCsControl());
  permissions.allowUltimate = ShouldUnlockHackNPC(gameInstance, npc, BetterNetrunningSettings.AlwaysNPCsUltimate(), BetterNetrunningSettings.ProgressionCyberdeckNPCsUltimate(), BetterNetrunningSettings.ProgressionIntelligenceNPCsUltimate(), BetterNetrunningSettings.ProgressionEnemyRarityNPCsUltimate());
  permissions.allowPing = BetterNetrunningSettings.AlwaysAllowPing() || permissions.allowCovert;
  permissions.allowWhistle = BetterNetrunningSettings.AlwaysAllowWhistle() || permissions.allowCovert;

  return permissions;
}




@addMethod(ScriptedPuppetPS)
private final func ShouldQuickhackBeInactive(puppetAction: ref<PuppetAction>, permissions: NPCHackPermissions) -> Bool {

  if permissions.isBreached || this.IsWhiteListedForHacks() {
    return false;
  }


  let actionRecord: ref<ObjectAction_Record> = puppetAction.GetObjectActionRecord();
  if !IsDefined(actionRecord) { return true; }
  let hackCategoryRecord = actionRecord.HackCategory();
  if !IsDefined(hackCategoryRecord) { return true; }
  let hackCategory: CName = hackCategoryRecord.EnumName();
  if Equals(hackCategory, n"CovertHack") && permissions.allowCovert {
    return false;
  }
  if Equals(hackCategory, n"DamageHack") && permissions.allowCombat {
    return false;
  }
  if Equals(hackCategory, n"ControlHack") && permissions.allowControl {
    return false;
  }
  if Equals(hackCategory, n"UltimateHack") && permissions.allowUltimate {
    return false;
  }


  if IsDefined(puppetAction as PingSquad) && permissions.allowPing {
    return false;
  }
  if Equals(puppetAction.GetObjectActionRecord().ActionName(), n"Whistle") && permissions.allowWhistle {
    return false;
  }

  return true;
}


@addMethod(ScriptedPuppetPS)
private final func SetQuickhackInactiveReason(puppetAction: ref<PuppetAction>, attiudeTowardsPlayer: EAIAttitude) -> Void {

  let isRemoteBreachLocked: Bool = BreachLockUtils.IsNPCLockedByRemoteBreachFailure(this);



  if isRemoteBreachLocked {
    puppetAction.SetInactiveWithReason(false, BNConstants.LOCKEY_NO_NETWORK_ACCESS());  // "No network access rights"
  } else {
    puppetAction.SetInactiveWithReason(false, LocKeyToString(BNConstants.LOCKEY_QUICKHACKS_LOCKED()));
  }
}




@addMethod(ScriptedPuppetPS)
protected final func IsWhiteListedForHacks() -> Bool {
  let puppet: wref<ScriptedPuppet> = this.GetOwnerEntity() as ScriptedPuppet;
  if !IsDefined(puppet) { return false; }
  let recordID: TweakDBID = puppet.GetRecordID();
  return recordID == t"Character.q000_tutorial_course_01_patroller"
      || recordID == t"Character.q000_tutorial_course_02_enemy_02"
      || recordID == t"Character.q000_tutorial_course_02_enemy_03"
      || recordID == t"Character.q000_tutorial_course_02_enemy_04"
      || recordID == t"Character.q000_tutorial_course_03_guard_01"
      || recordID == t"Character.q000_tutorial_course_03_guard_02"
      || recordID == t"Character.q000_tutorial_course_03_guard_03";
}

