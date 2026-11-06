#define AppVersion "2.0.0"

[Setup]
AppId=lostinsea.CipherBench.Windows
AppName=CipherBench
AppVersion={#AppVersion}
AppPublisher=lostinsea
DefaultDirName={localappdata}\Programs\CipherBench
DefaultGroupName=CipherBench
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
MinVersion=10.0
OutputDir=..\build\windows-installer
OutputBaseFilename=CipherBench-{#AppVersion}-Windows-x64-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\cipherbench.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\CREDITS.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\licenses\OFL-JetBrainsMono.txt"; DestDir: "{app}\licenses"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\CipherBench"; Filename: "{app}\cipherbench.exe"

[Run]
Filename: "{app}\cipherbench.exe"; Description: "Launch CipherBench"; Flags: nowait postinstall skipifsilent
