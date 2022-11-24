import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.Communications;
import Toybox.Position;
import Toybox.System;
import Toybox.Communications;

var hr;
var accel;
var magno;
var temp;
var lat;
var longit;
var altit;
var oxygen;
var lastHr;


class CommListener extends Communications.ConnectionListener {
    function initialize() {
        Communications.ConnectionListener.initialize();
    }

    function onComplete() {
        System.println("Transmit Complete");
    }

    function onError() {
        System.println("Transmit Failed");
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
        self.listener = new CommListener();
        self.timer = new SmartTouristHub(2000,self.listener);
        BehaviorDelegate.initialize();
    }

    function onKey(keyEvent){
        var key = keyEvent.getKey();
        var keyType = keyEvent.getType();
        
        if (key == WatchUi.KEY_ENTER and keyType == WatchUi.PRESS_TYPE_ACTION){
            if (!self.isRunning){ 
                // Sensor.setEnabledSensors( [Sensor.SENSOR_HEARTRATE,Sensor.SENSOR_PULSE_OXIMETRY,Sensor.SENSOR_TEMPERATURE] );\
                Sensor.enableSensorType(Sensor.SENSOR_HEARTRATE);
                Sensor.enableSensorType(Sensor.SENSOR_PULSE_OXIMETRY);
                Sensor.enableSensorType(Sensor.SENSOR_TEMPERATURE);
                Sensor.enableSensorEvents( method( :setData ) );

                var options = {
                    :acquisitionType => Position.LOCATION_CONTINUOUS
                };

                if (Position has :POSITIONING_MODE_AVIATION) {
                    options[:mode] = Position.POSITIONING_MODE_AVIATION;
                }

                if (Position has :CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5) {
                    options[:configuration] = :CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5;
                } else if (Position has :CONSTELLATION_GPS_GLONASS) {
                    options[:constellations] = [ Position.CONSTELLATION_GPS, Position.CONSTELLATION_GLONASS ];
                } else {
                    options = Position.LOCATION_CONTINUOUS;
                }

                // Continuous location updates using selected options
                try{
                    Position.enableLocationEvents(options, method(:onPosition));
                }
                catch (ex){
                    System.println(ex);
                }
                
                // Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:self.onPosition));
                self.view.startText.setText("Stop");
                self.view.stringHr.setText("Heart rate:");
                self.view.heartR.setText("-");
                self.isRunning = true;
                WatchUi.requestUpdate();
                self.timer.start();
            }
            else{
                self.view.startText.setText("Start");
                Sensor.disableSensorType(Sensor.SENSOR_HEARTRATE);
                Sensor.disableSensorType(Sensor.SENSOR_PULSE_OXIMETRY);
                Sensor.disableSensorType(Sensor.SENSOR_TEMPERATURE);
                Sensor.enableSensorEvents(null); 
                var options = {:acquisitionType => Position.LOCATION_DISABLE} ;
                Position.enableLocationEvents(options, method(:onPosition));
                          
                self.isRunning = false;
                $.lastHr = $.hr;
                $.hr = 0;
                self.view.stringHr.setText("");
                self.view.heartR.setText("");
                WatchUi.requestUpdate();
                self.timer.stop();
            }

            return true;
        }
        return false;
    }


    function onPosition(info as Position.Info) as Void {
        var myLocation = info.position.toDegrees();
        
        $.lat = myLocation[0];
        $.longit = myLocation[1];
        System.println("Latitude: " + myLocation[0]); // e.g. 38.856147
        System.println("Longitude: " + myLocation[1]); // e.g -94.800953
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

        
            System.println("Temperature " + $.temp);
            System.println("Altitude " + $.altit);
            System.println("Magnometer " + $.magno);
            System.println("Oxygen saturation " + $.oxygen);
            System.println("Accelerometer " + $.accel);
        }
        
    }

    // function setData(sensorData as SensorData) as Void{
    //     var d = sensorData;
    //     if (sensorData has :heartRateData && sensorData.heartRateData != null) {
    //       $.hr = sensorData.heartRateData.heartBeatIntervals;
    //       $.gps = sensorData.accelerometerData.
    //     }
    //     System.println(sensorData.heartRateData.heartBeatIntervals);
    // }

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

    function initialize(altitude,longitude,latitude,heartRate,temperature,oxygen){
        self.altitude = altitude;
        self.longitude = longitude;
        self.latitude = latitude;
        self.heartRate = heartRate;
        self.temperature = temperature;
        self.oxygen = oxygen;
    }

    function sendData(){

        var json = { "Altitude" => self.altitude, "Longitude" => self.longitude, "Latitude" => self.latitude,
                "Heart Rate" => self.heartRate, "Temperature" => self.temperature, "Oxygen" => self.oxygen};

        return json;
    }
}


class SmartTouristHub{
    var timer;
    var timeListener;
    var transmitting;
    var isRunning;
    var interval;
    

    function initialize(interval,listener){ //listener){
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
        }
    }
    function onTick(){
        if(!self.transmitting){
            self.transmitting = true;
            
            var smartTouristJsonObj = new SmartTouristDTO($.altit,$.longit,$.lat,$.hr,$.temp,$.oxygen);
            var jsonDictionary = smartTouristJsonObj.sendData();
            
            Communications.transmit(jsonDictionary, null, self.timeListener);
        }
    }
    function stop(){
        if(isRunning){
            timer.stop();
            self.isRunning = false;
        }

    }

}
