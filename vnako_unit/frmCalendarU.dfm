object frmCalendar: TfrmCalendar
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #26085#20184#12398#36984#25246
  ClientHeight = 266
  ClientWidth = 329
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDefault
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object grdCal: TMonthCalendar
    Left = 0
    Top = 0
    Width = 329
    Height = 266
    Align = alClient
    AutoSize = True
    Date = 0.897526979169924700
    TabOrder = 0
    OnClick = grdCalClick
  end
  object edtDate: TDateTimePicker
    Left = 8
    Top = 8
    Width = 242
    Height = 21
    Date = 40029.368635821760000000
    Time = 40029.368635821760000000
    TabOrder = 1
    OnChange = edtDateChange
    OnKeyPress = edtDateKeyPress
  end
  object btnOk: TButton
    Left = 256
    Top = 8
    Width = 57
    Height = 21
    Caption = #27770#23450'(&O)'
    TabOrder = 2
    OnClick = btnOkClick
  end
end
