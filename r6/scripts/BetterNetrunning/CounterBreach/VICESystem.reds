
module BetterNetrunning.CounterBreach

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Marking.*
import BetterNetrunning.Systems.*

public class BNICERegenTickEvent extends Event {}

public class BNVICESystem extends ScriptableSystem {

  private let m_initialized: Bool;
  private let m_iceHits: Int32;
  private let m_maxIceHits: Int32;
  private let m_conversionCost: Int32;
  private let m_regenDelayID: DelayID;

  public static func GetInstance(game: GameInstance) -> ref<BNVICESystem> {
    return GameInstance.GetScriptableSystemsContainer(game)
      .Get(n"BetterNetrunning.CounterBreach.BNVICESystem") as BNVICESystem;
  }

  private func OnAttach() -> Void {
    this.m_initialized = false;
    this.m_iceHits = 0;
    this.m_maxIceHits = 3;
    this.m_conversionCost = 6;
    this.BuildPlayerMarker();
    BNInfo("VICE", "BNVICESystem attached");
  }

  private cb func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    this.EnsureInitialized();
    this.QueueRegenTick();
  }

  public func GetICEHits() -> Int32 { return this.m_iceHits; }
  public func GetMaxICEHits() -> Int32 { return this.m_maxIceHits; }
  public func IsICEIntact() -> Bool { return this.m_iceHits > 0; }

  public func TakeBreach(npc: wref<NPCPuppet>) -> Void {
    this.EnsureInitialized();
    if this.m_iceHits <= 0 { return; }

    let damage: Int32 = this.RollBreachDamage(npc);
    let prev: Int32 = this.m_iceHits;
    this.m_iceHits = this.m_iceHits - damage;
    if this.m_iceHits < 0 { this.m_iceHits = 0; }

    BNInfo("VICE", "ICE hit: -" + ToString(damage) + " (" + ToString(prev) + " -> " + ToString(this.m_iceHits) + "/" + ToString(this.m_maxIceHits) + ")");
    this.SaveICEState();
    this.RefreshPanel();

    if this.m_iceHits <= 0 {
      let player: ref<PlayerPuppet> = GetPlayer(this.GetGameInstance());
      if IsDefined(player) {
        StatusEffectHelper.RemoveStatusEffect(player, t"AIQuickHackStatusEffect.BN_ICEIntact");
      }
    }
  }

  public func ZeroICE() -> Void {
    if this.m_iceHits <= 0 { return; }
    this.m_iceHits = 0;
    let player: ref<PlayerPuppet> = GetPlayer(this.GetGameInstance());
    if IsDefined(player) {
      StatusEffectHelper.RemoveStatusEffect(player, t"AIQuickHackStatusEffect.BN_ICEIntact");
    }
    this.SaveICEState();
    this.RefreshPanel();
    BNInfo("VICE", "ICE zeroed by counter-breach retaliation");
  }

  public func RestoreICE(hits: Int32) -> Void {
    this.EnsureInitialized();
    let wasDown: Bool = this.m_iceHits <= 0;
    this.m_iceHits = this.m_iceHits + hits;
    if this.m_iceHits > this.m_maxIceHits { this.m_iceHits = this.m_maxIceHits; }
    BNInfo("VICE", "ICE restored: +" + ToString(hits) + " -> " + ToString(this.m_iceHits) + "/" + ToString(this.m_maxIceHits));
    this.SaveICEState();
    this.RefreshPanel();
    if wasDown && this.m_iceHits > 0 {
      let player: ref<PlayerPuppet> = GetPlayer(this.GetGameInstance());
      if IsDefined(player) {
        StatusEffectHelper.ApplyStatusEffect(player, t"AIQuickHackStatusEffect.BN_ICEIntact", player.GetEntityID());
      }
    }
  }

  public func DumpRAMForICE() -> Void {
    this.EnsureInitialized();
    let gi: GameInstance = this.GetGameInstance();
    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if !IsDefined(mss) || !mss.IsDefendMode() {
      BNInfo("VICE", "DumpRAMForICE: not in Defend mode — ignored");
      return;
    }
    let player: ref<PlayerPuppet> = GetPlayer(gi);
    if !IsDefined(player) { return; }
    let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(gi);
    let playerID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
    let currentRAM: Float = pools.GetStatPoolValue(playerID, gamedataStatPoolType.Memory, false);
    let cost: Int32 = this.GetConversionCost();
    let hits: Int32 = Cast<Int32>(currentRAM) / cost;
    if hits <= 0 {
      BNInfo("VICE", "DumpRAMForICE: insufficient RAM (RAM=" + ToString(Cast<Int32>(currentRAM)) + ", cost=" + ToString(cost) + "/hit)");
      return;
    }
    pools.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Memory, 0.0, player, false);
    this.RestoreICE(hits);
  }

  public func EnsureInitialized() -> Void {
    if this.m_initialized { return; }
    let player: ref<PlayerPuppet> = GetPlayer(this.GetGameInstance());
    if !IsDefined(player) { return; }
    this.m_initialized = true;
    this.RefreshICEBonuses(player);
    this.StripQuickhackShield(player);

    let qs: ref<QuestsSystem> = GameInstance.GetQuestsSystem(player.GetGame());
    if IsDefined(qs) && qs.GetFact(n"bn_vice_initialized") != 0 {
      let saved: Int32 = qs.GetFact(n"bn_vice_ice_hits");
      this.m_iceHits = saved > this.m_maxIceHits ? this.m_maxIceHits : saved;
      if this.m_iceHits < 0 { this.m_iceHits = 0; }
      BNInfo("VICE", "ICE restored from save: " + ToString(this.m_iceHits) + "/" + ToString(this.m_maxIceHits));
    } else {
      this.m_iceHits = this.m_maxIceHits;
      this.SaveICEState();
      BNInfo("VICE", "ICE first-run: starting at full " + ToString(this.m_iceHits) + "/" + ToString(this.m_maxIceHits));
    }

    if this.m_iceHits > 0 {
      StatusEffectHelper.ApplyStatusEffect(player, t"AIQuickHackStatusEffect.BN_ICEIntact", player.GetEntityID());
    }
  }

  private func GetConversionCost() -> Int32 { return this.m_conversionCost; }

  private func SaveICEState() -> Void {
    let qs: ref<QuestsSystem> = GameInstance.GetQuestsSystem(this.GetGameInstance());
    if !IsDefined(qs) { return; }
    qs.SetFact(n"bn_vice_initialized", 1);
    qs.SetFact(n"bn_vice_ice_hits", this.m_iceHits);
  }

  private func QueueRegenTick() -> Void {
    let gi: GameInstance = this.GetGameInstance();
    let player: ref<PlayerPuppet> = GetPlayer(gi);
    if !IsDefined(player) { return; }
    GameInstance.GetDelaySystem(gi).CancelDelay(this.m_regenDelayID);
    this.m_regenDelayID = GameInstance.GetDelaySystem(gi)
      .DelayEvent(player, new BNICERegenTickEvent(), 30.0, false);
  }

  public func RegenTick(player: ref<PlayerPuppet>) -> Void {
    if this.m_iceHits < this.m_maxIceHits {
      let gi: GameInstance = this.GetGameInstance();
      let psmBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gi)
        .GetLocalInstanced(player.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
      if IsDefined(psmBB) {
        let combatState: Int32 = psmBB.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Combat);
        if combatState == EnumInt(gamePSMCombat.Default) {
          this.RestoreICE(1);
          BNInfo("VICE", "ICE regen: out of combat, +" + "1 hit (" + ToString(this.m_iceHits) + "/" + ToString(this.m_maxIceHits) + ")");
        }
      }
    }
    this.QueueRegenTick();
  }

  public func RefreshICEBonuses(player: ref<PlayerPuppet>) -> Void {
    let tier: Int32 = this.GetSelfICETier(player);
    let prevMax: Int32 = this.m_maxIceHits;
    if tier >= 3 {
      this.m_maxIceHits = 6; this.m_conversionCost = 4;
    } else if tier == 2 {
      this.m_maxIceHits = 5; this.m_conversionCost = 5;
    } else if tier == 1 {
      this.m_maxIceHits = 4; this.m_conversionCost = 6;
    } else {
      this.m_maxIceHits = 3; this.m_conversionCost = 6;
    }
    if this.m_iceHits > this.m_maxIceHits {
      this.m_iceHits = this.m_maxIceHits;
    }

    if tier > 0 && this.m_maxIceHits > prevMax && this.m_iceHits > 0 {
      this.m_iceHits = this.m_maxIceHits;
    }
    BNInfo("VICE", "Self-ICE tier " + ToString(tier) + " — max=" + ToString(this.m_maxIceHits) + " hits, cost=" + ToString(this.m_conversionCost) + " RAM/hit");
  }

  private func GetSelfICETier(player: ref<PlayerPuppet>) -> Int32 {
    let items: array<ItemID> = EquipmentSystem.GetItemsInArea(player, gamedataEquipmentArea.FrontalCortexCW);
    BNDebug("VICE", "GetSelfICETier: FrontalCortexCW item count=" + ToString(ArraySize(items)));
    let statsSys: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
    for itemID in items {
      if ItemID.IsValid(itemID) {
        let tdbid: TweakDBID = ItemID.GetTDBID(itemID);
        let cwType: CName = TweakDBInterface.GetCName(tdbid + t".cyberwareType", n"");
        BNDebug("VICE", "  item tdbid=" + TDBID.ToStringDEBUG(tdbid) + " cyberwareType=" + NameToString(cwType));
        if Equals(cwType, n"AntiVirus") {
          let qualityVal: Float = statsSys.GetStatValue(Cast<StatsObjectID>(itemID), gamedataStatType.Quality);
          BNDebug("VICE", "  -> AntiVirus found, quality=" + ToString(qualityVal));
          if qualityVal >= 4.0 { return 3; }
          if qualityVal >= 3.0 { return 2; }
          return 1;
        }
      }
    }
    return 0;
  }

  private func StripQuickhackShield(player: ref<PlayerPuppet>) -> Void {
    let gi: GameInstance = player.GetGame();
    let mod: ref<gameStatModifierData> = RPGManager.CreateStatModifier(
      gamedataStatType.QuickhackShield, gameStatModifierType.Additive, -100.0
    );
    RPGManager.InjectStatModifier(gi, player, mod);
    BNInfo("VICE", "QuickhackShield zeroed — ICE absorption is sole NPC hack defense");
  }

  private func RollBreachDamage(npc: wref<NPCPuppet>) -> Int32 {
    if !IsDefined(npc) { return 1; }
    let rank: Int32 = NPCRarityToRank(npc.GetNPCRarity());
    if rank >= 8 { return RandRange(3, 5); }
    if rank >= 6 { return RandRange(2, 4); }
    if rank >= 4 { return RandRange(1, 3); }
    return 1;
  }

  private func RefreshPanel() -> Void {
    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGameInstance())
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if IsDefined(mss) { mss.RefreshHUDPanel(); }
  }

  private func ShowWarning(text: String) -> Void {
    let msg: SimpleScreenMessage;
    msg.isShown = true;
    msg.duration = 4.0;
    msg.message = text;
    let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGameInstance())
      .Get(GetAllBlackboardDefs().UI_Notifications);
    if IsDefined(bb) {
      bb.SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(msg), true);
    }
  }

  private func BuildPlayerMarker() -> Void {
    let emptyTags: array<CName>;
    let emptyPkgs: array<TweakDBID>;
    TweakDBManager.CloneRecord(t"AIQuickHackStatusEffect.BN_ICEIntact", t"AIQuickHackStatusEffect.Hacking");
    TweakDBManager.SetFlat(t"AIQuickHackStatusEffect.BN_ICEIntact.gameplayTags", emptyTags);
    TweakDBManager.SetFlat(t"AIQuickHackStatusEffect.BN_ICEIntact.packages", emptyPkgs);
    TweakDBManager.UpdateRecord(t"AIQuickHackStatusEffect.BN_ICEIntact");
  }
}

@wrapMethod(UploadFromNPCToPlayerListener)
protected cb func OnStatPoolAdded() -> Bool {
  let result: Bool = wrappedMethod();

  let gi: GameInstance = this.m_gameInstance;

  let vice: ref<BNVICESystem> = BNVICESystem.GetInstance(gi);
  if !IsDefined(vice) || vice.GetICEHits() < 1 { return result; }

  if this.m_bnFirewallEngaged {
    BNInfo("VICE", "Firewall intercepted — ICE preserved");
    return result;
  }

  if !IsDefined(this.m_action) { return result; }

  let actionID: TweakDBID = this.m_action.GetObjectActionID();

  if Equals(actionID, t"AIQuickHack.HackReveal")
      || Equals(actionID, t"AIQuickHack.HackRevealPosition")
      || Equals(actionID, t"AIQuickHack.PreventionHackRevealPosition")
      || Equals(actionID, t"AIQuickHack.BlackICE_RAMDrain") {
    return result;
  }

  let player: ref<PlayerPuppet> = GetPlayer(gi);
  if !IsDefined(player) { return result; }

  BNFirewallUtils.CancelUpload(gi, this, player);

  let viceSystem: ref<BNVICESystem> = BNVICESystem.GetInstance(gi);
  if IsDefined(viceSystem) {
    viceSystem.TakeBreach(this.m_npcPuppet as NPCPuppet);
  }

  BNInfo("VICE", "ICE absorbed: " + TDBID.ToStringDEBUG(actionID));
  return result;
}

@addMethod(PlayerPuppet)
protected cb func OnBNICERegenTick(evt: ref<BNICERegenTickEvent>) -> Bool {
  let vice: ref<BNVICESystem> = BNVICESystem.GetInstance(this.GetGame());
  if IsDefined(vice) {
    vice.RegenTick(this);
  }
  return false;
}
