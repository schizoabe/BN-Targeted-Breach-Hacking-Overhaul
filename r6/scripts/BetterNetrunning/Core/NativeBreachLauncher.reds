
module BetterNetrunning.Core

import BetterNetrunning.Logging.*

public class BNNativeBreachAction extends PuppetAction {
  public let m_minigameDef:       TweakDBID;
  public let m_networkName:       String;
  public let m_entityForMinigame: wref<Entity>;
  public let m_devicesCount:      Int32;
  public let m_attempt:           Int32;

  public func CanPayCost(opt user: ref<GameObject>, opt checkOverclock: Bool) -> Bool { return true; }
  public func PayCost(opt checkOverclock: Bool) -> Bool { return true; }

  private func CompleteAction(gameInstance: GameInstance) -> Void {
    let gi: GameInstance = gameInstance;
    let requesterID: EntityID = this.GetRequesterID();

    let netBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().NetworkBlackboard);
    netBB.SetInt    (GetAllBlackboardDefs().NetworkBlackboard.DevicesCount,  this.m_devicesCount, true);
    netBB.SetBool   (GetAllBlackboardDefs().NetworkBlackboard.OfficerBreach, false, true);
    netBB.SetBool   (GetAllBlackboardDefs().NetworkBlackboard.RemoteBreach,  true, true);
    netBB.SetBool   (GetAllBlackboardDefs().NetworkBlackboard.SuicideBreach, false, true);
    netBB.SetVariant(GetAllBlackboardDefs().NetworkBlackboard.MinigameDef,   ToVariant(this.m_minigameDef), true);
    netBB.SetString (GetAllBlackboardDefs().NetworkBlackboard.NetworkName,   this.m_networkName, true);
    netBB.SetEntityID(GetAllBlackboardDefs().NetworkBlackboard.DeviceID,     requesterID, true);
    netBB.SetInt    (GetAllBlackboardDefs().NetworkBlackboard.Attempt,      this.m_attempt, true);

    let minigameBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().HackingMinigame);
    let entityForMinigame: wref<Entity> = this.m_entityForMinigame;
    if !IsDefined(entityForMinigame) {
      entityForMinigame = GameInstance.FindEntityByID(gi, requesterID) as Entity;
    }
    if IsDefined(entityForMinigame) {
      minigameBB.SetVariant(GetAllBlackboardDefs().HackingMinigame.Entity, ToVariant(entityForMinigame), true);
    }

    let psmEvent: ref<PSMPostponedParameterBool> = new PSMPostponedParameterBool();
    psmEvent.id = n"NanoWireRemoteBreach";
    psmEvent.value = true;
    GameInstance.GetPlayerSystem(gi).GetLocalPlayerMainGameObject().QueueEvent(psmEvent);

    BNInfo("NativeBreachLauncher", "CompleteAction fired via ProcessRPGAction — network=\"" + this.m_networkName + "\"");
  }
}

public class BNNativeBreachLauncher {

  public static func Launch(
    gi: GameInstance,
    requester: wref<GameObject>,
    minigameDef: TweakDBID,
    networkName: String,
    opt targetEntity: wref<Entity>,
    opt devicesCount: Int32,
    opt attempt: Int32
  ) -> Bool {
    if !IsDefined(requester) {
      BNError("NativeBreachLauncher", "Launch: requester not defined");
      return false;
    }

    let minigameBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().HackingMinigame);
    let currentState: HackingMinigameState = IntEnum(minigameBB.GetInt(GetAllBlackboardDefs().HackingMinigame.State));
    if Equals(currentState, HackingMinigameState.InProgress) {
      BNWarn("NativeBreachLauncher", "Launch failed — a minigame is already in progress");
      return false;
    }

    let action: ref<BNNativeBreachAction> = new BNNativeBreachAction();
    action.SetObjectActionID(t"QuickHack.BNNativeBreachTrigger");
    action.RegisterAsRequester(requester.GetEntityID());
    action.SetExecutor(requester);
    action.m_minigameDef       = minigameDef;
    action.m_networkName       = networkName;
    action.m_entityForMinigame = targetEntity;
    action.m_devicesCount      = devicesCount > 0 ? devicesCount : 1;
    action.m_attempt           = attempt > 0 ? attempt : 1;

    BNInfo("NativeBreachLauncher", "Launch: dispatching ProcessRPGAction for \"" + networkName + "\"");
    action.ProcessRPGAction(gi);
    return true;
  }
}
