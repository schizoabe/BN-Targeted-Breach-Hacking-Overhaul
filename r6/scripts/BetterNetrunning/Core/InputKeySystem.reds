module BetterNetrunning.Core

import BetterNetrunning.Marking.*
import BetterNetrunning.CounterBreach.*
import BetterNetrunning.UI.*

public class BNInputKeySystem extends ScriptableSystem {

    private let m_clearMarksKey:        EInputKey;
    private let m_forceJackOutKey:      EInputKey;
    private let m_cycleBreachModeKey:   EInputKey;
    private let m_toggleHUDPanelsKey:   EInputKey;
    private let m_cycleCascadeQHKey:    EInputKey;
    private let m_dumpRAMForICEKey:     EInputKey;

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
        } else if Equals(key, this.m_cycleCascadeQHKey) {
            BNInputActions.CycleCascadeQH(gi);
        } else if Equals(key, this.m_dumpRAMForICEKey) {
            BNInputActions.DumpRAMForICE(gi);
        }
    }

    public func SetClearMarksKey(key: EInputKey) -> Void      { this.m_clearMarksKey      = key; }
    public func SetForceJackOutKey(key: EInputKey) -> Void    { this.m_forceJackOutKey    = key; }
    public func SetCycleBreachModeKey(key: EInputKey) -> Void { this.m_cycleBreachModeKey = key; }
    public func SetToggleHUDPanelsKey(key: EInputKey) -> Void { this.m_toggleHUDPanelsKey = key; }
    public func SetCycleCascadeQHKey(key: EInputKey) -> Void  { this.m_cycleCascadeQHKey  = key; }
    public func SetDumpRAMForICEKey(key: EInputKey) -> Void   { this.m_dumpRAMForICEKey   = key; }
}

public class BNInputActions {

    public static func HasCyberdeck(player: ref<PlayerPuppet>) -> Bool {
        let equipData = EquipmentSystem.GetData(player);
        if !IsDefined(equipData) { return false; }
        return ItemID.IsValid(equipData.GetActiveItem(gamedataEquipmentArea.SystemReplacementCW));
    }

    public static func ClearMarks(gi: GameInstance) -> Void {
        let ms = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.Marking.MarkingStateSystem") as MarkingStateSystem;
        if IsDefined(ms) {
            ms.ClearAll();
            ms.RefreshMarkBeams();
        }
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

    public static func CycleCascadeQH(gi: GameInstance) -> Void {
        let cbs: ref<CounterBreachSystem> = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.CounterBreach.CounterBreachSystem") as CounterBreachSystem;
        let ms: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.Marking.MarkingStateSystem") as MarkingStateSystem;
        if !IsDefined(ms) { return; }

        let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(gi).GetLocalPlayerMainGameObject() as PlayerPuppet;
        if !IsDefined(player) { return; }
        let deckID: ItemID = EquipmentSystem.GetData(player).GetActiveItem(gamedataEquipmentArea.SystemReplacementCW);
        if !EquipmentSystem.IsItemCyberdeck(deckID) {
            if IsDefined(cbs) { cbs.ShowWarning("CASCADE: NO CYBERDECK"); }
            return;
        }

        let deckData: wref<gameItemData> = GameInstance.GetTransactionSystem(gi).GetItemData(player, deckID);
        let qhActions: array<wref<ObjectAction_Record>>;
        if IsDefined(deckData) {
            let parts: array<InnerItemData>;
            deckData.GetItemParts(parts);
            let pi: Int32 = 0;
            while pi < ArraySize(parts) {
                let part: InnerItemData = parts[pi];
                if ItemID.IsValid(InnerItemData.GetItemID(part)) {
                    let programRec: ref<Item_Record> = InnerItemData.GetStaticData(part);
                    if IsDefined(programRec) {
                        let progActions: array<wref<ObjectAction_Record>>;
                        programRec.ObjectActions(progActions);

                        let ai: Int32 = 0;
                        let foundForProgram: Bool = false;
                        while ai < ArraySize(progActions) && !foundForProgram {
                            let pact: wref<ObjectAction_Record> = progActions[ai];
                            if IsDefined(pact) && IsDefined(pact.ObjectActionType()) &&
                               Equals(pact.ObjectActionType().Type(), gamedataObjectActionType.PuppetQuickHack) {
                                ArrayPush(qhActions, pact);
                                foundForProgram = true;
                            }
                            ai += 1;
                        }
                    }
                }
                pi += 1;
            }
        }
        let count: Int32 = ArraySize(qhActions);
        if count == 0 {
            if IsDefined(cbs) { cbs.ShowWarning("CASCADE: NO QUICKHACK AVAILABLE"); }
            return;
        }

        let newIdx: Int32 = (ms.GetCascadeQHIndex() + 1) % count;
        ms.SetCascadeQHIndex(newIdx);

        let selectedAction: wref<ObjectAction_Record> = qhActions[newIdx];
        let uiFlatID: TweakDBID = selectedAction.GetID();
        TDBID.Append(uiFlatID, t"objectActionUI");
        let uiID: TweakDBID = FromVariant<TweakDBID>(TweakDBInterface.GetFlat(uiFlatID));
        TDBID.Append(uiID, t"caption");
        let captionCN: CName = FromVariant<CName>(TweakDBInterface.GetFlat(uiID));
        let name: String = IsNameValid(captionCN) ? GetLocalizedTextByKey(captionCN) : NameToString(selectedAction.ActionName());

        let testSys: ref<BNTestPanelSystem> = GameInstance.GetScriptableSystemsContainer(gi)
            .Get(n"BetterNetrunning.UI.BNTestPanelSystem") as BNTestPanelSystem;
        if IsDefined(testSys) { testSys.Refresh(0.0); }
    }

    public static func DumpRAMForICE(gi: GameInstance) -> Void {
        let vice = GameInstance.GetScriptableSystemsContainer(gi).Get(n"BetterNetrunning.CounterBreach.BNVICESystem") as BNVICESystem;
        if IsDefined(vice) { vice.DumpRAMForICE(); }
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

            let player = GameInstance.GetPlayerSystem(gi).GetLocalPlayerMainGameObject() as PlayerPuppet;
            if !BNInputActions.HasCyberdeck(player) { return; }
            if IsDefined(bootSys) { bootSys.Show(); }
            if IsDefined(testSys) { testSys.ShowTestPanel(0.0); }
            if IsDefined(logSys)  { logSys.Show(); }
        }
    }
}
