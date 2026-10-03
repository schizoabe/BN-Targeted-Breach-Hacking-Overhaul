
module BetterNetrunning.CounterBreach

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Marking.*
import BetterNetrunning.Perks.*
import HackingExtensions.*

@addField(UploadFromNPCToPlayerListener)
public let m_bnFirewallEngaged: Bool;

public class BNFirewallSucceededEvent extends OnCustomHackingSucceeded {
  public let m_npcPuppet:    wref<ScriptedPuppet>;
  public let m_playerPuppet: wref<PlayerPuppet>;
  public let m_listener:     wref<UploadFromNPCToPlayerListener>;
  public let m_actionID:     TweakDBID;

  public func Execute() -> Void {
    let gi: GameInstance = this.gameInstance;
    GameInstance.GetTimeSystem(gi).UnsetTimeDilation(n"BNFirewall");

    if IsDefined(this.m_listener) {
      BNFirewallUtils.CancelUpload(gi, this.m_listener, this.m_playerPuppet);
    }

    let perkSys: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gi);

    let canReflect: Bool = IsDefined(perkSys) && perkSys.GetPerkLevel(BNPerk.FirewallReflect) > 0;
    if canReflect && IsDefined(this.m_npcPuppet) {
      BNFirewallUtils.ReflectHack(gi, this.m_npcPuppet, this.m_actionID);
      BNInfo("Firewall", "Firewall Reflect: hack bounced to attacker");
    }

    let canBreach: Bool = canReflect && IsDefined(perkSys) && perkSys.GetPerkLevel(BNPerk.FirewallBreach) > 0;
    if canBreach && IsDefined(this.m_npcPuppet) && !this.m_npcPuppet.IsDead() {
      let npcPS: ref<ScriptedPuppetPS> = this.m_npcPuppet.GetPuppetPS();
      if IsDefined(npcPS) {
        npcPS.BN_StampSJKIBreached();
        if npcPS.m_bnNPCIceHitsRequired <= 0 { npcPS.m_bnNPCIceHitsRequired = 1; }
        npcPS.m_bnNPCIceHitsApplied = npcPS.m_bnNPCIceHitsRequired;
        npcPS.m_bnNPCIceDefeated = true;
        let exposeEvt: ref<SetExposeQuickHacks> = new SetExposeQuickHacks();
        exposeEvt.isRemote = true;
        npcPS.GetPersistencySystem().QueueEntityEvent(
          PersistentID.ExtractEntityID(npcPS.GetID()), exposeEvt);
        let mss: ref<MarkingStateSystem> =
          GameInstance.GetScriptableSystemsContainer(gi)
            .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
        if IsDefined(mss) {
          mss.AddMarkNamed(this.m_npcPuppet.GetEntityID(), MarkedSubnetType.NPC,
            this.m_npcPuppet.GetDisplayName(), npcPS.m_bnNPCIceHitsRequired);
        }
        BNInfo("Firewall", "Firewall Breach: netrunner ICE stamped + marked for Cascade");
      }
    }

    BNInfo("Firewall", "Firewall succeeded — block" + (canReflect ? " + reflect" : "") + (canBreach ? " + breach" : ""));
  }
}

public class BNFirewallFailedEvent extends OnCustomHackingFailed {
  public let m_listener: wref<UploadFromNPCToPlayerListener>;

  public func Execute() -> Void {

    if IsDefined(this.m_listener) {
      this.m_listener.m_bnFirewallEngaged = false;
    }
    GameInstance.GetTimeSystem(this.gameInstance).UnsetTimeDilation(n"BNFirewall");
    BNInfo("Firewall", "Firewall minigame failed — upload resumes, hack lands");
  }
}

public class BNFirewallUtils {

  public static func CancelUpload(gi: GameInstance, listener: wref<UploadFromNPCToPlayerListener>, player: wref<PlayerPuppet>) -> Void {
    if !IsDefined(listener) { return; }

    let statPools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gi);
    let objID: StatsObjectID = Cast<StatsObjectID>(listener.m_playerPuppet.GetEntityID());

    statPools.RequestRemovingStatPool(objID, gamedataStatPoolType.QuickHackUpload);
    statPools.RequestUnregisteringListener(objID, gamedataStatPoolType.QuickHackUpload, listener);

    listener.m_HUDData.active = false;
    listener.m_hudBlackboard.SetBool(GetAllBlackboardDefs().UI_HUDProgressBar.Active, false);

    if IsDefined(player) {
      StatusEffectHelper.RemoveStatusEffect(player, t"AIQuickHackStatusEffect.BeingHacked");
      player.SetIsBeingRevealed(false);
      StatusEffectHelper.RemoveStatusEffect(player, t"BaseStatusEffect.RevealInterrupted");
    }

    SaveLocksManager.RequestSaveLockRemove(gi, n"PlayerBeingHacked");

    let npc: wref<ScriptedPuppet> = listener.m_npcPuppet;
    if IsDefined(npc) {
      npc.QueueEvent(new RemoveLinkEvent());
      let unlinkFx: ref<RemoveLinkedStatusEffectsEvent> = new RemoveLinkedStatusEffectsEvent();
      if IsDefined(listener.m_action) {
        let aid: TweakDBID = listener.m_action.GetObjectActionID();
        unlinkFx.ssAction = aid == t"AIQuickHack.HackRevealPosition"
          || aid == t"AIQuickHack.PreventionHackRevealPosition";
      }
      npc.QueueEvent(unlinkFx);

      if !StatusEffectSystem.ObjectHasStatusEffect(npc, t"AIQuickHackStatusEffect.HackingInterrupted") {
        StatusEffectHelper.ApplyStatusEffect(npc, t"AIQuickHackStatusEffect.HackingInterrupted", npc.GetEntityID());
      }
      ScriptedPuppet.SendActionSignal(npc, n"HackingCompleted", 1.0);
    }

    listener.m_bnFirewallEngaged = false;
  }

  public static func ReflectHack(gi: GameInstance, npc: wref<ScriptedPuppet>, actionID: TweakDBID) -> Void {
    if !IsDefined(npc) { return; }

    let effectID: TweakDBID;
    if      actionID == t"AIQuickHack.Overheat"       || actionID == t"AIQuickHack.CombatOverheat"            { effectID = t"BaseStatusEffect.Burning";            }
    else if actionID == t"AIQuickHack.Contagion"                                                               { effectID = t"BaseStatusEffect.Poisoned";           }
    else if actionID == t"AIQuickHack.ShortCircuit"                                                            { effectID = t"BaseStatusEffect.Electrocuted";       }
    else if actionID == t"AIQuickHack.HackRevealPosition" || actionID == t"AIQuickHack.PreventionHackRevealPosition" { effectID = t"BaseStatusEffect.Blind";        }
    else if actionID == t"AIQuickHack.Weapon_Malfunction"                                                      { effectID = t"BaseStatusEffect.WeaponMalfunction"; }
    else                                                                                                       { effectID = t"BaseStatusEffect.Electrocuted";       }

    StatusEffectHelper.ApplyStatusEffect(npc, effectID, npc.GetEntityID());
    BNInfo("Firewall", "Hack reflected: " + TDBID.ToStringDEBUG(actionID) + " -> " + TDBID.ToStringDEBUG(effectID));
  }
}

@wrapMethod(UploadFromNPCToPlayerListener)
protected cb func OnStatPoolAdded() -> Bool {
  let result: Bool = wrappedMethod();
  let gi: GameInstance = this.m_gameInstance;

  this.m_bnFirewallEngaged = false;

  if IsDefined(this.m_action)
      && Equals(this.m_action.GetObjectActionID(), t"AIQuickHack.BlackICE_RAMDrain") {
    return result;
  }

  this.BNTryFirewall(gi);

  return result;
}

@addMethod(UploadFromNPCToPlayerListener)
private final func BNTryFirewall(gi: GameInstance) -> Bool {

  let mss: ref<MarkingStateSystem> =
    GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if !IsDefined(mss) || !mss.IsDefendMode() { return false; }

  let cbs: ref<CounterBreachSystem> =
    GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_COUNTER_BREACH_SYSTEM()) as CounterBreachSystem;
  if !IsDefined(cbs) { return false; }

  let charges: Int32 = cbs.GetFirewallCharges(gi);
  if charges <= 0 {
    BNInfo("Firewall", "Firewall depleted — hack proceeds to ICE");
    return false;
  }

  let hackSystem: ref<CustomHackingSystem> =
    GameInstance.GetScriptableSystemsContainer(gi)
      .Get(n"HackingExtensions.CustomHackingSystem") as CustomHackingSystem;
  if !IsDefined(hackSystem) { return false; }

  let successCB: ref<BNFirewallSucceededEvent> = new BNFirewallSucceededEvent();
  successCB.m_npcPuppet    = this.m_npcPuppet;
  successCB.m_playerPuppet = this.m_playerPuppet as PlayerPuppet;
  successCB.m_listener     = this;
  if IsDefined(this.m_action) {
    successCB.m_actionID = this.m_action.GetObjectActionID();
  }

  let failCB: ref<BNFirewallFailedEvent> = new BNFirewallFailedEvent();
  failCB.m_listener = this;

  GameInstance.GetTimeSystem(gi).SetTimeDilation(n"BNFirewall", 0.0);
  let launched: Bool = hackSystem.StartNewHackInstance(
    "BN Firewall",
    t"CustomHackingSystemMinigame.BNFirewall",
    null,
    [],
    successCB,
    failCB
  );

  if launched {
    this.m_bnFirewallEngaged = true;

    GameInstance.GetStatPoolsSystem(gi).RequestChangingStatPoolValue(
      Cast<StatsObjectID>(this.m_playerPuppet.GetEntityID()),
      gamedataStatPoolType.Memory,
      -4.0,
      this.m_playerPuppet,
      false,
      false
    );
    BNInfo("Firewall", "Firewall engaged — charges=" + ToString(charges) + ", -4 RAM spent");
  } else {

    GameInstance.GetTimeSystem(gi).UnsetTimeDilation(n"BNFirewall");
    BNWarn("Firewall", "Firewall minigame failed to launch — another minigame already active");
  }

  return launched;
}

@wrapMethod(UploadFromNPCToPlayerListener)
public func OnStatPoolValueChanged(oldValue: Float, newValue: Float, percToPoints: Float) -> Void {
  wrappedMethod(oldValue, newValue, percToPoints);
  if !this.m_HUDData.active && this.m_bnFirewallEngaged {
    GameInstance.GetTimeSystem(this.m_gameInstance).UnsetTimeDilation(n"BNFirewall");
    this.m_bnFirewallEngaged = false;
    BNInfo("Firewall", "Upload ended externally — time dilation cleared");
  }
}

@wrapMethod(UploadFromNPCToPlayerListener)
protected cb func OnStatPoolMaxValueReached(value: Float) -> Bool {
  if this.m_bnFirewallEngaged {
    GameInstance.GetTimeSystem(this.m_gameInstance).UnsetTimeDilation(n"BNFirewall");
    this.m_bnFirewallEngaged = false;
  }
  return wrappedMethod(value);
}
