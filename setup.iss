#ifndef AppVersion
  #define AppVersion "0.2.0"
#endif

[Setup]
AppId=DesktopRestore
AppName=Верни рабочий стол
AppVersion={#AppVersion}
DefaultDirName={localappdata}\Programs\DesktopRestore
DefaultGroupName=Верни рабочий стол
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
OutputDir=dist
OutputBaseFilename=DesktopRestore-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\DesktopRestore.exe

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; Flags: unchecked

[Files]
Source: "dist\DesktopRestore\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Верни рабочий стол"; Filename: "{app}\DesktopRestore.exe"
Name: "{autodesktop}\Верни рабочий стол"; Filename: "{app}\DesktopRestore.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\DesktopRestore.exe"; Description: "{cm:LaunchProgram,Верни рабочий стол}"; Flags: nowait postinstall skipifsilent
