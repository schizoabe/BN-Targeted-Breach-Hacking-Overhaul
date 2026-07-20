

module BetterNetrunning.RemoteBreach.Core

import BetterNetrunning.*
import BetterNetrunning.Core.*
import BetterNetrunning.Integration.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Utils.*

public abstract class IDaemonUnlockStrategy {

  
  public func ExecuteUnlock(
    daemonType: String,
    TargetType: TargetType,
    sourcePS: ref<DeviceComponentPS>,
    gameInstance: GameInstance
  ) -> Void {}

  public func GetStateSystem(gameInstance: GameInstance) -> ref<IScriptable> {
    return null;
  }

  public func MarkBreached(stateSystem: ref<IScriptable>, deviceID: PersistentID, gameInstance: GameInstance) -> Void {}

  
  public static func BuildUnlockFlags(unlockBasic: Bool, unlockNPCs: Bool, unlockCameras: Bool, unlockTurrets: Bool) -> BreachUnlockFlags {
    let flags: BreachUnlockFlags;
    flags.unlockBasic = unlockBasic;
    flags.unlockNPCs = unlockNPCs;
    flags.unlockCameras = unlockCameras;
    flags.unlockTurrets = unlockTurrets;
    return flags;
  }

  
  protected func ExecuteUnlockBase(
    sourcePS: ref<DeviceComponentPS>,
    flags: BreachUnlockFlags,
    gameInstance: GameInstance
  ) -> Void {
    let devicePS: ref<ScriptableDeviceComponentPS> = sourcePS as ScriptableDeviceComponentPS;
    if !IsDefined(devicePS) {
      return;
    }

    this.UnlockNetwork(sourcePS, flags, gameInstance);
  }

  
  protected func UnlockNetwork(
    sourcePS: ref<DeviceComponentPS>,
    flags: BreachUnlockFlags,
    gameInstance: GameInstance
  ) -> Void {}
}

@if(ModuleExists("HackingExtensions"))
public class ComputerUnlockStrategy extends IDaemonUnlockStrategy {

  public func ExecuteUnlock(
    daemonType: String,
    TargetType: TargetType,
    sourcePS: ref<DeviceComponentPS>,
    gameInstance: GameInstance
  ) -> Void {
    let computerPS: ref<ComputerControllerPS> = sourcePS as ComputerControllerPS;
    if !IsDefined(computerPS) {
      BNError("DaemonUnlock", "Cannot cast to ComputerControllerPS");
      return;
    }

    this.ExecuteUnlockBase(
      computerPS,
      IDaemonUnlockStrategy.BuildUnlockFlags(
        Equals(daemonType, DaemonTypes.Basic()),
        Equals(daemonType, DaemonTypes.NPC()),
        Equals(daemonType, DaemonTypes.Camera()),
        Equals(daemonType, DaemonTypes.Turret())
      ),
      gameInstance
    );
  }  // Override network unlock hook for Computer-specific logic
  protected func UnlockNetwork(
    sourcePS: ref<DeviceComponentPS>,
    flags: BreachUnlockFlags,
    gameInstance: GameInstance
  ) -> Void {
    let computerPS: ref<ComputerControllerPS> = sourcePS as ComputerControllerPS;
    if !IsDefined(computerPS) {
      return;
    }

    ComputerRemoteBreachUtils.UnlockNetworkDevices(
      computerPS,
      flags.unlockBasic,
      flags.unlockNPCs,
      flags.unlockCameras,
      flags.unlockTurrets
    );
  }

  public func GetStateSystem(gameInstance: GameInstance) -> ref<IScriptable> {
    return StateSystemUtils.GetDeviceStateSystem(gameInstance);
  }

  public func MarkBreached(stateSystem: ref<IScriptable>, deviceID: PersistentID, gameInstance: GameInstance) -> Void {
    let deviceBreachSystem: ref<DeviceRemoteBreachStateSystem> = stateSystem as DeviceRemoteBreachStateSystem;
    let entity: wref<GameObject> = GameInstance.FindEntityByID(
      gameInstance,
      PersistentID.ExtractEntityID(deviceID)
    ) as GameObject;
    if IsDefined(deviceBreachSystem) && IsDefined(entity) {
      deviceBreachSystem.MarkDeviceBreached(entity.GetEntityID());
    }
  }

  public static func Create() -> ref<ComputerUnlockStrategy> {
    return new ComputerUnlockStrategy();
  }
}

@if(ModuleExists("HackingExtensions"))
public class DeviceUnlockStrategy extends IDaemonUnlockStrategy {

  public func ExecuteUnlock(
    daemonType: String,
    TargetType: TargetType,
    sourcePS: ref<DeviceComponentPS>,
    gameInstance: GameInstance
  ) -> Void {
    let devicePS: ref<ScriptableDeviceComponentPS> = sourcePS as ScriptableDeviceComponentPS;
    if !IsDefined(devicePS) {
      BNError("DaemonUnlock", "Cannot cast to ScriptableDeviceComponentPS");
      return;
    }

    this.ExecuteUnlockBase(
      devicePS,
      IDaemonUnlockStrategy.BuildUnlockFlags(
        Equals(daemonType, DaemonTypes.Basic()),
        Equals(daemonType, DaemonTypes.NPC()),
        Equals(daemonType, DaemonTypes.Camera()),
        Equals(daemonType, DaemonTypes.Turret())
      ),
      gameInstance
    );
  }

  protected func UnlockNetwork(
    sourcePS: ref<DeviceComponentPS>,
    flags: BreachUnlockFlags,
    gameInstance: GameInstance
  ) -> Void {
    DeviceUnlockUtils.ApplyTimestampUnlock(
      sourcePS,
      gameInstance,
      flags.unlockBasic,
      flags.unlockNPCs,
      flags.unlockCameras,
      flags.unlockTurrets
    );

    let persistency: ref<GamePersistencySystem> = GameInstance.GetPersistencySystem(gameInstance);
    let exposeEvt: ref<SetExposeQuickHacks> = new SetExposeQuickHacks();
    exposeEvt.isRemote = true;
    persistency.QueuePSEvent(sourcePS.GetID(), sourcePS.GetClassName(), exposeEvt);
  }

  public func GetStateSystem(gameInstance: GameInstance) -> ref<IScriptable> {
    return StateSystemUtils.GetDeviceStateSystem(gameInstance);
  }

  public func MarkBreached(stateSystem: ref<IScriptable>, deviceID: PersistentID, gameInstance: GameInstance) -> Void {
    let deviceBreachSystem: ref<DeviceRemoteBreachStateSystem> = stateSystem as DeviceRemoteBreachStateSystem;
    let deviceEntity: wref<GameObject> = GameInstance.FindEntityByID(
      gameInstance,
      PersistentID.ExtractEntityID(deviceID)
    ) as GameObject;

    if IsDefined(deviceBreachSystem) && IsDefined(deviceEntity) {
      deviceBreachSystem.MarkDeviceBreached(deviceEntity.GetEntityID());
    }
  }

  public static func Create() -> ref<DeviceUnlockStrategy> {
    return new DeviceUnlockStrategy();
  }
}

@if(ModuleExists("HackingExtensions"))
public class VehicleUnlockStrategy extends IDaemonUnlockStrategy {

  public func ExecuteUnlock(
    daemonType: String,
    TargetType: TargetType,
    sourcePS: ref<DeviceComponentPS>,
    gameInstance: GameInstance
  ) -> Void {
    let vehiclePS: ref<VehicleComponentPS> = sourcePS as VehicleComponentPS;
    if !IsDefined(vehiclePS) {
      BNError("DaemonUnlock", "Cannot cast to VehicleComponentPS");
      return;
    }

    let vehicleEntity: wref<GameObject> = vehiclePS.GetOwnerEntityWeak() as GameObject;
    if !IsDefined(vehicleEntity) {
      BNError("DaemonUnlock", "Vehicle entity not found");
      return;
    }

    this.ExecuteUnlockBase(
      vehiclePS,
      IDaemonUnlockStrategy.BuildUnlockFlags(
        Equals(daemonType, DaemonTypes.Basic()),
        Equals(daemonType, DaemonTypes.NPC()),
        Equals(daemonType, DaemonTypes.Camera()),
        Equals(daemonType, DaemonTypes.Turret())
      ),
      gameInstance
    );
  }  // Override network unlock hook for Vehicle-specific logic
  protected func UnlockNetwork(
    sourcePS: ref<DeviceComponentPS>,
    flags: BreachUnlockFlags,
    gameInstance: GameInstance
  ) -> Void {
    let vehiclePS: ref<VehicleComponentPS> = sourcePS as VehicleComponentPS;
    if !IsDefined(vehiclePS) {
      return;
    }

    let vehicleEntity: wref<GameObject> = vehiclePS.GetOwnerEntityWeak() as GameObject;
    if !IsDefined(vehicleEntity) {
      return;
    }

    RemoteBreachUtils.UnlockNearbyNetworkDevices(
      vehicleEntity,
      gameInstance,
      flags.unlockBasic,
      flags.unlockNPCs,
      flags.unlockCameras,
      flags.unlockTurrets,
      "UnlockNetworkDevicesFromVehicle"
    );
  }

  public func GetStateSystem(gameInstance: GameInstance) -> ref<IScriptable> {
    return StateSystemUtils.GetDeviceStateSystem(gameInstance);
  }

  public func MarkBreached(stateSystem: ref<IScriptable>, deviceID: PersistentID, gameInstance: GameInstance) -> Void {
    let deviceBreachSystem: ref<DeviceRemoteBreachStateSystem> = stateSystem as DeviceRemoteBreachStateSystem;
    let entity: wref<GameObject> = GameInstance.FindEntityByID(
      gameInstance,
      PersistentID.ExtractEntityID(deviceID)
    ) as GameObject;
    if IsDefined(deviceBreachSystem) && IsDefined(entity) {
      deviceBreachSystem.MarkDeviceBreached(entity.GetEntityID());
    }
  }

  public static func Create() -> ref<VehicleUnlockStrategy> {
    return new VehicleUnlockStrategy();
  }
}

