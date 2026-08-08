import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;

//! Everything the view needs, gathered once per draw.
//!
//! Every sensor here is optional on some device or in some state, so each
//! getter degrades to null and the view renders a "--" placeholder rather
//! than a blank region.
class Metrics {

    // weather glyph ids, shared with Gfx.weather
    const WX_CLEAR = 0;
    const WX_PARTLY = 1;
    const WX_CLOUDY = 2;
    const WX_RAIN = 3;
    const WX_SNOW = 4;
    const WX_STORM = 5;
    const WX_FOG = 6;
    const WX_WIND = 7;

    const BB_COLUMNS = 50;
    const BB_WINDOW_SEC = 12 * 60 * 60;
    const BB_MAX_SAMPLES = 360;
    const BB_REFRESH_SEC = 300;

    var hour as Number = 0;
    var minute as Number = 0;
    var month as Number = 1;
    var day as Number = 1;
    var weekday as Number = 0;          // 0 = Sunday

    var battery as Float = 0.0;

    var hr as Number or Null = null;
    var hrZone as Number = 0;           // 0 = below zone 1

    var steps as Number = 0;
    var stepGoal as Number = 0;

    var bodyBattery as Number or Null = null;
    var bbSeries as Array<Number> or Null = null;

    var wxKind as Number = 2;  // WX_CLOUDY, set properly in initialize()
    var wxTemp as Number or Null = null;

    private var _zones as Array<Number> or Null = null;
    private var _bbStamp as Number = 0;

    function initialize() {
        wxKind = WX_CLOUDY;
        _bbStamp = -BB_REFRESH_SEC;   // force the first history read
    }

    function refresh() as Void {
        var now = Time.now();
        var t = Gregorian.info(now, Time.FORMAT_SHORT);
        hour = t.hour;
        minute = t.min;
        month = t.month;
        day = t.day;
        weekday = t.day_of_week - 1;    // API is 1 = Sunday

        battery = System.getSystemStats().battery;

        readActivity();
        readHeartRate();
        readBodyBattery(now.value());
        readWeather();
    }

    // ---------------------------------------------------------------- //

    private function readActivity() as Void {
        var info = ActivityMonitor.getInfo();
        if (info == null) { return; }
        steps = (info.steps != null) ? info.steps : 0;
        stepGoal = (info.stepGoal != null && info.stepGoal > 0) ? info.stepGoal : 10000;
    }

    private function readHeartRate() as Void {
        hr = null;

        var act = Activity.getActivityInfo();
        if (act != null && act.currentHeartRate != null) {
            hr = act.currentHeartRate;
        } else if (ActivityMonitor has :getHeartRateHistory) {
            var iter = ActivityMonitor.getHeartRateHistory(1, true);
            if (iter != null) {
                var sample = iter.next();
                if (sample != null
                    && sample.heartRate != null
                    && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    hr = sample.heartRate;
                }
            }
        }

        hrZone = zoneFor(hr);
    }

    //! Zone boundaries are stable, so they are read once and kept.
    private function zoneFor(bpm as Number or Null) as Number {
        if (bpm == null) { return 0; }

        if (_zones == null && (UserProfile has :getHeartRateZones)) {
            _zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        }
        var z = _zones;
        if (z == null || z.size() < 5) { return 0; }

        var zone = 0;
        for (var i = 0; i < 5; i++) {
            if (bpm >= z[i]) { zone = i + 1; }
        }
        return zone;
    }

    //! Body battery history, downsampled to one value per plotted column.
    //! Rebuilt every few minutes only — the walk over the iterator is the most
    //! expensive thing this face does.
    private function readBodyBattery(nowSec as Number) as Void {
        if (nowSec - _bbStamp < BB_REFRESH_SEC) { return; }
        _bbStamp = nowSec;
        bodyBattery = null;
        bbSeries = null;

        if (!(Toybox has :SensorHistory)
            || !(Toybox.SensorHistory has :getBodyBatteryHistory)) {
            return;
        }

        var iter = Toybox.SensorHistory.getBodyBatteryHistory({
            :period => new Time.Duration(BB_WINDOW_SEC),
            :order => Toybox.SensorHistory.ORDER_NEWEST_FIRST
        });
        if (iter == null) { return; }

        var raw = [] as Array<Number>;
        var sample = iter.next();
        while (sample != null && raw.size() < BB_MAX_SAMPLES) {
            if (sample.data != null) {
                raw.add(sample.data.toNumber());
            }
            sample = iter.next();
        }
        if (raw.size() == 0) { return; }

        bodyBattery = raw[0];   // newest-first, so index 0 is now

        var last = raw.size() - 1;
        var series = new [BB_COLUMNS] as Array<Number>;
        for (var i = 0; i < BB_COLUMNS; i++) {
            // column 0 is the oldest sample, column BB_COLUMNS-1 is now
            var age = (BB_COLUMNS - 1 - i) / (BB_COLUMNS - 1).toFloat();
            series[i] = raw[Math.round(age * last).toNumber()];
        }
        bbSeries = series;
    }

    private function readWeather() as Void {
        wxTemp = null;
        wxKind = WX_CLOUDY;

        if (!(Toybox has :Weather)) { return; }

        var cond = Toybox.Weather.getCurrentConditions();
        if (cond == null) { return; }

        if (cond.temperature != null) {
            var c = cond.temperature.toFloat();  // the API always reports Celsius
            var units = System.getDeviceSettings().temperatureUnits;
            wxTemp = (units == System.UNIT_STATUTE)
                ? Math.round(c * 9.0 / 5.0 + 32.0).toNumber()
                : Math.round(c).toNumber();
        }

        if (cond.condition != null) {
            wxKind = glyphFor(cond.condition);
        }
    }

    private function glyphFor(condition as Number) as Number {
        switch (condition) {
            case Toybox.Weather.CONDITION_CLEAR:
            case Toybox.Weather.CONDITION_FAIR:
            case Toybox.Weather.CONDITION_MOSTLY_CLEAR:
                return WX_CLEAR;

            case Toybox.Weather.CONDITION_PARTLY_CLEAR:
            case Toybox.Weather.CONDITION_PARTLY_CLOUDY:
            case Toybox.Weather.CONDITION_THIN_CLOUDS:
                return WX_PARTLY;

            case Toybox.Weather.CONDITION_RAIN:
            case Toybox.Weather.CONDITION_LIGHT_RAIN:
            case Toybox.Weather.CONDITION_HEAVY_RAIN:
            case Toybox.Weather.CONDITION_SHOWERS:
            case Toybox.Weather.CONDITION_LIGHT_SHOWERS:
            case Toybox.Weather.CONDITION_HEAVY_SHOWERS:
            case Toybox.Weather.CONDITION_SCATTERED_SHOWERS:
            case Toybox.Weather.CONDITION_CHANCE_OF_SHOWERS:
            case Toybox.Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
            case Toybox.Weather.CONDITION_DRIZZLE:
            case Toybox.Weather.CONDITION_FREEZING_RAIN:
            case Toybox.Weather.CONDITION_UNKNOWN_PRECIPITATION:
                return WX_RAIN;

            case Toybox.Weather.CONDITION_SNOW:
            case Toybox.Weather.CONDITION_LIGHT_SNOW:
            case Toybox.Weather.CONDITION_HEAVY_SNOW:
            case Toybox.Weather.CONDITION_FLURRIES:
            case Toybox.Weather.CONDITION_CHANCE_OF_SNOW:
            case Toybox.Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
            case Toybox.Weather.CONDITION_RAIN_SNOW:
            case Toybox.Weather.CONDITION_LIGHT_RAIN_SNOW:
            case Toybox.Weather.CONDITION_HEAVY_RAIN_SNOW:
            case Toybox.Weather.CONDITION_WINTRY_MIX:
            case Toybox.Weather.CONDITION_SLEET:
            case Toybox.Weather.CONDITION_ICE_SNOW:
            case Toybox.Weather.CONDITION_HAIL:
                return WX_SNOW;

            case Toybox.Weather.CONDITION_THUNDERSTORMS:
            case Toybox.Weather.CONDITION_SCATTERED_THUNDERSTORMS:
            case Toybox.Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
            case Toybox.Weather.CONDITION_TORNADO:
            case Toybox.Weather.CONDITION_HURRICANE:
            case Toybox.Weather.CONDITION_TROPICAL_STORM:
            case Toybox.Weather.CONDITION_SQUALL:
                return WX_STORM;

            case Toybox.Weather.CONDITION_FOG:
            case Toybox.Weather.CONDITION_MIST:
            case Toybox.Weather.CONDITION_HAZE:
            case Toybox.Weather.CONDITION_HAZY:
            case Toybox.Weather.CONDITION_SMOKE:
            case Toybox.Weather.CONDITION_DUST:
            case Toybox.Weather.CONDITION_SAND:
            case Toybox.Weather.CONDITION_SANDSTORM:
            case Toybox.Weather.CONDITION_VOLCANIC_ASH:
                return WX_FOG;

            case Toybox.Weather.CONDITION_WINDY:
                return WX_WIND;

            default:
                return WX_CLOUDY;
        }
    }
}
