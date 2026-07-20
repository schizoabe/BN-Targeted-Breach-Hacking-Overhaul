






local SettingsManager = require("settingsManager")
local TweakDBSetup = require("tweakdbSetup")
local NativeSettingsUI = require("nativeSettingsUI")
local RemoteBreach = require("remoteBreach")
local MarkingSystem = require("markingSystem")


registerHotkey("BN_ClearMarks",              "[BN] Clear All Marks",                              function() MarkingSystem.HK_ClearMarks() end)
registerHotkey("BN_HideWidgets",             "[BN] Hide HUD Widgets",                             function() MarkingSystem.HK_HideWidgets() end)
registerHotkey("BN_ShowNetworkStatus",       "[BN] Show Network Status",                          function() MarkingSystem.HK_ShowNetworkStatus() end)
registerHotkey("BN_ForceJackOut",            "[BN] Force Jack-Out (rescue)",                      function() MarkingSystem.HK_ForceJackOut() end)
registerHotkey("BN_DEV_TriggerCounterBreach","[BN DEV] Trigger Counter-Breach",                   function() MarkingSystem.HK_DEV_TriggerCounterBreach() end)
registerHotkey("BN_DEV_PrintHeat",           "[BN DEV] Print session heat",                       function() MarkingSystem.HK_DEV_PrintHeat() end)
registerHotkey("BN_DEV_PrintICEState",       "[BN DEV] Print ICE state",                          function() MarkingSystem.HK_DEV_PrintICEState() end)
registerHotkey("BN_DEV_CheckCyberdeck",      "[BN DEV] Check cyberdeck slot",                     function() MarkingSystem.HK_DEV_CheckCyberdeck() end)
registerHotkey("BN_DEV_ShowTestPanel",       "[BN DEV] Toggle HUD Panels (Network Status + ICE Log)", function() MarkingSystem.HK_DEV_ShowTestPanel() end)


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
    TweakDBSetup.SetupDaemonIcons()
    TweakDBSetup.ApplyBreachingHotkey(SettingsManager.Get("BreachingHotkey"))

    MarkingSystem.Init()


    local GameplayState = GetMod('GameplayState')
    if GameplayState then
        GameplayState.OnStateChange(function(inControl)
            MarkingSystem.SetPlayerInControl(inControl)
        end, 'BetterNetrunning')
    else
        print('[Better Netrunning] WARNING: GameplayState mod not found -- timers will tick during menus')
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

