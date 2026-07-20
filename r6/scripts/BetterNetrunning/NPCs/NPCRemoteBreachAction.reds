

module BetterNetrunning.NPCs

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Network.*
import BetterNetrunning.Marking.*
import BetterNetrunning.RemoteBreach.Core.*
import BetterNetrunningConfig.*
import BetterNetrunning.CounterBreach.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Perks.*

@if(ModuleExists("HackingExtensions"))
import HackingExtensions.*

@if(ModuleExists("HackingExtensions"))
public class OnNPCRemoteBreachICEBoardSucceeded extends OnCustomHackingSucceeded {
  public func Execute() -> Void {
    let gi: GameInstance = GetGameInstance();
    let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gi);

    let stateSystem: ref<NPCRemoteBreachStateSystem> =
      container.Get(BNConstants.CLASS_NPC_REMOTE_BREACH_STATE_SYSTEM()) as NPCRemoteBreachStateSystem;
    let npcPS: wref<ScriptedPuppetPS>;
    if IsDefined(stateSystem) { npcPS = stateSystem.GetCurrentNPC(); }

    let cbs: ref<CounterBreachSystem> =
      container.Get(BNConstants.CLASS_COUNTER_BREACH_SYSTEM()) as CounterBreachSystem;

    if !IsDefined(npcPS) {
      if IsDefined(cbs) { cbs.ShowWarning("ICE ANALYSIS COMPLETE"); }
      BNWarn("NPCRemoteBreach", "No NPC in state system after ICE board success");
      return;
    }

    let minigameBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi)
      .Get(GetAllBlackboardDefs().HackingMinigame);
    let activePrograms: array<TweakDBID> = FromVariant<array<TweakDBID>>(
      minigameBB.GetVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms));

    let hitsThisRound: Int32 = 0;
    let heatThisRound: Float = 0.0;
    let k: Int32 = 0;
    while k < ArraySize(activePrograms) {
      let pid: TweakDBID = activePrograms[k];
      if pid == BNConstants.PROGRAM_ACTION_BN_RB_ICEPICK_V1() { hitsThisRound += 2 + RandRange(0, 4); heatThisRound += 0.2; }
      else if pid == BNConstants.PROGRAM_ACTION_BN_RB_ICEPICK_V3() { hitsThisRound += 5 + RandRange(0, 4); }
      else if pid == BNConstants.PROGRAM_ACTION_BN_RB_ICEPICK_V2() { heatThisRound -= 0.3; }
      k += 1;
    }

    let markingSystem: ref<MarkingStateSystem> =
      container.Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    let globalBonus: Int32 = IsDefined(markingSystem) ? markingSystem.GetHeatICEBonus() : 0;

    if hitsThisRound > 0 {
      if npcPS.m_bnNPCIceHitsRequired <= 0 {
        npcPS.m_bnNPCIceHitsRequired = StateSystemUtils.GetHeatScaledICEHits(gi);
      }
      let effective: Int32 = npcPS.m_bnNPCIceHitsRequired + globalBonus;
      npcPS.m_bnNPCIceHitsApplied += hitsThisRound;
      if npcPS.m_bnNPCIceHitsApplied > effective {
        npcPS.m_bnNPCIceHitsApplied = effective;
      }
    }

    if IsDefined(markingSystem) && heatThisRound != 0.0 {
      markingSystem.AddSessionHeat(heatThisRound);
      BNInfo("NPCRemoteBreach", "ICE board heat delta: " + ToString(heatThisRound));
    }

    let effectiveRequired: Int32 = npcPS.m_bnNPCIceHitsRequired + globalBonus;
    if IsDefined(markingSystem) && markingSystem.GetDisarmICETimer() > 0.0 {
      effectiveRequired = 1;
    }
    let iceFullyBroken: Bool = npcPS.m_bnNPCIceDefeated || npcPS.m_bnNPCIceHitsApplied >= effectiveRequired;
    BNInfo("NPCRemoteBreach", "ICEBoardSucceeded: activePrograms=" + ToString(ArraySize(activePrograms))
      + " hitsThisRound=" + ToString(hitsThisRound)
      + " hitsApplied=" + ToString(npcPS.m_bnNPCIceHitsApplied)
      + " base=" + ToString(npcPS.m_bnNPCIceHitsRequired)
      + " effective=" + ToString(effectiveRequired)
      + " iceFullyBroken=" + ToString(iceFullyBroken));

    let npcEntity: wref<GameObject> = npcPS.GetOwnerEntityWeak() as GameObject;
    let npcName: String = "TARGET";
    if IsDefined(npcEntity) {
      let raw: String = GetLocalizedText(npcEntity.GetDisplayName());
      if NotEquals(raw, s"") { npcName = raw; }
    }
    if IsDefined(markingSystem) {
      markingSystem.RecordRemoteBreachTarget(npcName, "personnel");
      markingSystem.RecordBreachICEState(effectiveRequired, npcPS.m_bnNPCIceHitsApplied);
    }

    if iceFullyBroken {
      npcPS.m_bnNPCIceDefeated = true;

      if npcPS.IsConnectedToAccessPoint() {
        let deviceLink: ref<SharedGameplayPS> = npcPS.GetDeviceLink();
        if IsDefined(deviceLink) {
          deviceLink.m_betterNetrunningUnlockTimestampNPCs = TimeUtils.GetCurrentTimestamp(gi);
        }
      }
      npcPS.m_quickHacksExposed = true;

      npcPS.BN_StampSJKIBreached();
      let exposeEvent: ref<SetExposeQuickHacks> = new SetExposeQuickHacks();
      exposeEvent.isRemote = true;
      npcPS.GetPersistencySystem().QueueEntityEvent(
        PersistentID.ExtractEntityID(npcPS.GetID()), exposeEvent);

      if IsDefined(npcEntity) {
        RPGManager.GiveReward(gi, t"RPGActionRewards.Hacking",
          Cast<StatsObjectID>(npcEntity.GetEntityID()));
      }

      if IsDefined(stateSystem) { stateSystem.ClearCurrentNPC(); }

      if IsDefined(markingSystem) { markingSystem.ShowRemoteBreachStatus(); }
      BNInfo("NPCRemoteBreach", "ICE fully broken — NPC stamped and quickhacks exposed");
    } else {
      if IsDefined(markingSystem) { markingSystem.ShowRemoteBreachStatus(); }
      BNInfo("NPCRemoteBreach", "NEURAL ICE WEAKENED — "
        + ToString(npcPS.m_bnNPCIceHitsApplied) + "/"
        + ToString(effectiveRequired) + " HITS APPLIED");
    }
  }
}

@if(ModuleExists("HackingExtensions"))
public class OnNPCRemoteBreachSucceeded extends OnCustomHackingSucceeded {
  public func Execute() -> Void {
    let gi: GameInstance = GetGameInstance();
    let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gi);

    let stateSystem: ref<NPCRemoteBreachStateSystem> =
      container.Get(BNConstants.CLASS_NPC_REMOTE_BREACH_STATE_SYSTEM()) as NPCRemoteBreachStateSystem;

    if !IsDefined(stateSystem) {
      BNError("NPCRemoteBreach", "NPCRemoteBreachStateSystem not found on subnet success");
      return;
    }

    let npcPS: wref<ScriptedPuppetPS> = stateSystem.GetCurrentNPC();
    BNInfo("NPCRemoteBreach", "SubnetSucceeded callback fired — npcPS="
      + (IsDefined(npcPS) ? "defined" : "NULL")
      + (IsDefined(npcPS) ? (" connectedToAP=" + ToString(npcPS.IsConnectedToAccessPoint())
        + " quickHacksExposed=" + ToString(npcPS.m_quickHacksExposed)) : ""));
    if !IsDefined(npcPS) {
      BNError("NPCRemoteBreach", "No NPC in state system on subnet success");
      return;
    }

    if npcPS.IsConnectedToAccessPoint() {
      let deviceLink: ref<SharedGameplayPS> = npcPS.GetDeviceLink();
      if IsDefined(deviceLink) {
        deviceLink.m_betterNetrunningUnlockTimestampNPCs = TimeUtils.GetCurrentTimestamp(gi);
      }
    }

    npcPS.m_quickHacksExposed = true;

    npcPS.BN_StampSJKIBreached();

    let exposeEvent: ref<SetExposeQuickHacks> = new SetExposeQuickHacks();
    exposeEvent.isRemote = true;
    npcPS.GetPersistencySystem().QueueEntityEvent(
      PersistentID.ExtractEntityID(npcPS.GetID()), exposeEvent);

    BNInfo("NPCRemoteBreach", "NPC subnet breached — quickhacks exposed (single NPC only)");

    let npcEntity: wref<GameObject> = npcPS.GetOwnerEntityWeak() as GameObject;
    if IsDefined(npcEntity) {
      RPGManager.GiveReward(gi, t"RPGActionRewards.Hacking",
        Cast<StatsObjectID>(npcEntity.GetEntityID()));
    }

    stateSystem.ClearCurrentNPC();
  }
}

@if(ModuleExists("HackingExtensions"))
public class OnNPCRemoteBreachFailed extends OnCustomHackingFailed {
  public func Execute() -> Void {
    let gi: GameInstance = GetGameInstance();
    let stateSystem: ref<NPCRemoteBreachStateSystem> =
      GameInstance.GetScriptableSystemsContainer(gi)
        .Get(BNConstants.CLASS_NPC_REMOTE_BREACH_STATE_SYSTEM()) as NPCRemoteBreachStateSystem;
    if IsDefined(stateSystem) { stateSystem.ClearCurrentNPC(); }
  }
}

@if(ModuleExists("HackingExtensions"))
public class NPCRemoteBreachAction extends CustomAccessBreach {
  private let m_npcPS: ref<ScriptedPuppetPS>;
  private let m_isICEBoard: Bool;
  public let m_calculatedRAMCost: Int32;

  public func GetTweakDBChoiceRecord() -> String { return "NPCRemoteBreach"; }

  public func SetNPC(npcPS: ref<ScriptedPuppetPS>) -> Void {
    this.m_npcPS = npcPS;
  }

  public func GetCost() -> Int32 { return this.m_calculatedRAMCost; }

  public func CanPayCost(opt user: ref<GameObject>, opt checkForOverclockedState: Bool) -> Bool {
    if this.m_calculatedRAMCost <= 0 { return true; }
    let executor: ref<GameObject>;
    if IsDefined(user) { executor = user; } else { executor = this.GetExecutor(); }
    if !IsDefined(executor) { return false; }
    let statPoolSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(executor.GetGame());
    let currentRAM: Float = statPoolSystem.GetStatPoolValue(
      Cast<StatsObjectID>(executor.GetEntityID()), gamedataStatPoolType.Memory, false);
    return currentRAM >= Cast<Float>(this.m_calculatedRAMCost);
  }

  public func PayCost(opt checkForOverclockedState: Bool) -> Bool {
    if this.m_calculatedRAMCost <= 0 { return true; }
    let executor: ref<GameObject> = this.GetExecutor();
    if !IsDefined(executor) { return false; }
    let statPoolSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(executor.GetGame());
    let executorID: StatsObjectID = Cast<StatsObjectID>(executor.GetEntityID());
    let currentRAM: Float = statPoolSystem.GetStatPoolValue(executorID, gamedataStatPoolType.Memory, false);
    if currentRAM < Cast<Float>(this.m_calculatedRAMCost) { return false; }
    statPoolSystem.RequestSettingStatPoolValue(
      executorID, gamedataStatPoolType.Memory,
      currentRAM - Cast<Float>(this.m_calculatedRAMCost), executor, false);
    return true;
  }

  private func CompleteAction(gameInstance: GameInstance) -> Void {
    if !IsDefined(this.m_npcPS) {
      BNError("NPCRemoteBreach", "No NPC PS on action — cannot complete");
      return;
    }

    if this.m_npcPS.m_bnNPCIceHitsRequired == 0 {
      this.m_npcPS.m_bnNPCIceHitsRequired = StateSystemUtils.GetHeatScaledICEHits(gameInstance);
      BNInfo("NPCRemoteBreach",
        "NPC ICE initialized: " + ToString(this.m_npcPS.m_bnNPCIceHitsRequired) + " hits required");
    }

    let ms: ref<MarkingStateSystem> =
      GameInstance.GetScriptableSystemsContainer(gameInstance)
        .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    let disarmICEActive: Bool = IsDefined(ms) && ms.GetDisarmICETimer() > 0.0;
    let globalBonus: Int32 = IsDefined(ms) ? ms.GetHeatICEBonus() : 0;
    let effectiveRequired: Int32 = this.m_npcPS.m_bnNPCIceHitsRequired + globalBonus;
    if disarmICEActive {
      effectiveRequired = 1;
      BNInfo("NPCRemoteBreach", "Disarm ICE active — effective ICE required: 1"
        + " (base: " + ToString(this.m_npcPS.m_bnNPCIceHitsRequired) + ")");
    }
    let iceAccessible: Bool = this.m_npcPS.m_bnNPCIceDefeated || this.m_npcPS.m_bnNPCIceHitsApplied >= effectiveRequired;
    if !iceAccessible {
      this.m_isICEBoard = true;
      this.m_minigameDefinition = BNPerkData.GetRemoteBreachICEBoard(gameInstance);
      BNInfo("NPCRemoteBreach",
        "ICE intact (" + ToString(this.m_npcPS.m_bnNPCIceHitsApplied)
        + "/" + ToString(this.m_npcPS.m_bnNPCIceHitsRequired) + ") — showing ICE board");
    } else {
      this.m_isICEBoard = false;
      this.m_minigameDefinition = BNConstants.MINIGAME_NPC_REMOTE_BREACH();
      BNInfo("NPCRemoteBreach", "ICE compromised — showing NPC subnet board");
    }

    let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gameInstance);

    let nullDevPS: ref<ScriptableDeviceComponentPS>;
    let devSS: ref<DeviceRemoteBreachStateSystem> =
      container.Get(BNConstants.CLASS_DEVICE_REMOTE_BREACH_STATE_SYSTEM()) as DeviceRemoteBreachStateSystem;
    if IsDefined(devSS) { devSS.SetCurrentDevice(nullDevPS, ""); }

    let npcStateSystem: ref<NPCRemoteBreachStateSystem> =
      container.Get(BNConstants.CLASS_NPC_REMOTE_BREACH_STATE_SYSTEM()) as NPCRemoteBreachStateSystem;
    if IsDefined(npcStateSystem) {
      npcStateSystem.SetCurrentNPC(this.m_npcPS);
    }

    let customHackSystem: ref<CustomHackingSystem> =
      container.Get(BNConstants.CLASS_CUSTOM_HACKING_SYSTEM()) as CustomHackingSystem;

    if IsDefined(customHackSystem) {
      let emptyData: array<Variant>;
      let onSucceed: ref<OnCustomHackingSucceeded>;
      if this.m_isICEBoard {
        onSucceed = new OnNPCRemoteBreachICEBoardSucceeded();
      } else {
        onSucceed = new OnNPCRemoteBreachSucceeded();
      }
      let onFailed: ref<OnNPCRemoteBreachFailed> = new OnNPCRemoteBreachFailed();

      BNInfo("NPCRemoteBreach", "StartNewQuickhackInstance args:"
        + " networkName=" + this.m_networkName
        + " minigameDef=" + TDBID.ToStringDEBUG(this.m_minigameDefinition)
        + " isICEBoard=" + ToString(this.m_isICEBoard)
        + " npcPS=" + (IsDefined(this.m_npcPS) ? "defined" : "NULL")
        + " npcPSClass=" + (IsDefined(this.m_npcPS) ? NameToString(this.m_npcPS.GetClassName()) : "N/A")
        + " iceHits=" + ToString(this.m_npcPS.m_bnNPCIceHitsApplied)
        + "/" + ToString(this.m_npcPS.m_bnNPCIceHitsRequired)
        + " connectedToAP=" + ToString(this.m_npcPS.IsConnectedToAccessPoint())
        + " quickHacksExposed=" + ToString(this.m_npcPS.m_quickHacksExposed));

      let success: Bool = customHackSystem.StartNewQuickhackInstance(
        this.m_networkName,
        this,
        this.m_minigameDefinition,
        this.m_npcPS,
        emptyData,
        onSucceed,
        onFailed
      );
      BNInfo("NPCRemoteBreach", "StartNewQuickhackInstance returned: " + ToString(success));
    } else {
      BNError("NPCRemoteBreach", "CustomHackingSystem not found");
    }

    let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gameInstance)
      .Get(GetAllBlackboardDefs().NetworkBlackboard);
    bb.SetInt   (GetAllBlackboardDefs().NetworkBlackboard.DevicesCount,  1);
    bb.SetBool  (GetAllBlackboardDefs().NetworkBlackboard.OfficerBreach, false);
    bb.SetBool  (GetAllBlackboardDefs().NetworkBlackboard.RemoteBreach,  true);
    bb.SetBool  (GetAllBlackboardDefs().NetworkBlackboard.SuicideBreach, false);
    bb.SetVariant(GetAllBlackboardDefs().NetworkBlackboard.MinigameDef,
      ToVariant(this.m_minigameDefinition), true);
    bb.SetString (GetAllBlackboardDefs().NetworkBlackboard.NetworkName,  this.m_networkName, true);
    bb.SetEntityID(GetAllBlackboardDefs().NetworkBlackboard.DeviceID,
      GetPlayer(gameInstance).GetEntityID(), true);
    bb.SetInt   (GetAllBlackboardDefs().NetworkBlackboard.Attempt, this.m_attempt);

    let psmEvent: ref<PSMPostponedParameterBool> = new PSMPostponedParameterBool();
    psmEvent.id = n"NanoWireRemoteBreach";
    psmEvent.value = true;
    GameInstance.GetPlayerSystem(gameInstance).GetLocalPlayerMainGameObject().QueueEvent(psmEvent);
  }
}

@if(ModuleExists("HackingExtensions"))
@wrapMethod(ScriptedPuppet)
private final func TranslateChoicesIntoQuickSlotCommands(
  const puppetActions: script_ref<array<ref<PuppetAction>>>,
  commands: script_ref<array<ref<QuickhackData>>>
) -> Void {
  wrappedMethod(puppetActions, commands);

  let npcPS: ref<ScriptedPuppetPS> = this.GetPS();
  if !IsDefined(npcPS) { return; }

  if !BetterNetrunningSettings.RemoteBreachEnabledNPC() { return; }
  if this.IsDead() { return; }               // dead NPC gate
  if npcPS.m_quickHacksExposed { return; }          // already breached

  let perkSysNRB: ref<BNPerkSystem> = BNPerkSystem.GetInstance(this.GetGame());
  if !IsDefined(perkSysNRB) || perkSysNRB.GetPerkLevel(BNPerk.IntrusionSuite) <= 0 { return; }

  let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
  if !IsDefined(player) { return; }

  let action: ref<NPCRemoteBreachAction> = NPCRemoteBreachUtils.CreateAction(npcPS, player);
  if !IsDefined(action) { return; }

  let canPay: Bool = action.CanPayCost(player, false);

  let entry: ref<QuickhackData> = new QuickhackData();
  entry.m_itemID              = ItemID.None();
  entry.m_actionOwnerName     = StringToName(this.GetDisplayName());
  entry.m_actionOwner         = this.GetEntityID();
  let npcBreachRecord: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(t"QuickHack.BNNPCRemoteBreach");
  let deviceBreachRecord: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(BNConstants.DEVICE_ACTION_REMOTE_BREACH());
  entry.m_title               = LocKeyToString(npcBreachRecord.ObjectActionUI().Caption());
  entry.m_description         = LocKeyToString(npcBreachRecord.ObjectActionUI().Description());
  entry.m_icon                = deviceBreachRecord.ObjectActionUI().CaptionIcon().TexturePartID().GetID();
  entry.m_cost                = action.m_calculatedRAMCost;
  entry.m_costRaw             = action.m_calculatedRAMCost;
  entry.m_ICELevel            = 0.0;
  entry.m_ICELevelVisible     = false;
  entry.m_networkBreached     = false;
  entry.m_actionMatchesTarget = true;

  if canPay {
    entry.m_action      = action;
    entry.m_actionState = EActionInactivityReson.Ready;
    entry.m_isLocked    = false;
  } else {
    entry.m_isLocked       = true;
    entry.m_inactiveReason = BNConstants.LOCKEY_RAM_INSUFFICIENT();
    entry.m_actionState    = EActionInactivityReson.OutOfMemory;
  }

  ArrayPush(Deref(commands), entry);
}

@if(ModuleExists("HackingExtensions"))
public abstract class NPCRemoteBreachUtils {

  public static func CreateAction(
    npcPS: ref<ScriptedPuppetPS>,
    player: ref<PlayerPuppet>
  ) -> ref<NPCRemoteBreachAction> {
    if !IsDefined(player) { return null; }

    let gi: GameInstance = npcPS.GetGameInstance();

    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
    let statPoolSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gi);
    let playerID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
    let maxRAM: Float = statsSystem.GetStatValue(playerID, gamedataStatType.Memory);
    let costPercent: Int32 = BetterNetrunningSettings.RemoteBreachRAMCostPercent();
    let ramCost: Int32 = Cast<Int32>(maxRAM * Cast<Float>(costPercent) / 100.0 + 0.5);
    if ramCost < 1 { ramCost = 1; }

    let npcEntity: wref<GameObject> = npcPS.GetOwnerEntityWeak() as GameObject;
    let npcName: String = IsDefined(npcEntity)
      ? GetLocalizedText(npcEntity.GetDisplayName()) : "Target";

    let action: ref<NPCRemoteBreachAction> = new NPCRemoteBreachAction();
    action.SetNPC(npcPS);
    action.SetExecutor(player); // required: ProcessRPGAction calls PayCost → GetExecutor() must return player
    action.m_calculatedRAMCost = ramCost;
    action.m_networkName       = npcName;
    action.m_isRemote          = true;
    action.m_npcCount          = 1;
    action.m_attempt           = 0;
    action.actionName          = n"NPCRemoteBreachAction";

    let currentRAM: Float = statPoolSystem.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
    if currentRAM < Cast<Float>(ramCost) {
      action.SetInactiveWithReason(false, BNConstants.LOCKEY_RAM_INSUFFICIENT());
    } else {
      action.SetActive();
    }

    return action;
  }
}

