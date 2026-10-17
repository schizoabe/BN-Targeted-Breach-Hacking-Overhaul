
module BetterNetrunning.Integration

import BetterNetrunning.Logging.*
import BetterNetrunning.Core.*
import BetterNetrunning.Utils.*

@if(ModuleExists("RadialBreach"))
import RadialBreach.Config.*

@if(ModuleExists("RadialBreach"))
public static func GetRadialBreachRange(gameInstance: GameInstance) -> Float {
  let config: ref<RadialBreachSettings> = new RadialBreachSettings();

  if config.enabled && config.breachRange > 0.0 {
    return config.breachRange;
  }

  return 50.0;
}

@if(!ModuleExists("RadialBreach"))
public static func GetRadialBreachRange(gameInstance: GameInstance) -> Float {
  return 50.0;
}
