import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Geometry for the RECON face.
//!
//! Every number below is authored against a 454x454 round display — the same
//! coordinate space as `preview/face.js` — and scaled to the real screen at
//! runtime. When a value changes here it must change there too, otherwise the
//! preview stops telling the truth.
module Layout {

    const DESIGN = 454.0;

    var scale as Float = 1.0;
    var cx as Number = 227;
    var cy as Number = 227;

    //! Recomputed on the first draw; screen size never changes after that.
    function init(dc as Graphics.Dc) as Void {
        scale = dc.getWidth() / DESIGN;
        cx = dc.getWidth() / 2;
        cy = dc.getHeight() / 2;
    }

    //! Design units -> device pixels, rounded.
    function u(v as Numeric) as Number {
        return Math.round(v * scale).toNumber();
    }

    //! Design units -> device pixels, unrounded (for polar maths).
    function f(v as Numeric) as Float {
        return v * scale;
    }

    // ---- type sizes -------------------------------------------------------
    // Em heights on the design grid, mirrored from `preview/face.js`. Garmin's
    // bitmap fonts are a fixed per-device ladder that does not scale with the
    // grid, so everything but the clock is drawn with a vector font at exactly
    // these sizes. Get these wrong and the rows collide.
    // Scaled 1.3x from the authored sizes; the row anchors below were re-fitted
    // to the measured clearances rather than scaled with them, because the
    // screen did not get bigger.
    const WD_EM = 23;
    const STRIP_EM = 33;
    const LABEL_EM = 25;
    const BB_VALUE_EM = 31;
    const BAT_EM = 26;
    const VALUE_EMS = [48, 43, 38, 33];
    const ICON_PX = 31;      // stat-cell bitmaps, rasterised at this pixel size

    // ---- bezel ------------------------------------------------------------
    const RING_R = 218;
    const RING_W = 2;

    // ---- weekday arc ------------------------------------------------------
    const WD_R = 202;
    const WD_STEP = 12.5;    // degrees between labels
    // The highlight is sized and placed off the glyph it marks rather than
    // pinned to a radius: Hangul fills its em box, Latin fills about half of
    // it, and one fixed arc ends up either strangling the wide script or
    // floating away from the narrow one.
    //
    // PAD is 1.0 — the underline is exactly as wide as the glyph. Drawing it
    // wider (the authored look was 1.4x) makes the sub-pixel rounding in
    // drawAngledText read as a centring error, because the overhang lands
    // almost entirely on one side of a 7px letter.
    const WD_BAR_PAD = 1.0;  // highlight length as a multiple of the glyph width
    const WD_BAR_GAP = 4.3;  // clearance between the glyph box and the highlight
    const WD_BAR_H = 3;

    // ---- date | weather strip --------------------------------------------
    const STRIP_CY = 91;
    const STRIP_DIV_TOP = 74;
    const STRIP_DIV_H = 34;
    const DATE_RIGHT = 209;
    const WX_CX = 252;
    const WX_SIZE = 29;
    const TEMP_LEFT = 275;

    // ---- hero time --------------------------------------------------------
    const TIME_CY = 165;
    const COLON_GAP = 17;   // half-gap between the digits and the colon
    const COLON_SQ = 8;
    const COLON_DY = 22;
    const COLON_SHIFT = -3;

    // ---- HR | STEPS row ---------------------------------------------------
    const ROW_DIV_TOP = 223;
    const ROW_DIV_BOT = 311;
    const CELL_L = 146;
    const CELL_R = 308;
    const CELL_MAX_W = 132;
    const LABEL_CY = 240;
    const VALUE_CY = 282;
    const BAR_Y = 306;
    const BAR_H = 5;
    const BAR_W = 78;
    const SEG_GAP = 4;

    // ---- body battery band ------------------------------------------------
    const BB_LABEL_CY = 334;
    const BB_X0 = 102;
    const BB_X1 = 352;
    const BB_Y0 = 354;
    const BB_Y1 = 383;
    const BB_BAR = 3.4;
    const BB_SLOT = 5.0;
    const BB_CAP = 3;

    // ---- device battery ---------------------------------------------------
    const BAT_CY = 402;
    const BAT_ICON_W = 21;
    const BAT_ICON_H = 11;
    const BAT_ARC_R = 213;
    const BAT_ARC_W = 6;
    const BAT_ARC_SPAN = 46;  // degrees either side of bottom dead centre

    // ---- always-on display ------------------------------------------------
    const AOD_STRIP_CY = 152;
    const AOD_TIME_CY = 227;
    const AOD_BAT_CY = 312;

    const TRACK_LABEL = 1.4;  // letter spacing on small caps labels
}
