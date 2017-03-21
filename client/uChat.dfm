object frmChat: TfrmChat
  Left = 0
  Top = 0
  Caption = 'frmChat'
  ClientHeight = 411
  ClientWidth = 304
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ListView1: TListView
    Left = 3
    Top = 3
    Width = 296
    Height = 372
    Columns = <
      item
        Caption = '                        Mensagem'
        Width = 200
      end
      item
        Alignment = taCenter
        Caption = 'Nome'
        MinWidth = 80
        Width = 80
      end>
    TabOrder = 0
    ViewStyle = vsReport
  end
  object Button2: TButton
    Left = 207
    Top = 381
    Width = 91
    Height = 26
    Caption = 'Enviar'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Edit3: TEdit
    Left = 3
    Top = 384
    Width = 199
    Height = 21
    TabOrder = 2
  end
end
