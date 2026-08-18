
local SettingsManager = require("settingsManager")
local TweakDBSetup = require("tweakdbSetup")
local NativeSettingsUI = require("nativeSettingsUI")
local RemoteBreach = require("remoteBreach")
local MarkingSystem = require("markingSystem")

registerForEvent("onInit", function()
    print("[Better Netrunning] Initializing...")

    SettingsManager.Load()

    SettingsManager.OverrideConfigFunctions()

    local nativeSettings = GetMod("nativeSettings")
    if nativeSettings then
        NativeSettingsUI.Build(nativeSettings, SettingsManager, TweakDBSetup)
    else
        print("[Better Netrunning] NativeSettings not found")
    end

    TweakDBSetup.SetupAccessPrograms()
    TweakDBSetup.SetupUnconsciousBreach()
    TweakDBSetup.SetupCounterBreachMinigame()
    TweakDBSetup.SetupIcepickVariants()
    TweakDBSetup.SetupAPDaemons()
    TweakDBSetup.SetupSignalNoiseDaemon()
    TweakDBSetup.SetupOffensiveNPCDaemon()
    TweakDBSetup.SetupExitProtocol()
    TweakDBSetup.SetupOffloadProtocol()
    TweakDBSetup.SetupFirewallMinigame()
    TweakDBSetup.SetupCascadeProtocol()
    TweakDBSetup.SetupDaemonIcons()
    TweakDBSetup.ApplyBreachingHotkey(SettingsManager.Get("BreachingHotkey"))

    MarkingSystem.Init()

    local Engine = GetMod('0-Engine')
    if Engine then
        local BN = Engine.Register('BetterNetrunning')

        BN.WhenReady(function()
            NativeSettingsUI.PushHotkeys(SettingsManager)
            MarkingSystem.SetPlayerInControl(true)
        end)

        local function UpdatePlayerInControl()
            local state    = Engine.GetState()
            local tier     = state.blackboard and state.blackboard.psm and state.blackboard.psm.sceneTier or 1
            local inControl = Engine.IsPlaying() and not state.inMenu and tier < 3
            MarkingSystem.SetPlayerInControl(inControl)
        end

        BN.Subscribe('MenuOpen',         function() MarkingSystem.SetPlayerInControl(false) end)
        BN.Subscribe('MenuClose',        function()
            NativeSettingsUI.PushHotkeys(SettingsManager)
            UpdatePlayerInControl()
        end)
        BN.Subscribe('SceneTierChanged', UpdatePlayerInControl)
    else
        print('[Better Netrunning] WARNING: 0-Engine not found -- timers will tick during menus and hotkeys need a reload to apply')
        MarkingSystem.SetPlayerInControl(true)
    end

    if RemoteBreach and RemoteBreach.Setup then
        local success = RemoteBreach.Setup()
        if success then
            print("[Better Netrunning] Remote Breach enabled")
        end
    end
    print("[Better Netrunning] Initialization complete")
end)

registerForEvent("onUpdate", function(deltaTime)
    MarkingSystem.Update(deltaTime)
end)

return true
