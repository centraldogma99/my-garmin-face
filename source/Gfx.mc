import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Drawing primitives shared by the view.
//!
//! Angles in this module are *screen* degrees: 0 is 3 o'clock and positive
//! turns clockwise, matching the canvas preview. Conversion to Garmin's
//! counter-clockwise convention happens in one place, `arcScreen`.
module Gfx {

    const DEG = Math.PI / 180.0;

    function norm(deg as Float) as Float {
        var d = deg.toFloat();
        while (d < 0.0) { d += 360.0; }
        while (d >= 360.0) { d -= 360.0; }
        return d;
    }

    function arcScreen(
        dc as Graphics.Dc, x as Number, y as Number, r as Number,
        fromDeg as Float, toDeg as Float
    ) as Void {
        if ((toDeg - fromDeg).abs() < 0.01) { return; }
        var attr = (toDeg > fromDeg) ? Graphics.ARC_CLOCKWISE : Graphics.ARC_COUNTER_CLOCKWISE;
        // drawArc takes whole degrees. Rounding rather than truncating matters
        // on the short weekday highlight, where a consistent half-degree of
        // truncation walks the arc off the glyph it marks.
        dc.drawArc(x, y, r, attr,
            Math.round(norm(360.0 - fromDeg)).toNumber(),
            Math.round(norm(360.0 - toDeg)).toNumber());
    }

    function fill(dc as Graphics.Dc, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    }

    function box(
        dc as Graphics.Dc, x as Number, y as Number, w as Number, h as Number, color as Number
    ) as Void {
        fill(dc, color);
        dc.fillRectangle(x, y, w, h);
    }

    function disc(
        dc as Graphics.Dc, x as Numeric, y as Numeric, r as Numeric, color as Number
    ) as Void {
        fill(dc, color);
        dc.fillCircle(Math.round(x).toNumber(), Math.round(y).toNumber(),
            Math.round(r).toNumber());
    }

    function stroke(
        dc as Graphics.Dc, x0 as Numeric, y0 as Numeric, x1 as Numeric, y1 as Numeric,
        w as Numeric, color as Number
    ) as Void {
        fill(dc, color);
        var pw = Math.round(w).toNumber();
        dc.setPenWidth(pw < 1 ? 1 : pw);
        dc.drawLine(x0.toNumber(), y0.toNumber(), x1.toNumber(), y1.toNumber());
        dc.setPenWidth(1);
    }

    //! Monkey C has no letter spacing, and the small caps labels need it, so
    //! tracked strings are laid out one glyph at a time. Watch faces redraw
    //! once a minute, so the extra measuring is free.
    function trackedText(
        dc as Graphics.Dc, x as Number, y as Number,
        font as Graphics.FontType or Graphics.VectorFont,
        str as String, tracking as Number, justify as Number, color as Number
    ) as Void {
        var n = str.length();
        if (n == 0) { return; }

        var widths = new [n];
        var total = tracking * (n - 1);
        for (var i = 0; i < n; i++) {
            widths[i] = dc.getTextWidthInPixels(str.substring(i, i + 1), font);
            total += widths[i];
        }

        var left = x;
        if (justify == Graphics.TEXT_JUSTIFY_RIGHT) {
            left = x - total;
        } else if (justify == Graphics.TEXT_JUSTIFY_CENTER) {
            left = x - total / 2;
        }

        fill(dc, color);
        for (var i = 0; i < n; i++) {
            dc.drawText(
                left, y, font, str.substring(i, i + 1),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );
            left += widths[i] + tracking;
        }
    }

    function text(
        dc as Graphics.Dc, x as Number, y as Number,
        font as Graphics.FontType or Graphics.VectorFont,
        str as String, justify as Number, color as Number
    ) as Void {
        fill(dc, color);
        dc.drawText(x, y, font, str, justify | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Text rotated to stand on its own radius. `screenDeg` is the clockwise
    //! screen angle to turn the glyph by; Garmin measures counter-clockwise,
    //! hence the negation. Falls back to upright text where the device has no
    //! drawAngledText.
    function angledText(
        dc as Graphics.Dc, x as Number, y as Number,
        font as Graphics.FontType or Graphics.VectorFont,
        str as String, justify as Number, color as Number, screenDeg as Float
    ) as Void {
        fill(dc, color);
        var j = justify | Graphics.TEXT_JUSTIFY_VCENTER;
        // drawAngledText only accepts a vector font; a bitmap font id crashes it.
        if ((dc has :drawAngledText) && font instanceof Graphics.VectorFont) {
            // Its own horizontal justification rounds in the rotated frame, which
            // walks the glyph up to 1.5px off the point it was asked to centre on
            // — enough to visibly miss the weekday highlight. Anchor at the start
            // of the baseline instead and step back along it ourselves.
            var back = 0.0;
            if (justify == Graphics.TEXT_JUSTIFY_CENTER) {
                back = dc.getTextWidthInPixels(str, font) / 2.0;
            } else if (justify != Graphics.TEXT_JUSTIFY_LEFT) {
                back = dc.getTextWidthInPixels(str, font).toFloat();
            }
            var deg = norm(-screenDeg);
            var rad = deg * DEG;
            dc.drawAngledText(
                Math.round(x - Math.cos(rad) * back).toNumber(),
                Math.round(y + Math.sin(rad) * back).toNumber(),
                font, str,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
                deg.toNumber());
        } else {
            dc.drawText(x, y, font, str, j);
        }
    }

    //! First font in `fonts` whose rendering of `str` fits inside `maxW`.
    function fitFont(
        dc as Graphics.Dc, str as String, maxW as Number,
        fonts as Array<Graphics.FontType or Graphics.VectorFont>
    ) as Graphics.FontType or Graphics.VectorFont {
        for (var i = 0; i < fonts.size(); i++) {
            if (dc.getTextWidthInPixels(str, fonts[i]) <= maxW) { return fonts[i]; }
        }
        return fonts[fonts.size() - 1];
    }

    // ------------------------------------------------------------------ //
    // Weather glyphs. Drawn from primitives so the build ships no bitmaps
    // and scales to any display. Authored in a 24x24 box centred on (x, y),
    // `k` = box size / 24.
    // ------------------------------------------------------------------ //

    function cloud(dc as Graphics.Dc, x as Float, y as Float, k as Float, color as Number) as Void {
        disc(dc, x - 4.5 * k, y + 1.0 * k, 4.6 * k, color);
        disc(dc, x + 2.5 * k, y - 0.5 * k, 6.2 * k, color);
        box(dc, (x - 9.0 * k).toNumber(), (y + 1.5 * k).toNumber(),
            (15.5 * k).toNumber(), (4.2 * k).toNumber(), color);
        disc(dc, x - 9.0 * k, y + 3.6 * k, 2.1 * k, color);
        disc(dc, x + 6.5 * k, y + 3.6 * k, 2.1 * k, color);
    }

    function sun(dc as Graphics.Dc, x as Float, y as Float, k as Float, color as Number) as Void {
        disc(dc, x, y, 5.6 * k, color);
        for (var i = 0; i < 8; i++) {
            var a = i * 45.0 * DEG;
            stroke(dc,
                x + Math.cos(a) * 8.2 * k, y + Math.sin(a) * 8.2 * k,
                x + Math.cos(a) * 11.4 * k, y + Math.sin(a) * 11.4 * k,
                2.0 * k, color);
        }
    }

    function drizzle(
        dc as Graphics.Dc, x as Float, y as Float, k as Float, count as Number, color as Number
    ) as Void {
        for (var i = 0; i < count; i++) {
            var ox = x + (i - (count - 1) / 2.0) * 5.5 * k;
            stroke(dc, ox + 1.2 * k, y, ox - 1.2 * k, y + 5.0 * k, 2.0 * k, color);
        }
    }

    function bolt(dc as Graphics.Dc, x as Float, y as Float, k as Float, color as Number) as Void {
        fill(dc, color);
        dc.fillPolygon([
            [(x + 1.5 * k).toNumber(), (y + 0.5 * k).toNumber()],
            [(x - 4.0 * k).toNumber(), (y + 7.0 * k).toNumber()],
            [(x - 0.5 * k).toNumber(), (y + 7.0 * k).toNumber()],
            [(x - 2.0 * k).toNumber(), (y + 12.0 * k).toNumber()],
            [(x + 4.5 * k).toNumber(), (y + 4.5 * k).toNumber()],
            [(x + 0.8 * k).toNumber(), (y + 4.5 * k).toNumber()]
        ]);
    }

    //! `kind` comes from Metrics.WX_*
    function weather(
        dc as Graphics.Dc, kind as Number, x as Number, y as Number, sizePx as Number,
        hi as Number, mid as Number
    ) as Void {
        var k = sizePx / 24.0;
        var fx = x.toFloat();
        var fy = y.toFloat();

        switch (kind) {
            case 0: // clear
                sun(dc, fx, fy, k, hi);
                break;
            case 1: // partly cloudy
                sun(dc, fx + 4.0 * k, fy - 4.5 * k, k * 0.78, hi);
                cloud(dc, fx - 1.0 * k, fy + 3.0 * k, k * 0.92, mid);
                break;
            case 3: // rain
                cloud(dc, fx, fy - 4.0 * k, k * 0.94, mid);
                drizzle(dc, fx, fy + 4.5 * k, k, 3, hi);
                break;
            case 4: // snow
                cloud(dc, fx, fy - 4.0 * k, k * 0.94, mid);
                for (var i = 0; i < 3; i++) {
                    disc(dc, fx + (i - 1) * 5.5 * k, fy + 6.5 * k, 1.8 * k, hi);
                }
                break;
            case 5: // thunderstorm
                cloud(dc, fx, fy - 4.5 * k, k * 0.94, mid);
                bolt(dc, fx, fy, k, hi);
                break;
            case 6: // fog / haze
                cloud(dc, fx, fy - 5.0 * k, k * 0.88, mid);
                stroke(dc, fx - 8.0 * k, fy + 5.0 * k, fx + 8.0 * k, fy + 5.0 * k, 2.0 * k, hi);
                stroke(dc, fx - 6.0 * k, fy + 9.5 * k, fx + 6.0 * k, fy + 9.5 * k, 2.0 * k, hi);
                break;
            case 7: // wind
                stroke(dc, fx - 9.0 * k, fy - 5.0 * k, fx + 4.0 * k, fy - 5.0 * k, 2.2 * k, mid);
                stroke(dc, fx - 9.0 * k, fy + 0.5 * k, fx + 7.0 * k, fy + 0.5 * k, 2.2 * k, hi);
                stroke(dc, fx - 9.0 * k, fy + 6.0 * k, fx + 1.0 * k, fy + 6.0 * k, 2.2 * k, mid);
                break;
            default: // cloudy
                cloud(dc, fx, fy - 1.0 * k, k, mid);
                break;
        }
    }
}
