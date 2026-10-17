
module BetterNetrunning.Marking

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Perks.*
import BetterNetrunning.Network.*
import BetterNetrunning.Utils.*

@addMethod(ScriptedPuppetPS)
public func BN_IsRawQuickHacksExposed() -> Bool {
  return this.m_quickHacksExposed;
}

public class BNRemoteBreachSystem extends ScriptableSystem {
  private let m_isActive:      Bool;
  private let m_targetNPC:     ref<ScriptedPuppetPS>;
  private let m_targetDevice:  ref<ScriptableDeviceComponentPS>;
  private let m_activeListener: ref<BNHackResultListener>;

  public static func GetInstance(gi: GameInstance) -> ref<BNRemoteBreachSystem> {
    return GameInstance.GetScriptableSystemsContainer(gi)
      .Get(n"BetterNetrunning.Marking.BNRemoteBreachSystem") as BNRemoteBreachSystem;
  }

  private func OnAttach() -> Void {
    this.m_isActive = false;
  }

  public func IsActive() -> Bool {
    return this.m_isActive;
  }

  public func OnOutcomeFinished() -> Void {
    this.m_isActive       = false;
    this.m_activeListener = null;
    this.m_targetNPC      = null;
    this.m_targetDevice   = null;
  }

  public func LaunchOnNPC(gi: GameInstance, player: ref<PlayerPuppet>, npcPS: ref<ScriptedPuppetPS>) -> Bool {
    if this.m_isActive { return false; }

    let successCB: ref<BNRemoteBreachSucceededEvent> = new BNRemoteBreachSucceededEvent();
    let failCB: ref<BNRemoteBreachFailedEvent> = new BNRemoteBreachFailedEvent();
    this.m_activeListener = new BNHackResultListener();
    this.m_activeListener.successCB = successCB;
    this.m_activeListener.failCB    = failCB;
    this.m_activeListener.Arm(gi);

    let npcEntity: wref<Entity> = npcPS.GetOwnerEntityWeak() as Entity;
    let board: TweakDBID = BNPerkData.GetRemoteBreachICEBoard(gi);
    let launched: Bool = BNNativeBreachLauncher.Launch(gi, player, board, "Remote Breach", npcEntity);
    if !launched {
      BNWarn("RemoteBreach", "LaunchOnNPC: BNNativeBreachLauncher.Launch failed");
      this.m_activeListener = null;
      return false;
    }

    this.m_targetNPC = npcPS;
    this.m_isActive  = true;
    BNInfo("RemoteBreach", "Remote Breach ICE board opened on NPC — " + TDBID.ToStringDEBUG(board));
    return true;
  }

  public func LaunchOnDevice(gi: GameInstance, player: ref<PlayerPuppet>, devicePS: ref<ScriptableDeviceComponentPS>) -> Bool {
    if this.m_isActive { return false; }

    let successCB: ref<BNRemoteBreachSucceededEvent> = new BNRemoteBreachSucceededEvent();
    let failCB: ref<BNRemoteBreachFailedEvent> = new BNRemoteBreachFailedEvent();
    this.m_activeListener = new BNHackResultListener();
    this.m_activeListener.successCB = successCB;
    this.m_activeListener.failCB    = failCB;
    this.m_activeListener.Arm(gi);

    let deviceEntity: wref<Entity> = devicePS.GetOwnerEntityWeak() as Entity;
    let board: TweakDBID = BNPerkData.GetRemoteBreachICEBoard(gi);
    let launched: Bool = BNNativeBreachLauncher.Launch(gi, player, board, "Remote Breach", deviceEntity);
    if !launched {
      BNWarn("RemoteBreach", "LaunchOnDevice: BNNativeBreachLauncher.Launch failed");
      this.m_activeListener = null;
      return false;
    }

    this.m_targetDevice = devicePS;
    this.m_isActive     = true;
    BNInfo("RemoteBreach", "Remote Breach ICE board opened on device — " + TDBID.ToStringDEBUG(board));
    return true;
  }

  public func GetTargetNPC() -> ref<ScriptedPuppetPS> { return this.m_targetNPC; }
  public func GetTargetDevice() -> ref<ScriptableDeviceComponentPS> { return this.m_targetDevice; }
}

public class BNRemoteBreachSucceededEvent extends BNHackResultCallback {
  public func Execute() -> Void {
    let gi: GameInstance = this.gameInstance;
    let sys: ref<BNRemoteBreachSystem> = BNRemoteBreachSystem.GetInstance(gi);
    if !IsDefined(sys) { return; }

    let minigameBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().HackingMinigame);
    let activePrograms: array<TweakDBID> = FromVariant<array<TweakDBID>>(
      minigameBB.GetVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms));

    let npcPS: ref<ScriptedPuppetPS> = sys.GetTargetNPC();
    let devicePS: ref<ScriptableDeviceComponentPS> = sys.GetTargetDevice();

    if IsDefined(devicePS) {
      NetworkStateUtils.OnDaemonsCompleted(activePrograms, devicePS, gi);
      BNInfo("RemoteBreach", "ICE board succeeded on device");

      if devicePS.m_bnIceDefeated && !devicePS.IsBreached() {
        let deviceWeak: wref<GameObject> = devicePS.GetOwnerEntityWeak() as GameObject;
        let deviceEntity: ref<Device> = IsDefined(deviceWeak)
          ? GameInstance.FindEntityByID(gi, deviceWeak.GetEntityID()) as Device
          : null;
        if IsDefined(deviceEntity) {
          let targetType: TargetType = DaemonFilterUtils.IsCamera(devicePS)
            ? TargetType.Camera
            : (DaemonFilterUtils.IsTurret(devicePS) ? TargetType.Turret : TargetType.Basic);
          let persistency: ref<GamePersistencySystem> = GameInstance.GetPersistencySystem(gi);
          TargetedBreachUtils.UnlockDevice(deviceEntity, targetType, TimeUtils.GetCurrentTimestamp(gi), persistency);
          BNInfo("RemoteBreach", "ICE fully broken — device auto-unlocked");
        }
      }
    } else if IsDefined(npcPS) {
      let ms: ref<MarkingStateSystem> = NetworkStateUtils.GetMarkingSystem(gi);
      let i: Int32 = 0;
      while i < ArraySize(activePrograms) {
        let pid: TweakDBID = activePrograms[i];
        if Equals(pid, BNConstants.PROGRAM_BN_ICEPICK_V1()) {
          NetworkStateUtils.ApplyIcepickEffectNPC(npcPS, gi, 2 + RandRange(0, 4));
          if IsDefined(ms) { ms.AddSessionHeat(0.2); }
        } else if Equals(pid, BNConstants.PROGRAM_BN_ICEPICK_V2()) {
          if IsDefined(ms) { ms.AddSessionHeat(-0.5); }
        } else if Equals(pid, BNConstants.PROGRAM_BN_ICEPICK_V3()) {
          NetworkStateUtils.ApplyIcepickEffectNPC(npcPS, gi, 5 + RandRange(0, 4));
        }
        i += 1;
      }
      BNInfo("RemoteBreach", "ICE board succeeded on NPC");

      if npcPS.m_bnNPCIceDefeated && !npcPS.BN_IsRawQuickHacksExposed() {
        let npcWeak: wref<GameObject> = npcPS.GetOwnerEntityWeak() as GameObject;
        let npcEntity: ref<ScriptedPuppet> = IsDefined(npcWeak)
          ? GameInstance.FindEntityByID(gi, npcWeak.GetEntityID()) as ScriptedPuppet
          : null;
        if IsDefined(npcEntity) {
          let persistency: ref<GamePersistencySystem> = GameInstance.GetPersistencySystem(gi);
          TargetedBreachUtils.UnlockNPC(npcEntity, TimeUtils.GetCurrentTimestamp(gi), persistency, npcEntity.GetEntityID());
          BNInfo("RemoteBreach", "ICE fully broken — NPC auto-unlocked");
        }
      }
    }

    sys.OnOutcomeFinished();
  }
}

public class BNRemoteBreachFailedEvent extends BNHackResultCallback {
  public func Execute() -> Void {
    let sys: ref<BNRemoteBreachSystem> = BNRemoteBreachSystem.GetInstance(this.gameInstance);
    if !IsDefined(sys) { return; }
    BNInfo("RemoteBreach", "ICE board failed/abandoned — no ICE damage applied");
    sys.OnOutcomeFinished();
  }
}

public class BNRemoteBreachNPCAction extends PuppetAction {
  private let m_npcPS:   ref<ScriptedPuppetPS>;
  private let m_ramCost: Int32;

  public func SetNPC(npcPS: ref<ScriptedPuppetPS>, ramCost: Int32) -> Void {
    this.m_npcPS   = npcPS;
    this.m_ramCost = ramCost;
  }

  public func GetTweakDBChoiceRecord() -> String { return "BNRemoteBreach"; }
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
      BNError("RemoteBreach", "BNRemoteBreachNPCAction: no NPC PS");
      return;
    }

    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
    if IsDefined(player) && this.m_ramCost > 0 {
      let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gameInstance);
      let playerID: StatsObjectID   = Cast<StatsObjectID>(player.GetEntityID());
      let currentRAM: Float         = pool.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
      pool.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory,
        currentRAM - Cast<Float>(this.m_ramCost), player, false);
    }

    let sys: ref<BNRemoteBreachSystem> = BNRemoteBreachSystem.GetInstance(gameInstance);
    if !IsDefined(sys) || !IsDefined(player) {
      BNError("RemoteBreach", "BNRemoteBreachNPCAction: system or player not available");
      return;
    }
    if !sys.LaunchOnNPC(gameInstance, player, this.m_npcPS) {
      BNWarn("RemoteBreach", "Remote Breach failed to launch on NPC — board may already be active");
    }
  }
}

public class BNRemoteBreachDeviceAction extends PuppetAction {
  private let m_devicePS: ref<ScriptableDeviceComponentPS>;
  private let m_ramCost:  Int32;

  public func SetDevicePS(devicePS: ref<ScriptableDeviceComponentPS>, ramCost: Int32) -> Void {
    this.m_devicePS = devicePS;
    this.m_ramCost  = ramCost;
    this.SetObjectActionID(t"QuickHack.BNRemoteBreachDevice");
  }

  public func GetTweakDBChoiceRecord() -> String { return "BNRemoteBreach"; }
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
      BNError("RemoteBreach", "BNRemoteBreachDeviceAction: no device PS");
      return;
    }

    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
    if IsDefined(player) && this.m_ramCost > 0 {
      let pool: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gameInstance);
      let playerID: StatsObjectID   = Cast<StatsObjectID>(player.GetEntityID());
      let currentRAM: Float         = pool.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
      pool.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory,
        currentRAM - Cast<Float>(this.m_ramCost), player, false);
    }

    let sys: ref<BNRemoteBreachSystem> = BNRemoteBreachSystem.GetInstance(gameInstance);
    if !IsDefined(sys) || !IsDefined(player) {
      BNError("RemoteBreach", "BNRemoteBreachDeviceAction: system or player not available");
      return;
    }
    if !sys.LaunchOnDevice(gameInstance, player, this.m_devicePS) {
      BNWarn("RemoteBreach", "Remote Breach failed to launch on device — board may already be active");
    }
  }
}

@wrapMethod(ScriptedPuppet)
private final func TranslateChoicesIntoQuickSlotCommands(
  const puppetActions: script_ref<array<ref<PuppetAction>>>,
  commands:            script_ref<array<ref<QuickhackData>>>
) -> Void {
  wrappedMethod(puppetActions, commands);

  if this.IsDead() { return; }

  let perkSys: ref<BNPerkSystem> = BNPerkSystem.GetInstance(this.GetGame());
  if !IsDefined(perkSys) || perkSys.GetPerkLevel(BNPerk.IntrusionSuite) <= 0 { return; }

  let npcPS: ref<ScriptedPuppetPS> = this.GetPS() as ScriptedPuppetPS;
  if !IsDefined(npcPS) { return; }

  if npcPS.m_bnNPCIceDefeated || npcPS.BN_IsRawQuickHacksExposed() { return; }

  let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
  if !IsDefined(player) { return; }

  let ramCost: Int32 = 6;

  let action: ref<BNRemoteBreachNPCAction> = new BNRemoteBreachNPCAction();
  action.SetNPC(npcPS, ramCost);
  action.SetExecutor(player);

  let rec: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(t"QuickHack.BNRemoteBreach");

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
  entry.m_title        = LocKeyToString(rec.ObjectActionUI().Caption());
  entry.m_description  = LocKeyToString(rec.ObjectActionUI().Description());
  entry.m_icon         = rec.ObjectActionUI().CaptionIcon().TexturePartID().GetID();
  entry.m_iconCategory = rec.GameplayCategory().IconName();
  entry.m_category     = rec.HackCategory();
  entry.m_type         = rec.ObjectActionType().Type();

  if action.CanPayCost(player, false) {
    entry.m_action      = action;
    entry.m_actionState = EActionInactivityReson.Ready;
    entry.m_isLocked     = false;
  } else {
    entry.m_isLocked       = true;
    entry.m_inactiveReason = BNConstants.LOCKEY_RAM_INSUFFICIENT();
    entry.m_actionState    = EActionInactivityReson.OutOfMemory;
  }

  ArrayPush(Deref(commands), entry);
}

@wrapMethod(ScriptableDeviceComponentPS)
public final func GetRemoteActions(out outActions: array<ref<DeviceAction>>, const context: script_ref<GetActionsContext>) -> Void {
  wrappedMethod(outActions, context);

  if IsDefined(this as AccessPointControllerPS) { return; }

  let gi: GameInstance = this.GetGameInstance();

  let perkSys: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gi);
  if !IsDefined(perkSys) || perkSys.GetPerkLevel(BNPerk.IntrusionSuite) <= 0 { return; }

  if this.m_bnIceDefeated || this.IsBreached() { return; }

  let player: ref<PlayerPuppet> = GetPlayer(gi);
  if !IsDefined(player) { return; }

  let ramCost: Int32 = 6;

  let action: ref<BNRemoteBreachDeviceAction> = new BNRemoteBreachDeviceAction();
  action.SetUp(this);
  action.SetDevicePS(this, ramCost);
  action.AddDeviceName(this.m_deviceName);
  action.CreateInteraction();
  action.SetExecutor(player);
  if !action.CanPayCost(player, false) {
    action.SetInactiveWithReason(false, BNConstants.LOCKEY_RAM_INSUFFICIENT());
  }
  ArrayPush(outActions, action);
}

@wrapMethod(RPGManager)
public final static func GetPlayerQuickHackListWithQuality(player: wref<PlayerPuppet>) -> array<PlayerQuickhackData> {
  let list: array<PlayerQuickhackData> = wrappedMethod(player);
  if !IsDefined(player) || !player.m_bnInjectMarkHacks { return list; }

  let id: TweakDBID = t"QuickHack.BNRemoteBreachDevice";
  let record: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(id);
  if !IsDefined(record) { return list; }

  let present: Bool = false;
  let j: Int32 = 0;
  while j < ArraySize(list) {
    if Equals(list[j].actionRecord.GetID(), id) { present = true; }
    j += 1;
  }
  if !present {
    ArrayPush(list, new PlayerQuickhackData(ItemID.None(), record, 5));
  }
  return list;
}
