





























RemoteBreach = {}

function RemoteBreach.Setup()

    local CustomHackingSystem = GetMod("CustomHackingSystem")

    if not CustomHackingSystem then
        print("[BetterNetrunning] CustomHackingSystem not found - Remote Breach feature disabled")
        return false
    end

    print("[BetterNetrunning] Setting up Remote Breach minigame...")

    local api = CustomHackingSystem.API


    local betterNetrunningCategory = api.CreateHackingMinigameCategory("BetterNetrunning")








    local daemonRewardType = api.CreateProgramActionType("RemoteBreachDaemonRewards")

    local daemonUIIcon = api.CreateUIIcon(
        "BreachProtocol",
        "base\\gameplay\\gui\\common\\icons\\quickhacks_icons.inkatlas"
    )

    local unlockBasicUI = api.CreateProgramActionUI(
        "BN_UnlockBasicUI",
        LocKey(4820003),
        LocKey(4820004),
        daemonUIIcon
    )

    local unlockNPCUI = api.CreateProgramActionUI(
        "BN_UnlockNPCUI",
        LocKey(4820005),
        LocKey(4820006),
        daemonUIIcon
    )

    local unlockCameraUI = api.CreateProgramActionUI(
        "BN_UnlockCameraUI",
        LocKey(4820007),
        LocKey(4820008),
        daemonUIIcon
    )

    local unlockTurretUI = api.CreateProgramActionUI(
        "BN_UnlockTurretUI",
        LocKey(4820009),
        LocKey(4820010),
        daemonUIIcon
    )


    local unlockBasicProgramAction = api.CreateProgramAction(
        "BN_RemoteBreach_UnlockBasic",
        daemonRewardType,
        betterNetrunningCategory,
        unlockBasicUI,
        0
    )
    print("[BetterNetrunning] Created ProgramAction: " .. unlockBasicProgramAction)

    local unlockNPCProgramAction = api.CreateProgramAction(
        "BN_RemoteBreach_UnlockNPC",
        daemonRewardType,
        betterNetrunningCategory,
        unlockNPCUI,
        10
    )
    print("[BetterNetrunning] Created ProgramAction: " .. unlockNPCProgramAction)

    local unlockCameraProgramAction = api.CreateProgramAction(
        "BN_RemoteBreach_UnlockCamera",
        daemonRewardType,
        betterNetrunningCategory,
        unlockCameraUI,
        5
    )

    local unlockTurretProgramAction = api.CreateProgramAction(
        "BN_RemoteBreach_UnlockTurret",
        daemonRewardType,
        betterNetrunningCategory,
        unlockTurretUI,
        15
    )


    local unlockVehicleProgramAction = api.CreateProgramAction(
        "BN_RemoteBreach_UnlockVehicle",
        daemonRewardType,
        betterNetrunningCategory,
        unlockBasicUI,
        0
    )


    local unlockVehicleProgram = api.CreateProgram(
        "BN_UnlockVehicleQuickhacks",
        unlockVehicleProgramAction,
        4
    )

    local unlockBasicProgram = api.CreateProgram(
        "BN_UnlockQuickhacks",
        unlockBasicProgramAction, -- Pass the ProgramAction object, not a string
        4                         -- buffer size
    )

    local unlockNPCProgram = api.CreateProgram(
        "BN_UnlockNPCQuickhacks",
        unlockNPCProgramAction, -- Pass the ProgramAction object, not a string
        5                       -- buffer size
    )

    local unlockCameraProgram = api.CreateProgram(
        "BN_UnlockCameraQuickhacks",
        unlockCameraProgramAction, -- Pass the ProgramAction object, not a string
        4                          -- buffer size
    )

    local unlockTurretProgram = api.CreateProgram(
        "BN_UnlockTurretQuickhacks",
        unlockTurretProgramAction, -- Pass the ProgramAction object, not a string
        6                          -- buffer size
    )

    print("[BetterNetrunning] Created daemon program actions and programs for RemoteBreach")












    local iceRewardType = api.CreateProgramActionType("RemoteBreachICERewards")



    local BN_MINIGAME_ATLAS = "base\\gameplay\\gui\\fullscreen\\hacking_minigame\\atlas_minigame_programs.inkatlas"
    local iceIconV1 = api.CreateUIIcon("DataMineAdvanced", BN_MINIGAME_ATLAS)
    local iceIconV2 = api.CreateUIIcon("ICEMedium",        BN_MINIGAME_ATLAS)
    local iceIconV3 = api.CreateUIIcon("DataMineMaster",   BN_MINIGAME_ATLAS)

    local icepickV1UI = api.CreateProgramActionUI(
        "BN_RB_IcepickV1UI",
        LocKey(4820014),
        LocKey(4820015),
        iceIconV1
    )
    local icepickV2UI = api.CreateProgramActionUI(
        "BN_RB_IcepickV2UI",
        LocKey(4820016),
        LocKey(4820017),
        iceIconV2
    )
    local icepickV3UI = api.CreateProgramActionUI(
        "BN_RB_IcepickV3UI",
        LocKey(4820018),
        LocKey(4820019),
        iceIconV3
    )

    local icepickV1ProgramAction = api.CreateProgramAction(
        "BN_RemoteBreach_IcepickV1",
        iceRewardType,
        betterNetrunningCategory,
        icepickV1UI,
        0
    )
    local icepickV2ProgramAction = api.CreateProgramAction(
        "BN_RemoteBreach_IcepickV2",
        iceRewardType,
        betterNetrunningCategory,
        icepickV2UI,
        0
    )
    local icepickV3ProgramAction = api.CreateProgramAction(
        "BN_RemoteBreach_IcepickV3",
        iceRewardType,
        betterNetrunningCategory,
        icepickV3UI,
        0
    )

    local icepickV1Program = api.CreateProgram("BN_RB_IcepickV1", icepickV1ProgramAction, 3)
    local icepickV2Program = api.CreateProgram("BN_RB_IcepickV2", icepickV2ProgramAction, 5)
    local icepickV3Program = api.CreateProgram("BN_RB_IcepickV3", icepickV3ProgramAction, 7)







    local iceBoardF = api.CreateHackingMinigame(
        "BNRemoteBreachICEBoard_F",   10.00, 5, 0, 7, { icepickV1Program }, {}
    )
    local iceBoardFP = api.CreateHackingMinigame(
        "BNRemoteBreachICEBoard_FP",  10.00, 5, 0, 7, { icepickV1Program, icepickV2Program }, {}
    )
    local iceBoardFS = api.CreateHackingMinigame(
        "BNRemoteBreachICEBoard_FS",  10.00, 5, 0, 7, { icepickV1Program, icepickV3Program }, {}
    )
    local iceBoardFPS = api.CreateHackingMinigame(
        "BNRemoteBreachICEBoard_FPS", 10.00, 5, 0, 7, { icepickV1Program, icepickV2Program, icepickV3Program }, {}
    )

    TweakDB:CloneRecord("Minigame.BNRemoteBreachICEBoard_F",   "CustomHackingSystemMinigame.BNRemoteBreachICEBoard_F")
    TweakDB:CloneRecord("Minigame.BNRemoteBreachICEBoard_FP",  "CustomHackingSystemMinigame.BNRemoteBreachICEBoard_FP")
    TweakDB:CloneRecord("Minigame.BNRemoteBreachICEBoard_FS",  "CustomHackingSystemMinigame.BNRemoteBreachICEBoard_FS")
    TweakDB:CloneRecord("Minigame.BNRemoteBreachICEBoard_FPS", "CustomHackingSystemMinigame.BNRemoteBreachICEBoard_FPS")
    print("[BetterNetrunning] ICE board variants created: F=" .. iceBoardF .. " FP=" .. iceBoardFP .. " FS=" .. iceBoardFS .. " FPS=" .. iceBoardFPS)








    local npcSubnetBoard = api.CreateHackingMinigame(
        "BNNPCRemoteBreach",
        10.00, -- timeLimit
        5,     -- gridSize
        0,     -- extraDifficulty (medium)
        7,     -- bufferSize
        { unlockNPCProgram },
        {}
    )

    TweakDB:CloneRecord("Minigame.BNNPCRemoteBreach", "CustomHackingSystemMinigame.BNNPCRemoteBreach")
    print("[BetterNetrunning] NPC subnet board created: " .. npcSubnetBoard)







    local netrunnerNPCBoard = api.CreateHackingMinigame(
        "BNNetrunnerNPCRemoteBreach",
        10.00, -- timeLimit
        5,     -- gridSize
        0,     -- extraDifficulty (medium)
        7,     -- bufferSize
        { unlockBasicProgram, unlockNPCProgram, unlockCameraProgram, unlockTurretProgram },
        {}
    )

    TweakDB:CloneRecord("Minigame.BNNetrunnerNPCRemoteBreach", "CustomHackingSystemMinigame.BNNetrunnerNPCRemoteBreach")
    print("[BetterNetrunning] Netrunner NPC subnet board created: " .. netrunnerNPCBoard)





    local computerMinigameEasy = api.CreateHackingMinigame(
        "ComputerRemoteBreachEasy",
        10.00, -- timeLimit: 20 seconds
        5,     -- gridSize: 5x5
        -20,   -- extraDifficulty: easier
        7,     -- bufferSize
        {
            unlockBasicProgram,
            unlockCameraProgram
        },
        {}
    )

    api.CreateHackingMinigame(
        "ComputerRemoteBreachMedium",
        10.00, -- timeLimit: 25 seconds
        6,     -- gridSize: 6x6
        10,    -- extraDifficulty: moderate
        8,     -- bufferSize
        {
            unlockBasicProgram,
            unlockCameraProgram
        },
        {}
    )

    api.CreateHackingMinigame(
        "ComputerRemoteBreachHard",
        10.00, -- timeLimit: 30 seconds
        7,     -- gridSize: 7x7
        30,    -- extraDifficulty: hard
        9,     -- bufferSize
        {
            unlockBasicProgram,
            unlockCameraProgram
        },
        {}
    )





    local deviceMinigameEasy = api.CreateHackingMinigame(
        "DeviceRemoteBreachEasy",
        10.00,
        5,
        -20,
        7,
        {
            unlockBasicProgram
        },
        {}
    )

    api.CreateHackingMinigame(
        "DeviceRemoteBreachMedium",
        10.00,
        6,
        10,
        8,
        {
            unlockBasicProgram
        },
        {}
    )

    api.CreateHackingMinigame(
        "DeviceRemoteBreachHard",
        10.00,
        7,
        30,
        9,
        {
            unlockBasicProgram
        },
        {}
    )





    local cameraMinigameEasy = api.CreateHackingMinigame(
        "CameraRemoteBreachEasy",
        10.00,
        5,
        -20,
        7,
        {
            unlockBasicProgram,
            unlockCameraProgram
        },
        {}
    )

    api.CreateHackingMinigame(
        "CameraRemoteBreachMedium",
        10.00,
        6,
        10,
        8,
        {
            unlockBasicProgram,
            unlockCameraProgram
        },
        {}
    )

    api.CreateHackingMinigame(
        "CameraRemoteBreachHard",
        10.00,
        7,
        30,
        9,
        {
            unlockBasicProgram,
            unlockCameraProgram
        },
        {}
    )





    local turretMinigameEasy = api.CreateHackingMinigame(
        "TurretRemoteBreachEasy",
        10.00,
        5,
        -20,
        7,
        {
            unlockBasicProgram,
            unlockTurretProgram
        },
        {}
    )

    api.CreateHackingMinigame(
        "TurretRemoteBreachMedium",
        10.00,
        6,
        10,
        8,
        {
            unlockBasicProgram,
            unlockTurretProgram
        },
        {}
    )

    api.CreateHackingMinigame(
        "TurretRemoteBreachHard",
        10.00,
        7,
        30,
        9,
        {
            unlockBasicProgram,
            unlockTurretProgram
        },
        {}
    )






    local vehicleMinigameEasy = api.CreateHackingMinigame(
        "VehicleRemoteBreach",
        10.00, -- duration
        6,     -- bufferSize
        10,    -- difficulty (Medium-equivalent)
        8,     -- tracesStartingLength
        {
            unlockVehicleProgram
        },
        {}
    )









    TweakDB:CloneRecord("Minigame.ComputerRemoteBreachEasy", "CustomHackingSystemMinigame.ComputerRemoteBreachEasy")
    TweakDB:CloneRecord("Minigame.ComputerRemoteBreachMedium", "CustomHackingSystemMinigame.ComputerRemoteBreachMedium")
    TweakDB:CloneRecord("Minigame.ComputerRemoteBreachHard", "CustomHackingSystemMinigame.ComputerRemoteBreachHard")


    TweakDB:CloneRecord("Minigame.DeviceRemoteBreachEasy", "CustomHackingSystemMinigame.DeviceRemoteBreachEasy")
    TweakDB:CloneRecord("Minigame.DeviceRemoteBreachMedium", "CustomHackingSystemMinigame.DeviceRemoteBreachMedium")
    TweakDB:CloneRecord("Minigame.DeviceRemoteBreachHard", "CustomHackingSystemMinigame.DeviceRemoteBreachHard")


    TweakDB:CloneRecord("Minigame.CameraRemoteBreachEasy", "CustomHackingSystemMinigame.CameraRemoteBreachEasy")
    TweakDB:CloneRecord("Minigame.CameraRemoteBreachMedium", "CustomHackingSystemMinigame.CameraRemoteBreachMedium")
    TweakDB:CloneRecord("Minigame.CameraRemoteBreachHard", "CustomHackingSystemMinigame.CameraRemoteBreachHard")


    TweakDB:CloneRecord("Minigame.TurretRemoteBreachEasy", "CustomHackingSystemMinigame.TurretRemoteBreachEasy")
    TweakDB:CloneRecord("Minigame.TurretRemoteBreachMedium", "CustomHackingSystemMinigame.TurretRemoteBreachMedium")
    TweakDB:CloneRecord("Minigame.TurretRemoteBreachHard", "CustomHackingSystemMinigame.TurretRemoteBreachHard")


    TweakDB:CloneRecord("Minigame.VehicleRemoteBreach", "CustomHackingSystemMinigame.VehicleRemoteBreach")

    print("[BetterNetrunning] TweakDB entries created for minigame mapping (Minigame.* → CustomHackingSystemMinigame.*)")






    print("[BetterNetrunning] Remote Breach minigame setup complete (Phase 6 - Device-type-specific)")
    print("  - Category: " .. betterNetrunningCategory)
    print("  - Computer Minigames: Easy/Medium/Hard (Basic + Camera)")
    print("  - Generic Device Minigames: Easy/Medium/Hard (Basic only)")
    print("  - Camera Minigames: Easy/Medium/Hard (Basic + Camera)")
    print("  - Turret Minigames: Easy/Medium/Hard (Basic + Turret)")
    print("  - Vehicle Minigame: Fixed difficulty (Basic only)")
    print("  - Computer Easy: " .. computerMinigameEasy)
    print("  - Device Easy: " .. deviceMinigameEasy)
    print("  - Camera Easy: " .. cameraMinigameEasy)
    print("  - Turret Easy: " .. turretMinigameEasy)
    print("  - Vehicle Easy: " .. vehicleMinigameEasy)


    return true
end

return RemoteBreach

