

















module BetterNetrunning.RemoteBreach.Core

import BetterNetrunning.Logging.*


@addField(ScriptedPuppetPS)
public let m_bnNPCIceHitsRequired: Int32;

@addField(ScriptedPuppetPS)
public let m_bnNPCIceHitsApplied: Int32;



@addField(ScriptedPuppetPS)
public let m_bnNPCIceDefeated: Bool;


public class NPCRemoteBreachStateSystem extends ScriptableSystem {
  private let m_currentNPC: wref<ScriptedPuppetPS>;

  public func SetCurrentNPC(npcPS: ref<ScriptedPuppetPS>) -> Void {
    this.m_currentNPC = npcPS;
    BNDebug("NPCRemoteBreachState", "Current NPC set");
  }

  public func GetCurrentNPC() -> wref<ScriptedPuppetPS> {
    return this.m_currentNPC;
  }

  public func ClearCurrentNPC() -> Void {
    this.m_currentNPC = null;
  }
}

