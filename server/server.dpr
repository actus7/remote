program server;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frmMain},
  ChatFacade in '..\firebase\ChatFacade.pas',
  Firebase.Auth in '..\firebase\Firebase.Auth.pas',
  Firebase.Database in '..\firebase\Firebase.Database.pas',
  Firebase.Interfaces in '..\firebase\Firebase.Interfaces.pas',
  Firebase.Request in '..\firebase\Firebase.Request.pas',
  Firebase.Response in '..\firebase\Firebase.Response.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
