

module BetterNetrunning.Integration

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Marking.*

@wrapMethod(ScriptableDeviceAction)
public func CompleteAction(gameInstance: GameInstance) -> Void {
  wrappedMethod(gameInstance);

  if !this.IsQuickHack() { return; }

  let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
  if !IsDefined(player) { return; }
  let executor: ref<GameObject> = this.GetExecutor();
  if !IsDefined(executor) { return; }
  if !Equals(executor.GetEntityID(), player.GetEntityID()) { return; }

  let ms: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
    .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if !IsDefined(ms) { return; }

  if ms.IsApBreachFinalizing() { return; }

  if ms.GetHidePresenceTimer() > 0.0 {
    BNDebug("QuickhackHeat", "Quickhack heat suppressed — Hide Presence active");
    return;
  }

  let heat: Float = 0.05;

  if ms.GetSignalNoiseTimer() > 0.0 {
    heat *= 0.5;
    BNDebug("QuickhackHeat", "Signal Noise active — quickhack heat halved");
  }

  ms.AddSessionHeat(heat);
  BNInfo("QuickhackHeat", "Quickhack used — heat +" + ToString(heat));
}

