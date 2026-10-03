
module FilthyAccessPoints

@if(ModuleExists("BetterNetrunning"))
import BetterNetrunning.CounterBreach.*

public class DelayedRamJoltHealRequest extends ScriptableSystemRequest {}

public class FilthyAccessPointsSystem extends ScriptableSystem {
    private let m_minigameStateListener: ref<CallbackHandle>;
    private persistent let m_currentIntegrity: Int32;
    private persistent let m_lastUpdateTime: Int32;
    private persistent let m_isInitialized: Bool;
    private let m_isMinigameActive: Bool;
    private let m_activeDeviceID: EntityID;

    public static func GetInstance(gi: GameInstance) -> ref<FilthyAccessPointsSystem> {

        return GameInstance.GetScriptableSystemsContainer(gi).Get(n"FilthyAccessPoints.FilthyAccessPointsSystem") as FilthyAccessPointsSystem;
    }

    public func GetCurrentIntegrity() -> Int32 {
        return this.m_currentIntegrity;
    }

    private func OnRequest(request: ref<PlayerAttachRequest>) -> Void {
        let gi = this.GetGameInstance();

        if !this.m_isInitialized || this.m_lastUpdateTime <= 0 {
            this.m_currentIntegrity = 100;
            this.m_lastUpdateTime = GameTime.GetSeconds(GameInstance.GetTimeSystem(gi).GetGameTime());
            this.m_isInitialized = true;
        }

        this.m_isMinigameActive = false;
        let bbMinigame = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().HackingMinigame);

        if IsDefined(bbMinigame) && !IsDefined(this.m_minigameStateListener) {
            this.m_minigameStateListener = bbMinigame.RegisterListenerInt(GetAllBlackboardDefs().HackingMinigame.State, this, n"OnMinigameStateChanged");
        }
    }

    private func OnRequest(request: ref<PlayerDetachRequest>) -> Void {
        let bbMinigame = GameInstance.GetBlackboardSystem(this.GetGameInstance()).Get(GetAllBlackboardDefs().HackingMinigame);
        if IsDefined(bbMinigame) && IsDefined(this.m_minigameStateListener) {
            bbMinigame.UnregisterListenerInt(GetAllBlackboardDefs().HackingMinigame.State, this.m_minigameStateListener);
            this.m_minigameStateListener = null;
        }
    }

    private func UpdateIntegrity(config: ref<FilthyAccessPointsConfig>) -> Void {
        if !config.enableIntegritySystem { return; }

        let currentTime = GameTime.GetSeconds(GameInstance.GetTimeSystem(this.GetGameInstance()).GetGameTime());
        let secondsPassed = currentTime - this.m_lastUpdateTime;
        let hoursPassed = secondsPassed / 3600;

        if hoursPassed > 0 {
            let oldIntegrity = this.m_currentIntegrity;
            if this.m_currentIntegrity < config.passiveRegenMaxThreshold {
                this.m_currentIntegrity += hoursPassed * config.regenPerHour;
                if this.m_currentIntegrity > config.passiveRegenMaxThreshold {
                    this.m_currentIntegrity = config.passiveRegenMaxThreshold;
                }

                if this.m_currentIntegrity > oldIntegrity {
                    this.ShowWarning(GetLocalizedTextByKey(n"fap_warn_alert") + IntToString(this.m_currentIntegrity) + "%");
                }
            }

            this.m_lastUpdateTime = currentTime - (secondsPassed % 3600);
        }
    }

    public func HealFromRamJolt() -> Void {
        let config = FilthyAccessPointsConfig.Get();
        if !config.modEnabled || !config.enableIntegritySystem || !config.enableRamJoltHealing {
            return;
        }

        if this.m_currentIntegrity >= config.ramJoltMaxThreshold {
            return;
        }

        let delaySystem = GameInstance.GetDelaySystem(this.GetGameInstance());
        let request = new DelayedRamJoltHealRequest();

        delaySystem.DelayScriptableSystemRequest(n"FilthyAccessPoints.FilthyAccessPointsSystem", request, 3.0, false);
    }

    private func OnRequest(request: ref<DelayedRamJoltHealRequest>) -> Void {
        let config = FilthyAccessPointsConfig.Get();
        if !config.modEnabled || !config.enableIntegritySystem || !config.enableRamJoltHealing {
            return;
        }

        let oldIntegrity = this.m_currentIntegrity;
        if this.m_currentIntegrity < config.ramJoltMaxThreshold {
            this.m_currentIntegrity += config.ramJoltHealAmount;
            if this.m_currentIntegrity > config.ramJoltMaxThreshold {
                this.m_currentIntegrity = config.ramJoltMaxThreshold;
            }

            if this.m_currentIntegrity > oldIntegrity {
                this.ShowWarning(GetLocalizedTextByKey(n"fap_warn_alert") + IntToString(this.m_currentIntegrity) + "%");
            }
        }
    }

    public func GetRepairCost() -> Int32 {
        let config = FilthyAccessPointsConfig.Get();
        let missingIntegrity = 100 - this.m_currentIntegrity;
        return missingIntegrity * config.repairCostPerPercent;
    }

    public func TryRepairAtRipperdoc() -> Bool {
        let config = FilthyAccessPointsConfig.Get();
        if !config.modEnabled || !config.enableIntegritySystem || !config.enableRipperdocRepair { return false; }
        if this.m_currentIntegrity >= 100 { return false; }

        let gi = this.GetGameInstance();
        let transactionSystem = GameInstance.GetTransactionSystem(gi);
        let player = GameInstance.GetPlayerSystem(gi).GetLocalPlayerMainGameObject() as PlayerPuppet;

        let cost = this.GetRepairCost();
        if transactionSystem.GetItemQuantity(player, ItemID.FromTDBID(t"Items.money")) >= cost {
            transactionSystem.RemoveItemByTDBID(player, t"Items.money", cost);
            this.m_currentIntegrity = 100;
            this.ShowWarning(GetLocalizedTextByKey(n"fap_warn_repaired"));
            return true;
        }

        return false;
    }

    protected cb func OnMinigameStateChanged(state: Int32) -> Void {
        let config = FilthyAccessPointsConfig.Get();
        if !config.modEnabled { return; }

        let gi = this.GetGameInstance();
        if state == 1 {
            let bbNetwork = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().NetworkBlackboard);
            let deviceID = bbNetwork.GetEntityID(GetAllBlackboardDefs().NetworkBlackboard.DeviceID);

            if !EntityID.IsDefined(deviceID) {
                let player = GameInstance.GetPlayerSystem(gi).GetLocalPlayerMainGameObject() as PlayerPuppet;
                let target = GameInstance.GetTargetingSystem(gi).GetLookAtObject(player) as Device;
                if IsDefined(target) {
                    deviceID = target.GetEntityID();
                }
            }

            if EntityID.IsDefined(deviceID) {
                let device = GameInstance.FindEntityByID(gi, deviceID) as Device;
                if IsDefined(device) {
                    if device.IsA(n"AccessPoint") || device.IsA(n"Computer") || device.IsA(n"VendingMachine") || device.IsA(n"ArcadeMachine") || device.IsA(n"ConfessionBooth") || device.IsA(n"DropPoint") {
                        this.m_isMinigameActive = true;
                        this.m_activeDeviceID = deviceID;
                        return;
                    }
                }
            }

            this.m_isMinigameActive = false;
            return;
        }

        if state == 3 || state == 2 {
            if !this.m_isMinigameActive {
                return;
            }

            this.m_isMinigameActive = false;
            let player = GameInstance.GetPlayerSystem(gi).GetLocalPlayerMainGameObject() as PlayerPuppet;
            let deviceID = this.m_activeDeviceID;

            let emptyID: EntityID;
            this.m_activeDeviceID = emptyID;

            this.UpdateIntegrity(config);
            let isSuccess = state == 2;
            let malwareApplied = false;
            let oldIntegrity = this.m_currentIntegrity;
            let canApplyMalware = config.malwareON && (!isSuccess || config.enableMalwareOnSuccess);

            if config.enablePerfectHackImmunity && canApplyMalware && isSuccess {
                let bbMinigame = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().HackingMinigame);
                if IsDefined(bbMinigame) {
                    let activePrograms = FromVariant<array<TweakDBID>>(bbMinigame.GetVariant(GetAllBlackboardDefs().HackingMinigame.ActivePrograms));

                    if ArraySize(activePrograms) >= config.immunityDaemonThreshold {
                        canApplyMalware = false;
                    }
                }
            }

            if canApplyMalware {
                let finalSourceID = EntityID.IsDefined(deviceID) ? deviceID : player.GetEntityID();
                malwareApplied = this.ApplyRandomMalware(player, config, finalSourceID);
            }

            if config.enableIntegritySystem {
                let lossAmount = isSuccess ? config.integrityLossOnSuccess : config.integrityLossOnFail;

                if lossAmount > 0 {
                    let shouldDeduct = !(config.integrityLossOnlyOnMalware && !malwareApplied);
                    if shouldDeduct {
                        this.m_currentIntegrity -= lossAmount;
                        if this.m_currentIntegrity <= 0 {
                            this.m_currentIntegrity = 0;
                            this.ShowWarning(GetLocalizedTextByKey(n"fap_warn_compromised"));
                            if config.enableDeathAtZero { this.ForceDeepFry(player); }
                        } else if this.m_currentIntegrity < oldIntegrity {
                            this.ShowWarning(GetLocalizedTextByKey(n"fap_warn_alert") + IntToString(this.m_currentIntegrity) + "%");

                            let tutSys = FilthyAccessPointsTutorialSystem.GetInstance(gi);
                            if IsDefined(tutSys) {
                                tutSys.ShowTutorial(player);
                            }
                        }
                    }
                }
            }
        }
    }

    private func ApplyRandomMalware(player: wref<PlayerPuppet>, config: ref<FilthyAccessPointsConfig>, sourceID: EntityID) -> Bool {
        let roll = RandRange(1, 100);
        let pick = 0;
        let malwareType: TweakDBID;
        let iceDamage: Int32 = 0;

        if roll <= config.chanceMalwareHigh {
            iceDamage = 3;
            pick = RandRange(1, 4);
            if pick == 1 { malwareType = t"BaseStatusEffect.CrippleMovement"; }
            else if pick == 2 { malwareType = t"BaseStatusEffect.EMP"; }
            else { malwareType = t"BaseStatusEffect.WeaponMalfunction"; }
        } else if roll <= (config.chanceMalwareHigh + config.chanceMalwareMedium) {
            iceDamage = 2;
            pick = RandRange(1, 4);
            if pick == 1 { malwareType = t"BaseStatusEffect.Overheat"; }
            else if pick == 2 { malwareType = t"BaseStatusEffect.CyberwareMalfunction"; }
            else { malwareType = t"BaseStatusEffect.Burning"; }
        } else if roll <= (config.chanceMalwareHigh + config.chanceMalwareMedium + config.chanceMalwareLow) {
            iceDamage = 1;
            pick = RandRange(1, 3);
            if pick == 1 { malwareType = t"BaseStatusEffect.Blind"; }
            else { malwareType = t"BaseStatusEffect.WeaponMalfunction"; }
        } else {
            return false;
        }

        if this.TryAbsorbIntoICE(player, iceDamage) {
            return true;
        }

        StatusEffectHelper.ApplyStatusEffect(player, malwareType, sourceID);
        return true;
    }

    @if(ModuleExists("BetterNetrunning"))
    private func TryAbsorbIntoICE(player: wref<PlayerPuppet>, damage: Int32) -> Bool {
        let vice: ref<BNVICESystem> = BNVICESystem.GetInstance(player.GetGame());
        if IsDefined(vice) && vice.GetICEHits() >= 1 {
            vice.AbsorbHit(damage, "FAP malware");
            return true;
        }
        return false;
    }

    @if(!ModuleExists("BetterNetrunning"))
    private func TryAbsorbIntoICE(player: wref<PlayerPuppet>, damage: Int32) -> Bool {
        return false;
    }

    private func ForceDeepFry(player: ref<GameObject>) -> Void {
        let gi = player.GetGame();
        let audio = GameInstance.GetAudioSystem(gi);
        let pools = GameInstance.GetStatPoolsSystem(gi);

        audio.Play(n"ui_main_menu_glitch");
        pools.RequestSettingStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, 0.0, player, false);
        this.m_currentIntegrity = 100;
    }

    public func ShowWarning(text: String) -> Void {
        let msg: SimpleScreenMessage;
        msg.isShown = true;
        msg.duration = 5.0;
        msg.message = text;

        let bb = GameInstance.GetBlackboardSystem(this.GetGameInstance()).Get(GetAllBlackboardDefs().UI_Notifications);
        bb.SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(msg), true);
    }

    public func Drain(amount: Int32, source: CName) -> Int32 {
        let config = FilthyAccessPointsConfig.Get();
        if !config.modEnabled || !config.enableIntegritySystem { return this.m_currentIntegrity; }
        if amount <= 0 { return this.m_currentIntegrity; }

        let gi = this.GetGameInstance();
        let player = GameInstance.GetPlayerSystem(gi).GetLocalPlayerMainGameObject();
        let oldIntegrity = this.m_currentIntegrity;
        this.m_currentIntegrity -= amount;
        if this.m_currentIntegrity < 0 { this.m_currentIntegrity = 0; }

        if this.m_currentIntegrity <= 0 {
            this.ShowWarning(GetLocalizedTextByKey(n"fap_warn_compromised"));
            if config.enableDeathAtZero && IsDefined(player) { this.ForceDeepFry(player); }
        } else if this.m_currentIntegrity < oldIntegrity {
            this.ShowWarning(GetLocalizedTextByKey(n"fap_warn_alert") + IntToString(this.m_currentIntegrity) + "%");

            let tutSys = FilthyAccessPointsTutorialSystem.GetInstance(gi);
            if IsDefined(tutSys) && IsDefined(player) {
                tutSys.ShowTutorial(player);
            }
        }

        return this.m_currentIntegrity;
    }

    public func Restore(amount: Int32, source: CName) -> Int32 {
        let config = FilthyAccessPointsConfig.Get();
        if !config.modEnabled || !config.enableIntegritySystem { return this.m_currentIntegrity; }
        if amount <= 0 { return this.m_currentIntegrity; }

        this.m_currentIntegrity += amount;
        if this.m_currentIntegrity > 100 { this.m_currentIntegrity = 100; }
        return this.m_currentIntegrity;
    }
}

@wrapMethod(PlayerPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {
    let result = wrappedMethod(evt);
    if evt.staticData.GetID() == t"BaseStatusEffect.MemoryBooster" {
        let sys = FilthyAccessPointsSystem.GetInstance(this.GetGame());
        if IsDefined(sys) {
            sys.HealFromRamJolt();
        }
    }
    return result;
}

@addMethod(ButtonHints)
public final func AddButtonHintForCost(action: CName, label: String, cost: Int32) -> Void {
    this.AddButtonHint(action, label + " (" + ToString(cost) + ")€$");
}

@wrapMethod(RipperDocGameController)
private final func SetButtonHints(toDefault: Bool, opt isClose: Bool) -> Void {
    wrappedMethod(toDefault, isClose);

    let config = FilthyAccessPointsConfig.Get();
    let sys = FilthyAccessPointsSystem.GetInstance(this.GetPlayerControlledObject().GetGame());

    if config.modEnabled && config.enableIntegritySystem && config.enableRipperdocRepair {
        if IsDefined(sys) && sys.GetCurrentIntegrity() < 100 && IsDefined(this.m_vendorUserData) {
            this.m_buttonHintsController.AddButtonHintForCost(n"repair_personal_link", GetLocalizedTextByKey(n"fap_ui_repair_link"), sys.GetRepairCost());
        }
    }
}

@wrapMethod(RipperDocGameController)
protected cb func OnReleaseInput(e: ref<inkPointerEvent>) -> Bool {
    let config = FilthyAccessPointsConfig.Get();
    if e.IsAction(n"repair_personal_link") && IsDefined(this.m_vendorUserData) && config.modEnabled && config.enableIntegritySystem && config.enableRipperdocRepair {
        let sys = FilthyAccessPointsSystem.GetInstance(this.GetPlayerControlledObject().GetGame());
        if IsDefined(sys) && sys.GetCurrentIntegrity() < 100 {
            let outcome = sys.TryRepairAtRipperdoc();
            if outcome {
                this.m_audioSystem.Play(n"ui_menu_onpress");
                this.m_audioSystem.Play(n"OnSell");
                this.m_buttonHintsController.RemoveButtonHint(n"repair_personal_link");

                let root = this.GetRootWidget() as inkCompoundWidget;
                if IsDefined(root) {
                    let healthyColor = new HDRColor(0.36, 0.96, 0.93, 1.0);
                    let percent = root.GetWidgetByPathName(n"FilthyAccessPointsMeter/IntegrityRow/IntegrityTextPercent") as inkText;
                    let icon = root.GetWidgetByPathName(n"FilthyAccessPointsMeter/IntegrityRow/IntegrityIcon") as inkImage;

                    if IsDefined(icon) { icon.SetTintColor(healthyColor); }
                    if IsDefined(percent) {
                        percent.SetText("100%");
                        percent.SetTintColor(healthyColor);
                    }

                    let i = 0;
                    while i < 20 {
                        let segment = root.GetWidgetByPathName(StringToName("FilthyAccessPointsMeter/IntegrityRow/IntegrityCanvas/Segment" + ToString(i))) as inkRectangle;
                        if IsDefined(segment) {
                            segment.SetTintColor(healthyColor);
                            segment.SetOpacity(1.0);
                        }
                        i += 1;
                    }
                }
            } else {
                let uiMenuNotification = new UIMenuNotificationEvent();
                uiMenuNotification.m_notificationType = UIMenuNotificationType.VNotEnoughMoney;
                this.m_uiSystem.QueueEvent(uiMenuNotification);
            }
        }
    }
    return wrappedMethod(e);
}

@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
    let result = wrappedMethod();

    let config = FilthyAccessPointsConfig.Get();
    if !config.modEnabled || !config.enableIntegritySystem { return result; }

    let sys = FilthyAccessPointsSystem.GetInstance(this.GetPlayerControlledObject().GetGame());
    if !IsDefined(sys) { return result; }

    let integrity = sys.GetCurrentIntegrity();
    let root = this.GetRootWidget() as inkCompoundWidget;

    if IsDefined(root) {
        let mainContainer = new inkVerticalPanel();
        mainContainer.SetName(n"FilthyAccessPointsMeter");
        mainContainer.SetAnchor(inkEAnchor.TopCenter);
        mainContainer.SetAnchorPoint(new Vector2(0.5, 0.0));
        mainContainer.SetMargin(new inkMargin(70.0, 160.0, 0.0, 0.0));

        let rowPanel = new inkHorizontalPanel();
        rowPanel.SetName(n"IntegrityRow");
        rowPanel.SetHAlign(inkEHorizontalAlign.Center);
        mainContainer.AddChildWidget(rowPanel);

        let icon = new inkImage();
        icon.SetName(n"IntegrityIcon");
        icon.SetAtlasResource(r"base\\gameplay\\gui\\common\\icons\\mappin_icons.inkatlas");
        icon.SetTexturePart(n"JackIn");
        icon.SetSize(new Vector2(45.0, 45.0));
        icon.SetVAlign(inkEVerticalAlign.Center);
        icon.SetMargin(new inkMargin(0.0, 0.0, 15.0, 0.0));
        rowPanel.AddChildWidget(icon);

        let barContainer = new inkHorizontalPanel();
        barContainer.SetName(n"IntegrityCanvas");
        barContainer.SetVAlign(inkEVerticalAlign.Center);
        rowPanel.AddChildWidget(barContainer);

        let color: HDRColor;
        if integrity > 50 {
            color = new HDRColor(0.36, 0.96, 0.93, 1.0);
        } else if integrity > 20 {
            color = new HDRColor(1.0, 0.84, 0.0, 1.0);
        } else {
            color = new HDRColor(1.0, 0.2, 0.2, 1.0);
        }

        icon.SetTintColor(color);

        let totalSegments = 20;
        let activeSegments = integrity / 5;
        let i = 0;

        while i < totalSegments {
            let segment = new inkRectangle();
            segment.SetName(StringToName("Segment" + ToString(i)));
            segment.SetSize(new Vector2(23.0, 12.0));
            segment.SetMargin(new inkMargin(0.0, 0.0, 3.0, 0.0));

            if i < activeSegments {
                segment.SetTintColor(color);
                segment.SetOpacity(1.0);
            } else {
                segment.SetTintColor(new HDRColor(0.5, 0.5, 0.5, 1.0));
                segment.SetOpacity(0.2);
            }

            barContainer.AddChildWidget(segment);
            i += 1;
        }

        let textPercent = new inkText();
        textPercent.SetName(n"IntegrityTextPercent");
        textPercent.SetText(ToString(integrity) + "%");
        textPercent.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        textPercent.SetFontStyle(n"Semi-Bold");
        textPercent.SetFontSize(32);
        textPercent.SetVAlign(inkEVerticalAlign.Center);
        textPercent.SetMargin(new inkMargin(15.0, 0.0, 0.0, 0.0));
        textPercent.SetTintColor(color);
        rowPanel.AddChildWidget(textPercent);

        root.AddChildWidget(mainContainer);
    }

    return result;
}