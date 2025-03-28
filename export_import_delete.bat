:: what is it god dammit ?
choice /c 123 /m "1.export 2.delete 3.add"
if %errorlevel%==1 goto export
if %errorlevel%==2 goto delete
if %errorlevel%==3 goto add
:export
set /p "whatit_reallyis=Enter the Wi-Fi Profile name "
netsh wlan export profile name="%whatit_reallyis%"
goto :eof
:import
set /p "whatit_reallyis=Enter the file name "
netsh wlan add profile name="%whatit_reallyis%"
goto :eof
:delete
set /p "whatit_reallyis=Enter the Wi-Fi Profile name "
netsh wlan delete profile name="%whatit_reallyis%"
goto :eof