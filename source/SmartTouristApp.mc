import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;



class SmartTouristApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        var view = new SmartTouristView();
        return [ view , new SmartTouristDelegate(view) ] as Array<Views or InputDelegates>;
    }
}

function getApp() as SmartTouristApp {
    return Application.getApp() as SmartTouristApp;
}