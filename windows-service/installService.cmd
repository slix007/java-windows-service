cd "%2\..\"

nssm.exe install %1 java.exe
nssm.exe set %1 Application java.exe
nssm.exe set %1 AppDirectory %2
nssm.exe set %1 AppParameters -jar server.jar

nssm.exe set %1 DisplayName %1
nssm.exe set %1 Description PosPlus Proxy Server. Redirects TCP calls to a serial port.
nssm.exe set %1 Start SERVICE_AUTO_START
rem nssm.exe set %1 AppStdout %2\service.log
rem nssm.exe set %1 AppStderr %2\service.log
