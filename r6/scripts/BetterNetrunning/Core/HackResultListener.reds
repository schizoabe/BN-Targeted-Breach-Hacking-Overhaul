
module BetterNetrunning.Core

import BetterNetrunning.Logging.*

public class BNHackResultCallback extends IScriptable {
  public let gameInstance: GameInstance;
  public func Execute() -> Void {}
}

public class BNHackResultListener extends IScriptable {
  public let successCB: ref<BNHackResultCallback>;
  public let failCB:    ref<BNHackResultCallback>;

  private let m_gameInstance: GameInstance;
  private let m_bb:           ref<IBlackboard>;
  private let m_handle:       ref<CallbackHandle>;

  public func Arm(gi: GameInstance) -> Void {
    this.m_gameInstance = gi;
    this.m_bb = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().HackingMinigame);
    let preArmState: Int32 = this.m_bb.GetInt(GetAllBlackboardDefs().HackingMinigame.State);
    this.m_handle = this.m_bb.RegisterListenerInt(GetAllBlackboardDefs().HackingMinigame.State, this, n"OnBNHackResultStateChanged");
    BNDebug("HackResultListener", "Arm: registered, blackboard state at arm-time=" + ToString(preArmState));
  }

  protected cb func OnBNHackResultStateChanged(value: Int32) -> Void {
    BNDebug("HackResultListener", "OnBNHackResultStateChanged: raw value=" + ToString(value));
    let state: HackingMinigameState = IntEnum(value);
    if Equals(state, HackingMinigameState.Unknown) || Equals(state, HackingMinigameState.InProgress) {
      BNDebug("HackResultListener", "OnBNHackResultStateChanged: ignoring Unknown/InProgress");
      return;
    }

    if IsDefined(this.m_handle) {
      this.m_bb.UnregisterListenerInt(GetAllBlackboardDefs().HackingMinigame.State, this.m_handle);
      this.m_handle = null;
    }

    if Equals(state, HackingMinigameState.Succeeded) {
      BNDebug("HackResultListener", "OnBNHackResultStateChanged: Succeeded, successCB defined=" + ToString(IsDefined(this.successCB)));
      if IsDefined(this.successCB) {
        this.successCB.gameInstance = this.m_gameInstance;
        this.successCB.Execute();
      }
    } else {

      BNDebug("HackResultListener", "OnBNHackResultStateChanged: Failed/Abandoned (state=" + ToString(value) + "), failCB defined=" + ToString(IsDefined(this.failCB)));
      if IsDefined(this.failCB) {
        this.failCB.gameInstance = this.m_gameInstance;
        this.failCB.Execute();
      }
    }
  }
}
