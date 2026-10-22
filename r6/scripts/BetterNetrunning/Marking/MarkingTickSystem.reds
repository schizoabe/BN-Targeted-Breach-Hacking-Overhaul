
module BetterNetrunning.Marking

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.CounterBreach.*
import BetterNetrunning.Perks.*
import BetterNetrunning.UI.*
import RedscriptConfigFramework.*

public class MarkingTickCallback extends DelayCallback {
  public let sys: wref<MarkingTickSystem>;
  public func Call() -> Void {
    if IsDefined(this.sys) { this.sys.OnTick(); }
  }
}

public class MarkingTickSystem extends ScriptableSystem {

  private let m_counterBreachTimer: Float;
  private let m_counterBreachPending: Float;
  private let m_counterBreachEngaged: Bool;
  private let m_counterBreachWasInMinigame: Bool;
  private let m_counterBreachWasActive: Bool;

  private let m_panelRefreshAccum: Float;
  private let m_hudPanelsVisible: Bool;

  private func OnAttach() -> Void {
    this.ArmTick();
    BNInfo("MarkingTick", "Native tick system attached (0.1s interval)");
  }

  private func ArmTick() -> Void {
    let cb: ref<MarkingTickCallback> = new MarkingTickCallback();
    cb.sys = this;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, 0.1, false);
  }

  public func OnTick() -> Void {
    this.Update(0.1);
    this.RefreshVehicleBeams();

    this.m_panelRefreshAccum += 0.1;
    if this.m_panelRefreshAccum >= 0.25 {
      this.m_panelRefreshAccum -= 0.25;
      this.RefreshPanels();
    }

    this.ArmTick();
  }

  private func RefreshVehicleBeams() -> Void {
    let gi: GameInstance = this.GetGameInstance();
    let ms: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if IsDefined(ms) && ms.HasMarkedVehicleInRoot() {
      ms.RefreshMarkBeams();
    }
  }

  private func IsPlayerInControl(gi: GameInstance, player: wref<PlayerPuppet>) -> Bool {
    if !IsDefined(player) { return false; }

    let uiBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().UI_System);
    if IsDefined(uiBB) && uiBB.GetBool(GetAllBlackboardDefs().UI_System.IsInMenu) {
      return false;
    }

    let psmBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi)
      .GetLocalInstanced(player.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
    if IsDefined(psmBB) && psmBB.GetInt(GetAllBlackboardDefs().PlayerStateMachine.SceneTier) >= 3 {
      return false;
    }

    let rcfHub: ref<DVRCF_Hub> = DVRCF_Hub.Get(gi);
    if IsDefined(rcfHub) && rcfHub.IsOpen() {
      return false;
    }

    return true;
  }

  private func Update(deltaTime: Float) -> Void {
    let gi: GameInstance = this.GetGameInstance();
    let player: wref<PlayerPuppet> = GetPlayer(gi);

    let ms: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if !IsDefined(ms) { return; }

    let cbs: ref<CounterBreachSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_COUNTER_BREACH_SYSTEM()) as CounterBreachSystem;

    let shouldTick: Bool = this.IsPlayerInControl(gi, player);
    let inMinigame: Bool = IsDefined(cbs) ? cbs.IsMinigameActive() : false;

    let hideTimer: Float        = ms.GetHidePresenceTimer();
    let disarmTimer: Float      = ms.GetDisarmICETimer();
    let signalNoiseTimer: Float = ms.GetSignalNoiseTimer();
    if shouldTick {
      if hideTimer > 0.0        { ms.SetHidePresenceTimer(hideTimer - deltaTime); }
      if disarmTimer > 0.0      { ms.SetDisarmICETimer(disarmTimer - deltaTime); }
      if signalNoiseTimer > 0.0 { ms.SetSignalNoiseTimer(signalNoiseTimer - deltaTime); }
    }

    if shouldTick && hideTimer <= 0.0 {
      ms.AddSessionHeat(-this.GetHeatDecayPerSec(gi) * deltaTime);
    }

    let maxHeat: Float = ms.GetSessionHeat();

    if ms.HasAnyMarked() {
      ms.PruneExpiredMarksWithHeat(maxHeat);
    }

    let cbActive: Bool = IsDefined(cbs) ? cbs.IsActive() : false;

    if this.m_counterBreachWasActive && !cbActive {
      this.m_counterBreachTimer = this.GetCounterBreachCooldown(gi);
      BNInfo("CounterBreach", "Counter-breach ended — cooldown " + ToString(this.m_counterBreachTimer) + "s before next");
    }
    this.m_counterBreachWasActive = cbActive;

    if this.m_counterBreachWasInMinigame && !inMinigame && this.m_counterBreachPending > 0.0 {
      this.m_counterBreachPending = 5.0;
      BNInfo("CounterBreach", "ICE still retaliating after breach exit — restarting countdown");
      if IsDefined(cbs) { cbs.ShowWarning(GetLocalizedTextByKey(n"Better-Netrunning-Alert-ICERetaliating")); }
    }
    this.m_counterBreachWasInMinigame = inMinigame;

    if shouldTick {
      this.m_counterBreachTimer -= deltaTime;
    }

    if !cbActive {
      let armThreshold: Float = this.m_counterBreachEngaged ? 0.5 : 0.95;
      if maxHeat >= armThreshold && this.m_counterBreachTimer <= 0.0 {
        if this.m_counterBreachPending <= 0.0 {
          this.m_counterBreachPending = 5.0;
          BNInfo("CounterBreach", "BLACK ICE IMMINENT: heat=" + ToString(maxHeat) + " countdown=" + ToString(this.m_counterBreachPending));
          if IsDefined(cbs) {
            cbs.ShowWarning(GetLocalizedTextByKey(n"Better-Netrunning-Alert-ICERetaliating"));
          } else {
            BNWarn("CounterBreach", "CounterBreachSystem not found, minigame cannot fire");
          }
        }
      } else if maxHeat < 0.5 {
        if this.m_counterBreachPending > 0.0 {
          BNInfo("CounterBreach", "Counter-breach disarmed: heat=" + ToString(maxHeat));
          this.m_counterBreachPending = 0.0;
        }
        this.m_counterBreachEngaged = false;
      }
    }

    if shouldTick && this.m_counterBreachPending > 0.0 {
      this.m_counterBreachPending -= deltaTime;
      if this.m_counterBreachPending <= 0.0 {
        this.m_counterBreachPending = 0.0;
        if IsDefined(cbs) {
          if !cbActive {
            BNInfo("CounterBreach", "Counter-breach FIRING: heat=" + ToString(maxHeat));
            this.m_counterBreachEngaged = true;
            cbs.Trigger();
          } else {
            BNInfo("CounterBreach", "Counter-breach suppressed: board already active");
          }
        } else {
          BNWarn("CounterBreach", "Counter-breach FAILED TO FIRE: CounterBreachSystem is null");
        }
      }
    }
  }

  private func GetHeatDecayPerSec(gi: GameInstance) -> Float {
    let perkSys: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gi);
    if !IsDefined(perkSys) { return 0.001; }
    let rank: Int32 = perkSys.GetPerkLevel(BNPerk.ColdTrace);
    if rank > 0 { return 0.001 * (1.0 + Cast<Float>(rank) * 0.1); }
    return 0.001;
  }

  private func GetCounterBreachCooldown(gi: GameInstance) -> Float {
    let perkSys: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gi);
    if !IsDefined(perkSys) { return 5.0; }
    let rank: Int32 = perkSys.GetPerkLevel(BNPerk.TraceScrambler);
    if rank > 0 { return 5.0 + Cast<Float>(rank) * 10.0; }
    return 5.0;
  }

  private func RefreshPanels() -> Void {
    let gi: GameInstance = this.GetGameInstance();
    let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gi);

    let logSys: ref<ICEScoutLogSystem> = container.Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
    if IsDefined(logSys) {
      this.m_hudPanelsVisible = logSys.IsVisible();
    }

    if this.m_hudPanelsVisible {
      let testSys: ref<BNTestPanelSystem> = container.Get(n"BetterNetrunning.UI.BNTestPanelSystem") as BNTestPanelSystem;
      if IsDefined(testSys) { testSys.Refresh(this.m_counterBreachPending); }
      if IsDefined(logSys)  { logSys.Refresh(); }
    }
  }
}
