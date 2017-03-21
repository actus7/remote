unit uMainC;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  System.IOUtils, System.Threading, System.JSON, Data.DBXJSONCommon,
  ChatFacade, Firebase.Interfaces, Firebase.Auth, Firebase.Database,
  StdCtrls, Soap.EncdDecd, Vcl.Imaging.pngimage, System.IniFiles;

type
  TProcessJSONString = TProc<TJSONString>;

type
  TfrmMainC = class(TForm)
    Panel1: TPanel;
    lbl1: TLabel;
    edtKey: TEdit;
    edtEmail: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    edtSenha: TEdit;
    btnConectar: TButton;
    edtServidor: TEdit;
    Label3: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnConectarClick(Sender: TObject);

  private
    function DoLogin: Boolean;
    procedure NovaImagem(AImagem: TChatFile);
    { Private declarations }
  public
    LFC: IFirebaseChatFacade;

    { Public declarations }
  end;

var
  frmMainC: TfrmMainC;
  FToken: string;
  Images: array [0 .. 9, 0 .. 8] of TImage;
  PosX, PosY: Integer;

implementation

{$R *.dfm}

uses uChat;

procedure TfrmMainC.btnConectarClick(Sender: TObject);
begin
  if not DoLogin then
  begin
    ShowMessage('Login failed');
    exit;
  end;
  LFC := TFirebaseChatFacade.Create;
  LFC.SetBaseURI(edtServidor.Text);
  LFC.SetToken(FToken);
  LFC.SetUsername(edtEmail.Text);
  LFC.SetOnNewScreen(NovaImagem);
  LFC.StartListenScreen;
  frmChat.Show;
end;

function TfrmMainC.DoLogin: Boolean;
var
  Auth: IFirebaseAuth;
  AResponse: IFirebaseResponse;
  JSONResp: TJSONValue;
  Obj: TJSONObject;
begin
  Auth := TFirebaseAuth.Create;
  Auth.SetApiKey(edtKey.Text);
  AResponse := Auth.SignInWithEmailAndPassword(edtEmail.Text, edtSenha.Text);
  JSONResp := TJSONObject.ParseJSONValue(AResponse.ContentAsString);
  try
    if (not Assigned(JSONResp)) or (not(JSONResp is TJSONObject)) then
      exit(False);
    Obj := JSONResp as TJSONObject;
    Obj.Values['idToken'].Value;
    FToken := Obj.Values['idToken'].Value;
    Result := true;
  finally
    JSONResp.Free;
  end;
end;

function PngFromBase64(const base64: string): TPngImage;
var
  Input: TStringStream;
  Output: TBytesStream;
begin
  Input := TStringStream.Create(base64, TEncoding.ASCII);
  try
    Output := TBytesStream.Create;
    try
      Soap.EncdDecd.DecodeStream(Input, Output);
      Output.Position := 0;
      Result := TPngImage.Create;
      try
        Result.LoadFromStream(Output);
      except
        Result.Free;
        raise;
      end;
    finally
      Output.Free;
    end;
  finally
    Input.Free;
  end;
end;

procedure TfrmMainC.NovaImagem(AImagem: TChatFile);
var
  Png: TPngImage;
begin
  try
    Png := PngFromBase64(AImagem.FileStream);
    try
      try
        Application.ProcessMessages;
        TImage(Application.FindComponent('Captura' + AImagem.Position)).Picture.Assign(nil);
        TImage(Application.FindComponent('Captura' + AImagem.Position)).Picture.Assign(Png);
      finally
        TImage(Application.FindComponent('Captura' + AImagem.Position)).Update;
      end;
    finally
      Png.Free;
    end;
  except
  end;
end;

procedure TfrmMainC.FormClose(Sender: TObject; var Action: TCloseAction);
var
  appINI: TIniFile;
begin
  appINI := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  try
    appINI.WriteString('Conexao', 'Key', edtKey.Text);
    appINI.WriteString('Conexao', 'Server', edtServidor.Text);
    appINI.WriteString('Conexao', 'Email', edtEmail.Text);
    appINI.WriteString('Conexao', 'Senha', edtSenha.Text);
  finally
    appINI.Free;
  end;
end;

procedure TfrmMainC.FormCreate(Sender: TObject);
var
  appINI: TIniFile;
begin
  appINI := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  try
    edtKey.Text := appINI.ReadString('Conexao', 'Key', '');
    edtServidor.Text := appINI.ReadString('Conexao', 'Server', '');
    edtEmail.Text := appINI.ReadString('Conexao', 'Email', '');
    edtSenha.Text := appINI.ReadString('Conexao', 'Senha', '');
  finally
    appINI.Free;
  end;
end;

procedure TfrmMainC.FormShow(Sender: TObject);
begin
  Height := Screen.Height;
  Width := Screen.Width;

  for PosX := 0 to 9 do
  begin
    for PosY := 0 to 8 do
    begin
      Images[PosX, PosY] := TImage.Create(Application);
      Images[PosX, PosY].Parent := frmMainC;
      Images[PosX, PosY].Name := 'Captura' + IntToStr(PosX) + IntToStr(PosY);
      Images[PosX, PosY].Height := frmMainC.Height div 9 - 10;
      Images[PosX, PosY].Width := frmMainC.Width div 9;
      Images[PosX, PosY].Top := PosX * Images[PosX, PosY].Height;
      Images[PosX, PosY].Left := PosY * Images[PosX, PosY].Width;
    end;
  end;

end;

end.
