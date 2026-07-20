

module BetterNetrunning.NPCs

import BetterNetrunning.Logging.*
import BetterNetrunning.Core.*

public class UnconsciousBreachStateSystem extends ScriptableSystem {
  private let m_npcPS: wref<ScriptedPuppetPS>;

  public func SetNPC(npcPS: ref<ScriptedPuppetPS>) -> Void {
    this.m_npcPS = npcPS;
    BNDebug("UnconsciousBreachState", "Available NPC set");
  }

  public func GetNPC() -> wref<ScriptedPuppetPS> {
    return this.m_npcPS;
  }

  public func ClearNPC() -> Void {
    this.m_npcPS = null;
  }

  public func IsAvailableForDevice(devicePS: ref<ScriptableDeviceComponentPS>) -> Bool {
    if !IsDefined(this.m_npcPS) { return false; }
    if this.m_npcPS.m_betterNetrunningWasDirectlyBreached { return false; }
    return true;
  }
}

