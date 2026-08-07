import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

//! The RECON watch face.
//!
//! Reading order, outside in: the weekday ring sits on the bezel, then the
//! date and weather strip, then the time as the single dominant element, then
//! two stat cells, then the body battery trend, and finally the device battery
//! gauge back out on the bezel. Nothing overlaps, and every readout has a
//! placeholder for when its sensor has nothing to say.
class ReconView extends WatchUi.WatchFace {

    private const TIME_FONT = Graphics.FONT_NUMBER_THAI_HOT;
    private const STRIP_FONT = Graphics.FONT_TINY;
    private const LABEL_FONT = Graphics.FONT_XTINY;
    private const WD_FONT = Graphics.FONT_XTINY;
    private const WD_FONT_ON = Graphics.FONT_TINY;
    private const BB_VALUE_FONT = Graphics.FONT_TINY;
    private const BAT_FONT = Graphics.FONT_XTINY;

    private var _valueFonts as Array<Graphics.FontType>;
    private var _metrics as Metrics;
    private var _weekdays as Array<String>;
    private var _lowPower as Boolean = false;
    private var _ready as Boolean = false;

    function initialize() {
        WatchFace.initialize();
        _metrics = new Metrics();
        _valueFonts = [
            Graphics.FONT_NUMBER_MILD,
            Graphics.FONT_MEDIUM,
            Graphics.FONT_SMALL,
            Graphics.FONT_TINY
        ] as Array<Graphics.FontType>;
        _weekdays = [
            WatchUi.loadResource(Rez.Strings.Wd0) as String,
            WatchUi.loadResource(Rez.Strings.Wd1) as String,
            WatchUi.loadResource(Rez.Strings.Wd2) as String,
            WatchUi.loadResource(Rez.Strings.Wd3) as String,
            WatchUi.loadResource(Rez.Strings.Wd4) as String,
            WatchUi.loadResource(Rez.Strings.Wd5) as String,
            WatchUi.loadResource(Rez.Strings.Wd6) as String
        ] as Array<String>;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        if (!_ready) {
            Layout.init(dc);
            _ready = true;
        }
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        _metrics.refresh();

        dc.setColor(Theme.BG, Theme.BG);
        dc.clear();

        var dim = _lowPower;
        drawBezel(dc, dim);
        drawWeekdays(dc, dim);
        drawStrip(dc, dim);
        drawTime(dc, dim);

        // Always-on display keeps only the layer worth burning pixels for.
        if (!dim) {
            drawStatRow(dc);
            drawBodyBattery(dc);
        }
        drawBattery(dc, dim);
    }

    function onEnterSleep() as Void {
        _lowPower = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _lowPower = false;
        WatchUi.requestUpdate();
    }

    // ------------------------------------------------------------------ //

    private function drawBezel(dc as Graphics.Dc, dim as Boolean) as Void {
        dc.setColor(dim ? 0x0E1216 : Theme.RING, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(Layout.u(Layout.RING_W));
        dc.drawCircle(Layout.cx, Layout.cy, Layout.u(Layout.RING_R));
        dc.setPenWidth(1);
    }

    private function drawWeekdays(dc as Graphics.Dc, dim as Boolean) as Void {
        var r = Layout.f(Layout.WD_R);

        for (var i = 0; i < 7; i++) {
            var th = (i - 3) * Layout.WD_STEP * Gfx.DEG;
            var on = (i == _metrics.weekday);
            var x = Layout.cx + (Math.sin(th) * r).toNumber();
            var y = Layout.cy - (Math.cos(th) * r).toNumber();

            var color;
            if (on) {
                color = dim ? Theme.AOD_ACCENT : Theme.ACCENT;
            } else {
                color = dim ? Theme.AOD_LOW : Theme.TEXT_LOW;
            }

            Gfx.text(dc, x, y, on ? WD_FONT_ON : WD_FONT, _weekdays[i],
                Graphics.TEXT_JUSTIFY_CENTER, color);

            if (on) {
                Gfx.box(dc,
                    x - Layout.u(Layout.WD_BAR_W) / 2,
                    y + Layout.u(Layout.WD_BAR_DY),
                    Layout.u(Layout.WD_BAR_W),
                    Layout.u(Layout.WD_BAR_H),
                    color);
            }
        }
    }

    private function drawStrip(dc as Graphics.Dc, dim as Boolean) as Void {
        var cy = dim ? Layout.AOD_STRIP_CY : Layout.STRIP_CY;
        var hi = dim ? Theme.AOD_DIM : Theme.TEXT_VAL;
        var mid = dim ? Theme.AOD_LOW : Theme.TEXT_MID;
        var y = Layout.u(cy);

        Gfx.box(dc,
            Layout.cx,
            Layout.u(cy - (Layout.STRIP_CY - Layout.STRIP_DIV_TOP)),
            1,
            Layout.u(Layout.STRIP_DIV_H),
            dim ? Theme.AOD_HAIR : Theme.HAIR);

        var date = _metrics.month.format("%02d") + "." + _metrics.day.format("%02d");
        Gfx.text(dc, Layout.u(Layout.DATE_RIGHT), y, STRIP_FONT, date,
            Graphics.TEXT_JUSTIFY_RIGHT, hi);

        Gfx.weather(dc, _metrics.wxKind, Layout.u(Layout.WX_CX), y,
            Layout.u(Layout.WX_SIZE), hi, mid);

        var temp = (_metrics.wxTemp == null) ? "--°" : _metrics.wxTemp.format("%d") + "°";
        Gfx.text(dc, Layout.u(Layout.TEMP_LEFT), y, STRIP_FONT, temp,
            Graphics.TEXT_JUSTIFY_LEFT, hi);
    }

    private function drawTime(dc as Graphics.Dc, dim as Boolean) as Void {
        var y = Layout.u(dim ? Layout.AOD_TIME_CY : Layout.TIME_CY);
        var color = dim ? Theme.AOD_TEXT : Theme.TEXT_HI;
        var gap = Layout.u(Layout.COLON_GAP);

        Gfx.text(dc, Layout.cx - gap, y, TIME_FONT, _metrics.hour.format("%02d"),
            Graphics.TEXT_JUSTIFY_RIGHT, color);
        Gfx.text(dc, Layout.cx + gap, y, TIME_FONT, _metrics.minute.format("%02d"),
            Graphics.TEXT_JUSTIFY_LEFT, color);

        var sq = Layout.u(Layout.COLON_SQ);
        var dy = Layout.u(Layout.COLON_DY);
        var cy = y + Layout.u(Layout.COLON_SHIFT);
        var ck = dim ? Theme.AOD_ACCENT : Theme.ACCENT;
        Gfx.box(dc, Layout.cx - sq / 2, cy - dy - sq / 2, sq, sq, ck);
        Gfx.box(dc, Layout.cx - sq / 2, cy + dy - sq / 2, sq, sq, ck);
    }

    private function drawStatRow(dc as Graphics.Dc) as Void {
        var labelY = Layout.u(Layout.LABEL_CY);
        var valueY = Layout.u(Layout.VALUE_CY);
        var barY = Layout.u(Layout.BAR_Y);
        var barW = Layout.u(Layout.BAR_W);
        var barH = Layout.u(Layout.BAR_H);
        var maxW = Layout.u(Layout.CELL_MAX_W);
        var tracking = Layout.u(Layout.TRACK_LABEL);

        Gfx.box(dc, Layout.cx, Layout.u(Layout.ROW_DIV_TOP), 1,
            Layout.u(Layout.ROW_DIV_BOT - Layout.ROW_DIV_TOP), Theme.HAIR);

        // ---- heart rate ----
        var cellL = Layout.u(Layout.CELL_L);
        var hrTxt = (_metrics.hr == null) ? "--" : _metrics.hr.format("%d");

        Gfx.trackedText(dc, cellL, labelY, LABEL_FONT, "HR", tracking,
            Graphics.TEXT_JUSTIFY_CENTER, Theme.TEXT_LOW);
        Gfx.text(dc, cellL, valueY, Gfx.fitFont(dc, hrTxt, maxW, _valueFonts), hrTxt,
            Graphics.TEXT_JUSTIFY_CENTER, Theme.TEXT_VAL);

        // Five-segment zone ladder. The number of lit segments gives the zone
        // and they all take that zone's colour — lighting each segment in its
        // own colour turned the bar into a rainbow that read as decoration.
        // Below zone 1 one segment glows in the resting tint, so a resting
        // heart rate never looks like a dead sensor.
        var gap = Layout.u(Layout.SEG_GAP);
        var segW = (barW - 4 * gap) / 5;
        var segX = cellL - barW / 2;
        var lit = (_metrics.hr == null) ? 0 : (_metrics.hrZone < 1 ? 1 : _metrics.hrZone);
        for (var i = 0; i < 5; i++) {
            Gfx.box(dc, segX + i * (segW + gap), barY, segW, barH,
                (i < lit) ? Theme.zoneColor(_metrics.hrZone) : Theme.TRACK);
        }

        // ---- steps ----
        var cellR = Layout.u(Layout.CELL_R);
        var stepTxt = grouped(_metrics.steps);

        Gfx.trackedText(dc, cellR, labelY, LABEL_FONT, "STEPS", tracking,
            Graphics.TEXT_JUSTIFY_CENTER, Theme.TEXT_LOW);
        Gfx.text(dc, cellR, valueY, Gfx.fitFont(dc, stepTxt, maxW, _valueFonts), stepTxt,
            Graphics.TEXT_JUSTIFY_CENTER, Theme.TEXT_VAL);

        var frac = _metrics.steps.toFloat() / _metrics.stepGoal;
        if (frac > 1.0) { frac = 1.0; }
        if (frac < 0.0) { frac = 0.0; }
        var barX = cellR - barW / 2;
        Gfx.box(dc, barX, barY, barW, barH, Theme.TRACK);
        Gfx.box(dc, barX, barY, (barW * frac).toNumber(), barH,
            (frac >= 1.0) ? Theme.ACCENT : Theme.STEEL);
    }

    private function drawBodyBattery(dc as Graphics.Dc) as Void {
        var labelY = Layout.u(Layout.BB_LABEL_CY);
        var x0 = Layout.u(Layout.BB_X0);
        var x1 = Layout.u(Layout.BB_X1);
        var y0 = Layout.u(Layout.BB_Y0);
        var y1 = Layout.u(Layout.BB_Y1);
        var w = x1 - x0;
        var h = y1 - y0;
        var tracking = Layout.u(Layout.TRACK_LABEL);

        var value = (_metrics.bodyBattery == null) ? "--" : _metrics.bodyBattery.format("%d");
        var valueLeft = x1 - dc.getTextWidthInPixels(value, BB_VALUE_FONT);

        Gfx.trackedText(dc, x0, labelY, LABEL_FONT, "BODY BATTERY", tracking,
            Graphics.TEXT_JUSTIFY_LEFT, Theme.TEXT_LOW);
        Gfx.text(dc, x1, labelY, BB_VALUE_FONT, value,
            Graphics.TEXT_JUSTIFY_RIGHT, Theme.BB);

        // The window tag is the first thing to drop when a three-digit body
        // battery needs the room.
        var labelW = dc.getTextWidthInPixels("BODY BATTERY", LABEL_FONT) + tracking * 11;
        var tagW = dc.getTextWidthInPixels("12H", LABEL_FONT) + tracking * 2;
        var tagX = x0 + labelW + Layout.u(9);
        if (tagX + tagW <= valueLeft - Layout.u(10)) {
            Gfx.trackedText(dc, tagX, labelY, LABEL_FONT, "12H", tracking,
                Graphics.TEXT_JUSTIFY_LEFT, Theme.TEXT_FAINT);
        }

        var series = _metrics.bbSeries;
        Gfx.box(dc, x0, y1, w, 1, Theme.HAIR);          // baseline
        if (series == null) { return; }                  // bare axis, no orphan gridline
        Gfx.box(dc, x0, y0 + h / 2, w, 1, Theme.BB_GRID); // the 50 guide

        // Body battery sits in the 40-100 band most of the day, so a plain
        // 0-100 bar chart collapses into a solid slab. Filling each column dim
        // and capping it bright keeps the absolute level *and* draws the curve.
        var slot = Layout.f(Layout.BB_SLOT);
        var bar = Layout.u(Layout.BB_BAR);
        var cap = Layout.u(Layout.BB_CAP);
        var slots = (w / slot).toNumber();
        var count = series.size();
        if (slots < 1 || count < 1) { return; }

        for (var i = 0; i < slots; i++) {
            var v = series[i * count / slots];
            if (v > 100) { v = 100; }
            if (v < 0) { v = 0; }

            var bh = (h * v / 100.0).toNumber();
            if (bh < cap) { bh = cap; }
            var bx = x0 + (i * slot).toNumber();

            Gfx.box(dc, bx, y1 - bh, bar, bh, Theme.BB_DIM);
            Gfx.box(dc, bx, y1 - bh, bar, cap, (i == slots - 1) ? Theme.TEXT_HI : Theme.BB);
        }
    }

    private function drawBattery(dc as Graphics.Dc, dim as Boolean) as Void {
        var pct = _metrics.battery;
        var col = dim ? Theme.AOD_DIM : Theme.batteryColor(pct);
        var cy = Layout.u(dim ? Layout.AOD_BAT_CY : Layout.BAT_CY);

        if (!dim) {
            var from = 90.0 + Layout.BAT_ARC_SPAN;
            var sweep = 2.0 * Layout.BAT_ARC_SPAN;
            var r = Layout.u(Layout.BAT_ARC_R);

            dc.setPenWidth(Layout.u(Layout.BAT_ARC_W));
            Gfx.fill(dc, Theme.ARC_TRACK);
            Gfx.arcScreen(dc, Layout.cx, Layout.cy, r, from, from - sweep);
            Gfx.fill(dc, col);
            Gfx.arcScreen(dc, Layout.cx, Layout.cy, r, from, from - sweep * pct / 100.0);
            dc.setPenWidth(1);
        }

        var label = Math.round(pct).toNumber().format("%d") + "%";
        var tw = dc.getTextWidthInPixels(label, BAT_FONT);
        var iw = Layout.u(Layout.BAT_ICON_W);
        var ih = Layout.u(Layout.BAT_ICON_H);
        var pad = Layout.u(8);
        var ix = Layout.cx - (iw + pad + tw) / 2;
        var iy = cy - ih / 2;

        Gfx.fill(dc, col);
        dc.setPenWidth(Layout.u(2));
        dc.drawRectangle(ix, iy, iw, ih);
        dc.setPenWidth(1);
        Gfx.box(dc, ix + iw, cy - Layout.u(3), Layout.u(3), Layout.u(6), col);
        Gfx.box(dc, ix + Layout.u(3), iy + Layout.u(3),
            ((iw - Layout.u(6)) * pct / 100.0).toNumber(), ih - Layout.u(6), col);

        Gfx.text(dc, ix + iw + pad, cy, BAT_FONT, label,
            Graphics.TEXT_JUSTIFY_LEFT, col);
    }

    //! Monkey C has no locale-aware number formatting, and a bare five digit
    //! step count is hard to read at a glance.
    private function grouped(n as Number) as String {
        var s = n.format("%d");
        if (s.length() <= 3) { return s; }

        var out = "";
        var count = 0;
        for (var i = s.length() - 1; i >= 0; i--) {
            out = s.substring(i, i + 1) + out;
            count++;
            if (count % 3 == 0 && i > 0) { out = "," + out; }
        }
        return out;
    }
}
