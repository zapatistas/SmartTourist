import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.Communications;
import Toybox.Position;
import Toybox.System;
import Toybox.Communications;
import Toybox.BluetoothLowEnergy;

var hr;
var accel;
var magno;
var temp;
var lat;
var longit;
var altit;
var oxygen;
var heading;
var cadence;
var power;
var pressure;
var sensorInfo;
var gpsHeading;
var gpsSpeed;
var gpsTime;
var lastHr;
var lastGpsQuality;
var hasDirectMessagingSupport = true;
var mailMethod;
var phoneMethod;
var START = "start";
var STOP = "stop";
var CRASH = "crash";
var NOT_AVAILABLE = "NOT_AVAILABLE";
var LAST_KNOWN = "LAST_KNOWN";
var POOR = "POOR";
var USABLE = "USABLE";
var GOOD = "GOOD";
var intNotAvailable = 0 ;
var intLastKnown = 1 ;
var intPoor = 2;
var intUsable = 3;
var intGood = 4;


class CommListener extends Communications.ConnectionListener {
    // var delegate;
    var event;
    var lastEventSent;

    function initialize(smDel) {
        Communications.ConnectionListener.initialize();
        // self.delegate = smDel;
    }

    function onComplete() {
        System.println("Transmit Complete");
        self.lastEventSent = true;
    }

    function onError() {
        System.println("Transmit Failed");
        self.lastEventSent = false;
        // self.delegate.disableSensors();
    }
}

class SmartTouristDelegate extends WatchUi.BehaviorDelegate {
    var view;
    var isRunning;
    var timer;
    var listener;

    function initialize(view) {
        self.view = view;
        self.isRunning = false;
        self.listener = new CommListener(self);
        self.timer = new SmartTouristHub(2000,self.listener);
        mailMethod = method(:onMail);
        phoneMethod = method(:onPhone);
        if(Communications has :registerForPhoneAppMessages) {
            Communications.registerForPhoneAppMessages(phoneMethod);
        } else if(Communications has :setMailboxListener) {
            Communications.setMailboxListener(mailMethod);
        } else {
            hasDirectMessagingSupport = false;
        }
        BehaviorDelegate.initialize();
    }

    function onKey(keyEvent){
        var key = keyEvent.getKey();
        var keyType = keyEvent.getType();

        // When up-right button is pressed on phone start/stop sensor/gps data transmition
        if (key == WatchUi.KEY_ENTER and keyType == WatchUi.PRESS_TYPE_ACTION){
            if (!self.isRunning){ 
               enableSensors();
               var event = { "type" => "action", "value" => "start"};
               self.listener.event = event;
               Communications.transmit(event, null, self.listener);
            }
            else{
                disableSensors();
                var event = { "type" => "action", "value" => "stop"};
                self.listener.event = event;
                Communications.transmit(event, null, self.listener);
            }

            return true;
        }
        return false;
    }

    function setData(SensorInfo as Sensor.Info) as Void{
        var d = SensorInfo;
        if (self.isRunning){
            if (d.heartRate != null){
                if (d.heartRate != $.hr){
                    $.hr = d.heartRate;
                    self.view.heartR.setText(" "+$.hr);
                    WatchUi.requestUpdate();
                }
            }
            else{ // TODO: decided if we want to keep this or let watch show last heart rate
                
                self.view.heartR.setText("  -");
                WatchUi.requestUpdate();
            }

            if ( d.accel != null){ 
                $.accel = d.accel;
            }

            if ( d.temperature != null && d.temperature != $.temp ){ 
                $.temp = d.temperature;
            }

            if ( d.mag != null){ 
                $.magno = d.mag;
            }

            if (d.altitude != null && $.altit != d.altitude){
                $.altit = d.altitude;
            }

            if (d.oxygenSaturation != null && $.oxygen != d.oxygenSaturation){
                $.oxygen = d.oxygenSaturation;
            }

            $.cadence = d.cadence;
            $.power = d.power;
            $.pressure = d.pressure;
            $.heading = d.heading;
           
            // System.println("Temperature " + $.temp);
            // System.println("Altitude " + $.altit);
            // System.println("Magnometer " + $.magno);
            // System.println("Oxygen saturation " + $.oxygen);
            // System.println("Accelerometer " + $.accel);
        }
        
    }

    function onPosition(info as Position.Info) as Void {
        // Handle gps latitude and longitude 
        // TODO: Maybe send GPS quality in the future as well
        
        var myLocation = info.position.toDegrees();
        $.lat = myLocation[0];
        $.longit = myLocation[1];
        $.gpsHeading = info.heading;
        // $.gpsTime = info.when.mDateTime;
        $.gpsSpeed = info.speed;

        if ( info.accuracy == $.intNotAvailable){
            $.lastGpsQuality = NOT_AVAILABLE;
        }
        else if ( info.accuracy == $.intLastKnown){
            $.lastGpsQuality = LAST_KNOWN;
        }
        else if ( info.accuracy == $.intPoor){
            $.lastGpsQuality = POOR;
        }
        else if ( info.accuracy == $.intUsable){
            $.lastGpsQuality = USABLE;
        }
        else if ( info.accuracy == $.intGood){
            $.lastGpsQuality = GOOD;
        }

        System.println("GPS quality " + $.lastGpsQuality);
        System.println("Latitude: " + myLocation[0]); // e.g. 38.856147
        System.println("Longitude: " + myLocation[1]); // e.g -94.800953
    }


    function enableSensors(){
        // Enabling sensors and gps location. Right now heart rate, oxygen and temperature sensors are enabled one by one to avoid bugs created from Sensor.setEnabledSensors()
        
        if (Sensor has :enableSensorType){
            Sensor.enableSensorType(Sensor.SENSOR_HEARTRATE);
            Sensor.enableSensorType(Sensor.SENSOR_PULSE_OXIMETRY);
            Sensor.enableSensorType(Sensor.SENSOR_TEMPERATURE);
        }else{
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE,Sensor.SENSOR_PULSE_OXIMETRY,Sensor.SENSOR_TEMPERATURE]);
        }
        
        Sensor.enableSensorEvents( method( :setData ) );

        var options = {
            :acquisitionType => Position.LOCATION_CONTINUOUS
        };

        if (Position has :POSITIONING_MODE_AVIATION) {
            options[:mode] = Position.POSITIONING_MODE_AVIATION;
        }
        
        if ( Position has :CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5 &&
             Position has :hasConfigurationSupport &&
             Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5))
        {
            options[:configuration] = Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5;
        } else if (Position has :CONSTELLATION_GPS_GLONASS) {
            options[:constellations] = [ Position.CONSTELLATION_GPS, Position.CONSTELLATION_GLONASS ];            
        } else{
            options = Position.LOCATION_CONTINUOUS;
        }
         
        // Continuous location updates using selected options
        try{
            
            Position.enableLocationEvents(options, method(:onPosition));
        }
        catch (ex){
            System.println(ex.getErrorMessage());
            System.println("Position not enabled");
        }
        
        // Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:self.onPosition));
        self.view.startText.setText("Stop");
        self.view.stringHr.setText("Heart rate:");
        self.view.heartR.setText("-");
        self.isRunning = true;
        WatchUi.requestUpdate();
        self.timer.start();
       
    }

    function disableSensors(){
        self.view.startText.setText("Start");
        if (Sensor has :enableSensorType){
            Sensor.disableSensorType(Sensor.SENSOR_HEARTRATE);
            Sensor.disableSensorType(Sensor.SENSOR_PULSE_OXIMETRY);
            Sensor.disableSensorType(Sensor.SENSOR_TEMPERATURE);
        }else{
            Sensor.setEnabledSensors([]);
        }
        
        Sensor.enableSensorEvents(null); 
        var options = {:acquisitionType => Position.LOCATION_DISABLE} ;
        Position.enableLocationEvents(options, method(:onPosition));
        // System.println("Disable sensors");
        self.isRunning = false;
        $.lastHr = $.hr;
        $.hr = 0;
        self.view.stringHr.setText("");
        self.view.heartR.setText("");
        WatchUi.requestUpdate();
        self.timer.stop();
        
    }

    function onMail(mailIter) {

        // Deprecated class for older Garmin watches. Same functionality as :onPhone

        var mail;

        mail = mailIter.next();

        while(mail != null) {
            mail = mail.toString();
            if (mail == $.START and !self.isRunning){
                enableSensors();
            }else if ( mail == $.STOP and self.isRunning){
                disableSensors();
            }

            mail = mailIter.next();
        }

        Communications.emptyMailbox();
        WatchUi.requestUpdate();
    }

    function onPhone(msg) {
       // Receive messages from phone. At this moment the expected format is a string that contains "start" or "stop" for data transmition.
       if (msg.data == $.START and !self.isRunning){
            enableSensors();
       }else if ( msg.data == $.STOP and self.isRunning){
            disableSensors();
       }
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new SmartTouristMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}



class  SmartTouristDTO {
    public var altitude;
    public var longitude;
    public var latitude;
    public var heartRate;
    public var temperature;
    public var oxygen;
    public var accelerometer;
    public var magnetometer;
    public var gpsQuality;
    public var gpsAccuracy = 7.5;
    public var gpsSpeed;
    public var gpsHeading;
    public var gpsTime;
    public var cadence;
    public var power;
    public var pressure;
    public var heading;

    function initialize(altitude, longitude, latitude, heartRate, temperature, oxygen, accelerometer, magnetometer, gpsQuality){//, gpsSpeed, gpsHeading){
        self.altitude = altitude;
        self.longitude = longitude;
        self.latitude = latitude;
        self.heartRate = heartRate;
        self.temperature = temperature;
        self.oxygen = oxygen;
        // self.cadence = cadence;
        // self.power = power;
        // self.pressure = pressure;
        // self.heading = heading;
        self.accelerometer = accelerometer;
        self.magnetometer = magnetometer;
        self.gpsQuality = gpsQuality;
        self.gpsSpeed = gpsSpeed;
        self.gpsHeading = gpsHeading;
        // self.gpsTime = gpsTime;
       
    }

    function toDict(){

        var json = { "altitude" => self.altitude, "longitude" => self.longitude, "latitude" => self.latitude,
                "heart_rate" => self.heartRate, "temperature" => self.temperature, "oxygen" => self.oxygen,
                // "cadence" => self.cadence, "power" => self.power,  "heading" => self.heading,"pressure" => self.pressure,
                "accelerometer" => self.accelerometer, "magnetometer" => self.magnetometer, "gpsQuality" => self.gpsQuality,
                "gpsAccuracy" => self.gpsAccuracy};//, "gpsSpeed" => self.gpsSpeed, "gpsHeading" => self.gpsHeading};
                //"gpsTime" => self.gpsTime};

        return json;
    }
}


class SmartTouristHub{
    var timer;
    var timeListener;
    var transmitting;
    var isRunning;
    var interval;
    

    function initialize(interval,listener){
        self.timer = new Timer.Timer();
        self.timeListener = listener;
        self.transmitting = false;
        self.isRunning = false;
        self.interval = interval;
    }

    function start(){
        if(!self.isRunning){
            self.timer.start(method(:onTick),interval,true);
            self.isRunning = true;
            // System.println("Timer started");
        }
    }
    function onTick(){
        if(!self.transmitting){
            self.transmitting = true; //$.cadence, $.power, $.pressure, $.heading,
            var smartTouristJsonObj = new SmartTouristDTO($.altit,$.longit,$.lat,$.hr,$.temp,$.oxygen, $.accel, $.magno, $.lastGpsQuality);//, $.gpsSpeed, $.gpsHeading);//, $.gpsTime);

            var jsonDictionary = smartTouristJsonObj.toDict();
            // System.println(jsonDictionary);

            var event = { "type" => "data", "value" => jsonDictionary};
            self.timeListener.event = event;
            Communications.transmit(event, null, self.timeListener);
            self.transmitting = false;
        }
    }
    function stop(){
        if(isRunning){
            timer.stop();
            self.isRunning = false;
            // System.println("Timer Stopped");
        }

    }

}
