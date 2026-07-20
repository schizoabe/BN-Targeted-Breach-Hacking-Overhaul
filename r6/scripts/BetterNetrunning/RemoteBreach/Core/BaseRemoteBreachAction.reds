



















module BetterNetrunning.RemoteBreach.Core
import BetterNetrunning.Logging.*

import BetterNetrunning.*
import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Marking.*
import BetterNetrunning.RadialUnlock.*

@if(ModuleExists("HackingExtensions"))
import HackingExtensions.*

@if(ModuleExists("HackingExtensions.Programs"))
import HackingExtensions.Programs.*






@if(ModuleExists("HackingExtensions"))
public abstract class BaseRemoteBreachAction extends CustomAccessBreach {
    public let m_calculatedRAMCost: Int32; // Dynamic RAM cost


    public let m_isICEBoard: Bool;

    
    public func SetProperties(networkName: String, npcCount: Int32, attemptsCount: Int32, isRemote: Bool, isSuicide: Bool, minigameDefinition: TweakDBID, targetHack: ref<IScriptable>) -> Void {

        super.SetProperties(networkName, npcCount, attemptsCount, isRemote, isSuicide, minigameDefinition, targetHack);




    }

    
    public func CompleteAction(gameInstance: GameInstance) -> Void {

        let devicePS: ref<ScriptableDeviceComponentPS> = this.GetTargetDevice();
        if IsDefined(devicePS) {
            DebugUtils.LogRemoteBreachTarget(devicePS, "RemoteBreach");
        }



        let npcSS: ref<NPCRemoteBreachStateSystem> =
          GameInstance.GetScriptableSystemsContainer(gameInstance)
            .Get(BNConstants.CLASS_NPC_REMOTE_BREACH_STATE_SYSTEM()) as NPCRemoteBreachStateSystem;
        if IsDefined(npcSS) { npcSS.ClearCurrentNPC(); }



        this.SetStateSystemTarget(gameInstance);


        let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gameInstance);


        let allProgramsRecord: array<wref<Program_Record>>;
        let minigameRecord: ref<Minigame_Def_Record> = TweakDBInterface.GetMinigame_DefRecord(this.m_minigameDefinition);

        if IsDefined(minigameRecord) {
            minigameRecord.OverrideProgramsList(allProgramsRecord);

            let displayedDaemons: array<TweakDBID>;
            let i: Int32 = 0;
            while i < ArraySize(allProgramsRecord) {
                ArrayPush(displayedDaemons, allProgramsRecord[i].Program().GetID());
                i += 1;
            }

            let stateSystem: ref<DisplayedDaemonsStateSystem> = container.Get(BNConstants.CLASS_DISPLAYED_DAEMONS_STATE_SYSTEM()) as DisplayedDaemonsStateSystem;

            if IsDefined(stateSystem) {
                stateSystem.SetDisplayedDaemons(displayedDaemons);
                BNDebug("RemoteBreach", "Stored " + ToString(ArraySize(displayedDaemons)) + " displayed daemons for statistics");
            } else {
                BNError("RemoteBreach", "DisplayedDaemonsStateSystem not found");
            }
        } else {
            BNError("RemoteBreach", "Failed to get Minigame_Def_Record for: " + TDBID.ToStringDEBUG(this.m_minigameDefinition));
        }


        let customHackSystem: ref<CustomHackingSystem> = container.Get(BNConstants.CLASS_CUSTOM_HACKING_SYSTEM()) as CustomHackingSystem;

        if IsDefined(customHackSystem) {

            let emptyData: array<Variant>;



            let onSucceed: ref<OnCustomHackingSucceeded> = this.CreateSuccessCallback();
            let onFailed: ref<OnRemoteBreachFailed> = new OnRemoteBreachFailed();


            let success: Bool = customHackSystem.StartNewQuickhackInstance(
                this.m_networkName,      // Network name
                this,                    // This action
                this.m_minigameDefinition, // Minigame def
                this.m_targetHack,       // Target hack
                emptyData,               // additionalData (empty array)
                onSucceed,               // onSucceed callback
                onFailed                 // onFailed callback
            );

            if !success {
                BNError("RemoteBreach", "StartNewQuickhackInstance FAILED");
            }
        } else {
            BNError("RemoteBreach", "CustomHackingSystem not found - bonus daemons will not execute");
        }


        let blackboard: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gameInstance).Get(GetAllBlackboardDefs().NetworkBlackboard);
        blackboard.SetInt(GetAllBlackboardDefs().NetworkBlackboard.DevicesCount, this.m_npcCount);
        blackboard.SetBool(GetAllBlackboardDefs().NetworkBlackboard.OfficerBreach, false);
        blackboard.SetBool(GetAllBlackboardDefs().NetworkBlackboard.RemoteBreach, true);
        blackboard.SetBool(GetAllBlackboardDefs().NetworkBlackboard.SuicideBreach, false);
        blackboard.SetVariant(GetAllBlackboardDefs().NetworkBlackboard.MinigameDef, ToVariant(this.m_minigameDefinition), true);
        blackboard.SetString(GetAllBlackboardDefs().NetworkBlackboard.NetworkName, this.m_networkName, true);
        blackboard.SetEntityID(GetAllBlackboardDefs().NetworkBlackboard.DeviceID, GetPlayer(gameInstance).GetEntityID(), true);
        blackboard.SetInt(GetAllBlackboardDefs().NetworkBlackboard.Attempt, this.m_attempt);




        let psmEvent: ref<PSMPostponedParameterBool> = new PSMPostponedParameterBool();
        psmEvent.id = n"NanoWireRemoteBreach";
        psmEvent.value = true;
        GameInstance.GetPlayerSystem(gameInstance).GetLocalPlayerMainGameObject().QueueEvent(psmEvent);
    }





    
    public func GetCost() -> Int32 {

        return this.m_calculatedRAMCost;
    }

    
    public func PayCost(opt checkForOverclockedState: Bool) -> Bool {
        if this.m_calculatedRAMCost <= 0 {
            return true; // No cost to pay
        }

        let executor: ref<GameObject> = this.GetExecutor();
        if !IsDefined(executor) {
            return false;
        }

        let statPoolSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(executor.GetGame());
        let executorID: StatsObjectID = Cast<StatsObjectID>(executor.GetEntityID());
        let currentRAM: Float = statPoolSystem.GetStatPoolValue(executorID, gamedataStatPoolType.Memory, false);
        let costFloat: Float = Cast<Float>(this.m_calculatedRAMCost);


        if currentRAM < costFloat {
            return false;
        }


        let newRAM: Float = currentRAM - costFloat;
        statPoolSystem.RequestSettingStatPoolValue(executorID, gamedataStatPoolType.Memory, newRAM, executor, false);

        return true;
    }

    
    public func CanPayCost(opt user: ref<GameObject>, opt checkForOverclockedState: Bool) -> Bool {
        if this.m_calculatedRAMCost <= 0 {
            return true; // No cost required
        }

        let executor: ref<GameObject>;
        if IsDefined(user) {
            executor = user;
        } else {
            executor = this.GetExecutor();
        }

        if !IsDefined(executor) {
            BNDebug("BaseRemoteBreachAction", "CanPayCost: executor not defined, returning false");
            return false;
        }

        let statPoolSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(executor.GetGame());
        let executorID: StatsObjectID = Cast<StatsObjectID>(executor.GetEntityID());
        let currentRAM: Float = statPoolSystem.GetStatPoolValue(executorID, gamedataStatPoolType.Memory, false);

        return currentRAM >= Cast<Float>(this.m_calculatedRAMCost);
    }

    
    public func IsPossible(target: wref<GameObject>, opt actionRecord: wref<ObjectAction_Record>, opt objectActionsCallbackController: wref<gameObjectActionsCallbackController>) -> Bool {

        if !super.IsPossible(target, actionRecord, objectActionsCallbackController) {
            return false;
        }


        return this.CanPayCost();
    }

    
    protected func CreateSuccessCallback() -> ref<OnCustomHackingSucceeded> {
      if this.m_isICEBoard {
        return new OnRemoteBreachICEBoardSucceeded();
      }
      return new OnRemoteBreachSucceeded();
    }

    
    public func GetTargetDevice() -> wref<ScriptableDeviceComponentPS> {


        if IsDefined(this.m_targetHack) {
            let device: ref<Device> = this.m_targetHack as Device;
            if IsDefined(device) {
                return device.GetDevicePS();
            }
        }
        return null;
    }



    private func SetStateSystemTarget(gameInstance: GameInstance) -> Void {
        if !IsDefined(this.m_targetHack) {
            BNWarn("RemoteBreach", "m_targetHack not defined - cannot set StateSystem target");
            return;
        }

        let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gameInstance);
        let deviceStateSystem: ref<DeviceRemoteBreachStateSystem> = container.Get(BNConstants.CLASS_DEVICE_REMOTE_BREACH_STATE_SYSTEM()) as DeviceRemoteBreachStateSystem;
        if !IsDefined(deviceStateSystem) {
            BNError("RemoteBreach", "DeviceRemoteBreachStateSystem not found");
            return;
        }

        let devicePS: ref<ScriptableDeviceComponentPS> = this.m_targetHack as ScriptableDeviceComponentPS;
        if !IsDefined(devicePS) {
            BNError("RemoteBreach", "Failed to set StateSystem target - m_targetHack is not SDCPS");
            return;
        }

        let daemons: String;
        if IsDefined(devicePS as ComputerControllerPS) {
            daemons = "basic,camera";
        } else if DaemonFilterUtils.IsCamera(devicePS) {
            daemons = "basic,camera";
        } else if DaemonFilterUtils.IsTurret(devicePS) {
            daemons = "basic,turret";
        } else if IsDefined(devicePS as TerminalControllerPS) {
            daemons = "basic,npc";
        } else {
            daemons = "basic";
        }

        deviceStateSystem.SetCurrentDevice(devicePS, daemons);
    }
}

