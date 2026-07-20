





local TweakDBSetup = {}


function TweakDBSetup.SetupAccessPrograms()
    TweakDBSetup.CreateAccessProgram(
        "NetworkBasicAccess",
        "UnlockQuickhacks",
        LocKey("Better-Netrunning-Basic-Access-Name"),
        LocKey("Better-Netrunning-Basic-Access-Description"),
        "ChoiceCaptionParts.BreachProtocolIcon",
        20.0
    )

    TweakDBSetup.CreateAccessProgram(
        "NetworkNPCAccess",
        "UnlockNPCQuickhacks",
        LocKey("Better-Netrunning-NPC-Access-Name"),
        LocKey("Better-Netrunning-NPC-Access-Description"),
        "ChoiceCaptionParts.PingIcon",
        60.0
    )

    TweakDBSetup.CreateAccessProgram(
        "NetworkCameraAccess",
        "UnlockCameraQuickhacks",
        LocKey("Better-Netrunning-Camera-Access-Name"),
        LocKey("Better-Netrunning-Camera-Access-Description"),
        "ChoiceCaptionParts.CameraShutdownIcon",
        40.0
    )

    TweakDBSetup.CreateAccessProgram(
        "NetworkTurretAccess",
        "UnlockTurretQuickhacks",
        LocKey("Better-Netrunning-Turret-Access-Name"),
        LocKey("Better-Netrunning-Turret-Access-Description"),
        "ChoiceCaptionParts.TurretShutdownIcon",
        70.0
    )

    print("[Better Netrunning] Access Programs configured")
end


function TweakDBSetup.CreateAccessProgram(interactionName, actionName, caption, description, icon, complexity)

    TweakDB:CloneRecord("Interactions."..interactionName, "Interactions.NetworkGainAccessProgram")
    TweakDB:SetFlat("Interactions."..interactionName..".caption", caption)
    TweakDB:SetFlat("Interactions."..interactionName..".captionIcon", icon)
    TweakDB:SetFlat("Interactions."..interactionName..".description", description)


    TweakDB:CloneRecord("MinigameAction."..actionName, "MinigameAction.NetworkLowerICEMajor")
    TweakDB:SetFlat("MinigameAction."..actionName..".objectActionType", "ObjectActionType.MinigameUpload")
    TweakDB:SetFlat("MinigameAction."..actionName..".objectActionUI", "Interactions."..interactionName)
    TweakDB:SetFlat("MinigameAction."..actionName..".completionEffects", {})
    TweakDB:SetFlat("MinigameAction."..actionName..".complexity", complexity)
    TweakDB:SetFlat("MinigameAction."..actionName..".type", "MinigameAction.Both")
end



function TweakDBSetup.SetupUnconsciousBreach()
    TweakDB:SetFlat("Takedown.BreachUnconsciousOfficer.instigatorPrereqs", {
        "QuickHack.RemoteBreach_inline0",
        "QuickHack.QuickHack_inline3",
        "Takedown.GeneralStateChecks",
        "Takedown.IsPlayerInExploration",
        "Takedown.IsPlayerInAcceptableGroundLocomotionState",
        "Takedown.PlayerNotInSafeZone",
        "Takedown.GameplayRestrictions",
        "Takedown.BreachUnconsciousOfficer_inline0",
        "Takedown.BreachUnconsciousOfficer_inline1",
        "Takedown.BreachUnconsciousOfficer_inline2"
    })


    TweakDB:SetFlat("Takedown.BreachUnconsciousOfficer.targetActivePrereqs", {
        "Prereqs.QuickHackUploadingPrereq"
    })

    TweakDB:SetFlat("Takedown.BreachUnconsciousOfficer.targetPrereqs", {
        "Takedown.BreachUnconsciousOfficer_inline4"
    })

    TweakDB:SetFlat("Takedown.BreachUnconsciousOfficer.startEffects", {
        "QuickHack.QuickHack_inline12",
        "QuickHack.QuickHack_inline13"
    })




    TweakDB:SetFlat("Takedown.BreachUnconsciousOfficer.completionEffects", {})

    TweakDB:SetFlat("Takedown.BreachUnconsciousOfficer.actionName", "RemoteBreach")
    TweakDB:SetFlat("Takedown.BreachUnconsciousOfficer.activationTime", {})

    print("[Better Netrunning] Unconscious Breach configured (no network gate)")
end


function TweakDBSetup.ApplyBreachingHotkey(hotkey)
    local map = {[1] = "Choice1", [2] = "Choice2", [3] = "Choice3", [4] = "Choice4"}
    local idx = hotkey or 3
    if map[idx] == nil then idx = 3 end
    TweakDB:SetFlat("Interactions.BreachUnconsciousOfficer.action", map[idx])
end



function TweakDBSetup.SetupCounterBreachMinigame()

    TweakDB:CloneRecord("Interactions.NetworkCounterBreachICE", "Interactions.NetworkGainAccessProgram")
    TweakDB:SetFlat("Interactions.NetworkCounterBreachICE.caption",
        LocKey("Better-Netrunning-Counter-Breach-ICE-Name"))
    TweakDB:SetFlat("Interactions.NetworkCounterBreachICE.description",
        LocKey("Better-Netrunning-Counter-Breach-ICE-Description"))


    TweakDB:CloneRecord("MinigameAction.BNCounterBreachICE", "MinigameAction.NetworkLowerICEMajor")
    TweakDB:SetFlat("MinigameAction.BNCounterBreachICE.objectActionUI", "Interactions.NetworkCounterBreachICE")
    TweakDB:SetFlat("MinigameAction.BNCounterBreachICE.completionEffects", {})


    TweakDB:CloneRecord("MinigameProgram.BNCounterBreach", "minigame_v2.DefaultItemMinigame_inline0")
    TweakDB:SetFlat("MinigameProgram.BNCounterBreach.program", "MinigameAction.BNCounterBreachICE")
    TweakDB:SetFlat("MinigameProgram.BNCounterBreach.charactersChain", {-1, -1, -1, -1, -1})


    TweakDB:CloneRecord("CustomHackingSystemMinigame.BNCounterBreach", "minigame_v2.DefaultMinigame")
    TweakDB:SetFlat("CustomHackingSystemMinigame.BNCounterBreach.timeLimit", 12.0)
    TweakDB:SetFlat("CustomHackingSystemMinigame.BNCounterBreach.gridSize", 5)
    TweakDB:SetFlat("CustomHackingSystemMinigame.BNCounterBreach.bufferSize", 5)
    TweakDB:SetFlat("CustomHackingSystemMinigame.BNCounterBreach.extraDifficulty", 20)
    TweakDB:SetFlat("CustomHackingSystemMinigame.BNCounterBreach.overrideProgramsList",
        {"MinigameProgram.BNCounterBreach"})
    TweakDB:SetFlat("CustomHackingSystemMinigame.BNCounterBreach.forbiddenProgramsList", {})

    print("[Better Netrunning] Counter-Breach minigame configured")
end








function TweakDBSetup.SetupIcepickVariants()

    TweakDB:CloneRecord("Interactions.BNIcepickV1", "Interactions.NetworkGainAccessProgram")
    TweakDB:SetFlat("Interactions.BNIcepickV1.caption",
        LocKey("Better-Netrunning-Icepick-V1-Name"))
    TweakDB:SetFlat("Interactions.BNIcepickV1.description",
        LocKey("Better-Netrunning-Icepick-V1-Description"))

    TweakDB:CloneRecord("MinigameAction.BNIcepickV1", "MinigameAction.NetworkLowerICEMedium")
    TweakDB:SetFlat("MinigameAction.BNIcepickV1.objectActionUI",  "Interactions.BNIcepickV1")
    TweakDB:SetFlat("MinigameAction.BNIcepickV1.completionEffects", {})
    TweakDB:SetFlat("MinigameAction.BNIcepickV1.type",            "MinigameAction.Both")
    TweakDB:SetFlat("MinigameAction.BNIcepickV1.complexity",      20.0)


    TweakDB:CloneRecord("Interactions.BNIcepickV2", "Interactions.NetworkGainAccessProgram")
    TweakDB:SetFlat("Interactions.BNIcepickV2.caption",
        LocKey("Better-Netrunning-Icepick-V2-Name"))
    TweakDB:SetFlat("Interactions.BNIcepickV2.description",
        LocKey("Better-Netrunning-Icepick-V2-Description"))

    TweakDB:CloneRecord("MinigameAction.BNIcepickV2", "MinigameAction.NetworkLowerICEMedium")
    TweakDB:SetFlat("MinigameAction.BNIcepickV2.objectActionUI",  "Interactions.BNIcepickV2")
    TweakDB:SetFlat("MinigameAction.BNIcepickV2.completionEffects", {})
    TweakDB:SetFlat("MinigameAction.BNIcepickV2.type",            "MinigameAction.Both")
    TweakDB:SetFlat("MinigameAction.BNIcepickV2.complexity",      40.0)


    TweakDB:CloneRecord("Interactions.BNIcepickV3", "Interactions.NetworkGainAccessProgram")
    TweakDB:SetFlat("Interactions.BNIcepickV3.caption",
        LocKey("Better-Netrunning-Icepick-V3-Name"))
    TweakDB:SetFlat("Interactions.BNIcepickV3.description",
        LocKey("Better-Netrunning-Icepick-V3-Description"))

    TweakDB:CloneRecord("MinigameAction.BNIcepickV3", "MinigameAction.NetworkLowerICEMajor")
    TweakDB:SetFlat("MinigameAction.BNIcepickV3.objectActionUI",  "Interactions.BNIcepickV3")
    TweakDB:SetFlat("MinigameAction.BNIcepickV3.completionEffects", {})
    TweakDB:SetFlat("MinigameAction.BNIcepickV3.type",            "MinigameAction.Both")
    TweakDB:SetFlat("MinigameAction.BNIcepickV3.complexity",      70.0)

    print("[Better Netrunning] Icepick variants configured (V1/V2/V3)")
end







function TweakDBSetup.SetupAPDaemons()

    TweakDB:CloneRecord("Interactions.BNHidePresence", "Interactions.NetworkGainAccessProgram")
    TweakDB:SetFlat("Interactions.BNHidePresence.caption",
        LocKey("Better-Netrunning-HidePresence-Name"))
    TweakDB:SetFlat("Interactions.BNHidePresence.description",
        LocKey("Better-Netrunning-HidePresence-Description"))

    TweakDB:CloneRecord("MinigameAction.BNHidePresence", "MinigameAction.NetworkLowerICEMajor")
    TweakDB:SetFlat("MinigameAction.BNHidePresence.objectActionUI",  "Interactions.BNHidePresence")
    TweakDB:SetFlat("MinigameAction.BNHidePresence.completionEffects", {})
    TweakDB:SetFlat("MinigameAction.BNHidePresence.type",            "MinigameAction.AccessPoint")
    TweakDB:SetFlat("MinigameAction.BNHidePresence.complexity",      70.0)


    TweakDB:CloneRecord("Interactions.BNDisarmICE", "Interactions.NetworkGainAccessProgram")
    TweakDB:SetFlat("Interactions.BNDisarmICE.caption",
        LocKey("Better-Netrunning-DisarmICE-Name"))
    TweakDB:SetFlat("Interactions.BNDisarmICE.description",
        LocKey("Better-Netrunning-DisarmICE-Description"))

    TweakDB:CloneRecord("MinigameAction.BNDisarmICE", "MinigameAction.NetworkLowerICEMajor")
    TweakDB:SetFlat("MinigameAction.BNDisarmICE.objectActionUI",  "Interactions.BNDisarmICE")
    TweakDB:SetFlat("MinigameAction.BNDisarmICE.completionEffects", {})
    TweakDB:SetFlat("MinigameAction.BNDisarmICE.type",            "MinigameAction.AccessPoint")
    TweakDB:SetFlat("MinigameAction.BNDisarmICE.complexity",      70.0)

    print("[Better Netrunning] AP daemons configured (HidePresence/DisarmICE)")
end






function TweakDBSetup.SetupSignalNoiseDaemon()
    TweakDB:CloneRecord("Interactions.BNSignalNoise", "Interactions.NetworkGainAccessProgram")
    TweakDB:SetFlat("Interactions.BNSignalNoise.caption",
        LocKey("Better-Netrunning-SignalNoise-Name"))
    TweakDB:SetFlat("Interactions.BNSignalNoise.description",
        LocKey("Better-Netrunning-SignalNoise-Description"))

    TweakDB:CloneRecord("MinigameAction.BNSignalNoise", "MinigameAction.NetworkLowerICEMajor")
    TweakDB:SetFlat("MinigameAction.BNSignalNoise.objectActionUI",  "Interactions.BNSignalNoise")
    TweakDB:SetFlat("MinigameAction.BNSignalNoise.completionEffects", {})
    TweakDB:SetFlat("MinigameAction.BNSignalNoise.type",            "MinigameAction.AccessPoint")
    TweakDB:SetFlat("MinigameAction.BNSignalNoise.complexity",      30.0)

    print("[Better Netrunning] Signal Noise daemon configured")
end





local BN_MINIGAME_ATLAS = "base\\gameplay\\gui\\fullscreen\\hacking_minigame\\atlas_minigame_programs.inkatlas"

function TweakDBSetup.SetupDaemonIcons()
    local icons = {
        { record = "Interactions.BNIcepickV1",             name = "BNFracture",  part = "DataMineAdvanced"  },
        { record = "Interactions.BNIcepickV2",             name = "BNPurge",     part = "ICEMedium"         },
        { record = "Interactions.BNIcepickV3",             name = "BNSunder",    part = "DataMineMaster"    },
        { record = "Interactions.NetworkCounterBreachICE", name = "BNDeadlock",  part = "DoorAuthorization" },
        { record = "Interactions.BNHidePresence",          name = "BNGhost",     part = "AutoBlind"         },
        { record = "Interactions.BNDisarmICE",             name = "BNNull",      part = "ICEMajor"          },
        { record = "Interactions.BNSignalNoise",           name = "BNRaven",     part = "ICEPick"           },
    }

    for _, entry in ipairs(icons) do

        local uiIconPath = "CustomUIIcon." .. entry.part
        if TweakDB:GetRecord(uiIconPath) == nil then
            TweakDB:CreateRecord(uiIconPath, "gamedataUIIcon_Record")
        end
        TweakDB:SetFlat(uiIconPath .. ".atlasPartName",     CName.new(entry.part))
        TweakDB:SetFlat(uiIconPath .. ".atlasResourcePath", BN_MINIGAME_ATLAS)


        local captionIconPath = "UICaptionIcon." .. entry.name
        if TweakDB:GetRecord(captionIconPath) == nil then
            TweakDB:CreateRecord(captionIconPath, "gamedataChoiceCaptionIconPart_Record")
        end
        TweakDB:SetFlat(captionIconPath .. ".mappinVariant", "Mappins.InvalidVariant")
        TweakDB:SetFlat(captionIconPath .. ".partType",      "ChoiceCaptionPartType.Icon")
        TweakDB:SetFlat(captionIconPath .. ".texturePartID", uiIconPath)
        TweakDB:SetFlat(captionIconPath .. ".enumName",      CName.new(entry.name))


        TweakDB:SetFlat(entry.record .. ".captionIcon", captionIconPath)
    end

    print("[Better Netrunning] Daemon icons configured")
end

return TweakDBSetup

