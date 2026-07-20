



















module BetterNetrunning.Logging

import BetterNetrunningConfig.*





public enum LogLevel {
  ERROR = 0,    // Critical errors only
  WARNING = 1,  // Warnings + errors
  INFO = 2,     // Normal information (default)
  DEBUG = 3,    // Detailed debugging
  TRACE = 4     // Very detailed (performance impact)
}





public class LoggerStateSystem extends ScriptableSystem {
  private let m_lastLogMessage: String;
  private let m_lastLogContext: String;
  private let m_lastLogTimestamp: Float;
  private let m_duplicateCount: Int32;

  private func OnAttach() {
    this.m_lastLogMessage = "";
    this.m_lastLogContext = "";
    this.m_lastLogTimestamp = 0.0;
    this.m_duplicateCount = 0;
  }

  public func GetLastMessage() -> String { return this.m_lastLogMessage; }
  public func GetLastContext() -> String { return this.m_lastLogContext; }
  public func GetLastTimestamp() -> Float { return this.m_lastLogTimestamp; }
  public func GetDuplicateCount() -> Int32 { return this.m_duplicateCount; }

  public func SetLastMessage(msg: String) { this.m_lastLogMessage = msg; }
  public func SetLastContext(ctx: String) { this.m_lastLogContext = ctx; }
  public func SetLastTimestamp(time: Float) { this.m_lastLogTimestamp = time; }
  public func SetDuplicateCount(count: Int32) { this.m_duplicateCount = count; }
  public func IncrementDuplicateCount() { this.m_duplicateCount += 1; }
}






private static func GetCurrentLogLevel() -> LogLevel {
  if !BetterNetrunningSettings.EnableDebugLog() {
    return LogLevel.ERROR; // Only errors when debug disabled
  }

  let level: Int32 = BetterNetrunningSettings.DebugLogLevel();

  if level <= 0 {
    return LogLevel.ERROR;
  } else if level == 1 {
    return LogLevel.WARNING;
  } else if level == 2 {
    return LogLevel.INFO;
  } else if level == 3 {
    return LogLevel.DEBUG;
  } else {
    return LogLevel.TRACE;
  }
}






public static func BNError(context: String, message: String) -> Void {
  LogWithLevel(LogLevel.ERROR, context, message);
}


public static func BNWarn(context: String, message: String) -> Void {
  if EnumInt(GetCurrentLogLevel()) >= EnumInt(LogLevel.WARNING) {
    LogWithLevel(LogLevel.WARNING, context, message);
  }
}


public static func BNInfo(context: String, message: String) -> Void {
  if EnumInt(GetCurrentLogLevel()) >= EnumInt(LogLevel.INFO) {
    LogWithLevel(LogLevel.INFO, context, message);
  }
}


public static func BNDebug(context: String, message: String) -> Void {
  if EnumInt(GetCurrentLogLevel()) >= EnumInt(LogLevel.DEBUG) {
    LogWithLevel(LogLevel.DEBUG, context, message);
  }
}


public static func BNTrace(context: String, message: String) -> Void {
  if EnumInt(GetCurrentLogLevel()) >= EnumInt(LogLevel.TRACE) {
    LogWithLevel(LogLevel.TRACE, context, message);
  }
}





private static func LogWithLevel(level: LogLevel, context: String, message: String) -> Void {
  let gameInstance: GameInstance = GetGameInstance();
  let loggerState: ref<LoggerStateSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance).Get(n"BetterNetrunning.Logging.LoggerStateSystem") as LoggerStateSystem;

  if !IsDefined(loggerState) {

    let levelPrefix: String = GetLevelPrefix(level);
    let fullMessage: String = levelPrefix + " [" + context + "] " + message;
    ModLog(n"BetterNetrunning", fullMessage);
    return;
  }

  let currentTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(gameInstance));
  let timeSinceLastLog: Float = currentTime - loggerState.GetLastTimestamp();


  if timeSinceLastLog < 5.0 && Equals(loggerState.GetLastContext(), context) && Equals(loggerState.GetLastMessage(), message) {
    loggerState.IncrementDuplicateCount();
    return; // Suppress duplicate
  }


  if loggerState.GetDuplicateCount() > 0 {
    let levelPrefix: String = GetLevelPrefix(level);
    let summaryMsg: String = levelPrefix + " [" + loggerState.GetLastContext() + "] → Previous message repeated " + ToString(loggerState.GetDuplicateCount()) + " times";
    ModLog(n"BetterNetrunning", summaryMsg);
    loggerState.SetDuplicateCount(0);
  }


  let levelPrefix: String = GetLevelPrefix(level);
  let fullMessage: String = levelPrefix + " [" + context + "] " + message;
  ModLog(n"BetterNetrunning", fullMessage);


  loggerState.SetLastMessage(message);
  loggerState.SetLastContext(context);
  loggerState.SetLastTimestamp(currentTime);
}


private static func GetLevelPrefix(level: LogLevel) -> String {
  switch level {
    case LogLevel.ERROR:   return "[ERROR]  ";
    case LogLevel.WARNING: return "[WARN]   ";
    case LogLevel.INFO:    return "[INFO]   ";
    case LogLevel.DEBUG:   return "[DEBUG]  ";
    case LogLevel.TRACE:   return "[TRACE]  ";
  }
  return "[UNKNOWN]";
}

