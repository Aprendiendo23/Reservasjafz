; Script de Inno Setup para Reservas de Recursos
; Requiere: Inno Setup 6 o superior
; Uso: Compilar este archivo despues de ejecutar 'flutter build windows --release'

#define AppName "Reservas_de_Recursos"
#define AppVersion "1.0.0"
#define AppPublisher "Tu Empresa"
#define AppExeName "reservas_recursos.exe"
#define BuildPath "build\windows\x64\runner\Release"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
OutputDir=installer_output
OutputBaseFilename=ReservasRecursos_Instalador
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear icono en el escritorio"; GroupDescription: "Iconos adicionales"; Flags: unchecked
Name: "quicklaunchicon"; Description: "Crear icono en la barra de inicio rapido"; GroupDescription: "Iconos adicionales"; Flags: unchecked; OnlyBelowVersion: 6.1

[Files]
Source: "{#BuildPath}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\Desinstalar {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Ejecutar {#AppName}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
  if not DirExists(ExpandConstant('{#BuildPath}')) then
  begin
    MsgBox('Error: No se encuentra la carpeta de compilacion.' + #13#10 + 
           'Por favor ejecuta primero: flutter build windows --release', 
           mbError, MB_OK);
    Result := False;
  end;
end;
