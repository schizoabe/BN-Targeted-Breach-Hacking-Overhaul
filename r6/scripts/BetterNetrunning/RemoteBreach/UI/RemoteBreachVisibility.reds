

@addMethod(ScriptableDeviceComponentPS)
public final func IsDeviceAlreadyUnlocked() -> Bool {
  let sharedPS: ref<SharedGameplayPS> = this;
  if !IsDefined(sharedPS) {
    return false;
  }

  if IsDefined(this as VehicleComponentPS) {
    return BreachStatusUtils.IsBasicBreached(sharedPS);
  }

  if DaemonFilterUtils.IsCamera(this) {
    return BreachStatusUtils.IsCamerasBreached(sharedPS);
  }

  if DaemonFilterUtils.IsTurret(this) {
    return BreachStatusUtils.IsTurretsBreached(sharedPS);
  }

  if BreachStatusUtils.IsBasicBreached(sharedPS) {
    return true;
  }

  let deviceEntity: wref<GameObject> = this.GetOwnerEntityWeak() as GameObject;
  if IsDefined(deviceEntity) {
    let stateSystem: ref<DeviceRemoteBreachStateSystem> =
      GameInstance.GetScriptableSystemsContainer(this.GetGameInstance())
        .Get(BNConstants.CLASS_DEVICE_REMOTE_BREACH_STATE_SYSTEM()) as DeviceRemoteBreachStateSystem;

    if IsDefined(stateSystem) {
      return stateSystem.IsDeviceBreached(deviceEntity.GetEntityID());
    }
  }

  return false;
}

@if(ModuleExists("HackingExtensions"))
@addMethod(ScriptableDeviceComponentPS)
public final func TryAddCustomRemoteBreach(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {

  if IsDefined(this as AccessPointControllerPS) { return; }

  if this.IsDeviceAlreadyUnlocked() {
    return;
  }

  if BreachLockUtils.IsDeviceLockedByRemoteBreachFailure(this) {
    return;
  }

  let gi: GameInstance = this.GetGameInstance();
  if GameInstance.IsValid(gi) {
    let perkSys: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gi);
    if !IsDefined(perkSys) || perkSys.GetPerkLevel(BNPerk.IntrusionSuite) <= 0 {
      return;
    }
  }

  let hasCustomRemoteBreach: Bool = false;
  let i: Int32 = 0;
  while i < ArraySize(Deref(outActions)) {
    let action: ref<DeviceAction> = Deref(outActions)[i];
    if IsCustomRemoteBreachAction(action) {
      hasCustomRemoteBreach = true;
      break;
    }
    i += 1;
  }

  if !hasCustomRemoteBreach {
    let isCamera: Bool = DeviceTypeUtils.IsCameraDevice(this);
    let isTurret: Bool = DeviceTypeUtils.IsTurretDevice(this);
    let isComputer: Bool = IsDefined(this as ComputerControllerPS);
    let isVehicle: Bool = IsDefined(this as VehicleComponentPS);

    if isCamera { if !BetterNetrunningSettings.RemoteBreachEnabledCamera() { return; } }
    else if isTurret { if !BetterNetrunningSettings.RemoteBreachEnabledTurret() { return; } }
    else if isComputer { if !BetterNetrunningSettings.RemoteBreachEnabledComputer() { return; } }
    else if isVehicle { if !BetterNetrunningSettings.RemoteBreachEnabledVehicle() { return; } }
    else { if !BetterNetrunningSettings.RemoteBreachEnabledDevice() { return; } }

    let breachAction: ref<DeviceRemoteBreachAction> = this.ActionCustomDeviceRemoteBreach();
    ArrayPush(Deref(outActions), breachAction);
  }
}

@if(ModuleExists("HackingExtensions"))
@addMethod(ScriptableDeviceComponentPS)
public final func TryAddMissingCustomRemoteBreach(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {

  if IsDefined(this as AccessPointControllerPS) { return; }

  if this.IsDeviceAlreadyUnlocked() {
    return;
  }

  if BreachLockUtils.IsDeviceLockedByRemoteBreachFailure(this) {

    let i: Int32 = ArraySize(Deref(outActions)) - 1;
    while i >= 0 {
      let action: ref<DeviceAction> = Deref(outActions)[i];
      let className: CName = action.GetClassName();
      if IsCustomRemoteBreachAction(className) || IsDefined(action as RemoteBreach) {
        ArrayErase(Deref(outActions), i);
      }
      i -= 1;
    }
    return;  // Don't show minigame entry when unlocked
  }

  let gi2: GameInstance = this.GetGameInstance();
  if GameInstance.IsValid(gi2) {
    let perkSys2: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gi2);
    if !IsDefined(perkSys2) || perkSys2.GetPerkLevel(BNPerk.IntrusionSuite) <= 0 {
      return;
    }
  }

  let isCamera: Bool = DeviceTypeUtils.IsCameraDevice(this);
  let isTurret: Bool = DeviceTypeUtils.IsTurretDevice(this);
  let isComputer: Bool = IsDefined(this as ComputerControllerPS);
  let isVehicle: Bool = IsDefined(this as VehicleComponentPS);

  if isCamera { if !BetterNetrunningSettings.RemoteBreachEnabledCamera() { return; } }
  else if isTurret { if !BetterNetrunningSettings.RemoteBreachEnabledTurret() { return; } }
  else if isComputer { if !BetterNetrunningSettings.RemoteBreachEnabledComputer() { return; } }
  else if isVehicle { if !BetterNetrunningSettings.RemoteBreachEnabledVehicle() { return; } }
  else { if !BetterNetrunningSettings.RemoteBreachEnabledDevice() { return; } }

  let breachAction: ref<DeviceRemoteBreachAction> = this.ActionCustomDeviceRemoteBreach();
  ArrayPush(Deref(outActions), breachAction);
}

@addMethod(ScriptableDeviceComponentPS)
public final func RemoveCustomRemoteBreachIfUnlocked(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {

  let expirationResult: UnlockExpirationResult = UnlockExpirationUtils.CheckUnlockExpiration(this);

  if expirationResult.wasExpired {
    DeviceInteractionUtils.EnableJackInInteractionForAccessPoint(this);
  }

  let isUnlocked: Bool = expirationResult.isUnlocked;
  if !isUnlocked && !expirationResult.wasExpired && !DaemonFilterUtils.IsCamera(this) && !DaemonFilterUtils.IsTurret(this) && !IsDefined(this as VehicleComponentPS) {
    isUnlocked = this.IsBasicDeviceBreachedByCustomHackingSystem();
  }

  if isUnlocked {
    this.RemoveCustomRemoteBreachAction(outActions);
  }
}

@addMethod(ScriptableDeviceComponentPS)
private final func IsBasicDeviceBreachedByCustomHackingSystem() -> Bool {
  let deviceEntity: wref<GameObject> = this.GetOwnerEntityWeak() as GameObject;
  if !IsDefined(deviceEntity) { return false; }

  let deviceID: EntityID = deviceEntity.GetEntityID();
  let stateSystem: ref<DeviceRemoteBreachStateSystem> =
    GameInstance.GetScriptableSystemsContainer(this.GetGameInstance()).Get(BNConstants.CLASS_DEVICE_REMOTE_BREACH_STATE_SYSTEM()) as DeviceRemoteBreachStateSystem;

  if !IsDefined(stateSystem) { return false; }

  return stateSystem.IsDeviceBreached(deviceID);
}

@addMethod(ScriptableDeviceComponentPS)
private final func RemoveCustomRemoteBreachAction(outActions: script_ref<array<ref<DeviceAction>>>) -> Void {
  let i: Int32 = 0;
  while i < ArraySize(Deref(outActions)) {
    let action: ref<DeviceAction> = Deref(outActions)[i];
    if IsCustomRemoteBreachAction(action) {
      ArrayErase(Deref(outActions), i);
      break;
    }
    i += 1;
  }
}

@if(ModuleExists("HackingExtensions"))
@wrapMethod(QuickHackableHelper)
public static func TranslateActionsIntoQuickSlotCommands(const actions: array<ref<DeviceAction>>, commands: script_ref<array<ref<QuickhackData>>>, gameObject: ref<GameObject>, scriptableComponentPS: ref<ScriptableDeviceComponentPS>) -> Void {

  wrappedMethod(actions, commands, gameObject, scriptableComponentPS);

  let playerRef: ref<PlayerPuppet> = GetPlayer(gameObject.GetGame());
  if !IsDefined(playerRef) {
    BNDebug("RemoteBreachVisibility", "Player not defined - EXIT");
    return; // Early return if player not available
  }

  let i: Int32 = 0;
  let commandsSize: Int32 = ArraySize(Deref(commands));
  while i < commandsSize {
    let action: ref<ScriptableDeviceAction> = Deref(commands)[i].m_action as ScriptableDeviceAction;

    if IsDefined(action) && BNConstants.IsRemoteBreachAction(action.GetClassName()) {

      let remoteBreachAction: ref<BaseRemoteBreachAction> = action as BaseRemoteBreachAction;
      if IsDefined(remoteBreachAction) {

        let canPay: Bool = remoteBreachAction.CanPayCost(playerRef, true);

        let playerStatPoolSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(playerRef.GetGame());
        if IsDefined(playerStatPoolSystem) {
          DebugUtils.LogRemoteBreachRAMCheck(
            action.GetClassName(),
            remoteBreachAction.GetCost(),
            playerStatPoolSystem.GetStatPoolValue(Cast<StatsObjectID>(playerRef.GetEntityID()), gamedataStatPoolType.Memory, false),
            playerStatPoolSystem.GetStatPoolValue(Cast<StatsObjectID>(playerRef.GetEntityID()), gamedataStatPoolType.Memory, true),
            canPay,
            "RemoteBreachVisibility"
          );
        }

        if !canPay {
          BNDebug("RemoteBreachVisibility", "RAM insufficient - setting locked state");
          Deref(commands)[i].m_isLocked = true;
          Deref(commands)[i].m_inactiveReason = BNConstants.LOCKEY_RAM_INSUFFICIENT();
        }
      } else {
        BNDebug("RemoteBreachVisibility", "Failed to cast to BaseRemoteBreachAction - skipping");
      }
    }

    if !Deref(commands)[i].m_isLocked && IsDefined(Deref(commands)[i].m_action) {
      let linkedAction: ref<ScriptableDeviceAction> = Deref(commands)[i].m_action as ScriptableDeviceAction;
      if IsDefined(linkedAction) && linkedAction.IsInactive() {
        Deref(commands)[i].m_isLocked = true;
        Deref(commands)[i].m_inactiveReason = linkedAction.GetInactiveReason();
      }
    }

    i += 1;
  }
}
