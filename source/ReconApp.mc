import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class ReconApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new ReconView()];
    }

    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}
