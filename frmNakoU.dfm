object frmNako: TfrmNako
  Left = 346
  Top = 133
  Width = 606
  Height = 407
  Caption = #12394#12391#12375#12371
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poDefaultPosOnly
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnPaint = FormPaint
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 12
  object timerRunScript: TTimer
    Enabled = False
    Interval = 1
    OnTimer = timerRunScriptTimer
    Left = 176
    Top = 40
  end
  object AppEvent: TApplicationEvents
    OnActivate = AppEventActivate
    OnDeactivate = AppEventDeactivate
    OnIdle = AppEventIdle
    OnMinimize = AppEventMinimize
    OnRestore = AppEventRestore
    Left = 144
    Top = 40
  end
  object dlgFont: TFontDialog
    Font.Charset = SHIFTJIS_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
    Font.Style = []
    Options = []
    Left = 16
    Top = 40
  end
  object dlgColor: TColorDialog
    Left = 48
    Top = 40
  end
  object dlgPrinter: TPrinterSetupDialog
    Left = 80
    Top = 40
  end
  object edtPropNormal: TEditorExProp
    Color = clWindow
    Caret.AutoCursor = True
    Caret.AutoIndent = True
    Caret.BackSpaceUnIndent = True
    Caret.Cursors.DefaultCursor = crIBeam
    Caret.Cursors.DragSelCursor = crDrag
    Caret.Cursors.DragSelCopyCursor = 1959
    Caret.Cursors.InSelCursor = crDefault
    Caret.Cursors.LeftMarginCursor = 1958
    Caret.Cursors.TopMarginCursor = crDefault
    Caret.FreeCaret = False
    Caret.FreeRow = False
    Caret.InTab = False
    Caret.KeepCaret = False
    Caret.LockScroll = False
    Caret.NextLine = False
    Caret.PrevSpaceIndent = False
    Caret.RowSelect = True
    Caret.SelDragMode = dmAutomatic
    Caret.SelMove = True
    Caret.SoftTab = False
    Caret.Style = csDefault
    Caret.TabIndent = False
    Caret.TabSpaceCount = 8
    Caret.TokenEndStop = False
    Font.Charset = SHIFTJIS_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'FixedSys'
    Font.Style = []
    HitStyle = hsSelect
    Imagebar.DigitWidth = 2
    Imagebar.LeftMargin = 2
    Imagebar.MarkWidth = 0
    Imagebar.RightMargin = 2
    Imagebar.Visible = True
    Leftbar.BkColor = clSilver
    Leftbar.Color = clBlack
    Leftbar.Column = 4
    Leftbar.Edge = True
    Leftbar.LeftMargin = 2
    Leftbar.RightMargin = 4
    Leftbar.ShowNumber = True
    Leftbar.ShowNumberMode = nmRow
    Leftbar.Visible = True
    Leftbar.ZeroBase = False
    Leftbar.ZeroLead = False
    Margin.Character = 0
    Margin.Left = 6
    Margin.Line = 0
    Margin.Top = 2
    Marks.EofMark.Color = clGray
    Marks.EofMark.Visible = False
    Marks.RetMark.Color = clGray
    Marks.RetMark.Visible = False
    Marks.WrapMark.Color = clGray
    Marks.WrapMark.Visible = False
    Marks.HideMark.Color = clGray
    Marks.HideMark.Visible = False
    Marks.Underline.Color = clGray
    Marks.Underline.Visible = False
    Ruler.BkColor = clSilver
    Ruler.Color = clBlack
    Ruler.Edge = True
    Ruler.GaugeRange = 10
    Ruler.MarkColor = clBlack
    Ruler.Visible = True
    ScrollBars = ssBoth
    Speed.CaretVerticalAc = 2
    Speed.InitBracketsFull = False
    Speed.PageVerticalRange = 2
    Speed.PageVerticalRangeAc = 2
    View.Brackets = <>
    View.Colors.Ank.BkColor = clNone
    View.Colors.Ank.Color = clNone
    View.Colors.Ank.Style = []
    View.Colors.Comment.BkColor = clNone
    View.Colors.Comment.Color = clNone
    View.Colors.Comment.Style = []
    View.Colors.DBCS.BkColor = clNone
    View.Colors.DBCS.Color = clNone
    View.Colors.DBCS.Style = []
    View.Colors.Hit.BkColor = clNone
    View.Colors.Hit.Color = clNone
    View.Colors.Hit.Style = []
    View.Colors.Int.BkColor = clNone
    View.Colors.Int.Color = clNone
    View.Colors.Int.Style = []
    View.Colors.Mail.BkColor = clNone
    View.Colors.Mail.Color = clNone
    View.Colors.Mail.Style = []
    View.Colors.Reserve.BkColor = clNone
    View.Colors.Reserve.Color = clNone
    View.Colors.Reserve.Style = []
    View.Colors.Select.BkColor = clNavy
    View.Colors.Select.Color = clWhite
    View.Colors.Select.Style = []
    View.Colors.Str.BkColor = clNone
    View.Colors.Str.Color = clNone
    View.Colors.Str.Style = []
    View.Colors.Symbol.BkColor = clNone
    View.Colors.Symbol.Color = clNone
    View.Colors.Symbol.Style = []
    View.Colors.Url.BkColor = clNone
    View.Colors.Url.Color = clNone
    View.Colors.Url.Style = []
    View.ControlCode = False
    View.Mail = False
    View.Url = False
    WordWrap = False
    WrapOption.FollowRetMark = False
    WrapOption.FollowPunctuation = False
    WrapOption.FollowStr = #12289#12290#65292#65294#12539#65311#65281#12443#12444#12541#12542#12445#12446#12293#12540#65289#65341#65373#12301#12303'!),.:;?]}'#65377#65379#65380#65381#65392#65438#65439
    WrapOption.Leading = False
    WrapOption.LeadStr = #65288#65339#65371#12300#12302'([{'#65378
    WrapOption.PunctuationStr = #12289#12290#65292#65294',.'#65377#65380
    WrapOption.WordBreak = False
    WrapOption.WrapByte = 80
    ExMarks.DBSpaceMark.Color = clGray
    ExMarks.DBSpaceMark.Visible = False
    ExMarks.SpaceMark.Color = clGray
    ExMarks.SpaceMark.Visible = False
    ExMarks.TabMark.Color = clGray
    ExMarks.TabMark.Visible = False
    ExMarks.FindMark.Color = clGray
    ExMarks.FindMark.Visible = False
    ExMarks.Hit.BkColor = clNone
    ExMarks.Hit.Color = clNone
    ExMarks.Hit.Style = []
    ExMarks.ParenMark.Color = clGray
    ExMarks.ParenMark.Visible = False
    ExMarks.CurrentLine.Color = clGray
    ExMarks.CurrentLine.Visible = False
    ExMarks.DigitLine.Color = clGray
    ExMarks.DigitLine.Visible = False
    ExMarks.ImageLine.Color = clGray
    ExMarks.ImageLine.Visible = False
    ExMarks.Img0Line.Color = clGray
    ExMarks.Img0Line.Visible = False
    ExMarks.Img1Line.Color = clGray
    ExMarks.Img1Line.Visible = False
    ExMarks.Img2Line.Color = clGray
    ExMarks.Img2Line.Visible = False
    ExMarks.Img3Line.Color = clGray
    ExMarks.Img3Line.Visible = False
    ExMarks.Img4Line.Color = clGray
    ExMarks.Img4Line.Visible = False
    ExMarks.Img5Line.Color = clGray
    ExMarks.Img5Line.Visible = False
    ExMarks.EvenLine.Color = clGray
    ExMarks.EvenLine.Visible = False
    ExSearchOptions = []
    VerticalLines = <>
    Left = 112
    Top = 40
  end
end
