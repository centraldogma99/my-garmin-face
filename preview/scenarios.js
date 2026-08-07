/**
 * Deterministic sample data for the preview renders.
 * Mirrors the shape that `source/Metrics.mc` assembles on device.
 */
(function (global) {
  'use strict';

  /** Plausible 12-hour body battery curve ending at `now`, oldest first. */
  function bbCurve(nowHour, current, points) {
    var out = [];
    for (var i = 0; i < points; i++) {
      var t = i / (points - 1); // 0 = 12h ago, 1 = now
      var hour = (nowHour - 12 + t * 12 + 24) % 24;
      var v;
      if (hour < 6.5) {
        // asleep: recharging
        v = 32 + (hour + 3.5) * 8.2;
      } else if (hour < 8) {
        v = 88 - (hour - 6.5) * 3;
      } else {
        v = 83 - (hour - 8) * 2.1;
      }
      v += Math.sin(t * 11) * 1.8 + Math.sin(t * 3.3) * 1.1;
      out.push(Math.max(5, Math.min(100, Math.round(v))));
    }
    // pin the last sample to the reported current value
    var drift = current - out[out.length - 1];
    for (var j = 0; j < out.length; j++) {
      out[j] = Math.max(0, Math.min(100, Math.round(out[j] + drift * (j / (out.length - 1)))));
    }
    return out;
  }

  var ZONES = [98, 118, 138, 158, 175, 195]; // zone1..zone5 lower bounds + max

  function base() {
    return {
      hour: 14,
      minute: 35,
      month: 8,
      day: 7,
      weekday: 5, // 0 = Sunday -> 5 = Friday
      hr: 72,
      hrZones: ZONES,
      steps: 8432,
      stepGoal: 10000,
      battery: 84,
      bodyBattery: 62,
      bbWindowLabel: '12H',
      bbHistory: bbCurve(14, 62, 96),
      weather: { condition: 'clear', temp: 28 },
    };
  }

  function merge(over) {
    var d = base();
    for (var k in over) d[k] = over[k];
    return d;
  }

  var SCENARIOS = {
    'default': { label: 'Weekday afternoon · resting', data: merge({}) },

    'workout': {
      label: 'Zone 4 workout',
      data: merge({
        hour: 19,
        minute: 6,
        weekday: 2,
        hr: 164,
        steps: 14208,
        battery: 61,
        bodyBattery: 34,
        bbHistory: bbCurve(19, 34, 96),
        weather: { condition: 'partly', temp: 24 },
      }),
    },

    'morning': {
      label: 'Early morning · recovered',
      data: merge({
        hour: 6,
        minute: 4,
        weekday: 1,
        hr: 51,
        steps: 312,
        battery: 97,
        bodyBattery: 100,
        bbHistory: bbCurve(6, 100, 96),
        weather: { condition: 'fog', temp: 11 },
      }),
    },

    'edge': {
      label: 'Worst case · wide values, low battery',
      data: merge({
        hour: 0,
        minute: 0,
        weekday: 6,
        month: 12,
        day: 31,
        hr: 188,
        steps: 128456,
        stepGoal: 10000,
        battery: 8,
        bodyBattery: 5,
        bbHistory: bbCurve(0, 5, 96),
        weather: { condition: 'storm', temp: -17 },
      }),
    },

    'nodata': {
      label: 'Sensors unavailable',
      data: merge({
        hour: 11,
        minute: 9,
        weekday: 3,
        hr: null,
        steps: 0,
        bodyBattery: null,
        bbHistory: [],
        battery: 44,
        weather: { condition: 'cloudy', temp: null },
      }),
    },

    'aod': {
      label: 'Always-on display',
      data: merge({ hour: 3, minute: 12, weekday: 0, battery: 71 }),
      opts: { mode: 'aod' },
    },
  };

  global.ReconScenarios = { SCENARIOS: SCENARIOS, base: base, bbCurve: bbCurve, ZONES: ZONES };
})(typeof window !== 'undefined' ? window : globalThis);
