
module BetterNetrunning.Marking

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Network.*
import BetterNetrunning.UI.*
import BetterNetrunning.Utils.*

public class BNMarkNPCAction extends PuppetAction {
  private let m_npcPS:   ref<ScriptedPuppetPS>;
  private let m_ramCost: Int32;

  public func SetNPC(npcPS: ref<ScriptedPuppetPS>, ramCost: Int32) -> Void {
    this.m_npcPS   = npcPS;
    this.m_ramCost = ramCost;
  }

  public func GetTweakDBChoiceRecord() -> String { return "BNMarkNPC"; }
  public func GetCost() -> Int32 { return this.m_ramCost; }

  public func CanPayCost(opt user: ref<GameObject>, opt checkOverclock: Bool) -> Bool {
    let executor: ref<GameObject>;
    if IsDefined(user) { executor = user; } else { executor = this.GetExecutor(); }
    if !IsDefined(executor) { return false; }
    let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(executor.GetGame());
    let ram: Float = pool.GetStatPoolValue(Cast<StatsObjectID>(executor.GetEntityID()), gamedataStatPoolType.Memory, false);
    return ram >= Cast<Float>(this.m_ramCost);
  }

  public func PayCost(opt checkOverclock: Bool) -> Bool { return true; }

  private func CompleteAction(gameInstance: GameInstance) -> Void {
    if !IsDefined(this.m_npcPS) {
      BNError("NetworkScan", "BNMarkNPCAction: no NPC PS");
      return;
    }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if !IsDefined(mss) { return; }

    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
    if IsDefined(player) && this.m_ramCost > 0 {
      let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gameInstance);
      let playerID: StatsObjectID   = Cast<StatsObjectID>(player.GetEntityID());
      let currentRAM: Float         = pool.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
      pool.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory,
        currentRAM - Cast<Float>(this.m_ramCost), player, false);
    }

    mss.AddMarkFromEntity(this.m_npcPS.GetMyEntityID(), MarkedSubnetType.NPC);
    BNInfo("NetworkScan", "NPC marked: " + EntityID.ToDebugString(this.m_npcPS.GetMyEntityID()));

    let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gameInstance);
    let logSys: ref<ICEScoutLogSystem> = container.Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
    if IsDefined(logSys) { logSys.ShowIfNew(); }
    let testSys: ref<BNTestPanelSystem> = container.Get(n"BetterNetrunning.UI.BNTestPanelSystem") as BNTestPanelSystem;
    if IsDefined(testSys) { testSys.ShowTestPanel(0.0); }
  }
}

public class BNUnmarkNPCAction extends PuppetAction {
  private let m_npcPS:   ref<ScriptedPuppetPS>;
  private let m_ramCost: Int32;

  public func SetNPC(npcPS: ref<ScriptedPuppetPS>, ramCost: Int32) -> Void {
    this.m_npcPS   = npcPS;
    this.m_ramCost = ramCost;
  }

  public func GetTweakDBChoiceRecord() -> String { return "BNUnmarkNPC"; }
  public func GetCost() -> Int32 { return this.m_ramCost; }

  public func CanPayCost(opt user: ref<GameObject>, opt checkOverclock: Bool) -> Bool {
    let executor: ref<GameObject>;
    if IsDefined(user) { executor = user; } else { executor = this.GetExecutor(); }
    if !IsDefined(executor) { return false; }
    let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(executor.GetGame());
    let ram: Float = pool.GetStatPoolValue(Cast<StatsObjectID>(executor.GetEntityID()), gamedataStatPoolType.Memory, false);
    return ram >= Cast<Float>(this.m_ramCost);
  }

  public func PayCost(opt checkOverclock: Bool) -> Bool { return true; }

  private func CompleteAction(gameInstance: GameInstance) -> Void {
    if !IsDefined(this.m_npcPS) {
      BNError("NetworkScan", "BNUnmarkNPCAction: no NPC PS");
      return;
    }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if !IsDefined(mss) { return; }

    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
    if IsDefined(player) && this.m_ramCost > 0 {
      let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gameInstance);
      let playerID: StatsObjectID   = Cast<StatsObjectID>(player.GetEntityID());
      let currentRAM: Float         = pool.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
      pool.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory,
        currentRAM - Cast<Float>(this.m_ramCost), player, false);
    }

    mss.RemoveMarkAny(this.m_npcPS.GetMyEntityID());
    BNInfo("NetworkScan", "NPC unmarked: " + EntityID.ToDebugString(this.m_npcPS.GetMyEntityID()));

    let logSys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
    if IsDefined(logSys) { logSys.Refresh(); }
  }
}

@wrapMethod(ScriptedPuppet)
private final func TranslateChoicesIntoQuickSlotCommands(
  const puppetActions: script_ref<array<ref<PuppetAction>>>,
  commands:            script_ref<array<ref<QuickhackData>>>
) -> Void {
  if this.IsDead() {
    wrappedMethod(puppetActions, commands);
    return;
  }

  wrappedMethod(puppetActions, commands);

  let gi: GameInstance = this.GetGame();

  let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
    .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if !IsDefined(mss) { return; }

  let player: ref<PlayerPuppet> = GetPlayer(gi);
  if !IsDefined(player) { return; }

  let npcPS: ref<ScriptedPuppetPS> = this.GetPS() as ScriptedPuppetPS;
  if !IsDefined(npcPS) { return; }

  let ramCost: Int32 = 2;
  let isMarked: Bool = mss.IsMark(this.GetEntityID(), MarkedSubnetType.NPC);

  let entry: ref<QuickhackData> = new QuickhackData();
  entry.m_itemID              = ItemID.None();
  entry.m_actionOwnerName     = StringToName(this.GetDisplayName());
  entry.m_actionOwner         = this.GetEntityID();
  entry.m_cost                = ramCost;
  entry.m_costRaw             = ramCost;
  entry.m_ICELevel            = 0.0;
  entry.m_ICELevelVisible     = false;
  entry.m_networkBreached     = npcPS.m_bnNPCIceDefeated;
  entry.m_actionMatchesTarget = true;

  if isMarked {
    let action: ref<BNUnmarkNPCAction> = new BNUnmarkNPCAction();
    action.SetNPC(npcPS, ramCost);
    action.SetExecutor(player);

    let rec: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(t"QuickHack.BNUnmark");
    entry.m_title        = LocKeyToString(rec.ObjectActionUI().Caption());
    entry.m_description  = LocKeyToString(rec.ObjectActionUI().Description());
    entry.m_icon         = rec.ObjectActionUI().CaptionIcon().TexturePartID().GetID();
    entry.m_iconCategory = rec.GameplayCategory().IconName();
    entry.m_category     = rec.HackCategory();
    entry.m_type         = rec.ObjectActionType().Type();

    if action.CanPayCost(player, false) {
      entry.m_action      = action;
      entry.m_actionState = EActionInactivityReson.Ready;
      entry.m_isLocked    = false;
    } else {
      entry.m_isLocked       = true;
      entry.m_inactiveReason = BNConstants.LOCKEY_RAM_INSUFFICIENT();
      entry.m_actionState    = EActionInactivityReson.OutOfMemory;
    }
  } else {
    let action: ref<BNMarkNPCAction> = new BNMarkNPCAction();
    action.SetNPC(npcPS, ramCost);
    action.SetExecutor(player);

    let rec: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(t"QuickHack.BNMark");
    entry.m_title        = LocKeyToString(rec.ObjectActionUI().Caption());
    entry.m_description  = LocKeyToString(rec.ObjectActionUI().Description());
    entry.m_icon         = rec.ObjectActionUI().CaptionIcon().TexturePartID().GetID();
    entry.m_iconCategory = rec.GameplayCategory().IconName();
    entry.m_category     = rec.HackCategory();
    entry.m_type         = rec.ObjectActionType().Type();

    if action.CanPayCost(player, false) {
      entry.m_action      = action;
      entry.m_actionState = EActionInactivityReson.Ready;
      entry.m_isLocked    = false;
    } else {
      entry.m_isLocked       = true;
      entry.m_inactiveReason = BNConstants.LOCKEY_RAM_INSUFFICIENT();
      entry.m_actionState    = EActionInactivityReson.OutOfMemory;
    }
  }

  ArrayPush(Deref(commands), entry);
}

public class BNMarkDeviceAction extends PuppetAction {
  private let m_devicePS: ref<ScriptableDeviceComponentPS>;
  private let m_ramCost: Int32;

  public func SetDevicePS(devicePS: ref<ScriptableDeviceComponentPS>, ramCost: Int32) -> Void {
    this.m_devicePS = devicePS;
    this.m_ramCost = ramCost;
    this.SetObjectActionID(t"QuickHack.BNMarkDevice");
  }

  public func GetTweakDBChoiceRecord() -> String { return "BNMarkDevice"; }
  public func GetInteractionDescription() -> String {
    let rec: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(t"QuickHack.BNMarkDevice");
    if IsDefined(rec) {
      let s: String = LocKeyToString(rec.ObjectActionUI().Caption());
      if NotEquals(s, "") { return s; }
    }
    return "Mark";
  }
  public func GetCost() -> Int32 { return this.m_ramCost; }

  public func CanPayCost(opt user: ref<GameObject>, opt checkOverclock: Bool) -> Bool {
    let executor: ref<GameObject>;
    if IsDefined(user) { executor = user; } else { executor = this.GetExecutor(); }
    if !IsDefined(executor) { return false; }
    let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(executor.GetGame());
    let ram: Float = pool.GetStatPoolValue(Cast<StatsObjectID>(executor.GetEntityID()), gamedataStatPoolType.Memory, false);
    return ram >= Cast<Float>(this.m_ramCost);
  }

  public func PayCost(opt checkOverclock: Bool) -> Bool { return true; }

  private func CompleteAction(gameInstance: GameInstance) -> Void {
    if !IsDefined(this.m_devicePS) {
      BNError("NetworkScan", "BNMarkDeviceAction: no device PS");
      return;
    }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if !IsDefined(mss) { return; }

    let deviceEntity: wref<GameObject> = this.m_devicePS.GetOwnerEntityWeak() as GameObject;
    if !IsDefined(deviceEntity) { return; }

    let subnetType: MarkedSubnetType;
    if DaemonFilterUtils.IsCamera(this.m_devicePS) {
      subnetType = MarkedSubnetType.Camera;
    } else if DaemonFilterUtils.IsTurret(this.m_devicePS) {
      subnetType = MarkedSubnetType.Defense;
    } else {
      subnetType = MarkedSubnetType.Root;
    }

    let sharedPS: ref<SharedGameplayPS> = this.m_devicePS;
    NetworkStateUtils.EnsureDeviceICERolled(sharedPS, gameInstance);
    let iceHitsRequired: Int32 = IsDefined(sharedPS) ? sharedPS.m_bnIceHitsRequired : 0;

    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
    if IsDefined(player) && this.m_ramCost > 0 {
      let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gameInstance);
      let playerID: StatsObjectID   = Cast<StatsObjectID>(player.GetEntityID());
      let currentRAM: Float         = pool.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
      pool.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory,
        currentRAM - Cast<Float>(this.m_ramCost), player, false);
    }

    let displayName: String = GetLocalizedText(deviceEntity.GetDisplayName());
    if Equals(displayName, "") { displayName = "Device"; }
    mss.AddMarkNamed(deviceEntity.GetEntityID(), subnetType, displayName, iceHitsRequired);
    BNInfo("NetworkScan", "Device marked: " + displayName);

    let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gameInstance);
    let logSys: ref<ICEScoutLogSystem> = container.Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
    if IsDefined(logSys) { logSys.ShowIfNew(); }
    let testSys: ref<BNTestPanelSystem> = container.Get(n"BetterNetrunning.UI.BNTestPanelSystem") as BNTestPanelSystem;
    if IsDefined(testSys) { testSys.ShowTestPanel(0.0); }
  }
}

public class BNUnmarkDeviceAction extends PuppetAction {
  private let m_devicePS: ref<ScriptableDeviceComponentPS>;
  private let m_ramCost: Int32;

  public func SetDevicePS(devicePS: ref<ScriptableDeviceComponentPS>, ramCost: Int32) -> Void {
    this.m_devicePS = devicePS;
    this.m_ramCost = ramCost;
    this.SetObjectActionID(t"QuickHack.BNUnmarkDevice");
  }

  public func GetTweakDBChoiceRecord() -> String { return "BNUnmarkDevice"; }
  public func GetInteractionDescription() -> String {
    let rec: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(t"QuickHack.BNUnmarkDevice");
    if IsDefined(rec) {
      let s: String = LocKeyToString(rec.ObjectActionUI().Caption());
      if NotEquals(s, "") { return s; }
    }
    return "Unmark";
  }
  public func GetCost() -> Int32 { return this.m_ramCost; }

  public func CanPayCost(opt user: ref<GameObject>, opt checkOverclock: Bool) -> Bool {
    let executor: ref<GameObject>;
    if IsDefined(user) { executor = user; } else { executor = this.GetExecutor(); }
    if !IsDefined(executor) { return false; }
    let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(executor.GetGame());
    let ram: Float = pool.GetStatPoolValue(Cast<StatsObjectID>(executor.GetEntityID()), gamedataStatPoolType.Memory, false);
    return ram >= Cast<Float>(this.m_ramCost);
  }

  public func PayCost(opt checkOverclock: Bool) -> Bool { return true; }

  private func CompleteAction(gameInstance: GameInstance) -> Void {
    if !IsDefined(this.m_devicePS) {
      BNError("NetworkScan", "BNUnmarkDeviceAction: no device PS");
      return;
    }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if !IsDefined(mss) { return; }

    let deviceEntity: wref<GameObject> = this.m_devicePS.GetOwnerEntityWeak() as GameObject;
    if !IsDefined(deviceEntity) { return; }

    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
    if IsDefined(player) && this.m_ramCost > 0 {
      let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gameInstance);
      let playerID: StatsObjectID   = Cast<StatsObjectID>(player.GetEntityID());
      let currentRAM: Float         = pool.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
      pool.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory,
        currentRAM - Cast<Float>(this.m_ramCost), player, false);
    }

    let displayName: String = GetLocalizedText(deviceEntity.GetDisplayName());
    mss.RemoveMarkAny(deviceEntity.GetEntityID());
    BNInfo("NetworkScan", "Device unmarked: " + displayName);

    let logSys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
    if IsDefined(logSys) { logSys.Refresh(); }
  }
}

@wrapMethod(ScriptableDeviceComponentPS)
public final func GetRemoteActions(out outActions: array<ref<DeviceAction>>, const context: script_ref<GetActionsContext>) -> Void {
  wrappedMethod(outActions, context);

  BNDebug("NetworkScan", "GetRemoteActions: entered for " + NameToString(this.GetClassName()));

  if IsDefined(this as AccessPointControllerPS) {
    BNDebug("NetworkScan", "GetRemoteActions: skipped — is AccessPointControllerPS");
    return;
  }

  let gi: GameInstance = this.GetGameInstance();

  let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
    .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if !IsDefined(mss) {
    BNWarn("NetworkScan", "GetRemoteActions: MarkingStateSystem not found");
    return;
  }

  let deviceEntity: wref<GameObject> = this.GetOwnerEntityWeak() as GameObject;
  if !IsDefined(deviceEntity) {
    BNWarn("NetworkScan", "GetRemoteActions: no owner entity");
    return;
  }

  let subnetType: MarkedSubnetType;
  if DaemonFilterUtils.IsCamera(this) {
    subnetType = MarkedSubnetType.Camera;
  } else if DaemonFilterUtils.IsTurret(this) {
    subnetType = MarkedSubnetType.Defense;
  } else {
    subnetType = MarkedSubnetType.Root;
  }

  let ramCost: Int32 = 2;
  let isMarked: Bool = mss.IsMark(deviceEntity.GetEntityID(), subnetType);
  let player: ref<PlayerPuppet> = GetPlayer(gi);

  BNDebug("NetworkScan", "GetRemoteActions: injecting " + (isMarked ? "Unmark" : "Mark") + " for " + GetLocalizedText(deviceEntity.GetDisplayName()));

  if isMarked {
    let action: ref<BNUnmarkDeviceAction> = new BNUnmarkDeviceAction();
    action.SetUp(this);
    action.SetDevicePS(this, ramCost);
    action.AddDeviceName(this.m_deviceName);
    action.CreateInteraction();
    if IsDefined(player) { action.SetExecutor(player); }
    if !action.CanPayCost(player, false) {
      action.SetInactiveWithReason(false, BNConstants.LOCKEY_RAM_INSUFFICIENT());
    }
    ArrayPush(outActions, action);
    BNDebug("NetworkScan", "GetRemoteActions: pushed BNUnmarkDeviceAction, outActions size=" + ToString(ArraySize(outActions)));
  } else {
    let action: ref<BNMarkDeviceAction> = new BNMarkDeviceAction();
    action.SetUp(this);
    action.SetDevicePS(this, ramCost);
    action.AddDeviceName(this.m_deviceName);
    action.CreateInteraction();
    if IsDefined(player) { action.SetExecutor(player); }
    if !action.CanPayCost(player, false) {
      action.SetInactiveWithReason(false, BNConstants.LOCKEY_RAM_INSUFFICIENT());
    }
    ArrayPush(outActions, action);
    BNDebug("NetworkScan", "GetRemoteActions: pushed BNMarkDeviceAction, outActions size=" + ToString(ArraySize(outActions)));
  }
}

@addField(PlayerPuppet)
public let m_bnInjectMarkHacks: Bool;

@wrapMethod(QuickHackableHelper)
public final static func TranslateActionsIntoQuickSlotCommands(const actions: array<ref<DeviceAction>>, commands: script_ref<array<ref<QuickhackData>>>, gameObject: ref<GameObject>, scriptableComponentPS: ref<ScriptableDeviceComponentPS>) -> Void {
  let player: ref<PlayerPuppet> = GetPlayer(gameObject.GetGame());
  BNDebug("NetworkScan", "TranslateActionsIntoQuickSlotCommands: entered, incoming actions=" + ToString(ArraySize(actions)) + " playerDefined=" + ToString(IsDefined(player)));
  if IsDefined(player) { player.m_bnInjectMarkHacks = true; }
  wrappedMethod(actions, commands, gameObject, scriptableComponentPS);
  if IsDefined(player) { player.m_bnInjectMarkHacks = false; }
  BNDebug("NetworkScan", "TranslateActionsIntoQuickSlotCommands: finished, commands=" + ToString(ArraySize(Deref(commands))));
}

@wrapMethod(RPGManager)
public final static func GetPlayerQuickHackListWithQuality(player: wref<PlayerPuppet>) -> array<PlayerQuickhackData> {
  let list: array<PlayerQuickhackData> = wrappedMethod(player);
  if !IsDefined(player) || !player.m_bnInjectMarkHacks { return list; }

  BNDebug("NetworkScan", "GetPlayerQuickHackListWithQuality: flag set, injecting BNMarkDevice/BNUnmarkDevice records");

  let ids: array<TweakDBID>;
  ArrayPush(ids, t"QuickHack.BNMarkDevice");
  ArrayPush(ids, t"QuickHack.BNUnmarkDevice");

  let i: Int32 = 0;
  while i < ArraySize(ids) {
    let record: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(ids[i]);
    let present: Bool = false;
    let j: Int32 = 0;
    while j < ArraySize(list) {
      if Equals(list[j].actionRecord.GetID(), ids[i]) { present = true; }
      j += 1;
    }
    if !IsDefined(record) {
      BNWarn("NetworkScan", "GetPlayerQuickHackListWithQuality: record not found for " + TDBID.ToStringDEBUG(ids[i]));
    } else if !present {
      ArrayPush(list, new PlayerQuickhackData(ItemID.None(), record, 5));
      BNDebug("NetworkScan", "GetPlayerQuickHackListWithQuality: injected " + TDBID.ToStringDEBUG(ids[i]));
    }
    i += 1;
  }
  return list;
}
