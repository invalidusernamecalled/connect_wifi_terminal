Stable versions-
- `a76faea`bc3e75fd9804c54af778493878c3d6d6b

Batch Script to List and Connect to Wi-Fi Networks.

File Name- `connect.bat`

> [!NOTE]
> + this script may generate some working files in the location it is saved at.
> it is therefore recommended to save the script in its own separate folder.

#### Troubleshooting Section

##### (for the Script to work):-
+ Windows location services need to be <b>ON</b>
+ Let apps access your location <b>ON</b>
+ Let desktop apps access your location <b>ON</b>
+ "Network Command Shell" location access needs be <b>ON</b>
+ <b>Run as Administrator</b> (Create shorcut and modify its Properties to "Always Run As Administrator")

<SUP> Link - [Changes to Windows API impact network scanning request](https://learn.microsoft.com/en-us/windows/win32/nativewifi/wi-fi-access-location-changes)

##### Details

You might come accross the following (or similar) message when running a scan with the script.

```
Network shell commands need location permission to access WLAN information. Turn on Location services on the Location page in Privacy & security settings.

Here is the URI for the Location page in the Settings app:
ms-settings:privacy-location
To open the Location page in the Settings app, hold down the Ctrl key and select the link, or run the following command:
start ms-settings:privacy-location

Or, to open the Location page from the Run dialog box, press Windows logo key + R, and then copy and paste the URI above.

Function WlanQueryInterface returns error 5:
The requested operation requires elevation (Run as administrator).
```
For network scanning to work due to new restrictions introduced in the Windows API you could use the following method. 

Goto  (Windows) Settings > Privacy & Security > Location<br>
+ You need to turn on "Location Services"<br>
+ You need to turn on "Let apps access your Location"
+ Remember to keep the App "Network Command Shell" in the "On" position.
+ You may need to then right-click the script and "Run as administrator"

It is recommended to create a shortcut and edit its properties to "Always Run as Administrator"
