
















module BetterNetrunning.Logging

import BetterNetrunning.*
import BetterNetrunning.Core.*
import BetterNetrunning.Minigame.*
import BetterNetrunning.Utils.*
import BetterNetrunning.Logging.*

public abstract class BreachStatisticsCollector {




    
    public static func CollectNetworkDeviceStats(
        networkDevices: array<ref<DeviceComponentPS>>,
        unlockFlags: BreachUnlockFlags,
        stats: ref<BreachSessionStats>
    ) -> Void {

        stats.networkDeviceCount = ArraySize(networkDevices);


        if ArraySize(networkDevices) == 0 {
            return;
        }


        let i: Int32 = 0;
        while i < ArraySize(networkDevices) {
            let device: ref<DeviceComponentPS> = networkDevices[i];


            if IsDefined(device) {
                BreachStatisticsCollector.ProcessNetworkDevice(device, unlockFlags, stats);
            }

            i += 1;
        }
    }





    
    private static func ProcessNetworkDevice(
        device: ref<DeviceComponentPS>,
        unlockFlags: BreachUnlockFlags,
        stats: ref<BreachSessionStats>
    ) -> Void {

        let TargetType: TargetType = DeviceTypeUtils.GetDeviceType(device);


        let shouldUnlock: Bool = DeviceTypeUtils.ShouldUnlockByFlags(TargetType, unlockFlags);


        if DeviceTypeUtils.IsCameraDevice(device) {
            stats.cameraCount += 1;
            if shouldUnlock {
                stats.cameraUnlocked += 1;
            } else {
                stats.cameraSkipped += 1;
            }
        } else if DeviceTypeUtils.IsTurretDevice(device) {
            stats.turretCount += 1;
            if shouldUnlock {
                stats.turretUnlocked += 1;
            } else {
                stats.turretSkipped += 1;
            }
        } else if DeviceTypeUtils.IsNPCDevice(device) {
            stats.npcNetworkCount += 1;
            if shouldUnlock {
                stats.npcNetworkUnlocked += 1;
            } else {
                stats.npcNetworkSkipped += 1;
            }
        } else {
            stats.basicCount += 1;
            if shouldUnlock {
                stats.basicUnlocked += 1;
            } else {
                stats.basicSkipped += 1;
            }
        }


        if shouldUnlock {
            stats.devicesUnlocked += 1;
        } else {
            stats.devicesSkipped += 1;
        }
    }





    
    public static func CollectDisplayedDaemons(
        minigamePrograms: array<TweakDBID>,
        stats: ref<BreachSessionStats>
    ) -> Void {
        let i: Int32 = 0;
        while i < ArraySize(minigamePrograms) {
            let programID: TweakDBID = minigamePrograms[i];

            if DaemonFilterUtils.IsSubnetDaemon(programID) {
                ArrayPush(stats.displayedSubnetDaemons, programID);
            } else {
                ArrayPush(stats.displayedNormalDaemons, programID);
            }

            i += 1;
        }
    }

    
    public static func CollectExecutedDaemons(
        minigamePrograms: array<TweakDBID>,
        stats: ref<BreachSessionStats>
    ) -> Void {
        let i: Int32 = 0;
        while i < ArraySize(minigamePrograms) {
            let programID: TweakDBID = minigamePrograms[i];


            if BonusDaemonUtils.IsDatamineDaemon(programID) {
                ArrayPush(stats.executedBonusDaemons, programID);
                i += 1;
            } else if DaemonFilterUtils.IsSubnetDaemon(programID) {
                ArrayPush(stats.executedSubnetDaemons, programID);
                i += 1;
            } else {
                ArrayPush(stats.executedNormalDaemons, programID);
                i += 1;
            }
        }
    }
}








public class DisplayedDaemonsStateSystem extends ScriptableSystem {
    private let m_displayedDaemons: array<TweakDBID>;

    public func SetDisplayedDaemons(daemons: array<TweakDBID>) -> Void {
        ArrayClear(this.m_displayedDaemons);
        let i: Int32 = 0;
        while i < ArraySize(daemons) {
            ArrayPush(this.m_displayedDaemons, daemons[i]);
            i += 1;
        }
    }

    public func GetDisplayedDaemons() -> array<TweakDBID> {
        return this.m_displayedDaemons;
    }

    public func ClearDisplayedDaemons() -> Void {
        ArrayClear(this.m_displayedDaemons);
    }
}

