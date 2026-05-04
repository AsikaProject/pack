!define PRODUCT_NAME "Asika"
!define PRODUCT_VERSION "0.0.0.0"

!include "MUI2.nsh"
!include "Sections.nsh"
!include "LogicLib.nsh"

!define MUI_ICON "asika.ico"
!define MUI_UNICON "asika.ico"
!define MUI_ABORTWARNING

; Language strings
LangString DESC_Welcome ${LANG_ENGLISH} "Welcome to the ${PRODUCT_NAME} Setup Wizard.$\r$\n$\r$\nThis wizard will guide you through the installation of ${PRODUCT_NAME}.$\r$\n$\r$\nIt is recommended that you close all other applications before continuing."
LangString DESC_Welcome ${LANG_SIMPCHINESE} "欢迎使用 ${PRODUCT_NAME} 安装向导。$\r$\n$\r$\n此向导将引导您安装 ${PRODUCT_NAME}。$\r$\n$\r$\n建议在继续之前关闭所有其他应用程序。"
LangString DESC_Welcome ${LANG_JAPANESE} "${PRODUCT_NAME} セットアップウィザードへようこそ。$\r$\n$\r$\nこのウィザードでは、${PRODUCT_NAME} のインストール手順をご案内します。$\r$\n$\r$\n続行する前に、他のアプリケーションをすべて閉じることをお勧めします。"

LangString DESC_UninstallConfirm ${LANG_ENGLISH} "Are you sure you want to uninstall ${PRODUCT_NAME}?"
LangString DESC_UninstallConfirm ${LANG_SIMPCHINESE} "您确定要卸载 ${PRODUCT_NAME} 吗？"
LangString DESC_UninstallConfirm ${LANG_JAPANESE} "${PRODUCT_NAME} をアンインストールしてもよろしいですか？"

LangString DESC_Asikad ${LANG_ENGLISH} "Asika Daemon (asikad) - Core service process (Required)"
LangString DESC_Asikad ${LANG_SIMPCHINESE} "Asika 守护进程 (asikad) - 核心服务进程（必选）"
LangString DESC_Asikad ${LANG_JAPANESE} "Asika デーモン (asikad) - コアサービスプロセス（必須）"

LangString DESC_Cli ${LANG_ENGLISH} "Asika CLI (asika) - Command-line interface tool"
LangString DESC_Cli ${LANG_SIMPCHINESE} "Asika 命令行工具 (asika) - 命令行界面工具"
LangString DESC_Cli ${LANG_JAPANESE} "Asika CLI (asika) - コマンドラインインターフェースツール"

LangString DESC_Service ${LANG_ENGLISH} "Install and start Asika as a Windows service with firewall rule"
LangString DESC_Service ${LANG_SIMPCHINESE} "将 Asika 安装为 Windows 服务并配置防火墙规则"
LangString DESC_Service ${LANG_JAPANESE} "Asika を Windows サービスとしてインストールし、ファイアウォール規則を設定"

LangString DESC_Docs ${LANG_ENGLISH} "HTML and manpage documentation for asika and asikad"
LangString DESC_Docs ${LANG_SIMPCHINESE} "asika 和 asikad 的 HTML 和 manpage 文档"
LangString DESC_Docs ${LANG_JAPANESE} "asika と asikad の HTML および manpage ドキュメント"

LangString DESC_Finish ${LANG_ENGLISH} "Completing the ${PRODUCT_NAME} Setup Wizard$\r$\n$\r$\n${PRODUCT_NAME} has been installed on your computer.$\r$\n$\r$\nClick Finish to close this wizard."
LangString DESC_Finish ${LANG_SIMPCHINESE} "${PRODUCT_NAME} 安装向导完成$\r$\n$\r$\n${PRODUCT_NAME} 已安装到您的计算机上。$\r$\n$\r$\n点击完成以关闭此向导。"
LangString DESC_Finish ${LANG_JAPANESE} "${PRODUCT_NAME} セットアップウィザードの完了$\r$\n$\r$\n${PRODUCT_NAME} がコンピューターにインストールされました。$\r$\n$\r$\n［完了］をクリックしてウィザードを閉じます。"

; Installer pages (MUST come before MUI_LANGUAGE)
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_TEXT $(DESC_Finish)
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Languages (MUST come after all page macros)
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "Japanese"

Outfile "Asika_Setup_${PRODUCT_VERSION}.exe"
InstallDir "$PROGRAMFILES\${PRODUCT_NAME}"
RequestExecutionLevel admin
SetCompressor lzma

Var ServiceInstalled

Section "!Asika Daemon (asikad)" SEC_ASIKAD
    SectionIn RO
    SetOutPath "$INSTDIR"
    File "asikad.exe"
    StrCpy $ServiceInstalled 1
SectionEnd

Section /o "Asika CLI (asika)" SEC_CLI
    SetOutPath "$INSTDIR"
    File "asika.exe"
SectionEnd

Section /o "Install as Windows Service" SEC_SERVICE
SectionEnd

Section /o "Documentation" SEC_DOCS
    SetOutPath "$INSTDIR\doc"
    File "doc\asika.html"
    File "doc\asikad.html"
    File "doc\asika.1"
    File "doc\asikad.1"
SectionEnd

; Section descriptions (must be after sections)
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_ASIKAD} $(DESC_Asikad)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CLI} $(DESC_Cli)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_SERVICE} $(DESC_Service)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_DOCS} $(DESC_Docs)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Function .onInit
    StrCpy $ServiceInstalled 0
FunctionEnd

Function .onInstSuccess
    SectionGetFlags ${SEC_SERVICE} $0
    IntOp $0 $0 & ${SF_SELECTED}
    
    ${If} $0 == ${SF_SELECTED}
        ; Set service environment variable
        WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\asikad\Environment" \
            "ASIKA_CONFIG" "$INSTDIR\asika_config.toml"
        WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\asikad\Environment" \
            "GOMEMIMIT" "256MiB"
        
        ; Remove existing service if present
        nsExec::Exec 'sc query asikad >nul 2>&1'
        Pop $0
        ${If} $0 == 0
            nsExec::Exec 'sc stop asikad'
            nsExec::Exec 'sc delete asikad'
            Sleep 2000
        ${EndIf}
        
        ; Create service
        nsExec::Exec 'sc create asikad binPath= "\"$INSTDIR\asikad.exe\"" start= auto'
        Pop $0
        ${If} $0 != 0
            MessageBox MB_ICONSTOP "Failed to create service."
            Quit
        ${EndIf}
        
        ; Set description
        nsExec::Exec 'sc description asikad "Asika PR Manager - cross-platform PR manager and merge queue service"'
        
        ; Set failure recovery
        nsExec::Exec 'sc failure asikad actions= restart/10000/restart/20000/restart/30000 reset= 3600'
        
        ; Add firewall rule
        nsExec::Exec 'netsh advfirewall firewall add rule name="Asika Daemon" dir=in action=allow program="$INSTDIR\asikad.exe" enable=yes'
        
        ; Start service
        nsExec::Exec 'sc start asikad'
    ${EndIf}
    
    ; Write uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    ; Start menu shortcuts
    CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
    CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Asika Dashboard.lnk" \
        "$SYSDIR\cmd.exe" '/k "$INSTDIR\asikad.exe" --desktop' \
        "$SYSDIR\cmd.exe" "" SW_SHOWNORMAL "" \
        "Start Asika Dashboard in foreground mode"
    CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall Asika.lnk" "$INSTDIR\uninstall.exe"
FunctionEnd

Section "Uninstall"
    ; Confirm dialog
    MessageBox MB_ICONQUESTION|MB_YESNO $(DESC_UninstallConfirm) IDYES true IDNO false
    false:
        Abort
    
    ; Check if service is running
    nsExec::Exec 'sc query asikad >nul 2>&1'
    Pop $0
    ${If} $0 == 0
        nsExec::Exec 'sc stop asikad'
        Sleep 2000
        nsExec::Exec 'sc delete asikad'
    ${EndIf}
    
    ; Delete firewall rule
    nsExec::Exec 'netsh advfirewall firewall delete rule name="Asika Daemon"'
    
    ; Clean registry
    DeleteRegKey HKLM "SYSTEM\CurrentControlSet\Services\asikad\Environment"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
    
    ; Clean files (preserve config and logs)
    Delete "$INSTDIR\asikad.exe"
    Delete "$INSTDIR\asika.exe"
    Delete "$INSTDIR\uninstall.exe"
    RMDir /r "$INSTDIR\doc"
    
    ; Remove directory if empty
    RMDir "$INSTDIR"
    
    ; Clean start menu
    Delete "$SMPROGRAMS\${PRODUCT_NAME}\*.*"
    RMDir "$SMPROGRAMS\${PRODUCT_NAME}"
SectionEnd
