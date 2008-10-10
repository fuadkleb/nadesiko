unit dll_file_function;

interface
uses
  windows, dnako_import, dnako_import_types, dll_plugin_helper,
  unit_pack_files, SysUtils, Classes, shellapi, registry, inifiles,
  shlobj, Variants, ActiveX, hima_types, messages;

const
  NAKOFILE_DLL_VERSION = '1.5041';

type
  THiSystemDummy = class
  public
    constructor Create;
    function mixReader: TFileMixReader;
    function Sore: PHiValue;
  end;


procedure RegistFunction;
function ExpandEnvironmentStrDelphi(s: string): string;
// MixFile���`�F�b�N
procedure CheckMixFile(var fname: string);

implementation

uses unit_file, unit_windows_api, unit_string, hima_stream, StrUnit,
  mini_file_utils, unit_archive, LanUtil, unit_text_file, ComObj,
  unit_kanrenduke,
  EasyMasks;

var
  HiSystem: THiSystemDummy;

procedure CheckMixFile(var fname: string);
var
  s: THMemoryStream;
  f: string;
begin
  // mix file ������
  if HiSystem.mixReader <> nil then
  if HiSystem.mixReader.ReadFile(fname, s) then
  begin
    f := TempDir + ExtractFileName(fname);
    s.SaveToFile(f);
    fname := f;
    s.Free;
    Exit;
  end;

  CheckFileExists(fname);
end;


function ExpandEnvironmentStrDelphi(s: string): string;
var
  tmp: string;
begin
  SetLength(tmp, 4096);
  ExpandEnvironmentStrings(PChar(s), PChar(tmp), 4096);
  Result := PChar(tmp);
end;

function getNakoFileDllVersion(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(NAKOFILE_DLL_VERSION);
end;

function sys_saveAll(args: DWORD): PHiValue; stdcall;
var
  s, f: PHiValue;
  fname, str: string;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  f := nako_getFuncArg(args, 1);

  if s <> nil then str := hi_str(s) else str := hi_str(HiSystem.Sore);
  fname := hi_str(f);

  // (2) �f�[�^�̏���
  FileSaveAll(str, fname);

  // (3) �߂�l��ݒ�
  Result := nil;
end;

function sys_saveAllAdd(args: DWORD): PHiValue; stdcall;
var
  s, f: PHiValue;
  fname, str, ss: string;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  f := nako_getFuncArg(args, 1);

  if s <> nil then str := hi_str(s) else str := hi_str(HiSystem.Sore);
  fname := hi_str(f);
  if CheckFileExists(fname) then
  begin
    ss := FileLoadAll(fname);
  end else
  begin
    ss := '';
  end;

  // (2) �f�[�^�̏���
  FileSaveAll(ss + str, fname);

  // (3) �߂�l��ݒ�
  Result := nil;
end;

function sys_loadAll(args: DWORD): PHiValue; stdcall;
var
  v, f: PHiValue;
  fname, str: string;
begin

  // (1) �����̎擾
  v := nako_getFuncArg(args, 0);
  f := nako_getFuncArg(args, 1);

  fname := hi_str(f);

  // (2) �f�[�^�̏���
  try
    if (HiSystem.mixReader = nil)or
      (not HiSystem.mixReader.ReadFileAsString(fname, str)) then
    begin
      str := FileLoadAll(fname);
    end;
  except
    raise; // ��O�̍Đ���
  end;
  // (3) �߂�l��ݒ�
  Result := hi_var_new;
  hi_setStr(Result, str);
  if v <> nil then nako_varCopyData(Result, v);
end;

function sys_loadEveryLine(args: DWORD): PHiValue; stdcall;
var
  v, f: PHiValue;
  fname, s: string;
  h: TKTextFileStream;
begin
  // (1) �����̎擾
  v := nako_getFuncArg(args, 0); // �n���h��
  f := nako_getFuncArg(args, 1); // �t�@�C����

  fname := hi_str(f);

  // (2) �f�[�^�̏���
  //CheckMixFile(fname);
  if not CheckFileExists(fname) then raise Exception.Create('�t�@�C����������܂���B"'+fname+'"');

  // (3) �߂�l��ݒ� // Create �����n���h���� �w�����x�\���̒��Ŏ����I�ɕ���
  h := TKTextFileStream.Create(fname, fmOpenRead or fmShareDenyWrite);

  s := 'TKTextFileStream::' + IntToStr(Integer(h));

  Result := hi_newStr(s);

  // v �Ɋi�[
  if v <> nil then
  begin
    hi_setStr(v, s);
  end;
end;

function sys_CloseEveryLine(args: DWORD): PHiValue; stdcall;
var
  ph: PHiValue;
  h: TKTextFileStream;
begin
  // (1) �����̎擾
  ph := nako_getFuncArg(args, 0); // �n���h��

  h := TKTextFileStream(hi_int(ph));
  FreeAndNil(h);

  // (3) �߂�l��ݒ�
  Result := nil;
end;

function sys_pathFlagAdd(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue; str: string;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s = nil then s := nako_getSore;

  // (2) �f�[�^�̏���
  str := hi_str(s);
  str := CheckPathYen(str);

  // (3) �߂�l��ݒ�
  Result := hi_newStr(str);
end;

function sys_pathFlagDel(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue; str: string;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s = nil then s := nako_getSore;

  // (2) �f�[�^�̏���
  str := hi_str(s);
  str := CheckPathYen(str);
  System.Delete(str, Length(str), 1);

  // (3) �߂�l��ݒ�
  Result := hi_newStr(str);
end;

function sys_StrtoFileName(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue; str, ret: string;
  i: Integer;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s = nil then s := nako_getSore;
(*
$�@�@#�@�@%�@�@@�@�@!�@�@^
-(�}�C�i�X�L��)�@�@_(�A���_�|�X�R�A)
(�@�@)�@�@{�@�@}�@�@'(���p��)
*)
  // (2) �f�[�^�̏���
  str := hi_str(s); ret := '';
  i := 1;
  while i <= Length(str) do
  begin
    if str[i] in LeadBytes then
    begin
      ret := ret + str[i] + str[i+1];
      Inc(i, 2);
    end else
    begin
      case str[i] of
        // �����A���t�@�x�b�g
        '0'..'9','a'..'z','A'..'Z':
          begin
            ret := ret + str[i];
          end;
        // �L�������ǃt�@�C�����Ƃ��Ďg�������
        '$','#','%','@','!','^','~','(',')','{','}','-','_',' ','.':
          begin
            ret := ret + str[i];
          end;
        // �g���Ȃ�
          else
          begin
            ret := ret + convToFull(str[i]);
          end;
      end;
      Inc(i);
    end;
  end;

  // (3) �߂�l��ݒ�
  Result := hi_newStr(ret);
end;


function sys_StrtoFileNameUnix(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue; str, ret, ch: string;
  i: Integer;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s = nil then s := nako_getSore;

  // (2) �f�[�^�̏���
  str := hi_str(s); ret := '';
  i := 1;
  while i <= Length(str) do
  begin
    // UNIX�ł͑S�p�͕s�Ȃ̂łƂ肠�������p�ɕϊ����Ă݂�
    if str[i] in LeadBytes then
    begin
      ch := convToHalf(str[i] + str[i+1]);
      if Length(ch) >= 2 then
      begin
        // �����������E�E�E���p�ɕϊ��ł��Ȃ�
        // �����R�[�h�ɒ���
        ret := ret + IntToHex(Ord(str[i]),2) + IntToHex(Ord(str[i+1]),2);
        Inc(i,2); Continue;
      end;
      Inc(i, 2);
    end else
    begin
      ch := str[i];
      Inc(i);
    end;
    if ch = '' then Continue;

    if ch[1] in ['0'..'9','a'..'z','A'..'Z','-','_','.'] then
    begin
      ret := ret + ch[1];
    end else
    begin
      ret := ret + '_';
    end;
  end;

  // (3) �߂�l��ݒ�
  Result := hi_newStr(ret);
end;

function sys_exec(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue; str: string;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s = nil then s := nako_getSore;

  // (2) �f�[�^�̏���
  str := hi_str(s);
  _getEmbedFile(str); // �����\�Ȃ���s�t�@�C��������o��
  if 31 >= WinExec(PChar(str), SW_SHOW) then
  begin
    // ���s�Ȃ�
    ShellExecute(0, 'open', PChar(str), '','', SW_SHOWNORMAL);
  end;
  // (3) �߂�l��ݒ�
  Result := nil;
end;


function sys_exec_wait(args: DWORD): PHiValue; stdcall;
var
  fname: string;
begin
  // (1) �����̎擾
  fname := getArgStr(args, 0, True);

  // (2) �f�[�^�̏���
  _getEmbedFile(fname); // �����\�Ȃ���s�t�@�C��������o��
  RunAndWait(fname);

  // (3) �߂�l��ݒ�
  Result := nil;
end;


function sys_exec_open_hide(args: DWORD): PHiValue; stdcall;
var
  fname: string;
begin
  // (1) �����̎擾
  fname := getArgStr(args, 0, True);

  // (2) �f�[�^�̏���
  _getEmbedFile(fname); // �����\�Ȃ���s�t�@�C��������o��
  if 31 >= WinExec(PChar(fname), SW_HIDE) then
  begin
    // ���s�Ȃ�
    ShellExecute(0, 'open', PChar(fname), '','', SW_HIDE);
  end;

  // (3) �߂�l��ݒ�
  Result := nil;
end;


function sys_exec_wait_hide(args: DWORD): PHiValue; stdcall;
var
  fname: string;
begin
  // (1) �����̎擾
  fname := getArgStr(args, 0, True);

  _getEmbedFile(fname); // �����\�Ȃ���s�t�@�C��������o��
  RunAndWait(fname, True);

  // (3) �߂�l��ݒ�
  Result := nil;
end;

function sys_exec_command(args: DWORD): PHiValue; stdcall;
const
  BUF_LEN = 8192;
var
  ParentPipe,ChildPipe: TPipe;
  res: string;
  buf: array[1..BUF_LEN] of Char;
  len,cnt: Cardinal;
  hProcess: Cardinal;
  fname: string;
label
  endloop;
begin
  fname := getArgStr(args, 0, True);
  hProcess := RunAppWithPipe(fname, True,ParentPipe,ChildPipe);

  res := '';
  cnt := 0;

  while WaitForSingleObject(hProcess,10) <> WAIT_OBJECT_0 do
  begin
    FlushFileBuffers(ParentPipe.StdOut);
    PeekNamedPipe(ParentPipe.StdOut, nil, 0, nil, @len, nil);
    if len > 0 then
    begin
      cnt := 0;
      ReadFile(ParentPipe.StdOut,buf,BUF_LEN,len,nil);
      if len = BUF_LEN then
        res := res + buf
      else
        res := res + Copy(buf,1,len);
    end else
    begin
      Inc(cnt);
      if cnt > 3000 then
        goto endloop;
    end;
  end;
  repeat
    PeekNamedPipe(ParentPipe.StdOut, nil, 0, nil, @len, nil);
    if len > 0 then
    begin
      ReadFile(ParentPipe.StdOut,buf,BUF_LEN,len,nil);
      if len = BUF_LEN then
        res := res + buf
      else
        res := res + Copy(buf,1,len);
    end;
  until len = 0;
  //MessageBox(0,PChar(IntTOStr(GetLastError)),'',0);

  endloop:

  CloseHandle(ParentPipe.StdIn);
  CloseHandle(ParentPipe.StdOut);
  CloseHandle(ParentPipe.StdErr);
  CloseHandle(ChildPipe.StdIn);
  CloseHandle(ChildPipe.StdOut);
  CloseHandle(ChildPipe.StdErr);
  CloseHandle(hProcess);
  // (3) �߂�l��ݒ�
  Result := hi_newStr(res);
end;

function sys_exec_admin(args: DWORD): PHiValue; stdcall;
var
  s: string;
  f, arg: string;
begin
  s := Trim(getArgStr(args, 0, True));
  if Copy(s,1,1) = '"' then
  begin
    System.Delete(s,1,1);
    f := StrUnit.GetToken('"', s);
    arg := s;
  end else
  begin
    f := StrUnit.GetToken(' ', s);
    arg := s;
  end;
  _getEmbedFile(f); // �����\�Ȃ���s�t�@�C��������o��
  RunAsAdmin(nako_getMainWindowHandle, f, arg);
  Result := nil;
end;

function sys_exec_exp(args: DWORD): PHiValue; stdcall;
var
  s: string;
  h: HWND;
begin
  // (1) �����̎擾
  s := getArgStr(args, 0, True);
  h := nako_getMainWindowHandle;

  // (2) �f�[�^�̏���
  ShellExecute(
    h,
    'explore',
    PChar(s), '', '', SW_SHOWNORMAL);

  // (3) �߂�l��ݒ�
  Result := nil;
end;

function sys_setCurDir(args: DWORD): PHiValue; stdcall;
var s: PHiValue;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s = nil then s := nako_getSore;
  // (2) �f�[�^�̏���
  SetCurrentDir(hi_str(s));
  // (3) �߂�l��ݒ�
  Result := nil;
end;

function sys_getCurDir(args: DWORD): PHiValue; stdcall;
var
  s: string;
begin
  // (1) �����̎擾
  // (2) �f�[�^�̏���
  // (3) �߂�l��ݒ�
  Result := hi_var_new;
  s := CheckPathYen( GetCurrentDir );
  hi_setStr(Result, s);
end;

function sys_makeDir(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  a: string;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  // (2) �f�[�^�̏���
  try
    a := hi_str(s);
    if Pos('\', a) > 0  then ForceDirectories(a)
                        else MkDir(a);
  except on e: Exception do
    raise Exception.Create('�t�H���_�w' + hi_str(s) + '�x���쐬�ł��܂���B���R��,' + e.Message);
  end;
  // (3) �߂�l��ݒ�
  Result := nil;
end;

function sys_removeDir(args: DWORD): PHiValue; stdcall;
var ps: PHiValue; s: string;
begin
  // (1) �����̎擾
  ps := nako_getFuncArg(args, 0);
  s  := hi_str(ps);

  // (2) �f�[�^�̏���
  s := CheckPathYen(s);

  // �Ō��\�����
  System.Delete(s, Length(s), 1);
  SHFileDelete(s); // == RemoveDir(hi_str(s));(RemoveDir�ł͐���������)

  // (3) �߂�l��ݒ�
  Result := nil;
end;


function sys_enumFiles(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  path, f: string;
  g: THStringList;
  i: Integer;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s=nil then path := GetCurrentDir
           else path := hi_str(s);

  // (2) �f�[�^�̏���
  g := EnumFiles(path);

  // (3) ���ʂ̑��
  Result := hi_var_new;
  nako_ary_create(Result);
  for i := 0 to g.Count - 1 do
  begin
    f := g.Strings[i];
    if f = '' then Continue;
    s := hi_newStr(f);
    nako_ary_add(Result, s);
  end;
  //FileSaveAll(g.Text, 'test.txt');
  //FileSaveAll(hi_str(Result), 'test.txt');
  g.Free;
end;

function sys_enumAllFiles(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  path: string;
  g: THStringList;
  i: Integer;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s=nil then path := CheckPathYen( GetCurrentDir )
           else path := hi_str(s);

  // (2) �f�[�^�̏���
  g := EnumAllFiles(path);

  // (3) ���ʂ̑��
  Result := hi_var_new;
  nako_ary_create(Result);
  for i := 0 to g.Count - 1 do
  begin
    nako_ary_add(
      Result,
      hi_newStr(g.Strings[i])
    );
  end;

  g.Free;
end;


function sys_enumAllDir(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  path: string;
  g: THStringList;
  i: Integer;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s=nil then path := CheckPathYen( GetCurrentDir )
           else path := hi_str(s);

  // (2) �f�[�^�̏���
  g := EnumAllDirs(path);

  // (3) ���ʂ̑��
  Result := hi_var_new;
  nako_ary_create(Result);
  for i := 0 to g.Count - 1 do
  begin
    nako_ary_add(
      Result,
      hi_newStr(g.Strings[i])
    );
  end;

  g.Free;
end;


function sys_enumDirs (args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  path, n: string;
  g: THStringList;
  i: Integer;
begin
  Result := hi_var_new;
  nako_ary_create(Result);

  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s=nil then path := CheckPathYen( GetCurrentDir )
           else path := hi_str(s);

  if Copy(path, Length(path), 1) = '\' then path := path + '*';

  // (2) �f�[�^�̏���
  g := EnumDirs(path);
  for i := 0 to g.Count - 1 do
  begin
    n := g.Strings[i];
    // (3) �߂�l��ݒ�
    nako_ary_add(Result, hi_newStr(n));
  end;

end;

function sys_FileExists (args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  fname: string;
begin
  Result := hi_var_new;

  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  fname := hi_str(s);

  // (2) �f�[�^�̏���
  // (3) �߂�l��ݒ�

  // �t�H���_�H
  if DirectoryExists(fname) then
  begin
    hi_setBool(Result, True); Exit;
  end;

  // �t�@�C��
  if FileExists(fname) then
  begin
    hi_setBool(Result, True);
  end else
  begin
    hi_setBool(Result, False);
  end;
end;

function sys_ExistsDir (args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  fname: string;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  fname := hi_str(s);

  // �t�H���_�H
  Result := hi_newBool(DirectoryExists(fname));
end;

function sys_getLongFileName(args: DWORD): PHiValue; stdcall;
var
  fname: string;
begin
  fname := getArgStr(args, 0, True);
  Result := hi_newStr(ShortToLongFileName(fname));
end;
function sys_getShortFileName(args: DWORD): PHiValue; stdcall;
var
  fname: string;
begin
  fname := getArgStr(args, 0, True);
  Result := hi_newStr(LongToShortFileName(fname));
end;


function sys_fileCopy(args: DWORD): PHiValue; stdcall;
var
  pa, pb: PHiValue;
  sa, sb: string;
begin

  // (1) �����̎擾
  pa := nako_getFuncArg(args, 0);
  pb := nako_getFuncArg(args, 1);

  sa  := hi_str(pa);
  sb  := hi_str(pb);

  dll_plugin_helper._getEmbedFile(sa); // �����\�Ȃ���s�t�@�C��������o��

  // �p�X���Ȃ��ƌ�쓮���N�����̂Ńp�X��⊮���Ă��
  CheckMixFile(sa);
  if (Pos(':\', sa) = 0)and(Pos('\\', sa) = 0) then // �t���p�X�w��ł͂Ȃ�
  begin
    sa := CheckPathYen(GetCurrentDir) + sa;
  end;
  if (Pos(':\', sb) = 0)and(Pos('\\', sb) = 0) then // �t���p�X�w��ł͂Ȃ�
  begin
    sb := CheckPathYen(GetCurrentDir) + sb;
  end;

  // sa/sb ���t�H���_���H ... �t�H���_�Ȃ�Ō��'\'�͍폜
  if DirectoryExists(sa) then
  begin
    sa := CheckPathYen(sa);
    System.Delete(sa, Length(sa), 1);
  end;
  if DirectoryExists(sb) then
  begin
    sb := CheckPathYen(sb);
    System.Delete(sb, Length(sb), 1);
  end;

  // (2) �f�[�^�̏���
  unit_file.MainWindowHandle := nako_getMainWindowHandle;
  if not SHFileCopy(sa, sb, '�t�@�C���R�s�[') then
  begin
    raise Exception.Create('�u'+sa+'�v����u'+sb+'�v�փt�@�C���R�s�[�Ɏ��s�B');
  end;

  // (3) �߂�l��ݒ�
  Result := nil;
end;

function sys_fileCopyEx(args: DWORD): PHiValue; stdcall;
var
  extList: TStringList;
  blackList: TStringList;


  function _checkBlackList(path: string): Boolean;
  var
    i: Integer;
    mask: string;
  begin
    Result := False;
    for i := 0 to blackList.Count - 1 do
    begin
      mask := blackList.Strings[i];
      if MatchesMask(path, mask) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;

  function _match(path: string): Boolean;
  var
    i: Integer;
    mask: string;
  begin
    Result := False;
    for i := 0 to extList.Count - 1 do
    begin
      mask := extList.Strings[i];
      if MatchesMask(path, mask) then
      begin
        if _checkBlackList(path) then
        begin
          Continue;
        end;
        Result := True;
        Exit;
      end;
    end;
  end;

  procedure _copy(fromDir, toDir: string);
  var
    rec: TSearchRec;
    fromFile, toFile: string;
  begin
    // �f�B���N�g�����Ȃ�
    if not DirectoryExists(fromDir) then Exit;
    //
    SetWindowText(unit_file.MainWindowHandle, PChar(fromDir));
    //
    if 0 = FindFirst(fromDir+'*', faAnyFile, rec) then
    begin
      while (True) do
      begin
        if (rec.Name = '.') or (rec.Name = '..') then
        begin
          // do nothing
        end else
        if (rec.Attr and faDirectory > 0) then
        begin
          // copy recursive
          _copy(fromDir + rec.Name + '\', toDir + rec.Name + '\');
        end else
        begin
          // check filter
          fromFile := fromDir + rec.Name;
          toFile   := toDir   + rec.Name;
          if _match(toFile) then
          begin
            if not DirectoryExists(toDir) then ForceDirectories(toDir);
            if CopyFile(PChar(fromFile), PChar(toFile), False) = False then
            begin
              raise Exception.Create('"' + toFile + '"�̃R�s�[�Ɏ��s');
            end;
          end;
        end;
        // next
        if FindNext(rec) <> 0 then Break;
      end;
    end;
    FindClose(rec);
  end;

var
  fromDir, toDir, paramFrom, paramTo: string;
  extListStr: string;
  cap: string;
begin

  // (1) �����̎擾
  fromDir := getArgStr(args, 0, True);
  toDir   := getArgStr(args, 1);

  paramFrom := fromDir;
  paramTo   := toDir;

  // ---------------------------------------------------
  // �p�X���Ȃ��ƌ�쓮���N�����̂Ńp�X��⊮���Ă��
  CheckMixFile(fromDir);
  if (Pos(':\', fromDir) = 0)and(Pos('\\', fromDir) = 0) then // �t���p�X�w��ł͂Ȃ�
  begin
    fromDir := CheckPathYen(GetCurrentDir) + fromDir;
  end;
  if (Pos(':\', toDir) = 0)and(Pos('\\', toDir) = 0) then // �t���p�X�w��ł͂Ȃ�
  begin
    toDir := CheckPathYen(GetCurrentDir) + toDir;
  end;

  // fromDir, toDir ���p�X���H
  // �p�X�Ȃ�A\ ������
  if DirectoryExists(fromDir) then
  begin
    fromDir := CheckPathYen(fromDir);
  end;
  // toDir �͕K���f�B���N�g��
  toDir := CheckPathYen(toDir);

  // fromDir �Ƀt�B���^�̎w�肪���邩�H
  // �t�B���^������΁A�t�B���^�ƃp�X��؂藣��
  extList := nil;
  if not DirectoryExists(fromDir) then
  begin
    extListStr := ExtractFileName(fromDir);
    fromDir    := ExtractFilePath(fromDir);
    extList := SplitChar(';', extListStr);
  end;

  if extList = nil then
  begin
    extList := TStringList.Create;
  end;
  if extList.Count = 0 then
  begin
    extList.Add('*.*');
  end;

  blackList := TStringList.Create;
  blackList.Text := hi_str(nako_getVariable('�t�@�C�����o�R�s�[���O�p�^�[��'));

  // ---------------------------------------------------
  // (2) �f�[�^�̏���
  unit_file.MainWindowHandle := nako_getMainWindowHandle;
  SetLength(cap, 4096);
  GetWindowText(unit_file.MainWindowHandle, PChar(cap), 4095);
  // copy
  try
    _copy(fromDir, toDir);
  except
    on e:Exception do
    begin
      raise Exception.CreateFmt('�u%s�v����u%s�v�ւ̓r���ɔ����F%s',
        [paramFrom, paramTo, e.Message]);
    end;
  end;
  //
  FreeAndNil(extList);
  FreeAndNil(blackList);
  SetWindowText(unit_file.MainWindowHandle, PChar(cap));
  // (3) �߂�l��ݒ�
  Result := nil;
end;

function sys_dirCopy(args: DWORD): PHiValue; stdcall;
var
  a, b: PHiValue;
  sa,sb: string;
begin

  // (1) �����̎擾
  a := nako_getFuncArg(args, 0);
  b := nako_getFuncArg(args, 1);
  sa := hi_str(a);
  sb := hi_str(b);
  if Copy(sa,Length(sa),1) = '\' then System.Delete(sa,Length(sa),1);
  if Copy(sb,Length(sb),1) = '\' then System.Delete(sb,Length(sb),1);

  if DirectoryExists(sb) = False then
  begin
    ForceDirectories(sb);
  end;

  // (2) �f�[�^�̏���
  unit_file.MainWindowHandle := nako_getMainWindowHandle;
  if not SHFileCopy(sa, sb, '�t�H���_�R�s�[') then
  begin
    raise Exception.Create('�t�H���_�R�s�[�Ɏ��s�B' + GetLastErrorStr);
  end;

  // (3) �߂�l��ݒ�
  Result := nil;
end;

function sys_fileRename(args: DWORD): PHiValue; stdcall;
var
  a, b: PHiValue;
  sa, sb, dir: string;
begin
  // (1) �����̎擾
  a := nako_getFuncArg(args, 0);
  b := nako_getFuncArg(args, 1);

  // �p�X���Ȃ��ƌ�쓮���N�����̂Ńp�X��⊮���Ă��
  sa := hi_str(a);
  sb := hi_str(b);

  if (Pos(':\', sa) = 0)and(Pos('\\', sa) = 0) then // �t���p�X�w��ł͂Ȃ�
  begin
    sa := CheckPathYen(GetCurrentDir) + sa;
  end;
  if (Pos(':\', sb) = 0)and(Pos('\\', sb) = 0) then // �t���p�X�w��ł͂Ȃ�
  begin
    //sb := ExtractFilePath(sa) + sb;
    sb := CheckPathYen(GetCurrentDir) + sb;
  end;

  // �����ړ���̃t�H���_�����݂��Ȃ��Ȃ�΁A�f�B���N�g�����쐬����
  // ---
  // �ړ��悪�f�B���N�g��
  if (Copy(sb, Length(sb), 1) = '\') then
  begin
    if not DirectoryExists(sb) then
    begin
      ForceDirectories(sb);
    end;
  end else
  begin
    dir := ExtractFilePath(sb);
    ForceDirectories(dir);
  end;

  // (2) �f�[�^�̏���
  unit_file.MainWindowHandle := nako_getMainWindowHandle;
  if not SHFileRename(sa, sb) then
  begin
    raise Exception.CreateFmt('�u%s�v����u%s�v�փt�@�C�����ύX�Ɏ��s�B',[sa,sb]);
  end;

  // (3) �߂�l��ݒ�
  Result := nil;
end;

function sys_fileDelete(args: DWORD): PHiValue; stdcall;
var
  a: PHiValue;
begin
  // (1) �����̎擾
  a := nako_getFuncArg(args, 0);

  // (2) �f�[�^�̏���
  unit_file.MainWindowHandle := nako_getMainWindowHandle;
  if not SHFileDelete(hi_str(a)) then
  begin
    raise Exception.Create('�t�@�C���폜�Ɏ��s�B' + GetLastErrorStr);
  end;

  // (3) �߂�l��ݒ�
  Result := nil;
end;

function sys_fileDeleteAll(args: DWORD): PHiValue; stdcall;
var
  a: PHiValue;
begin
  // (1) �����̎擾
  a := nako_getFuncArg(args, 0);

  // (2) �f�[�^�̏���
  unit_file.MainWindowHandle := nako_getMainWindowHandle;
  if not SHFileDeleteComplete(hi_str(a)) then
  begin
    raise Exception.Create('�t�@�C���폜�Ɏ��s�B' + GetLastErrorStr);
  end;

  // (3) �߂�l��ݒ�
  Result := nil;
end;


procedure RegSetRoot(r: TRegistry; hiv: string);
begin
  if hiv = 'HKEY_CLASSES_ROOT'  then r.RootKey := HKEY_CLASSES_ROOT else
  if hiv = 'HKEY_CURRENT_USER'  then r.RootKey := HKEY_CURRENT_USER else
  if hiv = 'HKEY_LOCAL_MACHINE' then r.RootKey := HKEY_LOCAL_MACHINE else
  if hiv = 'HKEY_USERS'         then r.RootKey := HKEY_USERS else
  if hiv = 'HKEY_PERFORMANCE_DATA'  then r.RootKey := HKEY_PERFORMANCE_DATA else
  if hiv = 'HKEY_CURRENT_CONFIG'    then r.RootKey := HKEY_CURRENT_CONFIG else
  if hiv = 'HKEY_DYN_DATA'    then r.RootKey := HKEY_DYN_DATA       else
  raise Exception.Create('���W�X�g���p�X"'+hiv+'"�͊J���܂���B');
end;

function sys_registry_open(args: DWORD): PHiValue; stdcall;
var
  a: PHiValue;
  r: TRegistry;
  path: string;
  hiv: string;
begin
  a := nako_getFuncArg(args, 0);

  path := hi_str(a);
  hiv  := getToken_s(path, '\'); path := '\'+ path;

  r := TRegistry.Create;

  RegSetRoot(r, hiv);
  r.OpenKey(path, True);

  Result := hi_var_new;
  hi_setInt(Result, Integer(r));
end;

function sys_registry_write(args: DWORD): PHiValue; stdcall;
var
  h,s,a: PHiValue;
  r: TRegistry;
begin
  //H��S��A��
  h := nako_getFuncArg(args, 0);
  s := nako_getFuncArg(args, 1);
  a := nako_getFuncArg(args, 2);

  r := TRegistry(hi_int(h));
  r.WriteString(hi_str(s), hi_str(a));

  Result := nil;
end;

function sys_reg_easy_write(args: DWORD): PHiValue; stdcall;
var
  key, hiv, value, s: string;
  r: TRegistry;
begin
  // KEY��V��S��
  key   := getArgStr(args, 0, True);
  value := getArgStr(args, 1);
  s     := getArgStr(args, 2);
  //
  r := TRegistry.Create;
  try
    hiv := GetToken('\', key); key := '\' + key;
    RegSetRoot(r, hiv);
    if r.OpenKey(key, True) then
    begin
      r.WriteString(value, s);
    end;
  finally
    r.Free;
  end;
  Result := nil;
end;

function sys_reg_easy_read(args: DWORD): PHiValue; stdcall;
var
  key, hiv, value, s: string;
  r: TRegistry;
begin
  // KEY��V����
  key   := getArgStr(args, 0, True);
  value := getArgStr(args, 1);
  s     := getArgStr(args, 2);
  //
  Result := nil;
  r := TRegistry.Create;
  try
    hiv := GetToken('\', key); key := '\' + key;
    RegSetRoot(r, hiv);
    if r.OpenKey(key, False) then
    begin
      Result := hi_newStr(r.ReadString(value));
    end;
  finally
    r.Free;
  end;
end;

function sys_registry_writeInt(args: DWORD): PHiValue; stdcall;
var
  h,s,a: PHiValue;
  r: TRegistry;
begin
  //H��S��A��
  h := nako_getFuncArg(args, 0);
  s := nako_getFuncArg(args, 1);
  a := nako_getFuncArg(args, 2);

  r := TRegistry(hi_int(h));
  r.WriteInteger(hi_str(s), hi_int(a));

  Result := nil;
end;

function sys_registry_deleteKey(args: DWORD): PHiValue; stdcall;
var
  h,s: PHiValue;
  r: TRegistry;
begin
  //H��S��
  h := nako_getFuncArg(args, 0);
  s := nako_getFuncArg(args, 1);

  r := TRegistry(hi_int(h));
  r.DeleteKey(hi_str(s));

  Result := nil;
end;

function sys_registry_deleteVal(args: DWORD): PHiValue; stdcall;
var
  h,s: PHiValue;
  r: TRegistry;
begin
  //H��S��
  h := nako_getFuncArg(args, 0);
  s := nako_getFuncArg(args, 1);

  r := TRegistry(hi_int(h));
  r.DeleteValue(hi_str(s));

  Result := nil;
end;

function sys_registry_EnumKeys(args: DWORD): PHiValue; stdcall;
var
  h: PHiValue;
  r: TRegistry;
  sl: TStringList;
begin
  //H��S��
  h := nako_getFuncArg(args, 0);

  r := TRegistry(hi_int(h));
  sl := TStringList.Create;
  r.GetKeyNames(sl);

  Result := hi_newStr(sl.Text);
  sl.Free;
end;

function sys_registry_EnumValues(args: DWORD): PHiValue; stdcall;
var
  h: PHiValue;
  r: TRegistry;
  sl: TStringList;
begin
  //H��S��
  h := nako_getFuncArg(args, 0);

  r := TRegistry(hi_int(h));
  sl := TStringList.Create;
  r.GetValueNames(sl);

  Result := hi_newStr(sl.Text);
  sl.Free;
end;

function sys_registry_KeyExists(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  r: TRegistry;
  path, hiv: string;
begin
  s := nako_getFuncArg(args, 0);

  path := hi_str(s);
  hiv  := getToken_s(path, '\'); path := '\'+ path;

  r := TRegistry.Create;
  try
    RegSetRoot(r, hiv);
    Result := hi_var_new;
    hi_setBool(Result, r.KeyExists(path));
  finally
    r.Free;
  end;
end;

function sys_SHChangeNotify(args: DWORD): PHiValue; stdcall;
begin
  Result := nil;
  SHChangeNotify(
    SHCNE_ASSOCCHANGED,
    SHCNF_FLUSHNOWAIT,
    nil,
    nil);
end;


const
  KEY_TILE_WALLPAPER  = 'TileWallpaper';
  KEY_STYLE_WALLPAPER = 'WallpaperStyle';

function sys_ChangeWallpaper(args: DWORD): PHiValue; stdcall;
var
  fname: string;
begin
  Result := nil;
  // ---
  fname := getArgStr(args, 0, True);
  if fname = '' then fname := #0;
  // wallpaper
  SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, PChar(fname),
    SPIF_UPDATEINIFILE or SPIF_SENDWININICHANGE);
end;

function sys_ChangeWallpaperStyle(args: DWORD): PHiValue; stdcall;
var
  pat, fname: string;
  reg: TRegistry;
begin
  Result := nil;
  // ---
  pat := getArgStr(args, 0, True);
  // ---
  //***HKEY_CURRENT_USER\Control Panel\Desktop
  // style
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.OpenKey('Control Panel\Desktop',False);
    if pat = '����' then
    begin
      reg.WriteString(KEY_TILE_WALLPAPER,  '0');
      reg.WriteString(KEY_STYLE_WALLPAPER, '0');
    end else
    if pat = '�^�C��' then
    begin
      reg.WriteString(KEY_TILE_WALLPAPER,  '1');
      reg.WriteString(KEY_STYLE_WALLPAPER, '0');
    end else
    if pat = '�g��' then
    begin
      reg.WriteString(KEY_TILE_WALLPAPER,  '0');
      reg.WriteString(KEY_STYLE_WALLPAPER, '2');
    end else
    begin
      // ����
      reg.WriteString(KEY_TILE_WALLPAPER,  '0');
      reg.WriteString(KEY_STYLE_WALLPAPER, '0');
    end;
    fname := reg.ReadString('Wallpaper');
    if fname = '' then fname := #0;
    // wallpaper
    SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, PChar(fname),
      SPIF_UPDATEINIFILE or SPIF_SENDWININICHANGE);

  finally
    reg.Free;
  end;
end;


function sys_getWallpaper(args: DWORD): PHiValue; stdcall;
var
  fname: string;
  reg: TRegistry;
begin

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.OpenKey('Control Panel\Desktop',False);
    fname := reg.ReadString('Wallpaper');
    Result := hi_newStr(fname);

  finally
    reg.Free;
  end;
end;


function sys_getWallpaperStyle(args: DWORD): PHiValue; stdcall;
var
  s, pat, tile, style: string;
  reg: TRegistry;
begin

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.OpenKey('Control Panel\Desktop',False);

    tile  := reg.ReadString(KEY_TILE_WALLPAPER);
    style := reg.ReadString(KEY_STYLE_WALLPAPER);

    s := tile + style;
    if s = '00' then pat := '����'    else
    if s = '10' then pat := '�^�C��'  else
    if s = '02' then pat := '�g��'    else pat := '����';

    Result := hi_newStr(pat);

  finally
    reg.Free;
  end;
end;

function sys_registry_read(args: DWORD): PHiValue; stdcall;
var
  h, s: PHiValue;
  r: TRegistry;
begin
  //H��S��
  h := nako_getFuncArg(args, 0);
  s := nako_getFuncArg(args, 1);

  r := TRegistry(hi_int(h));

  Result := hi_var_new;
  hi_setStr(Result, r.ReadString(hi_str(s)));
end;

function sys_registry_readInt(args: DWORD): PHiValue; stdcall;
var
  h, s: PHiValue;
  r: TRegistry;
begin
  //H��S��
  h := nako_getFuncArg(args, 0);
  s := nako_getFuncArg(args, 1);

  r := TRegistry(hi_int(h));
  Result := hi_var_new;
  hi_setInt(Result, r.ReadInteger(hi_str(s)));
end;


function sys_registry_read_bin(args: DWORD): PHiValue; stdcall;
var
  h: Integer;
  s, buf: string;
  cnt: Integer;
  r: TRegistry;
begin
  //H, S, CNT
  h   := getArgInt(args, 0, True);
  s   := getArgStr(args, 1, False);
  cnt := getArgInt(args, 2, False);
  //
  SetLength(buf, cnt);
  //
  r := TRegistry(Pointer(h));
  r.ReadBinaryData(s, buf[1], cnt);
  //
  Result := hi_newStr(buf);
end;
function sys_registry_write_bin(args: DWORD): PHiValue; stdcall;
var
  h   : Integer;
  s   : string;
  v   : string;
  cnt : Integer;
  r   : TRegistry;
begin
  // H��S��V��CNT��
  h   := getArgInt(args, 0, True);
  s   := getArgStr(args, 1, False);
  v   := getArgStr(args, 2, False);
  cnt := getArgInt(args, 3, False);
  //
  if (Length(v) < cnt) then
  begin
    cnt := Length(v);
  end;
  //
  Result := nil;
  r := TRegistry(Pointer(h));
  r.WriteBinaryData(s, v[1], cnt);
end;


function sys_registry_close(args: DWORD): PHiValue; stdcall;
var
  a: PHiValue;
  r: TRegistry;
begin
  a := nako_getFuncArg(args, 0);

  r := TRegistry(hi_int(a));
  r.CloseKey;
  r.Free;

  Result := nil;
end;

function sys_shortcut(args: DWORD): PHiValue; stdcall;
var
  a, b: PHiValue;
begin
  a := nako_getFuncArg(args, 0);
  b := nako_getFuncArg(args, 1);
  CreateShortCut(hi_str(b), hi_str(a), '', '', ws2Normal);
  Result := nil;
end;

function sys_shortcut_ex(args: DWORD): PHiValue; stdcall;
var
  a, b, c, p: PHiValue;
  Arg,Comment,Key,Icon,WorkingDir,Win:String;
  HotKeyHi,HotKeyLo:BYTE;
  IconNo:Integer;
  WinState: TWindowState2;
  pc:PChar;
begin
  a := nako_getFuncArg(args, 0);
  b := nako_getFuncArg(args, 1);
  c := nako_getFuncArg(args, 2);

  Arg:='';
  Comment:='';
  Key:='';
  Icon:='';
  IconNo:=0;
  WorkingDir:='';
  Win:='';
  HotKeyHi:=0;
  HotKeyLo:=0;
  WinState:= ws2Normal;

  p := nako_hash_get(c,'����');
  if p <> nil then Arg := hi_str(p);
  p := nako_hash_get(c,'�R�����g');
  if p <> nil then Comment := hi_str(p);
  p := nako_hash_get(c,'�V���[�g�J�b�g�L�[');
  if p <> nil then
  begin
    Key := hi_str(p);
    pc:=PChar(AnsiUpperCase(Key));
    while pc^ <> #0 do
    begin
      case pc^ of
        '^':HotKeyHi:= HotKeyHi or HOTKEYF_CONTROL;
        '%':HotKeyHi:= HotKeyHi or HOTKEYF_ALT;
        '+':HotKeyHi:= HotKeyHi or HOTKEYF_SHIFT;
        else
          HotKeyLo:= BYTE(pc^);
      end;
      Inc(pc);
    end;
  end;
  p := nako_hash_get(c,'�A�C�R��');
  if p <> nil then Icon := hi_str(p);
  p := nako_hash_get(c,'�A�C�R���ԍ�');
  if p <> nil then IconNo := hi_int(p);
  p := nako_hash_get(c,'��ƃt�H���_');
  if p <> nil then WorkingDir := hi_str(p);
  p := nako_hash_get(c,'�E�B���h�E���');//�ő�/�ŏ�/�ʏ�
  if p <> nil then
  begin
    Win := hi_str(p);
    if Win = '�ő�' then
      WinState := ws2Maximized
    else if Win = '�ŏ�' then
      WinState := ws2Minimized;
  end;

  CreateShortCutEx(hi_str(b), hi_str(a), Arg, WorkingDir, Icon,IconNo, Comment,
    MakeWord(HotKeyLo,HotKeyHi), WinState);
  Result := nil;
end;

function sys_get_shortcut(args: DWORD): PHiValue; stdcall;
var
  a: PHiValue;
begin
  a := nako_getFuncArg(args, 0);
  Result := hi_newStr(GetShortCutLink(hi_str(a)));
end;


function sys_ini_open(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue; ss: string;
  i: TIniFile;
begin
  // 1)����
  s := nako_getFuncArg(args, 0);

  // �p�X���ȗ����ꂽ��A��̓p�X�ɂ���
  ss := hi_str(s);
  dll_plugin_helper._getEmbedFile(ss); // �����\�Ȃ���s�t�@�C��������o��

  if ExtractFileDrive(ss) = '' then
  begin
    if not FileExists(ExpandFileName(WinDir + ss)) then
      ss :=ExpandFileName(hi_str(nako_getVariable('��̓p�X')) + ss);
  end;

  // 2)INI
  i := TIniFile.Create(ss);
  // 3)����
  Result := hi_newInt(Integer(i));
end;
function sys_ini_close(args: DWORD): PHiValue; stdcall;
var
  h: PHiValue;
begin
  // 1)����
  h := nako_getFuncArg(args, 0);
  // 2)INI
  TIniFile(hi_int(h)).Free;
  // 3)����
  Result := nil;
end;
function sys_ini_read(args: DWORD): PHiValue; stdcall;
var
  h,a,b: PHiValue;
  s: string;
begin
  // 1)����
  h := nako_getFuncArg(args, 0);
  a := nako_getFuncArg(args, 1);
  b := nako_getFuncArg(args, 2);
  // 2)INI
  s := TIniFile(hi_int(h)).ReadString(hi_str(a),hi_str(b), '');
  // 3)����
  Result := hi_newStr(s);
end;
function sys_ini_write(args: DWORD): PHiValue; stdcall;
var
  h,a,b,s: PHiValue;
begin
  // 1)����
  h := nako_getFuncArg(args, 0);
  a := nako_getFuncArg(args, 1);
  b := nako_getFuncArg(args, 2);
  s := nako_getFuncArg(args, 3);
  // 2)INI
  TIniFile(hi_int(h)).WriteString(hi_str(a),hi_str(b),hi_str(s));
  // 3)����
  Result := nil;
end;

function sys_sp_path(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetSpecialFolder(getArgInt(args,0,True)));
end;
function get_CSIDL_COMMON_STARTUP(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetSpecialFolder(CSIDL_COMMON_STARTUP));
end;
function get_CSIDL_COMMON_DESKTOPDIRECTORY(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetSpecialFolder(CSIDL_COMMON_DESKTOPDIRECTORY));
end;
function get_CSIDL_COMMON_DOCUMENTS(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetSpecialFolder(CSIDL_COMMON_DOCUMENTS));
end;
function get_CSIDL_COMMON_APPDATA(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetSpecialFolder(CSIDL_COMMON_APPDATA));
end;
function get_CSIDL_COMMON_FAVORITES(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetSpecialFolder(CSIDL_COMMON_FAVORITES));
end;
function get_CSIDL_LOCAL_APPDATA(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetSpecialFolder(CSIDL_LOCAL_APPDATA));
end;
function get_USER_PROFILE(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetSpecialFolder(CSIDL_PROFILE));
end;
function get_APPDATA(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetSpecialFolder(CSIDL_APPDATA));
end;
function get_SENDTO(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetSpecialFolder(CSIDL_SENDTO));
end;
function get_QUICKLAUNCH(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(QuickLaunchDir);
end;
function get_COMSPEC(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(ExpandEnvironmentStrDelphi('%COMSPEC%'));
end;
function get_SYSTEMDRIVE(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(ExpandEnvironmentStrDelphi('%SystemDrive%'));
end;



function sys_getOE5(args: DWORD): PHiValue; stdcall;
var
  r: TRegistry;
  s: TStringList;
  id, path: string;
begin
  Result := hi_var_new;
  r := TRegistry.Create;
  s := TStringList.Create;
  try
    //HKEY_CURRENT_USER\Identities\<{ID}>\Software\Microsoft\Outlook Express\5.0\Rules\Mail
    r.RootKey := HKEY_CURRENT_USER;
    if r.OpenKeyReadOnly('Identities') then
    begin
      r.GetKeyNames(s);
      r.CloseKey;
      if s.Count = 0 then Exit;
      id := s.Strings[0];//writeln(id);
    end else Exit;
    if r.OpenKeyReadOnly('Identities\' + id + '\Software\Microsoft\Outlook Express\5.0') then
    begin
      path := r.ReadString('Store Root');
      r.CloseKey;

      // ���ϐ���W�J
      path := CheckPathYen(ExpandEnvironmentStrDelphi(path));

      // ���ʂ��Z�b�g
      hi_setStr(Result, path);
    end;
  finally
    s.Free;
    r.Free;
  end;
end;



function sys_getBecky2(args: DWORD): PHiValue; stdcall;
var
  r: TRegistry;
  s: TStringList;
  path: string;
begin
  Result := hi_var_new;
  r := TRegistry.Create;
  s := TStringList.Create;
  try
    r.RootKey := HKEY_CURRENT_USER;
    if r.OpenKeyReadOnly('Software\RimArts\B2\Settings') then
    begin
      path := CheckPathYen(r.ReadString('DataDir'));
      hi_setStr(Result, path);
    end;
  finally
    s.Free;
    r.Free;
  end;
end;

function sys_expandEnv(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr( ExpandEnvironmentStrDelphi( getArgStr(args,0,True) ) );
end;

function sys_getFileSize(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  F: TSearchRec;
  i: Int64;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s=nil then s := HiSystem.Sore;

  // (2) �f�[�^�̏���
  if FindFirst(hi_str(s), FaAnyFile, F) = 0 then
  begin
    i := F.FindData.nFileSizeLow + Int64(F.FindData.nFileSizeHigh) shl 32;
    FindClose(F);
  end else i := 0;

  // (3) �߂�l��ݒ�
  Result := hi_var_new;
  if i >= MaxInt then
  begin
    hi_setFloat(Result, i);
  end else
  begin
    hi_setInt(Result, Integer(i));
  end;
end;

function sys_getFileDate(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  F: TSearchRec;
  d: TDateTime;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s=nil then s := HiSystem.Sore;
  // (2) �f�[�^�̏���
  if FindFirst(hi_str(s), FaAnyFile, F) = 0 then
  begin
    d := FileDateToDateTime(F.Time);
    FindClose(F);
  end else
  begin
    Result := hi_newStr(''); Exit;
  end;

  // (3) �߂�l��ݒ�
  Result := hi_newStr(FormatDateTime('yyyy/mm/dd hh:nn:ss',d));
end;


function sys_getCreateFileDate(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  tCreation, tLastAccess, tLastWrite:TDateTime;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s=nil then s := HiSystem.Sore;

  // (2) �f�[�^�̏���
  if GetFileTimeEx(hi_str(s), tCreation, tLastAccess, tLastWrite) then
  begin
    Result := hi_newStr(FormatDateTime('yyyy/mm/dd hh:nn:ss', tCreation));
  end else
  begin
    Result := nil;
  end;
end;

function sys_getLastAccessFileDate(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  tCreation, tLastAccess, tLastWrite:TDateTime;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s=nil then s := HiSystem.Sore;

  // (2) �f�[�^�̏���
  if GetFileTimeEx(hi_str(s), tCreation, tLastAccess, tLastWrite) then
  begin
    Result := hi_newStr(FormatDateTime('yyyy/mm/dd hh:nn:ss', tLastAccess));
  end else
  begin
    Result := nil;
  end;
end;

function sys_getWriteFileDate(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  tCreation, tLastAccess, tLastWrite:TDateTime;
begin
  // (1) �����̎擾
  s := nako_getFuncArg(args, 0);
  if s=nil then s := HiSystem.Sore;

  // (2) �f�[�^�̏���
  if GetFileTimeEx(hi_str(s), tCreation, tLastAccess, tLastWrite) then
  begin
    Result := hi_newStr(FormatDateTime('yyyy/mm/dd hh:nn:ss', tLastWrite));
  end else
  begin
    Result := nil;
  end;
end;

function sys_setFileDateCreate(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
  fname, fdate: string;
  tCreation, tLastAccess, tLastWrite:TDateTime;
begin
  Result := nil;

  // �����̎擾
  p := nako_getFuncArg(args, 0); if p=nil then p := HiSystem.Sore;
  fname := hi_str(p);
  fdate := hi_str(nako_getFuncArg(args, 1));

  // ���݂̓����𓾂�
  if not GetFileTimeEx(fname, tCreation, tLastAccess, tLastWrite) then
  begin
    raise Exception.Create('�w'+fname+'�x������ł��܂���B');
  end;

  tCreation := StrToDateTimeDef(fdate, 0);
  if tCreation = 0 then raise Exception.Create('���t('+fdate+')�̌`���͔F���ł��܂���B');

  // ���t��ݒ肷��
  if not SetFileTimeEx(fname, tCreation, tLastAccess, tLastWrite) then
  begin
    raise Exception.Create('���t�̕ύX�Ɏ��s���܂����B');
  end;
end;

function sys_setFileDateWrite(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
  fname, fdate: string;
  tCreation, tLastAccess, tLastWrite:TDateTime;
begin
  Result := nil;

  // �����̎擾
  p := nako_getFuncArg(args, 0); if p=nil then p := HiSystem.Sore;
  fname := hi_str(p);
  fdate := hi_str(nako_getFuncArg(args, 1));

  // ���݂̓����𓾂�
  if not GetFileTimeEx(fname, tCreation, tLastAccess, tLastWrite) then
  begin
    raise Exception.Create('�w'+fname+'�x������ł��܂���B');
  end;

  tLastWrite := StrToDateTimeDef(fdate, 0);
  if tLastWrite = 0 then raise Exception.Create('���t('+fdate+')�̌`���͔F���ł��܂���B');

  // ���t��ݒ肷��
  if not SetFileTimeEx(fname, tCreation, tLastAccess, tLastWrite) then
  begin
    raise Exception.Create('���t�̕ύX�Ɏ��s���܂����B');
  end;
end;

function sys_setFileDateLastAccess(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
  fname, fdate: string;
  tCreation, tLastAccess, tLastWrite:TDateTime;
begin
  Result := nil;

  // �����̎擾
  p := nako_getFuncArg(args, 0); if p=nil then p := HiSystem.Sore;
  fname := hi_str(p);
  fdate := hi_str(nako_getFuncArg(args, 1));

  // ���݂̓����𓾂�
  if not GetFileTimeEx(fname, tCreation, tLastAccess, tLastWrite) then
  begin
    raise Exception.Create('�w'+fname+'�x������ł��܂���B');
  end;

  tLastAccess := StrToDateTimeDef(fdate, 0);
  if tLastAccess = 0 then raise Exception.Create('���t('+fdate+')�̌`���͔F���ł��܂���B');

  // ���t��ݒ肷��
  if not SetFileTimeEx(fname, tCreation, tLastAccess, tLastWrite) then
  begin
    raise Exception.Create('���t�̕ύX�Ɏ��s���܂����B');
  end;
end;

function sys_getFileAttr(args: DWORD): PHiValue; stdcall;
var f: PHiValue; fname: string;
begin
  f := nako_getFuncArg(args, 0);
  if f = nil then f := nako_getSore;
  fname := hi_str(f);
  Result := hi_newInt(GetFileAttributes(PChar(fname)));
end;

function sys_setFileAttr(args: DWORD): PHiValue; stdcall;
var f, s: PHiValue; fname: string;
begin
  f := nako_getFuncArg(args, 0);
  s := nako_getFuncArg(args, 1);
  if f = nil then f := nako_getSore;
  fname := hi_str(f);
  SetFileAttributes(PChar(fname), hi_int(s));
  Result := nil;
end;


function sys_getLogicalDrives(args: DWORD): PHiValue; stdcall;
var
  bufsize: DWORD;
  buf: string;
  i: Integer;
begin
  bufsize := GetLogicalDriveStrings(0, nil);
  SetLength(buf, bufsize);
  GetLogicalDriveStrings(bufsize, @buf[1]);
  for i := 1 to Length(buf) do
    if buf[i] = #0 then buf[i] := #13;
  buf := Trim(JReplace(buf, #13, #13#10, True));
  //
  Result := hi_newStr(buf);
end;

function sys_getDriveType(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue; sp, r: string;
  u: UINT;
begin
  p := nako_getFuncArg(args, 0);
  if p = nil then p := nako_getSore;
  sp := hi_str(p);

  // �s��|���݂��Ȃ�|���O���\|�Œ�|�l�b�g���[�N|CD-ROM|RAM
  u := GetDriveType(PChar(sp));
  case u of
    DRIVE_UNKNOWN     : r := '�s��';
    DRIVE_NO_ROOT_DIR : r := '���݂��Ȃ�';
    DRIVE_REMOVABLE   : r := '���O���\';
    DRIVE_FIXED       : r := '�Œ�';
    DRIVE_REMOTE      : r := '�l�b�g���[�N';
    DRIVE_CDROM       : r := 'CD-ROM';
    DRIVE_RAMDISK     : r := 'RAM';
    else                r := '';
  end;

  Result := hi_newStr(r);
end;

function sys_getDiskSize(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue; sp: string;
  iFree, iTotal: TLargeInteger;
begin
  p := nako_getFuncArg(args, 0);
  if p = nil then p := nako_getSore;
  sp := hi_str(p);

  GetDiskFreeSpaceEx(PChar(sp), iFree, iTotal, nil);

  Result := hi_newFloat(iTotal);
end;
function sys_getDiskFreeSize(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue; sp: string;
  iFree, iTotal: Int64;
begin
  p := nako_getFuncArg(args, 0);
  if p = nil then p := nako_getSore;
  sp := hi_str(p);

  GetDiskFreeSpaceEx(PChar(sp), iFree, iTotal, nil);
  Result := hi_newFloat(iFree);
end;
function sys_getVolumeName(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue; sp: string;
begin
  p := nako_getFuncArg(args, 0);
  if p = nil then p := nako_getSore;
  sp := hi_str(p);
  Result := hi_newStr(getVolumeName(sp));
end;
function sys_getSerialNo(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue; sp: string;
begin
  p := nako_getFuncArg(args, 0);
  if p = nil then p := nako_getSore;
  sp := hi_str(p);
  Result := hi_newInt(getSerialNo(sp));
end;

function sys_showHotplugDlg(args: DWORD): PHiValue; stdcall;
begin
  RunApp('rundll32 shell32.dll,Control_RunDLL hotplug.dll');
  Result := nil;
end;

function sys_file_h_open(args: DWORD): PHiValue; stdcall;
var
  a, b: PHiValue;
  f: TFileStream;
  fname, fmode: string;
  flg: Integer;
begin
  a := nako_getFuncArg(args, 0); fname := hi_str(a);
  b := nako_getFuncArg(args, 1); fmode := hi_str(b);

  flg := 0;
  dll_plugin_helper._getEmbedFile(fname); // �����\�Ȃ���s�t�@�C��������o��

  // ����?
  if (FileExists(fname)=False)or(Pos('��',fmode) > 0) then
  begin
    flg := flg or fmCreate;
  end;

  // ���[�h
  if (Pos('��',fmode) > 0)and(Pos('��',fmode) > 0) then
  begin
    flg := flg or fmOpenReadWrite;
  end else
  if Pos('��', fmode) > 0 then
  begin
    flg := flg or fmOpenRead;
  end else
  if Pos('��', fmode) > 0 then
  begin
    flg := flg or fmOpenWrite;
  end;

  // �r��
  if Pos('�r��', fmode) > 0 then
  begin
    flg := flg or fmShareExclusive;
  end else
  begin
    flg := flg or fmShareDenyNone;
  end;

  f := TFileStream.Create(fname, flg);
  Result := hi_newInt(Integer(f));
end;

function sys_file_h_read(args: DWORD): PHiValue; stdcall;
var
  ph, pcnt: PHiValue;
  s: string;
  h: TFileStream;
begin
  ph   := nako_getFuncArg(args, 0);
  pcnt := nako_getFuncArg(args, 1);

  h := TFileStream( hi_int(ph) );
  SetLength(s, hi_int(pcnt));

  h.Read(s[1], hi_int(pcnt));

  Result := hi_newStr(s);
end;

function sys_file_h_write(args: DWORD): PHiValue; stdcall;
var
  ph, ps: PHiValue;
  s: string;
  h: TFileStream;
begin
  ph   := nako_getFuncArg(args, 0);
  ps   := nako_getFuncArg(args, 1);

  h := TFileStream( hi_int(ph) );
  s := hi_str(ps);

  if Length(s) > 0 then
  begin
    h.Write(s[1], Length(s));
  end;

  Result := nil;
end;

function sys_file_h_close(args: DWORD): PHiValue; stdcall;
var
  ph: PHiValue;
  h : TFileStream;
begin
  ph := nako_getFuncArg(args, 0);
  h  := TFileStream( hi_int(ph) );

  FreeAndNil(h);

  Result := nil;
end;

function sys_file_h_getpos(args: DWORD): PHiValue; stdcall;
var
  ph: PHiValue;
  h : TFileStream;
begin
  ph := nako_getFuncArg(args, 0);
  h  := TFileStream( hi_int(ph) );

  Result := hi_newInt( h.Position );
end;

function sys_file_h_setpos(args: DWORD): PHiValue; stdcall;
var
  ph, pi: PHiValue;
  h : TFileStream;
  i : Integer;
begin
  ph := nako_getFuncArg(args, 0);
  pi := nako_getFuncArg(args, 1);

  h  := TFileStream( hi_int(ph) );
  i  := hi_int(pi);

  h.Position := i;

  Result := nil;
end;

function sys_file_h_size(args: DWORD): PHiValue; stdcall;
var
  ph: PHiValue;
  h : TFileStream;
begin
  ph := nako_getFuncArg(args, 0);
  h  := TFileStream( hi_int(ph) );

  Result := hi_newInt(h.Size);
end;

function sys_file_h_writeLine(args: DWORD): PHiValue; stdcall;
var
  ph: PHiValue;
  h: TFileStream;
  s: string;
begin
  s  := getArgStr(args, 0, True) + #13#10;
  ph := nako_getFuncArg(args, 1);
  //
  h  := TFileStream( hi_int(ph) );
  h.Write(s[1], Length(s));
  Result := nil;
end;

function sys_file_h_readLine(args: DWORD): PHiValue; stdcall;
const
  bufCount = 4096;
var
  ph: PHiValue;
  h : TFileStream;
  si, se: Int64;
  buf, res: string;
  i, j, sz: Integer;
  flagEnd: Boolean;
begin
  ph := nako_getFuncArg(args, 0);
  h  := TFileStream( hi_int(ph) );

  // buf
  SetLength(buf, bufCount);

  // defalt pos
  si := h.Position;
  res := ''; flagEnd := False; se :=si;

  // �K���ɓǂ�
  while True do
  begin
    sz := h.Read(buf[1], bufCount);
    if sz < bufCount then
    begin
      // �X�g���[���̍Ō�܂œǂ�ł��܂����ꍇ
      flagEnd := True;
    end;
    j := 0;
    for i := 1 to sz do
    begin
      if buf[i] in [#13,#10] then
      begin
        j := i;
        if (i+1) <= bufCount then
        begin
          if buf[i+1] in [#10] then
          begin
            j := i+1;
          end;
        end;
        Break;
      end;
    end;
    // ���s���o�b�t�@���ɂ������ꍇ
    if j > 0 then
    begin
      // 123456** 8
      res := res + Copy(buf, 1, j);
      se := si + Length(res);
      // ���s���������Ƃ�
      if Copy(res, Length(res), 1) = #10 then System.Delete(res, Length(res), 1);
      if Copy(res, Length(res), 1) = #13 then System.Delete(res, Length(res), 1);
      Break;
    end else
    begin
      // �S�Ẵo�b�t�@�𑫂�
      res := res + buf;
      se := si + Length(res);
      if flagEnd then Break; // ����ȏ�ǂ߂Ȃ��Ȃ�A�������I���
    end;
  end;

  // �C���f�b�N�X�����ɂ��炷
  h.Position := se;

  // ����
  Result := hi_newStr(res);
end;

function sys_compress(args: DWORD): PHiValue; stdcall;
var
  a, b: PHiValue;
  src, des, ext: string;
begin
  // (1) �����̎擾
  a := nako_getFuncArg(args, 0);
  b := nako_getFuncArg(args, 1);

  src := hi_str(a);
  des := hi_str(b);
  ext := LowerCase( ExtractFileExt(des) );

  // (2) ����
  if ext = '.lzh' then lha_compress(src, des) else
  if ext = '.zip' then zip_compress(src, des) else
  if ext = '.cab' then cab_compress(src, des) else
  if ext = '.exe' then lha_makeSFX(src, des) else
  if ext = '.yz1' then yz1_compress(src, des) else
  raise Exception.Create('"'+ext+'"�͖��Ή��̈��k�`���ł��B');
  nako_reportDLL(PChar(unit_archive.used_dll));

  // (3) ���ʂ̑��
  Result := nil;
end;

function sys_extract(args: DWORD): PHiValue; stdcall;
var
  a, b: PHiValue;
  src, des, ext: string;
begin
  // (1) �����̎擾
  a := nako_getFuncArg(args, 0);
  b := nako_getFuncArg(args, 1);
  // (2) ����
  src := hi_str(a);
  des := hi_str(b);
  ext := LowerCase( ExtractFileExt(src) );

  if ExtractFileExt(des) = '' then
  begin
    des := CheckPathYen(des);
    ForceDirectories(des);
  end;

  dll_plugin_helper._getEmbedFile(src); // �����\�Ȃ���s�t�@�C��������o��

  // (2) ����
  if ext = '.lzh' then lha_extract (src, des)  else
  if ext = '.zip' then zip_extract (src, des)  else
  if ext = '.cab' then cab_extract (src, des)  else
  if ext = '.yz1' then yz1_extract (src, des)  else
  raise Exception.Create('"'+ext+'"�͖��Ή��̈��k�`���ł��B');
  nako_reportDLL(PChar(unit_archive.used_dll));

  // (3) ���ʂ̑��
  Result := nil;
end;


function sys_archive_command(args: DWORD): PHiValue; stdcall;
var
  ext, cmd: string;
begin
  // (1) �����̎擾
  ext := getArgStr(args, 0);
  cmd := getArgStr(args, 1);
  ext := LowerCaseEx(ext);
  if Copy(ext,1,1) <> '.' then ext := '.' + ext;
  // (2) ����
  if ext = '.lzh' then UnlhaCommand(cmd)  else
  if ext = '.zip' then SevenZipCommand(cmd)  else
  if ext = '.cab' then CabCommand(cmd)  else
  if ext = '.yz1' then Yz1Command(cmd)  else
  raise Exception.Create('"'+ext+'"�͖��Ή��̈��k�`���ł��B');

  // (3) ���ʂ̑��
  Result := nil;
end;


function sys_makesfx(args: DWORD): PHiValue; stdcall;
var
  a, b: PHiValue;
begin
  // (1) �����̎擾
  a := nako_getFuncArg(args, 0);
  b := nako_getFuncArg(args, 1);

  // (2) ����
  lha_makeSFX(hi_str(a), hi_str(b));

  // (3) ���ʂ̑��
  Result := nil;
end;

function sys_getUserName(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetUserName);
end;

function sys_GetComputerName(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetComputerName);
end;

function sys_LanEnumDomain(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(LanEnumDomain);
end;

function sys_LanEnumComputer(args: DWORD): PHiValue; stdcall;
var
  a: PHiValue;
begin
  // (1) �����̎擾
  a := nako_getFuncArg(args, 0);
  if a = nil then
  begin
    Result := hi_newStr(LanEnumComputer('',True));
  end else
  begin
    Result := hi_newStr(LanEnumComputer(hi_str(a),True));
  end;
end;

function sys_LanEnumCommonDir(args: DWORD): PHiValue; stdcall;
var
  a: PHiValue;
begin
  // (1) �����̎擾
  a := nako_getFuncArg(args, 0);
  Result := hi_newStr(LanGetCommonResource(hi_str(a)));
end;

function sys_WNetAddConnection2(args: DWORD): PHiValue; stdcall;
var
  drv, dir, pass, user: string;
begin
  Result := nil;
  drv := getArgStr(args, 0, True);
  dir := getArgStr(args, 1);
  user:= getArgStr(args, 2);
  pass:= getArgStr(args, 3);
  //
  drv := Trim(drv);
  drv := UpperCase(Copy(drv,1,1)) + ':';
  dir := ExcludeTrailingPathDelimiter(dir);
  //

  try
    if user = '' then
      AddNetworkDrive(PChar(drv), PChar(dir), nil)
    else
      AddNetworkDrive(PChar(drv), PChar(dir), nil,PChar(pass),Pchar(user));
  except
    on e: Exception do
      raise Exception.Create(Format('"%s"��"%s"�����蓖�Ăł��܂���ł����B' + e.Message,[drv,dir]));
  end;
end;

function sys_WNetCancelConnection2(args: DWORD): PHiValue; stdcall;
var
  drv:String;
begin
  Result := nil;
  drv := getArgStr(args, 0, True);
  drv := UpperCase(Copy(drv,1,1)) + ':';
  if WNetCancelConnection2(Pchar(drv),0,False) <> NO_ERROR then
    raise Exception.Create(Format('"%s"�̊��蓖�Ă������ł��܂���ł����B' + GetLastErrorStr,[drv]));
end;

function sys_kanrenduke(args: DWORD): PHiValue; stdcall;
var
  ext, app: string;
begin
  Result := nil;
  ext := getArgStr(args, 0, True);
  app := getArgStr(args, 1, False);
  Kanrenduke(ext, app);
end;
function sys_kanrendukekaijo(args: DWORD): PHiValue; stdcall;
var
  ext: string;
begin
  Result := nil;
  ext := getArgStr(args, 0, True);
  KanrendukeKaijo(ext);
end;
// �o�͂̂��߂�
var outfile: TFileStream = nil;
var outfile_name: string = '';
function sys_set_outfile(args: DWORD): PHiValue; stdcall;
var
  s: string;
begin
  Result := nil;
  FreeAndNil(outfile);
  s := getArgStr(args, 0, True);
  if s = '' then
  begin
    outfile_name := '';
    Exit;
  end;

  if not FileExists(s) then
  begin
    outfile := TFileStream.Create(s, fmCreate);
    outfile.Seek(0, soFromBeginning); // �ŏ���
  end else
  begin
    outfile := TFileStream.Create(s, fmOpenReadWrite);
    outfile.Seek(0, soFromEnd); // �Ō��
  end;
  outfile_name := s;
end;
function sys_get_outfile(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(outfile_name);
end;
procedure check_outfile;
begin
  if outfile = nil then begin // �K���ȃt�@�C��������ďo�͂Ƃ���
    outfile_name := DesktopDir + '�Ȃł����o��.txt';
    outfile := TFileStream.Create(outfile_name, fmCreate);
  end;
end;
function sys_outfile_write(args: DWORD): PHiValue; stdcall;
var
  s: string;
begin
  Result := nil;
  s := getArgStr(args, 0, True);
  check_outfile;
  if s <> '' then outfile.Write(s[1], Length(s));
end;
function sys_outfile_writeln(args: DWORD): PHiValue; stdcall;
var
  s: string;
begin
  Result := nil;
  s := getArgStr(args, 0, True) + #13#10;
  check_outfile;
  if s <> '' then outfile.Write(s[1], Length(s));
end;
function sys_outfile_clear(args: DWORD): PHiValue; stdcall;
begin
  Result := nil;
  outfile.Position := 0;
  outfile.Size := 0;
end;

//--- GET DIRECTORY FUNCTION
function sys_WinDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(WinDir);
end;
function sys_SysDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(SysDir);
end;
function sys_TempDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(TempDir);
end;
function sys_DesktopDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(DesktopDir);
end;
function sys_SendToDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(SendToDir);
end;
function sys_StartUpDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(StartUpDir);
end;
function sys_RecentDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(RecentDir);
end;
function sys_ProgramsDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(ProgramsDir);
end;
function sys_MyDocumentDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(MyDocumentDir);
end;
function sys_FavoritesDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(FavoritesDir);
end;
function sys_MyMusicDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(MyMusicDir);
end;
function sys_MyPictureDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(MyPictureDir);
end;
function sys_FontsDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(FontsDir);
end;
function sys_ProgramFilesDir(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(ProgramFilesDir);
end;

const
  KEY_USER_DESKTOP = '\Control Panel\Desktop';

function sys_getScr(args: DWORD): PHiValue; stdcall;
var
  reg: TRegistry;
  scr: string;
begin
  Result := nil;
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if reg.OpenKey(KEY_USER_DESKTOP, False) then
    begin
      scr := reg.ReadString('SCRNSAVE.EXE');
      reg.CloseKey;
      Result := hi_newStr(scr);
    end;
  finally
    FreeAndNil(reg);
  end;
end;


function sys_runScr(args: DWORD): PHiValue; stdcall;
begin
  Result := nil;
  PostMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_SCREENSAVE, 0);
end;

function sys_setScr(args: DWORD): PHiValue; stdcall;
var
  reg: TRegistry;
  scr: string;
begin
  Result := nil;
  scr := getArgStr(args, 0, True);
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if reg.OpenKey(KEY_USER_DESKTOP, True) then
    begin
      if scr = '' then
      begin
        reg.WriteString('SCRNSAVE.EXE', '');
        reg.WriteInteger('ScreenSaveActive', 0);
      end else
      begin
        reg.WriteString('SCRNSAVE.EXE', scr);
        reg.WriteInteger('ScreenSaveActive', 1);
      end;
      reg.CloseKey;
    end else
    begin
      raise Exception.Create('�X�N���[���Z�C�o�[��ݒ�ł��܂���B');
    end;
  finally
    FreeAndNil(reg);
  end;
end;

function sys_getScrTime(args: DWORD): PHiValue; stdcall;
var
  reg: TRegistry;
  timer: Integer;
begin
  Result := nil;
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if reg.OpenKey(KEY_USER_DESKTOP, False) then
    begin
      timer := StrToIntDef(reg.ReadString('ScreenSaveTimeOut'), 0);
      reg.CloseKey;
      Result := hi_newInt(timer);
    end;
  finally
    FreeAndNil(reg);
  end;
end;

function sys_setScrTime(args: DWORD): PHiValue; stdcall;
var
  reg: TRegistry;
  timer: String;
begin
  Result := nil;
  timer := IntToStr(getArgInt(args, 0, True));
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if reg.OpenKey(KEY_USER_DESKTOP, True) then
    begin
      reg.WriteString('ScreenSaveTimeOut', timer);
      reg.CloseKey;
    end else
    begin
      raise Exception.Create('�X�N���[���Z�C�o�[�҂����Ԃ�ݒ�ł��܂���B');
    end;
  finally
    FreeAndNil(reg);
  end;
end;


//--- COM ----------------------------------------------------------------------
// ��肩��
(*
  //+COM(nakofile.dll)
  AddFunc  ('OLE_CREATE','{=?}S��', 638, sys_com_create,'COM�̃N���XS�𐶐����ĕԂ��B','OLE_CREATE');
  AddFunc  ('OLE_SET_PROP','{=?}H��N��V��', 637, sys_com_setProperty,'COM��N��V��������B','OLE_SET_PROP');
  AddFunc  ('OLE_GET_PROP','{=?}H��N��', 636, sys_com_getProperty,'COM��N���擾���ĕԂ��B','OLE_GET_PROP');

function sys_com_create(args: DWORD): PHiValue; stdcall;
begin
  Result := nako_var_new(nil);
  Result.int := Integer(CreateOleObject(getArgStr(args,0,True)));
  Result.VType := varInt;
end;

function sys_com_setProperty(args: DWORD): PHiValue; stdcall;
var
  i: IDispatch;
  n: string;
  p, v: PHiValue;
begin
  // args
  p := nako_getFuncArg(args, 0); if p = nil then p := nako_getSore;
  //todo: IDispatch�̎󂯓n���Ɏ��s����
  n := getArgStr(args,1);
  v := nako_getFuncArg(args, 2);
  if i = nil then raise Exception.Create('OLE�I�u�W�F�N�g���쐬����Ă��܂���B');
  //
  case v.VType of
    varNil    : SetDispatchPropValue(i, n, Unassigned);
    varInt    : SetDispatchPropValue(i, n, hi_int(v));
    varFloat  : SetDispatchPropValue(i, n, hi_float(v));
    varStr    : SetDispatchPropValue(i, n, hi_str(v));
    else begin
      SetDispatchPropValue(i, n, hi_str(v));
    end;
  end;
  Result := nil;
end;

function sys_com_getProperty(args: DWORD): PHiValue; stdcall;
var
  i: IDispatch;
  n: string;
  v: OleVariant;
begin
  // args
  i := IDispatch(getArgInt(args,0,True));
  n := getArgStr(args,1);
  v := GetDispatchPropValue(i, n);
  Result := hi_newStr(v);
end;
*)

procedure RegistFunction;

  function RuntimeDir: string;
  begin
    Result := ExtractFilePath(ParamStr(0));
  end;

begin
  //todo 1: ���V�X�e���ϐ��֐�(FILE)
  //<�t�@�C���ϐ��֐�>

  //+�t�@�C��(nakofile.dll)
  //-�t�@�C�����p�X����
  //AddFunc  ('�t�@�C�������o', 'S����|S��',  20, sys_extractFile,'�p�XS����t�@�C���������𒊏o���ĕԂ��B','�ӂ�����߂����イ�����');
  //AddFunc  ('�p�X���o',       'S����|S��',  21, sys_extractFilePath,'�t�@�C����S����p�X�����𒊏o���ĕԂ��B','�ς����イ�����');
  //AddFunc  ('�g���q���o',     'S����|S��',  22, sys_extractExt,'�t�@�C����S����g���q�����𒊏o���ĕԂ��B','�������傤�����イ�����');
  //AddFunc  ('�g���q�ύX',     'S��A��|S��', 23, sys_changeExt,'�t�@�C����S�̊g���q��A�ɕύX���ĕԂ��B','�������傤���ւ񂱂�');
  //AddFunc  ('���j�[�N�t�@�C��������','A��B��|A��', 24, sys_makeoriginalfile,'�t�H���_A�Ńw�b�_B�������j�[�N�ȃt�@�C�����𐶐����ĕԂ��B','��Ɂ[���ӂ�����߂���������');
  //AddFunc  ('���΃p�X�W�J',   'A��B��',     25, sys_expand_path,'���΃p�X�`����{�p�X�a�œW�J���ĕԂ��B','���������ς��Ă񂩂�');
  AddFunc  ('�I�[�p�X�ǉ�','{=?}S��|S��|S��|S����',525, sys_pathFlagAdd,  '�t�H���_���̏I�[�Ɂu\�v�L�����Ȃ���΂��ĕԂ�','���イ����ς�����');
  AddFunc  ('�I�[�p�X�폜','{=?}S��|S��|S��|S����',526, sys_pathFlagDel,  '�t�H���_���̏I�[�Ɂu\�v�L��������΍폜���ĕԂ�','���イ����ς���������');
  AddFunc  ('������t�@�C�����ϊ�','{=?}S��|S��|S��|S����',527, sys_StrtoFileName,  '��������t�@�C�����Ƃ��Ďg����悤�ɕϊ����ĕԂ��B','������ӂ�����߂��ւ񂩂�');
  AddFunc  ('������UNIX�t�@�C�����ϊ�','{=?}S��|S��|S��|S����',528, sys_StrtoFileNameUnix,  '��������t�@�C�����Ƃ��Ďg����悤�ɕϊ����ĕԂ��B','������ӂ�����߂��ւ񂩂�');
  //-�J���ۑ�
  AddFunc  ('�ۑ�','{������=?}S��F��|F��',             500, sys_saveAll,  '������S�̓��e���t�@�C����F�֕ۑ�����B','�ق���');
  AddFunc  ('�J��','{�Q�Ɠn�� �ϐ�=?}V��F��|V��F����', 501, sys_loadAll,  '�ϐ�V(�ȗ������ꍇ�́w����x)�Ƀt�@�C����F�̓��e��ǂݍ��ށB','�Ђ炭');
  AddFunc  ('�ǂ�','{�Q�Ɠn�� �ϐ�=?}V��F��|V��F����', 502, sys_loadAll,  '�ϐ�V(�ȗ������ꍇ�́w����x)�Ƀt�@�C����F�̓��e��ǂݍ��ށB','�Ђ炭');
  AddFunc  ('�ǉ��ۑ�','{������=?}S��F��|F��',         504, sys_saveAllAdd,'������S�̓��e���t�@�C����F�֒ǉ��ۑ�����B','�����ق���');
  //-��s���ǂݏ���
  AddFunc  ('���s�ǂ�','{�Q�Ɠn�� �ϐ�=?}V��F��|V��F����', 503, sys_loadEveryLine,  '��s���ǂނ��߂Ƀt�@�C����F���J���ăn���h����Ԃ��B�����Ƒg�ݍ��킹�Ďg���B','�܂����傤���');
  AddFunc  ('�o�͐�ݒ�','F��|F��', 505, sys_set_outfile,  '�w�o�́x���߂̏o�͐�t�@�C��S���w�肷��B','�����傭���������Ă�');
  AddFunc  ('�o�͐�擾','', 506, sys_get_outfile,  '�w�o�́x���߂̏o�͐�t�@�C�������擾����B','�����傭��������Ƃ�');
  SetSetterGetter('�o�͐�t�@�C��','�o�͐�ݒ�','�o�͐�擾',507,'�w�o�́x���߂̏o�͐�t�@�C�����w�肷��B','�����傭�����ӂ�����');
  AddFunc  ('�o��','S��|S��', 509, sys_outfile_write, '�w�o�͐�x�Ŏw�肵���t�@�C���֕�����S+���s��ǋL����(�w��Ȃ��́u�Ȃł����o��.txt�v�֏o��)','�����傭');
  AddFunc  ('��s�o��','S��|S��', 508, sys_outfile_writeln, '�w�o�͐�x�Ŏw�肵���t�@�C���֕�����S+���s��ǋL����','�������傤�����傭');
  AddFunc  ('�o�͐揉����','', 510, sys_outfile_clear, '�w�o�͐�x�Ŏw�肵���t�@�C��������������','�����傭�������傫��');

  //-�N��
  AddFunc  ('�N��','{������=?}S��',                      520, sys_exec, '�t�@�C��S���N������B','���ǂ�');
  AddFunc  ('�N���ҋ@','{������=?}S��',                  521, sys_exec_wait, '�t�@�C��S���N�����ďI������܂őҋ@����B','���ǂ�������');
  AddFunc  ('�G�N�X�v���[���[�N��','{������=?}DIR��|DIR��|DIR��', 522, sys_exec_exp, '�t�H���_DIR���G�N�X�v���[���[�ŋN������B','�������Ղ�[��[���ǂ�');
  AddFunc  ('�B���N��','{������=?}S��', 523, sys_exec_open_hide, '�t�@�C��S�����I�t�ŋN������B','���������ǂ�');
  AddFunc  ('�B���N���ҋ@','{������=?}S��', 524, sys_exec_wait_hide, '�t�@�C��S�����I�t�ŋN�����ďI���܂őҋ@����B','���������ǂ�������');
  AddFunc  ('�R�}���h���s','{������=?}S��', 675, sys_exec_command, '�t�@�C��S�����I�t�ŋN�����ďI���܂őҋ@����B�N�������v���O�����̕W���o�͂̓��e��Ԃ��B','���܂�ǂ�������');
  AddFunc  ('�Ǘ��Ҍ������s','{������=?}S��', 676, sys_exec_admin, '�t�@�C��S���Ǘ��Ҍ����ŋN������B','����肵�Ⴏ�񂰂񂶂�����');
  //-�t�H���_����
  AddFunc  ('��ƃt�H���_�ύX','{������}S��|S��',      530, sys_setCurDir, '�J�����g�f�B���N�g����S�ɕύX����B','�����傤�ӂ��邾�ւ񂱂�');
  AddFunc  ('��ƃt�H���_�擾','',                     531, sys_getCurDir, '�J�����g�f�B���N�g�����擾���ĕԂ��B','�����傤�ӂ��邾����Ƃ�');
  SetSetterGetter('��ƃt�H���_', '��ƃt�H���_�ύX', '��ƃt�H���_�擾', 537, '�J�����g�f�B���N�g���̕ύX���s���B','�����傤���ӂ��邾');
  AddFunc  ('�t�H���_�쐬','S��|S��|S��',              532, sys_makeDir,   '�p�XS�Ƀt�H���_���쐬����B','�ӂ��邾��������');
  AddFunc  ('�t�H���_�폜','S��|S��|S����',            559, sys_removeDir, '�p�XS�̃t�H���_���폜����B(�t�H���_�͋�łȂ��Ă��ǂ�)','�ӂ��邾��������');
  //-�񋓁E����
  AddFunc  ('�t�@�C����','{������=?}S��|S��|S��',   533, sys_enumFiles,'�p�XS�ɂ���t�@�C����z��`���ŕԂ��B�u;�v�ŋ�؂��ĕ����̊g���q���w��\�B�������ȗ�����ƃJ�����g�f�B���N�g���̃t�@�C���ꗗ��Ԃ��B','�ӂ�����������');
  AddFunc  ('�t�H���_��','{������=?}S��|S��|S��',   534, sys_enumDirs, '�p�XS�ɂ���t�H���_��z��`���ŕԂ��B�������ȗ�����ƃJ�����g�f�B���N�g���̃t�H���_�ꗗ��Ԃ��B','�ӂ��邾�������');
  AddFunc  ('����','S��|S��',       535, sys_FileExists, '�p�XS�Ƀt�@�C�����t�H���_�����݂��邩�m�F���Ă͂�(=1)��������(=0)�ŕԂ�','���񂴂�');
  AddFunc  ('�S�t�@�C����','{������=?}S��|S��|S��', 536, sys_enumAllFiles,'�p�XS�ɂ���t�@�C�����T�u�t�H���_���܂ߔz��`���ŕԂ��B�u;�v�ŋ�؂��ĕ����̊g���q���w��\�B','����ӂ�����������');
  AddFunc  ('�S�t�H���_��','{������=?}S��|S��|S��', 680, sys_enumAllDir,'�p�XS�ɂ���t�H���_���ċA�I�Ɍ������Ĕz��`���ŕԂ��B�B','����ӂ��邾�������');
  //-�R�s�[�ړ��폜
  AddFunc  ('�t�@�C���R�s�[','A����B��|A��B��',540,sys_fileCopy,  '�t�@�C��A����B�փR�s�[����B','�ӂ����邱�ҁ[');
  AddFunc  ('�t�@�C���ړ�',  'A����B��|A��B��',541,sys_fileRename,  '�t�@�C��A����B�ֈړ�����B','�ӂ����邢�ǂ�');
  AddFunc  ('�t�@�C���폜',  'A��|A��',        542,sys_fileDelete,'�t�@�C��A���폜����(�S�~���ֈړ�)�B','�ӂ����邳������');
  AddFunc  ('�t�@�C�����ύX','A����B��|A��B��',543,sys_fileRename,'�t�@�C����A����B�֕ύX����B','�ӂ�����߂��ւ񂱂�');
  AddFunc  ('�t�H���_�R�s�[','A����B��|A��B��',544,sys_dirCopy,   '�t�H���_A����B�փR�s�[����B','�ӂ��邾���ҁ[');
  AddFunc  ('�t�@�C�����S�폜', 'A��|A��',     545,sys_fileDeleteAll,'�t�@�C��A�����S�ɍ폜����B(�S�~���ֈړ����Ȃ�)','�ӂ����邩�񂺂񂳂�����');
  AddFunc  ('�t�@�C�����o�R�s�[', 'A����B��|A��B��',546,sys_fileCopyEx,'�t�H���_A(�p�X+���C���h�J�[�h���X�g�u;�v�ŋ�؂�)����t�H���_B�֔C�ӂ̃t�@�C���݂̂��R�s�[����','�ӂ����邿�イ������ҁ[');
  AddStrVar('�t�@�C�����o�R�s�[���O�p�^�[��','Thumbs.db',547,'�t�@�C�����o�R�s�[�ŏ��O����p�^�[������s���ƃ��C���h�J�[�h�Ŏw�肷��B','�ӂ����邿�イ������ҁ[���傪���ς��[��');
  //-�V���[�g�J�b�g
  AddFunc  ('�V���[�g�J�b�g�쐬','A��B��|A��B��', 555, sys_shortcut,'�A�v���P�[�V����A�̃V���[�g�J�b�g��B�ɍ��','����[�Ƃ����Ƃ�������');
  AddFunc  ('�V���[�g�J�b�g�ڍ׍쐬','A��B��C��|A��B��', 553, sys_shortcut_ex,'�A�v���P�[�V����A�̃V���[�g�J�b�g��B�Ƀn�b�V��C�̐ݒ�ō��','����[�Ƃ����Ƃ��傤������������');
  AddFunc  ('�V���[�g�J�b�g�����N��擾','A��', 554, sys_get_shortcut,'�V���[�g�J�b�gA�̃����N����擾����B','����[�Ƃ����Ƃ�񂭂�������Ƃ�');
  //-�t�@�C�����
  AddFunc  ('�t�@�C���T�C�Y','F��',           556, sys_getFileSize,'�t�@�C��F�̃T�C�Y��Ԃ�','�ӂ����邳����');
  AddFunc  ('�t�@�C�����t','F��',             557, sys_getFileDate,'�t�@�C��F�̓��t��Ԃ�','�ӂ�����ЂÂ�');
  AddFunc  ('�t�@�C���쐬����','F��',         621, sys_getCreateFileDate,'�t�@�C��F�̍쐬������Ԃ�','�ӂ�����ЂÂ�');
  AddFunc  ('�t�@�C���X�V����','F��',         622, sys_getWriteFileDate,'�t�@�C��F�̍X�V������Ԃ�','�ӂ����邱������ɂ���');
  AddFunc  ('�t�@�C���ŏI�A�N�Z�X����','F��', 623, sys_getLastAccessFileDate,'�t�@�C��F�̍ŏI�A�N�Z�X������Ԃ�','�ӂ����邳�����イ���������ɂ���');
  AddFunc  ('�t�@�C���쐬�����ύX','{=?}F��S��|S��',  624, sys_setFileDateCreate,'�t�@�C��F�̍쐬������S�ɐݒ肷��','�ӂ����邳�������ɂ����ւ񂱂�');
  AddFunc  ('�t�@�C���X�V�����ύX','{=?}F��S��|S��',  625, sys_setFileDateWrite,'�t�@�C��F�̍X�V������S�ɐݒ肷��','�ӂ����邱������ɂ����ւ񂱂�');
  AddFunc  ('�t�@�C���ŏI�A�N�Z�X�����ύX','{=?}F��S��|S��',  626, sys_setFileDateLastAccess,'�t�@�C��F�̍ŏI�A�N�Z�X������S�ɐݒ肷��','�ӂ����邳�����イ���������ɂ����ւ񂱂�');
  AddFunc  ('�t�@�C�������擾','{=?}F��',         627, sys_getFileAttr,'�t�@�C��F�̑������擾����','�ӂ����邼����������Ƃ�');
  AddFunc  ('�t�@�C�������ݒ�','{=?}F��S��|S��',  628, sys_setFileAttr,'�t�@�C��F�̑�����ݒ肷��','�ӂ����邼�����������Ă�');
  AddIntVar('�A�[�J�C�u����',   $20,  640, '�t�@�C������','���[�����Ԃ�������');
  AddIntVar('�f�B���N�g������', $10,  641, '�t�@�C������','�ł��ꂭ�Ƃ肼������');
  AddIntVar('�B���t�@�C������', $2,   642, '�t�@�C������','�������ӂ����邼������');
  AddIntVar('�ǂݍ��ݐ�p����', $1,   643, '�t�@�C������','��݂��݂���悤��������');
  AddIntVar('�V�X�e���t�@�C������',$4,644, '�t�@�C������','�����Ăނӂ����邼������');
  AddIntVar('�m�[�}������',     $80,  645, '�t�@�C������','�́[�܂邼������');
  AddFunc  ('�t�H���_����','{=?}F��',  639, sys_ExistsDir,'�t�H���_F�����݂���̂����ׂāA�͂�(=1)��������(=0)�ŕԂ��B','�ӂ��邾���񂴂�');
  AddFunc  ('�����t�@�C�����擾','{=?}F��',  673, sys_getLongFileName,'�����t�@�C����(�����O�t�@�C��)��Ԃ��B','�Ȃ����ӂ�����߂�����Ƃ�');
  AddFunc  ('�Z���t�@�C�����擾','{=?}F��',  674, sys_getShortFileName,'�Z���t�@�C����(�V���[�g�t�@�C��)��Ԃ��B','�݂������ӂ�����߂�����Ƃ�');

  //-�h���C�u���
  AddFunc  ('�g�p�\�h���C�u�擾','',646, sys_getLogicalDrives,'�g�p�\�h���C�u�̈ꗗ�𓾂�','���悤���̂��ǂ炢�Ԃ���Ƃ�');
  AddFunc  ('�h���C�u���','{=?}A��',647, sys_getDriveType,'���[�g�h���C�u�`�̎��(�s��|���݂��Ȃ�|���O���\|�Œ�|�l�b�g���[�N|CD-ROM|RAM)��Ԃ��B','�ǂ炢�Ԃ���邢');
  AddFunc  ('�f�B�X�N�T�C�Y','{=?}A��',648, sys_getDiskSize,'�f�B�X�N�`�̑S�̂̃o�C�g����Ԃ��B','�ł�����������');
  AddFunc  ('�f�B�X�N�󂫃T�C�Y','{=?}A��',649, sys_getDiskFreeSize,'�f�B�X�N�`�̗��p�\�󂫃o�C�g����Ԃ��B','�ł���������������');
  AddFunc  ('�{�����[�����擾','{=?}A��',665, sys_getVolumeName,'�f�B�X�N�`�̃{�����[������Ԃ��B','�ڂ��[�ނ߂�����Ƃ�');
  AddFunc  ('�f�B�X�N�V���A���ԍ��擾','{=?}A��',666, sys_getSerialNo,'�f�B�X�N�`�̃V���A���ԍ���Ԃ��B','�ł��������肠��΂񂲂�����Ƃ�');
  AddFunc  ('�n�[�h�E�F�A���O���N��','',672, sys_showHotplugDlg,'�n�[�h�E�F�A���O���_�C�A���O��\������','�́[�ǂ������Ƃ�͂������ǂ�');

  //-�R���\�[��
  //AddFunc  ('�W�����͎擾','CNT��', 558, nil,'CNT�o�C�g�̕W�����͂��擾����(�R���\�[���̂�)','�Ђ傤�����ɂイ��傭����Ƃ�');
  //-�X�g���[������
  AddFunc  ('�t�@�C���X�g���[���J��',  'A��B��',   561, sys_file_h_open,  '�t�@�C����A�����[�hB(��|��|��|�r��)�ŃX�g���[�����J���n���h����Ԃ��B','�ӂ����邷�Ƃ�[�ނЂ炭');
  AddFunc  ('�t�@�C���X�g���[���ǂ�',  'H��CNT��', 562, sys_file_h_read,  '�t�@�C���X�g���[���n���h��H��CNT�o�C�g�ǂ�ŕԂ��B','�ӂ����邷�Ƃ�[�ނ��');
  AddFunc  ('�t�@�C���X�g���[������',  'H��S��',   563, sys_file_h_write, '�t�@�C���X�g���[���n���h��H��(S�̃o�C�g����)������S�������B�����Ԃ��Ȃ��B','�ӂ����邷�Ƃ�[�ނ���');
  AddFunc  ('�t�@�C���X�g���[������','H��',      564, sys_file_h_close, '�t�@�C���X�g���[���n���h��H�����B','�ӂ����邷�Ƃ�[�ނƂ���');
  AddFunc  ('�t�@�C���X�g���[���ʒu�擾','H��',    565, sys_file_h_getpos,'�t�@�C���X�g���[���n���h��H�̈ʒu���擾����','�ӂ����邷�Ƃ�[�ނ�������Ƃ�');
  AddFunc  ('�t�@�C���X�g���[���ʒu�ݒ�','H��I��', 566, sys_file_h_setpos,'�t�@�C���X�g���[���n���h��H�̈ʒu��I�ɐݒ肷��','�ӂ����邷�Ƃ�[�ނ��������Ă�');
  AddFunc  ('�t�@�C���X�g���[���T�C�Y','H��',  567, sys_file_h_size,  '�t�@�C���X�g���[���n���h��H�ŊJ�����t�@�C���̃T�C�Y��Ԃ�','�ӂ����邷�Ƃ�[�ނ�����');
  AddFunc  ('�t�@�C���X�g���[����s�ǂ�',  'H��|H��', 568, sys_file_h_readLine,  '�t�@�C���X�g���[���n���h��H�ň�s�ǂ�ŕԂ��B','�ӂ����邷�Ƃ�[�ނ������傤���');
  AddFunc  ('�t�@�C���X�g���[����s����',  '{=?}S��H��|H��|H��', 569, sys_file_h_writeLine,  '�t�@�C���X�g���[���n���h��H��S����s����','�ӂ����邷�Ƃ�[�ނ������傤����');

  //+���k��(nakofile.dll)
  //-���k��
  AddFunc('���k','A��B��|A����B��', 570, sys_compress, '�p�XA���t�@�C��B�ֈ��k����B','�������キ','7-zip32.dll,UNLHA32.DLL');
  AddFunc('��','A��B��|A����B��', 571, sys_extract, '�t�@�C��A���p�XB�։𓀂���B','�����Ƃ�','7-zip32.dll,UNLHA32.DLL');
  AddFunc('���ȉ𓀏��ɍ쐬','A��B��|A����', 572, sys_makesfx, '�p�XA���t�@�C��B�֎��ȉ𓀏��ɂ��쐬����','���������Ƃ����傱��������','7-zip32.dll,UNLHA32.DLL');
  AddFunc('���k�𓀎��s','TYPE��CMD��|CMD��', 573, sys_archive_command, 'TYPE(�g���q)�ŃA�[�J�C�oDLL�փR�}���hCMD�𒼐ڎ��s����','�������キ�����Ƃ���������','7-zip32.dll,UNLHA32.DLL');
  //+���W�X�g��/INI�t�@�C��(nakofile.dll)
  //-���W�X�g��
  AddFunc  ('���W�X�g���J��','S��', 580, sys_registry_open,'���W�X�g���p�XS���J���ăn���h����Ԃ�','�ꂶ���Ƃ�Ђ炭');
  AddFunc  ('���W�X�g������','H��|H��', 581, sys_registry_close,'���W�X�g���̃n���h��H�����','�ꂶ���Ƃ�Ђ炭');
  AddFunc  ('���W�X�g������','H��S��A��', 582, sys_registry_write,'���W�X�g���̃n���h��H���g���ăL�[S�ɕ�����A������','�ꂶ���Ƃ肩��');
  AddFunc  ('���W�X�g����������','H��S��A��', 583, sys_registry_writeInt,'���W�X�g���̃n���h��H���g���ăL�[S�ɐ���A������','�ꂶ���Ƃ肹����������');
  AddFunc  ('���W�X�g���L�[�폜','H��S��', 584, sys_registry_deleteKey,'���W�X�g���̃n���h��H���g���ăL�[S���폜����','�ꂶ���Ƃ肫�[��������');
  AddFunc  ('���W�X�g���l�폜','H��S��', 585, sys_registry_deleteVal,'���W�X�g���̃n���h��H���g���ĒlS���폜����','�ꂶ���Ƃ肠������������');
  AddFunc  ('���W�X�g���L�[��','H��', 586, sys_registry_enumKeys,'���W�X�g���̃n���h��H�̃L�[����񋓂���','�ꂶ���Ƃ肫�[�������');
  AddFunc  ('���W�X�g���l��','H��', 587, sys_registry_enumValues,'���W�X�g���̃n���h��H���g���Ēl��񋓂���','�ꂶ���Ƃ肠�����������');
  AddFunc  ('���W�X�g���ǂ�','H��S��', 588, sys_registry_read,'���W�X�g���̃n���h��H���g����S��ǂ�ŕԂ�','�ꂶ���Ƃ���');
  AddFunc  ('���W�X�g�������ǂ�','H��S��', 589, sys_registry_readInt,'���W�X�g���̃n���h��H���g���Đ���S��ǂ�ŕԂ�','�ꂶ���Ƃ肹���������');
  AddFunc  ('���W�X�g���L�[����','S��|S��', 590, sys_registry_KeyExists,'���W�X�g���̃L�[S�����݂��邩���ׂ�B','�ꂶ���Ƃ肫�[���񂴂�');
  AddFunc  ('���W�X�g���l�ݒ�','KEY��V��S��|V��S��', 657, sys_reg_easy_write,'���W�X�g���L�[KEY�̒lV�ɕ�����S���������ށB�n���h������s�v�ŁB','�ꂶ���Ƃ肠���������Ă�');
  AddFunc  ('���W�X�g���l�擾','KEY��V����|V��', 658, sys_reg_easy_read,'���W�X�g���L�[KEY�̒lV�̒l��ǂށB�n���h������s�v�ŁB','�ꂶ���Ƃ肠��������Ƃ�');
  AddFunc  ('���W�X�g���o�C�i���ǂ�','{=?}H��S��CNT��', 670, sys_registry_read_bin,'���W�X�g���̃n���h��H�������ĒlS��CNT�o�C�g�ǂށB','�ꂶ���Ƃ�΂��Ȃ���');
  AddFunc  ('���W�X�g���o�C�i������','{=?}H��S��V��CNT��', 671, sys_registry_write_bin,'���W�X�g���̃n���h��H�������ĒlS�Ƀf�[�^V��CNT�o�C�g�ǂށB','�ꂶ���Ƃ�΂��Ȃ���');
  //-INI�t�@�C��
  AddFunc  ('INI�J��','F��', 591, sys_ini_open,'INI�t�@�C��F���J���ăn���h����Ԃ�','INI�Ђ炭');
  AddFunc  ('INI����','H��|H��', 592, sys_ini_close,'INI�t�@�C���̃n���h��H�����','INI�Ƃ���');
  AddFunc  ('INI�ǂ�','H��A��B��', 593, sys_ini_read,'INI�t�@�C���̃n���h��H�ŃZ�N�V�����`�̃L�[�a��ǂށB','INI���');
  AddFunc  ('INI����','H��A��B��S��|', 594, sys_ini_write,'INI�t�@�C���̃n���h��H�ŃZ�N�V�����`�̃L�[�a�ɒl�r�������B','INI����');
  //-�V�F��
  AddFunc  ('�֘A�t���V�X�e���ʒm','', 650, sys_SHChangeNotify,'�֘A�t���̍X�V���V�X�e���ɒʒm����B','������Â������Ăނ���');
  AddFunc  ('�֘A�t��','S��A��|A��', 655, sys_kanrenduke,'�g���qS���A�v���P�[�V����A�Ɗ֘A�t������','������Â�');
  AddFunc  ('�֘A�t������','S��|S��', 656, sys_kanrendukekaijo,'�g���qS�̊֘A�t������������','������Â���������');
  //-�ǎ�
  AddFunc  ('�ǎ��ݒ�','{=?}F��|F��', 651, sys_ChangeWallpaper,'�摜�t�@�C��F�ɕǎ���ύX����B','���ׂ��݂ւ񂱂�');
  AddFunc  ('�ǎ��擾','', 652, sys_getWallpaper,'�ǎ��̃t�@�C�������擾����B','���ׂ��݂���Ƃ�');
  AddFunc  ('�ǎ��X�^�C���ݒ�','{=?}A��|A��', 653, sys_ChangeWallpaperStyle,'�ǎ��̃X�^�C��A(����|�g��|�^�C��)�ɕύX����','���ׂ��݂�������ւ񂱂�');
  AddFunc  ('�ǎ��X�^�C���擾','', 654, sys_getWallpaperStyle,'�ǎ��̃X�^�C�����擾����B','���ׂ��݂������邵��Ƃ�');
  //-�X�N���[���Z�[�o�[
  AddFunc  ('�X�N���[���Z�C�o�[�擾','', 681, sys_getScr,'�X�N���[���Z�C�o�[�̃t�@�C�������擾����B','������[�񂹂��΁[����Ƃ�');
  AddFunc  ('�X�N���[���Z�C�o�[�ݒ�','{=?}FILE��|FILE��', 682, sys_setScr,'�X�N���[���Z�C�o�[�Ƃ��ăt�@�C����FILE��ݒ肷��B','������[�񂹂��΁[�����Ă�');
  AddFunc  ('�X�N���[���Z�C�o�[�҂����Ԏ擾','', 683, sys_getScrTime,'�X�N���[���Z�C�o�[�̑҂����Ԃ�b�Ŏ擾����B','������[�񂹂��΁[�܂������񂵂�Ƃ�');
  AddFunc  ('�X�N���[���Z�C�o�[�҂����Ԑݒ�','{=?}V��|V��', 684, sys_setScrTime,'�X�N���[���Z�C�o�[�̑҂����Ԃ�V�b�ɐݒ肷��B','������[�񂹂��΁[�܂������񂹂��Ă�');
  AddFunc  ('�X�N���[���Z�C�o�[�N��','', 685, sys_runScr,'�ݒ肳��Ă���X�N���[���Z�C�o�[���N������','������[�񂹂��΁[���ǂ�');


  //+����t�H���_(nakofile.dll)
  //-�p�X
  AddFunc  ('WINDOWS�p�X',  '',                 600, sys_WinDir,'Windows�̃C���X�g�[���p�X��Ԃ�','WINDOWS�ς�');
  AddFunc  ('SYSTEM�p�X',   '',                 601, sys_SysDir,'System�t�H���_�̃p�X��Ԃ�','SYSTEM�ς�');
  AddFunc  ('�e���|�����t�H���_', '',           602, sys_TempDir,'��Ɨp�̃e���|�����t�H���_�̃p�X�𓾂ĕԂ�','�Ă�ۂ��ӂ��邾');
  AddFunc  ('�f�X�N�g�b�v',       '',           603, sys_DesktopDir,'�f�X�N�g�b�v�̃t�H���_�̃p�X��Ԃ�','�ł����Ƃ���');
  AddFunc  ('SENDTO�p�X',         '',           604, sys_SendToDir,'�u����v���j���[�̃t�H���_�̃p�X��Ԃ�','SENDTO�ς�');
  AddFunc  ('�X�^�[�g�A�b�v',     '',           605, sys_StartUpDir,'Windows���N���������Ɏ����I�Ɏ��s����u�X�^�[�g�A�b�v�v�̃t�H���_�p�X��Ԃ�','�����[�Ƃ�����');
  AddFunc  ('RECENT�p�X',        '',            606, sys_RecentDir,'','RECENT�ς�');
  AddFunc  ('�X�^�[�g���j���[',  '',            607, sys_ProgramsDir,'�X�^�[�g���j���[\�v���O�����̃t�H���_�̃p�X�Ԃ�','�����[�Ƃ߂ɂ�[');//�X�^�[�g���j���[\�v���O����\
  AddFunc  ('�}�C�h�L�������g',  '',            608, sys_MyDocumentDir, '�}�C�h�L�������g�̃t�H���_�̃p�X��Ԃ�','�܂��ǂ���߂��');
  AddFunc  ('FAVORITES�p�X',     '',            609, sys_FavoritesDir,'','FAVORITES�ς�');
  AddFunc  ('���C����t�H���_',  '',            610, sys_FavoritesDir,'','�����ɂ���ς�');
  AddFunc  ('�}�C�~���[�W�b�N',  '',            612, sys_MyMusicDir,'','�܂��݂�[������');
  AddFunc  ('�}�C�s�N�`���[',    '',            613, sys_MyPictureDir,'','�܂��҂�����[');
  AddFunc  ('�}�C�s�N�`��',      '',            669, sys_MyPictureDir,'','�܂��҂�����');
  AddFunc  ('�t�H���g�p�X',      '',            614, sys_FontsDir,'','�ӂ���Ƃς�');
  AddFunc  ('PROGRAMFILES�p�X',  '',            615, sys_ProgramFilesDir,'','PROGRAMFILES�ς�');
  AddFunc  ('OE5���[���t�H���_',  '',           618, sys_getOE5,'Outlook Express5/6�̃��[�����ۑ�����Ă���t�H���_���擾���ĕԂ�','OE5�߁[��ӂ��邾');
  AddFunc  ('BECKY2���[���t�H���_','',          619, sys_getBecky2,'Becky!Ver.2�̃��[�����ۑ�����Ă���t�H���_���擾���ĕԂ�','Becky2�߁[��ӂ��邾');
  AddFunc  ('���ϐ��W�J','{=?}S��|S��|S��',   620, sys_expandEnv,'�u%UserProfiel%aaa\bbb�v�̂悤�Ȋ��ϐ����܂ރp�X��W�J���ĕԂ�','���񂫂傤�ւ񂷂��Ă񂩂�');
  AddFunc  ('����p�X�擾','{=?}A��|A��',       660, sys_sp_path,'����p�X(CSIDL_xxx)A���w�肵�ē���p�X�𒲂ׂĕԂ�','�Ƃ�����ς�����Ƃ�');
  AddFunc  ('���ʃX�^�[�g�A�b�v','',            661, get_CSIDL_COMMON_STARTUP,'','���傤�������[�Ƃ�����');
  AddFunc  ('���ʃf�X�N�g�b�v','',              662, get_CSIDL_COMMON_DESKTOPDIRECTORY,'','���傤���ł����Ƃ���');
  AddFunc  ('���ʃ}�C�h�L�������g','',          663, get_CSIDL_COMMON_DOCUMENTS,'','���傤���܂��ǂ���߂��');
  AddFunc  ('���ʐݒ�t�H���_','',              611, get_CSIDL_COMMON_APPDATA,'���ʂ�APPDATA�t�H���_','���傤�������Ă��ӂ��邾');
  AddFunc  ('�l�ݒ�t�H���_','',              664, get_CSIDL_LOCAL_APPDATA,'���[�U�[���Ƃ�APPDATA�t�H���_','�����񂹂��Ă��ӂ��邾');
  AddFunc  ('���[�U�[�z�[���t�H���_','',        659, get_USER_PROFILE,'%USERPROFILE%','��[���[�ف[�ނӂ��邾');
  AddFunc  ('�A�v���ݒ�t�H���_','',            638, get_APPDATA,'%APPDATA%','���Ղ肹���Ă��ӂ��邾');
  AddFunc  ('���郁�j���[�t�H���_','',          637, get_SENDTO,'���郁�j���[�̃p�X','������߂ɂ�[�ӂ��邾');
  AddFunc  ('�N�C�b�N�N���t�H���_','',          629, get_QUICKLAUNCH,'���郁�j���[�̃p�X','�����������ǂ��ӂ��邾');
  AddFunc  ('COMSPEC','',                       667, get_COMSPEC,'�V�F��(CMD.EXE)�̎��','COMSPEC');
  AddFunc  ('�V�X�e���h���C�u','',              668, get_SYSTEMDRIVE,'Windows���C���X�g�[������Ă���h���C�u��Ԃ�','�����Ăނǂ炢��');
  //-�Ȃł����p�X
  AddStrVar('�����^�C���p�X',{''}RuntimeDir, 616, '�Ȃł����̎��s�t�@�C���̃p�X','��񂽂��ނς�');
  AddStrVar('��̓p�X',{''}'', 617, '���s�����v���O�����̃p�X','�ڂ���ς�');


  //+LAN(nakofile.dll)
  //-�R���s���[�^�[���
  AddFunc  ('���[�U�[���擾','', 630, sys_getUserName,'���O�I�����[�U�[����Ԃ��B','��[���[�߂�����Ƃ�');
  AddFunc  ('�R���s���[�^�[���擾','', 631, sys_getComputerName,'�R���s���[�^�[�̋��L����Ԃ�','����҂�[���[�߂�����Ƃ�');
  //-LAN���L�R���s���[�^�[���
  AddFunc  ('�h���C����','', 632, sys_LanEnumDomain,'LAN��̃h���C����񋓂��ĕԂ��B','�ǂ߂���������');
  AddFunc  ('�R���s���[�^�[��','{=?}DOMAIN��', 633, sys_LanEnumComputer,'LAN���DOMAIN�ɑ�����R���s���[�^�[��񋓂��ĕԂ��B','����҂�[���[�������');
  AddFunc  ('���L�t�H���_��','{=?}COM��', 634, sys_LanEnumCommonDir,'LAN���COM�̋��L�t�H���_��񋓂��ĕԂ��B','���傤�䂤�ӂ��邾�������');
  AddFunc  ('�l�b�g���[�N�h���C�u�ڑ�','A��B��{=�u�v}USER��{=�u�v}PASS��|A��B��', 635, sys_WNetAddConnection2,'�h���C�uA�Ƀl�b�g���[�N�t�H���_B�����蓖�Ă�B�ڑ����[�U��USER�ƃp�X���[�hPASS�͏ȗ��\�B','�˂��Ƃ�[���ǂ炢�Ԃ�����');
  AddFunc  ('�l�b�g���[�N�h���C�u�ؒf','A��|A��', 636, sys_WNetCancelConnection2,'�h���C�uA�Ɋ��蓖�Ă�ꂽ�l�b�g���[�N�t�H���_��ؒf����B','�˂��Ƃ�[���ǂ炢�Ԃ�����');
  //-nakofile.dll
  AddFunc  ('NAKOFILE_DLL�o�[�W����','', 690, getNakoFileDllVersion,'nakofile.dll�̃o�[�W�����𓾂�','NAKOFILE_DLL�΁[�����');
  //</�t�@�C���ϐ��֐�>

end;



{ THiSystemDummy }

constructor THiSystemDummy.Create;
begin
end;

function THiSystemDummy.mixReader: TFileMixReader;
begin
  FileMixReader := TFileMixReader(nako_getPackFileHandle);
  Result := FileMixReader;
end;

function THiSystemDummy.Sore: PHiValue;
begin
  Result := nako_getSore;
end;



initialization
  HiSystem := THiSystemDummy.Create;
  outfile := nil;
  OleInitialize(nil);

finalization
  FreeAndNil(outfile);
  HiSystem.Free;
  OleUninitialize;



  
end.
