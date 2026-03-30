[Setup]
AppName=Piscigranja
AppVersion=1.0.0
DefaultDirName={pf}\Piscigranja
DefaultGroupName=Piscigranja
OutputDir=output
OutputBaseFilename=PiscigranjaInstaller
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\Piscigranja"; Filename: "{app}\piscigranja.exe"
Name: "{commondesktop}\Piscigranja"; Filename: "{app}\piscigranja.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"

[Code]

// Mensajes dinámicos durante instalación
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    WizardForm.StatusLabel.Caption := 'Instalando archivos de Piscigranja...';
  end;

  if CurStep = ssPostInstall then
  begin
    WizardForm.StatusLabel.Caption := 'Finalizando instalación...';
  end;
end;

// Mensaje por archivo (más realista)
procedure CurInstallProgressChanged(CurProgress, MaxProgress: Integer);
begin
  WizardForm.ProgressGauge.Position := CurProgress;
end;