

module BetterNetrunning.Marking

import BetterNetrunning.Core.*
import BetterNetrunning.Logging.*
import BetterNetrunning.UI.*

public abstract class ICEDiagnosticUtils {

  public static func GetTierLabel(hitsRequired: Int32) -> String {
    if hitsRequired <= 0 { return "UNKNOWN ICE"; }
    if hitsRequired <= 3 { return "LEGACY ICE"; }
    if hitsRequired <= 5 { return "HARDENED ICE"; }
    return "CORPORATE ICE";
  }

  public static func GetStatusLabel(hitsApplied: Int32, hitsRequired: Int32) -> String {
    if hitsRequired <= 0           { return "UNKNOWN"; }
    if hitsApplied <= 0            { return "INTACT"; }
    if hitsApplied >= hitsRequired { return "FULLY COMPROMISED"; }
    let pct: Int32 = (hitsApplied * 100) / hitsRequired;
    return ToString(pct) + "% DEGRADED";
  }
}

public class ICEScoutLog {
  private let m_canvas:      ref<inkCanvas>;
  private let m_content:     ref<inkText>;
  private let m_animProxy:   ref<inkAnimProxy>;
  private let m_bg:          ref<inkImage>;
  private let m_frame:       ref<inkImage>;
  private let m_sidebar:     ref<inkImage>;
  private let m_footerFluff: ref<inkImage>;
  private let m_footer:      ref<inkText>;

  private let m_isVisible: Bool;

  public static func Create(parent: ref<inkCompoundWidget>) -> ref<ICEScoutLog> {
    let log = new ICEScoutLog();
    log.Build(parent);
    return log;
  }

  private func Build(parent: ref<inkCompoundWidget>) -> Void {
    let w:     Float = 680.0;
    let h:     Float = 280.0;
    let sideW: Float = 50.0;
    let txtX:  Float = sideW + 20.0;

    let canvas = new inkCanvas();
    canvas.SetName(n"ICEScoutInner");
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
    bg.SetTintColor(new HDRColor(0.01, 0.04, 0.04, 1.0));
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
    frame.SetTintColor(new HDRColor(0.10, 0.80, 0.75, 1.0));
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
    sidebar.SetTintColor(new HDRColor(0.10, 0.80, 0.75, 1.0));
    sidebar.Reparent(canvas);
    this.m_sidebar = sidebar;

    let title = new inkText();
    title.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    title.SetFontSize(20);
    title.SetLetterCase(textLetterCase.UpperCase);
    title.SetAnchor(inkEAnchor.TopLeft);
    title.SetMargin(new inkMargin(txtX, 10.0, 12.0, 0.0));
    title.SetTintColor(new HDRColor(0.15, 1.2, 1.1, 1.0));
    title.SetText("ICE Scout Log  //  Diagnostic Feed");
    title.Reparent(canvas);

    let footerFluff = new inkImage();
    footerFluff.SetAnchor(inkEAnchor.TopLeft);
    footerFluff.SetSize(new Vector2(w - sideW - 30.0, 18.0));
    footerFluff.SetMargin(new inkMargin(txtX, h - 38.0, 0.0, 0.0));
    footerFluff.SetBrushMirrorType(inkBrushMirrorType.NoMirror);
    footerFluff.SetBrushTileType(inkBrushTileType.NoTile);
    footerFluff.SetAtlasResource(r"base\\gameplay\\gui\\quests\\assets\\q000_jenkins_brief.inkatlas");
    footerFluff.SetTexturePart(n"Intro_fluff_01");
    footerFluff.SetTintColor(new HDRColor(0.10, 0.80, 0.75, 1.0));
    footerFluff.SetOpacity(0.5);
    footerFluff.Reparent(canvas);
    this.m_footerFluff = footerFluff;

    let footer = new inkText();
    footer.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    footer.SetFontSize(10);
    footer.SetLetterCase(textLetterCase.UpperCase);
    footer.SetAnchor(inkEAnchor.TopLeft);
    footer.SetMargin(new inkMargin(txtX, h - 24.0, 12.0, 0.0));
    footer.SetTintColor(new HDRColor(0.15, 1.2, 1.1, 0.7));
    footer.SetText("BN // ICE Diagnostic System v1.0");
    footer.Reparent(canvas);
    this.m_footer = footer;

    let content = new inkText();
    content.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    content.SetFontSize(15);
    content.SetLetterCase(textLetterCase.UpperCase);
    content.SetAnchor(inkEAnchor.TopLeft);
    content.SetMargin(new inkMargin(txtX, 38.0, 12.0, 0.0));
    content.SetTintColor(new HDRColor(0.15, 1.2, 1.1, 1.0));
    content.SetText("");
    content.Reparent(canvas);
    this.m_content = content;
  }

  private func ResizeForEntries(count: Int32) -> Void {
    if !IsDefined(this.m_canvas) { return; }
    let w:       Float = 680.0;
    let sideW:   Float = 50.0;
    let txtX:    Float = sideW + 20.0;
    let lineH:   Float = 20.0;
    let minH:    Float = 110.0;
    let newH:    Float = 38.0 + Cast<Float>(count) * lineH + 48.0;
    if newH < minH { newH = minH; }

    this.m_canvas.SetSize(new Vector2(w, newH));
    this.m_bg.SetSize(new Vector2(w, newH));
    this.m_frame.SetSize(new Vector2(w, newH));
    this.m_sidebar.SetSize(new Vector2(sideW, newH - 20.0));
    this.m_footerFluff.SetMargin(new inkMargin(txtX, newH - 38.0, 0.0, 0.0));
    this.m_footer.SetMargin(new inkMargin(txtX, newH - 24.0, 12.0, 0.0));
  }

  public func Refresh(gi: GameInstance) -> Void {
    if !IsDefined(this.m_content) { return; }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if !IsDefined(mss) { return; }

    this.m_content.SetText(this.BuildContentText(mss, gi));
    this.ResizeForEntries(mss.GetTotalCount());
  }

  public func IsVisible() -> Bool { return this.m_isVisible; }

  public func ShowIfNew(gi: GameInstance) -> Void {
    if !IsDefined(this.m_canvas) || !IsDefined(this.m_content) { return; }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if IsDefined(mss) {
      this.m_content.SetText(this.BuildContentText(mss, gi));
      this.ResizeForEntries(mss.GetTotalCount());
    }

    if !this.m_isVisible {
      this.m_isVisible = true;
      this.PlayShowAnimation();
    }
  }

  public func Show(gi: GameInstance) -> Void {
    if !IsDefined(this.m_canvas) { return; }
    this.m_isVisible = true;

    let wasAnimating = IsDefined(this.m_animProxy) && this.m_animProxy.IsPlaying();
    if wasAnimating { this.m_animProxy.Stop(); }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    if IsDefined(mss) {
      this.m_content.SetText(this.BuildContentText(mss, gi));
      this.ResizeForEntries(mss.GetTotalCount());
    }

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
    def.AddInterpolator(opacIn);

    this.m_animProxy = this.m_canvas.PlayAnimation(def);
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

  private func BuildContentText(mss: ref<MarkingStateSystem>, gi: GameInstance) -> String {
    let out: String = "";
    let i: Int32;
    let cameras: array<MarkEntry> = mss.GetMarkedCameraEntries();
    let defense: array<MarkEntry> = mss.GetMarkedDefenseEntries();
    let root: array<MarkEntry>    = mss.GetMarkedRootEntries();
    let npcs: array<MarkEntry>    = mss.GetMarkedNPCEntries();

    i = 0;
    while i < ArraySize(cameras) {
      out += this.FormatDeviceEntry(gi, cameras[i]);
      i += 1;
    }
    i = 0;
    while i < ArraySize(defense) {
      out += this.FormatDeviceEntry(gi, defense[i]);
      i += 1;
    }
    i = 0;
    while i < ArraySize(root) {
      out += this.FormatDeviceEntry(gi, root[i]);
      i += 1;
    }
    i = 0;
    while i < ArraySize(npcs) {
      out += this.FormatNPCEntry(gi, npcs[i]);
      i += 1;
    }
    if Equals(out, "") { return "NO TRACKED TARGETS, PING SOMETHING"; }
    return out;
  }

  private func FormatDeviceEntry(gi: GameInstance, entry: MarkEntry) -> String {
    let hitsRequired: Int32 = entry.iceHitsRequired;
    let hitsApplied: Int32  = 0;

    let device: ref<Device> = GameInstance.FindEntityByID(gi, entry.entityID) as Device;
    if IsDefined(device) {
      let ps: ref<ScriptableDeviceComponentPS> = device.GetDevicePS();
      if IsDefined(ps) {
        hitsApplied  = ps.m_bnIceHitsApplied;
        if hitsRequired == 0 { hitsRequired = ps.m_bnIceHitsRequired; }
        if ps.m_bnIceDefeated {
          return entry.displayName + ": "
              + ICEDiagnosticUtils.GetTierLabel(hitsRequired) + ", FULLY COMPROMISED\n";
        }
      }
    } else {

      let vehicle: ref<VehicleObject> = GameInstance.FindEntityByID(gi, entry.entityID) as VehicleObject;
      if IsDefined(vehicle) {
        let vps: ref<SharedGameplayPS> = vehicle.GetVehiclePS() as SharedGameplayPS;
        if IsDefined(vps) {
          hitsApplied  = vps.m_bnIceHitsApplied;
          if hitsRequired == 0 { hitsRequired = vps.m_bnIceHitsRequired; }
          if vps.m_bnIceDefeated {
            return entry.displayName + ": "
                + ICEDiagnosticUtils.GetTierLabel(hitsRequired) + ", FULLY COMPROMISED\n";
          }
        }
      }
    }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    let effective: Int32 = hitsRequired + (IsDefined(mss) ? mss.GetHeatICEBonus() : 0);

    return entry.displayName + ": "
        + ICEDiagnosticUtils.GetTierLabel(hitsRequired) + ", "
        + ICEDiagnosticUtils.GetStatusLabel(hitsApplied, effective) + "\n";
  }

  private func FormatNPCEntry(gi: GameInstance, entry: MarkEntry) -> String {
    let hitsRequired: Int32 = entry.iceHitsRequired;
    let hitsApplied: Int32  = 0;

    let npc: ref<ScriptedPuppet> = GameInstance.FindEntityByID(gi, entry.entityID) as ScriptedPuppet;
    if IsDefined(npc) {
      let ps: ref<ScriptedPuppetPS> = npc.GetPuppetPS() as ScriptedPuppetPS;
      if IsDefined(ps) {
        hitsApplied  = ps.m_bnNPCIceHitsApplied;
        if hitsRequired == 0 { hitsRequired = ps.m_bnNPCIceHitsRequired; }

        if ps.m_bnNPCIceDefeated {
          return entry.displayName + ": "
              + ICEDiagnosticUtils.GetTierLabel(hitsRequired) + ", FULLY COMPROMISED\n";
        }
      }
    }

    let mss: ref<MarkingStateSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(BNConstants.CLASS_MARKING_STATE_SYSTEM()) as MarkingStateSystem;
    let effective: Int32 = hitsRequired + (IsDefined(mss) ? mss.GetHeatICEBonus() : 0);

    return entry.displayName + ": "
        + ICEDiagnosticUtils.GetTierLabel(hitsRequired) + ", "
        + ICEDiagnosticUtils.GetStatusLabel(hitsApplied, effective) + "\n";
  }

  private func PlayShowAnimation() -> Void {
    if IsDefined(this.m_animProxy) && this.m_animProxy.IsPlaying() {
      this.m_animProxy.Stop();
    }

    this.m_canvas.SetOpacity(0.0);
    this.m_canvas.SetVisible(true);

    let def = new inkAnimDef();

    let scaleIn = new inkAnimScale();
    scaleIn.SetStartScale(new Vector2(1.0, 0.0));
    scaleIn.SetEndScale(new Vector2(1.0, 1.0));
    scaleIn.SetDuration(0.35);
    scaleIn.SetType(inkanimInterpolationType.Exponential);
    scaleIn.SetMode(inkanimInterpolationMode.EasyOut);
    def.AddInterpolator(scaleIn);

    let opacIn = new inkAnimTransparency();
    opacIn.SetStartTransparency(0.0);
    opacIn.SetEndTransparency(1.0);
    opacIn.SetDuration(0.25);
    opacIn.SetType(inkanimInterpolationType.Linear);
    opacIn.SetMode(inkanimInterpolationMode.EasyOut);
    def.AddInterpolator(opacIn);

    this.m_animProxy = this.m_canvas.PlayAnimation(def);
  }
}

public class ICEScoutLogSystem extends ScriptableSystem {
  private let m_log: ref<ICEScoutLog>;

  public func RegisterLog(log: ref<ICEScoutLog>) -> Void {
    this.m_log = log;
  }

  public func Refresh() -> Void {
    if IsDefined(this.m_log) {
      this.m_log.Refresh(this.GetGameInstance());
    }
  }

  public func ShowIfNew() -> Void {
    if !IsDefined(this.m_log) { return; }
    let gi: GameInstance = this.GetGameInstance();

    if this.m_log.IsVisible() {

      this.m_log.ShowIfNew(gi);
      return;
    }

    let bootSys: ref<BNBootSystem> = GameInstance.GetScriptableSystemsContainer(gi)
        .Get(n"BetterNetrunning.UI.BNBootSystem") as BNBootSystem;
    if IsDefined(bootSys) { bootSys.Show(); }

    let testSys: ref<BNTestPanelSystem> = GameInstance.GetScriptableSystemsContainer(gi)
        .Get(n"BetterNetrunning.UI.BNTestPanelSystem") as BNTestPanelSystem;
    if IsDefined(testSys) { testSys.ShowTestPanel(0.0); }

    this.m_log.Show(gi);
  }

  public func IsVisible() -> Bool {
    return IsDefined(this.m_log) && this.m_log.IsVisible();
  }

  public func Show() -> Void {
    if IsDefined(this.m_log) {
      this.m_log.Show(this.GetGameInstance());
    }
  }

  public func Hide() -> Void {
    if IsDefined(this.m_log) { this.m_log.Hide(); }
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  let gi: GameInstance = this.GetGame();

  let sys: ref<ICEScoutLogSystem> = GameInstance.GetScriptableSystemsContainer(gi)
      .Get(n"BetterNetrunning.Marking.ICEScoutLogSystem") as ICEScoutLogSystem;
  if !IsDefined(sys) {
    BNWarn("UI", "ICEScoutLog: ICEScoutLogSystem unavailable — log skipped");
    return result;
  }

  let inkSystem = GameInstance.GetInkSystem();
  if !IsDefined(inkSystem) { return result; }
  let hudLayer = inkSystem.GetLayer(n"inkHUDLayer");
  if !IsDefined(hudLayer) { return result; }
  let hudRoot = hudLayer.GetVirtualWindow();
  if !IsDefined(hudRoot) { return result; }

  hudRoot.RemoveChildByName(n"ICEScoutCanvas");

  let canvas = new inkCanvas();
  canvas.SetName(n"ICEScoutCanvas");
  canvas.SetAnchor(inkEAnchor.TopLeft);
  canvas.SetAnchorPoint(new Vector2(0.0, 0.0));
  canvas.SetMargin(new inkMargin(20.0, 630.0, 0.0, 0.0));
  canvas.SetSize(new Vector2(680.0, 900.0));
  canvas.Reparent(hudRoot);

  sys.RegisterLog(ICEScoutLog.Create(canvas));
  BNInfo("UI", "ICEScoutLog injected");

  return result;
}

