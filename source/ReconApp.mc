import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class ReconApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as Array<Views or InputDelegates> {
        return [new ReconView()] as Array<Views or InputDelegates>;
    }

    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}
