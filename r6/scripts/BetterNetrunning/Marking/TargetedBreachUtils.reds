
























module BetterNetrunning.Marking

import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Network.*





@if(ModuleExists("HackthePlanetForReal"))
@addMethod(ScriptedPuppetPS)
public func BN_StampSJKIBreached() -> Void {
    this.m_sjkiNPCSubnetBreached = true;
    BNDebug("TargetedBreachUtils", "SJKI NPC breach flag stamped");
}

@if(!ModuleExists("HackthePlanetForReal"))
@addMethod(ScriptedPuppetPS)
public func BN_StampSJKIBreached() -> Void {}





public abstract class TargetedBreachUtils {

    
    public static func UnlockMarkedEntities(
        markingSystem: ref<MarkingStateSystem>,
        unlockFlags:   BreachUnlockFlags,
        gameInstance:  GameInstance
    ) -> Void {
        let failChance: Float = NetworkStateUtils.GetPropagationFailureChance(markingSystem, gameInstance);

        BNInfo("TargetedBreachUtils", "UnlockMarkedEntities -- flags Basic="
            + ToString(unlockFlags.unlockBasic)
            + " NPC=" + ToString(unlockFlags.unlockNPCs)
            + " Camera=" + ToString(unlockFlags.unlockCameras)
            + " Turret=" + ToString(unlockFlags.unlockTurrets)
            + " heat=" + FloatToStringPrec(IsDefined(markingSystem) ? markingSystem.GetSessionHeat() : 0.0, 2)
            + " failChance=" + FloatToStringPrec(failChance, 2));

        let allUnlocked: array<String>;
        let totalAttempted: Int32 = 0;

        if unlockFlags.unlockBasic && markingSystem.HasMarkedRoot() {
            let batch: array<EntityID> = markingSystem.GetMarkedRoot();
            BNInfo("TargetedBreachUtils", "Unlocking Root/Basic marked entities (incl. vehicles): "
                + ToString(ArraySize(batch)));
            totalAttempted += ArraySize(batch);
            let names: array<String> = TargetedBreachUtils.UnlockEntityIDs(batch, TargetType.Basic, gameInstance, failChance);
            let j: Int32 = 0; while j < ArraySize(names) { ArrayPush(allUnlocked, names[j]); j += 1; }
        }
        if unlockFlags.unlockNPCs && markingSystem.HasMarkedNPCs() {
            let batch: array<EntityID> = markingSystem.GetMarkedNPCs();
            BNInfo("TargetedBreachUtils", "Unlocking NPC marked entities: "
                + ToString(ArraySize(batch)));
            totalAttempted += ArraySize(batch);
            let names: array<String> = TargetedBreachUtils.UnlockEntityIDs(batch, TargetType.NPC, gameInstance, failChance);
            let j: Int32 = 0; while j < ArraySize(names) { ArrayPush(allUnlocked, names[j]); j += 1; }
        }
        if unlockFlags.unlockCameras && markingSystem.HasMarkedCameras() {
            let batch: array<EntityID> = markingSystem.GetMarkedCameras();
            BNInfo("TargetedBreachUtils", "Unlocking Camera marked entities: "
                + ToString(ArraySize(batch)));
            totalAttempted += ArraySize(batch);
            let names: array<String> = TargetedBreachUtils.UnlockEntityIDs(batch, TargetType.Camera, gameInstance, failChance);
            let j: Int32 = 0; while j < ArraySize(names) { ArrayPush(allUnlocked, names[j]); j += 1; }
        }
        if unlockFlags.unlockTurrets && markingSystem.HasMarkedDefense() {
            let batch: array<EntityID> = markingSystem.GetMarkedDefense();
            BNInfo("TargetedBreachUtils", "Unlocking Defense marked entities: "
                + ToString(ArraySize(batch)));
            totalAttempted += ArraySize(batch);
            let names: array<String> = TargetedBreachUtils.UnlockEntityIDs(batch, TargetType.Turret, gameInstance, failChance);
            let j: Int32 = 0; while j < ArraySize(names) { ArrayPush(allUnlocked, names[j]); j += 1; }
        }

        if totalAttempted > 0 {
            markingSystem.ShowPropagationResult(allUnlocked, totalAttempted - ArraySize(allUnlocked));
        }

        let logSys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance)
            .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
        if IsDefined(logSys) { logSys.Refresh(); }
    }

    
    private static func UnlockEntityIDs(
        entityIDs:    array<EntityID>,
        targetType:   TargetType,
        gameInstance: GameInstance,
        failChance:   Float
    ) -> array<String> {
        let unlockedNames: array<String>;
        let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
        let persistency: ref<GamePersistencySystem> =
            GameInstance.GetPersistencySystem(gameInstance);

        let i: Int32 = 0;
        while i < ArraySize(entityIDs) {
            let entityID: EntityID = entityIDs[i];


            let failed: Bool = failChance > 0.0 && RandF() < failChance;
            if failed {
                BNInfo("TargetedBreachUtils",
                    "Propagation failed — entity not unlocked: "
                    + EntityID.ToDebugString(entityID)
                    + " (failChance=" + FloatToStringPrec(failChance, 2) + ")");
            } else {
                let entity: ref<GameObject> =
                    GameInstance.FindEntityByID(gameInstance, entityID) as GameObject;

                if !IsDefined(entity) {
                    BNWarn("TargetedBreachUtils",
                        "Marked entity not found in world: " + EntityID.ToDebugString(entityID));
                } else {
                    BNDebug("TargetedBreachUtils",
                        "Dispatching unlock for: " + EntityID.ToDebugString(entityID)
                        + " class=" + NameToString(entity.GetClassName()));

                    let unlocked: Bool = false;


                    let puppet: ref<ScriptedPuppet> = entity as ScriptedPuppet;
                    if IsDefined(puppet) {
                        TargetedBreachUtils.UnlockNPC(puppet, currentTime, persistency, entityID);
                        unlocked = true;
                    } else {

                        let vehicle: ref<VehicleObject> = entity as VehicleObject;
                        if IsDefined(vehicle) {
                            TargetedBreachUtils.UnlockVehicle(vehicle, currentTime, gameInstance);
                            unlocked = true;
                        } else {

                            let device: ref<Device> = entity as Device;
                            if IsDefined(device) {
                                TargetedBreachUtils.UnlockDevice(device, targetType, currentTime, persistency);
                                unlocked = true;
                            } else {
                                BNWarn("TargetedBreachUtils",
                                    "Entity is not NPC, Vehicle, or Device: "
                                    + EntityID.ToDebugString(entityID)
                                    + " class=" + NameToString(entity.GetClassName()));
                            }
                        }
                    }

                    if unlocked {
                        let raw: String = GetLocalizedText(entity.GetDisplayName());
                        let displayName: String = NotEquals(raw, s"") ? raw : NameToString(entity.GetClassName());
                        ArrayPush(unlockedNames, displayName);
                    }
                }
            }
            i += 1;
        }
        return unlockedNames;
    }

    
    private static func UnlockVehicle(
        vehicle:      ref<VehicleObject>,
        currentTime:  Float,
        gameInstance: GameInstance
    ) -> Void {
        let vehiclePS: ref<VehicleComponentPS> = vehicle.GetVehiclePS();
        if !IsDefined(vehiclePS) {
            BNWarn("TargetedBreachUtils",
                "Vehicle has no VehicleComponentPS: "
                + EntityID.ToDebugString(vehicle.GetEntityID()));
            return;
        }

        let sharedPS: ref<SharedGameplayPS> = vehiclePS;
        if !IsDefined(sharedPS) {
            BNWarn("TargetedBreachUtils",
                "VehicleComponentPS could not cast to SharedGameplayPS");
            return;
        }


        sharedPS.m_betterNetrunningUnlockTimestampBasic = currentTime;


        if sharedPS.m_bnIceHitsRequired <= 0 { sharedPS.m_bnIceHitsRequired = 1; }
        sharedPS.m_bnIceHitsApplied = sharedPS.m_bnIceHitsRequired;
        sharedPS.m_bnIceDefeated = true;


        let persistency: ref<GamePersistencySystem> =
            GameInstance.GetPersistencySystem(gameInstance);

        let subnetEvt: ref<SetBreachedSubnet> = new SetBreachedSubnet();
        subnetEvt.unlockTimestampBasic   = currentTime;
        subnetEvt.unlockTimestampNPCs    = 0.0;
        subnetEvt.unlockTimestampCameras = 0.0;
        subnetEvt.unlockTimestampTurrets = 0.0;
        persistency.QueuePSEvent(vehiclePS.GetID(), vehiclePS.GetClassName(), subnetEvt);

        BNInfo("TargetedBreachUtils",
            "Vehicle unlocked: " + EntityID.ToDebugString(vehicle.GetEntityID()));
    }

    
    private static func UnlockNPC(
        puppet:      ref<ScriptedPuppet>,
        currentTime: Float,
        persistency: ref<GamePersistencySystem>,
        entityID:    EntityID
    ) -> Void {
        let npcPS: ref<ScriptedPuppetPS> = puppet.GetPuppetPS();
        if !IsDefined(npcPS) {
            BNWarn("TargetedBreachUtils",
                "NPC has no PuppetPS: " + EntityID.ToDebugString(entityID));
            return;
        }


        let deviceLink: ref<SharedGameplayPS> = npcPS.GetDeviceLink();
        if IsDefined(deviceLink) {
            deviceLink.m_betterNetrunningUnlockTimestampNPCs = currentTime;
            BNDebug("TargetedBreachUtils", "NPC DeviceLink timestamp set");
        } else {
            BNDebug("TargetedBreachUtils",
                "NPC is standalone -- no DeviceLink timestamp needed");
        }


        npcPS.BN_StampSJKIBreached();


        if npcPS.m_bnNPCIceHitsRequired <= 0 { npcPS.m_bnNPCIceHitsRequired = 1; }
        npcPS.m_bnNPCIceHitsApplied = npcPS.m_bnNPCIceHitsRequired;
        npcPS.m_bnNPCIceDefeated = true;


        let exposeEvt: ref<SetExposeQuickHacks> = new SetExposeQuickHacks();
        exposeEvt.isRemote = true;
        persistency.QueueEntityEvent(entityID, exposeEvt);

        BNInfo("TargetedBreachUtils",
            "NPC unlocked: " + EntityID.ToDebugString(entityID));
    }

    
    private static func UnlockDevice(
        device:      ref<Device>,
        targetType:  TargetType,
        currentTime: Float,
        persistency: ref<GamePersistencySystem>
    ) -> Void {
        let devicePS: ref<ScriptableDeviceComponentPS> = device.GetDevicePS();
        if !IsDefined(devicePS) {
            BNWarn("TargetedBreachUtils", "Device has no PS");
            return;
        }

        let sharedPS: ref<SharedGameplayPS> = devicePS;
        if !IsDefined(sharedPS) {
            BNWarn("TargetedBreachUtils",
                "Device PS cannot cast to SharedGameplayPS");
            return;
        }


        TimeUtils.SetDeviceUnlockTimestamp(sharedPS, targetType, currentTime);


        if sharedPS.m_bnIceHitsRequired <= 0 { sharedPS.m_bnIceHitsRequired = 1; }
        sharedPS.m_bnIceHitsApplied = sharedPS.m_bnIceHitsRequired;
        sharedPS.m_bnIceDefeated = true;


        let exposeEvt: ref<SetExposeQuickHacks> = new SetExposeQuickHacks();
        exposeEvt.isRemote = true;
        persistency.QueuePSEvent(devicePS.GetID(), devicePS.GetClassName(), exposeEvt);


        let subnetEvt: ref<SetBreachedSubnet> = new SetBreachedSubnet();
        subnetEvt.unlockTimestampBasic   = Equals(targetType, TargetType.Basic)   ? currentTime : 0.0;
        subnetEvt.unlockTimestampNPCs    = Equals(targetType, TargetType.NPC)     ? currentTime : 0.0;
        subnetEvt.unlockTimestampCameras = Equals(targetType, TargetType.Camera)  ? currentTime : 0.0;
        subnetEvt.unlockTimestampTurrets = Equals(targetType, TargetType.Turret)  ? currentTime : 0.0;
        persistency.QueuePSEvent(devicePS.GetID(), devicePS.GetClassName(), subnetEvt);

        BNInfo("TargetedBreachUtils",
            "Device unlocked (" + DeviceTypeUtils.DeviceTypeToString(targetType) + "): "
            + EntityID.ToDebugString(device.GetEntityID()));
    }
}
