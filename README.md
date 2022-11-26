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

