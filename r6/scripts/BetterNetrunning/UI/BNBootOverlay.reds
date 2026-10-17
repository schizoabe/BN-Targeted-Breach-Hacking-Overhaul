
module BetterNetrunning.UI

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Marking.*

public class BNBootOverlay {
    private let m_canvas:       ref<inkCanvas>;
    private let m_title:        ref<inkText>;
    private let m_progressFill: ref<inkImage>;
    private let m_animProxy:    ref<inkAnimProxy>;

    public static func Create(parent: ref<inkCompoundWidget>, gi: GameInstance) -> ref<BNBootOverlay> {
        let overlay = new BNBootOverlay();
        overlay.Build(parent, BNUIScale.GetScale(gi));
        return overlay;
    }

    private func Build(parent: ref<inkCompoundWidget>, scale: Float) -> Void {
        let w:     Float = 520.0 * scale;
        let h:     Float = 110.0 * scale;
        let sideW: Float = 50.0 * scale;
        let txtX:  Float = sideW + 20.0 * scale;
        let barW:  Float = w - txtX - 12.0 * scale;

        let canvas = new inkCanvas();
        canvas.SetName(n"BNBootInner");
        canvas.SetAnchor(inkEAnchor.TopLeft);
        canvas.SetAnchorPoint(new Vector2(0.0, 0.0));
        canvas.SetSize(new Vector2(w, h));
        canvas.SetRenderTransformPivot(new Vector2(0.5, 0.0));
        canvas.SetVisible(false);
        canvas.Reparent(parent);
        this.m_canvas = canvas;

        let title = new inkText();
        title.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        title.SetFontSize(Cast<Int32>(18.0 * scale));
        title.SetLetterCase(textLetterCase.UpperCase);
        title.SetAnchor(inkEAnchor.TopLeft);
        title.SetMargin(new inkMargin(txtX, 26.0 * scale, 12.0 * scale, 0.0));
        title.SetTintColor(new HDRColor(1.2, 0.78, 0.12, 1.0));
        title.SetText(GetLocalizedTextByKey(n"Better-Netrunning-UI-Boot-Title") + " CYBERDECK");
        title.Reparent(canvas);
        this.m_title = title;

        let barBg = new inkImage();
        barBg.SetAnchor(inkEAnchor.TopLeft);
        barBg.SetMargin(new inkMargin(txtX, 65.0 * scale, 0.0, 0.0));
        barBg.SetSize(new Vector2(barW, 6.0 * scale));
        barBg.SetBrushMirrorType(inkBrushMirrorType.NoMirror);
        barBg.SetBrushTileType(inkBrushTileType.NoTile);
        barBg.SetAtlasResource(r"base\\gameplay\\gui\\common\\tooltip\\tooltips_new.inkatlas");
        barBg.SetTexturePart(n"generic_background");
        barBg.SetTintColor(new HDRColor(0.06, 0.05, 0.02, 1.0));
        barBg.SetOpacity(0.9);
        barBg.Reparent(canvas);

        let barFill = new inkImage();
        barFill.SetAnchor(inkEAnchor.TopLeft);
        barFill.SetMargin(new inkMargin(txtX, 65.0 * scale, 0.0, 0.0));
        barFill.SetSize(new Vector2(barW, 6.0 * scale));
        barFill.SetRenderTransformPivot(new Vector2(0.0, 0.5));
        barFill.SetBrushMirrorType(inkBrushMirrorType.NoMirror);
        barFill.SetBrushTileType(inkBrushTileType.NoTile);
        barFill.SetAtlasResource(r"base\\gameplay\\gui\\common\\tooltip\\tooltips_new.inkatlas");
        barFill.SetTexturePart(n"generic_background");
        barFill.SetTintColor(new HDRColor(0.90, 0.58, 0.10, 1.0));
        barFill.Reparent(canvas);
        this.m_progressFill = barFill;
    }

    public func Show(gi: GameInstance) -> Void {
        if !IsDefined(this.m_canvas) { return; }

        if IsDefined(this.m_animProxy) && this.m_animProxy.IsPlaying() {
            this.m_animProxy.Stop();
        }

        let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
            .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
        if IsDefined(mss) && IsDefined(this.m_title) {
            this.m_title.SetText(GetLocalizedTextByKey(n"Better-Netrunning-UI-Boot-Title") + " " + mss.GetEquippedCyberdeckName());
        }

        this.m_canvas.SetOpacity(0.0);
        this.m_canvas.SetVisible(true);

        let def = new inkAnimDef();

        let scaleIn = new inkAnimScale();
        scaleIn.SetStartScale(new Vector2(1.0, 0.0));
        scaleIn.SetEndScale(new Vector2(1.0, 1.0));
        scaleIn.SetDuration(0.2);
        scaleIn.SetType(inkanimInterpolationType.Exponential);
        scaleIn.SetMode(inkanimInterpolationMode.EasyOut);
        def.AddInterpolator(scaleIn);

        let opacIn = new inkAnimTransparency();
        opacIn.SetStartTransparency(0.0);
        opacIn.SetEndTransparency(1.0);
        opacIn.SetDuration(0.2);
        opacIn.SetType(inkanimInterpolationType.Linear);
        def.AddInterpolator(opacIn);

        let scaleOut = new inkAnimScale();
        scaleOut.SetStartScale(new Vector2(1.0, 1.0));
        scaleOut.SetEndScale(new Vector2(1.0, 0.0));
        scaleOut.SetDuration(0.25);
        scaleOut.SetStartDelay(1.3);
        scaleOut.SetType(inkanimInterpolationType.Exponential);
        scaleOut.SetMode(inkanimInterpolationMode.EasyIn);
        def.AddInterpolator(scaleOut);

        let opacOut = new inkAnimTransparency();
        opacOut.SetStartTransparency(1.0);
        opacOut.SetEndTransparency(0.0);
        opacOut.SetDuration(0.2);
        opacOut.SetStartDelay(1.3);
        opacOut.SetType(inkanimInterpolationType.Linear);
        def.AddInterpolator(opacOut);

        this.m_animProxy = this.m_canvas.PlayAnimation(def);

        let barDef = new inkAnimDef();
        let barScale = new inkAnimScale();
        barScale.SetStartScale(new Vector2(0.0, 1.0));
        barScale.SetEndScale(new Vector2(1.0, 1.0));
        barScale.SetDuration(1.2);
        barScale.SetStartDelay(0.1);
        barScale.SetType(inkanimInterpolationType.Linear);
        barDef.AddInterpolator(barScale);
        this.m_progressFill.PlayAnimation(barDef);
    }

    public func Abort() -> Void {
        if !IsDefined(this.m_canvas) { return; }
        if IsDefined(this.m_animProxy) && this.m_animProxy.IsPlaying() {
            this.m_animProxy.Stop();
        }
        this.m_canvas.SetVisible(false);
    }
}

public class BNBootSystem extends ScriptableSystem {
    private let m_overlay: ref<BNBootOverlay>;

    public func RegisterOverlay(overlay: ref<BNBootOverlay>) -> Void {
        this.m_overlay = overlay;
    }

    public func Show() -> Void {
        if IsDefined(this.m_overlay) {
            this.m_overlay.Show(this.GetGameInstance());
        }
    }

    public func Abort() -> Void {
        if IsDefined(this.m_overlay) { this.m_overlay.Abort(); }
    }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
    let result: Bool = wrappedMethod();
    let gi: GameInstance = this.GetGame();

    let sys: ref<BNBootSystem> = GameInstance.GetScriptableSystemsContainer(gi)
        .Get(n"BetterNetrunning.UI.BNBootSystem") as BNBootSystem;
    if !IsDefined(sys) {
        BNWarn("UI", "BNBootOverlay: BNBootSystem unavailable — boot overlay skipped");
        return result;
    }

    let inkSystem = GameInstance.GetInkSystem();
    if !IsDefined(inkSystem) { return result; }
    let hudLayer = inkSystem.GetLayer(n"inkHUDLayer");
    if !IsDefined(hudLayer) { return result; }
    let hudRoot = hudLayer.GetVirtualWindow();
    if !IsDefined(hudRoot) { return result; }

    hudRoot.RemoveChildByName(n"BNBootCanvas");

    let scale: Float = BNUIScale.GetScale(gi);

    let canvas = new inkCanvas();
    canvas.SetName(n"BNBootCanvas");
    canvas.SetAnchor(inkEAnchor.TopLeft);
    canvas.SetAnchorPoint(new Vector2(0.0, 0.0));
    canvas.SetMargin(new inkMargin(20.0 * scale, 320.0 * scale, 0.0, 0.0));
    canvas.SetSize(new Vector2(520.0 * scale, 110.0 * scale));
    canvas.Reparent(hudRoot);

    sys.RegisterOverlay(BNBootOverlay.Create(canvas, gi));
    BNInfo("UI", "BNBootOverlay injected");

    return result;
}
