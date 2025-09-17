@echo off
setlocal enabledelayedexpansion
set pinged_google=0
if "%~1"=="skip" goto start
cd /d "%~dp0"
net session >nul 2>&1
if %errorlevel%==0 (
    set "title_append="
) else (
    set "title_append=^^^<^^^!^^^> Not running as Administrator" 
    echo ^^^<^^^!^^^> Not running as Administrator ANY COMMAND MAY NOT WORK ^^^!
)
    netsh wlan show networks 1>NUL
    if %errorlevel% NEQ 0 echo:&call :colors white red "Check"&echo|set/p=..Wifi is Switched On.&call :colors green black " Network scanning error code: [%errorlevel%]. Try again"&echo:&netsh wlan show interfaces | findstr /ic:"hardware on" /ic:"hardware off" /ic:"software on" /ic:"software off" /irc:"Name *[:]"& pause
title connect
for /f "delims=" %%i in ('powershell -c "write-host -nonewline `t"') do set "tab=%%i"
set networks=0
echo:Initializing..
for /f "tokens=1,2 delims=:" %%i in ('netsh wlan show interfaces ^| findstr /iR "Name GUID BSSID"') do (
set temp_name=%%i
set temp_name=!temp_name: =!
if /i "!temp_name!"=="Name" set /a networks+=1&for /f "tokens=* delims= " %%s in ("%%j") do set "name_[!networks!]=%%s"
REM set guid_[!networks!]=
if /i "!temp_name!"=="GUID" for /f "tokens=* delims= " %%d in ("%%j") do set guid_[!networks!]=%%d
)
set total_network=!networks!
call :pick_interface
for /l %%a in (1,1,!networks!) do if "!name_[%%a]!"=="!interfacename!" set real_guid=!guid_[%%a]!
for /f "delims=" %%i in ('dir /b "%ProgramData%\Microsoft\Wlansvc\Profiles\Interfaces\*" ^| find /i "%real_guid%"') do set guid_dir=%ProgramData%\Microsoft\Wlansvc\Profiles\Interfaces\%%i
:start
call :picknext
echo:Total network interfaces found:%total_network%
echo:
set /a all_ears=0
set ssid_connected=
for /f "tokens=1,* delims=:" %%i in ('netsh wlan show interfaces ^| findstr /ir "Name.*[:] State.*[:] ssid.*[:]"') do (
if !all_ears! NEQ 1 for /f "tokens=1 delims= " %%b in ("%%i") do if /i "%%b"=="name" for /f "tokens=* delims= " %%a in ("%%j") do set all_ears=9&if "%%a"=="!interfacename!" set /a all_ears=1
if !all_ears!==1 for /f "tokens=1 delims= " %%b in ("%%i") do if /i "%%b"=="ssid" for /f "tokens=* delims= " %%a in ("%%j") do set "ssid_connected=%%a"
if !all_ears!==1 for /f "tokens=1 delims= " %%b in ("%%i") do if /i "%%b"=="state" for /f "tokens=* delims= " %%a in ("%%j") do echo interface state is %%a*...
)

    set networks=0
    for /f "tokens=1,2,3,*" %%a in ('netsh wlan show networks mode^=bssid interface^="!interfacename!" ') do (

        if "%%a"=="SSID" (
            set /a networks=networks+1
            set ssid_[!networks!]=%%d
            set encrypt_[!networks!]=
            set auth_[!networks!]=
            set signal_strength_[!networks!]=
            set bssid_[!networks!]=
            set nutindex=0
        )

	if "%%a"=="Authentication" (
            set auth_[!networks!]=%%c
        )

        if "%%a"=="Encryption" (
            set encrypt_[!networks!]=%%c
        )

        if "%%a"=="Signal" (
            set temp=00%%c
            if "%%c" NEQ "" set temp=!temp:~-4!
            for %%z in ("!networks!") do set signal_strength_[%%~z]=!signal_strength_[%%~z]![!nutindex!]!temp!
        )
        
        if "%%a"=="BSSID" (
            for %%z in ("!networks!") do set /a nutindex+=1&set bssid_[%%~z]=!bssid_[%%~z]![!nutindex!]--%%d
        )


    )
    set total_found_networks=!networks!
    type nul >"%tmp%\wifi_sign.txt"
    for /l %%a in ( 1, 1, !networks! ) do (

        if "!ssid_[%%a]!" == "" ( 
            (echo:!signal_strength_[%%a]!/!bssid_[%%a]!/"")>>"%tmp%\wifi_sign.txt"
        ) else (
            if "!signal_strength_[%%a]!"=="" set signal_strength_[%%a]=signal_is_not_available
            if "!bssid_[%%a]!"=="" set bssid_[%%a]=N.A.
            (echo:!signal_strength_[%%a]!/!bssid_[%%a]!/"!ssid_[%%a]!")>>"%tmp%\wifi_sign.txt"
        )

    )
    set list_empty=1
    for /f "delims=" %%i in ('type "%tmp%\wifi_sign.txt"') do set /a list_empty=0
    if %list_empty%==1 echo (list empty)
    if %list_empty%==1 (set choice_list=) else (set choice_list=123456789)
    :print_info
    set skip=0
    set /a displaycurtain=networks
    set corecount=9
    :repat
    set /a displaycurtain=displaycurtain-9
    set /a escape=0 
    if !displaycurtain! LEQ 0 set escape=1
    set counter=0
    echo:===============================================================================
    echo:#^)SSID NAME%tab%SIGNAL:%tab%BSSID:
    echo:===============================================================================
    if !skip!==0 for /f "tokens=1,2,* delims=/" %%i in ('type "%tmp%\wifi_sign.txt" ^| sort /R /+4 ') do set /a counter+=1 & (if !counter! GTR 9 goto :next) & set "ssid_[!counter!]=%%~k"&(if "%%~k"=="" echo:!counter!^)-HIDDEN%tab%signal:%%i%tab%%tab%bssids:%%j) &if "%%~k"=="!ssid_connected!" (if "%%~k" NEQ "" echo !counter!^) %%~k*%tab%signal:%%i%tab%%tab%bssids:%%j) else (if "%%~k" NEQ "" echo !counter!^) %%~k%tab%signal:%%i%tab%%tab%bssids:%%j)
    
    if !skip! GTR 0 for /f "skip=%skip% tokens=1,2,* delims=/" %%i in ('type "%tmp%\wifi_sign.txt" ^| sort /R /+4') do set /a corecount+=1&set /a counter+=1 & (if !counter! GTR 9 goto :next) & set "ssid_[!counter!]=%%~k"&(if "%%~k"=="" echo:!counter!^)-HIDDEN%tab%signal:%%i%tab%%tab%bssids:%%j ) &if "%%~k"=="!ssid_connected!" (if "%%~k" NEQ "" echo !corecount!^)^(!counter!^) %%~k*%tab%signal:%%i%tab%%tab%bssids:%%j) else (if "%%~k" NEQ "" echo !corecount!^)^(!counter!^) %%~k%tab%signal:%%i%tab%%tab%bssids:%%j)
    :next
    set /a skip=skip+9
    call :colors black red "x^) Disconnect"
    echo: D^) re-connect E^) Existing profile
    if %list_empty%==0 echo Select 1-9   
    choice /c %choice_list%YXRDE /n /m "Or Press Y for (next page/relist),(R) for total refresh"    
    set choice=%errorlevel%
    if %list_empty%==1 if %choice%==2 netsh wlan disconnect interface="!interfacename!" &  goto :start
    if %list_empty%==1 if %choice%==3 echo refreshing ..&timeout 2 >NUL& start cmd /c "call "%~fp0"" & goto :eof
    if %list_empty%==1 if %choice%==4 call :re-connect & goto :start
    if %list_empty%==1 if %choice%==5 goto connect_all_profiles
    if %list_empty%==1 goto :start
    if !choice!==10 if !escape!==0 (call :picknext & goto repat) else (set /a skip=0 &set corecount=9 & call :picknext & goto repat)
    echo:
    if %choice%==11 call :disconnect & pause >NUL & goto :start
    if %choice%==12 echo refreshing ..&timeout 2 >NUL& start cmd /c "call "%~fp0" skip" & exit
    if %choice%==13 call :re-connect & goto :start
    if %choice%==14 goto connect_all_profiles
for /f "tokens=*" %%i in ("!ssid_[%choice%]!") do set ssid_[%choice%]="%%i"&set "ssid_choice_without_qoute=%%~i"
echo:
call :colors black green "CONNECTING..."
echo:
echo Guid==%guid_dir%
if "!ssid_[%choice%]!"=="" call :display_ssid_is_hidden
if "!whatis_SSID!" NEQ "" set "ssid_[%choice%]=!whatis_SSID!"
if "!ssid_[%choice%]!"=="" goto :after_call_hidden_ssid
for /f "tokens=*" %%i in ("!ssid_[%choice%]!") do echo:you chose %%i&set ssid_[%choice%]="%%i"&set "ssid_choice_without_qoute=%%~i"
for /f "delims=" %%i in ('echo:"GETTING PROFILE FILE for particular ssid:!ssid_choice_without_qoute!..."') do echo %%~i
powershell -c "$directoryPath = \"%guid_dir%\";$xmlFiles = Get-ChildItem -Path $directoryPath -Filter \"*.xml\";foreach ($xmlFile in $xmlFiles) {  [xml]$xmlContent = Get-Content $xmlFile.FullName;$ssidName = $xmlContent.WLANProfile.SSIDConfig.SSID.name; $profileName = $xmlContent.WLANProfile.name; if ($ssidName -eq \"!ssid_choice_without_qoute!\") { Write-Host \"$profileName\" } };">"%tmp%\wifi_sign_profile_name.txt"
set profile_exist=0
for /f "tokens=*" %%i in ('type "%tmp%\wifi_sign_profile_name.txt"') do set profile_exist=1
if !profile_exist! == 0 (call :no_profile_exists&goto :eof)
REM if "%~1" NEQ "" (for /f "tokens=*" %%i in ('type "%tmp%\wifi_sign_profile_name.txt"') do echo netsh wlan connect name="%%i" ssid="!ssid_choice_without_qoute!" interface="!interfacename!" & netsh wlan connect name="%%i" ssid="!ssid_choice_without_qoute!" interface="!interfacename!" >NUL) & goto :eof
for /f "tokens=*" %%i in ('type "%tmp%\wifi_sign_profile_name.txt"') do ( choice /m "profile:%%i %tab% :would u like to connect to this?" /c ynq
if !errorlevel! == 3  goto start
if !errorlevel! == 1 netsh wlan connect name="%%i" ssid=!ssid_[%choice%]! interface="!interfacename!" >NUL & call :checkerrorlevelwlanprofile )
goto after_call_hidden_ssid
:checkerrorlevelwlanprofile
if %errorlevel%==0 (echo: & call :colors black cyan "Done") else (echo: RAN ERROR & goto :nekst)
exit /b
:after_call_hidden_ssid
echo:
set disconnect_times=0
:END
set /a all_ears=0
set old_state=
for /f "tokens=1,* delims=:" %%i in ('netsh wlan show interfaces ^| findstr /ir "Name *[:] State *[:]"') do (
for /f "tokens=1 delims= " %%b in ("%%i") do if /i "%%b"=="name" for /f "tokens=* delims= " %%a in ("%%j") do set all_ears=9&if "%%a"=="!interfacename!" set all_ears=1
if !all_ears!==1 for /f "tokens=1 delims= " %%b in ("%%i") do if /i "%%b"=="state" for /f "tokens=* delims= " %%a in ("%%j") do echo interface state is %%a..&(if /i "%%a" == "connected" call :colors black green "connected." & goto :nekst)
set /a disconnect_times+=1
set old_state=%%j
if "!old_state!" NEQ "%%j" set /a disconnect_times=0
if !disconnect_times! GTR 15 echo do you want to retry?
if !disconnect_times! GTR 15 choice /c yncd /d c /t 1 /m "(C)ontinue (D)elet Profile?"
if !disconnect_times! GTR 15 (set disconnect_times=0&(if !errorlevel!==1 goto :start)&(if !errorlevel!==2 call :disconnect & goto :nekst)&(if !errorlevel!==4 goto :delete_profile))
)
REM goto repeat_all_ears near the :END
goto :END
:nekst
echo Waiting to detect ip address. press key to skip & timeout 3 >NUL
set found_ip_address=0
for /f "tokens=2 delims=:" %%i in ('netsh interface ipv4 show addresses "!interfacename!" ^| find /i "ip address" ^| findstr /r "[0-9]*[.][0-9]*[.][0-9]*[.][0-9]*"') do for /f "tokens=* delims= " %%a in ("%%i") do set found_ip_address=%%i
echo:
if "%found_ip_address%"=="0" call :colors black red "No I.P. address is Set" 
if "%found_ip_address%"=="0" echo: on interface "!interfacename!"
echo:
set pingable-gateway=
for /f "tokens=2 delims=:" %%i in ('netsh interface ip show config "!interfacename!" ^| find /i "Default Gateway"') do set pingable-gateway=%%i
if "%pingable-gateway%"=="" (echo NO GATEWAY FOUND:) else (echo pinging GATEWAY....&ping -n 1 %pingable-gateway%  -S %found_ip_address%  | find /i "ttl")
echo:------------------
echo pinging GOOGLE
set pinged_google=0
ping -n 1 8.8.8.8 -S %found_ip_address% | find /i "ttl"&&(set pinged_google=1&call :colors black magenta "^>       Hip Hip Hurray        "& PAUSE >NUL) || (call :colors white blue "Nope Nop It's time to be a Purple head again ^!"&PAUSE >NUL &goto :start)
timeout 20 >NUL
goto :start
:colors

Set Black1=[40m

Set Red1=[41m

Set Green1=[42m
Set Yellow1=[43m

Set Blue1=[44m

Set Magenta1=[45m
Set white1=[107m
Set Cyan1=[46m

Set Black=[30m
Set Red=[31m
Set Green=[32m
Set Blue=[34m
Set Yellow=[33m
Set Magenta=[35m
Set Cyan=[36m
Set white=[37m

for /f "delims=" %%i in (%3) do echo|set/p=!%~11!!%~2!%%~i[0m
REM powershell -c "write-host -nonewline -backgroundcolor %first% -foregroundcolor %second% \"%~3\""
goto :eof
:pick_interface
set counters=0
    for /f "tokens=2* delims=:" %%a in ('netsh wlan show interfaces ^|  findstr "Name.*[:]"') do set /a counters+=1 & set "ifacename[!counters!]=%%a"
    if !counters! LEQ 1 for /f %%i in ("%counters%") do set interfacename=!ifacename[%%i]!
    if !counters! GTR 1 (
    set choices=
    echo Select an interface
    for /l %%i in (1,1,!counters!) do echo %%i^) !ifacename[%%i]! & set choices=!choices!%%i
    choice /c !choices!
    for /f "delims=" %%i in ("!errorlevel!") do set interfacename=!ifacename[%%i]!
    )
    for /f "tokens=* delims= " %%a in ("!interfacename!") do set "interfacename=%%a"
exit /b
    :picknext
cls
echo interface ^<!interfacename!^>%tab%%tab%%tab%%tab%^( Scanning is%tab%%tab%%title_append%& echo:%tab%%tab%%tab%%tab%%tab%throttled by Windows API^)&(echo|set/p=%tab%IP: [%found_ip_address%], & if %pinged_google%==1 echo Able to ping to google)
    call :colors  black yellow "scanning interfaces on this computer..."
    echo:
    echo:
    if "!interfacename!" NEQ "" (for /f "delims=" %%i in ("!interfacename!") do echo Found:^<%%i^>.) else (echo: & echo:***No Wireless interface found^!*** & echo: &  PAUSE & GOTO :eof)
    call :colors black cyan "Pick a network"
    echo:

goto :eof

:no_profile_exists
echo No Profile Exists for this ssid.
echo|set/p=Would u like to create it?
choice /m "(c)reate profile, use (e)xisting profiles" /c ceq
if %errorlevel%==3 goto start
if %errorlevel%==2 goto connect_all_profiles
:create_wlan_profile
:enter_hidden_ssid
set ssid_is_hidden=0
if "!ssid_choice_without_qoute!"=="" set /a ssid_is_hidden=1&set /p hidden_ssid=Please enter the hidden network's SSID:
if !ssid_is_hidden!==1 if "!hidden_ssid!"=="" goto :enter_hidden_ssid
if "!ssid_choice_without_qoute!"=="" (set "default_pfname=!hidden_ssid!"&set "ssid_choice_without_qoute=!hidden_ssid!") else (set "default_pfname=!ssid_choice_without_qoute!")
:profile_nameing_unique_loop
set /a counter=1
for /f "tokens=1,2,3,4,*" %%a in ('netsh wlan show profiles interface="!interfacename!" ^| findstr /rc:"^[ ]" ^| find /i "all user profile"') do ( 
if "%%e"=="!default_pfname!" (
   set "default_pfname=!default_pfname! !counter!"
   goto :profile_nameing_unique_loop
)
)
set authentication=
set encryption=
for /l %%i in (1,1,%total_found_networks%) do (
if !ssid_[%%i]!=="!ssid_choice_without_qoute!" (
set authentication=!auth_[%%i]!
set encryption=!encrypt_[%%i]!
)
)

set auth_methods=open wpa2-personal wpa-personal wpa3-personal
set auth_value=open WPA2PSK WPAPSK WPA3
set encrypt_value=TKIP AES WEP WEP WEP NONE
set encrypt_methods=tkip ccmp wep-40bit wep wep-104bit none

set authfound=0
set val=0
for %%a in (%auth_methods%) do set /a authfound+=1&if /i "%%a"=="!authentication!" set val=!authfound!&set authfound=0&goto skipmode1
:skipmode1
set counter=0
for %%a in (%auth_value%) do set /a counter+=1& if !counter!==!val! set authentication_write=%%a
if !authfound! NEQ 0 echo:No authentication found&call :no_auth

set encryptfound=0
set val=0
for %%a in (%encrypt_methods%) do set /a encryptfound+=1&if /i "%%a"=="!encryption!" set val=!encryptfound!&set encryptfound=0&goto skipmode2
:skipmode2
set counter=0
for %%a in (%encrypt_value%) do set /a counter+=1&if !counter!==!val! set encryption_write=%%a
if !encryptfound! NEQ 0 echo:No encryption found&call :no_encrypt

echo|set/p=xxxx|choice /c 0 /d 0 /t 2 1>NUL 2>NUL
choice /c AM /m "Choose mode:Auto|Manual:" /d M /t 10
if %errorlevel%==2 (set mode=manual) else (set mode=auto)
echo:Chosen !mode!

echo:disclaimer:In built input method isn't completely SECURE
echo:Would u enter password now?   You can enter password using GUI
choice /m "Press N to Skip"
type nul >details_wifi_export_00223912.txt

for /f "delims=" %%I in ("!default_pfname!") do (echo:%%I)>>details_wifi_export_00223912.txt
for /f "delims=" %%I in ("!ssid_choice_without_qoute!") do (echo:%%I)>>details_wifi_export_00223912.txt
(echo:!authentication_write!)>>details_wifi_export_00223912.txt
(echo:!encryption_write!)>>details_wifi_export_00223912.txt
(echo:!mode!)>>details_wifi_export_00223912.txt
if %ssid_is_hidden%==1 (echo:^<nonBroadcast^>true^</nonBroadcast^>)>>details_wifi_export_00223912.txt
echo:Created Base file for use with Powershell. Press key
pause >NUL
if "!authentication_write!"=="WPA2PSK" goto wpa2-powershell
powershell -c "$filePath = \"details_wifi_export_00223912.txt\";$profile_name = Get-Content -Path $filePath | Select-Object -First 1;$ssid = Get-Content -Path $filePath | Select-Object -Skip 1 | Select-Object -First 1;$authentication = Get-Content -Path $filePath | Select-Object -Skip 2 | Select-Object -First 1;$encryption = Get-Content -Path $filePath | Select-Object -Skip 3 | Select-Object -First 1;$connectionMode = Get-Content -Path $filePath | Select-Object -Skip 4 | Select-Object -First 1;$broadcastType = Get-Content -Path $filePath | Select-Object -Skip 5 | Select-Object -First 1;$passphrase = Read-Host -Prompt \"Enter the Wi-Fi passphrase\" -AsSecureString;$fileName=[System.IO.Path]::GetRandomFileName().Substring(0, 10);$xmlFilePath = \"%tmp%\$fileName.xml\";$plainPassphrase = [System.Net.NetworkCredential]::new(\"\", $passphrase).Password;$xmlContent = \"^<WLANProfile xmlns=`\"http://www.microsoft.com/networking/WLAN/profile/v1"`\"><name>$profile_name</name><SSIDConfig><SSID><name>$ssid</name></SSID>$broadcastType</SSIDConfig><connectionType>ESS</connectionType><connectionMode>$connectionMode</connectionMode><MSM><security><authEncryption><authentication>$authentication</authentication><encryption>$encryption</encryption><useOneX>false</useOneX></authEncryption><sharedKey><keyType>passPhrase</keyType><protected>false</protected><keyMaterial>$plainPassphrase</keyMaterial></sharedKey></security></MSM></WLANProfile>\";$xmlContent ^| Out-File -FilePath $xmlFilePath -Encoding UTF8;write-host $xmlFilePath;netsh wlan add profile filename=\"$xmlFilePath\";if ($LASTEXITCODE -eq 0) { write-host \"profile export success.\" } else { write-host \"error during export.\" };Remove-Item -Path $xmlFilePath;write-host -foregroundcolor Green \"profile done.\""
del details_wifi_export_00223912.txt
echo:Connecting with Wi-fi
netsh wlan connect name="!default_pfname!" ssid="!ssid_choice_without_qoute!" interface="!interfacename!"
if %errorlevel%==0 (echo Success) else (echo Error connecting)
timeout 10 >NUL
goto :eof
:wpa2-powershell
powershell -c "$filePath = \"details_wifi_export_00223912.txt\";$profile_name = Get-Content -Path $filePath | Select-Object -First 1;$ssid = Get-Content -Path $filePath | Select-Object -Skip 1 | Select-Object -First 1;$authentication = Get-Content -Path $filePath | Select-Object -Skip 2 | Select-Object -First 1;$encryption = Get-Content -Path $filePath | Select-Object -Skip 3 | Select-Object -First 1;$connectionMode = Get-Content -Path $filePath | Select-Object -Skip 4 | Select-Object -First 1;$broadcastType = Get-Content -Path $filePath | Select-Object -Skip 5 | Select-Object -First 1;$passphrase = Read-Host -Prompt \"Enter the Wi-Fi passphrase\" -AsSecureString;$fileName=[System.IO.Path]::GetRandomFileName().Substring(0, 10);$xmlFilePath = \"%tmp%\$fileName.xml\";$plainPassphrase = [System.Net.NetworkCredential]::new(\"\", $passphrase).Password;$xmlContent = \"^<WLANProfile xmlns=`\"http://www.microsoft.com/networking/WLAN/profile/v1"`\"><name>$profile_name</name><SSIDConfig><SSID><name>$ssid</name></SSID>$broadcastType</SSIDConfig><connectionType>ESS</connectionType><connectionMode>$connectionMode</connectionMode><MSM><security><authEncryption><authentication>$authentication</authentication><encryption>$encryption</encryption><useOneX>false</useOneX></authEncryption><sharedKey><keyType>passPhrase</keyType><protected>false</protected><keyMaterial>$plainPassphrase</keyMaterial></sharedKey><PMKCacheMode>enabled</PMKCacheMode><PMKCacheTTL>240</PMKCacheTTL><PMKCacheSize>20</PMKCacheSize></security></MSM></WLANProfile>\";$xmlContent ^| Out-File -FilePath $xmlFilePath -Encoding UTF8;write-host $xmlFilePath;netsh wlan add profile filename=\"$xmlFilePath\";if ($LASTEXITCODE -eq 0) { write-host \"profile export success.\" } else { write-host \"error during export.\" };Remove-Item -Path $xmlFilePath;write-host -foregroundcolor Green \"profile done.\""
del details_wifi_export_00223912.txt
echo:Connecting with Wi-fi
netsh wlan connect name="!default_pfname!" ssid="!ssid_choice_without_qoute!" interface="!interfacename!"
if %errorlevel%==0 (echo Success) else (echo Error connecting)
timeout 10 >NUL
goto :eof



echo|set/p=Creating profile.
echo:^<?xml version="1.0"?^>^<^!--- Support: https://github.com/invalidusernamecalled/connect_wifi_terminal >>>Profile_scheme.xml
echo:^<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"^>>>Profile_scheme.xml
echo:^<name^>!default_pfname!^</name^>>>Profile_scheme.xml
echo:^<SSIDConfig^>>>Profile_scheme.xml
echo:^<SSID^>>>Profile_scheme.xml
for /f "delims=" %%I in ("!ssid_choice_without_qoute!") do echo:^<name^>%%I^</name^>>>Profile_scheme.xml
echo:^</SSID^>>>Profile_scheme.xml
echo:^</SSIDConfig^>>>Profile_scheme.xml
echo:^<connectionType^>ESS^</connectionType^>>>Profile_scheme.xml
echo:^<connectionMode^>manual^</connectionMode^>>>Profile_scheme.xml
REM echo:^<autoSwitch^>false^</autoSwitch^>>>Profile_scheme.xml
echo|set/p=.
echo:^<MSM^>>>Profile_scheme.xml
echo:^<security^>>>Profile_scheme.xml
echo:^<authEncryption^>>>Profile_scheme.xml
echo:^<authentication^>!authentication_write!^</authentication^>>>Profile_scheme.xml
echo:^<encryption^>!encryption_write!^</encryption^>>>Profile_scheme.xml
echo:^<useOneX^>false^</useOneX^>>>Profile_scheme.xml
echo:^</authEncryption^>>>Profile_scheme.xml
echo:^</security^>>>Profile_scheme.xml
echo:^</MSM^>>>Profile_scheme.xml
echo:^</WLANProfile^>>>Profile_scheme.xml
echo|set/p=.
echo:Adding profile..
echo:netsh wlan add profile filename=profile_Scheme.XML interface="!interfacename!" >NUL
netsh wlan add profile filename=profile_Scheme.XML interface="!interfacename!" >NUL
if %ERRORLEVEL% NEQ 0 echo:RAN ERROR [%errorlevel%]
if %ERRORLEVEL% == 0 echo:DONE


:no_auth
echo 1.open 
echo 2.WPA2PSK
echo 3.WPAPSK 
echo 4.WPA3
echo:
choice /c 1234 /m "Choose [1-4]:"
set zchoice=%errorlevel%
if %zchoice%==1 set authentication_write=open
if %zchoice%==2 set authentication_write=WPA2PSK
if %zchoice%==3 set authentication_write=WPAPSK
if %zchoice%==4 set authentication_write=WPA3
goto :eof
:no_encrypt
echo 1.TKIP 
echo 2.AES
echo 3.WEP 
echo 4.none
echo:
choice /c 1234 /m "Choose [1-4]:"
set zchoice=%errorlevel%
if %zchoice%==1 set encryption_write=TKIP
if %zchoice%==2 set encryption_write=AES
if %zchoice%==3 set encryption_write=WEP
if %zchoice%==4 set encryption_write=none
goto :eof
:disconnect
netsh wlan disconnect interface="!interfacename!"&&(Echo Successfully disconnected!&PAUSE >NUL)
if %errorlevel% NEQ 0 echo RAN ERROR DISCONNECTNG[%errorlevel%]&PAUSE >NUL
goto :eof
:delete_profile
choice /m "Sure?"
if %errorlevel%==2 goto :start
echo:deleting in 2 seconds & timeout 2 >NUL
for /f "tokens=*" %%i in ('type "%tmp%\wifi_sign_profile_name.txt"') do netsh wlan delete profile name="%%i" interface="!interfacename!"
goto :eof
:display_ssid_is_hidden
set whatis_SSID=
call :colors black cyan "Wi-fi SSID is empty."
echo |set /p=: Would u like to enter it?
choice
if %errorlevel%==2 goto hidden_ssid
set /p whatis_SSID=
exit /b
:hidden_ssid
echo |set /p=Do you want to attempt to connect using existing profile or create a new?
choice /m "(C)reate Profile / (e)xisting Profile" /c ceq
if %errorlevel%==3 goto start
if %errorlevel%==1 goto :no_profile_exists
:connect_all_profiles
echo:GETTING ALL PROFILE FILES...
powershell -c "$directoryPath = \"%guid_dir%\";$xmlFiles = Get-ChildItem -Path $directoryPath -Filter \"*.xml\";foreach ($xmlFile in $xmlFiles) {  [xml]$xmlContent = Get-Content $xmlFile.FullName;$profileName = $xmlContent.WLANProfile.name;  write-host $profileName };">"%tmp%\wifi_sign_profile_name.txt"
set /a profile_counter=1
:here222
echo off & for /f "tokens=*" %%i in ('type "%tmp%\wifi_sign_profile_name.txt"') do echo:[!profile_counter!] %%i & CALL set "all-profiles[!profile_counter!]=%%i" & set /a profile_counter+=1
set /p choose-the-profile=Enter profile no.:
CALL set "chosen_profile=%%all-profiles[!choose-the-profile!]%%"
if "!chosen_profile!"=="" echo Invalid Profile Choice & timeout 2 >NUL  & goto start
choice /m "profile:!chosen_profile!%tab% :would u like to connect to this?"
if !errorlevel! == 1 netsh wlan connect name="!chosen_profile!" interface="!interfacename!" >NUL
goto :start
:re-connect
for /f "tokens=1,2,* delims=:" %%A in ('netsh wlan show interfaces ^| findstr /C:"SSID" ^| findstr /v "BSSID"') do set "CURRENT_WIFI=%%B"

:: Trim leading/trailing spaces
for /f "tokens=* delims= " %%A in ("%CURRENT_WIFI%") do set CURRENT_WIFI=%%A
)

:: Check if a network name was found
if "%CURRENT_WIFI%"=="" (
    echo No Wi-Fi network is currently connected.
    pause
    goto :eof
) else (
echo YOU WERE PREVIOUSLY CONNECTED: "%CURRENT_WIFI%" bye bye.. disconnecting
timeout 1 >NUL
)
echo:
COLOR 74
netsh wlan disconnect interface="!interfacename!"
timeout /t 5 > nul
echo:
COLOR 03
echo:RECONNECTING...
echo on
netsh wlan connect name="%CURRENT_WIFI%" interface="!interfacename!"
@echo off
if %errorlevel%==0 echo: & echo Done!
echo:
timeout 5
goto :eof