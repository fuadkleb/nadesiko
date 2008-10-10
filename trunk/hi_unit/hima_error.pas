unit hima_error;

interface
//{$DEFINE ERROR_LOG}


uses
  Windows, SysUtils, hima_types, mmsystem;

type
  // �f�o�b�O.�\�[�X�R�[�h��� 32 bit
  TDebugInfo = packed record
    Flag    : Byte; // ���g�p
    FileNo  : Byte; // 0..255
    LineNo  : WORD; // 0..65535
  end;

  EHimaSyntax = class(Exception)
  public
    constructor Create(FileNo, LineNo: Integer; Msg: string; Args: array of const); overload;
    constructor Create(DInfo: TDebugInfo; Msg: string; Args: array of const); overload;
  end;
  EHimaRuntime = class(EHimaSyntax)
  end;

const
  // �����Ȃ��̃��b�Z�[�W
  ERR_NOPAIR_STRING   = '������u�v���Ή����Ă��܂���B';
  ERR_NOPAIR_STRING2  = '������w�x���Ή����Ă��܂���B';
  ERR_NOPAIR_STRING3  = '������ "..." ���Ή����Ă��܂���B';
  ERR_NOPAIR_STRING4  = '������ `...` ���Ή����Ă��܂���B';
  ERR_NOPAIR_COMMENT  = '�R�����g /* ... */ ���Ή����Ă��܂���B';
  ERR_NOPAIR_KAKU     = '�z��v�f [...] ���Ή����Ă��܂���B';
  ERR_NOPAIR_KAKKO    = '�J�b�R (...) ���Ή����Ă��܂���B';
  ERR_NOPAIR_NAMI     = '�g�J�b�R�o...�p���Ή����Ă��܂���B';
  ERR_INVALID_SIKI    = '�v�Z���̍����������ǂݎ��܂���B';
  ERR_SYNTAX          = '���@�̃G���[�B';
  ERR_STACK_OVERFLOW  = '�ċA�X�^�b�N�����e���x�𒴂��܂����B';
  ERR_SECURITY        = '�Z�L�����e�B�G���[�B';
  // �������̃��b�Z�[�W
  ERR_S_SOURCE_DUST   = '�v���O�������ɖ���`�̕����w%s�x������܂��B';
  ERR_S_UNDEFINED     = '����`�̒P��w%s�x������܂��B';
  ERR_S_UNDEF_OPTION  = '�w%s�x�͖���`�̎��s�I�v�V�����ł��B';
  ERR_S_UNDEF_MARK    = '�ˑR�L���w%s�x������܂��B�P�̂ł͈Ӗ��������܂���B';
  ERR_S_UNDEF_GROUP   = '�w%s�x�̓O���[�v�Ƃ��Ē�`����Ă��܂���B';
  ERR_S_SYNTAX        = '���@�G���[�B���̈ʒu�Łw%s�x�͎g���܂���B';
  ERR_S_STRICT_UNDEF  = '����`�̒P��w%s�x������܂��B�����ɐ錾���Ă��������B';
  ERR_S_VARINIT_UNDEF = '�P��w%s�x�����������ꂸ�Ɏg���܂����B';
  ERR_S_VAR_ELEMENT   = '�ϐ��w%s�x�̗v�f���ǂݎ��܂���B';
  ERR_S_DEF_FUNC      = '�֐��w%s�x�̐錾�ɕ��@�̊ԈႢ������܂��B';
  ERR_S_DEF_GROUP     = '�O���[�v�w%s�x�̐錾�ɕ��@�̊ԈႢ������܂��B';
  ERR_S_DEF_VAR       = '�ϐ��w%s�x�̒�`���Ԉ���Ă��܂��B';
  ERR_S_DLL_FUNCTION_EXEC = 'DLL�֐��w%s�x�̎��s���ɃG���[���N���܂����B';
  ERR_S_FUNCTION_EXEC = '�֐��w%s�x�̎��s���ɃG���[���N���܂����B';
  ERR_S_CALL_FUNC     = '�֐��w%s�x�̌Ăяo���ŕ��@�̊ԈႢ������܂��B';
  // �������Q�̃��b�Z�[�W
  ERR_SS_FUNC_ARG     = '�֐��w%s�x�̈����w%s�x���s�����Ă��܂��B';
  ERR_SS_UNDEF_GROUP  = '�O���[�v�w%s�x�ɂ̓����o�[�w%s�x�����݂��܂���B�����m�F���Ă��������B';

  //----------------------------------------------------------------------------
  // ���s���̃G���[(�����Ȃ��j
  ERR_RUN_CALC        = '�v�Z���Ɍv�Z���̌��������܂����B';
  // ���s���̃G���[�i���s����j
  ERR_S_RUN_VALUE     = '�ϐ��w%s�x�̒l���擾�ł��܂���B';

var
  HimaErrorMessage: string;
  HimaFileList: THStringList; // �Ђ܂��Ŏg���t�@�C���̊Ǘ��p

function setSourceFileName(fname: string): Integer; // �\�[�X�t�@�C����o�^����
function ErrFmt(FileNo, LineNo: Integer; Msg: string; Args: array of const): string;

procedure debugi(i:Integer);
procedure debugs(s:string);

var useErrorLog:Boolean = False; // <--- for DEBUG
var FileErrLog: TextFile;
procedure errLog(s: string);

implementation

uses hima_string, unit_string, hima_variable, hima_system;

var
  HimaLog: string = '';

procedure debugi(i:Integer);
var s: string;
begin
  s := IntToStr(i);
  MessageBox(0, PChar(s), 'debug', MB_OK);
end;
procedure debugs(s:string);
begin
  MessageBox(0, PChar(s), 'debug', MB_OK);
end;

function setSourceFileName(fname: string): Integer;
begin
  Result := HimaFileList.IndexOf(fname);
  if Result < 0 then
  begin
    Result := HimaFileList.Add(fname);
  end;
end;

var last_err_result : string = '';
var last_err_file   : string = '';

function ErrFmt(FileNo, LineNo: Integer; Msg: string; Args: array of const): string;
var
  fname, s, file_info: string;
const
  err_h    = '[�G���[] ';
  err_same = '�O��Ɠ��l�̗��R�ŃG���[�B';
begin
  //=== �t�@�C�����̎擾
  if FileNo < 0 then
  begin
    fname := '�]����';
  end else
  begin
    // �t�@�C�����𓾂�
    if FileNo < HimaFileList.Count then
    begin
      try
        fname := ExtractFileName(HimaFileList.Strings[FileNo]);
      except fname := ''; end;
    end else
    begin
      fname := '�]����';
    end;
  end;
  //=== �G���[���b�Z�[�W�ƈ�����g�ݍ��킹��
  try
    s := Format(Msg, Args);
  except
    s := Msg;
  end;

  //=== �t�@�C���ԍ��ƃG���[���b�Z�[�W��g�ݗ��Ă�
  file_info := fname + '(' + IntToStr(LineNo) + '): ';

  // �d�����镔�����폜

  if last_err_result <> '' then // �O��Ƃ̊��S�d�����폜
  begin
    s := JReplace(s, last_err_result, '');
  end;

  if (Copy(s, 1, Length(err_h))=err_h) then // head
  begin
    getToken_s(s, ':'); // �w�b�_���΂�����؂���
  end;

  s := Trim(s);
  if (s = '')and(HimaErrorMessage <> '') then
  begin
    s := err_same;
  end;

  //-------------------
  // ���ʂ�Ԃ�
  Result := err_h + file_info + s;
  last_err_result := Result;

  // �����G���[���b�Z�[�W���ŏd�����Ȃ���Βǉ�
  if (Pos(Result, HimaErrorMessage) = 0) then
  begin
    if Pos(err_same, Result) > 0 then // ���������O��ƈႤ�s�Ȃ�o��
    begin
      if last_err_file = file_info then Exit;
    end;
    HimaErrorMessage := HimaErrorMessage + Result + #13#10;
    last_err_file := file_info;
  end;

end;

var
  LogTime: DWORD;
  fOpen: Boolean = False;

function TempDir:string;
var
 TempTmp:array[0..MAX_PATH] of Char;
begin
 GetTemppath(MAX_PATH,TempTmp);
 Result:=StrPas(TempTmp);
 if Copy(Result,Length(Result),1)<>'\' then Result := Result + '\';
end;

procedure errLog(s: string);
var
  logname: string;
begin
  if not useErrorLog then Exit;
  if not fOpen then
  begin
    logname := TempDir + 'nakolog_' + FormatDateTime('hhnnss',Now) + '.txt';
    AssignFile(FileErrLog, logname);
    Rewrite(FileErrLog);
    LogTime := timeGetTime;
    fOpen := True;
  end;
  Writeln(
    FileErrLog,
    Format('%0.5d',[(timeGetTime-LogTime)]) + ':' + s
  );
end;

{ EHimaSyntax }

constructor EHimaSyntax.Create(FileNo, LineNo: Integer; Msg: string;
  Args: array of const);
begin
  inherited Create( ErrFmt(FileNo, LineNo, Msg, Args) );
  hi_setStr(HiSystem.ErrMsg, HimaErrorMessage);
end;

constructor EHimaSyntax.Create(DInfo: TDebugInfo; Msg: string;
  Args: array of const);
begin
  inherited Create( ErrFmt(DInfo.FileNo, DInfo.LineNo, Msg, Args) );
  hi_setStr(HiSystem.ErrMsg, HimaErrorMessage);
end;

initialization
  HimaFileList := THStringList.Create;

finalization
  FreeAndNil(HimaFileList);
  if useErrorLog then CloseFile(FileErrLog);


end.
