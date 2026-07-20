

module BetterNetrunning.RemoteBreach.Core

import BetterNetrunning.*
import BetterNetrunning.Breach.*
import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Integration.*
import BetterNetrunning.Network.*
import BetterNetrunning.Marking.*
import BetterNetrunning.CounterBreach.*
import BetterNetrunning.Utils.*
import BetterNetrunning.RadialUnlock.*
import BetterNetrunning.RemoteBreach.Common.*
import BetterNetrunning.Logging.*

@if(ModuleExists("HackingExtensions"))
import HackingExtensions.*

@if(ModuleExists("HackingExtensions"))
import HackingExtensions.Programs.*

public abstract class DaemonTypes {
    public static func Basic() -> String { return TDBID.ToStringDEBUG(BNConstants.PROGRAM_UNLOCK_QUICKHACKS()); }
    public static func NPC() -> String { return TDBID.ToStringDEBUG(BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS()); }
    public static func Camera() -> String { return TDBID.ToStringDEBUG(BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS()); }
    public static func Turret() -> String { return TDBID.ToStringDEBUG(BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS()); }
}

@if(ModuleExists("HackingExtensions"))
public abstract class StateSystemUtils {

    public static func GetHeatScaledICEHits(gi: GameInstance) -> Int32 {
        let c: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gi);
        let ms: ref<MarkingStateSystem> = IsDefined(c) ? c.Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem : null;
        let heat: Float = IsDefined(ms) ? ms.GetSessionHeat() : 0.0;
        let iceMin: Int32;
        let iceMax: Int32;
        if      heat >= 0.95 { iceMin = 6; iceMax = 11; }  // MAXIMUM: 6-10
        else if heat >= 0.80 { iceMin = 5; iceMax = 10; }  // PEAK:     5-9
        else if heat >= 0.60 { iceMin = 4; iceMax =  8; }  // CRITICAL: 4-7
        else if heat >= 0.40 { iceMin = 3; iceMax =  7; }  // HOT:      3-6
        else if heat >= 0.20 { iceMin = 2; iceMax =  6; }  // WARM:     2-5
        else                 { iceMin = 1; iceMax =  4; }  // COLD:     1-3
        return RandRange(iceMin, iceMax);
    }

    public static func GetDeviceStateSystem(gameInstance: GameInstance) -> ref<DeviceRemoteBreachStateSystem> {
        let c: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gameInstance);
        return IsDefined(c) ? c.Get(BNConstants.CLASS_DEVICE_REMOTE_BREACH_STATE_SYSTEM()) as DeviceRemoteBreachStateSystem : null;
    }

    public static func GetCustomHackingSystem(gameInstance: GameInstance) -> ref<CustomHackingSystem> {
        return GameInstance.GetScriptableSystemsContainer(gameInstance).Get(BNConstants.CLASS_CUSTOM_HACKING_SYSTEM()) as CustomHackingSystem;
    }

    public static func GetNPCStateSystem(gameInstance: GameInstance) -> ref<NPCRemoteBreachStateSystem> {
        return GameInstance.GetScriptableSystemsContainer(gameInstance).Get(BNConstants.CLASS_NPC_REMOTE_BREACH_STATE_SYSTEM()) as NPCRemoteBreachStateSystem;
    }
}

@if(ModuleExists("HackingExtensions"))
public abstract class RemoteBreachRAMUtils {

  public static func CheckAndLockRemoteBreachRAM(
    actions: script_ref<array<ref<DeviceAction>>>
  ) -> Void {
    let i: Int32 = 0;
    while i < ArraySize(Deref(actions)) {
      let action: ref<DeviceAction> = Deref(actions)[i];
      if !IsDefined(action) {
        i += 1;
      } else {
        let className: CName = action.GetClassName();
        if !IsCustomRemoteBreachAction(className) {
          i += 1;
        } else {
          let remoteBreachAction: ref<CustomAccessBreach> = action as CustomAccessBreach;
          if IsDefined(remoteBreachAction) && !remoteBreachAction.CanPayCost() {
            let sAction: ref<ScriptableDeviceAction> = action as ScriptableDeviceAction;
            if IsDefined(sAction) {
              sAction.SetInactive();
              sAction.SetInactiveReason(BNConstants.LOCKEY_RAM_INSUFFICIENT());
            }
          }
          i += 1;
        }
      }
    }
  }
}

@if(ModuleExists("HackingExtensions"))
public abstract class ProgramIDUtils {

    public static func ApplyProgramToSharedPS(programID: TweakDBID, sharedPS: ref<SharedGameplayPS>, gameInstance: GameInstance) -> Void {
        let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);

        if programID == BNConstants.PROGRAM_UNLOCK_QUICKHACKS() {
            sharedPS.m_betterNetrunningUnlockTimestampBasic = currentTime;
        } else if programID == BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS() {
            sharedPS.m_betterNetrunningUnlockTimestampNPCs = currentTime;
        } else if programID == BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS() {
            sharedPS.m_betterNetrunningUnlockTimestampCameras = currentTime;
        } else if programID == BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS() {
            sharedPS.m_betterNetrunningUnlockTimestampTurrets = currentTime;
        }
    }

    
    public static func IsAnyDaemonCompleted(sharedPS: ref<SharedGameplayPS>) -> Bool {
        return BreachStatusUtils.IsBasicBreached(sharedPS)
            || BreachStatusUtils.IsNPCsBreached(sharedPS)
            || BreachStatusUtils.IsCamerasBreached(sharedPS)
            || BreachStatusUtils.IsTurretsBreached(sharedPS);
    }

    
    public static func CreateBreachEventFromProgram(programID: TweakDBID, gameInstance: GameInstance) -> ref<SetBreachedSubnet> {
        let event: ref<SetBreachedSubnet> = new SetBreachedSubnet();
        let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);

        if programID == BNConstants.PROGRAM_UNLOCK_QUICKHACKS() {
            event.unlockTimestampBasic = currentTime;
        } else if programID == BNConstants.PROGRAM_UNLOCK_NPC_QUICKHACKS() {
            event.unlockTimestampNPCs = currentTime;
        } else if programID == BNConstants.PROGRAM_UNLOCK_CAMERA_QUICKHACKS() {
            event.unlockTimestampCameras = currentTime;
        } else if programID == BNConstants.PROGRAM_UNLOCK_TURRET_QUICKHACKS() {
            event.unlockTimestampTurrets = currentTime;
        }

        return event;
    }
}

@if(ModuleExists("HackingExtensions"))
public abstract class RemoteBreachUtils {

    public static func UnlockNearbyNetworkDevices(sourceEntity: wref<GameObject>, gameInstance: GameInstance, unlockBasic: Bool, unlockNPCs: Bool, unlockCameras: Bool, unlockTurrets: Bool, logPrefix: String) -> RadialUnlockResult {
        let result: RadialUnlockResult;

        if !IsDefined(sourceEntity) {
            return result;
        }

        let targetingSetup: TargetingSetup = RemoteBreachUtils.SetupDeviceTargeting(sourceEntity, gameInstance);
        if !targetingSetup.isValid {
            return result;
        }

        let parts: array<TS_TargetPartInfo>;
        targetingSetup.targetingSystem.GetTargetParts(targetingSetup.player, targetingSetup.query, parts);

        let unlockFlags: BreachUnlockFlags = IDaemonUnlockStrategy.BuildUnlockFlags(unlockBasic, unlockNPCs, unlockCameras, unlockTurrets);

        let i: Int32 = 0;
        while i < ArraySize(parts) {
            let deviceResult: RadialUnlockResult = RemoteBreachUtils.ProcessNetworkDevice(parts[i], targetingSetup, unlockFlags);
            result.basicCount += deviceResult.basicCount;
            result.cameraCount += deviceResult.cameraCount;
            result.turretCount += deviceResult.turretCount;
            result.npcCount += deviceResult.npcCount;
            result.basicUnlocked += deviceResult.basicUnlocked;
            result.cameraUnlocked += deviceResult.cameraUnlocked;
            result.turretUnlocked += deviceResult.turretUnlocked;
            result.npcUnlocked += deviceResult.npcUnlocked;
            i += 1;
        }

        return result;
    }

    private static func SetupDeviceTargeting(sourceEntity: wref<GameObject>, gameInstance: GameInstance) -> TargetingSetup {
        let setup: TargetingSetup;
        setup.isValid = false;
        setup.breachRadius = GetRadialBreachRange(gameInstance);
        setup.sourcePos = sourceEntity.GetWorldPosition();

        setup.player = GetPlayer(gameInstance);
        if !IsDefined(setup.player) {
            return setup;
        }

        setup.targetingSystem = GameInstance.GetTargetingSystem(gameInstance);
        if !IsDefined(setup.targetingSystem) {
            return setup;
        }

        setup.query.searchFilter = TSF_All(TSFMV.Obj_Device);
        setup.query.testedSet = TargetingSet.Complete;
        setup.query.maxDistance = setup.breachRadius * 2.0;
        setup.query.filterObjectByDistance = true;
        setup.query.includeSecondaryTargets = false;
        setup.query.ignoreInstigator = true;

        setup.isValid = true;
        return setup;
    }

    
    private static func ProcessNetworkDevice(part: TS_TargetPartInfo, setup: TargetingSetup, flags: BreachUnlockFlags) -> RadialUnlockResult {
        let result: RadialUnlockResult;

        let entity: wref<GameObject> = TS_TargetPartInfo.GetComponent(part).GetEntity() as GameObject;
        if !IsDefined(entity) {
            return result;
        }

        let device: ref<Device> = entity as Device;
        if !IsDefined(device) {
            return result;
        }

        let devicePS: ref<ScriptableDeviceComponentPS> = device.GetDevicePS();
        if !IsDefined(devicePS) {
            return result;
        }

        let sharedPS: ref<SharedGameplayPS> = devicePS;
        if !IsDefined(sharedPS) {
            return result;
        }

        let apControllers: array<ref<AccessPointControllerPS>> = sharedPS.GetAccessPoints();
        if ArraySize(apControllers) == 0 {
            return result;  // Not network-connected
        }

        let distance: Float = Vector4.Distance(setup.sourcePos, entity.GetWorldPosition());
        if distance > setup.breachRadius {
            return result;
        }

        let isCamera: Bool = DeviceTypeUtils.IsCameraDevice(devicePS);
        let isTurret: Bool = DeviceTypeUtils.IsTurretDevice(devicePS);
        let isNPC: Bool = DeviceTypeUtils.IsNPCDevice(devicePS);

        if isCamera {
            result.cameraCount = 1;
        } else if isTurret {
            result.turretCount = 1;
        } else if isNPC {
            result.npcCount = 1;
        } else {
            result.basicCount = 1;
        }

        let unlocked: Bool = RemoteBreachUtils.UnlockDeviceByType(devicePS, flags);

        if unlocked {
            if isCamera {
                result.cameraUnlocked = 1;
            } else if isTurret {
                result.turretUnlocked = 1;
            } else if isNPC {
                result.npcUnlocked = 1;
            } else {
                result.basicUnlocked = 1;
            }
        }

        return result;
    }

    
    private static func UnlockDeviceByType(devicePS: ref<ScriptableDeviceComponentPS>, flags: BreachUnlockFlags) -> Bool {
        let TargetType: TargetType = DeviceTypeUtils.GetDeviceType(devicePS);

        if !DeviceTypeUtils.ShouldUnlockByFlags(TargetType, flags) {
            return false;  // Device type not allowed by flags
        }

        DeviceUnlockUtils.ApplyTimestampUnlock(
            devicePS,
            devicePS.GetGameInstance(),
            flags.unlockBasic,
            flags.unlockNPCs,
            flags.unlockCameras,
            flags.unlockTurrets
        );

        return true;  // Successfully unlocked
    }
}

@if(ModuleExists("HackingExtensions"))
public abstract class ComputerRemoteBreachUtils {

    public static func UnlockNetworkDevices(computerPS: ref<ComputerControllerPS>, unlockBasic: Bool, unlockNPCs: Bool, unlockCameras: Bool, unlockTurrets: Bool) -> Void {
        let sharedPS: ref<SharedGameplayPS> = computerPS;
        if !IsDefined(sharedPS) {
            return;
        }

        let apControllers: array<ref<AccessPointControllerPS>> = sharedPS.GetAccessPoints();
        if ArraySize(apControllers) == 0 {
            return;  // Standalone computer, no network devices
        }

        let flags: BreachUnlockFlags = IDaemonUnlockStrategy.BuildUnlockFlags(unlockBasic, unlockNPCs, unlockCameras, unlockTurrets);

        let i: Int32 = 0;
        while i < ArraySize(apControllers) {
            ComputerRemoteBreachUtils.ProcessAccessPointDevices(apControllers[i], flags);
            i += 1;
        }
    }

    private static func ProcessAccessPointDevices(apPS: ref<AccessPointControllerPS>, flags: BreachUnlockFlags) -> Void {
        if !IsDefined(apPS) {
            return;
        }

        let devices: array<ref<DeviceComponentPS>>;
        apPS.GetChildren(devices);

        let setBreachedEvent: ref<SetBreachedSubnet> = ComputerRemoteBreachUtils.CreateBreachEvent(apPS.GetGameInstance(), flags);

        let j: Int32 = 0;
        while j < ArraySize(devices) {
            ComputerRemoteBreachUtils.ProcessNetworkConnectedDevice(devices[j], apPS, setBreachedEvent, flags);
            j += 1;
        }
    }

    private static func CreateBreachEvent(gameInstance: GameInstance, flags: BreachUnlockFlags) -> ref<SetBreachedSubnet> {
        let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
        let event: ref<SetBreachedSubnet> = new SetBreachedSubnet();
        event.unlockTimestampBasic = flags.unlockBasic ? currentTime : 0.0;
        event.unlockTimestampNPCs = flags.unlockNPCs ? currentTime : 0.0;
        event.unlockTimestampCameras = flags.unlockCameras ? currentTime : 0.0;
        event.unlockTimestampTurrets = flags.unlockTurrets ? currentTime : 0.0;
        return event;
    }

    private static func ProcessNetworkConnectedDevice(
        device: ref<DeviceComponentPS>,
        apPS: ref<AccessPointControllerPS>,
        setBreachedEvent: ref<SetBreachedSubnet>,
        flags: BreachUnlockFlags
    ) -> Void {
        if !IsDefined(device) {
            return;
        }

        apPS.QueuePSEvent(device, setBreachedEvent);

        let TargetType: TargetType = DeviceTypeUtils.GetDeviceType(device);
        let shouldUnlock: Bool = ComputerRemoteBreachUtils.ShouldUnlockDeviceType(TargetType, flags);

        if shouldUnlock {
            apPS.QueuePSEvent(device, apPS.ActionSetExposeQuickHacks());
        }
    }

    private static func ShouldUnlockDeviceType(TargetType: TargetType, flags: BreachUnlockFlags) -> Bool {
        switch TargetType {
            case TargetType.NPC:
                return flags.unlockNPCs;
            case TargetType.Camera:
                return flags.unlockCameras;
            case TargetType.Turret:
                return flags.unlockTurrets;
            case TargetType.Basic:
                return flags.unlockBasic;
            default:
                return false;
        }
    }
}

public abstract class MinigameIDHelper {

    public static func GetMinigameID(targetType: MinigameTargetType, difficulty: GameplayDifficulty, opt devicePS: ref<ScriptableDeviceComponentPS>) -> TweakDBID {
        switch targetType {
            case MinigameTargetType.Computer:
                return MinigameIDHelper.GetComputerMinigameID(difficulty);
            case MinigameTargetType.Device:
                return MinigameIDHelper.GetDeviceMinigameID(difficulty, devicePS);
            case MinigameTargetType.Vehicle:
                return MinigameIDHelper.GetVehicleMinigameID(difficulty);
            default:
                BNWarn("CustomHacking", "Unknown target type - defaulting to Device Medium");
                return BNConstants.MINIGAME_DEVICE_BREACH_MEDIUM();
        }
    }

    private static func GetComputerMinigameID(difficulty: GameplayDifficulty) -> TweakDBID {
        switch difficulty {
            case GameplayDifficulty.Easy:
                return BNConstants.MINIGAME_COMPUTER_BREACH_EASY();
            case GameplayDifficulty.Hard:
                return BNConstants.MINIGAME_COMPUTER_BREACH_HARD();
            default:
                return BNConstants.MINIGAME_COMPUTER_BREACH_MEDIUM();
        }
    }

    private static func GetDeviceMinigameID(difficulty: GameplayDifficulty, devicePS: ref<ScriptableDeviceComponentPS>) -> TweakDBID {

        let minigameBase: String;

        if DaemonFilterUtils.IsCamera(devicePS) {
            minigameBase = "CameraRemoteBreach";
        } else if DaemonFilterUtils.IsTurret(devicePS) {
            minigameBase = "TurretRemoteBreach";
        } else {
            minigameBase = "DeviceRemoteBreach";
        }

        switch difficulty {
            case GameplayDifficulty.Easy:
                return TDBID.Create("Minigame." + minigameBase + "Easy");
            case GameplayDifficulty.Hard:
                return TDBID.Create("Minigame." + minigameBase + "Hard");
            default:
                return TDBID.Create("Minigame." + minigameBase + "Medium");
        }
    }

    private static func GetVehicleMinigameID(difficulty: GameplayDifficulty) -> TweakDBID {

        return BNConstants.MINIGAME_VEHICLE_BREACH();
    }
}

enum GameplayDifficulty {
    Easy = 0,
    Medium = 1,
    Hard = 2
}

enum MinigameTargetType {
    Computer = 0,
    Device = 1,
    Vehicle = 2
}

public abstract class RemoteBreachActionHelper {

    public static func Initialize(action: ref<CustomAccessBreach>, devicePS: ref<ScriptableDeviceComponentPS>, actionName: CName) -> Void {
        action.clearanceLevel = DefaultActionsParametersHolder.GetInteractiveClearance();
        action.SetUp(devicePS);
        action.AddDeviceName(devicePS.GetDeviceName());

        action.SetObjectActionID(BNConstants.DEVICE_ACTION_REMOTE_BREACH());

        action.CreateInteraction();

        action.actionName = actionName;

        RemoteBreachActionHelper.SetDynamicRAMCost(action, devicePS);
    }

    private static func SetDynamicRAMCost(action: ref<CustomAccessBreach>, devicePS: ref<ScriptableDeviceComponentPS>) -> Void {
        let player: ref<PlayerPuppet> = GetPlayer(devicePS.GetGameInstance());
        if !IsDefined(player) {
            BNError("CustomHacking", "Player not found - using default RAM cost");
            return;
        }

        let statPoolSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(devicePS.GetGameInstance());
        if !IsDefined(statPoolSystem) {
            BNError("CustomHacking", "StatPoolsSystem not found - using default RAM cost");
            return;
        }

        let playerID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());

        let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(devicePS.GetGameInstance());

        let currentRAM: Float = statPoolSystem.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
        let maxRAMCap: Float = statsSystem.GetStatValue(playerID, gamedataStatType.Memory);

        let costPercent: Int32 = BetterNetrunningSettings.RemoteBreachRAMCostPercent();
        let ramCost: Float = maxRAMCap * (Cast<Float>(costPercent) / 100.0);

        let roundedCost: Int32 = Cast<Int32>(ramCost + 0.5);

        if roundedCost < 1 {
            roundedCost = 1;
        }

        let remoteBreachAction: ref<BaseRemoteBreachAction> = action as BaseRemoteBreachAction;
        if IsDefined(remoteBreachAction) {
            remoteBreachAction.m_calculatedRAMCost = roundedCost;
        }
    }

    public static func SetMinigameDefinition(action: ref<CustomAccessBreach>, targetType: MinigameTargetType, difficulty: GameplayDifficulty, devicePS: ref<ScriptableDeviceComponentPS>) -> Void {
        let minigameID: TweakDBID = MinigameIDHelper.GetMinigameID(targetType, difficulty, devicePS);

        action.SetProperties(
            devicePS.GetDeviceName(),  // networkName
            1,                         // npcCount
            0,                         // attemptsCount
            true,                      // isRemote
            false,                     // isSuicide
            minigameID,               // minigameDefinition
            devicePS                   // targetHack
        );

    }

    public static func GetCurrentDifficulty() -> GameplayDifficulty {
        return GameplayDifficulty.Medium;
    }

    public static func RemoveTweakDBRemoteBreach(actions: script_ref<array<ref<DeviceAction>>>, actionName: CName) -> Void {
        let actionsArray: array<ref<DeviceAction>> = Deref(actions);
        let i: Int32 = ArraySize(actionsArray) - 1;

        while i >= 0 {
            let action: ref<DeviceAction> = actionsArray[i];
            if IsDefined(action) && Equals(action.actionName, actionName) {
                ArrayErase(actionsArray, i);
            }
            i -= 1;
        }

        actions = actionsArray;
    }
}

@if(ModuleExists("HackingExtensions"))
public class OnRemoteBreachSucceeded extends OnCustomHackingSucceeded {

    public func Execute() -> Void {
        BNInfo("RemoteBreachSucceeded", "Execute: START");
        let activePrograms: array<TweakDBID> = this.GetActivePrograms();
        BNInfo("RemoteBreachSucceeded", "Execute: activePrograms=" + ToString(ArraySize(activePrograms)));
        let device: wref<ScriptableDeviceComponentPS> = this.RetrieveTargetDevice();
        BNInfo("RemoteBreachSucceeded", "Execute: device=" + (IsDefined(device) ? device.GetDeviceName() : "NULL"));

        if !IsDefined(device) {
            BNError("RemoteBreach", "No device found - cannot execute programs");
            return;
        }

        BNInfo("RemoteBreachSucceeded", "Execute: calling ExecuteProgramsAndRewardsWithStats");
        this.ExecuteProgramsAndRewardsWithStats(activePrograms, device);
        BNInfo("RemoteBreachSucceeded", "Execute: DONE");
    }

    private func GetActivePrograms() -> array<TweakDBID> {
        let minigameBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(GetGameInstance()).Get(GetAllBlackboardDefs().HackingMinigame);
        return FromVariant<array<TweakDBID>>(minigameBB.GetVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms));
    }

    private func RetrieveTargetDevice() -> wref<ScriptableDeviceComponentPS> {

        if IsDefined(this.hackInstanceSettings) && IsDefined(this.hackInstanceSettings.hackedTarget) {
            let device: wref<ScriptableDeviceComponentPS> = this.TryGetDeviceFromHackInstanceSettings();
            if IsDefined(device) {
                return device;
            }
        }

        return this.TryGetDeviceFromStateSystems();
    }

    private func TryGetDeviceFromHackInstanceSettings() -> wref<ScriptableDeviceComponentPS> {

        let device: wref<ScriptableDeviceComponentPS> = this.hackInstanceSettings.hackedTarget as ScriptableDeviceComponentPS;
        if IsDefined(device) {
            return device;
        }

        let targetObj: ref<GameObject> = this.hackInstanceSettings.hackedTarget as GameObject;
        if !IsDefined(targetObj) {
            return null;
        }

        let deviceObj: ref<Device> = targetObj as Device;
        if !IsDefined(deviceObj) {
            return null;
        }

        device = deviceObj.GetDevicePS();
        return device;
    }

    private func TryGetDeviceFromStateSystems() -> wref<ScriptableDeviceComponentPS> {
        let deviceStateSystem: ref<DeviceRemoteBreachStateSystem> = GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(BNConstants.CLASS_DEVICE_REMOTE_BREACH_STATE_SYSTEM()) as DeviceRemoteBreachStateSystem;
        if IsDefined(deviceStateSystem) {
            return deviceStateSystem.GetCurrentDevice();
        }
        return null;
    }

    private func ExecuteProgramsAndRewardsWithStats(activePrograms: array<TweakDBID>, device: wref<ScriptableDeviceComponentPS>) -> Void {

        BNInfo("RemoteBreachSucceeded", "ExecuteStats: START — device=" + device.GetDeviceName());
        let stats: ref<BreachSessionStats> = BreachSessionStats.Create("RemoteBreach", device.GetDeviceName());
        stats.minigameSuccess = true;
        stats.programsInjected = ArraySize(activePrograms);

        let unlockFlags: BreachUnlockFlags = DaemonFilterUtils.ExtractUnlockFlags(activePrograms);
        stats.unlockBasic = unlockFlags.unlockBasic;
        stats.unlockCameras = unlockFlags.unlockCameras;
        stats.unlockTurrets = unlockFlags.unlockTurrets;
        stats.unlockNPCs = unlockFlags.unlockNPCs;
        BNInfo("RemoteBreachSucceeded", "ExecuteStats: unlockFlags — basic=" + ToString(unlockFlags.unlockBasic) + " cameras=" + ToString(unlockFlags.unlockCameras) + " turrets=" + ToString(unlockFlags.unlockTurrets) + " npcs=" + ToString(unlockFlags.unlockNPCs));

        let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(GetGameInstance());
        let stateSystem: ref<DisplayedDaemonsStateSystem> = container.Get(BNConstants.CLASS_DISPLAYED_DAEMONS_STATE_SYSTEM()) as DisplayedDaemonsStateSystem;
        let displayedDaemons: array<TweakDBID>;

        if IsDefined(stateSystem) {
            displayedDaemons = stateSystem.GetDisplayedDaemons();
        } else {
            BNError("RemoteBreach", "DisplayedDaemonsStateSystem not found - falling back to activePrograms");
            displayedDaemons = activePrograms;
        }

        BNInfo("RemoteBreachSucceeded", "ExecuteStats: collecting daemon stats");
        BreachStatisticsCollector.CollectDisplayedDaemons(displayedDaemons, stats);  // All daemons in minigame
        BreachStatisticsCollector.CollectExecutedDaemons(activePrograms, stats);     // Successfully completed daemons

        BNInfo("RemoteBreachSucceeded", "ExecuteStats: resolving network devices");
        let networkDevices: array<ref<DeviceComponentPS>>;
        let breachedAPID: PersistentID;
        let masterPS: ref<MasterControllerPS> = device as MasterControllerPS;
        if IsDefined(masterPS) {

            masterPS.GetChildren(networkDevices);
            let apPS: ref<AccessPointControllerPS> = device as AccessPointControllerPS;
            if IsDefined(apPS) {
                breachedAPID = apPS.GetID();  // Direct AccessPoint
            }

        } else {

            let sharedPS: ref<SharedGameplayPS> = device;
            if IsDefined(sharedPS) {
                let apControllers: array<ref<AccessPointControllerPS>> = sharedPS.GetAccessPoints();
                if ArraySize(apControllers) > 0 {

                    apControllers[0].GetChildren(networkDevices);
                    breachedAPID = apControllers[0].GetID();  // First AccessPoint (primary network)
                }

            }
        }
        BNInfo("RemoteBreachSucceeded", "ExecuteStats: networkDevices=" + ToString(ArraySize(networkDevices)));

        BreachStatisticsCollector.CollectNetworkDeviceStats(networkDevices, unlockFlags, stats);
        BNInfo("RemoteBreachSucceeded", "ExecuteStats: CollectNetworkDeviceStats done");

        let deviceEntity: ref<Device> = GameInstance.FindEntityByID(GetGameInstance(), PersistentID.ExtractEntityID(device.GetID())) as Device;
        BNInfo("RemoteBreachSucceeded", "ExecuteStats: deviceEntity=" + (IsDefined(deviceEntity) ? "ok" : "NULL — entity may have streamed out"));

        BNInfo("RemoteBreachSucceeded", "ExecuteStats: calling GiveReward — entityID=" + ToString(device.GetMyEntityID()));
        RPGManager.GiveReward(GetGameInstance(), t"RPGActionRewards.Hacking", Cast<StatsObjectID>(device.GetMyEntityID()));
        BNInfo("RemoteBreachSucceeded", "ExecuteStats: GiveReward done");

        BNInfo("RemoteBreachSucceeded", "ExecuteStats: calling DisableJackInInteraction");
        DeviceInteractionUtils.DisableJackInInteractionForAccessPoint(device);
        BNInfo("RemoteBreachSucceeded", "ExecuteStats: DisableJackInInteraction done");

        stats.Finalize();
        LogBreachSummary(stats);
        BNInfo("RemoteBreachSucceeded", "ExecuteStats: DONE");
    }

}// -----------------------------------------------------------------------------

@if(ModuleExists("HackingExtensions"))
public class OnRemoteBreachFailed extends OnCustomHackingFailed {
    public func Execute() -> Void {
        let device: wref<ScriptableDeviceComponentPS> = this.RetrieveTargetDevice();

        if !IsDefined(device) {
            BNError("RemoteBreach", "No device found - cannot apply failure penalty");
            return;
        }

        device.FinalizeNetrunnerDive(HackingMinigameState.Failed);
    }

    private func RetrieveTargetDevice() -> wref<ScriptableDeviceComponentPS> {
        if IsDefined(this.hackInstanceSettings) && IsDefined(this.hackInstanceSettings.hackedTarget) {
            let device: wref<ScriptableDeviceComponentPS> = this.TryGetDeviceFromHackInstanceSettings();
            if IsDefined(device) {
                return device;
            }
        }
        return this.TryGetDeviceFromStateSystems();
    }

    private func TryGetDeviceFromHackInstanceSettings() -> wref<ScriptableDeviceComponentPS> {

        let device: wref<ScriptableDeviceComponentPS> = this.hackInstanceSettings.hackedTarget as ScriptableDeviceComponentPS;
        if IsDefined(device) {
            return device;
        }

        let targetObj: ref<GameObject> = this.hackInstanceSettings.hackedTarget as GameObject;
        if !IsDefined(targetObj) {
            return null;
        }

        let deviceObj: ref<Device> = targetObj as Device;
        if !IsDefined(deviceObj) {
            return null;
        }

        return deviceObj.GetDevicePS();
    }

    private func TryGetDeviceFromStateSystems() -> wref<ScriptableDeviceComponentPS> {
        let gameInstance: GameInstance = GetGameInstance();
        let deviceStateSystem: ref<DeviceRemoteBreachStateSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance).Get(BNConstants.CLASS_DEVICE_REMOTE_BREACH_STATE_SYSTEM()) as DeviceRemoteBreachStateSystem;
        if IsDefined(deviceStateSystem) {
            return deviceStateSystem.GetCurrentDevice();
        }
        return null;
    }
}

@if(ModuleExists("HackingExtensions"))
public class OnRemoteBreachICEBoardSucceeded extends OnCustomHackingSucceeded {

  public func Execute() -> Void {
    let gi: GameInstance = GetGameInstance();
    let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gi);

    let devicePS: ref<ScriptableDeviceComponentPS>;
    let stateSystem: ref<DeviceRemoteBreachStateSystem> =
      container.Get(BNConstants.CLASS_DEVICE_REMOTE_BREACH_STATE_SYSTEM()) as DeviceRemoteBreachStateSystem;
    if IsDefined(stateSystem) {
      devicePS = stateSystem.GetCurrentDevice();
    }

    let cbs: ref<CounterBreachSystem> =
      container.Get(BNConstants.CLASS_COUNTER_BREACH_SYSTEM()) as CounterBreachSystem;

    if IsDefined(devicePS) {

      let minigameBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi)
        .Get(GetAllBlackboardDefs().HackingMinigame);
      let activePrograms: array<TweakDBID> = FromVariant<array<TweakDBID>>(
        minigameBB.GetVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms));

      let k: Int32 = 0;
      while k < ArraySize(activePrograms) {
        let pid: TweakDBID = activePrograms[k];
        if pid == BNConstants.PROGRAM_ACTION_BN_RB_ICEPICK_V1() {
          NetworkStateUtils.ApplyIcepickEffect(devicePS, gi, 2 + RandRange(0, 4));
        } else if pid == BNConstants.PROGRAM_ACTION_BN_RB_ICEPICK_V3() {
          NetworkStateUtils.ApplyIcepickEffect(devicePS, gi, 5 + RandRange(0, 4));
        }

        k += 1;
      }

      let state: NetworkState = NetworkStateUtils.GetNetworkState(devicePS, gi);
      let ms: ref<MarkingStateSystem> =
        container.Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
      let heat: Float = IsDefined(ms) ? ms.GetSessionHeat() : 0.0;

      if IsDefined(ms) && ms.GetDisarmICETimer() > 0.0 && state.hitsRequired > 0 {
        state.hitsRequired = 1;
        state.globalBonus  = 0;
      }

      let availableDaemons: String = IsDefined(stateSystem) ? stateSystem.GetAvailableDaemons() : "basic";
      let targetType: String = "device";
      if Equals(availableDaemons, "basic,camera") { targetType = "camera"; }
      else if Equals(availableDaemons, "basic,turret") { targetType = "turret"; }

      if IsDefined(ms) {
        let deviceEntity: wref<GameObject> = devicePS.GetOwnerEntityWeak() as GameObject;
        let deviceName: String = "DEVICE";
        if IsDefined(deviceEntity) {
          let raw: String = GetLocalizedText(deviceEntity.GetDisplayName());
          if NotEquals(raw, s"") { deviceName = raw; }
        }
        ms.RecordRemoteBreachTarget(deviceName, targetType);

      }

      if NetworkStateUtils.IsSubnetAccessible(state) {

        let unlockCamera: Bool = Equals(availableDaemons, "basic,camera");
        let unlockTurret: Bool = Equals(availableDaemons, "basic,turret");
        let unlockNPC:    Bool = Equals(availableDaemons, "basic,npc");

        DeviceUnlockUtils.ApplyTimestampUnlock(devicePS, gi, true, unlockNPC, unlockCamera, unlockTurret);

        let persistency: ref<GamePersistencySystem> = GameInstance.GetPersistencySystem(gi);
        let exposeEvt: ref<SetExposeQuickHacks> = new SetExposeQuickHacks();
        exposeEvt.isRemote = true;
        persistency.QueuePSEvent(devicePS.GetID(), devicePS.GetClassName(), exposeEvt);

        let deviceEntity: wref<GameObject> = devicePS.GetOwnerEntityWeak() as GameObject;
        if IsDefined(deviceEntity) && IsDefined(stateSystem) {
          stateSystem.MarkDeviceBreached(deviceEntity.GetEntityID());
        }

        RPGManager.GiveReward(gi, t"RPGActionRewards.Hacking",
          Cast<StatsObjectID>(devicePS.GetMyEntityID()));

        if IsDefined(ms) { ms.ShowRemoteBreachStatus(); }
        BNInfo("RemoteBreachICE", "ICE fully broken — device stamped immediately");
      } else {
        if IsDefined(ms) { ms.ShowRemoteBreachStatus(); }
        BNInfo("RemoteBreachICE", "ICE WEAKENED — " + NetworkStateUtils.FormatVulnerabilityMessage(state, heat));
      }
    } else {
      if IsDefined(cbs) { cbs.ShowWarning("ICE ANALYSIS COMPLETE — REMOTE BREACH AGAIN TO CONTINUE"); }
      BNWarn("RemoteBreachICE", "No device in state system after ICE board success");
    }
  }
}

public abstract class RemoteBreachLockUtils {

  public static func RemoveAllRemoteBreachActions(
    outActions: script_ref<array<ref<DeviceAction>>>
  ) -> Void {
    let i: Int32 = ArraySize(Deref(outActions)) - 1;

    while i >= 0 {
      let action: ref<DeviceAction> = Deref(outActions)[i];
      let className: CName = action.GetClassName();

      if IsCustomRemoteBreachAction(className) || IsDefined(action as RemoteBreach) {
        ArrayErase(Deref(outActions), i);
      }

      i -= 1;
    }
  }

  
  public static func GetRemoteBreachInactiveReason(
    action: ref<BaseScriptableAction>,
    devicePS: ref<ScriptableDeviceComponentPS>,
    player: ref<PlayerPuppet>,
    out canExecute: Bool
  ) -> String {
    canExecute = true;

    if !action.CanPayCost(player) {
      canExecute = false;
      return BNConstants.LOCKEY_RAM_INSUFFICIENT();
    }

    if !BetterNetrunningSettings.BreachFailurePenaltyEnabled() {
      return "";
    }

    if RemoteBreachLockSystem.IsRemoteBreachLockedByTimestamp(devicePS, devicePS.GetGameInstance()) {
      canExecute = false;
      return BNConstants.LOCKEY_NO_NETWORK_ACCESS();
    }

    return "";
  }
}


