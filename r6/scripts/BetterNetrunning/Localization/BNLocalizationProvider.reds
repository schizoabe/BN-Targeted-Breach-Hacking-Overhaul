module BetterNetrunning.Localization

import Codeware.Localization.*

public class BNLocalizationProvider extends ModLocalizationProvider {
  public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    switch language {
      default: return new BNLocEnglish();
    };
  }

  public func GetFallback() -> CName {
    return n"en-us";
  }
}
