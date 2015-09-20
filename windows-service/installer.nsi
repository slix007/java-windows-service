; The name of the installer
Name "Windows Service Server"

!define PRODUCT_NAME "Windows Service Server"
;Without spaces
!define SERVICE_NAME "MyServer" 

#!define WIN win32
!define WIN win64

; The file to write
OutFile "installer-${WIN}.exe"

; The default installation directory
InstallDir "$PROGRAMFILES\${PRODUCT_NAME}"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

;-------------------------------- Java Runtime Download Script --------------------------------
; Definitions for Java 1.8 Detection
!define JRE_VERSION "1.8"
!define JRE_URL "http://javadl.sun.com/webapps/download/AutoDL?BundleId=95501"

Function GetJRE
        MessageBox MB_OK "${PRODUCT_NAME} uses Java ${JRE_VERSION}, it will now \
                         be downloaded and installed"

        StrCpy $2 "$TEMP\Java Runtime Environment.exe"
        nsisdl::download /TIMEOUT=30000 ${JRE_URL} $2
        Pop $R0 ;Get the return value
                StrCmp $R0 "success" +3
                MessageBox MB_OK "Download failed: $R0"
                Quit
        ExecWait $2
        Delete $2
        SetRebootFlag true
FunctionEnd
;------------------------------------------------------------------------------------------------
Function DetectJRE
  ReadRegStr $2 HKLM "SOFTWARE\JavaSoft\Java Runtime Environment" \
             "CurrentVersion"
  StrCmp $2 ${JRE_VERSION} done

  Call GetJRE

  done:
FunctionEnd
;------------------------------------------------------------------------------------------------
Function CheckIsAdmin
         # call UserInfo plugin to get user info.  The plugin puts the result in the stack
         UserInfo::getAccountType

         # pop the result from the stack into $0
         Pop $0

         # compare the result with the string "Admin" to see if the user is admin.
         # If match, go to done
         StrCmp $0 "Admin" done

         # if there is not a match, print message and return
         MessageBox MB_OK "User is not admin: $0. You should have the admin rights."
         Quit
         Return

         done:
         # otherwise, confirm and return
         # MessageBox MB_OK "is admin"
FunctionEnd
;------------------------------------------------------------------------------------------------

;-------------------------------- PAGES ---------------------------------------------------------
; installer properties
XPStyle on

!include Sections.nsh
!include MUI2.nsh
!define MUI_HEADERIMAGE
!define MUI_PAGE_CUSTOMFUNCTION_SHOW MyWelcomeShowCallback
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_LANGUAGE "English"
Function MyWelcomeShowCallback
SendMessage $mui.WelcomePage.Text ${WM_SETTEXT} 0 "STR:$(MUI_TEXT_WELCOME_INFO_TEXT)$\n$\nVersion: 2.1"
FunctionEnd

!define MUI_PAGE_HEADER_TEXT "Installation folder location."
!define MUI_PAGE_HEADER_SUBTEXT ""
!insertmacro MUI_PAGE_DIRECTORY

Page instfiles


;-----------------------------------------------------------------------------------------------

!define LINK_INSTALL "$SMPROGRAMS\${PRODUCT_NAME}\Install PosPlus service.lnk"
!define LINK_UNINSTALL "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall PosPlus service.lnk"
!define LINK_START "$SMPROGRAMS\${PRODUCT_NAME}\Start PosPlus service.lnk"
!define LINK_STOP "$SMPROGRAMS\${PRODUCT_NAME}\Stop PosPlus service.lnk"

Section "Install server(required)"
        SectionIn RO

        ; Has user the admin rights or not?
        Call CheckIsAdmin
        
        ; Check JRE.
        Call DetectJRE
        
        ; Set output path to the installation directory.
        SetOutPath $INSTDIR
        
        # Copy files to the installation directory.
        File /oname=$INSTDIR\nssm.exe "${WIN}\nssm.exe"
        
        File installService.cmd
        File /r "server"
       

        # define uninstaller name
        WriteUninstaller $INSTDIR\uninstaller.exe


        # ------------------------------------- Create links -----------------------------------
        # Create directory
        CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}";
        
        # Create link to uninstaller
        CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall PosPlus Software.lnk" "$INSTDIR\uninstaller.exe"
        ShellLink::SetRunAsAdministrator "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall PosPlus Software.lnk"
        
        # Create installService.bat file
        FileOpen $0 "$INSTDIR\installService.bat" w
        FileWrite $0 ' "$INSTDIR\installService.cmd" "${SERVICE_NAME}" "$INSTDIR\server" '
        FileClose $0
        Pop $0

        CreateShortCut "${LINK_INSTALL}" "$INSTDIR\installService.bat" ""
        CreateShortCut '${LINK_UNINSTALL}' '$INSTDIR\nssm' 'remove ${SERVICE_NAME}'
        CreateShortCut '${LINK_START}' '$INSTDIR\nssm' 'start ${SERVICE_NAME}'
        CreateShortCut '${LINK_STOP}' '$INSTDIR\nssm' 'stop ${SERVICE_NAME}'
        ShellLink::SetRunAsAdministrator "${LINK_INSTALL}"
        ShellLink::SetRunAsAdministrator "${LINK_UNINSTALL}"
        ShellLink::SetRunAsAdministrator "${LINK_START}"
        ShellLink::SetRunAsAdministrator "${LINK_STOP}"
        

        # ------------------TODO Add uninstall information to Add/Remove Programs ------------------
        ;WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${SERVICE_NAME}" \
         ;                "DisplayName" "${PRODUCT_NAME}"
        ;WriteRegStr HKLM "SOFTWARE\${PRODUCT_NAME}" 'DisplayName' '${PRODUCT_NAME}'
        ;WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${SERVICE_NAME}" \
        ;                 "UninstallString" "$INSTDIR\uninstall.exe"

        # --------------------- "Create windows service" ---------------------
        SetOutPath $INSTDIR
                   nsExec::ExecToStack "$INSTDIR\installService.bat"
                   nsExec::ExecToStack '$INSTDIR\nssm start ${SERVICE_NAME}'
                   
        
        # --------------------- Reboot if JRE was installed  ---------------------

        IfRebootFlag 0 +3
        MessageBox MB_YESNO|MB_ICONQUESTION "Windows should be restarted.$\rDo you wish to reboot the system now?" IDNO +2
                   Reboot



        GetDlGItem $0 $HWNDPARENT 3

        EnableWindow $0 0

SectionEnd ; end the section
;--------------------------------------------------------

; Uninstaller
Section "Uninstall"

        # Remove windows service
        SetOutPath $INSTDIR
        nsExec::ExecToStack '$INSTDIR\nssm stop ${SERVICE_NAME}'
        nsExec::ExecToStack '$INSTDIR\nssm remove ${SERVICE_NAME} confirm'

        # Always delete uninstaller first
        Delete $INSTDIR\uninstaller.exe

        # Clean windows registry
        DeleteRegKey HKLM "SOFTWARE\${PRODUCT_NAME}"

        # now delete installed files
        RmDir /r $INSTDIR\server
        RmDir /r $INSTDIR\terminal-client
        RmDir /r "$SMPROGRAMS\${PRODUCT_NAME}"

        # now delete installed directory
        RmDir /r $INSTDIR

SectionEnd
