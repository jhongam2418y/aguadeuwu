[Setup]
AppId={{A1B2C3D4-1234-5678-ABCD-123456789ABC}}
AppName=El paraiso de andahuasi
AppVersion=1.3.9
AppPublisher=El paraiso de andahuasi System
AppPublisherURL=
AppSupportURL=
AppUpdatesURL=

DefaultDirName={autopf}\ElParaisoDeAndahuasi
DefaultGroupName=El paraiso de andahuasi

OutputDir=output
OutputBaseFilename=ElParaisoDeAndahuasiInstaller

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
Name: "{localappdata}\ElParaisoDeAndahuasi"; Flags: uninsneveruninstall

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\El paraiso de andahuasi"; Filename: "{app}\elparaisodeandahuasi.exe"
Name: "{group}\Desinstalar El paraiso de andahuasi"; Filename: "{uninstallexe}"
Name: "{autodesktop}\El paraiso de andahuasi"; Filename: "{app}\elparaisodeandahuasi.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\elparaisodeandahuasi.exe"; Description: "Ejecutar El paraiso de andahuasi"; Flags: nowait postinstall skipifsilent
