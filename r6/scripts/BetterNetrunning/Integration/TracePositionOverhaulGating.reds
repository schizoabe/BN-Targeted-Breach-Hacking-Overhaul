

module BetterNetrunning.Integration

@if(ModuleExists("TracePositionOverhaul"))
import TracePositionOverhaul.*

public abstract class TracePositionOverhaulGating {

  

  @if(ModuleExists("TracePositionOverhaul"))
  public static func IsValidTraceSource(npc: wref<NPCPuppet>) -> Bool {

    if !IsDefined(npc) { return false; }
    if !ScriptedPuppet.IsAlive(npc) { return false; }
    if ScriptedPuppet.IsDefeated(npc) { return false; }

    if !ScriptedPuppet.CanTrace(npc) { return false; }

    if !npc.IsNetrunnerPuppet() { return false; }

    return true;
  }

  @if(!ModuleExists("TracePositionOverhaul"))
  public static func IsValidTraceSource(npc: wref<NPCPuppet>) -> Bool {

    if !IsDefined(npc) { return false; }
    if !ScriptedPuppet.IsAlive(npc) { return false; }
    if ScriptedPuppet.IsDefeated(npc) { return false; }

    if !npc.IsNetrunnerPuppet() { return false; }

    return true;
  }

  

  @if(ModuleExists("TracePositionOverhaul"))
  public static func GetNPCsInRadius(
    player: wref<PlayerPuppet>,
    gameInstance: GameInstance,
    radius: Float
  ) -> array<ref<GameObject>> {
    let npcs: array<ref<GameObject>>;

    let targetingSystem: ref<TargetingSystem> = GameInstance.GetTargetingSystem(gameInstance);

    let searchQuery: TargetSearchQuery;
    searchQuery.testedSet = TargetingSet.Complete;
    searchQuery.searchFilter = TSF_All(TSFMV.Obj_Puppet);  // All puppets (NPCs)
    searchQuery.maxDistance = radius;
    searchQuery.filterObjectByDistance = true;
    searchQuery.includeSecondaryTargets = false;
    searchQuery.ignoreInstigator = true;

    let targetParts: array<TS_TargetPartInfo>;
    targetingSystem.GetTargetParts(player, searchQuery, targetParts);

    let i: Int32 = 0;
    while i < ArraySize(targetParts) {
      let targetComponent: ref<TargetingComponent> = TS_TargetPartInfo.GetComponent(targetParts[i]);
      if IsDefined(targetComponent) {
        let obj: ref<GameObject> = targetComponent.GetEntity() as GameObject;
        if IsDefined(obj) && obj.IsNPC() {
          ArrayPush(npcs, obj);
        }
      }
      i += 1;
    }

    return npcs;
  }

  @if(!ModuleExists("TracePositionOverhaul"))
  public static func GetNPCsInRadius(
    player: wref<PlayerPuppet>,
    gameInstance: GameInstance,
    radius: Float
  ) -> array<ref<GameObject>> {

    let npcs: array<ref<GameObject>>;
    return npcs;
  }

  

  public static func FindNearestValidTraceSource(
    player: wref<PlayerPuppet>,
    gameInstance: GameInstance,
    radius: Float
  ) -> wref<NPCPuppet> {

    let npcs: array<ref<GameObject>> = TracePositionOverhaulGating.GetNPCsInRadius(player, gameInstance, radius);

    if ArraySize(npcs) == 0 {
      return null;
    }

    let playerPos: Vector4 = player.GetWorldPosition();
    let nearestNPC: wref<NPCPuppet>;
    let nearestDistSq: Float = radius * radius; // Squared distance threshold

    let i: Int32 = 0;
    let count: Int32 = ArraySize(npcs);
    while i < count {
      let npcPuppet: wref<NPCPuppet> = npcs[i] as NPCPuppet;

      if TracePositionOverhaulGating.IsValidTraceSource(npcPuppet) {
        let npcPos: Vector4 = npcPuppet.GetWorldPosition();
        let distSq: Float = Vector4.DistanceSquared2D(playerPos, npcPos);

        if distSq < nearestDistSq {
          nearestDistSq = distSq;
          nearestNPC = npcPuppet;
        }
      }

      i += 1;
    }

    return nearestNPC;
  }

} // class TracePositionOverhaulGating

