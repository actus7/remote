object frmMainC: TfrmMainC
  Left = 0
  Top = 0
  Caption = 'Viewer'
  ClientHeight = 514
  ClientWidth = 791
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 791
    Height = 41
    Align = alTop
    TabOrder = 0
    object lbl1: TLabel
      Left = 16
      Top = 14
      Width = 22
      Height = 13
      Caption = 'Key:'
    end
    object Label1: TLabel
      Left = 394
      Top = 14
      Width = 32
      Height = 13
      Caption = 'E-mail:'
    end
    object Label2: TLabel
      Left = 536
      Top = 14
      Width = 34
      Height = 13
      Caption = 'Senha:'
    end
    object Label3: TLabel
      Left = 190
      Top = 14
      Width = 44
      Height = 13
      Caption = 'Servidor:'
    end
    object edtKey: TEdit
      Left = 44
      Top = 11
      Width = 140
      Height = 21
      TabOrder = 0
    end
    object edtEmail: TEdit
      Left = 432
      Top = 11
      Width = 98
      Height = 21
      TabOrder = 1
    end
    object edtSenha: TEdit
      Left = 576
      Top = 11
      Width = 89
      Height = 21
      PasswordChar = '*'
      TabOrder = 2
    end
    object btnConectar: TButton
      Left = 671
      Top = 9
      Width = 106
      Height = 25
      Caption = 'Conectar'
      TabOrder = 3
      OnClick = btnConectarClick
    end
    object edtServidor: TEdit
      Left = 240
      Top = 11
      Width = 148
      Height = 21
      TabOrder = 4
    end
  end
end
