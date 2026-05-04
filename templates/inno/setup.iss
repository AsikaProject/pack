#define MyAppName "Asika"
#define MyAppVersion "0.0.0.0"
#define MyAppPublisher "Asika Project"

[Setup]
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}

DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}

OutputBaseFilename=Asika_Setup_{#MyAppVersion}
Compression=lzma
SolidCompression=yes

WizardStyle=modern
WizardResizable=no

LicenseFile=LICENSE
PrivilegesRequired=admin
UninstallDisplayIcon={app}\asikad.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Components]
Name: "core"; Description: "Asika Daemon (Required)"; Flags: fixed
Name: "cli"; Description: "Asika CLI"
Name: "service"; Description: "Install as Windows Service"
Name: "docs"; Description: "Documentation"

[Tasks]
Name: "addtopath"; Description: "Add Asika to PATH"; Flags: unchecked
Name: "autorun"; Description: "Start Asika after install"; Flags: unchecked

[Files]
Source: "asikad.exe"; DestDir: "{app}"; Components: core
Source: "asika.exe"; DestDir: "{app}"; Components: cli; Flags: ignoreversion

Source: "doc\*"; DestDir: "{app}\doc"; Components: docs; Flags: recursesubdirs

[Icons]
Name: "{group}\Asika Dashboard"; Filename: "{app}\asikad.exe"; Parameters: "--desktop"
Name: "{group}\Uninstall"; Filename: "{uninstallexe}"

[Code]
function AddToPath(Value: string): Boolean;
var
  OrigPath: string;
begin
  Result := False;
  if not RegQueryStringValue(HKLM,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', OrigPath) then exit;

  if Pos(LowerCase(Value), LowerCase(OrigPath)) = 0 then
  begin
    OrigPath := OrigPath + ';' + Value;
    RegWriteStringValue(HKLM,
      'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
      'Path', OrigPath);
    Result := True;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    if WizardIsTaskSelected('addtopath') then
      AddToPath(ExpandConstant('{app}'));

    if IsComponentSelected('service') then
    begin
      Exec('sc.exe', 'stop asikad', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      Exec('sc.exe', 'delete asikad', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

      if not Exec('sc.exe',
        'create asikad binPath= "' + ExpandConstant('{app}\asikad.exe') + '" start= auto',
        '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      begin
        MsgBox('Failed to create service', mbError, MB_OK);
        exit;
      end;

      Exec('sc.exe', 'description asikad "Asika PR Manager service"',
        '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

      Exec('sc.exe',
        'failure asikad actions= restart/10000/restart/20000/restart/30000 reset= 3600',
        '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

      Exec('reg.exe',
        'add HKLM\SYSTEM\CurrentControlSet\Services\asikad /v Environment /t REG_MULTI_SZ /d "ASIKA_CONFIG=' +
        ExpandConstant('{app}\asika_config.toml') + '\0GOMEMLIMIT=256MiB\0" /f',
        '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

      Exec('netsh.exe',
        'advfirewall firewall add rule name="Asika Daemon" dir=in action=allow program="' +
        ExpandConstant('{app}\asikad.exe') + '" enable=yes',
        '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

      Exec('sc.exe', 'start asikad', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    end;

    if WizardIsTaskSelected('autorun') then
      Exec(ExpandConstant('{app}\asikad.exe'), '--desktop', '', SW_SHOW, ewNoWait, ResultCode);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    Exec('sc.exe', 'stop asikad', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec('sc.exe', 'delete asikad', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    Exec('netsh.exe',
      'advfirewall firewall delete rule program="' +
      ExpandConstant('{app}\asikad.exe') + '"',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    Exec('reg.exe',
      'delete HKLM\SYSTEM\CurrentControlSet\Services\asikad /v Environment /f',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;

[UninstallDelete]
Type: filesandordirs; Name: "{app}\doc"
Type: dirifempty; Name: "{app}"
