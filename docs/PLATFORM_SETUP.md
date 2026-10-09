# Platform setup (run once after `flutter create .`)

## Android — `android/app/src/main/AndroidManifest.xml`
Add inside `<manifest>`, above `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
```

Set `minSdkVersion 21` in `android/app/build.gradle` (geolocator requires it).

## iOS — `ios/Runner/Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Your location is used to show where you are on the Kengtung map and to find directions to places.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Your location is used to show where you are on the Kengtung map and to find directions to places.</string>
```

## Web
No permission files needed. The browser prompts for location on first use, and
manages its own tile cache, so the "Download" buttons are hidden there.
Location requires the site to be served over **HTTPS** (localhost is exempt).
