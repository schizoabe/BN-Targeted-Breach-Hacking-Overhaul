
module BetterNetrunning.Core

import BetterNetrunning.Marking.*
import BetterNetrunning.Perks.*

import RedscriptConfigFramework.*

public func BN_RCFModId() -> String = "BetterNetrunning"

public class BNConfig extends ScriptableSystem {
  public let clearMarksKey:      EInputKey = EInputKey.IK_None;
  public let forceJackOutKey:    EInputKey = EInputKey.IK_None;
  public let cycleBreachModeKey: EInputKey = EInputKey.IK_None;
  public let toggleHUDPanelsKey: EInputKey = EInputKey.IK_None;
  public let cycleCascadeQHKey:  EInputKey = EInputKey.IK_None;
  public let dumpRAMForICEKey:   EInputKey = EInputKey.IK_None;

  public let quickhackUnlockDurationHours: Int32 = 6;
  public let breachPenaltyDurationMinutes: Int32 = 10;

  public let enableClassicMode:            Bool = false;
  public let allowBreachUnconsciousNPCs:   Bool = true;
  public let offensiveDaemonsEnabled:      Bool = true;
  public let markBeamsEnabled:             Bool = true;
  public let breachFailurePenaltyEnabled:    Bool = true;
  public let apBreachFailurePenaltyEnabled:  Bool = true;
  public let npcBreachFailurePenaltyEnabled: Bool = true;
  public let enableDebugLog:               Bool = false;
  public let debugLogLevel:                Int32 = 2;

  public let unconsciousBreachChoiceSlot:  Int32 = 3;

  private let m_provider: ref<BNConfigProvider>;

  public static func GetInstance(gi: GameInstance) -> ref<BNConfig> {
    return GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.Core.BNConfig") as BNConfig;
  }

  private func OnAttach() -> Void {
    this.m_provider = new BNConfigProvider();
    this.m_provider.Init(this);

    DVRCF_Store.RestoreInto(this.GetGameInstance(), BN_RCFModId(), this.m_provider, this.m_provider.BuildSchema());
    this.PushToInputSystem();
    GameInstance.GetCallbackSystem()
      .RegisterCallback(n"Session/Ready", this, n"OnSessionReady")
      .SetLifetime(CallbackLifetime.Forever);
  }

  private func OnDetach() -> Void {
    GameInstance.GetCallbackSystem().UnregisterCallback(n"Session/Ready", this);
  }

  protected cb func OnSessionReady(event: ref<GameSessionEvent>) -> Void {
    if !IsDefined(this.m_provider) { return; }
    DVRCF.Register(this.GetGameInstance(), BN_RCFModId(), "Netrunning Overhaul", "Configure Netrunning Overhaul.", this.m_provider);
    this.PushToInputSystem();
  }

  public func PushToInputSystem() -> Void {
    let inputSys: ref<BNInputKeySystem> = BNInputKeySystem.GetInstance(this.GetGameInstance());
    if !IsDefined(inputSys) { return; }
    inputSys.SetClearMarksKey(this.clearMarksKey);
    inputSys.SetForceJackOutKey(this.forceJackOutKey);
    inputSys.SetCycleBreachModeKey(this.cycleBreachModeKey);
    inputSys.SetToggleHUDPanelsKey(this.toggleHUDPanelsKey);
    inputSys.SetCycleCascadeQHKey(this.cycleCascadeQHKey);
    inputSys.SetDumpRAMForICEKey(this.dumpRAMForICEKey);
  }

  public func RefreshMarkBeamsNow() -> Void {
    let ms: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGameInstance()).Get(n"BetterNetrunning.Marking.MarkingStateSystem") as MarkingStateSystem;
    if IsDefined(ms) { ms.RefreshMarkBeams(); }
  }

  public func GetBreachUnconsciousNPCActionID() -> TweakDBID {
    switch this.unconsciousBreachChoiceSlot {
      case 1: return t"Takedown.BNBreachUnconsciousNPC_Choice1";
      case 2: return t"Takedown.BNBreachUnconsciousNPC_Choice2";
      case 4: return t"Takedown.BNBreachUnconsciousNPC_Choice4";
      default: return t"Takedown.BNBreachUnconsciousNPC_Choice3";
    }
  }
}

public class BNConfigProvider extends DVRCF_Provider {
  private let m_cfg: wref<BNConfig>;

  public func Init(cfg: ref<BNConfig>) -> Void {
    this.m_cfg = cfg;
  }

  public func BuildSchema() -> ref<DVRCF_Schema> {
    let b: ref<DVRCF_SchemaBuilder> = DVRCF_SchemaBuilder.New("Netrunning Overhaul");

    b.Tab("Controls");
    b.Section("Unconscious Breach");
    let choiceSlots: array<String>;
    ArrayPush(choiceSlots, "Choice 1");
    ArrayPush(choiceSlots, "Choice 2");
    ArrayPush(choiceSlots, "Choice 3");
    ArrayPush(choiceSlots, "Choice 4");
    b.Dropdown("BN_UnconsciousBreachChoiceSlot", "Unconscious Breaching Hotkey Slot", choiceSlots);
    b.Tip("Which interaction-choice slot the \"Breach\" prompt occupies on an unconscious NPC's body. Change this if it conflicts with another mod's prompt on the same slot.");

    b.Section("Hotkeys");
    b.Keybind("BN_ClearMarks", "Clear All Marks");
    b.Tip("Clears all breach marks and hides the HUD panels.");
    b.Keybind("BN_ForceJackOut", "Force Jack-Out");
    b.Tip("Emergency escape from a stuck breach board.");
    b.Keybind("BN_CycleBreachMode", "Cycle Breach Mode");
    b.Tip("Cycles between Scout, Attack, and Defend modes (requires cyberdeck).");
    b.Keybind("BN_ToggleHUDPanels", "Toggle HUD Panels");
    b.Tip("Shows or hides the Network Status and ICE Log panels.");
    b.Keybind("BN_CycleCascadeQH", "Cycle Cascade Quickhack");
    b.Tip("Cycles which installed quickhack the Cascade Protocol daemon broadcasts.");
    b.Keybind("BN_DumpRAMForICE", "Dump RAM -> ICE");
    b.Tip("Converts all current RAM into ICE hits (Defend mode only). Sacrifice offense for defense mid-fight.");

    b.Tab("Breaching");
    b.Section("General");
    b.Toggle("BN_EnableClassicMode", "Enable Classic Mode");
    b.Tip("If enabled, the entire network can be breached by uploading any daemon. Disables the subnet system and its breach daemons.");
    b.Toggle("BN_AllowBreachUnconsciousNPCs", "Allow Breaching Unconscious NPCs");
    b.Tip("Allows breaching unconscious NPCs connected to a network.");
    b.Slider("BN_QuickhackUnlockDurationHours", "Quickhack Unlock Duration (Hours)", 0.0, 24.0, 1.0, true);
    b.Tip("How long quickhacks stay unlocked after a successful breach (in-game time). 0 = permanent (never re-locks).");
    b.Toggle("BN_OffensiveDaemonsEnabled", "Offensive Daemons");
    b.Tip("When all marked cameras have their ICE compromised, adds camera shutdown and malfunction daemons to the breach board.");
    b.Toggle("BN_MarkBeamsEnabled", "Mark Beams");
    b.Tip("Draws a network beam from V to each marked entity. Beams appear on mark and disappear on unmark.");

    b.Tab("Breach Penalty");
    b.Section("Failure Penalties");
    b.Toggle("BN_BreachFailurePenaltyEnabled", "Enable Breach Failure Penalty");
    b.Tip("Applies penalties when a breach protocol fails: disconnection VFX, type-specific lockout, and a trace attempt.");
    b.Toggle("BN_APBreachFailurePenaltyEnabled", "Access Point Breach Penalty");
    b.Tip("Locks Jack In on the failed Access Point target for a duration (other targets remain accessible).");
    b.Toggle("BN_NPCBreachFailurePenaltyEnabled", "NPC Breach Penalty");
    b.Tip("Locks Breach on the failed unconscious NPC for a duration (other NPCs remain breachable).");
    b.Slider("BN_BreachPenaltyDurationMinutes", "Breach Penalty Duration (Minutes)", 1.0, 60.0, 1.0, true);
    b.Tip("How long a target stays locked out after a failed breach attempt before it can be re-attempted.");

    b.Tab("Debug");
    b.Section("Logging");
    b.Toggle("BN_EnableDebugLog", "Enable Debug Logging");
    b.Tip("Enables debug log output.");
    let logLevels: array<String>;
    ArrayPush(logLevels, "ERROR (Errors Only)");
    ArrayPush(logLevels, "WARNING (Errors + Warnings)");
    ArrayPush(logLevels, "INFO (Default)");
    ArrayPush(logLevels, "DEBUG (Detailed)");
    ArrayPush(logLevels, "TRACE (Very Detailed)");
    b.Dropdown("BN_DebugLogLevel", "Log Level", logLevels);
    b.Tip("Verbosity of debug logs. Only applies when Debug Logging is enabled.");

    b.Section("Perks (Dev)");
    b.ButtonPair("BN_DevPerksMax", "Max All", "BN_DevPerksZero", "Zero All", "Dev: All Perks", "");
    b.Tip("Instantly sets every BN perk to max rank, or zeroes them all. For in-game testing only.");

    b.Section("Network Heat (Dev)");
    b.ButtonPair("BN_DevHeatMax", "Max (100%)", "BN_DevHeatZero", "Zero (0%)", "Dev: Session Heat", "");
    b.Tip("Forces session Heat to 100% or 0% instantly, bypassing Hide Presence/mode suppression. For testing Counter-Breach without waiting for Heat to climb naturally.");

    return b.Build();
  }

  public func GetBool(key: String) -> Bool {
    let c = this.m_cfg;
    if !IsDefined(c) { return false; }
    if Equals(key, "BN_EnableClassicMode")             { return c.enableClassicMode; }
    if Equals(key, "BN_AllowBreachUnconsciousNPCs")    { return c.allowBreachUnconsciousNPCs; }
    if Equals(key, "BN_OffensiveDaemonsEnabled")       { return c.offensiveDaemonsEnabled; }
    if Equals(key, "BN_MarkBeamsEnabled")              { return c.markBeamsEnabled; }
    if Equals(key, "BN_BreachFailurePenaltyEnabled")   { return c.breachFailurePenaltyEnabled; }
    if Equals(key, "BN_APBreachFailurePenaltyEnabled") { return c.apBreachFailurePenaltyEnabled; }
    if Equals(key, "BN_NPCBreachFailurePenaltyEnabled"){ return c.npcBreachFailurePenaltyEnabled; }
    if Equals(key, "BN_EnableDebugLog")                { return c.enableDebugLog; }
    return false;
  }

  public func SetBool(key: String, value: Bool) -> Void {
    let c = this.m_cfg;
    if !IsDefined(c) { return; }
    if Equals(key, "BN_EnableClassicMode")             { c.enableClassicMode = value; }
    else if Equals(key, "BN_AllowBreachUnconsciousNPCs")    { c.allowBreachUnconsciousNPCs = value; }
    else if Equals(key, "BN_OffensiveDaemonsEnabled")       { c.offensiveDaemonsEnabled = value; }
    else if Equals(key, "BN_MarkBeamsEnabled")              { c.markBeamsEnabled = value; c.RefreshMarkBeamsNow(); }
    else if Equals(key, "BN_BreachFailurePenaltyEnabled")   { c.breachFailurePenaltyEnabled = value; }
    else if Equals(key, "BN_APBreachFailurePenaltyEnabled") { c.apBreachFailurePenaltyEnabled = value; }
    else if Equals(key, "BN_NPCBreachFailurePenaltyEnabled"){ c.npcBreachFailurePenaltyEnabled = value; }
    else if Equals(key, "BN_EnableDebugLog")                { c.enableDebugLog = value; }
  }

  public func GetInt(key: String) -> Int32 {
    let c = this.m_cfg;
    if !IsDefined(c) { return 0; }
    if Equals(key, "BN_ClearMarks")        { return EnumInt(c.clearMarksKey); }
    if Equals(key, "BN_ForceJackOut")      { return EnumInt(c.forceJackOutKey); }
    if Equals(key, "BN_CycleBreachMode")   { return EnumInt(c.cycleBreachModeKey); }
    if Equals(key, "BN_ToggleHUDPanels")   { return EnumInt(c.toggleHUDPanelsKey); }
    if Equals(key, "BN_CycleCascadeQH")    { return EnumInt(c.cycleCascadeQHKey); }
    if Equals(key, "BN_DumpRAMForICE")     { return EnumInt(c.dumpRAMForICEKey); }
    if Equals(key, "BN_QuickhackUnlockDurationHours") { return c.quickhackUnlockDurationHours; }
    if Equals(key, "BN_BreachPenaltyDurationMinutes") { return c.breachPenaltyDurationMinutes; }
    if Equals(key, "BN_DebugLogLevel")     { return c.debugLogLevel; }
    if Equals(key, "BN_UnconsciousBreachChoiceSlot") { return c.unconsciousBreachChoiceSlot - 1; }
    return 0;
  }

  public func SetInt(key: String, value: Int32) -> Void {
    let c = this.m_cfg;
    if !IsDefined(c) { return; }
    if Equals(key, "BN_QuickhackUnlockDurationHours") { c.quickhackUnlockDurationHours = value; return; }
    if Equals(key, "BN_BreachPenaltyDurationMinutes") { c.breachPenaltyDurationMinutes = value; return; }
    if Equals(key, "BN_DebugLogLevel")                { c.debugLogLevel = value; return; }
    if Equals(key, "BN_UnconsciousBreachChoiceSlot")  { c.unconsciousBreachChoiceSlot = value + 1; return; }
    if Equals(key, "BN_ClearMarks")        { c.clearMarksKey      = IntEnum<EInputKey>(value); }
    else if Equals(key, "BN_ForceJackOut")      { c.forceJackOutKey    = IntEnum<EInputKey>(value); }
    else if Equals(key, "BN_CycleBreachMode")   { c.cycleBreachModeKey = IntEnum<EInputKey>(value); }
    else if Equals(key, "BN_ToggleHUDPanels")   { c.toggleHUDPanelsKey = IntEnum<EInputKey>(value); }
    else if Equals(key, "BN_CycleCascadeQH")    { c.cycleCascadeQHKey  = IntEnum<EInputKey>(value); }
    else if Equals(key, "BN_DumpRAMForICE")     { c.dumpRAMForICEKey   = IntEnum<EInputKey>(value); }
    else { return; }
    c.PushToInputSystem();
  }

  public func OnButton(key: String) -> Void {
    if Equals(key, "BN_DevPerksMax") {
      BNPerkData.ApplyDevAll(GetPlayer(GetGameInstance()), true);
    } else if Equals(key, "BN_DevPerksZero") {
      BNPerkData.ApplyDevAll(GetPlayer(GetGameInstance()), false);
    } else if Equals(key, "BN_DevHeatMax") {
      let ms: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"BetterNetrunning.Marking.MarkingStateSystem") as MarkingStateSystem;
      if IsDefined(ms) { ms.DebugSetSessionHeat(1.0); }
    } else if Equals(key, "BN_DevHeatZero") {
      let ms: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"BetterNetrunning.Marking.MarkingStateSystem") as MarkingStateSystem;
      if IsDefined(ms) { ms.DebugSetSessionHeat(0.0); }
    }
  }
}
