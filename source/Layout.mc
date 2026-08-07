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

    // ---- bezel ------------------------------------------------------------
    const RING_R = 218;
    const RING_W = 2;

    // ---- weekday arc ------------------------------------------------------
    const WD_R = 202;
    const WD_STEP = 10.6;   // degrees between labels
    const WD_BAR_DY = 12;   // underline offset below the glyph, in screen space
    const WD_BAR_W = 19;
    const WD_BAR_H = 3;

    // ---- date | weather strip --------------------------------------------
    const STRIP_CY = 104;
    const STRIP_DIV_TOP = 91;
    const STRIP_DIV_H = 26;
    const DATE_RIGHT = 209;
    const WX_CX = 248;
    const WX_SIZE = 22;
    const TEMP_LEFT = 267;

    // ---- hero time --------------------------------------------------------
    const TIME_CY = 178;
    const COLON_GAP = 17;   // half-gap between the digits and the colon
    const COLON_SQ = 8;
    const COLON_DY = 22;
    const COLON_SHIFT = -3;

    // ---- HR | STEPS row ---------------------------------------------------
    const ROW_DIV_TOP = 238;
    const ROW_DIV_BOT = 306;
    const CELL_L = 146;
    const CELL_R = 308;
    const CELL_MAX_W = 132;
    const LABEL_CY = 246;
    const VALUE_CY = 274;
    const BAR_Y = 300;
    const BAR_H = 5;
    const BAR_W = 78;
    const SEG_GAP = 4;

    // ---- body battery band ------------------------------------------------
    const BB_LABEL_CY = 330;
    const BB_X0 = 102;
    const BB_X1 = 352;
    const BB_Y0 = 350;
    const BB_Y1 = 382;
    const BB_BAR = 3.4;
    const BB_SLOT = 5.0;
    const BB_CAP = 3;

    // ---- device battery ---------------------------------------------------
    const BAT_CY = 404;
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
