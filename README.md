+++++++++++++++++++++++++++++++++++++++++++++++
 + this script generates files in the same folder
 + recommended to create a new empty folder and run the script from there.

+++++++++++++++++++++++++++++++++++++++++++++++

# Windows Troubleshooting

<SUP> Link - [Windows changes to API impacts network scanning request](https://learn.microsoft.com/en-us/windows/win32/nativewifi/wi-fi-access-location-changes)

You might come accross the following (or similar) message when running the script.

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
To resolve this you need to goto  (Windows) Settings > Privacy & Security > Location<br>
+ You need to turn on "Location Services"<br>
+ You need to turn on "Let apps access your Location"
+ You may then need to right-click the script and "Run as administrator"

Usually doing this once, resolves it forever. (Subsequent runs of the app don't require "Run as administrator")
