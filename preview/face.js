/**
 * RECON watch face — shared render spec.
 *
 * This file is the visual source of truth for the design. Every coordinate is
 * authored against a 454x454 round display and scaled by `s = size / 454`, which
 * is exactly what `source/Layout.mc` does on device. Keep the two in sync: if a
 * number changes here it must change there.
 */
(function (global) {
  'use strict';

  var DESIGN = 454;

  /* ------------------------------------------------------------------ *
   * Palette
   *
   * Colour is used as a channel, not decoration:
   *   accent (orange) -> today's marker, the colon, and a met step goal
   *   steel / white   -> primary readouts (steps, battery)
   *   cyan            -> body battery, and nothing else
   *   zone ramp       -> heart rate, and nothing else
   * ------------------------------------------------------------------ */
  var C = {
    bg: '#000000',
    ring: '#171C22',
    hair: '#242B34',
    track: '#1F262E',
    arcTrack: '#2A323C',
    /* Brightness is the hierarchy: only the time gets full white. */
    textHi: '#F2F5F8',
    textVal: '#D8E0E7',
    textMid: '#A9B4BF',
    textLow: '#5F6B77',
    textFaint: '#39424C',
    accent: '#FF6A1A',
    steel: '#93A0AB',
    bb: '#35BEF5',
    bbDim: '#113A4D',
    bbGrid: '#141C23',
    batOk: '#93A0AB',
    batWarn: '#FF9500',
    batLow: '#FF3B30',
    /* index 0 = below zone 1 (resting), 1..5 = HR zones 1..5 */
    zone: ['#48535D', '#8A98A6', '#2E9BF0', '#35C759', '#FF9500', '#FF3B30'],
  };

  /* ------------------------------------------------------------------ *
   * Layout (design units @ 454)
   * ------------------------------------------------------------------ */
  var L = {
    ringR: 218,
    ringW: 2,

    /* weekday bezel arc */
    wdR: 202,
    wdStep: 12.5, // degrees between labels
    wdFont: 23,
    wdBarPad: 1.0,   // highlight length as a multiple of the glyph width
    wdBarGap: 4.3,   // clearance between the glyph box and the highlight
    wdBarH: 3,

    /* date | weather strip */
    stripCy: 91,
    stripDivTop: 74,
    stripDivBot: 108,
    dateRight: 209,
    stripFont: 33,
    wxCx: 252,
    wxSize: 29,
    tempLeft: 275,

    /* hero time */
    timeCy: 165,
    timeFont: 123,
    colonHalfGap: 17,
    colonSq: 8,
    colonDy: 22,
    colonShift: -3,

    /* HR | STEPS row */
    rowDivTop: 223,
    rowDivBot: 311,
    cellL: 146,
    cellR: 308,
    labelCy: 240,
    labelFont: 25,
    valueCy: 282,
    valueFont: 37,
    cellMaxW: 132,
    barY: 306,
    barH: 5,
    barW: 78,
    segGap: 4,

    /* body battery band */
    bbLabelCy: 334,
    bbLabelFont: 23,
    bbValueFont: 31,
    bbX0: 102,
    bbX1: 352,
    bbY0: 354,
    bbY1: 383,
    bbBar: 3.4,
    bbSlot: 5,
    bbCap: 3,

    /* device battery */
    batCy: 402,
    batFont: 26,
    iconBox: 34,
    batIconW: 21,
    batIconH: 10.5,
    batArcR: 213,
    batArcW: 6,
    batArcSpan: 46, // degrees either side of bottom dead centre

  };

  var VALUE_SIZES = [48, 43, 38, 33];

  var WEEKDAYS = {
    ko: ['일', '월', '화', '수', '목', '금', '토'],
    en: ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
  };

  var FS = 1; // font stress multiplier, set per draw

  var FAMILY = "'Noto Sans KR', 'Noto Sans', 'DejaVu Sans', sans-serif";

  /* ------------------------------------------------------------------ *
   * Primitives
   * ------------------------------------------------------------------ */
  /** Design-unit font size -> device pixels, including the stress multiplier. */
  function gf(g, v) {
    return g(v) * FS;
  }

  function font(ctx, size, weight) {
    ctx.font = (weight || 400) + ' ' + size + 'px ' + FAMILY;
  }

  function text(ctx, str, x, y, opts) {
    opts = opts || {};
    font(ctx, opts.size, opts.weight);
    ctx.fillStyle = opts.color;
    ctx.textAlign = opts.align || 'center';
    ctx.textBaseline = 'middle';
    ctx.letterSpacing = (opts.tracking || 0) + 'px';
    ctx.fillText(str, x, y);
    ctx.letterSpacing = '0px';
  }

  /**
   * Garmin's FONT_NUMBER_* faces are tabular — every digit has the same
   * advance, so a clock never shifts as the minutes tick over. Web fonts are
   * proportional (a "1" is narrow), which would make the preview lie about
   * centring, so digits are laid out cell by cell here instead.
   */
  function digitCell(ctx, size, weight, tracking) {
    var w = 0;
    for (var d = 0; d <= 9; d++) w = Math.max(w, measure(ctx, String(d), size, weight, 0));
    return w + (tracking || 0);
  }

  function tabular(ctx, str, x, y, opts) {
    var cw = digitCell(ctx, opts.size, opts.weight, opts.tracking);
    var total = cw * str.length;
    var start = opts.align === 'right' ? x - total : opts.align === 'center' ? x - total / 2 : x;
    for (var i = 0; i < str.length; i++) {
      text(ctx, str.charAt(i), start + i * cw + cw / 2, y, {
        size: opts.size,
        weight: opts.weight,
        color: opts.color,
      });
    }
    return total;
  }

  /** Largest of `sizes` whose rendering of `str` stays inside `maxW`. */
  function fitSize(ctx, str, maxW, sizes, weight, tracking) {
    for (var i = 0; i < sizes.length; i++) {
      if (measure(ctx, str, sizes[i], weight, tracking) <= maxW) return sizes[i];
    }
    return sizes[sizes.length - 1];
  }

  function measure(ctx, str, size, weight, tracking) {
    font(ctx, size, weight);
    ctx.letterSpacing = (tracking || 0) + 'px';
    var w = ctx.measureText(str).width;
    ctx.letterSpacing = '0px';
    return w;
  }

  function rect(ctx, x, y, w, h, color) {
    ctx.fillStyle = color;
    ctx.fillRect(x, y, w, h);
  }

  /** Stroke an arc. Angles are screen degrees: 0 = 3 o'clock, positive = clockwise. */
  function arc(ctx, cx, cy, r, from, to, width, color, cap) {
    if (Math.abs(to - from) < 0.01) return;
    ctx.beginPath();
    ctx.strokeStyle = color;
    ctx.lineWidth = width;
    ctx.lineCap = cap || 'butt';
    ctx.arc(cx, cy, r, (from * Math.PI) / 180, (to * Math.PI) / 180, to < from);
    ctx.stroke();
    ctx.lineCap = 'butt';
  }

  function circle(ctx, x, y, r, color) {
    ctx.beginPath();
    ctx.fillStyle = color;
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fill();
  }

  function line(ctx, x0, y0, x1, y1, width, color) {
    ctx.beginPath();
    ctx.strokeStyle = color;
    ctx.lineWidth = width;
    ctx.moveTo(x0, y0);
    ctx.lineTo(x1, y1);
    ctx.stroke();
  }

  function poly(ctx, pts, color) {
    ctx.beginPath();
    ctx.fillStyle = color;
    ctx.moveTo(pts[0][0], pts[0][1]);
    for (var i = 1; i < pts.length; i++) ctx.lineTo(pts[i][0], pts[i][1]);
    ctx.closePath();
    ctx.fill();
  }

  /* ------------------------------------------------------------------ *
   * Weather glyphs — drawn, not fonted, so the device build needs no assets.
   * Every glyph is authored in a 24x24 box centred on (x, y) and scaled by k.
   * ------------------------------------------------------------------ */
  function cloud(ctx, x, y, k, color) {
    circle(ctx, x - 4.5 * k, y + 1 * k, 4.6 * k, color);
    circle(ctx, x + 2.5 * k, y - 0.5 * k, 6.2 * k, color);
    rect(ctx, x - 9 * k, y + 1.5 * k, 15.5 * k, 4.2 * k, color);
    circle(ctx, x - 9 * k, y + 3.6 * k, 2.1 * k, color);
    circle(ctx, x + 6.5 * k, y + 3.6 * k, 2.1 * k, color);
  }

  function sun(ctx, x, y, k, color, rays) {
    circle(ctx, x, y, 5.6 * k, color);
    if (rays === false) return;
    for (var i = 0; i < 8; i++) {
      var a = (i * Math.PI) / 4;
      line(
        ctx,
        x + Math.cos(a) * 8.2 * k,
        y + Math.sin(a) * 8.2 * k,
        x + Math.cos(a) * 11.4 * k,
        y + Math.sin(a) * 11.4 * k,
        2 * k,
        color,
      );
    }
  }

  /* Stat-cell icons: Material Symbols (Apache-2.0), the same artwork the
     device build ships as PNG. Authored on a 960-unit grid with the origin at
     the baseline, hence the translate. */
  var ICON_PATHS = {
    heart: 'm480-120-58-52q-101-91-167-157T150-447.5Q111-500 95.5-544T80-634q0-94 63-157t157-63q52 0 99 22t81 62q34-40 81-62t99-22q94 0 157 63t63 157q0 46-15.5 90T810-447.5Q771-395 705-329T538-172l-58 52Z',
    walk: 'm280-40 112-564-72 28v136h-80v-188l202-86q14-6 29.5-7t29.5 4q14 5 26.5 14t20.5 23l40 64q26 42 70.5 69T760-520v80q-70 0-125-29t-94-74l-25 123 84 80v300h-80v-260l-84-64-72 324h-84Zm260-700q-33 0-56.5-23.5T460-820q0-33 23.5-56.5T540-900q33 0 56.5 23.5T620-820q0 33-23.5 56.5T540-740Z',
  };

  function icon(ctx, name, x, y, size, color) {
    var s = size / 960;
    ctx.save();
    ctx.translate(x - size / 2, y - size / 2);
    ctx.scale(s, s);
    ctx.translate(0, 960);
    ctx.fillStyle = color;
    ctx.fill(new Path2D(ICON_PATHS[name]));
    ctx.restore();
  }

  function drizzle(ctx, x, y, k, color, count) {
    for (var i = 0; i < count; i++) {
      var ox = x + (i - (count - 1) / 2) * 5.5 * k;
      line(ctx, ox + 1.2 * k, y, ox - 1.2 * k, y + 5 * k, 2 * k, color);
    }
  }

  var WX = {
    clear: function (ctx, x, y, k, c) {
      sun(ctx, x, y, k, c.hi);
    },
    partly: function (ctx, x, y, k, c) {
      sun(ctx, x + 4 * k, y - 4.5 * k, k * 0.78, c.hi);
      cloud(ctx, x - 1 * k, y + 3 * k, k * 0.92, c.mid);
    },
    cloudy: function (ctx, x, y, k, c) {
      cloud(ctx, x, y - 1 * k, k, c.mid);
    },
    rain: function (ctx, x, y, k, c) {
      cloud(ctx, x, y - 4 * k, k * 0.94, c.mid);
      drizzle(ctx, x, y + 4.5 * k, k, c.hi, 3);
    },
    snow: function (ctx, x, y, k, c) {
      cloud(ctx, x, y - 4 * k, k * 0.94, c.mid);
      for (var i = 0; i < 3; i++) circle(ctx, x + (i - 1) * 5.5 * k, y + 6.5 * k, 1.8 * k, c.hi);
    },
    storm: function (ctx, x, y, k, c) {
      cloud(ctx, x, y - 4.5 * k, k * 0.94, c.mid);
      poly(
        ctx,
        [
          [x + 1.5 * k, y + 0.5 * k],
          [x - 4 * k, y + 7 * k],
          [x - 0.5 * k, y + 7 * k],
          [x - 2 * k, y + 12 * k],
          [x + 4.5 * k, y + 4.5 * k],
          [x + 0.8 * k, y + 4.5 * k],
        ],
        c.hi,
      );
    },
    fog: function (ctx, x, y, k, c) {
      cloud(ctx, x, y - 5 * k, k * 0.88, c.mid);
      line(ctx, x - 8 * k, y + 5 * k, x + 8 * k, y + 5 * k, 2 * k, c.hi);
      line(ctx, x - 6 * k, y + 9.5 * k, x + 6 * k, y + 9.5 * k, 2 * k, c.hi);
    },
    wind: function (ctx, x, y, k, c) {
      line(ctx, x - 9 * k, y - 5 * k, x + 4 * k, y - 5 * k, 2.2 * k, c.mid);
      line(ctx, x - 9 * k, y + 0.5 * k, x + 7 * k, y + 0.5 * k, 2.2 * k, c.hi);
      line(ctx, x - 9 * k, y + 6 * k, x + 1 * k, y + 6 * k, 2.2 * k, c.mid);
      arc(ctx, x + 4 * k, y - 2.4 * k, 2.6 * k, -90, 130, 2.2 * k, c.mid);
      arc(ctx, x + 7 * k, y + 3.2 * k, 3 * k, -90, 130, 2.2 * k, c.hi);
    },
  };

  /* ------------------------------------------------------------------ *
   * Data helpers
   * ------------------------------------------------------------------ */
  function hrZone(hr, zones) {
    if (hr == null || !zones) return 0;
    var z = 0;
    for (var i = 0; i < 5; i++) if (hr >= zones[i]) z = i + 1;
    return z;
  }

  function grouped(n) {
    return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  }

  function pad2(n) {
    return n < 10 ? '0' + n : String(n);
  }

  function batteryColor(pct) {
    if (pct <= 15) return C.batLow;
    if (pct <= 30) return C.batWarn;
    return C.batOk;
  }

  /* ------------------------------------------------------------------ *
   * Sections
   * ------------------------------------------------------------------ */

  function drawBezel(ctx, g) {
    ctx.beginPath();
    ctx.strokeStyle = C.ring;
    ctx.lineWidth = g(L.ringW);
    ctx.arc(g(227), g(227), g(L.ringR), 0, Math.PI * 2);
    ctx.stroke();
  }

  function drawWeekdays(ctx, g, data, opts) {
    var labels = WEEKDAYS[opts.weekdayLocale] || WEEKDAYS.ko;
    var today = data.weekday; // 0 = Sunday
    var cx = g(227);
    var cy = g(227);

    /* Each glyph is rotated to stand on its own radius, so the row reads as a
       fan struck from the centre rather than as text sitting on an arch. */
    for (var i = 0; i < 7; i++) {
      var deg = (i - 3) * L.wdStep;
      var th = (deg * Math.PI) / 180;
      var on = i === today;
      var color = on ? C.accent : C.textLow;

      ctx.save();
      ctx.translate(cx + Math.sin(th) * g(L.wdR), cy - Math.cos(th) * g(L.wdR));
      ctx.rotate(th);
      text(ctx, labels[i], 0, 0, {
        size: gf(g, L.wdFont),
        weight: 500,
        color: color,
      });
      ctx.restore();

      if (on) {
        /* The highlight is measured off the glyph it marks. Hangul fills its em
           box, Latin fills about half of it, and one fixed arc span looks pasted
           on under whichever is narrower. */
        var w = measure(ctx, labels[i], gf(g, L.wdFont), 500, 0);
        var barR = g(L.wdR) - gf(g, L.wdFont) / 2 - g(L.wdBarGap);
        var half = (w * L.wdBarPad * 90) / (Math.PI * barR);
        arc(ctx, cx, cy, barR, -90 + deg - half, -90 + deg + half, g(L.wdBarH), color);
      }
    }
  }

  function drawStrip(ctx, g, data, opts) {
    var cy = L.stripCy;
    var hi = C.textVal;
    var mid = C.textMid;

    rect(ctx, g(227) - g(1) / 2, g(L.stripDivTop), g(1), g(L.stripDivBot - L.stripDivTop), C.hair);

    text(ctx, pad2(data.month) + '.' + pad2(data.day), g(L.dateRight), g(cy), {
      size: gf(g, L.stripFont),
      weight: 600,
      color: hi,
      align: 'right',
      tracking: g(0.5),
    });

    var glyph = WX[data.weather.condition] || WX.cloudy;
    glyph(ctx, g(L.wxCx), g(cy), (g(L.wxSize) / 24) * 1.0, { hi: hi, mid: mid });

    var t = data.weather.temp == null ? '--' : String(Math.round(data.weather.temp));
    text(ctx, t + '°', g(L.tempLeft), g(cy), {
      size: gf(g, L.stripFont),
      weight: 600,
      color: hi,
      align: 'left',
    });
  }

  function drawTime(ctx, g, data, opts) {
    var hh = pad2(data.hour);
    var mm = pad2(data.minute);
    var size = gf(g, L.timeFont);
    var color = C.textHi;
    var cx = g(227);
    var cy = g(L.timeCy);

    tabular(ctx, hh, cx - g(L.colonHalfGap), cy, {
      size: size,
      weight: 700,
      color: color,
      align: 'right',
      tracking: g(-2),
    });
    tabular(ctx, mm, cx + g(L.colonHalfGap), cy, {
      size: size,
      weight: 700,
      color: color,
      align: 'left',
      tracking: g(-2),
    });

    var sq = g(L.colonSq);
    var ck = C.accent;
    var ccy = cy + g(L.colonShift);
    rect(ctx, cx - sq / 2, ccy - g(L.colonDy) - sq / 2, sq, sq, ck);
    rect(ctx, cx - sq / 2, ccy + g(L.colonDy) - sq / 2, sq, sq, ck);
  }

  function drawStatRow(ctx, g, data) {
    /* column rule */
    rect(ctx, g(227) - g(1) / 2, g(L.rowDivTop), g(1), g(L.rowDivBot - L.rowDivTop), C.hair);

    /* ---- heart rate ---- */
    var z = hrZone(data.hr, data.hrZones);
    var hrTxt = data.hr == null ? '--' : String(data.hr);

    icon(ctx, 'heart', g(L.cellL), g(L.labelCy), gf(g, L.iconBox), C.textLow);
    text(ctx, hrTxt, g(L.cellL), g(L.valueCy), {
      size: fitSize(ctx, hrTxt, g(L.cellMaxW), VALUE_SIZES.map(function (v) { return gf(g, v); }), 700, g(-0.5)),
      weight: 700,
      color: C.textVal,
      tracking: g(-0.5),
    });

    /* Five-segment zone ladder: how many segments are lit gives the zone,
       and they all take the current zone's colour. Lighting each segment in
       its own colour turned the bar into a rainbow that read as decoration.
       Below zone 1 the first segment glows in the resting tint, so the
       readout never looks like a dead sensor. */
    var segW = (g(L.barW) - 4 * g(L.segGap)) / 5;
    var x0 = g(L.cellL) - g(L.barW) / 2;
    var lit = data.hr == null ? 0 : Math.max(1, z);
    for (var i = 0; i < 5; i++) {
      rect(
        ctx,
        x0 + i * (segW + g(L.segGap)),
        g(L.barY),
        segW,
        g(L.barH),
        i < lit ? C.zone[z] : C.track,
      );
    }

    /* ---- steps ---- */
    icon(ctx, 'walk', g(L.cellR), g(L.labelCy), gf(g, L.iconBox), C.textLow);
    var stepTxt = grouped(data.steps);
    text(ctx, stepTxt, g(L.cellR), g(L.valueCy), {
      size: fitSize(ctx, stepTxt, g(L.cellMaxW), VALUE_SIZES.map(function (v) { return gf(g, v); }), 700, g(-0.5)),
      weight: 700,
      color: C.textVal,
      tracking: g(-0.5),
    });

    var frac = Math.max(0, Math.min(1, data.steps / (data.stepGoal || 1)));
    var bx = g(L.cellR) - g(L.barW) / 2;
    rect(ctx, bx, g(L.barY), g(L.barW), g(L.barH), C.track);
    rect(ctx, bx, g(L.barY), g(L.barW) * frac, g(L.barH), frac >= 1 ? C.accent : C.steel);
  }

  function drawBodyBattery(ctx, g, data) {
    var lx = g(L.bbX0);
    text(ctx, 'BODY BATTERY', lx, g(L.bbLabelCy), {
      size: gf(g, L.bbLabelFont),
      weight: 600,
      color: C.textLow,
      align: 'left',
      tracking: g(1.4),
    });
    var cur = data.bodyBattery;
    var curTxt = cur == null ? '--' : String(cur);
    var lw = measure(ctx, 'BODY BATTERY', gf(g, L.bbLabelFont), 600, g(1.4));
    var tag = data.bbWindowLabel || '12H';
    var tagW = measure(ctx, tag, gf(g, L.bbLabelFont), 600, g(1.4));
    var valueLeft = g(L.bbX1) - measure(ctx, curTxt, gf(g, L.bbValueFont), 700, g(-0.5));

    if (lx + lw + g(9) + tagW <= valueLeft - g(10)) {
      text(ctx, tag, lx + lw + g(9), g(L.bbLabelCy), {
        size: gf(g, L.bbLabelFont),
        weight: 600,
        color: C.textFaint,
        align: 'left',
        tracking: g(1.4),
      });
    }

    text(ctx, curTxt, g(L.bbX1), g(L.bbLabelCy), {
      size: gf(g, L.bbValueFont),
      weight: 700,
      color: C.bb,
      align: 'right',
      tracking: g(-0.5),
    });

    /* plot area */
    var x0 = g(L.bbX0);
    var y0 = g(L.bbY0);
    var y1 = g(L.bbY1);
    var h = y1 - y0;

    var series = data.bbHistory || [];
    rect(ctx, x0, y1, g(L.bbX1 - L.bbX0), g(1), C.hair); // baseline
    if (series.length === 0) return; // no history: bare axis, no orphan gridline
    rect(ctx, x0, y0 + h * 0.5, g(L.bbX1 - L.bbX0), g(1), C.bbGrid); // 50 guide

    /* Body battery lives in the 40-100 band most of the day, so a plain 0-100
       bar chart collapses into a solid slab. Filling the column dim and
       capping it bright keeps the absolute level *and* draws the curve. */
    var slots = Math.floor(g(L.bbX1 - L.bbX0) / g(L.bbSlot));
    var cap = g(L.bbCap);
    for (var i = 0; i < slots; i++) {
      var v = series[Math.floor((i * series.length) / slots)];
      if (v == null) continue;
      var bh = Math.max(cap, (Math.max(0, Math.min(100, v)) / 100) * h);
      var bx = x0 + i * g(L.bbSlot);
      var isNow = i === slots - 1;
      rect(ctx, bx, y1 - bh, g(L.bbBar), bh, C.bbDim);
      rect(ctx, bx, y1 - bh, g(L.bbBar), cap, isNow ? C.textHi : C.bb);
    }
  }

  function drawBattery(ctx, g, data, opts) {
    var pct = data.battery;
    var col = batteryColor(pct);

    var cx = g(227);
    var cy = L.batCy;

    var from = 90 + L.batArcSpan;
    var sweep = 2 * L.batArcSpan;
    arc(ctx, cx, cx, g(L.batArcR), from, from - sweep, g(L.batArcW), C.arcTrack);
    arc(ctx, cx, cx, g(L.batArcR), from, from - sweep * (pct / 100), g(L.batArcW), col);

    /* numeric readout */
    var label = Math.round(pct) + '%';
    var tw = measure(ctx, label, gf(g, L.batFont), 600, g(0.5));
    var iw = g(L.batIconW);
    var total = iw + g(8) + tw;
    var ix = cx - total / 2;
    var iy = g(cy) - g(L.batIconH) / 2;

    ctx.strokeStyle = col;
    ctx.lineWidth = g(1.6);
    ctx.strokeRect(ix + g(0.8), iy + g(0.8), iw - g(1.6), g(L.batIconH) - g(1.6));
    rect(ctx, ix + iw, g(cy) - g(3), g(2.4), g(6), col);
    rect(
      ctx,
      ix + g(3),
      iy + g(3),
      Math.max(g(1), (iw - g(6)) * (pct / 100)),
      g(L.batIconH) - g(6),
      col,
    );

    text(ctx, label, ix + iw + g(8), g(cy), {
      size: gf(g, L.batFont),
      weight: 600,
      color: col,
      align: 'left',
      tracking: g(0.5),
    });
  }

  /* ------------------------------------------------------------------ *
   * Entry point
   * ------------------------------------------------------------------ */
  function drawFace(ctx, size, data, opts) {
    opts = opts || {};
    opts.weekdayLocale = opts.weekdayLocale || 'ko';
    FS = opts.fontScale || 1;
    var g = function (v) {
      return (v * size) / DESIGN;
    };

    ctx.save();
    circle(ctx, size / 2, size / 2, size / 2, C.bg);

    drawBezel(ctx, g);
    drawWeekdays(ctx, g, data, opts);
    drawStrip(ctx, g, data, opts);
    drawTime(ctx, g, data, opts);
    drawStatRow(ctx, g, data);
    drawBodyBattery(ctx, g, data);
    drawBattery(ctx, g, data, opts);

    /* Always-on display is the same face behind a row mask: every other
       device row is blanked and the parity flips with the minute, which is
       what AMOLED burn-in protection asks for (<=10% lit, no pixel lit for
       three minutes). Mirrors ReconView.drawAodMask. */
    if (opts.mode === 'aod') {
      ctx.fillStyle = C.bg;
      for (var y = data.minute % 2; y < size; y += 2) {
        ctx.fillRect(0, y, size, 1);
      }
    }

    ctx.restore();
  }

  global.ReconFace = {
    DESIGN: DESIGN,
    palette: C,
    layout: L,
    draw: drawFace,
    hrZone: hrZone,
  };
})(typeof window !== 'undefined' ? window : globalThis);
