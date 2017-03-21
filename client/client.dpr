program client;

uses
  Vcl.Forms,
  uMainC in 'uMainC.pas' {frmMainC},
  ChatFacade in '..\firebase\ChatFacade.pas',
  Firebase.Auth in '..\firebase\Firebase.Auth.pas',
  Firebase.Database in '..\firebase\Firebase.Database.pas',
  Firebase.Interfaces in '..\firebase\Firebase.Interfaces.pas',
  Firebase.Request in '..\firebase\Firebase.Request.pas',
  Firebase.Response in '..\firebase\Firebase.Response.pas',
  uChat in 'uChat.pas' {frmChat};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMainC, frmMainC);
  Application.CreateForm(TfrmChat, frmChat);
  Application.Run;
end.
