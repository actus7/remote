unit uChat;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, ChatFacade,
  System.Actions, Vcl.ActnList;

type
  TfrmChat = class(TForm)
    ListView1: TListView;
    Button2: TButton;
    Edit3: TEdit;
    procedure Button2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    LFC: IFirebaseChatFacade;

    procedure OnNewMessage(AChatMsg: TChatMessage);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmChat: TfrmChat;

implementation

{$R *.dfm}

uses
  uMainC;

procedure TfrmChat.Button2Click(Sender: TObject);
begin
  LFC.SendMessage(Edit3.Text);
end;

procedure TfrmChat.OnNewMessage(AChatMsg: TChatMessage);
var
  ListItem: TListItem;
begin
  try
    ListView1.Items.BeginUpdate;
    try
      ListItem := ListView1.Items.Add;
      ListItem.Caption := AChatMsg.Msg;
      with ListItem.SubItems do
      begin
        Add(AChatMsg.Username);
      end;
    finally
      ListView1.Items.EndUpdate;
    end;
  finally
    AChatMsg.Free;
  end;
end;

procedure TfrmChat.FormShow(Sender: TObject);
begin
  LFC := TFirebaseChatFacade.Create;
  LFC.SetBaseURI(frmMainC.edtServidor.Text);
  LFC.SetToken(FToken);
  LFC.SetUsername(frmMainC.edtEmail.Text);
  LFC.SetOnNewMessage(OnNewMessage);
  LFC.StartListenChat;
end;

end.
