# SmartTourist

A Garmin device app for fenix 6/fenix 6 pro Solar smartwatch.
It enables heart rate, gps location, altitude, accelerometer, temperature and oxygen transmition to a companion mobile app.

To use the Garmin simulator, download the Connect IQ SDK from [here](https://developer.garmin.com/connect-iq/sdk/)
(download the sdk suited for your operating system and the appropriate Mobile SDK for the companion app) and follow the guide.

To connect the Garmin simulator to the companion app, follow the steps available in [here](https://developer.garmin.com/connect-iq/core-topics/communicating-with-mobile-apps/).

Some sample code and information is found [here](https://developer.garmin.com/connect-iq/core-topics/mobile-sdk-for-android/).
In essence, initialize connectIQ class of the mobile sdk in the android app by:
``` java
ConnectIQ connectIQ = ConnectIQ.getInstance(ConnectIQ.IQConnectType.<protocol>);
```
, where ```<protocol>``` is ```WIRELESS``` (for BLE communication, which is also default), ```TETHERED``` for debugging with usb.

How to use the app:

Press top right button on the watch or simulated watch to start getting heart rate etc. The obtained heart rate will be displayed on the screen. If a heart rate is not detected a '-' symbol will be displayed. This means that the watch needs to be readjusted in order to detect the user's heart rate. Press the same button to stop the process.

*Code specific:*

Main functionality is implemented in SmartTouristDelegate.mc. This file contains four classes:

CommListener -> used for transmiting data to companion app. It is initialized in SmartTouristDelegate class.

SmartTouristDelegate -> Implements core functionality. Initializes every other class used in the .mc file.

Functions implemented:
	
	-	onKey: Triggered when user presses a button on smartwatch. Starts/stop sensor/gps data transmition.
	-	setData: Handles input from the enabled sensors. (Updates global sensor variables and UI only when heart rate changes)
	-	onPosition: Handles latitude/longitude information from GPS. (Updates global gps variables)
	-	enableSensors : Enables heart rate, oxygen, temperature sensors and gps. Updates UI to inform user data transmition started.
	-	disableSensors : Disables heart rate, oxygen, temperature sensors and gps. Updates UI to inform user data transmition stoped.
	-	onPhone: Handles message received from mobile app. Currently used to start or stop data transmition. Expects a message as string of type "start" or "stop".
	-	onMail: Deprecated function that works like :onPhone. Used as a fallback method for older smartwatches.

SmartTouristDTO -> Class wrapper for data transmition. It is used to send latest updated data. Currently supports sending altitude, longitude, latitude, heart rate, oxygen, temperature, accelerometer, magnetometer.

Functions implemented:

	-	toDict: Wraps data into a dictionary.

SmartTouristHub - > Class that contains a timer that sends data every 2 seconds. To change the transmition interval change the initialized interval value from 2000 to prefered value.

Functions implemented:
	
	-	start: Starts timer. 
    - 	onTick: Sends data. Data are send as a dictionary of type event = {"type" => "data", "value" => {data}}
	-	stop: Stops timer.
	
*Note*

When starting or stoping data transmition from smartwatch an appropriate event is sent to the companion app to notify.
The event is sent as a dictionary of type event = {"type" => "action", "value" => "start/stop"}
	