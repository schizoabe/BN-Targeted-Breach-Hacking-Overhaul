

module BetterNetrunning.CounterBreach

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Network.*
import BetterNetrunning.Marking.*
import HackingExtensions.*

@if(ModuleExists("DarkFuture.Needs"))
import DarkFuture.Needs.{DFNerveSystem, DFChangeNeedValueProps}

public class CounterBreachSucceededEvent extends OnCustomHackingSucceeded {

  public func Execute() -> Void {
    let gi: GameInstance = this.gameInstance;
    BNInfo("CounterBreach", "Counter-breach defeated — reducing Heat");

    let markingSystem: ref<MarkingStateSystem> =
      GameInstance.GetScriptableSystemsContainer(gi)
        .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if IsDefined(markingSystem) {
      markingSystem.AddSessionHeat(-0.20);
    }

    let cbs: ref<CounterBreachSystem> =
      GameInstance.GetScriptableSystemsContainer(gi)
        .Get(BNConstants.CLASS_COUNTER_BREACH_SYSTEM()) as CounterBreachSystem;
    if IsDefined(cbs) {
      cbs.ShowWarning("COUNTER-BREACH DEFEATED!");
      cbs.OnOutcomeFinished();
    }
  }
}

public class CounterBreachFailedEvent extends OnCustomHackingFailed {

  public func Execute() -> Void {
    let gi: GameInstance = this.gameInstance;
    let cbs: ref<CounterBreachSystem> =
      GameInstance.GetScriptableSystemsContainer(gi)
        .Get(BNConstants.CLASS_COUNTER_BREACH_SYSTEM()) as CounterBreachSystem;
    if IsDefined(cbs) {
      cbs.ApplyFailConsequence();
      cbs.OnOutcomeFinished();
    }
  }
}

public class CounterBreachSystem extends ScriptableSystem {

  private let m_isActive: Bool;

  private let m_lastBreachWasStandalone: Bool;

  private let m_abandonListener: ref<CallbackHandle>;

  private func OnAttach() -> Void {
    this.m_isActive = false;
    this.m_lastBreachWasStandalone = false;
  }

  private func OnDetach() -> Void {
    this.CleanupAbandonListener();
  }

  public func IsActive() -> Bool {
    return this.m_isActive;
  }

  public func SetLastBreachWasStandalone(value: Bool) -> Void {
    this.m_lastBreachWasStandalone = value;
    BNDebug("CounterBreach", "LastBreachWasStandalone = " + ToString(value));
  }

  public func IsPersonalLinkDisconnecting() -> Bool {
    let gi: GameInstance = this.GetGameInstance();
    let bbMinigame: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi)
      .Get(GetAllBlackboardDefs().HackingMinigame);
    if !IsDefined(bbMinigame) { return false; }
    let breachEntity: wref<Entity> = FromVariant<wref<Entity>>(
      bbMinigame.GetVariant(GetAllBlackboardDefs().HackingMinigame.Entity));
    let device: ref<Device> = breachEntity as Device;
    if !IsDefined(device) { return false; }
    let devicePS: ref<ScriptableDeviceComponentPS> = device.GetDevicePS();
    if !IsDefined(devicePS) { return false; }
    return devicePS.IsPersonalLinkDisconnecting();
  }

  public func IsMinigameActive() -> Bool {
    let gi: GameInstance = this.GetGameInstance();
    let player: ref<PlayerPuppet> = GetPlayer(gi);
    if !IsDefined(player) { return false; }
    let psmBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi)
      .GetLocalInstanced(player.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
    if !IsDefined(psmBB) { return false; }
    return psmBB.GetBool(GetAllBlackboardDefs().PlayerStateMachine.IsInMinigame);
  }

  public func OnOutcomeFinished() -> Void {
    this.m_isActive = false;
    this.CleanupAbandonListener();
  }

  public func ForceJackOut() -> Void {
    let gi: GameInstance = this.GetGameInstance();

    if this.m_isActive {
      BNWarn("CounterBreach", "Counter-breach stuck — force-cleaning state");
      this.OnOutcomeFinished();
      return;
    }

    let bbMinigame: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi)
      .Get(GetAllBlackboardDefs().HackingMinigame);
    if !IsDefined(bbMinigame) { return; }

    let breachEntity: wref<Entity> = FromVariant<wref<Entity>>(
      bbMinigame.GetVariant(GetAllBlackboardDefs().HackingMinigame.Entity));
    let breachDevice: ref<Device> = breachEntity as Device;
    if !IsDefined(breachDevice) {
      BNWarn("CounterBreach", "ForceJackOut: no breach device found");
      return;
    }

    let devicePS: ref<ScriptableDeviceComponentPS> = breachDevice.GetDevicePS();
    if !IsDefined(devicePS) { return; }

    if !devicePS.IsPersonalLinkConnected()
    && !devicePS.IsPersonalLinkConnecting()
    && !devicePS.IsPersonalLinkDisconnecting() {
      return;
    }

    let player: ref<PlayerPuppet> = GetPlayer(gi);
    devicePS.DisconnectPersonalLink(player, n"", true);
    BNWarn("CounterBreach", "ForceJackOut: DisconnectPersonalLink called — V was stuck");
  }

  public func ApplyFailConsequence() -> Void {
    BNInfo("CounterBreach", "Counter-breach failed — ICE retaliation incoming");
    this.ApplyRandomHack();
    this.ReduceNerve(6.0);
    this.AlertNearbyNPCs(40.0);

    let gi: GameInstance = this.GetGameInstance();
    let wantedBB: ref<IBlackboard> =
      GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().UI_WantedBar);
    let currentStars: Int32 = IsDefined(wantedBB)
      ? wantedBB.GetInt(GetAllBlackboardDefs().UI_WantedBar.CurrentWantedLevel)
      : 0;
    let newStars: Int32 = currentStars + 1;
    if newStars > 5 { newStars = 5; }
    BNInfo("CounterBreach", "NCPD escalated: " + ToString(currentStars) + " -> " + ToString(newStars) + " stars");
    this.TriggerNCPD(newStars);
  }

  @if(ModuleExists("DarkFuture.Needs"))
  private func ReduceNerve(amount: Float) -> Void {
    let sys = DFNerveSystem.Get();
    if IsDefined(sys) { sys.ChangeNeedValue(-amount); };
  }

  @if(!ModuleExists("DarkFuture.Needs"))
  private func ReduceNerve(amount: Float) -> Void {}

  public func ShowWarning(text: String) -> Void {
    let msg: SimpleScreenMessage;
    msg.isShown = true;
    msg.duration = 5.0;
    msg.message = text;
    let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGameInstance())
      .Get(GetAllBlackboardDefs().UI_Notifications);
    if IsDefined(bb) {
      bb.SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(msg), true);
    }
  }

  public func TriggerNCPD(stars: Int32) -> Void {
    let gi: GameInstance = this.GetGameInstance();
    let ps: ref<PreventionSystem> =
      GameInstance.GetScriptableSystemsContainer(gi).Get(n"PreventionSystem") as PreventionSystem;
    if !IsDefined(ps) {
      BNWarn("CounterBreach", "PreventionSystem not found — cannot trigger NCPD");
      return;
    }
    let req: ref<SetWantedLevel> = new SetWantedLevel();
    req.m_forcePlayerPositionAsLastCrimePoint = true;
    switch stars {
      case 1: req.m_wantedLevel = EPreventionHeatStage.Heat_1; break;
      case 2: req.m_wantedLevel = EPreventionHeatStage.Heat_2; break;
      case 3: req.m_wantedLevel = EPreventionHeatStage.Heat_3; break;
      case 4: req.m_wantedLevel = EPreventionHeatStage.Heat_4; break;
      case 5: req.m_wantedLevel = EPreventionHeatStage.Heat_5; break;
      default: req.m_wantedLevel = EPreventionHeatStage.Heat_3;
    }
    ps.QueueRequest(req);
  }

  private func ApplyRandomHack() -> Void {
    let gi: GameInstance = this.GetGameInstance();
    let player: ref<PlayerPuppet> = GetPlayer(gi);
    if !IsDefined(player) { return; }

    let roll: Int32 = RandRange(0, 6);
    let effectID: TweakDBID;
    let hackLabel: String;
    let dealsDamage: Bool = false;

    switch roll {
      case 0:
        effectID = t"BaseStatusEffect.Burning";
        hackLabel = "OVERHEAT";
        dealsDamage = true;
        break;
      case 1:
        effectID = t"BaseStatusEffect.Poisoned";
        hackLabel = "BIOHAZARD PAYLOAD";
        dealsDamage = true;
        break;
      case 2:
        effectID = t"BaseStatusEffect.Electrocuted";
        hackLabel = "SHORT-CIRCUIT";
        dealsDamage = true;
        break;
      case 3:
        effectID = t"BaseStatusEffect.Blind";
        hackLabel = "OPTICS BREACH";
        break;
      case 4:
        effectID = t"BaseStatusEffect.WeaponMalfunction";
        hackLabel = "WEAPON MALFUNCTION";
        break;
      default:
        effectID = t"BaseStatusEffect.LocomotionMalfunction";
        hackLabel = "MOVEMENT LOCKDOWN";
        break;
    }

    StatusEffectHelper.ApplyStatusEffect(player, effectID, player.GetEntityID());
    BNInfo("CounterBreach", "ICE hack deployed: " + hackLabel + " (roll=" + ToString(roll) + ")");

    if dealsDamage {
      let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gi);
      let playerID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
      let currentHP: Float = pools.GetStatPoolValue(playerID, gamedataStatPoolType.Health, false);
      let damage: Float = currentHP * 0.25 * 2.5;
      let newHP: Float = currentHP - damage;
      if newHP < 1.0 { newHP = 1.0; }
      pools.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Health, newHP, player, false);
    }

    this.ShowWarning("HOSTILE ICE SUCCESSFUL — " + hackLabel + " DEPLOYED");
  }

  private func AlertNearbyNPCs(radius: Float) -> Void {
    let gi: GameInstance = this.GetGameInstance();
    let player: ref<PlayerPuppet> = GetPlayer(gi);
    if !IsDefined(player) { return; }

    let searchQuery: TargetSearchQuery = TSQ_ALL();
    searchQuery.testedSet             = TargetingSet.Complete;
    searchQuery.maxDistance           = radius;
    searchQuery.filterObjectByDistance = true;
    searchQuery.includeSecondaryTargets = false;
    searchQuery.ignoreInstigator      = true;

    let targetParts: array<TS_TargetPartInfo>;
    GameInstance.GetTargetingSystem(gi).GetTargetParts(player, searchQuery, targetParts);

    let playerID: EntityID = player.GetEntityID();
    let alertedCount: Int32 = 0;

    let i: Int32 = 0;
    while i < ArraySize(targetParts) {
      let npc: ref<NPCPuppet> = TS_TargetPartInfo.GetComponent(targetParts[i]).GetEntity() as NPCPuppet;
      if IsDefined(npc)
          && ScriptedPuppet.IsAlive(npc)
          && !ScriptedPuppet.IsDefeated(npc)
          && !Equals(npc.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Combat) {
        NPCPuppet.ChangeHighLevelState(npc, gamedataNPCHighLevelState.Combat);
        NPCPuppet.RevealPlayerPositionIfNeeded(npc, playerID, false);
        alertedCount += 1;
      }
      i += 1;
    }

    BNInfo("CounterBreach", "ICE trace — " + ToString(alertedCount) + " NPCs alerted within " + ToString(RoundF(radius)) + "m");
  }

  private func CleanupAbandonListener() -> Void {
    if IsDefined(this.m_abandonListener) {
      let bbMinigame: ref<IBlackboard> =
        GameInstance.GetBlackboardSystem(this.GetGameInstance())
          .Get(GetAllBlackboardDefs().HackingMinigame);
      if IsDefined(bbMinigame) {
        bbMinigame.UnregisterListenerInt(
          GetAllBlackboardDefs().HackingMinigame.State, this.m_abandonListener);
      }
      this.m_abandonListener = null;
    }
  }

  protected cb func OnCounterBreachStateChanged(state: Int32) -> Void {
    if state == 4 {
      BNInfo("CounterBreach", "Counter-breach abandoned — applying fail consequence");
      this.ApplyFailConsequence();
      this.OnOutcomeFinished();
    } else if state == 2 || state == 3 {
      this.CleanupAbandonListener();
    }
  }

  
  public func Trigger() -> Void {
    if this.m_isActive {
      BNDebug("CounterBreach", "Already active — ignoring trigger");
      return;
    }

    let gi: GameInstance = this.GetGameInstance();
    let hackSystem: ref<CustomHackingSystem> =
      GameInstance.GetScriptableSystemsContainer(gi)
        .Get(n"HackingExtensions.CustomHackingSystem") as CustomHackingSystem;

    if !IsDefined(hackSystem) {
      BNWarn("CounterBreach", "CustomHackingSystem not found — is the mod installed?");
      return;
    }

    this.ForceJackOut();

    let launched: Bool = hackSystem.StartNewHackInstance(
      "ICE Counter-Breach",
      t"CustomHackingSystemMinigame.BNCounterBreach",
      null,
      [],
      new CounterBreachSucceededEvent(),
      new CounterBreachFailedEvent()
    );

    if launched {
      this.m_isActive = true;
      BNInfo("CounterBreach", "Counter-breach triggered — defeat the ICE retaliation or face the consequences");

      let bbMinigame: ref<IBlackboard> =
        GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().HackingMinigame);
      if IsDefined(bbMinigame) {
        this.m_abandonListener = bbMinigame.RegisterListenerInt(
          GetAllBlackboardDefs().HackingMinigame.State, this, n"OnCounterBreachStateChanged");
      }
    } else {
      BNWarn("CounterBreach", "Counter-breach launch failed — player may already be hacking");
    }
  }
}

