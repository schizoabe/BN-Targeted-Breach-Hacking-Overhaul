
module BetterNetrunning.Minigame

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Marking.*
import BetterNetrunning.CounterBreach.*

public class BNCascadeSecondUploadCallback extends DelayCallback {
  public let m_player: wref<PlayerPuppet>;
  public let m_target: wref<ScriptedPuppet>;
  public let m_quickhackData: ref<QuickhackData>;

  public static func Create(player: ref<PlayerPuppet>, target: ref<ScriptedPuppet>, data: ref<QuickhackData>) -> ref<BNCascadeSecondUploadCallback> {
    let cb: ref<BNCascadeSecondUploadCallback> = new BNCascadeSecondUploadCallback();
    cb.m_player = player;
    cb.m_target = target;
    cb.m_quickhackData = data;
    return cb;
  }

  public func Call() -> Void {
    if !IsDefined(this.m_player) || !IsDefined(this.m_target) || !IsDefined(this.m_quickhackData) { return; }
    if !ScriptedPuppet.IsAlive(this.m_target) { return; }
    BNCascadeDispatchUtils.TriggerQuickhackUpload(this.m_player, this.m_quickhackData);
  }
}

public abstract class BNCascadeDispatchUtils {

  public static func TriggerQuickhackUpload(player: ref<PlayerPuppet>, data: ref<QuickhackData>) -> Void {
    let blackboard: ref<IBlackboard> = GameInstance.GetBlackboardSystem(player.GetGame())
      .GetLocalInstanced(player.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
    let evt: ref<OnSpecialQuickhackTriggeredEvent> = new OnSpecialQuickhackTriggeredEvent();
    evt.quickhackData = data;
    blackboard.SetVariant(GetAllBlackboardDefs().PlayerStateMachine.CostFreeActionID, ToVariant(data.m_action.GetObjectActionID()));
    GameInstance.GetDelaySystem(player.GetGame()).DelayEvent(player, evt, 0.10);
  }

  public static func ResolveSelectedAction(gi: GameInstance, player: ref<PlayerPuppet>, cbs: ref<CounterBreachSystem>, markingSystem: ref<MarkingStateSystem>) -> wref<ObjectAction_Record> {
    let deckID: ItemID = EquipmentSystem.GetData(player).GetActiveItem(gamedataEquipmentArea.SystemReplacementCW);
    if !EquipmentSystem.IsItemCyberdeck(deckID) {
      if IsDefined(cbs) { cbs.ShowWarning("CASCADE: NO CYBERDECK"); }
      BNInfo("CascadeDispatch", "No cyberdeck equipped");
      return null;
    }

    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(gi);
    let deckData: wref<gameItemData> = ts.GetItemData(player, deckID);
    let qhActions: array<wref<ObjectAction_Record>>;
    if IsDefined(deckData) {
      let parts: array<InnerItemData>;
      deckData.GetItemParts(parts);
      let pi: Int32 = 0;
      while pi < ArraySize(parts) {
        let part: InnerItemData = parts[pi];
        if ItemID.IsValid(InnerItemData.GetItemID(part)) {
          let programRec: ref<Item_Record> = InnerItemData.GetStaticData(part);
          if IsDefined(programRec) {
            let progActions: array<wref<ObjectAction_Record>>;
            programRec.ObjectActions(progActions);
            let ai: Int32 = 0;
            let foundForProgram: Bool = false;
            while ai < ArraySize(progActions) && !foundForProgram {
              let pact: wref<ObjectAction_Record> = progActions[ai];
              if IsDefined(pact) && IsDefined(pact.ObjectActionType()) &&
                 Equals(pact.ObjectActionType().Type(), gamedataObjectActionType.PuppetQuickHack) {
                ArrayPush(qhActions, pact);
                foundForProgram = true;
              }
              ai += 1;
            }
          }
        }
        pi += 1;
      }
    }

    let qhCount: Int32 = ArraySize(qhActions);
    if qhCount == 0 {
      if IsDefined(cbs) { cbs.ShowWarning("CASCADE: QUICKHACK NOT APPLICABLE"); }
      BNWarn("CascadeDispatch", "No PuppetQuickHack action in player quickhack list");
      return null;
    }

    let cascadeIdx: Int32 = IsDefined(markingSystem) ? markingSystem.GetCascadeQHIndex() % qhCount : 0;
    return qhActions[cascadeIdx];
  }
}
