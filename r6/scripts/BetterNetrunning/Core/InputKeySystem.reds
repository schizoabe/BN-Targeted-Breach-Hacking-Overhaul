module BetterNetrunning.Core

import BetterNetrunning.Marking.*
import BetterNetrunning.CounterBreach.*
import BetterNetrunning.UI.*

public class BNInputKeySystem extends ScriptableSystem {

    private let m_clearMarksKey:      EInputKey;
    private let m_forceJackOutKey:    EInputKey;
    private let m_cycleBreachModeKey: EInputKey;
    private let m_toggleHUDPanelsKey: EInputKey;

    public static func GetInstance(gi: GameInstance) -> ref<BNInputKeySystem> {
        return GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.Core.BNInputKeySystem") as BNInputKeySystem;
    }

    private cb func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
        GameInstance.GetCallbackSystem().RegisterCallback(n"Input/Key", this, n"OnKeyInput", true);
    }

    private cb func OnPlayerDetach(request: ref<PlayerDetachRequest>) -> Void {
        GameInstance.GetCallbackSystem().UnregisterCallback(n"Input/Key", this, n"OnKeyInput");
    }

    public cb func OnKeyInput(event: ref<KeyInputEvent>) -> Void {
        if !Equals(event.GetAction(), EInputAction.IACT_Release) { return; }
        let key = event.GetKey();
        let gi  = this.GetGameInstance();
        if Equals(key, this.m_clearMarksKey) {
            BNInputActions.ClearMarks(gi);
        } else if Equals(key, this.m_forceJackOutKey) {
            BNInputActions.ForceJackOut(gi);
        } else if Equals(key, this.m_cycleBreachModeKey) {
            let player = GameInstance.GetPlayerSystem(gi).GetLocalPlayerMainGameObject() as PlayerPuppet;
            BNInputActions.CycleBreachMode(gi, BNInputActions.HasCyberdeck(player));
        } else if Equals(key, this.m_toggleHUDPanelsKey) {
            BNInputActions.ToggleHUDPanels(gi);
        }
    }

    public func ApplyHotkeys(clearMarks: String, forceJackOut: String, cycleBreachMode: String, toggleHUDPanels: String) -> Void {
        this.m_clearMarksKey      = IntEnum<EInputKey>(Cast<Int32>(EnumValueFromString("EInputKey", clearMarks)));
        this.m_forceJackOutKey    = IntEnum<EInputKey>(Cast<Int32>(EnumValueFromString("EInputKey", forceJackOut)));
        this.m_cycleBreachModeKey = IntEnum<EInputKey>(Cast<Int32>(EnumValueFromString("EInputKey", cycleBreachMode)));
        this.m_toggleHUDPanelsKey = IntEnum<EInputKey>(Cast<Int32>(EnumValueFromString("EInputKey", toggleHUDPanels)));
    }
}

public class BNInputActions {

    public static func HasCyberdeck(player: ref<PlayerPuppet>) -> Bool {
        let equipData = EquipmentSystem.GetData(player);
        if !IsDefined(equipData) { return false; }
        return ItemID.IsValid(equipData.GetActiveItem(gamedataEquipmentArea.SystemReplacementCW));
    }

    public static func ClearMarks(gi: GameInstance) -> Void {
        let ms = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.Marking.MarkingStateSystem") as MarkingStateSystem;
        if IsDefined(ms) { ms.ClearAll(); }
        let testSys = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.UI.BNTestPanelSystem") as BNTestPanelSystem;
        let logSys  = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
        if IsDefined(testSys) { testSys.Hide(); }
        if IsDefined(logSys)  { logSys.Hide(); }
    }

    public static func ForceJackOut(gi: GameInstance) -> Void {
        let cbs = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.CounterBreach.CounterBreachSystem") as CounterBreachSystem;
        if IsDefined(cbs) { cbs.ForceJackOut(); }
    }

    public static func CycleBreachMode(gi: GameInstance, hasDeck: Bool) -> Void {
        let cbs = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.CounterBreach.CounterBreachSystem") as CounterBreachSystem;
        if !hasDeck {
            if IsDefined(cbs) { cbs.ShowWarning("NO CYBERDECK — SCOUT MODE ONLY"); }
            return;
        }
        let ms = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.Marking.MarkingStateSystem") as MarkingStateSystem;
        if !IsDefined(ms) { return; }
        let nextMode = (ms.GetBreachMode() + 1) % 3;
        ms.SetBreachMode(nextMode);
        let label: String;
        if nextMode == 0      { label = "SCOUT"; }
        else if nextMode == 1 { label = "ATTACK"; }
        else                  { label = "DEFEND"; }
        if IsDefined(cbs) { cbs.ShowWarning("BREACH MODE: " + label); }
    }

    public static func ToggleHUDPanels(gi: GameInstance) -> Void {
        let logSys  = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
        let testSys = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.UI.BNTestPanelSystem") as BNTestPanelSystem;
        let bootSys = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.UI.BNBootSystem") as BNBootSystem;
        let visible = IsDefined(logSys) && logSys.IsVisible();
        if visible {
            if IsDefined(bootSys) { bootSys.Abort(); }
            if IsDefined(testSys) { testSys.Hide(); }
            if IsDefined(logSys)  { logSys.Hide(); }
        } else {
            if IsDefined(bootSys) { bootSys.Show(); }
            if IsDefined(testSys) { testSys.ShowTestPanel(0.0); }
            if IsDefined(logSys)  { logSys.Show(); }
        }
    }
}
