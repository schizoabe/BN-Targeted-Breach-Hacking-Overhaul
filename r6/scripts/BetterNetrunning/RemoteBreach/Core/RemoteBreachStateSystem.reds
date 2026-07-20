

module BetterNetrunning.RemoteBreach.Core

import BetterNetrunning.*
import BetterNetrunningConfig.*
import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*

@if(ModuleExists("HackingExtensions"))
import HackingExtensions.*

@if(ModuleExists("HackingExtensions"))
public class DeviceRemoteBreachStateSystem extends ScriptableSystem {
    private let m_currentDevicePS: wref<ScriptableDeviceComponentPS>;
    private let m_availableDaemons: String;
    private let m_breachedDevices: array<EntityID>;

    public func SetCurrentDevice(devicePS: ref<ScriptableDeviceComponentPS>, availableDaemons: String) -> Void {
        this.m_currentDevicePS = devicePS;
        this.m_availableDaemons = availableDaemons;
    }

    public func GetCurrentDevice() -> wref<ScriptableDeviceComponentPS> {
        return this.m_currentDevicePS;
    }

    public func GetAvailableDaemons() -> String {
        return this.m_availableDaemons;
    }

    public func ClearCurrentDevice() -> Void {
        this.m_currentDevicePS = null;
        this.m_availableDaemons = "";
    }

    public func MarkDeviceBreached(deviceID: EntityID) -> Void {
        if !ArrayContains(this.m_breachedDevices, deviceID) {
            ArrayPush(this.m_breachedDevices, deviceID);
        }
    }

    public func IsDeviceBreached(deviceID: EntityID) -> Bool {
        return ArrayContains(this.m_breachedDevices, deviceID);
    }
}


