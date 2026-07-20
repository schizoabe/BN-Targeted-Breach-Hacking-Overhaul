module BetterNetrunning.Breach

import BetterNetrunning.Logging.*
import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Breach.*
import BetterNetrunning.Marking.*
import BetterNetrunning.Perks.*

@addMethod(AccessPointControllerPS)
public func GetMainframe() -> ref<AccessPointControllerPS> {
  let parents: array<ref<DeviceComponentPS>>;
  this.GetParents(parents);
  let i: Int32 = 0;
  while i < ArraySize(parents) {
    if IsDefined(parents[i] as AccessPointControllerPS) {
      return (parents[i] as AccessPointControllerPS).GetMainframe();
    };
    i += 1;
  };
  return this;
}

@replaceMethod(AccessPointControllerPS)
public final const func CheckConnectedClassTypes() -> ConnectedClassTypes {
  let data: ConnectedClassTypes;
  let slaves: array<ref<DeviceComponentPS>> = this.GetImmediateSlaves();

  let i: Int32 = 0;
  while i < ArraySize(slaves) {

    if data.surveillanceCamera && data.securityTurret && data.puppet {
      break;
    }

    this.UpdateDeviceTypeData(slaves[i], data);
    i += 1;
  }

  return data;
}

@addMethod(AccessPointControllerPS)
private final func UpdateDeviceTypeData(slave: ref<DeviceComponentPS>, out data: ConnectedClassTypes) -> Void {

  let slavePS: ref<ScriptableDeviceComponentPS> = slave as ScriptableDeviceComponentPS;
  if IsDefined(slavePS) {
    if !data.surveillanceCamera && DaemonFilterUtils.IsCamera(slavePS) {
      data.surveillanceCamera = true;
      return;
    }
    if !data.securityTurret && DaemonFilterUtils.IsTurret(slavePS) {
      data.securityTurret = true;
      return;
    }
  }

  if data.puppet {
    return;  // Already found
  }

  let puppetLink: ref<PuppetDeviceLinkPS> = slave as PuppetDeviceLinkPS;
  if !IsDefined(puppetLink) {
    return;
  }

  let puppet: ref<GameObject> = puppetLink.GetOwnerEntityWeak() as GameObject;
  if IsDefined(puppet) && puppet.IsActive() {
    data.puppet = true;
  }
}

@replaceMethod(ScriptedPuppet)
protected cb func OnAccessPointMiniGameStatus(evt: ref<AccessPointMiniGameStatus>) -> Bool {
  let deviceLink: ref<PuppetDeviceLinkPS> = this.GetDeviceLink();
  if IsDefined(deviceLink) {
    deviceLink.PerformNPCBreach(evt.minigameState);
  }

  let gi: GameInstance = this.GetGame();

  if this.IsIncapacitated() {
    if Equals(evt.minigameState, HackingMinigameState.Succeeded) {
      this.HandleUnconsciousBreachSuccess(gi);
    }

    let player: ref<PlayerPuppet> = GetPlayer(gi);
    if IsDefined(player) {
      let ntPerkSys: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gi);
      let ntLevel: Int32 = IsDefined(ntPerkSys) ? ntPerkSys.GetPerkLevel(BNPerk.NeuralTap) : -1;
      BNInfo("UnconsciousBreach", s"Neural Tap level check: \(ntLevel)");
      if !IsDefined(ntPerkSys) || ntLevel < 2 {
        StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.BrainMeltQuestForceKill", player.GetEntityID());
        BNInfo("UnconsciousBreach", "Neural Tap r1 — Synapse Burnout applied");
      } else {
        BNInfo("UnconsciousBreach", "Neural Tap r2 — unconscious NPC spared");
      }
    }
  }

  if Equals(evt.minigameState, HackingMinigameState.Failed) && ShouldApplyBreachPenalty(BreachType.UnconsciousNPC) {
    let player: ref<PlayerPuppet> = GetPlayer(gi);
    if IsDefined(player) && IsDefined(this) {
      ApplyFailurePenalty(player, this, gi);
      BNInfo("UnconsciousBreach", "Breach failed — penalty applied");
    }
  }

  this.ClearNetworkBlackboardState();
  this.RestoreTimeDilation();
  QuickhackModule.RequestRefreshQuickhackMenu(gi, this.GetEntityID());
}

@addMethod(ScriptedPuppet)
private final func HandleUnconsciousBreachSuccess(gi: GameInstance) -> Void {
  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gi);
  let markingSystem: ref<MarkingStateSystem> =
    container.Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;

  let minigameBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi)
    .Get(GetAllBlackboardDefs().HackingMinigame);
  let activePrograms: array<TweakDBID> = FromVariant<array<TweakDBID>>(
    minigameBB.GetVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms));

  let unlockFlags: BreachUnlockFlags = DaemonFilterUtils.ExtractUnlockFlags(activePrograms);

  let k: Int32 = 0;
  while k < ArraySize(activePrograms) {
    let pid: TweakDBID = activePrograms[k];
    if pid == BNConstants.PROGRAM_BN_ICEPICK_V2() {
      if IsDefined(markingSystem) { markingSystem.AddSessionHeat(-0.10); }
      BNInfo("UnconsciousBreach", "Purge completed — heat -0.10");
    } else if pid == BNConstants.PROGRAM_SIGNAL_NOISE() {
      if IsDefined(markingSystem) { markingSystem.SetSignalNoiseTimer(60.0); }
      BNInfo("UnconsciousBreach", "Signal Noise — per-mark heat tick halved for 60s");
    }
    k += 1;
  }

  if IsDefined(markingSystem) && markingSystem.HasAnyMarked() {
    TargetedBreachUtils.UnlockMarkedEntities(markingSystem, unlockFlags, gi);
    BNInfo("UnconsciousBreach", "Propagated to marked targets — Basic="
      + ToString(unlockFlags.unlockBasic) + " Cameras=" + ToString(unlockFlags.unlockCameras)
      + " Turrets=" + ToString(unlockFlags.unlockTurrets));
  } else {
    BNInfo("UnconsciousBreach", "No marks — nothing propagated");
  }

  if IsDefined(markingSystem) {
    let raw: String = GetLocalizedText(this.GetDisplayName());
    let npcName: String = NotEquals(raw, s"") ? raw : "OPERATIVE";
    markingSystem.RecordRemoteBreachTarget(npcName, "personnel");
    markingSystem.RecordBreachICEState(1, 1);
    markingSystem.ShowRemoteBreachStatus();
  }

  RPGManager.GiveReward(gi, t"RPGActionRewards.Hacking", Cast<StatsObjectID>(this.GetEntityID()));
}

@addMethod(ScriptedPuppet)
private final func ClearNetworkBlackboardState() -> Void {
  let emptyID: EntityID;
  this.GetNetworkBlackboard().SetString(this.GetNetworkBlackboardDef().NetworkName, "");
  this.GetNetworkBlackboard().SetEntityID(this.GetNetworkBlackboardDef().DeviceID, emptyID);
}

@addMethod(ScriptedPuppet)
private final func RestoreTimeDilation() -> Void {
  let easeOutCurve: CName = TweakDBInterface.GetCName(t"timeSystem.nanoWireBreach.easeOutCurve", n"DiveEaseOut");
  GameInstance.GetTimeSystem(this.GetGame()).UnsetTimeDilation(n"NetworkBreach", easeOutCurve);
}

