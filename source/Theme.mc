import Toybox.Graphics;
import Toybox.Lang;

//! Colour is a data channel here, not decoration:
//!   accent  -> today's marker, the colon, a met step goal
//!   steel   -> gauges and the device battery
//!   cyan    -> body battery, and nothing else
//!   zones   -> heart rate, and nothing else
//! Keeps parity with the palette in `preview/face.js`.
module Theme {

    const BG          = 0x000000;
    const RING        = 0x171C22;
    const HAIR        = 0x242B34;
    const TRACK       = 0x1F262E;  // segment / bar tracks
    const ARC_TRACK   = 0x2A323C;  // bezel gauge track, needs to read as a scale

    const TEXT_HI     = 0xF2F5F8;  // the time, and only the time
    const TEXT_VAL    = 0xD8E0E7;  // stat readouts
    const TEXT_MID    = 0xA9B4BF;
    const TEXT_LOW    = 0x5F6B77;  // labels
    const TEXT_FAINT  = 0x39424C;

    const ACCENT      = 0xFF6A1A;
    const STEEL       = 0x93A0AB;

    const BB          = 0x35BEF5;
    const BB_DIM      = 0x113A4D;
    const BB_GRID     = 0x141C23;

    const BAT_WARN    = 0xFF9500;
    const BAT_LOW     = 0xFF3B30;

    // Always-on display: same composition, far fewer lit pixels.
    const AOD_TEXT    = 0x606A73;
    const AOD_DIM     = 0x4C555D;
    const AOD_LOW     = 0x2E353D;
    const AOD_ACCENT  = 0x8A4413;
    const AOD_HAIR    = 0x161A1F;

    //! index 0 = below zone 1 (resting), 1..5 = heart rate zones 1..5
    const ZONES = [0x48535D, 0x8A98A6, 0x2E9BF0, 0x35C759, 0xFF9500, 0xFF3B30] as Array<Number>;

    function zoneColor(zone as Number) as Number {
        if (zone < 0) { zone = 0; }
        if (zone > 5) { zone = 5; }
        return ZONES[zone];
    }

    function batteryColor(pct as Float) as Number {
        if (pct <= 15.0) { return BAT_LOW; }
        if (pct <= 30.0) { return BAT_WARN; }
        return STEEL;
    }
}
