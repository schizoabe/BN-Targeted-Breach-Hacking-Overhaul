



















module BetterNetrunning.Core

import BetterNetrunningConfig.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Integration.*
import BetterNetrunning.Utils.*


public struct TargetingSetup {
    public let isValid: Bool;
    public let breachRadius: Float;
    public let sourcePos: Vector4;
    public let originType: String;           // "NPC" or "Device"
    public let player: wref<PlayerPuppet>;
    public let targetingSystem: ref<TargetingSystem>;
    public let query: TargetSearchQuery;
}


public struct VehicleProcessResult {
    public let vehicleFound: Bool;
    public let unlocked: Bool;
}


enum NetworkClassification {
    BreachedNetwork = 0,
    CrossNetwork = 1,
    PureStandalone = 2
}






public abstract class EntityUnlockProcessor {

    protected let m_origin: Vector4;
    protected let m_radiusSq: Float;
    protected let m_breachedAPID: PersistentID;
    protected let m_gameInstance: GameInstance;
    protected let m_unlockFlags: BreachUnlockFlags;


    protected let m_standaloneCount: Int32;
    protected let m_crossNetworkCount: Int32;
    protected let m_standaloneUnlocked: Int32;
    protected let m_crossNetworkUnlocked: Int32;

    
    public func Initialize(
        origin: Vector4,
        radiusSq: Float,
        breachedAPID: PersistentID,
        gameInstance: GameInstance,
        unlockFlags: BreachUnlockFlags
    ) -> Void {
        this.m_origin = origin;
        this.m_radiusSq = radiusSq;
        this.m_breachedAPID = breachedAPID;
        this.m_gameInstance = gameInstance;
        this.m_unlockFlags = unlockFlags;

        this.m_standaloneCount = 0;
        this.m_crossNetworkCount = 0;
        this.m_standaloneUnlocked = 0;
        this.m_crossNetworkUnlocked = 0;
    }

    
    public func ProcessEntity(part: TS_TargetPartInfo) -> Void {

        let entity: wref<GameObject>;
        if !DeviceUnlockUtils.ExtractAndValidateEntity(
            part, this.m_origin, this.m_radiusSq, entity
        ) { return; }


        if !this.CastToSpecificType(entity) { return; }


        let classification: NetworkClassification = this.ClassifyNetwork();


        switch classification {
            case NetworkClassification.BreachedNetwork:
                return; // Skip (already processed)
            case NetworkClassification.CrossNetwork:
                this.m_crossNetworkCount += 1;
                if this.ShouldUnlockCrossNetwork() {
                    if this.UnlockEntity() {
                        this.m_crossNetworkUnlocked += 1;
                    }
                }
                break;
            case NetworkClassification.PureStandalone:
                this.m_standaloneCount += 1;
                if this.ShouldUnlockStandalone() {
                    if this.UnlockEntity() {
                        this.m_standaloneUnlocked += 1;
                    }
                }
                break;
        }
    }

    
    protected func CastToSpecificType(entity: wref<GameObject>) -> Bool;

    
    protected func ClassifyNetwork() -> NetworkClassification;

    
    protected func UnlockEntity() -> Bool;

    
    protected func ShouldUnlockCrossNetwork() -> Bool {
        return this.m_unlockFlags.unlockBasic;
    }

    
    protected func ShouldUnlockStandalone() -> Bool {
        return this.m_unlockFlags.unlockBasic;
    }


    public func GetStandaloneCount() -> Int32 { return this.m_standaloneCount; }
    public func GetCrossNetworkCount() -> Int32 { return this.m_crossNetworkCount; }
    public func GetStandaloneUnlocked() -> Int32 { return this.m_standaloneUnlocked; }
    public func GetCrossNetworkUnlocked() -> Int32 { return this.m_crossNetworkUnlocked; }
}


public class DeviceUnlockProcessor extends EntityUnlockProcessor {

    private let m_device: ref<Device>;
    private let m_devicePS: ref<ScriptableDeviceComponentPS>;

    
    protected func CastToSpecificType(entity: wref<GameObject>) -> Bool {

        this.m_device = entity as Device;
        if !IsDefined(this.m_device) { return false; }


        this.m_devicePS = this.m_device.GetDevicePS();
        return IsDefined(this.m_devicePS);
    }

    
    protected func ClassifyNetwork() -> NetworkClassification {
        return DeviceUnlockUtils.ClassifyDeviceNetwork(
            this.m_devicePS,
            this.m_breachedAPID
        );
    }

    
    protected func UnlockEntity() -> Bool {
        return DeviceUnlockUtils.UnlockDeviceInRadius(
            this.m_devicePS,
            this.m_unlockFlags,
            this.m_gameInstance
        );
    }
}


public class VehicleUnlockProcessor extends EntityUnlockProcessor {

    private let m_vehicle: ref<VehicleObject>;

    
    protected func CastToSpecificType(entity: wref<GameObject>) -> Bool {
        this.m_vehicle = entity as VehicleObject;
        return IsDefined(this.m_vehicle);
    }

    
    protected func ClassifyNetwork() -> NetworkClassification {

        return NetworkClassification.PureStandalone;
    }

    
    protected func UnlockEntity() -> Bool {
        return DeviceUnlockUtils.TryUnlockVehicle(
            this.m_vehicle,
            this.m_gameInstance
        );
    }
}


public class NPCUnlockProcessor extends EntityUnlockProcessor {

    private let m_puppet: ref<ScriptedPuppet>;
    private let m_npcPS: ref<ScriptedPuppetPS>;

    
    protected func CastToSpecificType(entity: wref<GameObject>) -> Bool {

        this.m_puppet = entity as ScriptedPuppet;
        if !IsDefined(this.m_puppet) { return false; }


        this.m_npcPS = this.m_puppet.GetPS();
        return IsDefined(this.m_npcPS);
    }

    
    protected func ClassifyNetwork() -> NetworkClassification {
        return DeviceUnlockUtils.ClassifyNPCNetwork(
            this.m_puppet,
            this.m_breachedAPID,
            this.m_gameInstance
        );
    }

    
    protected func UnlockEntity() -> Bool {
        return DeviceUnlockUtils.UnlockStandaloneNPC(this.m_puppet);
    }

    
    protected func ShouldUnlockCrossNetwork() -> Bool {
        return this.m_unlockFlags.unlockNPCs && BetterNetrunningSettings.RadialUnlockCrossNetwork();
    }

    
    protected func ShouldUnlockStandalone() -> Bool {
        return this.m_unlockFlags.unlockNPCs;
    }
}

public abstract class DeviceUnlockUtils {




    
    public static func ProcessNPCsInRadius(
        devicePS: ref<ScriptableDeviceComponentPS>,
        breachedAPID: PersistentID,
        unlockFlags: BreachUnlockFlags,
        out npcPureStandaloneCount: Int32,
        out npcCrossNetworkCount: Int32,
        out npcPureStandaloneUnlocked: Int32,
        out npcCrossNetworkUnlocked: Int32,
        gameInstance: GameInstance
    ) -> Void {
        npcPureStandaloneCount = 0;
        npcCrossNetworkCount = 0;
        npcPureStandaloneUnlocked = 0;
        npcCrossNetworkUnlocked = 0;


        let deviceEntity: wref<GameObject> = devicePS.GetOwnerEntityWeak() as GameObject;
        if !IsDefined(deviceEntity) {
            return;
        }


        let origin: Vector4 = deviceEntity.GetWorldPosition();
        let radius: Float = GetRadialBreachRange(gameInstance);
        let radiusSq: Float = radius * radius;


        let player: wref<PlayerPuppet> = GetPlayer(gameInstance);
        if !IsDefined(player) { return; }

        let targetingSystem: ref<TargetingSystem> = GameInstance.GetTargetingSystem(gameInstance);
        if !IsDefined(targetingSystem) { return; }

        let query: TargetSearchQuery;
        query.searchFilter = TSF_And(TSF_All(TSFMV.Obj_Puppet), TSF_Not(TSFMV.Obj_Player));
        query.testedSet = TargetingSet.Complete;
        query.maxDistance = radius * 2.0;
        query.filterObjectByDistance = true;
        query.includeSecondaryTargets = false;
        query.ignoreInstigator = true;

        let parts: array<TS_TargetPartInfo>;
        targetingSystem.GetTargetParts(player, query, parts);


        let processor: ref<NPCUnlockProcessor> = new NPCUnlockProcessor();
        processor.Initialize(origin, radiusSq, breachedAPID, gameInstance, unlockFlags);


        let i: Int32 = ArraySize(parts) - 1;
        while i >= 0 {
            processor.ProcessEntity(parts[i]);
            i -= 1;
        }


        npcPureStandaloneCount = processor.GetStandaloneCount();
        npcCrossNetworkCount = processor.GetCrossNetworkCount();
        npcPureStandaloneUnlocked = processor.GetStandaloneUnlocked();
        npcCrossNetworkUnlocked = processor.GetCrossNetworkUnlocked();
    }





    
    public static func SetupDeviceTargeting(sourceEntity: wref<GameObject>, gameInstance: GameInstance) -> TargetingSetup {
        let setup: TargetingSetup;
        setup.isValid = false;
        setup.breachRadius = GetRadialBreachRange(gameInstance);


        let minigameBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gameInstance)
            .Get(GetAllBlackboardDefs().HackingMinigame);
        let breachEntity: wref<Entity> = FromVariant<wref<Entity>>(
            minigameBB.GetVariant(GetAllBlackboardDefs().HackingMinigame.Entity)
        );
        let npcPuppet: wref<ScriptedPuppet> = breachEntity as ScriptedPuppet;

        if IsDefined(npcPuppet) {

            setup.sourcePos = npcPuppet.GetWorldPosition();
            setup.originType = "NPC";
        } else {

            setup.sourcePos = sourceEntity.GetWorldPosition();
            setup.originType = "Device";
        }

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


    private static func SetupVehicleTargeting(devicePS: ref<ScriptableDeviceComponentPS>, gameInstance: GameInstance) -> TargetingSetup {
        let setup: TargetingSetup;
        setup.isValid = false;

        let deviceEntity: wref<GameObject> = devicePS.GetOwnerEntityWeak() as GameObject;
        if !IsDefined(deviceEntity) {
            BNError("DeviceUnlockUtils", "deviceEntity not defined");
            return setup;
        }

        setup.sourcePos = deviceEntity.GetWorldPosition();
        setup.breachRadius = GetRadialBreachRange(gameInstance);

        setup.player = GetPlayer(gameInstance);
        if !IsDefined(setup.player) {
            BNError("DeviceUnlockUtils", "player not defined");
            return setup;
        }

        setup.targetingSystem = GameInstance.GetTargetingSystem(gameInstance);
        if !IsDefined(setup.targetingSystem) {
            BNError("DeviceUnlockUtils", "targetingSystem not defined");
            return setup;
        }

        setup.query.testedSet = TargetingSet.Complete;
        setup.query.maxDistance = setup.breachRadius;
        setup.query.filterObjectByDistance = true;
        setup.query.includeSecondaryTargets = false;
        setup.query.ignoreInstigator = true;

        setup.isValid = true;
        return setup;
    }





    
    private static func ExtractAndValidateEntity(
        part: TS_TargetPartInfo,
        sourcePos: Vector4,
        breachRadius: Float,
        out entity: wref<GameObject>
    ) -> Bool {

        entity = TS_TargetPartInfo.GetComponent(part).GetEntity() as GameObject;
        if !IsDefined(entity) {
            return false;
        }


        let targetPos: Vector4 = entity.GetWorldPosition();
        let distance: Float = Vector4.Distance(sourcePos, targetPos);
        if distance > breachRadius {
            return false;
        }

        return true;
    }

    
    private static func ClassifyDeviceNetwork(
        sharedPS: ref<SharedGameplayPS>,
        breachedAPID: PersistentID
    ) -> NetworkClassification {
        if DeviceUnlockUtils.IsConnectedToBreachedNetwork(sharedPS, breachedAPID) {
            return NetworkClassification.BreachedNetwork;
        } else if ArraySize(sharedPS.GetAccessPoints()) > 0 {
            return NetworkClassification.CrossNetwork;
        }
        return NetworkClassification.PureStandalone;
    }

    
    private static func ClassifyNPCNetwork(
        puppet: ref<ScriptedPuppet>,
        breachedAPID: PersistentID,
        gameInstance: GameInstance
    ) -> NetworkClassification {
        let npcPS: ref<ScriptedPuppetPS> = puppet.GetPS();
        if !IsDefined(npcPS) {
            return NetworkClassification.PureStandalone;
        }

        let deviceLink: ref<PuppetDeviceLinkPS> = npcPS.GetDeviceLink();
        if !IsDefined(deviceLink) {
            return NetworkClassification.PureStandalone;
        } else if !DeviceUnlockUtils.IsNPCConnectedToBreachedNetwork(puppet, breachedAPID, gameInstance) {
            return NetworkClassification.CrossNetwork;
        }

        return NetworkClassification.BreachedNetwork;
    }

    
    private static func UnlockNetworkNPC(puppetLink: ref<PuppetDeviceLinkPS>) -> Bool {
        if !IsDefined(puppetLink) {
            return false;
        }

        let npcObject: wref<GameObject> = puppetLink.GetOwnerEntityWeak() as GameObject;
        if !IsDefined(npcObject) {
            return false;
        }

        let puppet: ref<ScriptedPuppet> = npcObject as ScriptedPuppet;
        if !IsDefined(puppet) {
            return false;
        }

        let npcPS: ref<ScriptedPuppetPS> = puppet.GetPS();
        if !IsDefined(npcPS) {
            return false;
        }


        let exposeEvent: ref<SetExposeQuickHacks> = new SetExposeQuickHacks();
        exposeEvent.isRemote = true;
        npcPS.GetPersistencySystem().QueueEntityEvent(PersistentID.ExtractEntityID(npcPS.GetID()), exposeEvent);

        return true;
    }

    
    private static func UnlockStandaloneNPC(puppet: ref<ScriptedPuppet>) -> Bool {
        if !IsDefined(puppet) {
            return false;
        }

        let npcPS: ref<ScriptedPuppetPS> = puppet.GetPS();
        if !IsDefined(npcPS) {
            return false;
        }


        let exposeEvent: ref<SetExposeQuickHacks> = new SetExposeQuickHacks();
        exposeEvent.isRemote = true;
        npcPS.GetPersistencySystem().QueueEntityEvent(PersistentID.ExtractEntityID(npcPS.GetID()), exposeEvent);

        return true;
    }

    
    private static func ShouldApplyCrossNetworkFilter(sharedPS: ref<SharedGameplayPS>) -> Bool {
        if !IsDefined(sharedPS) {
            return true;  // Filter out invalid devices
        }


        if BetterNetrunningSettings.RadialUnlockCrossNetwork() {
            return false;  // Cross-Network enabled, don't filter
        }


        let apControllers: array<ref<AccessPointControllerPS>> = sharedPS.GetAccessPoints();
        if ArraySize(apControllers) > 0 {
            return true;  // Network-connected device, filter out
        }

        return false;  // Standalone device, don't filter
    }

    
    private static func IsConnectedToBreachedNetwork(
        sharedPS: ref<SharedGameplayPS>,
        breachedAPID: PersistentID
    ) -> Bool {
        if !IsDefined(sharedPS) {
            return false;
        }


        let apControllers: array<ref<AccessPointControllerPS>> = sharedPS.GetAccessPoints();
        let idx: Int32 = 0;
        while idx < ArraySize(apControllers) {
            if PersistentID.IsDefined(apControllers[idx].GetID()) && PersistentID.IsDefined(breachedAPID) {
                if Equals(apControllers[idx].GetID(), breachedAPID) {
                    return true;  // Device belongs to breached network
                }
            }
            idx += 1;
        }

        return false;  // Device not connected to breached network
    }

    
    private static func UnlockDeviceInRadius(
        devicePS: ref<ScriptableDeviceComponentPS>,
        unlockFlags: BreachUnlockFlags,
        gameInstance: GameInstance
    ) -> Bool {
        let sharedPS: ref<SharedGameplayPS> = devicePS;
        if !IsDefined(sharedPS) {
            return false;
        }


        if DeviceUnlockUtils.ShouldApplyCrossNetworkFilter(sharedPS) {
            return false;
        }


        let deviceType: TargetType = DeviceTypeUtils.GetDeviceType(devicePS);


        if !DeviceTypeUtils.ShouldUnlockByFlags(deviceType, unlockFlags) {
            return false;  // Device type not in unlockFlags, skip
        }


        let currentTimestamp: Float = 0.0;
        if Equals(deviceType, TargetType.Camera) {
            currentTimestamp = sharedPS.m_betterNetrunningUnlockTimestampCameras;
        } else if Equals(deviceType, TargetType.Turret) {
            currentTimestamp = sharedPS.m_betterNetrunningUnlockTimestampTurrets;
        } else {
            currentTimestamp = sharedPS.m_betterNetrunningUnlockTimestampBasic;
        }

        if currentTimestamp > 0.0 {
            return false;  // Already unlocked, skip
        }


        let newTimestamp: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
        if Equals(deviceType, TargetType.Camera) {
            sharedPS.m_betterNetrunningUnlockTimestampCameras = newTimestamp;
        } else if Equals(deviceType, TargetType.Turret) {
            sharedPS.m_betterNetrunningUnlockTimestampTurrets = newTimestamp;
        } else {
            sharedPS.m_betterNetrunningUnlockTimestampBasic = newTimestamp;
        }

        return true;
    }





    
    public static func ProcessEntityInRadius(
        parts: array<TS_TargetPartInfo>,
        origin: Vector4,
        radiusSq: Float,
        breachedAPID: PersistentID,
        gameInstance: GameInstance,
        unlockFlags: BreachUnlockFlags,
        out standaloneCount: Int32,
        out crossNetworkCount: Int32,
        out standaloneUnlocked: Int32,
        out crossNetworkUnlocked: Int32
    ) -> Void {

        let deviceProcessor: ref<DeviceUnlockProcessor> = new DeviceUnlockProcessor();
        deviceProcessor.Initialize(origin, radiusSq, breachedAPID, gameInstance, unlockFlags);


        let vehicleProcessor: ref<VehicleUnlockProcessor> = new VehicleUnlockProcessor();
        vehicleProcessor.Initialize(origin, radiusSq, breachedAPID, gameInstance, unlockFlags);


        let i: Int32 = ArraySize(parts) - 1;
        while i >= 0 {
            deviceProcessor.ProcessEntity(parts[i]);
            vehicleProcessor.ProcessEntity(parts[i]);
            i -= 1;
        }


        standaloneCount = deviceProcessor.GetStandaloneCount() + vehicleProcessor.GetStandaloneCount();
        crossNetworkCount = deviceProcessor.GetCrossNetworkCount() + vehicleProcessor.GetCrossNetworkCount();
        standaloneUnlocked = deviceProcessor.GetStandaloneUnlocked() + vehicleProcessor.GetStandaloneUnlocked();
        crossNetworkUnlocked = deviceProcessor.GetCrossNetworkUnlocked() + vehicleProcessor.GetCrossNetworkUnlocked();
    }


    private static func TryUnlockVehicle(
        vehicle: ref<VehicleObject>,
        gameInstance: GameInstance
    ) -> Bool {
        let vehPS: ref<VehicleComponentPS> = vehicle.GetVehiclePS();
        if !IsDefined(vehPS) {
            BNError("DeviceUnlockUtils", "VehiclePS not defined for vehicle");
            return false;
        }

        let vehSharedPS: ref<SharedGameplayPS> = vehPS;
        if !IsDefined(vehSharedPS) {
            BNError("DeviceUnlockUtils", "vehSharedPS cast failed");
            return false;
        }

        let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);
        vehSharedPS.m_betterNetrunningUnlockTimestampBasic = currentTime;
        return true;
    }

    
    public static func ApplyTimestampUnlock(
        device: ref<DeviceComponentPS>,
        gameInstance: GameInstance,
        unlockBasic: Bool,
        unlockNPCs: Bool,
        unlockCameras: Bool,
        unlockTurrets: Bool
    ) -> Void {
        let sharedPS: ref<SharedGameplayPS> = device as SharedGameplayPS;
        if !IsDefined(sharedPS) {
            return;
        }

        let deviceType: TargetType = DeviceTypeUtils.GetDeviceType(device);
        let currentTime: Float = TimeUtils.GetCurrentTimestamp(gameInstance);

        switch deviceType {
            case TargetType.NPC:
                if unlockNPCs {
                    sharedPS.m_betterNetrunningUnlockTimestampNPCs = currentTime;
                }
                break;
            case TargetType.Camera:
                if unlockCameras {
                    sharedPS.m_betterNetrunningUnlockTimestampCameras = currentTime;
                }
                break;
            case TargetType.Turret:
                if unlockTurrets {
                    sharedPS.m_betterNetrunningUnlockTimestampTurrets = currentTime;
                }
                break;
            default: // TargetType.Basic
                if unlockBasic {
                    sharedPS.m_betterNetrunningUnlockTimestampBasic = currentTime;
                }
                break;
        }
    }





    
    private static func CollectNetworkNPCsFromAccessPoint(
        accessPoint: ref<AccessPointControllerPS>,
        origin: Vector4,
        radius: Float,
        out processedIDs: array<PersistentID>
    ) -> Void {

        if !IsDefined(accessPoint) { return; }


        let puppets: array<ref<PuppetDeviceLinkPS>> = accessPoint.GetPuppets();

        let i: Int32 = 0;
        while i < ArraySize(puppets) {
            let puppetLink: ref<PuppetDeviceLinkPS> = puppets[i];


            if IsDefined(puppetLink) && puppetLink.IsConnected() {

                let npcObject: wref<GameObject> = puppetLink.GetOwnerEntityWeak() as GameObject;
                if IsDefined(npcObject) && npcObject.IsActive() {

                    let npcPos: Vector4 = npcObject.GetWorldPosition();
                    let distance: Float = Vector4.Distance(origin, npcPos);
                    if distance <= radius {

                        ArrayPush(processedIDs, puppetLink.GetID());
                    }
                }
            }

            i += 1;
        }
    }

    
    private static func IsNPCConnectedToBreachedNetwork(
        npc: ref<ScriptedPuppet>,
        breachedAPID: PersistentID,
        gameInstance: GameInstance
    ) -> Bool {
        let npcPS: ref<ScriptedPuppetPS> = npc.GetPS();
        if !IsDefined(npcPS) {
            return false;
        }


        let deviceLink: ref<PuppetDeviceLinkPS> = npcPS.GetDeviceLink();
        if !IsDefined(deviceLink) {
            return false;  // Standalone NPC (no network connection)
        }


        let sharedPS: ref<SharedGameplayPS> = deviceLink;
        if !IsDefined(sharedPS) {
            return false;
        }


        return DeviceUnlockUtils.IsConnectedToBreachedNetwork(sharedPS, breachedAPID);
    }

}


