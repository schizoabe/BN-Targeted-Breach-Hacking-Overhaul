
module BetterNetrunning.UI

public abstract class BNUIScale {

  public static func GetScale(gi: GameInstance) -> Float {
    let inkSystem = GameInstance.GetInkSystem();
    if !IsDefined(inkSystem) { return 1.0; }
    let hudLayer = inkSystem.GetLayer(n"inkHUDLayer");
    if !IsDefined(hudLayer) { return 1.0; }
    let hudRoot = hudLayer.GetVirtualWindow();
    if !IsDefined(hudRoot) { return 1.0; }
    let size: Vector2 = hudRoot.GetSize();
    if size.X <= 0.0 || size.Y <= 0.0 { return 1.0; }
    return MinF(size.X / 2560.0, size.Y / 1440.0);
  }
}
