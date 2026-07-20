



























module BetterNetrunning.Breach
import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*







































public class BreachLockSystem {




  
  public static func IsLockedByTimestamp(
    timestamp: Float,
    gameInstance: GameInstance,
    out shouldClear: Bool
  ) -> Bool {
    shouldClear = false;
    if timestamp <= 0.0 {
      return false;
    }

    let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
    let lockDurationSeconds: Float = Cast<Float>(BetterNetrunningSettings.BreachPenaltyDurationMinutes() * 60);
    if currentTime - timestamp > lockDurationSeconds {
      shouldClear = true;
      return false;
    }

    return true;
  }




  public static func IsAPBreachLockedByTimestamp(
    devicePS: ref<SharedGameplayPS>,
    gameInstance: GameInstance
  ) -> Bool {
    if !IsDefined(devicePS) {
      return false;
    }

    let shouldClear: Bool;
    let isLocked: Bool = BreachLockSystem.IsLockedByTimestamp(
      devicePS.m_betterNetrunningAPBreachFailedTimestamp,
      gameInstance,
      shouldClear
    );

    if shouldClear {
      devicePS.m_betterNetrunningAPBreachFailedTimestamp = 0.0;
    }

    return isLocked;
  }




  public static func IsNPCBreachLockedByTimestamp(
    npcPS: ref<ScriptedPuppetPS>,
    gameInstance: GameInstance
  ) -> Bool {
    if !IsDefined(npcPS) {
      return false;
    }

    let shouldClear: Bool;
    let isLocked: Bool = BreachLockSystem.IsLockedByTimestamp(
      npcPS.m_betterNetrunningNPCBreachFailedTimestamp,
      gameInstance,
      shouldClear
    );

    if shouldClear {
      npcPS.m_betterNetrunningNPCBreachFailedTimestamp = 0.0;
    }

    return isLocked;
  }
}

