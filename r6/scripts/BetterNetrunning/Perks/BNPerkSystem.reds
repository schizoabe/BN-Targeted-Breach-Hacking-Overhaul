

module BetterNetrunning.Perks

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*

public enum BNPerk {

  ColdTrace        = 0,
  NeuralTap        = 1,
  SubnetSpecialist = 2,
  ICEAnalyst       = 3,
  IntrusionSuite   = 4,
  GhostRun         = 5,
  TraceScrambler   = 6,
  ZeroSignature    = 7,

  DisarmICE        = 8,
  HidePresence     = 9,
  Purge            = 10,
  Sunder           = 11,
  TrackingProtocol = 12,
  IceBreaker       = 13,
}

public abstract class BNPerkData {

  public static func GetMaxLevel(perk: BNPerk) -> Int32 {
    switch perk {
      case BNPerk.ColdTrace:        return 3;
      case BNPerk.NeuralTap:        return 2;
      case BNPerk.SubnetSpecialist: return 3;
      case BNPerk.ICEAnalyst:       return 3;
      case BNPerk.IntrusionSuite:   return 1;
      case BNPerk.GhostRun:         return 2;
      case BNPerk.TraceScrambler:   return 3;
      case BNPerk.ZeroSignature:    return 1;
      case BNPerk.DisarmICE:        return 1;
      case BNPerk.HidePresence:     return 1;
      case BNPerk.Purge:            return 1;
      case BNPerk.Sunder:           return 1;
      case BNPerk.TrackingProtocol: return 3;
      case BNPerk.IceBreaker:       return 2;
      default:                       return 0;
    }
  }

  public static func GetName(perk: BNPerk) -> String {
    switch perk {
      case BNPerk.ColdTrace:        return "Cold Trace";
      case BNPerk.NeuralTap:        return "Neural Tap";
      case BNPerk.SubnetSpecialist: return "Subnet Specialist";
      case BNPerk.ICEAnalyst:       return "ICE Analyst";
      case BNPerk.IntrusionSuite:   return "Intrusion Suite";
      case BNPerk.GhostRun:         return "Ghost Run";
      case BNPerk.TraceScrambler:   return "Trace Scrambler";
      case BNPerk.ZeroSignature:    return "Zero Signature";
      case BNPerk.DisarmICE:        return "Disarm ICE";
      case BNPerk.HidePresence:     return "Hide Presence";
      case BNPerk.Purge:            return "Purge";
      case BNPerk.Sunder:           return "Sunder";
      case BNPerk.TrackingProtocol: return "Tracking Protocol";
      case BNPerk.IceBreaker:       return "Ice Breaker";
      default:                       return "Unknown";
    }
  }

  public static func GetRemoteBreachICEBoard(gi: GameInstance) -> TweakDBID {
    let perkSys: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gi);
    if !IsDefined(perkSys) { return t"Minigame.BNRemoteBreachICEBoard_FPS"; }
    let hasPurge:  Bool = perkSys.GetPerkLevel(BNPerk.Purge)  > 0;
    let hasSunder: Bool = perkSys.GetPerkLevel(BNPerk.Sunder) > 0;
    if hasPurge && hasSunder { return t"Minigame.BNRemoteBreachICEBoard_FPS"; }
    if hasPurge              { return t"Minigame.BNRemoteBreachICEBoard_FP";  }
    if hasSunder             { return t"Minigame.BNRemoteBreachICEBoard_FS";  }
    return t"Minigame.BNRemoteBreachICEBoard_F";
  }
}

@addField(PlayerPuppetPS)
public persistent let bnPerkLevels: array<Int32>;

@addMethod(PlayerPuppet)
public func GetBNPerkLevel(perk: BNPerk) -> Int32 {
  let ps: ref<PlayerPuppetPS> = this.GetPS() as PlayerPuppetPS;
  if !IsDefined(ps) { return 0; }
  let idx: Int32 = EnumInt(perk);
  if idx < 0 || idx >= ArraySize(ps.bnPerkLevels) { return 0; }
  return ps.bnPerkLevels[idx];
}

@addMethod(PlayerPuppet)
public func SetBNPerkLevel(perk: BNPerk, level: Int32) -> Void {
  let ps: ref<PlayerPuppetPS> = this.GetPS() as PlayerPuppetPS;
  if !IsDefined(ps) { return; }
  let idx: Int32 = EnumInt(perk);
  while ArraySize(ps.bnPerkLevels) <= idx {
    ArrayPush(ps.bnPerkLevels, 0);
  }
  ps.bnPerkLevels[idx] = level;
}

@addMethod(PlayerPuppet)
public func GetBNPerkLevelInt(idx: Int32) -> Int32 {
  return this.GetBNPerkLevel(IntEnum<BNPerk>(idx));
}

@addMethod(PlayerPuppet)
public func SetBNPerkLevelInt(idx: Int32, level: Int32) -> Void {
  this.SetBNPerkLevel(IntEnum<BNPerk>(idx), level);
}

public class BNPerkSystem extends ScriptableSystem {

  public static func GetInstance(gameInstance: GameInstance) -> ref<BNPerkSystem> {
    return GameInstance.GetScriptableSystemsContainer(gameInstance)
      .Get(n"BetterNetrunning.Perks.BNPerkSystem") as BNPerkSystem;
  }

  public func GetPerkLevel(perk: BNPerk) -> Int32 {
    let player: ref<PlayerPuppet> = GetPlayer(this.GetGameInstance());
    if !IsDefined(player) { return 0; }
    return player.GetBNPerkLevel(perk);
  }

  public func GetPerkLevelInt(idx: Int32) -> Int32 {
    return this.GetPerkLevel(IntEnum<BNPerk>(idx));
  }
}

