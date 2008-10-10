unit frmDebugU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids, ExtCtrls, Menus, CsvUtils2, ComCtrls, HEditor,
  hOleddEditor, EditorEx;

type
  TfrmDebug = class(TForm)
    panelBottom: TPanel;
    grdVar: TStringGrid;
    btnContinue: TButton;
    btnStep: TButton;
    btnClose: TButton;
    popDebug: TPopupMenu;
    N1: TMenuItem;
    Panel2: TPanel;
    Label1: TLabel;
    edtFind: TEdit;
    btnFind: TButton;
    MainMenu1: TMainMenu;
    E1: TMenuItem;
    mnuEval: TMenuItem;
    S1: TMenuItem;
    mnuScopeLocal: TMenuItem;
    mnuScopeGlobal: TMenuItem;
    mnuScopeGlobalLocal: TMenuItem;
    N2: TMenuItem;
    T1: TMenuItem;
    mnuEnumFunc: TMenuItem;
    mnuEnumVar: TMenuItem;
    chkViewLineNo: TCheckBox;
    mnuScopeUser: TMenuItem;
    mnuEnumGroup: TMenuItem;
    Splitter1: TSplitter;
    panelSrc: TPanel;
    Panel4: TPanel;
    lblInfo: TLabel;
    panelSrcEdit: TPanel;
    procedure btnCloseClick(Sender: TObject);
    procedure btnContinueClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnFindClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure mnuEvalClick(Sender: TObject);
    procedure mnuScopeLocalClick(Sender: TObject);
    procedure mnuScopeGlobalClick(Sender: TObject);
    procedure mnuScopeGlobalLocalClick(Sender: TObject);
    procedure mnuEnumFuncClick(Sender: TObject);
    procedure mnuEnumVarClick(Sender: TObject);
    procedure btnStepClick(Sender: TObject);
    procedure chkViewLineNoClick(Sender: TObject);
    procedure mnuScopeUserClick(Sender: TObject);
    procedure mnuEnumGroupClick(Sender: TObject);
    procedure grdVarDblClick(Sender: TObject);
    procedure lblInfoClick(Sender: TObject);
    procedure panelBottomResize(Sender: TObject);
  private
    { Private �錾 }
    csvCmd: TCsvSheet;
    scope: string;
  public
    { Public �錾 }
    edtMain:TEditorEx;
    procedure EnumVar;
    procedure data2grid;
    procedure getSource;
  end;

var
  FfrmDebug: TfrmDebug = nil;

function frmDebug(Parent: TForm) : TfrmDebug;

implementation

uses frmNakoU, dnako_import, dnako_import_types, unit_string, frmMemoU,
  vnako_function, NadesikoFountain;

{$R *.dfm}

function frmDebug(Parent: TForm) : TfrmDebug;
begin
  if FfrmDebug = nil then FfrmDebug := TfrmDebug.Create(Parent);
  Result := FfrmDebug;
end;

procedure TfrmDebug.btnCloseClick(Sender: TObject);
begin
  Halt;
end;

procedure TfrmDebug.btnContinueClick(Sender: TObject);
begin
  nako_continue;
  Close;
end;

procedure TfrmDebug.EnumVar;
var
  p: PHiValue;
  sl: TStringList;
  i, j: Integer;
  s, cmd, e, txt: string;
begin
  s := '�w'+scope+'�x�̕ϐ��񋓁B';
  try
    p := nako_eval(PChar(s));
    txt := hi_str(p);
    if (p <> nil)and(p.Registered = 0) then nako_var_free(p);
  except
  end;
  //
  csvCmd.Clear;
  sl := TStringList.Create;
  try
    sl.Text := txt;
    for i := 0 to sl.Count - 1 do
    begin
      s := sl.Strings[i];
      if Pos('=', s) > 0 then
      begin
        cmd := getToken_s(s, '=');
        e   := getToken_s(s, ')'); e := JReplace(e, '(', '');
        j := csvCmd.Count;
        if (e='�֐�') then
        begin
          if mnuEnumFunc.Checked = False then Continue;
        end else
        if (e='�O���[�v') then
        begin
          if mnuEnumGroup.Checked = False then Continue;
        end else
        begin
          if mnuEnumVar.Checked = False then Continue;
        end;
        csvCmd.Cells[0, j] := cmd;
        csvCmd.Cells[1, j] := e;
        csvCmd.Cells[2, j] := Trim(s);
      end;
    end;

    //
    data2grid;
  finally
    sl.Free;
  end;
end;

procedure TfrmDebug.FormCreate(Sender: TObject);
begin
  csvCmd := TCsvSheet.Create;
  scope := '�O���[�o�����[�J�����[�U�[';
  edtMain := TEditorEx.Create(panelSrcEdit);
  edtMain.Parent := panelSrcEdit;
  edtMain.Align := alClient;
  edtMain.Caret.TabSpaceCount := 4;
  edtMain.Marks.Underline.Visible := True;
  edtMain.Leftbar.Visible := False;
  edtMain.Margin.Left := 4;
  edtMain.ReadOnly := True;
  edtMain.Font.Size := 8;
  edtMain.Font.Name := '�l�r �S�V�b�N';
  edtMain.Fountain := TNadesikoFountain.Create(Self);
end;

procedure TfrmDebug.FormDestroy(Sender: TObject);
begin
  csvCmd.Free;
end;

procedure TfrmDebug.btnFindClick(Sender: TObject);
var
  i, j: Integer;
  s, key: string;
  c: TCsvSheet;
begin
  EnumVar;
  key := edtFind.Text;
  c := TCsvSheet.Create;
  try
    // csvCmd
    for i := 0 to csvCmd.Count - 1 do
    begin
      s := csvCmd.Cells[0, i];
      if (Pos(key, s) > 0)or(key='') then
      begin
        j := c.Count;
        c.Cells[0,j] := csvCmd.Cells[0,i];
        c.Cells[1,j] := csvCmd.Cells[1,i];
        c.Cells[2,j] := csvCmd.Cells[2,i];
      end;
    end;
    // �O���b�h�֔��f
    csvCmd.Assign(c);
    data2grid;
  finally
    c.Free;
  end;
end;

procedure TfrmDebug.FormShow(Sender: TObject);
begin
  Application.ProcessMessages;
  btnFindClick(nil);
  //
  getSource;
end;

procedure TfrmDebug.mnuEvalClick(Sender: TObject);
var
  s: string;
  p: PHiValue;
begin
  s := InputBox('�]��','�]��������������͂��Ă��������B', '');
  if s='' then Exit;
  p := nako_eval(PChar(s));
  ShowMessage('�]����������:'#13#10+hi_str(p));
end;

procedure TfrmDebug.mnuScopeLocalClick(Sender: TObject);
begin
  scope := '���[�J��';
  btnFindClick(nil);
end;

procedure TfrmDebug.mnuScopeGlobalClick(Sender: TObject);
begin
  scope := '�O���[�o��';
  btnFindClick(nil);
end;

procedure TfrmDebug.mnuScopeGlobalLocalClick(Sender: TObject);
begin
  scope := '�O���[�o��,���[�J��';
  btnFindClick(nil);
end;

procedure TfrmDebug.mnuEnumFuncClick(Sender: TObject);
begin
  mnuEnumFunc.Checked := not mnuEnumFunc.Checked;
  btnFindClick(nil);
end;

procedure TfrmDebug.mnuEnumVarClick(Sender: TObject);
begin
  mnuEnumVar.Checked := not mnuEnumVar.Checked;
  btnFindClick(nil);
end;

procedure TfrmDebug.btnStepClick(Sender: TObject);
begin
  // ���̍s��
  nako_DebugNextStop;
  Close;
end;

procedure TfrmDebug.chkViewLineNoClick(Sender: TObject);
begin
  nako_setDebugLineNo(chkViewLineNo.Checked);
  Application.ProcessMessages;
end;

procedure TfrmDebug.mnuScopeUserClick(Sender: TObject);
begin
  scope := '���[�J���O���[�o�����[�U�[';
  btnFindClick(nil);
end;

procedure TfrmDebug.mnuEnumGroupClick(Sender: TObject);
begin
  mnuEnumGroup.Checked := not mnuEnumGroup.Checked;
  btnFindClick(nil);
end;

procedure TfrmDebug.data2grid;
var
  i, j: Integer;
begin
  grdVar.RowCount := csvCmd.Count + 2;
  grdVar.Row := 1;
  //
  grdVar.Cells[0,0] := '���O';
  grdVar.Cells[1,0] := '�^';
  grdVar.Cells[2,0] := '���e';
  for i := 0 to csvCmd.Count - 1 do
  begin
    for j := 0 to 2 do
    begin
      grdVar.Cells[j, i + 1] := csvCmd.Cells[j, i];
    end;
  end;
  // ��s������
  grdVar.Cells[0, grdVar.RowCount - 1] := '';
  grdVar.Cells[1, grdVar.RowCount - 1] := '';
  grdVar.Cells[2, grdVar.RowCount - 1] := '';
end;

procedure TfrmDebug.grdVarDblClick(Sender: TObject);
var
  m: TfrmMemo;
  r: Integer;
begin
  r := grdVar.Row;
  if r < 0 then Exit;

  m := TfrmMemo.Create(self);
  try
    m.edtMain.Lines.Text := JReplace(grdVar.Cells[2,r],'{\n}',#13#10);
    ShowModalCheck(m, self);
  finally
    m.Free;
  end;
end;

procedure TfrmDebug.getSource;
var
  fileNo, lineNo: Integer;
  txt: string;
begin
  // ���s�s�̎擾
  try
    nako_getLineNo(@fileNo, @lineNo);
  except
    fileNo := -1; lineNo := 0;
  end;
  if (fileNo = 255)or(fileNo < 0) then
  begin
    // �\�[�X�̎擾�Ɏ��s
    lblInfo.Caption := '�\�[�X�͎擾�ł��܂���ł����B';
    edtMain.Lines.Text := '';
    Exit;
  end;
  lblInfo.Caption := 'file:' + IntToStr(fileNo) + ' line:' + IntToStr(lineNo);
  // �\�[�X�̎擾
  SetLength(txt, 65535);
  nako_getSourceText(fileNo, PChar(txt), Length(txt));
  //
  edtMain.Lines.Text := txt;
  edtMain.SetFocus;
  edtMain.SelStart := Pos(IntToStr(lineNo)+':', txt) - 1;
end;

procedure TfrmDebug.lblInfoClick(Sender: TObject);
begin
  getSource;
end;

procedure TfrmDebug.panelBottomResize(Sender: TObject);
begin
  btnClose.Left := panelBottom.ClientWidth - btnClose.Width - 8;
end;

end.
