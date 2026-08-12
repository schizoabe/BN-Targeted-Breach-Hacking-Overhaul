
module BetterNetrunning.CounterBreach

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Marking.*
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
    if IsDefined(this.m_npcPuppet) {
      BNFirewallUtils.ReflectHack(gi, this.m_npcPuppet, this.m_actionID);
    }

    let cbs: ref<CounterBreachSystem> =
      GameInstance.GetScriptableSystemsContainer(gi)
        .Get(BNConstants.CLASS_COUNTER_BREACH_SYSTEM()) as CounterBreachSystem;
    if IsDefined(cbs) {
      cbs.ShowWarning("FIREWALL: HACK REFLECTED!");
    }
    BNInfo("Firewall", "Firewall succeeded — hack reflected to attacker");
  }
}

public class BNFirewallFailedEvent extends OnCustomHackingFailed {
  public let m_listener: wref<UploadFromNPCToPlayerListener>;

  public func Execute() -> Void {
    GameInstance.GetTimeSystem(this.gameInstance).UnsetTimeDilation(n"BNFirewall");
    if IsDefined(this.m_listener) {
      this.m_listener.m_bnFirewallEngaged = false;
      this.m_listener.ForceClose();
    }
    BNInfo("Firewall", "Firewall minigame failed — hack lands");
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

  let mss: ref<MarkingStateSystem> =
    GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if !IsDefined(mss) || !mss.IsDefendMode() { return result; }
  if !mss.IsFirewallArmed() {
    BNInfo("Firewall", "Firewall disarmed (weapons cold) — hack proceeds");
    return result;
  }

  let cbs: ref<CounterBreachSystem> =
    GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_COUNTER_BREACH_SYSTEM()) as CounterBreachSystem;
  if !IsDefined(cbs) { return result; }

  let charges: Int32 = cbs.GetFirewallCharges(gi);
  if charges <= 0 {
    cbs.ShowWarning("FIREWALL DEPLETED — HACK INCOMING");
    BNInfo("Firewall", "Firewall depleted — hack proceeds");
    return result;
  }

  let hackSystem: ref<CustomHackingSystem> =
    GameInstance.GetScriptableSystemsContainer(gi)
      .Get(n"HackingExtensions.CustomHackingSystem") as CustomHackingSystem;
  if !IsDefined(hackSystem) { return result; }

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
    cbs.ShowWarning("FIREWALL DEPLOYED — CANCELLING QUICKHACK");
    BNInfo("Firewall", "Firewall engaged — charges=" + ToString(charges));
  } else {
    GameInstance.GetTimeSystem(gi).UnsetTimeDilation(n"BNFirewall");
    BNWarn("Firewall", "Firewall minigame failed to launch — another minigame already active");
  }

  return result;
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
