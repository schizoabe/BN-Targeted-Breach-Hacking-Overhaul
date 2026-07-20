


















































module BetterNetrunning.Network

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Marking.*
import BetterNetrunning.Perks.*

@if(ModuleExists("DarkFuture.Needs"))
import DarkFuture.Needs.{DFNerveSystem, DFChangeNeedValueProps}





public abstract class HeatThresholds {
  public static func Low() -> Float  { return 0.3; }
  public static func High() -> Float { return 0.7; }
  public static func Max() -> Float  { return 1.0; }
}





public struct NetworkState {
  public let hitsRequired: Int32;  // base ICE pool (2-6); 0 = uninitialized (AP)
  public let hitsApplied:  Int32;  // ICE damage dealt so far
  public let globalBonus:  Int32;  // heat bonus from MarkingStateSystem (added to base for effective)
  public let isDefeated:   Bool;   // latched true once hitsApplied >= effective; never resets
}





public abstract class NetworkStateUtils {





  
  public static func GetNetworkState(
    devicePS:     ref<ScriptableDeviceComponentPS>,
    gameInstance: GameInstance
  ) -> NetworkState {
    let state: NetworkState;
    if !IsDefined(devicePS) { return state; }
    let sharedPS: ref<SharedGameplayPS> = devicePS;
    if !IsDefined(sharedPS) { return state; }
    state.hitsRequired = sharedPS.m_bnIceHitsRequired;
    state.hitsApplied  = sharedPS.m_bnIceHitsApplied;
    state.isDefeated   = sharedPS.m_bnIceDefeated;
    let ms: ref<MarkingStateSystem> = NetworkStateUtils.GetMarkingSystem(gameInstance);
    state.globalBonus  = IsDefined(ms) ? ms.GetHeatICEBonus() : 0;
    return state;
  }





  
  public static func ResolveWriteTarget(
    devicePS: ref<ScriptableDeviceComponentPS>,
    gi:       GameInstance
  ) -> ref<ScriptableDeviceComponentPS> {
    let minigameBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi)
      .Get(GetAllBlackboardDefs().HackingMinigame);
    let breachEntity: wref<Entity> = FromVariant<wref<Entity>>(
      minigameBB.GetVariant(GetAllBlackboardDefs().HackingMinigame.Entity));
    let breachDevice: ref<Device> = breachEntity as Device;
    if IsDefined(breachDevice) {
      let breachPS: ref<ScriptableDeviceComponentPS> = breachDevice.GetDevicePS();
      if IsDefined(breachPS) {
        return breachPS;
      }
    }
    return devicePS;
  }





  
  public static func OnEntityMarked(
    devicePS: ref<ScriptableDeviceComponentPS>,
    gameInstance: GameInstance
  ) -> Void {

  }

  
  public static func OnBreachEntered(
    devicePS: ref<ScriptableDeviceComponentPS>,
    gameInstance: GameInstance
  ) -> Void {
    let sharedPS: ref<SharedGameplayPS> = devicePS;
    if IsDefined(sharedPS) && sharedPS.m_bnIceHitsRequired == 0 {
      sharedPS.m_bnIceHitsRequired = NetworkStateUtils.GetHeatScaledICEHits(gameInstance);
      BNInfo("NetworkState",
        "ICE health initialized: " + ToString(sharedPS.m_bnIceHitsRequired) + " hits required");
    }

    if IsDefined(sharedPS) {
      let ms: ref<MarkingStateSystem> = NetworkStateUtils.GetMarkingSystem(gameInstance);
      if IsDefined(ms) {
        ms.RecordBreachICEState(sharedPS.m_bnIceHitsRequired, sharedPS.m_bnIceHitsApplied);
        let owner: wref<GameObject> = sharedPS.GetOwnerEntityWeak() as GameObject;
        let deviceName: String = s"";
        if IsDefined(owner) {
          let key: String = owner.GetDisplayName();
          deviceName = NotEquals(key, s"") ? GetLocalizedText(key) : s"";
        }
        ms.RecordBreachDeviceName(deviceName);
      }
    }
  }

  
  @if(ModuleExists("DarkFuture.Needs"))
  public static func OnBreachFailed(
    devicePS: ref<ScriptableDeviceComponentPS>,
    gameInstance: GameInstance
  ) -> Void {
    let ms: ref<MarkingStateSystem> = NetworkStateUtils.GetMarkingSystem(gameInstance);
    if IsDefined(ms) {
      ms.AddSessionHeat(0.50);
      BNInfo("NetworkState", "Breach failed — session heat +0.50");
    }
    let dfSys = DFNerveSystem.Get();
    if IsDefined(dfSys) { dfSys.ChangeNeedValue(-5.0); };
  }

  @if(!ModuleExists("DarkFuture.Needs"))
  public static func OnBreachFailed(
    devicePS: ref<ScriptableDeviceComponentPS>,
    gameInstance: GameInstance
  ) -> Void {
    let ms: ref<MarkingStateSystem> = NetworkStateUtils.GetMarkingSystem(gameInstance);
    if IsDefined(ms) {
      ms.AddSessionHeat(0.50);
      BNInfo("NetworkState", "Breach failed — session heat +0.50");
    }
  }

  
  public static func ApplyIcepickEffect(
    devicePS:     ref<ScriptableDeviceComponentPS>,
    gameInstance: GameInstance,
    hits:         Int32
  ) -> Void {
    let sharedPS: ref<SharedGameplayPS> = devicePS;
    if !IsDefined(sharedPS) { return; }

    let ms: ref<MarkingStateSystem> = NetworkStateUtils.GetMarkingSystem(gameInstance);
    let globalBonus: Int32 = IsDefined(ms) ? ms.GetHeatICEBonus() : 0;

    if hits > 0 {

      if sharedPS.m_bnIceHitsRequired <= 0 {
        sharedPS.m_bnIceHitsRequired = RandRange(2, 7);
      }
      let effective: Int32 = sharedPS.m_bnIceHitsRequired + globalBonus;
      sharedPS.m_bnIceHitsApplied += hits;
      if sharedPS.m_bnIceHitsApplied > effective {
        sharedPS.m_bnIceHitsApplied = effective;
      }
      if sharedPS.m_bnIceHitsApplied >= effective {
        sharedPS.m_bnIceDefeated = true;
      }
      BNInfo("NetworkState",
        "ICE hits: " + ToString(sharedPS.m_bnIceHitsApplied)
        + "/" + ToString(effective)
        + " (base=" + ToString(sharedPS.m_bnIceHitsRequired)
        + " +bonus=" + ToString(globalBonus) + ")"
        + (sharedPS.m_bnIceDefeated ? " [DEFEATED]" : ""));
    }

    if IsDefined(ms) {
      let effective: Int32 = sharedPS.m_bnIceHitsRequired + globalBonus;
      ms.RecordBreachICEState(effective, sharedPS.m_bnIceHitsApplied);
    }
  }

  
  public static func OnDaemonsCompleted(
    activePrograms: array<TweakDBID>,
    devicePS:       ref<ScriptableDeviceComponentPS>,
    gameInstance:   GameInstance
  ) -> Void {
    let writeTarget: ref<ScriptableDeviceComponentPS> =
      NetworkStateUtils.ResolveWriteTarget(devicePS, gameInstance);

    let ms: ref<MarkingStateSystem> = NetworkStateUtils.GetMarkingSystem(gameInstance);


    let perkSys: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gameInstance);
    let iceAnalystBonus: Int32 = IsDefined(perkSys) ? perkSys.GetPerkLevel(BNPerk.ICEAnalyst) : 0;



    let hideWasActive: Bool = IsDefined(ms) && ms.GetHidePresenceTimer() > 0.0;

    let i: Int32 = 0;
    while i < ArraySize(activePrograms) {
      let pid: TweakDBID = activePrograms[i];

      if Equals(pid, BNConstants.PROGRAM_BN_ICEPICK_V1()) {
        let v1Hits: Int32 = 2 + iceAnalystBonus + RandRange(0, 4);
        NetworkStateUtils.ApplyIcepickEffect(writeTarget, gameInstance, v1Hits);
        if IsDefined(ms) { ms.AddSessionHeat(0.4); }
        BNInfo("NetworkState", "IcepickV1 (Fracture) — " + ToString(v1Hits) + " ICE hits, session heat +0.40");

      } else if Equals(pid, BNConstants.PROGRAM_BN_ICEPICK_V2()) {
        NetworkStateUtils.ApplyIcepickEffect(writeTarget, gameInstance, 0);
        if IsDefined(ms) { ms.AddSessionHeat(-0.5); }
        BNInfo("NetworkState", "IcepickV2 (Purge) — session heat -0.50");

      } else if Equals(pid, BNConstants.PROGRAM_BN_ICEPICK_V3()) {
        let v3Hits: Int32 = 5 + iceAnalystBonus + RandRange(0, 4);
        NetworkStateUtils.ApplyIcepickEffect(writeTarget, gameInstance, v3Hits);
        BNInfo("NetworkState", "IcepickV3 (Sunder) — " + ToString(v3Hits) + " ICE hits, no heat change");

      } else if Equals(pid, t"MinigameAction.NetworkLowerICEMedium") {

        let legacyHits: Int32 = 2 + RandRange(0, 4);
        NetworkStateUtils.ApplyIcepickEffect(writeTarget, gameInstance, legacyHits);
        if IsDefined(ms) { ms.AddSessionHeat(0.2); }
        BNInfo("NetworkState", "Vanilla Icepick — legacy, treated as V1: " + ToString(legacyHits) + " ICE hits");

      } else if Equals(pid, BNConstants.PROGRAM_UNLOCK_QUICKHACKS())
             || Equals(pid, BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS())
             || Equals(pid, BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS())
             || Equals(pid, BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS()) {
        if IsDefined(ms) { ms.AddSessionHeat(0.05); }

      } else if Equals(pid, BNConstants.PROGRAM_HIDE_PRESENCE()) {

        let ghostRunRank: Int32 = IsDefined(perkSys) ? perkSys.GetPerkLevel(BNPerk.GhostRun) : 0;
        let ghostRunBonus: Float = ghostRunRank >= 2 ? 60.0 : (ghostRunRank >= 1 ? 30.0 : 0.0);
        if IsDefined(ms) {
          ms.AddSessionHeat(-1.0);
          ms.SetHidePresenceTimer(60.0 + ghostRunBonus);
        }
        BNInfo("NetworkState", "Hide Presence — heat zeroed, suppressed for " + ToString(Cast<Int32>(60.0 + ghostRunBonus)) + "s");

      } else if Equals(pid, BNConstants.PROGRAM_DISARM_ICE()) {

        let iceBreakerRank: Int32 = IsDefined(perkSys) ? perkSys.GetPerkLevel(BNPerk.IceBreaker) : 0;
        let iceBreakerBonus: Float = iceBreakerRank >= 2 ? 60.0 : (iceBreakerRank >= 1 ? 30.0 : 0.0);
        if IsDefined(ms) { ms.SetDisarmICETimer(60.0 + iceBreakerBonus); }
        BNInfo("NetworkState", "Disarm ICE — subnet gate bypassed for " + ToString(Cast<Int32>(60.0 + iceBreakerBonus)) + "s");

      } else if Equals(pid, BNConstants.PROGRAM_SIGNAL_NOISE()) {
        if IsDefined(ms) { ms.SetSignalNoiseTimer(60.0); }
        BNInfo("NetworkState", "Signal Noise — per-mark heat tick halved for 60s");
      }

      i += 1;
    }



    if hideWasActive
        && IsDefined(perkSys) && perkSys.GetPerkLevel(BNPerk.ZeroSignature) > 0
        && IsDefined(ms) {
      ms.AddSessionHeat(-1.0);
      BNInfo("NetworkState", "Zero Signature — Hide Presence was active, heat reset to 0");
    }




    let minigameBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gameInstance)
      .Get(GetAllBlackboardDefs().HackingMinigame);
    let breachEntity: wref<Entity> = FromVariant<wref<Entity>>(
      minigameBB.GetVariant(GetAllBlackboardDefs().HackingMinigame.Entity));
    let breachPuppet: ref<ScriptedPuppet> = breachEntity as ScriptedPuppet;
    if IsDefined(breachPuppet) && breachPuppet.IsIncapacitated() {
      let player: ref<PlayerPuppet> = GetPlayer(gameInstance);

      if IsDefined(player) {
        RPGManager.GiveReward(gameInstance, t"RPGActionRewards.Hacking",
          Cast<StatsObjectID>(breachPuppet.GetEntityID()));
      }
      let ntLevel: Int32 = IsDefined(perkSys) ? perkSys.GetPerkLevel(BNPerk.NeuralTap) : -1;
      BNInfo("NetworkState", s"Neural Tap debug — perkSys defined: \(IsDefined(perkSys)), NeuralTap level: \(ntLevel)");
      if !IsDefined(perkSys) || perkSys.GetPerkLevel(BNPerk.NeuralTap) < 2 {
        if IsDefined(player) {
          StatusEffectHelper.ApplyStatusEffect(breachPuppet,
            t"BaseStatusEffect.BrainMeltQuestForceKill", player.GetEntityID());
        }
        BNInfo("NetworkState", "Neural Tap r1 — Synapse Burnout applied to unconscious NPC");
      } else {
        BNInfo("NetworkState", "Neural Tap r2 — unconscious NPC spared after breach");
      }
    }
  }





  
  public static func IsSubnetAccessible(state: NetworkState) -> Bool {
    if state.hitsRequired == 0 { return true; }
    if state.isDefeated { return true; }
    return state.hitsApplied >= (state.hitsRequired + state.globalBonus);
  }

  
  public static func GetPropagationFailureChance(
    markingSystem: ref<MarkingStateSystem>,
    gameInstance:  GameInstance
  ) -> Float {
    if !IsDefined(markingSystem) { return 0.0; }

    if markingSystem.GetDisarmICETimer() > 0.0 || markingSystem.GetHidePresenceTimer() > 0.0 {
      return 0.0;
    }

    let heat: Float = markingSystem.GetSessionHeat();
    let heatBase: Float;
    if heat <= 0.0 {
      heatBase = 0.0;
    } else if heat < HeatThresholds.Low() {
      heatBase = 0.05;
    } else if heat < HeatThresholds.High() {
      heatBase = 0.20;
    } else {
      heatBase = 0.50;
    }

    let markPenalty: Float = 0.0;
    let markedCount: Int32 = markingSystem.GetTotalCount();
    if markedCount > 0 {
      let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
      if IsDefined(player) {
        let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(gameInstance);
        if IsDefined(statsSystem) {
          let maxRAM: Float = statsSystem.GetStatValue(
            Cast<StatsObjectID>(player.GetEntityID()),
            gamedataStatType.Memory
          );
          if maxRAM > 0.0 {
            markPenalty = Cast<Float>(markedCount) / maxRAM * 0.25;
          }
        }
      }
    }

    let total: Float = heatBase + markPenalty;
    if total > 1.0 { total = 1.0; }


    let perkSys: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gameInstance);
    if IsDefined(perkSys) {
      let ssRank: Int32 = perkSys.GetPerkLevel(BNPerk.SubnetSpecialist);
      if ssRank > 0 {
        total *= (1.0 - Cast<Float>(ssRank) * 0.05);
        if total < 0.0 { total = 0.0; }
      }
    }

    return total;
  }





  
  public static func FormatVulnerabilityMessage(state: NetworkState, sessionHeat: Float) -> String {
    if state.hitsRequired <= 0 {
      return "ICE UNASSESSED — BREACH TO SCAN SUBNET";
    }
    if state.hitsApplied >= state.hitsRequired {
      return "ICE FULLY COMPROMISED — SUBNET ACCESS GUARANTEED";
    }
    let pct: Int32 = state.hitsApplied * 100 / state.hitsRequired;
    if pct == 0 { return "ICE INTACT — NO BREACH DETECTED"; }
    if pct < 40 { return "WEAK ICE — " + ToString(pct) + "% DEGRADED"; }
    if pct < 70 { return "INTEGRITY FAILING — " + ToString(pct) + "% DEGRADED"; }
    return "CRITICAL — ICE NEAR COLLAPSE";
  }





  
  private static func GetIceBonusHits(sessionHeat: Float) -> Int32 {
    if sessionHeat >= 0.7 { return 5; }
    if sessionHeat >= 0.6 { return 4; }
    if sessionHeat >= 0.5 { return 3; }
    if sessionHeat >= 0.4 { return 2; }
    if sessionHeat >= 0.3 { return 1; }
    return 0;
  }





  public static func GetHeatScaledICEHits(gi: GameInstance) -> Int32 {
    return RandRange(2, 7); // 2-6
  }

  private static func GetMarkingSystem(gi: GameInstance) -> ref<MarkingStateSystem> {
    return GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  }
}

