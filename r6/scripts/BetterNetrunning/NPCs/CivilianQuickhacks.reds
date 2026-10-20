
module BetterNetrunning.NPCs

@wrapMethod(ScriptedPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  if this.IsCrowd() {
    this.UpdateQuickHackableState(true);
    this.UpdateLootInteraction();
  } else if this.IsVendor() {
    this.UpdateQuickHackableState(true);
  };
  return result;
}

@wrapMethod(ScriptedPuppet)
protected func ToggleInteractionLayers() -> Void {
  wrappedMethod();
  if this.IsCrowd() {
    if this.GetRecord().CanHaveGenericTalk() {
      this.EnableInteraction(n"GenericTalk", true);
    };
    this.EnableInteraction(n"Grapple", true);
    this.EnableInteraction(n"TakedownLayer", true);
    this.EnableInteraction(n"AerialTakedown", true);
    this.EnableInteraction(n"Loot", true);
  };
}

@wrapMethod(ScriptedPuppet)
public const func IsQuickHackAble() -> Bool {
  let result: Bool = wrappedMethod();
  if this.IsCrowd() { return true; };
  if this.IsVendor() { return true; };
  return result;
}

@wrapMethod(ScriptedPuppet)
protected const func ShouldRegisterToHUD() -> Bool {
  if this.IsCrowd() { return true; };
  if this.IsVendor() { return true; };
  return wrappedMethod();
}

@wrapMethod(ScriptedPuppet)
public const func GetCurrentOutline() -> EFocusOutlineType {
  if (this.IsCivilian() && !this.IsAggressive()) || this.IsVendor() {
    return EFocusOutlineType.NEUTRAL;
  };
  if GameObject.IsFriendlyTowardsPlayer(this) {
    return EFocusOutlineType.FRIENDLY;
  };
  return wrappedMethod();
}

