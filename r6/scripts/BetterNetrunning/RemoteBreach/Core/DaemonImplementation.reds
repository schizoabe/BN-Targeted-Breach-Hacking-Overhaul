




















module BetterNetrunning.RemoteBreach.Core

import BetterNetrunning.*
import BetterNetrunning.Core.*
import BetterNetrunning.Network.*
import BetterNetrunning.Marking.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Logging.*

@if(ModuleExists("HackingExtensions"))
import HackingExtensions.*

@if(ModuleExists("HackingExtensions.Programs"))
import HackingExtensions.Programs.*





@if(ModuleExists("HackingExtensions"))
public abstract class DaemonExecutionUtils {

    
    public static func ProcessDaemonWithStrategy(
        sourcePS: ref<DeviceComponentPS>,
        gameInstance: GameInstance,
        strategy: ref<IDaemonUnlockStrategy>,
        daemonTypeStr: String
    ) -> Void {

        let sharedPS: ref<SharedGameplayPS> = sourcePS as SharedGameplayPS;
        if !IsDefined(sharedPS) {
            BNError("ProcessDaemonWithStrategy", "Cannot cast to SharedGameplayPS");
            return;
        }





        let TargetType: TargetType = DaemonExecutionUtils.GetDeviceTypeFromDaemonType(daemonTypeStr);


        let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
        TimeUtils.SetDeviceUnlockTimestamp(sharedPS, TargetType, currentTime);


        let stateSystem: ref<IScriptable> = strategy.GetStateSystem(gameInstance);
        if IsDefined(stateSystem) {
            strategy.MarkBreached(stateSystem, sourcePS.GetID(), gameInstance);
        }


        strategy.ExecuteUnlock(daemonTypeStr, TargetType, sourcePS, gameInstance);
    }

    
    public static func GetDeviceTypeFromDaemonType(daemonTypeStr: String) -> TargetType {
        let TargetType: TargetType;

        if Equals(daemonTypeStr, DaemonTypes.NPC()) {
            TargetType = TargetType.NPC;
        } else if Equals(daemonTypeStr, DaemonTypes.Camera()) {
            TargetType = TargetType.Camera;
        } else if Equals(daemonTypeStr, DaemonTypes.Turret()) {
            TargetType = TargetType.Turret;
        } else {

            TargetType = TargetType.Basic;
        }

        BNDebug("DaemonTypeMapping", s"Mapped daemon type '\(daemonTypeStr)' to TargetType.\(ToString(TargetType))");
        return TargetType;
    }
}





@if(ModuleExists("HackingExtensions.Programs"))
public class DeviceDaemonAction extends HackProgramAction {
    private let m_daemonTypeStr: String;

    
    public func SetDaemonType(daemonTypeStr: String) -> Void {
        this.m_daemonTypeStr = daemonTypeStr;
    }

    
    protected func ExecuteProgramSuccess() -> Void {
        let player: ref<PlayerPuppet> = this.GetPlayer();
        if !IsDefined(player) {
            BNError("DeviceDaemonAction", "Player not defined");
            return;
        }

        let gameInstance: GameInstance = player.GetGame();
        BNDebug("DeviceDaemonAction", "Executing daemon: " + this.m_daemonTypeStr);

        let stateSystem: ref<DeviceRemoteBreachStateSystem> = StateSystemUtils.GetDeviceStateSystem(gameInstance);
        if !IsDefined(stateSystem) {
            BNError("DeviceDaemonAction", "DeviceRemoteBreachStateSystem not found");
            return;
        }

        let devicePS: wref<ScriptableDeviceComponentPS> = stateSystem.GetCurrentDevice();
        if !IsDefined(devicePS) {
            BNError("DeviceDaemonAction", "No device in StateSystem");
            return;
        }

        if IsDefined(devicePS as VehicleComponentPS) {
            this.ProcessDaemonWithStrategy(devicePS, gameInstance, VehicleUnlockStrategy.Create());
        } else if IsDefined(devicePS as ComputerControllerPS) {
            this.ProcessDaemonWithStrategy(devicePS, gameInstance, ComputerUnlockStrategy.Create());
        } else {
            this.ProcessDaemonWithStrategy(devicePS, gameInstance, DeviceUnlockStrategy.Create());
        }
    }

    private func ProcessDaemonWithStrategy(
        sourcePS: ref<DeviceComponentPS>,
        gameInstance: GameInstance,
        strategy: ref<IDaemonUnlockStrategy>
    ) -> Void {
        DaemonExecutionUtils.ProcessDaemonWithStrategy(sourcePS, gameInstance, strategy, this.m_daemonTypeStr);
    }

    protected func ExecuteProgramFailure() -> Void {}
}

@if(ModuleExists("HackingExtensions.Programs"))
public class BetterNetrunningDaemonAction extends DeviceDaemonAction {}










@if(ModuleExists("HackingExtensions.Programs"))
public abstract class RemoteBreachIcepickActionBase extends HackProgramAction {

  protected func GetHits() -> Int32 { return 0; }
  protected func GetHeatDelta() -> Float { return 0.0; }

  protected func ExecuteProgramSuccess() -> Void {
    let player: ref<PlayerPuppet> = this.GetPlayer();
    if !IsDefined(player) { return; }
    let gi: GameInstance = player.GetGame();


    let devicePS: ref<ScriptableDeviceComponentPS>;
    let stateSystem: ref<DeviceRemoteBreachStateSystem> = StateSystemUtils.GetDeviceStateSystem(gi);
    if IsDefined(stateSystem) {
      devicePS = stateSystem.GetCurrentDevice();
    }

    if IsDefined(devicePS) {



      this.ApplyHeatDelta(gi);
      return;
    }





    let npcStateSystem: ref<NPCRemoteBreachStateSystem> = StateSystemUtils.GetNPCStateSystem(gi);
    if IsDefined(npcStateSystem) {
      return;
    }

    BNWarn("RemoteBreachIcepick", "No device or NPC in state system — ICE effect skipped");
  }

  private func ApplyHeatDelta(gi: GameInstance) -> Void {
    let heatDelta: Float = this.GetHeatDelta();
    if heatDelta != 0.0 {
      let ms: ref<MarkingStateSystem> =
        GameInstance.GetScriptableSystemsContainer(gi)
          .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
      if IsDefined(ms) { ms.AddSessionHeat(heatDelta); }
    }
  }

  protected func ExecuteProgramFailure() -> Void {}
}


@if(ModuleExists("HackingExtensions.Programs"))
public class RemoteBreachIcepickV1Action extends RemoteBreachIcepickActionBase {
  protected func GetHits() -> Int32 { return 2; }
  protected func GetHeatDelta() -> Float { return 0.2; }
}


@if(ModuleExists("HackingExtensions.Programs"))
public class RemoteBreachIcepickV2Action extends RemoteBreachIcepickActionBase {
  protected func GetHits() -> Int32 { return 0; }
  protected func GetHeatDelta() -> Float { return -0.3; }
}


@if(ModuleExists("HackingExtensions.Programs"))
public class RemoteBreachIcepickV3Action extends RemoteBreachIcepickActionBase {
  protected func GetHits() -> Int32 { return 5; }
  protected func GetHeatDelta() -> Float { return 0.0; }
}


