object frmError: TfrmError
  Left = 192
  Top = 114
  BorderStyle = bsDialog
  Caption = '�Ȃł����G���[�\��'
  ClientHeight = 213
  ClientWidth = 465
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = '�l�r �o�S�V�b�N'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 12
  object panelBase: TPanel
    Left = 0
    Top = 177
    Width = 465
    Height = 36
    Align = alBottom
    TabOrder = 0
    OnResize = panelBaseResize
    object panelBtn: TPanel
      Left = 200
      Top = 2
      Width = 256
      Height = 33
      BevelOuter = bvNone
      TabOrder = 0
      object btnDebug: TButton
        Left = 6
        Top = 4
        Width = 75
        Height = 25
        Caption = '�f�o�b�O(&D)'
        TabOrder = 0
        OnClick = btnDebugClick
      end
      object btnContinue: TButton
        Left = 90
        Top = 4
        Width = 75
        Height = 25
        Caption = '������(&C)'
        TabOrder = 1
        OnClick = btnContinueClick
      end
      object btnClose: TButton
        Left = 174
        Top = 4
        Width = 75
        Height = 25
        Caption = '�I��(&O)'
        TabOrder = 2
        OnClick = btnCloseClick
      end
    end
    object btnOteage: TButton
      Left = 7
      Top = 5
      Width = 65
      Height = 25
      Caption = '����グ'
      TabOrder = 1
      OnClick = btnOteageClick
    end
  end
  object edtMain: TMemo
    Left = 0
    Top = 0
    Width = 465
    Height = 177
    Align = alClient
    Font.Charset = SHIFTJIS_CHARSET
    Font.Color = clBlack
    Font.Height = -13
    Font.Name = '�l�r �S�V�b�N'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 1
  end
end
