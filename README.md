# java-windows-service
This is an example how to use java standalone bootstrap server as windows service.

You can use it if you have a java server that starts like "java -jar server.jar" and you wants to install it to Windows machines like a service that starts on system startup.

As a result you will have two windows executable files for x32 and x64 platforms that have UI to install your application.

This project use spring-boot hello world project as a bootstrap server.
[NSSM](https://nssm.cc/) is used for creation of windows service. The nssm.exe files are already included into this repository.
[Nsis] (http://nsis.sourceforge.net/Main_Page) is used for installer itself. You need to download and install Nsis to build an executable installer.

To build java server use __gradle build__.
To build windows installser use __gradle buildInstallers__.
