
module BetterNetrunning.Systems

public func NPCRarityToRank(rarity: gamedataNPCRarity) -> Int32 {
  switch rarity {
    case gamedataNPCRarity.Trash:
      return 1;
    case gamedataNPCRarity.Weak:
      return 2;
    case gamedataNPCRarity.Normal:
      return 3;
    case gamedataNPCRarity.Rare:
      return 4;
    case gamedataNPCRarity.Officer:
      return 5;
    case gamedataNPCRarity.Elite:
      return 6;
    case gamedataNPCRarity.Boss:
      return 7;
    case gamedataNPCRarity.MaxTac:
      return 8;
  }
  return 0;
}
