[Setup]
AppId={{A1B2C3D4-1234-5678-ABCD-123456789ABC}}
AppName=Piscigranja
AppVersion=1.1.8
AppPublisher=Piscigranja System
AppPublisherURL=
AppSupportURL=
AppUpdatesURL=

DefaultDirName={autopf}\Piscigranja
DefaultGroupName=Piscigranja

OutputDir=output
OutputBaseFilename=PiscigranjaInstaller

Compression=lzma
SolidCompression=yes
WizardStyle=modern

DisableDirPage=no
DisableProgramGroupPage=yes

PrivilegesRequired=admin

CloseApplications=yes
RestartApplications=yes

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Opciones adicionales:"; Flags: unchecked

; 🔥 BD persistente (NO se elimina al desinstalar)
[Dirs]
Name: "{localappdata}\Piscigranja"; Flags: uninsneveruninstall

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Piscigranja"; Filename: "{app}\piscigranja.exe"
Name: "{group}\Desinstalar Piscigranja"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Piscigranja"; Filename: "{app}\piscigranja.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\piscigranja.exe"; Description: "Ejecutar Piscigranja"; Flags: nowait postinstall skipifsilent
