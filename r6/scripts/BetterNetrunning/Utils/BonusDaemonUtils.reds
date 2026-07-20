



module BetterNetrunning.Utils
import BetterNetrunning.Logging.*

import BetterNetrunning.Core.*

public abstract class BonusDaemonUtils {






  public static func HasProgram(programs: array<TweakDBID>, programID: TweakDBID) -> Bool {
    let i: Int32 = 0;
    while i < ArraySize(programs) {
      if Equals(programs[i], programID) {
        return true;
      }
      i += 1;
    }
    return false;
  }


  public static func IsDatamineDaemon(programID: TweakDBID) -> Bool {
    return Equals(programID, BNConstants.PROGRAM_DATAMINE_BASIC())
        || Equals(programID, BNConstants.PROGRAM_DATAMINE_ADVANCED())
        || Equals(programID, BNConstants.PROGRAM_DATAMINE_MASTER());
  }

} // class BonusDaemonUtils

