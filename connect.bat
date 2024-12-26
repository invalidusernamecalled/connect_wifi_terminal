@echo off 
setlocal enabledelayedexpansion

:start
call :display_first_line

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

    

    :print_info
    set skip=0
    set /a displaycurtain=networks
    :repat
    set /a displaycurtain=displaycurtain-9
    set /a escape=0 
    if !displaycurtain! LEQ 0 set escape=1
    set counter=0
    if !skip!==0 for /f "tokens=1,2 delims=," %%i in ('type wifi_sign.txt ^| sort /R ') do set /a counter+=1 & (if !counter! GTR 9 goto :next) &  echo !counter!) %%~j, %%i & set ssid_[!counter!]="%%~j"&set signal_strength_[!counter!]=%%i
    if !skip! GTR 0 for /f "skip=%skip% tokens=1,2 delims=," %%i in ('type wifi_sign.txt ^| sort /R') do set /a counter+=1 & (if !counter! GTR 9 goto :next) & echo !counter!) %%~j, %%i & set ssid_[!counter!]="%%~j"&set signal_strength_[!counter!]=%%i
    :next
    set /a skip=skip+9
    call :colors black red "x) Disconnect"
    choice /c 123456789YXR /n /m "1-9:      Press y/Y for (more)  (R)efresh ::X for disconnect"
    set choice=%errorlevel%
    if !choice!==10 if !escape!==0 (call :display_first_line & goto repat) else (set /a skip=0 & call :display_first_line & goto repat)
    echo:
    if %choice%==11 netsh wlan disconnect & goto :eof
    if %choice%==12 echo refreshing ..&timeout 2 >NUL& start cmd /c "call %~fp0" & goto :eof
for /f "tokens=*" %%i in (!ssid_[%choice%]!) do set ssid_[%choice%]=%%i
echo you chose !ssid_[%choice%]!
echo:
call :colors black green "CONNECTING..."
echo:
echo netsh wlan connect name=!ssid_[%choice%]! interface="!interfacename!"
netsh wlan connect name=!ssid_[%choice%]! interface="!interfacename!
if %errorlevel%==0 (echo: & call :colors black cyan "Done!") else (echo: RAN ERROR & goto :nekst)
echo:
:END
set /a all_ears=0
for /f "tokens=1,* delims=:" %%i in ('netsh wlan show interfaces ^| findstr /r "Name.*[:] State.*[:]"') do (
if !all_ears!==1 set interfacestate=%%j&set all_ears=0&for /f "tokens=* delims= " %%a in ("%%j") do echo interface state is %%a..
for /f "tokens=* delims= " %%a in ("%%j") do if "%%a"=="!interfacename!" set /a all_ears+=1
)
for /f "tokens=* delims= " %%i in ("!interfacestate!") do if /i "%%i"=="connected" echo:&echo:&goto nekst
REM goto repeat_all_ears near the :END
goto :END
:nekst
set pingable-gateway=
for /f "tokens=2 delims=:" %%i in ('netsh interface ip show config "!interfacename!" ^| find /i "Default Gateway"') do set pingable-gateway=%%i
if "%pingable-gateway%"=="" (echo NO GATEWAY FOUND:) else (echo pinging GATEWAY....&ping %pingable-gateway% | find /i "ttl")
echo:------------------
echo pinging GOOGLE
ping 8.8.8.8 | find /i "ttl"&&call :colors black magenta ">       Hip Hip Hurray        <"
timeout 20 >NUL
goto :eof
:colors

Set Black1=[40m

Set Red1=[41m

Set Green1=[42m
Set Yellow1=[43m

Set Blue1=[44m

Set Magenta1=[45m

Set Cyan1=[46m

Set Black=[30m
Set Red=[31m
Set Green=[32m
Set Blue=[34m
Set Yellow=[33m
Set Magenta=[35m
Set Cyan=[36m

for /f "delims=" %%i in (%3) do echo !%~11!!%~2!%%~i[0m
REM powershell -c "write-host -nonewline -backgroundcolor %first% -foregroundcolor %second% \"%~3\""
goto :eof
:display_first_line
cls
    echo.
    if defined interfacename echo interface ^<!interfacename!^> & echo: & goto picknext
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
    echo:
    call :colors black cyan "Pick a network"
    echo:

