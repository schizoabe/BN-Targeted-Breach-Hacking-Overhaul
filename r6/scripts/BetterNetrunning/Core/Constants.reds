

module BetterNetrunning.Core

public abstract class BNConstants {

  public static func CLASS_REMOTE_BREACH_DEVICE() -> CName {
    return n"BetterNetrunning.RemoteBreach.Actions.DeviceRemoteBreachAction";
  }

  public static func CLASS_DEVICE_REMOTE_BREACH_STATE_SYSTEM() -> CName {
    return n"BetterNetrunning.RemoteBreach.Core.DeviceRemoteBreachStateSystem";
  }

  public static func CLASS_NPC_REMOTE_BREACH_STATE_SYSTEM() -> CName {
    return n"BetterNetrunning.RemoteBreach.Core.NPCRemoteBreachStateSystem";
  }

  public static func CLASS_DISPLAYED_DAEMONS_STATE_SYSTEM() -> CName {
    return n"BetterNetrunning.Logging.DisplayedDaemonsStateSystem";
  }

public static func CLASS_MARKING_STATE_SYSTEM() -> CName {
    return n"BetterNetrunning.Marking.MarkingStateSystem";
}

public static func CLASS_COUNTER_BREACH_SYSTEM() -> CName {
    return n"BetterNetrunning.CounterBreach.CounterBreachSystem";
}

  public static func CLASS_CUSTOM_HACKING_SYSTEM() -> CName {
    return n"HackingExtensions.CustomHackingSystem";
  }

  public static func ACTION_REMOTE_BREACH() -> CName {
    return n"RemoteBreach";
  }

  public static func ACTION_SET_BREACHED_SUBNET() -> CName {
    return n"SetBreachedSubnet";
  }

  public static func ACTION_PING_DEVICE() -> CName {
    return n"PingDevice";
  }

  public static func ACTION_DISTRACTION() -> CName {
    return n"QuickHackDistraction";
  }

  public static func ACTION_PHYSICAL_BREACH() -> CName {
    return n"PhysicalBreach";
  }

  public static func ACTION_SUICIDE_BREACH() -> CName {
    return n"SuicideBreach";
  }

  public static func ACTION_UNCONSCIOUS_BREACH() -> CName {
    return n"BreachUnconsciousOfficer";
  }

  public static func LOCKEY_QUICKHACKS_LOCKED() -> CName {
    return n"Better-Netrunning-Quickhacks-Locked";
  }

  public static func LOCKEY_NO_NETWORK_ACCESS() -> String {
    return "LocKey#7021";
  }

  public static func LOCKEY_ACTIVATE_NETWORK_DEVICE() -> String {
    return "LocKey#49279";
  }

  public static func LOCKEY_NOT_POWERED() -> String {
    return "LocKey#7013";
  }

  public static func LOCKEY_ACCESS() -> CName {
    return n"LocKey#34844";
  }

  public static func LOCKEY_RAM_INSUFFICIENT() -> String {
    return "LocKey#27398";
  }

  public static func DEVICE_NAME_PREFIX() -> String {
    return "Gameplay-Devices-DisplayNames-";
  }

  public static func PROGRAM_UNLOCK_QUICKHACKS() -> TweakDBID {
    return t"MinigameAction.UnlockQuickhacks";
  }

  public static func PROGRAM_UNLOCK_NPC_QUICKHACKS() -> TweakDBID {
    return t"MinigameAction.UnlockNPCQuickhacks";
  }

  public static func PROGRAM_UNLOCK_CAMERA_QUICKHACKS() -> TweakDBID {
    return t"MinigameAction.UnlockCameraQuickhacks";
  }

  public static func PROGRAM_UNLOCK_TURRET_QUICKHACKS() -> TweakDBID {
    return t"MinigameAction.UnlockTurretQuickhacks";
  }

  public static func PROGRAM_DATAMINE_BASIC() -> TweakDBID {
    return t"MinigameAction.NetworkDataMineLootAll";
  }

  public static func PROGRAM_DATAMINE_ADVANCED() -> TweakDBID {
    return t"MinigameAction.NetworkDataMineLootAllAdvanced";
  }

  public static func PROGRAM_DATAMINE_MASTER() -> TweakDBID {
    return t"MinigameAction.NetworkDataMineLootAllMaster";
  }

  public static func PROGRAM_NETWORK_DEVICE_BASIC_ACTIONS() -> TweakDBID {
    return t"MinigameAction.NetworkDeviceBasicActions";
  }

  public static func PROGRAM_BN_COUNTER_BREACH() -> TweakDBID {
    return t"MinigameAction.BN_CounterBreach";
  }

  public static func PROGRAM_BN_ICEPICK_V1() -> TweakDBID {
    return t"MinigameAction.BNIcepickV1";
  }

  public static func PROGRAM_BN_ICEPICK_V2() -> TweakDBID {
    return t"MinigameAction.BNIcepickV2";
  }

  public static func PROGRAM_BN_ICEPICK_V3() -> TweakDBID {
    return t"MinigameAction.BNIcepickV3";
  }

  public static func PROGRAM_HIDE_PRESENCE() -> TweakDBID {
    return t"MinigameAction.BNHidePresence";
  }

  public static func PROGRAM_DISARM_ICE() -> TweakDBID {
    return t"MinigameAction.BNDisarmICE";
  }

  public static func PROGRAM_SIGNAL_NOISE() -> TweakDBID {
    return t"MinigameAction.BNSignalNoise";
  }

  public static func PROGRAM_ACTION_BN_UNLOCK_BASIC() -> TweakDBID {
    return t"MinigameProgramAction.BN_RemoteBreach_UnlockBasic";
  }

  public static func PROGRAM_ACTION_BN_UNLOCK_NPC() -> TweakDBID {
    return t"MinigameProgramAction.BN_RemoteBreach_UnlockNPC";
  }

  public static func PROGRAM_ACTION_BN_UNLOCK_CAMERA() -> TweakDBID {
    return t"MinigameProgramAction.BN_RemoteBreach_UnlockCamera";
  }

  public static func PROGRAM_ACTION_BN_UNLOCK_TURRET() -> TweakDBID {
    return t"MinigameProgramAction.BN_RemoteBreach_UnlockTurret";
  }

  public static func PROGRAM_ACTION_BN_UNLOCK_VEHICLE() -> TweakDBID {
    return t"MinigameProgramAction.BN_RemoteBreach_UnlockVehicle";
  }

  public static func PROGRAM_ACTION_BN_RB_ICEPICK_V1() -> TweakDBID {
    return t"MinigameProgramAction.BN_RemoteBreach_IcepickV1";
  }

  public static func PROGRAM_ACTION_BN_RB_ICEPICK_V2() -> TweakDBID {
    return t"MinigameProgramAction.BN_RemoteBreach_IcepickV2";
  }

  public static func PROGRAM_ACTION_BN_RB_ICEPICK_V3() -> TweakDBID {
    return t"MinigameProgramAction.BN_RemoteBreach_IcepickV3";
  }

  public static func MINIGAME_RB_ICE_BOARD_F() -> TweakDBID {
    return t"Minigame.BNRemoteBreachICEBoard_F";
  }
  public static func MINIGAME_RB_ICE_BOARD_FP() -> TweakDBID {
    return t"Minigame.BNRemoteBreachICEBoard_FP";
  }
  public static func MINIGAME_RB_ICE_BOARD_FS() -> TweakDBID {
    return t"Minigame.BNRemoteBreachICEBoard_FS";
  }
  public static func MINIGAME_RB_ICE_BOARD_FPS() -> TweakDBID {
    return t"Minigame.BNRemoteBreachICEBoard_FPS";
  }

  public static func MINIGAME_NPC_REMOTE_BREACH() -> TweakDBID {
    return t"Minigame.BNNPCRemoteBreach";
  }

  public static func MINIGAME_NETRUNNER_NPC_REMOTE_BREACH() -> TweakDBID {
    return t"Minigame.BNNetrunnerNPCRemoteBreach";
  }

  public static func PROGRAM_ACTION_REMOTE_BREACH_EASY() -> TweakDBID {
    return t"MinigameProgramAction.RemoteBreachEasy";
  }

  public static func PROGRAM_ACTION_REMOTE_BREACH_MEDIUM() -> TweakDBID {
    return t"MinigameProgramAction.RemoteBreachMedium";
  }

  public static func PROGRAM_ACTION_REMOTE_BREACH_HARD() -> TweakDBID {
    return t"MinigameProgramAction.RemoteBreachHard";
  }

  public static func MINIGAME_COMPUTER_BREACH_EASY() -> TweakDBID {
    return t"Minigame.ComputerRemoteBreachEasy";
  }

  public static func MINIGAME_COMPUTER_BREACH_MEDIUM() -> TweakDBID {
    return t"Minigame.ComputerRemoteBreachMedium";
  }

  public static func MINIGAME_COMPUTER_BREACH_HARD() -> TweakDBID {
    return t"Minigame.ComputerRemoteBreachHard";
  }

  public static func MINIGAME_DEVICE_BREACH_MEDIUM() -> TweakDBID {
    return t"Minigame.DeviceRemoteBreachMedium";
  }

  public static func MINIGAME_VEHICLE_BREACH() -> TweakDBID {
    return t"Minigame.VehicleRemoteBreach";
  }

  public static func DEVICE_ACTION_REMOTE_BREACH() -> TweakDBID {
    return t"DeviceAction.RemoteBreach";
  }

  
  public static func IsRemoteBreachAction(className: CName) -> Bool {
    return Equals(className, BNConstants.CLASS_REMOTE_BREACH_DEVICE());
  }
}


