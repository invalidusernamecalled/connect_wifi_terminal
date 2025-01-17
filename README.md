+++++++++++++++++++++++++++++++++++++++++++++++
 + this script generates some files in the same folder
 + it is therefore recommended to host the script in a a separate folder

+++++++++++++++++++++++++++++++++++++++++++++++

# Windows Troubleshooting

<SUP> Link - [Changes to Windows API impact network scanning request](https://learn.microsoft.com/en-us/windows/win32/nativewifi/wi-fi-access-location-changes)

You might come accross the following (or similar) message when running a scan from the script.

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

Usually doing this once, resolves it forever. (Subsequent runs of the app don't require "Run as administrator")
