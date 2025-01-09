@echo off 
setlocal enabledelayedexpansion
set networks=0
for /f "tokens=1,2 delims=:" %%i in ('netsh wlan show interfaces ^| findstr /iR "Name GUID"') do (
set temp_name=%%i
set temp_name=!temp_name: =!
echo !temp_name!z
if /i "!temp_name!"=="Name" set /a networks+=1&for /f "tokens=* delims= " %%s in ("%%j") do set name_[!networks!]=%%s
set guid_[!networks!]=
if /i "!temp_name!"=="GUID" for /f "tokens=* delims= " %%d in ("%%j") do set guid_[!networks!]=%%d
)

:start
call :display_first_line

echo:Total network interfaces found:%networks%
for /l %%a in (1,1,!networks!) do if "!name_[%%a]!"=="!interfacename!" set real_guid=!guid_[%%a]!

    set networks=0
    for /f "tokens=1,2,3,*" %%a in ('netsh wlan show networks mode^=bssid interface^="!interfacename!" ') do (

        if "%%a"=="SSID" (
            set /a networks=networks+1
            set ssid_[!networks!]=%%d
        )

        if "%%a"=="Signal" (
            set temp=00%%c
            set signal_strength_[!networks!]=!temp:~-4!
        )

    )
    type nul >wifi_sign.txt
    for /l %%a in ( 1, 1, !networks! ) do (

        if "!ssid_[%%a]!" == "" ( 
            echo !signal_strength_[%%a]!%, "<hidden>" >>wifi_sign.txt
        ) else (
            echo !signal_strength_[%%a]!, "!ssid_[%%a]!" >>wifi_sign.txt
        )

    )
    set list_empty=1
    for /f "delims=" %%i in ('type wifi_sign.txt') do set /a list_empty=0
    if %list_empty%==1 echo (list empty)
    if %list_empty%==1 (set choice_list=) else (set choice_list=123456789)
    :print_info
    set skip=0
    set /a displaycurtain=networks
    :repat
    set /a displaycurtain=displaycurtain-9
    set /a escape=0 
    if !displaycurtain! LEQ 0 set escape=1
    set counter=0
    if !skip!==0 for /f "tokens=1,2 delims=," %%i in ('type wifi_sign.txt ^| sort /R ') do set /a counter+=1 & (if !counter! GTR 9 goto :next) &  echo !counter!) %%~j, %%i & set "ssid_[!counter!]=%%~j"&set signal_strength_[!counter!]=%%i
    if !skip! GTR 0 for /f "skip=%skip% tokens=1,2 delims=," %%i in ('type wifi_sign.txt ^| sort /R') do set /a counter+=1 & (if !counter! GTR 9 goto :next) & echo !counter!) %%~j, %%i & set "ssid_[!counter!]=%%~j"&set signal_strength_[!counter!]=%%i
    :next
    set /a skip=skip+9
    call :colors black red "x) Disconnect"
    if %list_empty%==0 echo Select 1-9   
    choice /c %choice_list%YXR /n /m "Or  Press Y for (next page),(R) for refresh"    
    set choice=%errorlevel%
    if %list_empty%==1 if %choice%==2 netsh wlan disconnect interface="!interfacename!" &  goto :start
    if %list_empty%==1 if %choice%==3 echo refreshing ..&timeout 2 >NUL& start cmd /c "call %~fp0" & goto :eof
    if %list_empty%==1 goto :start
    if !choice!==10 if !escape!==0 (call :display_first_line & goto repat) else (set /a skip=0 & call :display_first_line & goto repat)
    echo:
    if %choice%==11 netsh wlan disconnect interface="!interfacename!" & goto :eof
    if %choice%==12 echo refreshing ..&timeout 2 >NUL& start cmd /c "call %~fp0" & goto :eof
for /f "tokens=*" %%i in (!ssid_[%choice%]!) do echo:you chose %%i&set ssid_[%choice%]="%%i"&set "ssid_choice_without_qoute=%%~i"
echo:
call :colors black green "CONNECTING..."
echo:



for /f "delims=" %%i in ('dir /b "%ProgramData%\Microsoft\Wlansvc\Profiles\Interfaces\*" ^| find /i "%real_guid%"') do set guid_dir=%ProgramData%\Microsoft\Wlansvc\Profiles\Interfaces\%%i
echo Guid==%guid_dir%

echo:GETTING PROFILE FILE...
powershell -c "$directoryPath = \"%guid_dir%\";$xmlFiles = Get-ChildItem -Path $directoryPath -Filter \"*.xml\";foreach ($xmlFile in $xmlFiles) {  [xml]$xmlContent = Get-Content $xmlFile.FullName;$ssidName = $xmlContent.WLANProfile.SSIDConfig.SSID.name; $profileName = $xmlContent.WLANProfile.name; if ($ssidName -eq \"!ssid_choice_without_qoute!\") { Write-Host \"$profileName\" } };">wifi_sign_profile_name.txt


set profile_exist=0
for /f "tokens=*" %%i in (wifi_sign_profile_name.txt) do set profile_exist=1
if !profile_exist! == 0 echo No Profile Exists for this interface.& echo: & pause >NUL & goto start

for /f "tokens=*" %%i in (wifi_sign_profile_name.txt) do echo netsh wlan connect name=%%i ssid=!ssid_[%choice%]! interface="!interfacename!" & netsh wlan connect name=%%i ssid=!ssid_[%choice%]! interface="!interfacename!" >NUL





if %errorlevel% NEQ 0 (for /l %%i in (0,1,5) do echo:) & echo:netsh wlan connect name=!ssid_[%choice%]! interface="!interfacename!" & echo:RAN ERROR [code:%errorlevel%] & if "!ssid_[%choice%]!"=="" call :colors blacks cyan "Invalid empty Wi-fi name selected" & pause >NUL & goto :start
if %errorlevel%==0 (echo: & call :colors black cyan "Done!") else (echo: RAN ERROR & goto :nekst)
echo:
set disconnect_times=0
:END
set /a all_ears=0
for /f "tokens=1,* delims=:" %%i in ('netsh wlan show interfaces ^| findstr /r "Name.*[:] State.*[:]"') do (
if !all_ears!==1 set interfacestate=%%j&set all_ears=0&for /f "tokens=* delims= " %%a in ("%%j") do echo interface state is %%a..&if /i "%%a"=="disconnected" set /a disconnect_times +=1
if %disconnect_times% GTR 12 echo do you want to retry?
if %disconnect_times% GTR 12 choice
if %disconnect_times% GTR 12 (set disconnect_times=0&if %errorlevel%==1 goto :start) 
for /f "tokens=* delims= " %%a in ("%%j") do if "%%a"=="!interfacename!" set /a all_ears+=1
)
for /f "tokens=* delims= " %%i in ("!interfacestate!") do if /i "%%i"=="connected" echo:&echo:&goto nekst
REM goto repeat_all_ears near the :END
goto :END
:nekst
set found_ip_address=0
for /f "tokens=2 delims=:" %%i in ('netsh interface ipv4 show addresses "!interfacename!" ^| find /i "ip address" ^| findstr /r "[0-9]*[.][0-9]*[.][0-9]*[.][0-9]*"') do for /f "tokens=* delims= " %%a in ("%%i") do set found_ip_address=%%i
if "%found_ip_address%"=="0" call :colors black red "No I.P. address is Set" 
if "%found_ip_address%"=="0" echo:on interface "!interfacename!"
set pingable-gateway=
for /f "tokens=2 delims=:" %%i in ('netsh interface ip show config "!interfacename!" ^| find /i "Default Gateway"') do set pingable-gateway=%%i
if "%pingable-gateway%"=="" (echo NO GATEWAY FOUND:) else (echo pinging GATEWAY....&ping %pingable-gateway%  -S %found_ip_address%  | find /i "ttl")
echo:------------------
echo pinging GOOGLE
ping -n 3 8.8.8.8 -S %found_ip_address% | find /i "ttl"&&call :colors black magenta ">       Hip Hip Hurray        <"
timeout 20 >NUL
goto :eof
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

for /f "delims=" %%i in (%3) do echo !%~11!!%~2!%%~i[0m
REM powershell -c "write-host -nonewline -backgroundcolor %first% -foregroundcolor %second% \"%~3\""
goto :eof
:display_first_line
cls
    echo.
    if defined interfacename if "!interfacename!" NEQ "" echo interface ^<!interfacename!^> & echo: & goto picknext
    call :colors  black yellow "scanning interfaces on this computer..."
    echo:
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

    
    if "!interfacename!" NEQ "" (echo Found:^<!interfacename!^>.) else (echo: & echo:***No Wireless interface found^!*** & echo: &  PAUSE & GOTO :eof)
    :picknext
    netsh wlan show networks 1>NUL 2>NUL
    if %errorlevel% NEQ 0 echo:&echo|set/p=Check Wi-Fi is Switched On. &call :colors green black "Network scanning error code: [%errorlevel%]. Try again"
    echo:
    call :colors black cyan "Pick a network"
    echo:

