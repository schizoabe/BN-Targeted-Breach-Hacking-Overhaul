
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
  public let markBeamsEnabled:             Bool = false;
  public let breachFailurePenaltyEnabled:    Bool = true;
  public let apBreachFailurePenaltyEnabled:  Bool = true;
  public let npcBreachFailurePenaltyEnabled: Bool = true;
  public let enableDebugLog:               Bool = false;
  public let debugLogLevel:                Int32 = 2;

  public let hackThePlanetEnabled:               Bool = true;

  public let hackThePlanetReinitializeAccessPoints: Bool = false;

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
    DVRCF.Register(this.GetGameInstance(), BN_RCFModId(),
      GetLocalizedTextByKey(n"Better-Netrunning-RCF-HubTitle"),
      GetLocalizedTextByKey(n"Better-Netrunning-RCF-HubDescription"),
      this.m_provider);
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
    let b: ref<DVRCF_SchemaBuilder> = DVRCF_SchemaBuilder.New(GetLocalizedTextByKey(n"Better-Netrunning-RCF-HubTitle"));

    b.Tab(GetLocalizedTextByKey(n"Better-Netrunning-RCF-Tab-Controls"));
    b.Section(GetLocalizedTextByKey(n"Better-Netrunning-RCF-Section-UnconsciousBreach"));
    let choiceSlots: array<String>;
    ArrayPush(choiceSlots, GetLocalizedTextByKey(n"Better-Netrunning-RCF-ChoiceSlot1"));
    ArrayPush(choiceSlots, GetLocalizedTextByKey(n"Better-Netrunning-RCF-ChoiceSlot2"));
    ArrayPush(choiceSlots, GetLocalizedTextByKey(n"Better-Netrunning-RCF-ChoiceSlot3"));
    ArrayPush(choiceSlots, GetLocalizedTextByKey(n"Better-Netrunning-RCF-ChoiceSlot4"));
    b.Dropdown("BN_UnconsciousBreachChoiceSlot", GetLocalizedTextByKey(n"Better-Netrunning-RCF-UnconsciousBreachChoiceSlot-Label"), choiceSlots);
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-UnconsciousBreachChoiceSlot-Tip"));

    b.Section(GetLocalizedTextByKey(n"Better-Netrunning-RCF-Section-Hotkeys"));
    b.Keybind("BN_ClearMarks", GetLocalizedTextByKey(n"Better-Netrunning-RCF-ClearMarks-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-ClearMarks-Tip"));
    b.Keybind("BN_ForceJackOut", GetLocalizedTextByKey(n"Better-Netrunning-RCF-ForceJackOut-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-ForceJackOut-Tip"));
    b.Keybind("BN_CycleBreachMode", GetLocalizedTextByKey(n"Better-Netrunning-RCF-CycleBreachMode-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-CycleBreachMode-Tip"));
    b.Keybind("BN_ToggleHUDPanels", GetLocalizedTextByKey(n"Better-Netrunning-RCF-ToggleHUDPanels-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-ToggleHUDPanels-Tip"));
    b.Keybind("BN_CycleCascadeQH", GetLocalizedTextByKey(n"Better-Netrunning-RCF-CycleCascadeQH-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-CycleCascadeQH-Tip"));
    b.Keybind("BN_DumpRAMForICE", GetLocalizedTextByKey(n"Better-Netrunning-RCF-DumpRAMForICE-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-DumpRAMForICE-Tip"));

    b.Tab(GetLocalizedTextByKey(n"Better-Netrunning-RCF-Tab-Breaching"));
    b.Section(GetLocalizedTextByKey(n"Better-Netrunning-RCF-Section-General"));
    b.Toggle("BN_EnableClassicMode", GetLocalizedTextByKey(n"Better-Netrunning-RCF-EnableClassicMode-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-EnableClassicMode-Tip"));
    b.Toggle("BN_AllowBreachUnconsciousNPCs", GetLocalizedTextByKey(n"Better-Netrunning-RCF-AllowBreachUnconsciousNPCs-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-AllowBreachUnconsciousNPCs-Tip"));
    b.Slider("BN_QuickhackUnlockDurationHours", GetLocalizedTextByKey(n"Better-Netrunning-RCF-QuickhackUnlockDurationHours-Label"), 0.0, 24.0, 1.0, true);
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-QuickhackUnlockDurationHours-Tip"));
    b.Toggle("BN_OffensiveDaemonsEnabled", GetLocalizedTextByKey(n"Better-Netrunning-RCF-OffensiveDaemonsEnabled-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-OffensiveDaemonsEnabled-Tip"));
    b.Toggle("BN_MarkBeamsEnabled", GetLocalizedTextByKey(n"Better-Netrunning-RCF-MarkBeamsEnabled-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-MarkBeamsEnabled-Tip"));

    b.Section(GetLocalizedTextByKey(n"Better-Netrunning-RCF-Section-HackThePlanet"));
    b.Toggle("BN_HackThePlanetEnabled", GetLocalizedTextByKey(n"Better-Netrunning-RCF-HackThePlanetEnabled-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-HackThePlanetEnabled-Tip"));
    b.Toggle("BN_HackThePlanetReinitializeAccessPoints", GetLocalizedTextByKey(n"Better-Netrunning-RCF-HackThePlanetReinitializeAccessPoints-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-HackThePlanetReinitializeAccessPoints-Tip"));

    b.Tab(GetLocalizedTextByKey(n"Better-Netrunning-RCF-Tab-BreachPenalty"));
    b.Section(GetLocalizedTextByKey(n"Better-Netrunning-RCF-Section-FailurePenalties"));
    b.Toggle("BN_BreachFailurePenaltyEnabled", GetLocalizedTextByKey(n"Better-Netrunning-RCF-BreachFailurePenaltyEnabled-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-BreachFailurePenaltyEnabled-Tip"));
    b.Toggle("BN_APBreachFailurePenaltyEnabled", GetLocalizedTextByKey(n"Better-Netrunning-RCF-APBreachFailurePenaltyEnabled-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-APBreachFailurePenaltyEnabled-Tip"));
    b.Toggle("BN_NPCBreachFailurePenaltyEnabled", GetLocalizedTextByKey(n"Better-Netrunning-RCF-NPCBreachFailurePenaltyEnabled-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-NPCBreachFailurePenaltyEnabled-Tip"));
    b.Slider("BN_BreachPenaltyDurationMinutes", GetLocalizedTextByKey(n"Better-Netrunning-RCF-BreachPenaltyDurationMinutes-Label"), 1.0, 60.0, 1.0, true);
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-BreachPenaltyDurationMinutes-Tip"));

    b.Tab(GetLocalizedTextByKey(n"Better-Netrunning-RCF-Tab-Debug"));
    b.Section(GetLocalizedTextByKey(n"Better-Netrunning-RCF-Section-Logging"));
    b.Toggle("BN_EnableDebugLog", GetLocalizedTextByKey(n"Better-Netrunning-RCF-EnableDebugLog-Label"));
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-EnableDebugLog-Tip"));
    let logLevels: array<String>;
    ArrayPush(logLevels, GetLocalizedTextByKey(n"Better-Netrunning-RCF-LogLevel-Error"));
    ArrayPush(logLevels, GetLocalizedTextByKey(n"Better-Netrunning-RCF-LogLevel-Warning"));
    ArrayPush(logLevels, GetLocalizedTextByKey(n"Better-Netrunning-RCF-LogLevel-Info"));
    ArrayPush(logLevels, GetLocalizedTextByKey(n"Better-Netrunning-RCF-LogLevel-Debug"));
    ArrayPush(logLevels, GetLocalizedTextByKey(n"Better-Netrunning-RCF-LogLevel-Trace"));
    b.Dropdown("BN_DebugLogLevel", GetLocalizedTextByKey(n"Better-Netrunning-RCF-DebugLogLevel-Label"), logLevels);
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-DebugLogLevel-Tip"));

    b.Section(GetLocalizedTextByKey(n"Better-Netrunning-RCF-Section-PerksDev"));
    b.ButtonPair("BN_DevPerksMax", GetLocalizedTextByKey(n"Better-Netrunning-RCF-DevPerks-Max"), "BN_DevPerksZero", GetLocalizedTextByKey(n"Better-Netrunning-RCF-DevPerks-Zero"), GetLocalizedTextByKey(n"Better-Netrunning-RCF-DevPerks-GroupLabel"), "");
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-DevPerks-Tip"));

    b.Section(GetLocalizedTextByKey(n"Better-Netrunning-RCF-Section-HeatDev"));
    b.ButtonPair("BN_DevHeatMax", GetLocalizedTextByKey(n"Better-Netrunning-RCF-DevHeat-Max"), "BN_DevHeatZero", GetLocalizedTextByKey(n"Better-Netrunning-RCF-DevHeat-Zero"), GetLocalizedTextByKey(n"Better-Netrunning-RCF-DevHeat-GroupLabel"), "");
    b.Tip(GetLocalizedTextByKey(n"Better-Netrunning-RCF-DevHeat-Tip"));

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
    if Equals(key, "BN_HackThePlanetEnabled")          { return c.hackThePlanetEnabled; }
    if Equals(key, "BN_HackThePlanetReinitializeAccessPoints") { return c.hackThePlanetReinitializeAccessPoints; }
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
    else if Equals(key, "BN_HackThePlanetEnabled")          { c.hackThePlanetEnabled = value; }
    else if Equals(key, "BN_HackThePlanetReinitializeAccessPoints") { c.hackThePlanetReinitializeAccessPoints = value; }
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
