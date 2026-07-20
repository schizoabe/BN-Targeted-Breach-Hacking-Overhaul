












module BetterNetrunning.Integration

import BetterNetrunning.Marking.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Network.*

@addMethod(ScriptableDeviceComponentPS)
public func BN_SJKIHandleSuccess(gi: GameInstance) -> Void {

  let minigameBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi)
    .Get(GetAllBlackboardDefs().HackingMinigame);

  let activePrograms: array<TweakDBID> = FromVariant<array<TweakDBID>>(
    minigameBB.GetVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms));

  BNInfo("SJKIIntegration", "BN_SJKIHandleSuccess — ActivePrograms count="
    + ToString(ArraySize(activePrograms)));



  NetworkStateUtils.OnDaemonsCompleted(activePrograms, this, gi);




  let iceState: NetworkState = NetworkStateUtils.GetNetworkState(this, gi);

  let unlockFlags: BreachUnlockFlags = DaemonFilterUtils.ExtractUnlockFlags(activePrograms);



  let noSubnetDaemons: Bool = !unlockFlags.unlockBasic && !unlockFlags.unlockNPCs
      && !unlockFlags.unlockCameras && !unlockFlags.unlockTurrets;
  if noSubnetDaemons && NetworkStateUtils.IsSubnetAccessible(NetworkStateUtils.GetNetworkState(this, gi)) {
      let isCamera: Bool = DeviceTypeUtils.IsCameraDevice(this);
      let isTurret: Bool = DeviceTypeUtils.IsTurretDevice(this);
      DeviceUnlockUtils.ApplyTimestampUnlock(this, gi, !isCamera && !isTurret, false, isCamera, isTurret);
      BNInfo("SJKIIntegration", "ICE fully broken — auto-exposing device quickhacks");
  }

  BNInfo("SJKIIntegration", "unlockFlags Basic=" + ToString(unlockFlags.unlockBasic)
    + " NPC=" + ToString(unlockFlags.unlockNPCs)
    + " Camera=" + ToString(unlockFlags.unlockCameras)
    + " Turret=" + ToString(unlockFlags.unlockTurrets));


  let markingSystem: ref<MarkingStateSystem> =
    GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;

  BNInfo("SJKIIntegration", "MarkingSystem defined=" + ToString(IsDefined(markingSystem))
    + " hasMarks=" + ToString(IsDefined(markingSystem) && markingSystem.HasAnyMarked()));

  if !IsDefined(markingSystem) || !markingSystem.HasAnyMarked() {
    BNInfo("SJKIIntegration", "No marks — propagation skipped");



    if IsDefined(markingSystem) {
      let deviceName: String = "DEVICE";
      let owner: wref<GameObject> = this.GetOwnerEntityWeak() as GameObject;
      if IsDefined(owner) {
        let raw: String = GetLocalizedText(owner.GetDisplayName());
        if NotEquals(raw, s"") { deviceName = raw; }
      }
      let targetType: String = "device";
      if unlockFlags.unlockNPCs     { targetType = "personnel"; }
      else if unlockFlags.unlockCameras { targetType = "camera"; }
      else if unlockFlags.unlockTurrets { targetType = "turret"; }
      markingSystem.RecordRemoteBreachTarget(deviceName, targetType);
      markingSystem.RecordBreachICEState(iceState.hitsRequired, iceState.hitsApplied);
      markingSystem.ShowRemoteBreachStatus();
    }
    return;
  }


  let markedCount: Int32 = markingSystem.GetTotalCount();
  let player: ref<PlayerPuppet> = GetPlayer(gi);
  if IsDefined(player) && markedCount > 0 {
    let poolSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gi);
    let playerID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
    let curRAM: Float = poolSystem.GetStatPoolValue(
      playerID, gamedataStatPoolType.Memory, false);
    poolSystem.RequestSettingStatPoolValue(
      playerID, gamedataStatPoolType.Memory,
      MaxF(0.0, curRAM - Cast<Float>(markedCount)),
      player, false);
    BNInfo("SJKIIntegration", "RAM cost: -" + ToString(markedCount));
  }


  TargetedBreachUtils.UnlockMarkedEntities(markingSystem, unlockFlags, gi);
  BNInfo("SJKIIntegration", "Targeted unlock complete");


  let ms: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
    .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
  if IsDefined(ms) {
    let deviceName: String = "DEVICE";
    let owner: wref<GameObject> = this.GetOwnerEntityWeak() as GameObject;
    if IsDefined(owner) {
      let raw: String = GetLocalizedText(owner.GetDisplayName());
      if NotEquals(raw, s"") { deviceName = raw; }
    }
    let targetType: String = "device";
    if unlockFlags.unlockNPCs     { targetType = "personnel"; }
    else if unlockFlags.unlockCameras { targetType = "camera"; }
    else if unlockFlags.unlockTurrets { targetType = "turret"; }
    ms.RecordRemoteBreachTarget(deviceName, targetType);
    ms.RecordBreachICEState(1, 1);
    ms.ShowRemoteBreachStatus();
  }
}

