unit ChatFacade;

interface

uses
  Firebase.Interfaces, Firebase.Database, System.SysUtils, Generics.Collections,
  System.Threading, System.JSON,
  // Novas implementações
  System.SyncObjs, IdSync;

type
  TLog = class(TIdNotify)
  protected
    FArg: string;
    FMsg: string;
    procedure DoNotify; override;
  public
    class procedure LogMsg(const aArq, aMsg: string);
  end;

  TChatMessage = class(TObject)
  private
    FMsg: string;
    FUsername: string;
    FTimeStamp: TDateTime;
    procedure SetMsg(const Value: string);
    procedure SetUsername(const Value: string);
    procedure SetTimeStamp(const Value: TDateTime);
  public
    property Username: string read FUsername write SetUsername;
    property Msg: string read FMsg write SetMsg;
    property TimeStamp: TDateTime read FTimeStamp write SetTimeStamp;
  end;

  TChatFile = class(TObject)
  private
    FUsername: string;
    FFileName: string;
    FPosition: string;
    FFileStream: string;
    FTimeStamp: TDateTime;
    procedure SetUsername(const Value: string);
    procedure SetFileName(const Value: string);
    procedure SetPosition(const Value: string);
    procedure SetFileStream(const Value: string);
    procedure SetTimeStamp(const Value: TDateTime);
  public
    property Username: string read FUsername write SetUsername;
    property FileName: string read FFileName write SetFileName;
    property Position: string read FPosition write SetPosition;
    property FileStream: string read FFileStream write SetFileStream;
    property TimeStamp: TDateTime read FTimeStamp write SetTimeStamp;
  end;

  IFirebaseChatFacade = interface
    ['{84BAC826-AF2A-4422-A98F-53382119A693}']
    procedure SetBaseURI(const AURI: string);
    procedure SetToken(const AToken: string);
    procedure SetUsername(const AUsername: string);
    procedure SendScreen(PosX, PosY: integer; AFileStream: string);
    procedure SendMessage(AMessage: string);
    procedure SetOnNewMessage(AProc: TProc<TChatMessage>);
    procedure SetOnNewScreen(AProc: TProc<TChatFile>);
    procedure StartListenChat;
    procedure StartListenScreen;
    procedure StopListenChat;
    procedure DeleteOlderChat;
  end;

  TFirebaseChatFacade = class(TInterfacedObject, IFirebaseChatFacade)
  private
    FMessages: TDictionary<string, TChatMessage>;
    FScreens: TDictionary<string, TChatFile>;
    FBaseURI: string;
    FUsername: string;
    FOnNewMessage: TProc<TChatMessage>;
    FOnNewScreen: TProc<TChatFile>;
    Run: Boolean;
    FToken: string;

    // Novas Implementações
    FCritical: TCriticalSection;
    procedure ParseResponseScr(AResp: IFirebaseResponse);
    procedure ParseResponseMsg(AResp: IFirebaseResponse);
    procedure RemoveOlderMessage;
    procedure RemoveOlderFiles;
    procedure SetBaseURI(const Value: string);
    procedure SetUsername(const Value: string);
    procedure OnNewMessage(AChatMsg: TChatMessage);
    procedure OnNewScreen(AChatFile: TChatFile);
    procedure SetToken(const Value: string);
  public
    constructor Create;
    destructor Destroy; override;
    property BaseURI: string read FBaseURI write SetBaseURI;
    property Username: string read FUsername write SetUsername;
    property Token: string read FToken write SetToken;
    procedure SetOnNewMessage(AProc: TProc<TChatMessage>);
    procedure SetOnNewScreen(AProc: TProc<TChatFile>);
    procedure SendScreen(PosX, PosY: integer; AFileStream: string);
    procedure SendMessage(AMessage: string);
    procedure StartListenChat;
    procedure StartListenScreen;
    procedure StopListenChat;
    procedure DeleteOlderChat;
  end;

implementation

uses
  System.Classes;

type
  TChatParser = class(TObject)
    class function GetMessage(AObj: TJSONObject): TChatMessage;
    class function GetJSON(AChatMessage: TChatMessage): TJSONObject; overload;
    class function GetJSON(AUsername: string; AMessage: string): TJSONObject; overload;
  end;

  TScreenParser = class(TObject)
    class function GetScreen(APosicao: string; AObj: TJSONObject): TChatFile;
    class function GetJSONScreen(AChatFile: TChatFile): TJSONObject; overload;
    class function GetJSONScreen(AFileStream: string): TJSONObject; overload;
  end;

  { TFirebaseChatFacade }

constructor TFirebaseChatFacade.Create;
begin
  inherited Create;
  FMessages := TDictionary<string, TChatMessage>.Create;
  FScreens := TDictionary<string, TChatFile>.Create;
  // Novas Implementações
  FCritical := TCriticalSection.Create;
end;

destructor TFirebaseChatFacade.Destroy;
var
  I: integer;
begin
  Run := false;
  for I := 0 to 2 do
    TThread.Sleep(50);
  if Assigned(FMessages) then
    FMessages.Free;
  if Assigned(FScreens) then
    FScreens.Free;
  // Novas Implementações
  if Assigned(FCritical) then
    FCritical.Free;
  inherited;
end;

procedure TFirebaseChatFacade.OnNewMessage(AChatMsg: TChatMessage);
begin
  TThread.Queue(nil,
    procedure
    begin
      FOnNewMessage(AChatMsg);
    end);
end;

procedure TFirebaseChatFacade.OnNewScreen(AChatFile: TChatFile);
begin
  TThread.Queue(nil,
    procedure
    begin
      FOnNewScreen(AChatFile);
    end);
end;

procedure TFirebaseChatFacade.ParseResponseMsg(AResp: IFirebaseResponse);
var
  Obj: TJSONObject;
  I: integer;
  Key: string;
  ChatMsg: TChatMessage;
  JSONResp: TJSONValue;
begin
  // TLog.LogMsg('uChatFacade', AResp.ContentAsString);
  JSONResp := TJSONObject.ParseJSONValue(AResp.ContentAsString);
  if (not Assigned(JSONResp)) or (not(JSONResp is TJSONObject)) then
  begin
    if Assigned(JSONResp) then
      JSONResp.Free;
    exit;
  end;
  Obj := JSONResp as TJSONObject;
  try
    // TMonitor.Enter(FScreens);
    FCritical.Enter;
    try
      for I := 0 to Obj.Count - 1 do
      begin
        Key := Obj.Pairs[I].JsonString.Value;
        if not FMessages.ContainsKey(Key) then
        begin
          ChatMsg := TChatParser.GetMessage(Obj.Pairs[I].JsonValue as TJSONObject);
          FMessages.Add(Key, ChatMsg);
          OnNewMessage(ChatMsg);
          RemoveOlderMessage;
        end;
      end;
    finally
      // TMonitor.exit(FScreens);
      FCritical.Release;
    end;
  finally
    Obj.Free;
  end;
end;

procedure TFirebaseChatFacade.ParseResponseScr(AResp: IFirebaseResponse);
var
  Obj, Obj2: TJSONObject;
  I: integer;
  Key, Posicao: string;
  ChatFile: TChatFile;
  JSONRespScr: TJSONValue;
  X: integer;
begin
  JSONRespScr := TJSONObject.ParseJSONValue(AResp.ContentAsString);
  if (not Assigned(JSONRespScr)) or (not(JSONRespScr is TJSONObject)) then
  begin
    if Assigned(JSONRespScr) then
      JSONRespScr.Free;
    exit;
  end;
  Obj := JSONRespScr as TJSONObject;
  try
    // TMonitor.Enter(FScreens);
    FCritical.Enter;
    try
      for I := 0 to Obj.Count - 1 do
      begin
        Posicao := Obj.Pairs[I].JsonString.Value;
        Obj2 := Obj.Pairs[I].JsonValue as TJSONObject;
        for X := 0 to Obj2.Count - 1 do
        begin
          Key := Obj2.Pairs[X].JsonString.Value;
          if not FScreens.ContainsKey(Key) then // Verificar as Keys que precisa atualizar
          begin
            delete(Posicao, 1, 1);
            ChatFile := TScreenParser.GetScreen(Posicao, Obj2.Pairs[X].JsonValue as TJSONObject);
            FScreens.Add(Key, ChatFile);
            OnNewScreen(ChatFile);
            // RemoveOlderFiles;
          end;
        end;
      end;
    finally
      // TMonitor.exit(FScreens);
      FCritical.Release;
    end;
  finally
    Obj.Free;
  end;
end;

procedure TFirebaseChatFacade.RemoveOlderMessage;
var
  Pair: TPair<string, TChatMessage>;
  Older: TDateTime;
  ToDelete: string;
begin
  TMonitor.Enter(FMessages);
  try
    if FMessages.Count < 20 then
      exit;
    Older := Now;
    for Pair in FMessages do
      if Pair.Value.TimeStamp < Older then
      begin
        Older := Pair.Value.TimeStamp;
        ToDelete := Pair.Key;
      end;
    if not ToDelete.IsEmpty then
      FMessages.Remove(ToDelete);
  finally
    TMonitor.exit(FMessages);
  end;
end;

procedure TFirebaseChatFacade.RemoveOlderFiles;
var
  Pair: TPair<string, TChatFile>;
  Older: TDateTime;
  ToDelete: string;
begin
  TMonitor.Enter(FScreens);
  try
    if FScreens.Count < 162 then
      exit;
    Older := Now;
    for Pair in FScreens do
      if Pair.Value.TimeStamp < Older then
      begin
        Older := Pair.Value.TimeStamp;
        ToDelete := Pair.Key;
      end;
    if not ToDelete.IsEmpty then
      FScreens.Remove(ToDelete);
  finally
    TMonitor.exit(FScreens);
  end;
end;

procedure TFirebaseChatFacade.SendScreen(PosX, PosY: integer; AFileStream: string);
begin
  TTask.Run(
    procedure
    var
      FFC: IFirebaseDatabase;
      ToSend: TJSONObject;
      QueryParams: TDictionary<string, string>;
    begin
      FFC := TFirebaseDatabase.Create;
      FFC.SetBaseURI(FBaseURI);
      FFC.SetToken(FToken);
      ToSend := TScreenParser.GetJSONScreen(AFileStream);
      QueryParams := TDictionary<string, string>.Create;
      FFC.Delete(['screen/a' + IntToStr(PosX) + IntToStr(PosY) + '.json'], QueryParams);
      FFC.Post(['screen/a' + IntToStr(PosX) + IntToStr(PosY) + '.json'], ToSend);
    end);
end;

procedure TFirebaseChatFacade.SendMessage(AMessage: string);
begin
  TTask.Run(
    procedure
    var
      FFC: IFirebaseDatabase;
      ToSend: TJSONObject;
    begin
      FFC := TFirebaseDatabase.Create;
      FFC.SetBaseURI(FBaseURI);
      FFC.SetToken(FToken);
      ToSend := TChatParser.GetJSON(FUsername, AMessage);
      FFC.Post(['msg.json'], ToSend);
    end);
end;

procedure TFirebaseChatFacade.SetBaseURI(const Value: string);
begin
  FBaseURI := Value;
end;

procedure TFirebaseChatFacade.SetOnNewMessage(AProc: TProc<TChatMessage>);
begin
  FOnNewMessage := AProc;
end;

procedure TFirebaseChatFacade.SetOnNewScreen(AProc: TProc<TChatFile>);
begin
  FOnNewScreen := AProc;
end;

procedure TFirebaseChatFacade.SetToken(const Value: string);
begin
  FToken := Value;
end;

procedure TFirebaseChatFacade.SetUsername(const Value: string);
begin
  FUsername := Value;
end;

procedure TFirebaseChatFacade.StartListenChat;
begin
  Run := true;
  TTask.Run(
    procedure
    var
      FFC: IFirebaseDatabase;
      Response: IFirebaseResponse;
      I: integer;
      QueryParams: TDictionary<string, string>;
    begin
      FFC := TFirebaseDatabase.Create;
      FFC.SetBaseURI(FBaseURI);
      FFC.SetToken(FToken);
      QueryParams := TDictionary<string, string>.Create;
      try
        QueryParams.Add('orderBy', '"$key"');
        QueryParams.Add('limitToLast', '20');
        while Run do
        begin
          Response := FFC.Get(['msg.json'], QueryParams);
          ParseResponseMsg(Response);
          TThread.Sleep(200);
        end;
      finally
        QueryParams.Free;
      end;
    end);
end;

procedure TFirebaseChatFacade.StartListenScreen;
begin
  Run := true;
  TTask.Run(
    procedure
    var
      FFC: IFirebaseDatabase;
      Response: IFirebaseResponse;
      I: integer;
      QueryParams: TDictionary<string, string>;
    begin
      FFC := TFirebaseDatabase.Create;
      FFC.SetBaseURI(FBaseURI);
      FFC.SetToken(FToken);
      QueryParams := TDictionary<string, string>.Create;
      try
        QueryParams.Add('orderBy', '"$key"');
        QueryParams.Add('limitToLast', '60');
        while Run do
        begin
          Response := FFC.Get(['screen.json'], QueryParams);
          ParseResponseScr(Response);
          TThread.Sleep(250);
        end;
      finally
        QueryParams.Free;
      end;
    end);
end;

procedure TFirebaseChatFacade.DeleteOlderChat;
begin
  Run := true;
  TTask.Run(
    procedure
    var
      FFC: IFirebaseDatabase;
      Response: IFirebaseResponse;
      I: integer;
      QueryParams: TDictionary<string, string>;
    begin
      FFC := TFirebaseDatabase.Create;
      FFC.SetBaseURI(FBaseURI);
      FFC.SetToken(FToken);
      QueryParams := TDictionary<string, string>.Create;
      try
        // QueryParams.Add('orderBy', '"$key"');
        // QueryParams.Add('limitToLast', '1');
        while Run do
        begin
          Response := FFC.Delete(['.json'], QueryParams);
          ParseResponseMsg(Response);
          TThread.Sleep(30000);
        end;
      finally
        QueryParams.Free;
      end;
    end);
end;

procedure TFirebaseChatFacade.StopListenChat;
begin
  Run := false;
end;

{ TChatMessage }

procedure TChatMessage.SetMsg(const Value: string);
begin
  FMsg := Value;
end;

procedure TChatMessage.SetTimeStamp(const Value: TDateTime);
begin
  FTimeStamp := Value;
end;

procedure TChatMessage.SetUsername(const Value: string);
begin
  FUsername := Value;
end;

{ TChatFile }

procedure TChatFile.SetFileName(const Value: string);
begin
  FFileName := Value;
end;

procedure TChatFile.SetFileStream(const Value: string);
begin
  FFileStream := Value;
end;

procedure TChatFile.SetPosition(const Value: string);
begin
  FPosition := Value;
end;

procedure TChatFile.SetTimeStamp(const Value: TDateTime);
begin
  FTimeStamp := Value;
end;

procedure TChatFile.SetUsername(const Value: string);
begin
  FUsername := Value;
end;

{ TChatParser }

class function TChatParser.GetJSON(AChatMessage: TChatMessage): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', AChatMessage.Username);
  Result.AddPair('text', AChatMessage.Msg);
end;

class function TChatParser.GetJSON(AUsername, AMessage: string): TJSONObject;
var
  ChatMsg: TChatMessage;
begin
  ChatMsg := TChatMessage.Create;
  try
    ChatMsg.Username := AUsername;
    ChatMsg.Msg := AMessage;
    Result := TChatParser.GetJSON(ChatMsg);
  finally
    ChatMsg.Free;
  end;
end;

class function TChatParser.GetMessage(AObj: TJSONObject): TChatMessage;
begin
  Result := TChatMessage.Create;
  Result.Username := AObj.Values['name'].Value;
  Result.Msg := AObj.Values['text'].Value;
  Result.TimeStamp := Now;
end;

{ TScreenParser }

class function TScreenParser.GetJSONScreen(AChatFile: TChatFile): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('filestream', AChatFile.FileStream);
end;

class function TScreenParser.GetJSONScreen(AFileStream: string): TJSONObject;
var
  ChatFile: TChatFile;
begin
  ChatFile := TChatFile.Create;
  try
    ChatFile.FileStream := AFileStream;
    Result := TScreenParser.GetJSONScreen(ChatFile);
  finally
    ChatFile.Free;
  end;
end;

class function TScreenParser.GetScreen(APosicao: string; AObj: TJSONObject): TChatFile;
begin
  Result := TChatFile.Create;
  Result.Position := APosicao;
  Result.FileStream := AObj.Values['filestream'].Value;
  Result.TimeStamp := Now;
end;

{ TLog }

procedure TLog.DoNotify;
var
  Log: TextFile;
  arquivo: string;
  dirlog: string;
begin
  try
    dirlog := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'log';
    arquivo := dirlog + '\_' + formatdatetime('ddmmyy', date) + '_' + FArg + '.txt';
    if not DirectoryExists(dirlog) then
      ForceDirectories(dirlog);
    AssignFile(Log, arquivo);
    if FileExists(arquivo) then
      Append(Log)
    else
      ReWrite(Log);
    try
      WriteLn(Log, TimeToStr(Now) + ' - :' + FMsg);
    finally
      CloseFile(Log)
    end;
  except
    raise Exception.Create('ERRO NA GERAÇÃO DO LOG');
  end;
end;

class procedure TLog.LogMsg(const aArq, aMsg: string);
begin
  with TLog.Create do
    try
      FArg := aArq;
      FMsg := aMsg;
      Notify;
    except
      Free;
      raise;
    end;
end;

end.
