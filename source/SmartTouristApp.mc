import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;

var hasDirectMessagingSupport = true;
var page = 0;
var strings = ["","","","",""];
var stringsSize = 5;
var mailMethod;
var phoneMethod;
var crashOnMessage = false;

class SmartTouristApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
        mailMethod = method(:onMail);
        phoneMethod = method(:onPhone);
        if(Communications has :registerForPhoneAppMessages) {
            Communications.registerForPhoneAppMessages(phoneMethod);
        } else if(Communications has :setMailboxListener) {
            Communications.setMailboxListener(mailMethod);
        } else {
            hasDirectMessagingSupport = false;
        }
        
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

    function onMail(mailIter) {
        var mail;

        mail = mailIter.next();

        while(mail != null) {
            var i;
            for(i = (stringsSize - 1); i > 0; i -= 1) {
                strings[i] = strings[i-1];
            }
            strings[0] = mail.toString();
            page = 1;
            mail = mailIter.next();
        }

        Communications.emptyMailbox();
        WatchUi.requestUpdate();
    }

    function onPhone(msg) {
        var i;

        if((crashOnMessage == true) && msg.data.equals("Hi")) {
            msg.length(); // Generates a symbol not found error in the VM
        }

        for(i = (stringsSize - 1); i > 0; i -= 1) {
            strings[i] = strings[i-1];
        }
        strings[0] = msg.data.toString();
        page = 1;

        WatchUi.requestUpdate();
    }
}

function getApp() as SmartTouristApp {
    return Application.getApp() as SmartTouristApp;
}