unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.WinXCtrls,
  System.IOUtils, System.Threading, System.JSON, Data.DBXJSONCommon, IWSystem,
  ChatFacade, Firebase.Interfaces, Firebase.Auth, Firebase.Database, Soap.EncdDecd,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, Registry;

const
  WEB_API_KEY = 'AIzaSyCc8kVQojl6NU39KlVT1V_XIlEt3hspsco';

type
  TfrmMain = class(TForm)
    Button1: TButton;
    tmrteste: TTimer;
    mm1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrtesteTimer(Sender: TObject);
  private
    function DoLogin: Boolean;
    { Private declarations }
  public
    LFC: IFirebaseChatFacade;
    FToken: string;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  Images: array [0 .. 9, 0 .. 8] of TImage;
  PosX, PosY: Integer;

implementation

{$R *.dfm}

function TfrmMain.DoLogin: Boolean;
var
  Auth: IFirebaseAuth;
  AResponse: IFirebaseResponse;
  JSONResp: TJSONValue;
  Obj: TJSONObject;
begin
  Auth := TFirebaseAuth.Create;
  Auth.SetApiKey(WEB_API_KEY);
  AResponse := Auth.SignInWithEmailAndPassword('newuser@novouser.com', 'novouser');
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

procedure TfrmMain.FormShow(Sender: TObject);
begin
  if not DoLogin then
  begin
    ShowMessage('Login failed');
    exit;
  end;
  LFC := TFirebaseChatFacade.Create;
  LFC.SetBaseURI('https://remote-273cd.firebaseio.com');
  LFC.SetToken(FToken);
  LFC.SetUsername('newuser@novouser.com');

  Height := Screen.Height;
  Width := Screen.Width;

  for PosX := 0 to 9 do
  begin
    for PosY := 0 to 8 do
    begin
      Images[PosX, PosY] := TImage.Create(Application);
      Images[PosX, PosY].Parent := frmMain;
      Images[PosX, PosY].Name := 'Captura' + IntToStr(PosX) + IntToStr(PosY);
      Images[PosX, PosY].Height := frmMain.Height div 9 - 10;
      Images[PosX, PosY].Width := frmMain.Width div 9;
      Images[PosX, PosY].Top := PosX * Images[PosX, PosY].Height;
      Images[PosX, PosY].Left := PosY * Images[PosX, PosY].Width;
    end;
  end;
  // tmrteste.Enabled := true;
end;

function Base64FromPng(Png: TPngImage): string;
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

procedure Alterar(pImagemBMP: string; pTile: Boolean = true);
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

function CapturaTela(imgW, imgH, X, Y: Integer): TPngImage;
var
  dc: hdc;
  cv: TCanvas;
  Bmp: TBitmap;
  JPG: TJPegImage;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Width := imgW;
    Bmp.Height := imgH;
    dc := GetDc(0);
    cv := TCanvas.Create;
    cv.Handle := dc;
    Bmp.Canvas.CopyRect(Rect(1, 1, imgW, imgH), cv, Rect(X, Y, imgW + X, imgH + Y));
    Bmp.PixelFormat := pf4bit;
    JPG := TJPegImage.Create;
    try
      JPG.Assign(Bmp);
      JPG.CompressionQuality := 20;
      Bmp.Assign(JPG);
      Result := TPngImage.Create;
      Result.Assign(Bmp);
    finally
      FreeAndNil(JPG);
    end;
    cv.Free;
    ReleaseDC(0, dc);
  finally
    FreeAndNil(Bmp);
  end;
end;

procedure TfrmMain.tmrtesteTimer(Sender: TObject);
begin
  tmrteste.Interval := 500;
  Button1Click(Sender);
end;

function IsSameBitmap(Bitmap1, Bitmap2: TBitmap): Boolean;
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

procedure TfrmMain.Button1Click(Sender: TObject);
var
  vPng: TPngImage;
  vBmp1, vBmp2: TBitmap;
  Filename: string;
  aTask: ITask;
  tmpImage: TImage;
  Stream1, Stream2: TMemoryStream;
const
  NamePrefix = 'Captura';
begin
  vBmp1 := TBitmap.Create;
  vBmp2 := TBitmap.Create;
  Stream1 := TMemoryStream.Create;
  Stream2 := TMemoryStream.Create;
  try
    aTask := TTask.Create(
      procedure()
      begin
        sleep(100);
        TThread.Synchronize(nil,
          procedure
          begin
            for PosX := 0 to 9 do
            begin
              for PosY := 0 to 8 do
              begin
                tmpImage := TImage(Application.FindComponent(NamePrefix + IntToStr(PosX) + IntToStr(PosY)));
                vBmp1.Assign(tmpImage.Picture.Graphic);

                vPng := CapturaTela(tmpImage.Width, tmpImage.Height, tmpImage.Left, tmpImage.Top);
                vBmp2.Assign(vPng);

                if not IsSameBitmap(vBmp1, vBmp2) then
                begin
                  mm1.Lines.Add('Mudou imagem: ' + tmpImage.Name);
                  LFC.SendScreen(PosX, PosY, Base64FromPng(vPng));
                end;

                tmpImage.Picture.Graphic := vPng;
                Filename := IncludeTrailingPathDelim(gsAppPath) + tmpImage.Name + '.png';
                if FileExists(Filename) then
                  DeleteFile(Filename);
                tmpImage.Picture.SaveToFile(Filename);
                tmpImage.Invalidate;

                Alterar(IncludeTrailingPathDelim(gsAppPath) + 'oi.png');
              end;
            end;
          end);
      end);
    aTask.Start;
  finally
    Stream1.Free;
    Stream2.Free;
  end;

end;

end.
