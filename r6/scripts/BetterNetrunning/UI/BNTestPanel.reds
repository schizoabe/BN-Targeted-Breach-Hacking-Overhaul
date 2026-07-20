module BetterNetrunning.UI

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.Marking.*
import BetterNetrunning.Perks.*

public class BNTestPanel {
    private let m_canvas:        ref<inkCanvas>;
    private let m_animProxy:     ref<inkAnimProxy>;
    private let m_isVisible:     Bool;

    private let m_bg:            ref<inkImage>;
    private let m_frame:         ref<inkImage>;
    private let m_sidebar:       ref<inkImage>;
    private let m_footerFluff:   ref<inkImage>;

    private let m_deckLine:      ref<inkText>;
    private let m_marksLine:     ref<inkText>;
    private let m_heatLabel:     ref<inkText>;
    private let m_signalLabel:   ref<inkText>;
    private let m_hideLabel:     ref<inkText>;
    private let m_disarmLabel:   ref<inkText>;
    private let m_counterLabel:  ref<inkText>;

    private let m_div3:          ref<inkRectangle>;

    private let m_signalTrack:   ref<inkRectangle>;
    private let m_hideTrack:     ref<inkRectangle>;
    private let m_disarmTrack:   ref<inkRectangle>;
    private let m_counterTrack:  ref<inkRectangle>;

    private let m_heatFill:      ref<inkRectangle>;
    private let m_signalFill:    ref<inkRectangle>;
    private let m_hideFill:      ref<inkRectangle>;
    private let m_disarmFill:    ref<inkRectangle>;
    private let m_counterFill:   ref<inkRectangle>;

    public static func Create(parent: ref<inkCompoundWidget>) -> ref<BNTestPanel> {
        let p = new BNTestPanel();
        p.Build(parent);
        return p;
    }

    private func Build(parent: ref<inkCompoundWidget>) -> Void {
        let w:      Float = 520.0;
        let h:      Float = 296.0;
        let sideW:  Float = 50.0;
        let txtX:   Float = sideW + 20.0;    // 70
        let trackW: Float = w - txtX - 12.0; // 438

        let canvas = new inkCanvas();
        canvas.SetName(n"BNTestInner");
        canvas.SetAnchor(inkEAnchor.TopLeft);
        canvas.SetAnchorPoint(new Vector2(0.0, 0.0));
        canvas.SetSize(new Vector2(w, h));
        canvas.SetRenderTransformPivot(new Vector2(0.5, 0.0));
        canvas.SetVisible(false);
        canvas.Reparent(parent);
        this.m_canvas = canvas;

        let bg = new inkImage();
        bg.SetAnchor(inkEAnchor.TopLeft);
        bg.SetSize(new Vector2(w, h));
        bg.SetBrushMirrorType(inkBrushMirrorType.NoMirror);
        bg.SetBrushTileType(inkBrushTileType.NoTile);
        bg.SetAtlasResource(r"base\\gameplay\\gui\\common\\tooltip\\tooltips_new.inkatlas");
        bg.SetTexturePart(n"generic_background");
        bg.SetTintColor(new HDRColor(0.04, 0.03, 0.01, 1.0));
        bg.SetOpacity(0.72);
        bg.Reparent(canvas);
        this.m_bg = bg;

        let frame = new inkImage();
        frame.SetAnchor(inkEAnchor.TopLeft);
        frame.SetSize(new Vector2(w, h));
        frame.SetBrushMirrorType(inkBrushMirrorType.NoMirror);
        frame.SetBrushTileType(inkBrushTileType.NoTile);
        frame.SetAtlasResource(r"base\\gameplay\\gui\\common\\tooltip\\tooltips_new.inkatlas");
        frame.SetTexturePart(n"generic_background_fg");
        frame.SetTintColor(new HDRColor(0.90, 0.58, 0.10, 1.0));
        frame.Reparent(canvas);
        this.m_frame = frame;

        let sidebar = new inkImage();
        sidebar.SetAnchor(inkEAnchor.TopLeft);
        sidebar.SetSize(new Vector2(sideW, h - 20.0));
        sidebar.SetMargin(new inkMargin(8.0, 10.0, 0.0, 0.0));
        sidebar.SetBrushMirrorType(inkBrushMirrorType.NoMirror);
        sidebar.SetBrushTileType(inkBrushTileType.NoTile);
        sidebar.SetAtlasResource(r"base\\gameplay\\gui\\quests\\assets\\sq021_farms_map.inkatlas");
        sidebar.SetTexturePart(n"Frame_FG");
        sidebar.SetTintColor(new HDRColor(0.90, 0.58, 0.10, 1.0));
        sidebar.Reparent(canvas);
        this.m_sidebar = sidebar;

        let title = new inkText();
        title.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        title.SetFontSize(20);
        title.SetLetterCase(textLetterCase.UpperCase);
        title.SetAnchor(inkEAnchor.TopLeft);
        title.SetMargin(new inkMargin(txtX, 10.0, 12.0, 0.0));
        title.SetTintColor(new HDRColor(1.2, 0.78, 0.12, 1.0));
        title.SetText("Network Status  //  Daemon Feed");
        title.Reparent(canvas);

        let deckLine = new inkText();
        deckLine.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        deckLine.SetFontSize(10);
        deckLine.SetLetterCase(textLetterCase.UpperCase);
        deckLine.SetAnchor(inkEAnchor.TopLeft);
        deckLine.SetMargin(new inkMargin(txtX, 30.0, 12.0, 0.0));
        deckLine.SetTintColor(new HDRColor(0.70, 0.45, 0.08, 0.55));
        deckLine.SetText("CYBERDECK");
        deckLine.Reparent(canvas);
        this.m_deckLine = deckLine;

        let div1 = new inkRectangle();
        div1.SetAnchor(inkEAnchor.TopLeft);
        div1.SetMargin(new inkMargin(txtX, 50.0, 0.0, 0.0));
        div1.SetSize(new Vector2(trackW, 1.0));
        div1.SetTintColor(new HDRColor(0.90, 0.58, 0.10, 0.5));
        div1.Reparent(canvas);

        let marksLine = new inkText();
        marksLine.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        marksLine.SetFontSize(15);
        marksLine.SetLetterCase(textLetterCase.UpperCase);
        marksLine.SetAnchor(inkEAnchor.TopLeft);
        marksLine.SetMargin(new inkMargin(txtX, 62.0, 12.0, 0.0));
        marksLine.SetTintColor(new HDRColor(1.2, 0.78, 0.12, 1.0));
        marksLine.SetText("ACTIVE MARKS ... 0");
        marksLine.Reparent(canvas);
        this.m_marksLine = marksLine;

        let div2 = new inkRectangle();
        div2.SetAnchor(inkEAnchor.TopLeft);
        div2.SetMargin(new inkMargin(txtX, 82.0, 0.0, 0.0));
        div2.SetSize(new Vector2(trackW, 1.0));
        div2.SetTintColor(new HDRColor(0.90, 0.58, 0.10, 0.3));
        div2.Reparent(canvas);

        let heatLabel = new inkText();
        heatLabel.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        heatLabel.SetFontSize(14);
        heatLabel.SetLetterCase(textLetterCase.UpperCase);
        heatLabel.SetAnchor(inkEAnchor.TopLeft);
        heatLabel.SetMargin(new inkMargin(txtX, 92.0, 12.0, 0.0));
        heatLabel.SetTintColor(new HDRColor(1.2, 0.78, 0.12, 1.0));
        heatLabel.SetText("NETWORK HEAT ... COLD 0%");
        heatLabel.Reparent(canvas);
        this.m_heatLabel = heatLabel;

        let heatTrack = new inkRectangle();
        heatTrack.SetAnchor(inkEAnchor.TopLeft);
        heatTrack.SetMargin(new inkMargin(txtX, 110.0, 0.0, 0.0));
        heatTrack.SetSize(new Vector2(trackW, 10.0));
        heatTrack.SetTintColor(new HDRColor(0.08, 0.08, 0.06, 1.0));
        heatTrack.Reparent(canvas);

        let heatFill = new inkRectangle();
        heatFill.SetAnchor(inkEAnchor.TopLeft);
        heatFill.SetMargin(new inkMargin(txtX, 110.0, 0.0, 0.0));
        heatFill.SetSize(new Vector2(1.0, 10.0));
        heatFill.SetTintColor(new HDRColor(0.15, 1.1, 0.15, 1.0));
        heatFill.Reparent(canvas);
        this.m_heatFill = heatFill;

        let signalLabel = new inkText();
        signalLabel.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        signalLabel.SetFontSize(14);
        signalLabel.SetLetterCase(textLetterCase.UpperCase);
        signalLabel.SetAnchor(inkEAnchor.TopLeft);
        signalLabel.SetMargin(new inkMargin(txtX, 118.0, 12.0, 0.0));
        signalLabel.SetTintColor(new HDRColor(0.05, 0.50, 0.50, 0.7));
        signalLabel.SetText("RAVEN ... READY");
        signalLabel.Reparent(canvas);
        this.m_signalLabel = signalLabel;

        let signalTrack = new inkRectangle();
        signalTrack.SetAnchor(inkEAnchor.TopLeft);
        signalTrack.SetMargin(new inkMargin(txtX, 136.0, 0.0, 0.0));
        signalTrack.SetSize(new Vector2(trackW, 10.0));
        signalTrack.SetTintColor(new HDRColor(0.08, 0.08, 0.06, 1.0));
        signalTrack.SetVisible(false);
        signalTrack.Reparent(canvas);
        this.m_signalTrack = signalTrack;

        let signalFill = new inkRectangle();
        signalFill.SetAnchor(inkEAnchor.TopLeft);
        signalFill.SetMargin(new inkMargin(txtX, 136.0, 0.0, 0.0));
        signalFill.SetSize(new Vector2(1.0, 10.0));
        signalFill.SetTintColor(new HDRColor(0.10, 0.80, 0.75, 1.0));
        signalFill.SetVisible(false);
        signalFill.Reparent(canvas);
        this.m_signalFill = signalFill;

        let hideLabel = new inkText();
        hideLabel.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        hideLabel.SetFontSize(14);
        hideLabel.SetLetterCase(textLetterCase.UpperCase);
        hideLabel.SetAnchor(inkEAnchor.TopLeft);
        hideLabel.SetMargin(new inkMargin(txtX, 144.0, 12.0, 0.0));
        hideLabel.SetTintColor(new HDRColor(0.60, 0.40, 0.08, 0.4));
        hideLabel.SetText("GHOST ... OFFLINE");
        hideLabel.Reparent(canvas);
        this.m_hideLabel = hideLabel;

        let hideTrack = new inkRectangle();
        hideTrack.SetAnchor(inkEAnchor.TopLeft);
        hideTrack.SetMargin(new inkMargin(txtX, 162.0, 0.0, 0.0));
        hideTrack.SetSize(new Vector2(trackW, 10.0));
        hideTrack.SetTintColor(new HDRColor(0.08, 0.08, 0.06, 1.0));
        hideTrack.SetVisible(false);
        hideTrack.Reparent(canvas);
        this.m_hideTrack = hideTrack;

        let hideFill = new inkRectangle();
        hideFill.SetAnchor(inkEAnchor.TopLeft);
        hideFill.SetMargin(new inkMargin(txtX, 162.0, 0.0, 0.0));
        hideFill.SetSize(new Vector2(1.0, 10.0));
        hideFill.SetTintColor(new HDRColor(0.20, 0.60, 1.40, 1.0));
        hideFill.SetVisible(false);
        hideFill.Reparent(canvas);
        this.m_hideFill = hideFill;

        let disarmLabel = new inkText();
        disarmLabel.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        disarmLabel.SetFontSize(14);
        disarmLabel.SetLetterCase(textLetterCase.UpperCase);
        disarmLabel.SetAnchor(inkEAnchor.TopLeft);
        disarmLabel.SetMargin(new inkMargin(txtX, 170.0, 12.0, 0.0));
        disarmLabel.SetTintColor(new HDRColor(0.60, 0.40, 0.08, 0.4));
        disarmLabel.SetText("NULL ... OFFLINE");
        disarmLabel.Reparent(canvas);
        this.m_disarmLabel = disarmLabel;

        let disarmTrack = new inkRectangle();
        disarmTrack.SetAnchor(inkEAnchor.TopLeft);
        disarmTrack.SetMargin(new inkMargin(txtX, 188.0, 0.0, 0.0));
        disarmTrack.SetSize(new Vector2(trackW, 10.0));
        disarmTrack.SetTintColor(new HDRColor(0.08, 0.08, 0.06, 1.0));
        disarmTrack.SetVisible(false);
        disarmTrack.Reparent(canvas);
        this.m_disarmTrack = disarmTrack;

        let disarmFill = new inkRectangle();
        disarmFill.SetAnchor(inkEAnchor.TopLeft);
        disarmFill.SetMargin(new inkMargin(txtX, 188.0, 0.0, 0.0));
        disarmFill.SetSize(new Vector2(1.0, 10.0));
        disarmFill.SetTintColor(new HDRColor(1.10, 0.90, 0.10, 1.0));
        disarmFill.SetVisible(false);
        disarmFill.Reparent(canvas);
        this.m_disarmFill = disarmFill;

        let div3 = new inkRectangle();
        div3.SetAnchor(inkEAnchor.TopLeft);
        div3.SetMargin(new inkMargin(txtX, 196.0, 0.0, 0.0));
        div3.SetSize(new Vector2(trackW, 1.0));
        div3.SetTintColor(new HDRColor(0.90, 0.58, 0.10, 0.5));
        div3.Reparent(canvas);
        this.m_div3 = div3;

        let counterLabel = new inkText();
        counterLabel.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        counterLabel.SetFontSize(14);
        counterLabel.SetLetterCase(textLetterCase.UpperCase);
        counterLabel.SetAnchor(inkEAnchor.TopLeft);
        counterLabel.SetMargin(new inkMargin(txtX, 208.0, 12.0, 0.0));
        counterLabel.SetTintColor(new HDRColor(1.2, 0.78, 0.12, 0.5));
        counterLabel.SetText("ICE BREACH ... NOMINAL");
        counterLabel.Reparent(canvas);
        this.m_counterLabel = counterLabel;

        let counterTrack = new inkRectangle();
        counterTrack.SetAnchor(inkEAnchor.TopLeft);
        counterTrack.SetMargin(new inkMargin(txtX, 226.0, 0.0, 0.0));
        counterTrack.SetSize(new Vector2(trackW, 10.0));
        counterTrack.SetTintColor(new HDRColor(0.08, 0.08, 0.06, 1.0));
        counterTrack.SetVisible(false);
        counterTrack.Reparent(canvas);
        this.m_counterTrack = counterTrack;

        let counterFill = new inkRectangle();
        counterFill.SetAnchor(inkEAnchor.TopLeft);
        counterFill.SetMargin(new inkMargin(txtX, 226.0, 0.0, 0.0));
        counterFill.SetSize(new Vector2(1.0, 10.0));
        counterFill.SetTintColor(new HDRColor(1.50, 0.08, 0.05, 1.0));
        counterFill.SetVisible(false);
        counterFill.Reparent(canvas);
        this.m_counterFill = counterFill;

        let footerFluff = new inkImage();
        footerFluff.SetAnchor(inkEAnchor.TopLeft);
        footerFluff.SetSize(new Vector2(trackW, 18.0));
        footerFluff.SetMargin(new inkMargin(txtX, h - 25.0, 0.0, 0.0));
        footerFluff.SetBrushMirrorType(inkBrushMirrorType.NoMirror);
        footerFluff.SetBrushTileType(inkBrushTileType.NoTile);
        footerFluff.SetAtlasResource(r"base\\gameplay\\gui\\quests\\assets\\q000_jenkins_brief.inkatlas");
        footerFluff.SetTexturePart(n"Intro_fluff_01");
        footerFluff.SetTintColor(new HDRColor(0.90, 0.58, 0.10, 1.0));
        footerFluff.SetOpacity(0.5);
        footerFluff.Reparent(canvas);
        this.m_footerFluff = footerFluff;
    }

    private static func HeatFillColor(heat: Float) -> HDRColor {
        let h: Float = ClampF(heat, 0.0, 1.0);
        let r: Float;
        let g: Float;
        let b: Float;
        if h <= 0.5 {
            let t: Float = h * 2.0;
            r = 0.15 + t * (1.1 - 0.15);
            g = 1.1  + t * (0.85 - 1.1);
            b = 0.15 * (1.0 - t);
        } else {
            let t: Float = (h - 0.5) * 2.0;
            r = 1.1  + t * (1.5  - 1.1);
            g = 0.85 + t * (0.08 - 0.85);
            b = 0.0;
        }
        return new HDRColor(r, g, b, 1.0);
    }

    private func UpdateContent(
        gi:                GameInstance,
        heat:              Float,
        marks:             Int32,
        hideTimer:         Float,
        disarmTimer:       Float,
        signalTimer:       Float,
        counterBreachTime: Float
    ) -> Void {
        if !IsDefined(this.m_canvas) { return; }
        let w:      Float = 520.0;
        let sideW:  Float = 50.0;
        let txtX:   Float = 70.0;
        let trackW: Float = 438.0;

        let deckMss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
            .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
        if IsDefined(deckMss) && IsDefined(this.m_deckLine) {
            this.m_deckLine.SetText(deckMss.GetEquippedCyberdeckName());
        }

        this.m_marksLine.SetText("ACTIVE MARKS ... " + ToString(marks));

        let heatStr: String;
        if      heat < 0.2  { heatStr = "COLD"; }
        else if heat < 0.4  { heatStr = "WARM"; }
        else if heat < 0.6  { heatStr = "HOT"; }
        else if heat < 0.8  { heatStr = "CRITICAL"; }
        else if heat < 0.95 { heatStr = "PEAK"; }
        else                { heatStr = "MAXIMUM"; }
        let pct: Int32 = Cast<Int32>(heat * 100.0);
        this.m_heatLabel.SetText("NETWORK HEAT ... " + heatStr + " " + ToString(pct) + "%");
        let heatW: Float = ClampF(heat, 0.0, 1.0) * trackW;
        if heatW < 1.0 { heatW = 1.0; }
        this.m_heatFill.SetSize(new Vector2(heatW, 10.0));
        this.m_heatFill.SetTintColor(BNTestPanel.HeatFillColor(heat));

        let perkSys: ref<BNPerkSystem> = BNPerkSystem.GetInstance(gi);
        let hasHidePresence: Bool = !IsDefined(perkSys) || perkSys.GetPerkLevel(BNPerk.HidePresence) > 0;
        let hasDisarmICE: Bool    = !IsDefined(perkSys) || perkSys.GetPerkLevel(BNPerk.DisarmICE) > 0;

        let showSignalBar:  Bool = signalTimer > 0.0;
        let showHideBar:    Bool = hideTimer > 0.0;
        let showDisarmBar:  Bool = disarmTimer > 0.0;
        let showCounterBar: Bool = counterBreachTime > 0.0;

        if showSignalBar {
            this.m_signalLabel.SetText("RAVEN ... " + ToString(Cast<Int32>(signalTimer)) + "s");
            this.m_signalLabel.SetTintColor(new HDRColor(0.10, 1.2, 1.1, 1.0));
            let fillW: Float = ClampF(signalTimer / 60.0, 0.0, 1.0) * trackW;
            if fillW < 1.0 { fillW = 1.0; }
            this.m_signalFill.SetSize(new Vector2(fillW, 10.0));
        } else {
            this.m_signalLabel.SetText("RAVEN ... READY");
            this.m_signalLabel.SetTintColor(new HDRColor(0.05, 0.50, 0.50, 0.7));
        }
        this.m_signalTrack.SetVisible(showSignalBar);
        this.m_signalFill.SetVisible(showSignalBar);

        if showHideBar {
            this.m_hideLabel.SetText("GHOST ... " + ToString(Cast<Int32>(hideTimer)) + "s");
            this.m_hideLabel.SetTintColor(new HDRColor(0.20, 0.70, 1.40, 1.0));
            let fillW: Float = ClampF(hideTimer / 120.0, 0.0, 1.0) * trackW;
            if fillW < 1.0 { fillW = 1.0; }
            this.m_hideFill.SetSize(new Vector2(fillW, 10.0));
        } else if hasHidePresence {
            this.m_hideLabel.SetText("GHOST ... READY");
            this.m_hideLabel.SetTintColor(new HDRColor(0.10, 0.35, 0.70, 0.7));
        } else {
            this.m_hideLabel.SetText("GHOST ... OFFLINE");
            this.m_hideLabel.SetTintColor(new HDRColor(0.60, 0.40, 0.08, 0.4));
        }
        this.m_hideTrack.SetVisible(showHideBar);
        this.m_hideFill.SetVisible(showHideBar);

        if showDisarmBar {
            this.m_disarmLabel.SetText("NULL ... " + ToString(Cast<Int32>(disarmTimer)) + "s");
            this.m_disarmLabel.SetTintColor(new HDRColor(1.20, 1.00, 0.10, 1.0));
            let fillW: Float = ClampF(disarmTimer / 120.0, 0.0, 1.0) * trackW;
            if fillW < 1.0 { fillW = 1.0; }
            this.m_disarmFill.SetSize(new Vector2(fillW, 10.0));
        } else if hasDisarmICE {
            this.m_disarmLabel.SetText("NULL ... READY");
            this.m_disarmLabel.SetTintColor(new HDRColor(0.55, 0.45, 0.05, 0.7));
        } else {
            this.m_disarmLabel.SetText("NULL ... OFFLINE");
            this.m_disarmLabel.SetTintColor(new HDRColor(0.60, 0.40, 0.08, 0.4));
        }
        this.m_disarmTrack.SetVisible(showDisarmBar);
        this.m_disarmFill.SetVisible(showDisarmBar);

        if showCounterBar {
            this.m_counterLabel.SetText("ICE BREACH ... INCOMING " + ToString(Cast<Int32>(counterBreachTime)) + "s");
            this.m_counterLabel.SetTintColor(new HDRColor(1.50, 0.20, 0.05, 1.0));
            let charge: Float = ClampF((5.0 - counterBreachTime) / 5.0, 0.0, 1.0);
            let fillW: Float  = charge * trackW;
            if fillW < 1.0 { fillW = 1.0; }
            this.m_counterFill.SetSize(new Vector2(fillW, 10.0));
        } else {
            this.m_counterLabel.SetText("ICE BREACH ... NOMINAL");
            this.m_counterLabel.SetTintColor(new HDRColor(1.2, 0.78, 0.12, 0.5));
        }
        this.m_counterTrack.SetVisible(showCounterBar);
        this.m_counterFill.SetVisible(showCounterBar);

        let curY: Float = 120.0; // bottom of heat bar (Y=110 + height=10)

        let sigLabelY: Float = curY + 8.0;
        this.m_signalLabel.SetMargin(new inkMargin(txtX, sigLabelY, 12.0, 0.0));
        if showSignalBar {
            let sigBarY: Float = sigLabelY + 18.0;
            this.m_signalTrack.SetMargin(new inkMargin(txtX, sigBarY, 0.0, 0.0));
            this.m_signalFill.SetMargin(new inkMargin(txtX, sigBarY, 0.0, 0.0));
            curY = sigBarY + 10.0;
        } else {
            curY = sigLabelY + 18.0;
        }

        let hideLabelY: Float = curY + 8.0;
        this.m_hideLabel.SetMargin(new inkMargin(txtX, hideLabelY, 12.0, 0.0));
        if showHideBar {
            let hideBarY: Float = hideLabelY + 18.0;
            this.m_hideTrack.SetMargin(new inkMargin(txtX, hideBarY, 0.0, 0.0));
            this.m_hideFill.SetMargin(new inkMargin(txtX, hideBarY, 0.0, 0.0));
            curY = hideBarY + 10.0;
        } else {
            curY = hideLabelY + 18.0;
        }

        let disarmLabelY: Float = curY + 8.0;
        this.m_disarmLabel.SetMargin(new inkMargin(txtX, disarmLabelY, 12.0, 0.0));
        if showDisarmBar {
            let disarmBarY: Float = disarmLabelY + 18.0;
            this.m_disarmTrack.SetMargin(new inkMargin(txtX, disarmBarY, 0.0, 0.0));
            this.m_disarmFill.SetMargin(new inkMargin(txtX, disarmBarY, 0.0, 0.0));
            curY = disarmBarY + 10.0;
        } else {
            curY = disarmLabelY + 18.0;
        }

        let div3Y: Float = curY + 8.0;
        this.m_div3.SetMargin(new inkMargin(txtX, div3Y, 0.0, 0.0));
        curY = div3Y + 1.0;

        let ctrLabelY: Float = curY + 11.0;
        this.m_counterLabel.SetMargin(new inkMargin(txtX, ctrLabelY, 12.0, 0.0));
        if showCounterBar {
            let ctrBarY: Float = ctrLabelY + 18.0;
            this.m_counterTrack.SetMargin(new inkMargin(txtX, ctrBarY, 0.0, 0.0));
            this.m_counterFill.SetMargin(new inkMargin(txtX, ctrBarY, 0.0, 0.0));
            curY = ctrBarY + 10.0;
        } else {
            curY = ctrLabelY + 18.0;
        }

        let footerY: Float = curY + 5.0;
        let newH: Float    = footerY + 25.0;
        this.m_footerFluff.SetMargin(new inkMargin(txtX, footerY, 0.0, 0.0));
        this.m_canvas.SetSize(new Vector2(w, newH));
        this.m_bg.SetSize(new Vector2(w, newH));
        this.m_frame.SetSize(new Vector2(w, newH));
        this.m_sidebar.SetSize(new Vector2(sideW, newH - 20.0));
    }

    public func Show(gi: GameInstance, counterBreachTime: Float) -> Void {
        if !IsDefined(this.m_canvas) { return; }
        this.m_isVisible = true;

        let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
            .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
        if IsDefined(mss) {
            this.UpdateContent(
                gi,
                mss.GetSessionHeat(),
                mss.GetTotalCount(),
                mss.GetHidePresenceTimer(),
                mss.GetDisarmICETimer(),
                mss.GetSignalNoiseTimer(),
                counterBreachTime
            );
        }

        let wasAnimating = IsDefined(this.m_animProxy) && this.m_animProxy.IsPlaying();
        if wasAnimating { this.m_animProxy.Stop(); }

        this.m_canvas.SetOpacity(0.0);
        this.m_canvas.SetVisible(true);

        let def = new inkAnimDef();

        let scaleIn = new inkAnimScale();
        scaleIn.SetStartScale(new Vector2(1.0, 0.0));
        scaleIn.SetEndScale(new Vector2(1.0, 1.0));
        scaleIn.SetDuration(0.35);
        scaleIn.SetStartDelay(1.4);
        scaleIn.SetType(inkanimInterpolationType.Exponential);
        scaleIn.SetMode(inkanimInterpolationMode.EasyOut);
        def.AddInterpolator(scaleIn);

        let opacIn = new inkAnimTransparency();
        opacIn.SetStartTransparency(0.0);
        opacIn.SetEndTransparency(1.0);
        opacIn.SetDuration(0.25);
        opacIn.SetStartDelay(1.4);
        opacIn.SetType(inkanimInterpolationType.Linear);
        opacIn.SetMode(inkanimInterpolationMode.EasyOut);
        def.AddInterpolator(opacIn);

        this.m_animProxy = this.m_canvas.PlayAnimation(def);
    }

    public func Refresh(gi: GameInstance, counterBreachTime: Float) -> Void {
        if !IsDefined(this.m_canvas) || !this.m_isVisible { return; }

        let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
            .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
        if IsDefined(mss) {
            this.UpdateContent(
                gi,
                mss.GetSessionHeat(),
                mss.GetTotalCount(),
                mss.GetHidePresenceTimer(),
                mss.GetDisarmICETimer(),
                mss.GetSignalNoiseTimer(),
                counterBreachTime
            );
        }
    }

    public func Hide() -> Void {
        if !IsDefined(this.m_canvas) { return; }
        this.m_isVisible = false;

        let wasAnimating = IsDefined(this.m_animProxy) && this.m_animProxy.IsPlaying();
        if wasAnimating { this.m_animProxy.Stop(); }

        if !this.m_canvas.IsVisible() { return; }

        if wasAnimating {
            this.m_canvas.SetVisible(false);
            return;
        }

        let def = new inkAnimDef();
        let scaleOut = new inkAnimScale();
        scaleOut.SetStartScale(new Vector2(1.0, 1.0));
        scaleOut.SetEndScale(new Vector2(1.0, 0.0));
        scaleOut.SetDuration(0.25);
        scaleOut.SetType(inkanimInterpolationType.Exponential);
        scaleOut.SetMode(inkanimInterpolationMode.EasyIn);
        def.AddInterpolator(scaleOut);
        let opacOut = new inkAnimTransparency();
        opacOut.SetStartTransparency(1.0);
        opacOut.SetEndTransparency(0.0);
        opacOut.SetDuration(0.2);
        def.AddInterpolator(opacOut);
        this.m_animProxy = this.m_canvas.PlayAnimation(def);
    }
}

public class BNTestPanelSystem extends ScriptableSystem {
    private let m_panel: ref<BNTestPanel>;

    public func RegisterPanel(p: ref<BNTestPanel>) -> Void {
        this.m_panel = p;
    }

    public func ShowTestPanel(counterBreachTime: Float) -> Void {
        if IsDefined(this.m_panel) {
            this.m_panel.Show(this.GetGameInstance(), counterBreachTime);
        }
    }

    public func Refresh(counterBreachTime: Float) -> Void {
        if IsDefined(this.m_panel) {
            this.m_panel.Refresh(this.GetGameInstance(), counterBreachTime);
        }
    }

    public func Hide() -> Void {
        if IsDefined(this.m_panel) { this.m_panel.Hide(); }
    }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
    let result: Bool = wrappedMethod();
    let gi: GameInstance = this.GetGame();

    let sys: ref<BNTestPanelSystem> = GameInstance.GetScriptableSystemsContainer(gi)
        .Get(n"BetterNetrunning.UI.BNTestPanelSystem") as BNTestPanelSystem;
    if !IsDefined(sys) {
        BNWarn("UI", "BNTestPanel: BNTestPanelSystem unavailable — test panel skipped");
        return result;
    }

    let inkSystem = GameInstance.GetInkSystem();
    if !IsDefined(inkSystem) { return result; }
    let hudLayer = inkSystem.GetLayer(n"inkHUDLayer");
    if !IsDefined(hudLayer) { return result; }
    let hudRoot = hudLayer.GetVirtualWindow();
    if !IsDefined(hudRoot) { return result; }

    hudRoot.RemoveChildByName(n"BNTestCanvas");

    let canvas = new inkCanvas();
    canvas.SetName(n"BNTestCanvas");
    canvas.SetAnchor(inkEAnchor.TopLeft);
    canvas.SetAnchorPoint(new Vector2(0.0, 0.0));
    canvas.SetMargin(new inkMargin(20.0, 320.0, 0.0, 0.0));
    canvas.SetSize(new Vector2(520.0, 296.0));
    canvas.Reparent(hudRoot);

    sys.RegisterPanel(BNTestPanel.Create(canvas));
    BNInfo("UI", "BNTestPanel injected");

    return result;
}

