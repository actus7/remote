unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.WinXCtrls,
  System.IOUtils, System.Threading, System.JSON, Data.DBXJSONCommon, IWSystem,
  ChatFacade, Firebase.Interfaces, Firebase.Auth, Firebase.Database, Soap.EncdDecd,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, System.Win.Registry, System.IniFiles;

type
  TTCapturaTela = class(TThread)
  private
    function DoLogin: Boolean;
    function ImagensIguais(Bitmap1, Bitmap2: TBitmap): Boolean;
    function Base64FromPng(Png: TPngImage): string;
    procedure ScreenShot(X, Y, Width, Height: integer; bm: TBitmap);
  protected
    Images: array [0 .. 9, 0 .. 8] of TImage;
    PosX, PosY: integer;
    procedure Execute; override;
    procedure AtualizaTela;
  public
    LFC: IFirebaseChatFacade;
    FToken: string;
    vBmp1, vBmp2: TBitmap;
    constructor Create(CreateSuspended: Boolean);
  end;

  TfrmMain = class(TForm)
    Panel1: TPanel;
    lbl1: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    edtKey: TEdit;
    edtEmail: TEdit;
    edtSenha: TEdit;
    btnConectar: TButton;
    edtServidor: TEdit;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
  private
    ThrCapturaTela: TTCapturaTela;
    { Private declarations }
  end;

var
  frmMain: TfrmMain;
  Key, Server, Email, Senha: string;

implementation

{$R *.dfm}

procedure TfrmMain.btnConectarClick(Sender: TObject);
begin
  Key := edtKey.Text;
  Server := edtServidor.Text;
  Email := edtEmail.Text;
  Senha := edtSenha.Text;
  ThrCapturaTela := TTCapturaTela.Create(False);
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
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

  if Assigned(ThrCapturaTela) then
  begin
    ThrCapturaTela.Terminate;
    ThrCapturaTela.Free;
    ThrCapturaTela := Nil;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
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

procedure TfrmMain.FormShow(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := True;
  Height := Screen.Height;
  Width := Screen.Width;
end;

procedure Alterar(pImagemBMP: string; pTile: Boolean = True);
var
  Reg: TRegIniFile;
begin
  Reg := TRegIniFile.Create('Control Panel\Desktop');
  with Reg do
  begin
    WriteString('', 'Wallpaper', pImagemBMP);
    if (pTile) then
      WriteString('', 'TileWallpaper', '1')
    else
      WriteString('', 'TileWallpaper', '0')
  end;
  Reg.Free;
  SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, nil, SPIF_SENDWININICHANGE);
end;

{ TWMinhaThread }

constructor TTCapturaTela.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FreeOnTerminate := False;
end;

function TTCapturaTela.DoLogin: Boolean;
var
  Auth: IFirebaseAuth;
  AResponse: IFirebaseResponse;
  JSONResp: TJSONValue;
  Obj: TJSONObject;
begin
  Auth := TFirebaseAuth.Create;
  Auth.SetApiKey(Key);
  AResponse := Auth.SignInWithEmailAndPassword(Email, Senha);
  JSONResp := TJSONObject.ParseJSONValue(AResponse.ContentAsString);
  try
    if (not Assigned(JSONResp)) or (not(JSONResp is TJSONObject)) then
      exit(False);
    Obj := JSONResp as TJSONObject;
    Obj.Values['idToken'].Value;
    FToken := Obj.Values['idToken'].Value;
    Result := True;
  finally
    JSONResp.Free;
  end;
end;

function TTCapturaTela.ImagensIguais(Bitmap1, Bitmap2: TBitmap): Boolean;
var
  Stream1, Stream2: TMemoryStream;
begin
  Assert((Bitmap1 <> nil) and (Bitmap2 <> nil), 'Erro!');
  Result := False;
  if (Bitmap1.Height <> Bitmap2.Height) or (Bitmap1.Width <> Bitmap2.Width) then
    exit;
  Stream1 := TMemoryStream.Create;
  try
    Bitmap1.SaveToStream(Stream1);
    Stream2 := TMemoryStream.Create;
    try
      Bitmap2.SaveToStream(Stream2);
      if Stream1.Size = Stream2.Size Then
        Result := CompareMem(Stream1.Memory, Stream2.Memory, Stream1.Size);
    finally
      Stream2.Free;
    end;
  finally
    Stream1.Free;
  end;
end;

function TTCapturaTela.Base64FromPng(Png: TPngImage): string;
var
  Input: TBytesStream;
  Output: TStringStream;
begin
  Input := TBytesStream.Create;
  try
    Png.SaveToStream(Input);
    Input.Position := 0;
    Output := TStringStream.Create('', TEncoding.ASCII);
    try
      Soap.EncdDecd.EncodeStream(Input, Output);
      Result := Output.DataString;
    finally
      Output.Free;
    end;
  finally
    Input.Free;
  end;
end;

procedure TTCapturaTela.ScreenShot(X: integer; Y: integer; // (x, y) = Left-top coordinate
  Width: integer; Height: integer; // (Width-Height) = Bottom-Right coordinate
  bm: TBitmap); // Destination
var
  dc: hdc;
  lpPal: PLOGPALETTE;
begin
  { test width and height }
  if ((Width = 0) or (Height = 0)) then
    exit;
  bm.Width := Width;
  bm.Height := Height;
  { get the screen dc }
  dc := GetDc(0);
  if (dc = 0) then
    exit;
  { do we have a palette device? }
  if (GetDeviceCaps(dc, RASTERCAPS) and RC_PALETTE = RC_PALETTE) then
  begin
    { allocate memory for a logical palette }
    GetMem(lpPal, SizeOf(TLOGPALETTE) + (255 * SizeOf(TPALETTEENTRY)));
    { zero it out to be neat }
    FillChar(lpPal^, SizeOf(TLOGPALETTE) + (255 * SizeOf(TPALETTEENTRY)), #0);
    { fill in the palette version }
    lpPal^.palVersion := $300;
    { grab the system palette entries }
    lpPal^.palNumEntries := GetSystemPaletteEntries(dc, 0, 256, lpPal^.palPalEntry);
    if (lpPal^.palNumEntries <> 0) then
      { create the palette }
      bm.Palette := CreatePalette(lpPal^);
    FreeMem(lpPal, SizeOf(TLOGPALETTE) + (255 * SizeOf(TPALETTEENTRY)));
  end;
  { copy from the screen to the bitmap }
  BitBlt(bm.Canvas.Handle, 1, 1, Width, Height, dc, X, Y, SRCCOPY);
  bm.PixelFormat := pf4bit;
  { release the screen dc }
  ReleaseDC(0, dc);
end;

procedure TTCapturaTela.AtualizaTela;
var
  lfrmMain: TfrmMain;
  vPNG: TPNGObject;

  Filename: string;
const
  NamePrefix = 'Captura';
begin
  if PosX <= 9 then // Coluna
  begin
    if PosY <= 8 then // Linha
    begin
      try
        vBmp1.Assign(Images[PosX, PosY].Picture.Graphic);
        try
          vPNG := TPNGObject.Create;
          ScreenShot(Images[PosX, PosY].Left, Images[PosX, PosY].Top, Images[PosX, PosY].Width, Images[PosX, PosY].Height, vBmp2);
          vPNG.Assign(vBmp2);
          if not ImagensIguais(vBmp1, vBmp2) then
          begin
            LFC.SendScreen(PosX, PosY, Base64FromPng(vPNG)); // Envia imagem para o banco
            Images[PosX, PosY].Picture.Graphic := vBmp2;
            { Filename := IncludeTrailingPathDelim(gsAppPath) + Images[PosX, PosY].Name + '.png';
              if FileExists(Filename) then
              DeleteFile(Filename);
              vPNG.SaveToFile(Filename); }
          end;

        finally
          vPNG.Free;
        end;
      except
      end;
      Inc(PosY);
    end
    else
    begin
      PosY := 0;
      Inc(PosX);
    end;
  end
  else
  begin
    PosY := 0;
    PosX := 0;
  end;
end;

procedure TTCapturaTela.Execute;
var
  tmpPosX, tmpPosY: integer;
begin
  if not DoLogin then
  begin
    ShowMessage('Login failed');
    exit;
  end;

  LFC := TFirebaseChatFacade.Create;
  LFC.SetBaseURI(Server);
  LFC.SetToken(FToken);
  LFC.SetUsername(Email);

  Alterar(IncludeTrailingPathDelim(gsAppPath) + 'oi.png');

  for tmpPosX := 0 to 9 do
  begin
    for tmpPosY := 0 to 8 do
    begin
      Images[tmpPosX, tmpPosY] := TImage.Create(Application);
      Images[tmpPosX, tmpPosY].Parent := frmMain;
      Images[tmpPosX, tmpPosY].Name := 'Captura' + IntToStr(tmpPosX) + IntToStr(tmpPosY);
      Images[tmpPosX, tmpPosY].Height := frmMain.Height div 9 - 10;
      Images[tmpPosX, tmpPosY].Width := frmMain.Width div 9;
      Images[tmpPosX, tmpPosY].Top := tmpPosX * Images[tmpPosX, tmpPosY].Height;
      Images[tmpPosX, tmpPosY].Left := tmpPosY * Images[tmpPosX, tmpPosY].Width;
    end;
  end;

  vBmp1 := TBitmap.Create;
  vBmp2 := TBitmap.Create;
  PosX := 0;
  PosY := 0;
  while not Terminated do
  begin
    Synchronize(AtualizaTela);
    sleep(10);
  end;
  vBmp1.Free;
  vBmp2.Free;
end;

end.
