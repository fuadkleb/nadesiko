{$A8,B-,C+,D+,E-,F-,G+,H+,I+,J-,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$MINSTACKSIZE $00004000}
{$MAXSTACKSIZE $00100000}
{$IMAGEBASE $00400000}
{$APPTYPE GUI}
{$WARN SYMBOL_DEPRECATED ON}
{$WARN SYMBOL_LIBRARY ON}
{$WARN SYMBOL_PLATFORM ON}
{$IFDEF VER150}
{$ELSE}
{$WARN SYMBOL_EXPERIMENTAL ON}
{$WARN UNIT_LIBRARY ON}
{$WARN UNIT_PLATFORM ON}
{$WARN UNIT_DEPRECATED ON}
{$WARN UNIT_EXPERIMENTAL ON}
{$ENDIF}
{$WARN HRESULT_COMPAT ON}
{$WARN HIDING_MEMBER ON}
{$WARN HIDDEN_VIRTUAL ON}
{$WARN GARBAGE ON}
{$WARN BOUNDS_ERROR ON}
{$WARN ZERO_NIL_COMPAT ON}
{$WARN STRING_CONST_TRUNCED ON}
{$WARN FOR_LOOP_VAR_VARPAR ON}
{$WARN TYPED_CONST_VARPAR ON}
{$WARN ASG_TO_TYPED_CONST ON}
{$WARN CASE_LABEL_RANGE ON}
{$WARN FOR_VARIABLE ON}
{$WARN CONSTRUCTING_ABSTRACT ON}
{$WARN COMPARISON_FALSE ON}
{$WARN COMPARISON_TRUE ON}
{$WARN COMPARING_SIGNED_UNSIGNED ON}
{$WARN COMBINING_SIGNED_UNSIGNED ON}
{$WARN UNSUPPORTED_CONSTRUCT ON}
{$WARN FILE_OPEN ON}
{$WARN FILE_OPEN_UNITSRC ON}
{$WARN BAD_GLOBAL_SYMBOL ON}
{$WARN DUPLICATE_CTOR_DTOR ON}
{$WARN INVALID_DIRECTIVE ON}
{$WARN PACKAGE_NO_LINK ON}
{$WARN PACKAGED_THREADVAR ON}
{$WARN IMPLICIT_IMPORT ON}
{$WARN HPPEMIT_IGNORED ON}
{$WARN NO_RETVAL ON}
{$WARN USE_BEFORE_DEF ON}
{$WARN FOR_LOOP_VAR_UNDEF ON}
{$WARN UNIT_NAME_MISMATCH ON}
{$WARN NO_CFG_FILE_FOUND ON}
{$WARN IMPLICIT_VARIANTS ON}
{$WARN UNICODE_TO_LOCALE ON}
{$WARN LOCALE_TO_UNICODE ON}
{$WARN IMAGEBASE_MULTIPLE ON}
{$WARN SUSPICIOUS_TYPECAST ON}
{$WARN PRIVATE_PROPACCESSOR ON}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$IFDEF VER150}
{$ELSE}
{$WARN OPTION_TRUNCATED ON}
{$WARN WIDECHAR_REDUCED ON}
{$WARN DUPLICATES_IGNORED ON}
{$WARN UNIT_INIT_SEQ ON}
{$WARN LOCAL_PINVOKE ON}
{$ENDIF}
{$WARN MESSAGE_DIRECTIVE ON}




unit unit_file;
//------------------------------------------------------------------------------
// �t�@�C�����o�͂Ɋւ���ėp�I�ȃ��j�b�g
// [�쐬] �N�W����s��
// [�A��] http://kujirahand.com/
// [���t] 2004/07/28
//
interface

uses
  Windows, SysUtils, hima_types, ShellApi, comobj, shlobj, activex;

type
  TWindowState2 = (ws2Normal, ws2Minimized, ws2Maximized);




// ������Ƀt�@�C���̓��e��S���J��
function FileLoadAll(Filename: AnsiString): AnsiString;

// ������Ƀt�@�C���̓��e��S����������
procedure FileSaveAll(s, Filename: AnsiString);

//COPY
function SHFileCopy(const Source, Dest, Title: AnsiString): Boolean;
function SHFileDelete(const Source: AnsiString): Boolean;
function SHFileDeleteComplete(const Source: AnsiString): Boolean;
function SHFileMove(const Source, Dest: AnsiString): Boolean;
function SHFileRename(const Source, Dest: AnsiString): Boolean;

//EnumFile
function EnumFiles(path: AnsiString): THStringList;
function EnumAllFiles(path: AnsiString; out basePath: AnsiString): THStringList; overload;
function EnumAllFiles(path: AnsiString): THStringList; overload;
function EnumAllDirs(path: AnsiString): THStringList;
function EnumDirs(const path: AnsiString): THStringList;
function CreateShortCut(SavePath, TargetApp, Arg, WorkDir: AnsiString; State: TWindowState2): Boolean;
function CreateShortCutEx(SavePath, TargetApp, Arg, WorkDir, IconPath: AnsiString;
    IconNo:Integer;Comment: AnsiString;Hotkey:Word; State: TWindowState2): Boolean;
function GetShortCutLink(Path : AnsiString): AnsiString;

//�t�@�C���̍쐬�E�X�V�E�ŏI���������𓾂�
function GetFileTimeEx(fname:string; var tCreation, tLastAccess, tLastWrite:TDateTime):Boolean;
function SetFileTimeEx(fname:string; tCreation, tLastAccess, tLastWrite: TDateTime): Boolean;
//TDateTime����t�@�C�������𓾂�
function DateTimeToFileTimeEx(dt: TDateTime):TFileTime;
// �t�@�C���^�C�������[�J����TTimeDate�ɕϊ�����
function FileTimeToDateTimeEx(const ft:TFileTime):TDateTime;

function getVolumeName(drive: AnsiString): AnsiString;
function getSerialNo(drive: AnsiString): DWORD;
function getFileSystemName(drive: AnsiString): AnsiString;

function ShortToLongFileName(ShortName: AnsiString):String;
function LongToShortFileName(LongName: AnsiString):String;
procedure RunAsAdmin(hWnd: THandle; aFile: AnsiString; aParameters: AnsiString);

function DelphiDateTimeToUnix(ConvDate:TdateTime):longint;
function UnixToDelphiDateTime(USec:longint):TDateTime;

var MainWindowHandle: THandle = 0;

const
  HOTKEYF_SHIFT = $01;
  HOTKEYF_CONTROL = $02;
  HOTKEYF_ALT = $04;
  HOTKEYF_EXT = $08;

const
  UnixStartDate : tdatetime = 25569.0;
  TENTHOFSEC=100;
  SECOND=1000;
  MINUTE=60000;
  HOUR=3600000;
  DAY=86400000;
  SECONDSPERDAY=86400;

implementation

uses
  unit_windows_api, unit_string;

function DelphiDateTimeToUnix(ConvDate:TdateTime):longint;
   // Converts Delphi TDateTime to Unix seconds,
   //  ConvDate = the Date and Time that you want to convert
   //  example:   UnixSeconds:=DelphiDateTimeToUnix(Now);
begin
  Result:=round((ConvDate-UnixStartDate)*SECONDSPERDAY);
end;

function UnixToDelphiDateTime(USec:longint):TDateTime;
{Converts Unix seconds to Delphi TDateTime,
   USec = the Unix Date Time that you want to convert
   example:  DelphiTimeDate:=UnixToDelphiTimeDate(693596);}
begin
  Result:=(Usec/SECONDSPERDAY)+UnixStartDate;
end;

procedure RunAsAdmin(hWnd: THandle; aFile: AnsiString; aParameters: AnsiString);
var
  sei: TShellExecuteInfoA;
begin
  ZeroMemory(@sei, SizeOf(sei));
  sei.cbSize := SizeOf(sei);
  sei.Wnd := hWnd;
  sei.fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_FLAG_NO_UI;
  sei.lpVerb := 'runas';
  sei.lpFile := PAnsiChar(aFile);
  sei.lpParameters := PAnsiChar(aParameters);
  sei.nShow := SW_SHOWNORMAL;
  if not ShellExecuteEx(@sei) then
    raise Exception.Create('�N���Ɏ��s���܂����B(' + aFile + ')');
end;

function ShortToLongFileName(ShortName: AnsiString):String;
var
  SearchRec: TSearchRec;
begin
  result:= '';
  // �t���p�X��
  ShortName:= ExpandFileName(ShortName);
  // �������O�ɕϊ��i�f�B���N�g�����j
  while LastDelimiter('\', ShortName) >= 3 do begin
    if FindFirst(ShortName, faAnyFile, SearchRec) = 0 then
      try
        result := '\' + SearchRec.Name + result;
      finally
        // ���������Ƃ����� Close -> [Delphi-ML:17508] ���Q��
        FindClose(SearchRec);
      end
    else
      // �t�@�C����������Ȃ���΂��̂܂�
      result := '\' + ExtractFileName(ShortName) + result;
    ShortName := ExtractFilePath(ShortName);
    SetLength(ShortName, Length(ShortName)-1); // �Ō�� '\' ���폜
  end;
  result := ShortName + result;
end;

function LongToShortFileName(LongName: AnsiString):String;
var
  tmp: AnsiString;
begin
  SetLength(tmp, MAX_PATH + 1);
  GetShortPathNameA(PAnsiChar(LongName), PAnsiChar(tmp), MAX_PATH);
  Result := string(PAnsiChar(tmp));
end;

function getVolumeName(drive: AnsiString): AnsiString;
var
  fi: SHFILEINFOA;
begin
  if Length(drive) = 1 then drive := drive + ':\';
  //
  SHGetFileInfoA(PAnsiChar(drive), 0, fi, sizeof(SHFILEINFO), SHGFI_DISPLAYNAME);
  Result := string(fi.szDisplayName);
end;

function getFileSystemName(drive: AnsiString): AnsiString;
var
	SystemName: array [0..1000] of Char;
	SerialNumber: DWORD;
	FileNameLength: DWORD;
  Flags: DWORD;
begin
  if Length(drive) = 1 then drive := drive + ':\';
  //
	GetVolumeInformationA(
		PAnsiChar(drive),
    nil,
		0,
		@SerialNumber,
		FileNameLength,
		Flags,
		@SystemName[0],
		1000);
  //
  Result := string(PAnsiChar(@SystemName[0]));
end;


function getSerialNo(drive: AnsiString): DWORD;
var
	SerialNumber: DWORD;
	FileNameLength: DWORD;
  Flags: DWORD;
begin
  if Length(drive) = 1 then drive := drive + ':\';
  //
	GetVolumeInformationA(
		PAnsiChar(drive),
		nil,
		0,
		@SerialNumber,
		FileNameLength,
		Flags,
    nil,
		0);
  //
  Result := SerialNumber
end;

function getMainWindowHandle: THandle;
begin
  if MainWindowHandle = 0 then
  begin
    MainWindowHandle := GetForegroundWindow;
  end;

  Result := MainWindowHandle;
end;


// �t�@�C���^�C�������[�J����TTimeDate�ɕϊ�����
function FileTimeToDateTimeEx(const ft:TFileTime):TDateTime;
var lt:TFileTime; st:TSystemTime;
begin
  // 2�����́u����Ȋ֐��������B �v�X�����B27 �F�f�t�H���g�̖��������� �F02/10/15 19:24 ���
  FileTimeToLocalFileTime(ft,lt);
  FileTimeToSystemTime(lt,st);
  Result:=SystemTimeToDateTime(st);
end;

//TDateTime����t�@�C�������𓾂�
function DateTimeToFileTimeEx(dt: TDateTime):TFileTime;
var ft:TFileTime; st:TSystemTime;
begin
  DateTimeToSystemTime(dt, st);
  SystemTimeToFileTime(st, ft);
  LocalFileTimeToFileTime(ft, Result);
end;


//�t�@�C���̍쐬�E�X�V�E�ŏI���������𓾂�
function GetFileTimeEx(fname:string; var tCreation, tLastAccess, tLastWrite:TDateTime):boolean;
var
  F: TWin32FindDataA;
  h:THandle;
begin
  Result:=False;
  h := FindFirstFileA(PAnsiChar(fname),F);
  if h <> INVALID_HANDLE_VALUE then
  begin
    tCreation   :=  FileTimeToDateTimeEx( F. ftCreationTime   );
    tLastAccess :=  FileTimeToDateTimeEx( F. ftLastAccessTime );
    tLastWrite  :=  FileTimeToDateTimeEx( F. ftLastWriteTime  );
    Windows.FindClose(h);
    Result := True;
  end;
end;

// �ꊇ�Ńt�@�C��������ύX����
function SetFileTimeEx(fname:string; tCreation, tLastAccess, tLastWrite: TDateTime): Boolean;
var
  fCreation, fLastAccess, fLastWrite: TFileTime;
  hFile: THandle;
begin
  // �����̕ϊ�
  fCreation   := DateTimeToFileTimeEx(tCreation   );
  fLastAccess := DateTimeToFileTimeEx(tLastAccess );
  fLastWrite  := DateTimeToFileTimeEx(tLastWrite  );

  // �����̕ύX
	hFile := CreateFileA(PAnsiChar(fname), GENERIC_WRITE, 0, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL, 0);
  if hFile <> INVALID_HANDLE_VALUE then
  begin
	  SetFileTime(hFile, @fCreation, @fLastAccess, @fLastWrite);
	  CloseHandle(hFile);
    Result := True;
  end else
  begin
    Result := False;
  end;
end;


// ������Ƀt�@�C���̓��e��S���J��
function FileLoadAll(Filename: AnsiString): AnsiString;
var
  f: THandle;
  size, rsize: DWORD;
begin
  // open
  f := CreateFileA(PAnsiChar(Filename), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,0);
  if f = INVALID_HANDLE_VALUE then
    raise EInOutError.Create('�t�@�C��"' + Filename + '"���J���܂���B' + GetLastErrorStr);
  try
    // set pointer
    SetFilePointer(f, 0, nil, FILE_BEGIN); // ���߂���[���̈ʒu��

    // read
    size := GetFileSize(f, nil); // 4G �ȉ�����
    SetLength(Result, size);
    if not ReadFile(f, Result[1], size, rsize, nil) then
    begin // ���s
      raise EInOutError.Create('�t�@�C��"' + Filename + '"�̓ǂݎ��Ɏ��s���܂����B' + GetLastErrorStr);
    end;
  finally
    // close
    CloseHandle(f);
  end;
end;

// ������Ƀt�@�C���̓��e��S����������
procedure FileSaveAll(s, Filename: AnsiString);
var
  f: THandle;
  size, rsize: DWORD;
begin
  // open
  f := CreateFileA(PAnsiChar(Filename), GENERIC_WRITE, 0, nil,
    CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,0);
  if f = INVALID_HANDLE_VALUE then
    raise EInOutError.Create('�t�@�C��"' + Filename + '"���J���܂���B' + GetLastErrorStr);
  try
    // set pointer
    SetFilePointer(f, 0, nil, FILE_BEGIN); // ���߂���[���̈ʒu��

    // write
    size := Length(s);
    if size > 0 then
    begin
      if not WriteFile(f, s[1], size, rsize, nil) then
      begin // ���s
        raise EInOutError.Create('�t�@�C��"' + Filename + '"�̓ǂݎ��Ɏ��s���܂����B' + GetLastErrorStr);
      end;
    end;
  finally
    // close
    CloseHandle(f);
  end;
end;


function SHFileCopy(const Source, Dest, Title: AnsiString): Boolean;
var
  foStruct: TSHFileOpStructA;
  s_src, s_des: AnsiString;
begin
  Result := False;
  if (Source='')or(Dest='') then Exit;

  s_src := Source + #0#0;
  s_des := Dest   + #0#0;

  with foStruct do
  begin
    wnd    := getMainWindowHandle;
    wFunc  := FO_COPY;            //�t���O�i�R�s�[�̏ꍇ��FO_COPY�j
    pFrom  := PAnsiChar(s_src);
    pTo    := PAnsiChar(s_des);
    fFlags := FOF_MULTIDESTFILES or FOF_NOCONFIRMATION or FOF_NOCONFIRMMKDIR{orFOF_NOERRORUI};
    fAnyOperationsAborted := False;          // ���������f���ꂽ�ꍇ FALSE ���Ԃ�
    hNameMappings         := nil;            // �����O��̃t�@�C��
    lpszProgressTitle     := PAnsiChar(Title);   // �_�C�A���O�̃^�C�g��
  end;
  Result := (SHFileOperationA(foStruct) = 0);
end;

function SHFileDelete(const Source: AnsiString): Boolean;
var
  foStruct: TSHFileOpStructA;
begin
  ZeroMemory(@foStruct, sizeof(foStruct));
  with foStruct do
  begin
    wnd    := getMainWindowHandle;//Application.Handle;
    wFunc  := FO_DELETE;  //�t���O�i�R�s�[�̏ꍇ��FO_COPY�j
    pFrom  := PAnsiChar(Source + #0#0);  //����t�H���_
    fFlags := FOF_NOCONFIRMATION or FOF_ALLOWUNDO;  //�_�C�A���O��\��
  end;
  Result := (SHFileOperationA(foStruct)=0);
end;

function SHFileDeleteComplete(const Source: AnsiString): Boolean;
var
  foStruct: TSHFileOpStructA;
begin
  with foStruct do
  begin
    wnd    := getMainWindowHandle;//Application.Handle;
    wFunc  := FO_DELETE;  //�t���O�i�R�s�[�̏ꍇ��FO_COPY�j
    pFrom  := PAnsiChar(Source + #0#0);  //����t�H���_
    pTo    := Nil; // �K�v
    fFlags := FOF_NOCONFIRMATION or FOF_MULTIDESTFILES or FOF_NOERRORUI;  //�_�C�A���O��\��
    fAnyOperationsAborted := False;
    hNameMappings         := nil;
    lpszProgressTitle     := nil;
  end;
  Result := (SHFileOperationA(foStruct)=0);
end;

function SHFileMove(const Source, Dest: AnsiString): Boolean;
var
  foStruct: TSHFileOpStructA;
begin
  with foStruct do
  begin
    wnd       :=  getMainWindowHandle;//Application.Handle;
    wFunc     :=  FO_MOVE;  //�t���O�i�R�s�[�̏ꍇ��FO_COPY�j
    pFrom     :=  PAnsiChar(Source + #0#0);  //����t�H���_
    pTo       :=  PAnsiChar(Dest   + #0#0);
    fFlags    :=  FOF_NOCONFIRMATION or FOF_ALLOWUNDO or FOF_NOERRORUI;  //�_�C�A���O��\��
    fAnyOperationsAborted := False;
    hNameMappings         := nil;
    lpszProgressTitle     := nil;
  end;
  Result := (SHFileOperationA(foStruct)=0);
end;

function SHFileRename(const Source, Dest: AnsiString): Boolean;
begin
  Result := SHFileMove(Source, Dest);
end;

function EnumFiles(path: AnsiString): THStringList;
var
  rec: TSearchRec;
  basePath: AnsiString;
  s: AnsiString;

  procedure _enum(path: AnsiString);
  begin
    // �t�@�C���̌���
    if FindFirst(path, FaAnyFile, rec) = 0 then
    begin
      repeat
        if not ((rec.Attr and FaDirectory)>0) then
        begin
          Result.Add(rec.Name);
        end;
      until FindNext(rec) <> 0;
      FindClose(rec);
    end;
  end;

begin
  Result := THStringList.Create;

  // path ���t�H���_���H
  if DirectoryExists(path) then
  begin
    path := CheckPathYen(path);
  end;

  // ��{�p�X�̔����o��
  basePath := ExtractFilePath(path);
  if basePath <> '' then
  begin
    System.Delete(path, 1, Length(basePath));
  end;

  // �g���q��;�ŋ�؂��Ă���̂�;�܂ł�؂�o���Ă��ꂼ���
  while True do
  begin
    s := getToken_s(path, ';');

    // �p�X���L�q����ĂȂ���� basePath �𑫂�
    if Pos(':\', s) = 0 then s := basePath + s;

    // �t�H���_�݂̂̎w��Ȃ�� ���C���h�J�[�h�𑫂�
    if Copy(s, Length(s), 1) = '\' then s := s + '*';

    _enum(s);

    if path = '' then Break;
  end;

end;

function EnumAllFiles(path: AnsiString): THStringList; overload;
var
  temp: AnsiString;
begin
  Result := EnumAllFiles(path, temp);
end;

/// �S�t�@�C���񋓁A���� path �ɂ́A��{�ƂȂ�p�X��Ԃ�
function EnumAllFiles(path: AnsiString; out basePath: AnsiString): THStringList; overload;
var
  s: AnsiString;
  hmain: THandle;
  smain: AnsiString;

  procedure _enum(path: AnsiString);
  var
    base, ext, s, title: AnsiString;
    dirs: THStringList;
    files: THStringList;
    i: Integer;
  begin
    // ��{�p�X���擾
    base := ExtractFilePath(path); base := CheckPathYen(base);
    ext  := ExtractFileName(path);

    if hmain > 0 then
    begin
      title := '�p�X������:' + base;
      SetWindowText(hmain, PAnsiChar(title));
    end;

    // �t�@�C�����
    files := EnumFiles(path);
    for i := 0 to files.Count - 1 do
    begin
      Result.Add(base + files.Strings[i]); // �p�X��ǉ����Č��ʂɑ���
    end;
    files.Free;

    // �t�H���_���
    dirs := EnumDirs(base+'*');
    for i := 0 to dirs.Count - 1 do
    begin
      s := base + dirs.Strings[i] + '\' + ext;
      _enum(s); // �ċA�I�Ɍ���
    end;
    dirs.Free;
  end;

begin
  Result := THStringList.Create;

  // path ���t�H���_���H
  if DirectoryExists(path) then
  begin
    path := CheckPathYen(path);
  end;

  // ��{�p�X�̔����o��
  basePath := ExtractFilePath(path);
  if basePath = '' then
  begin
    // path �ɂ̓t�B���^�̂݋L�q����Ă���̂�
    // basePath�ɃJ�����g�t�H���_���w��
    basePath := GetCurrentDir;
    basePath := CheckPathYen(basePath);
  end else
  begin
    // ���������� path �����{�ƂȂ�p�X����������
    if basePath <> '' then System.Delete(path, 1, Length(basePath));
  end;

  hmain := MainWindowHandle;
  if hmain > 0 then
  begin
    SetLength(smain, 1024);
    GetWindowTextA(hmain, PAnsiChar(smain), 1023);
  end;

  // �g���q��;�ŋ�؂��Ă���̂�;�܂ł�؂�o���Ă��ꂼ���
  while True do
  begin
    s := getToken_s(path, ';');

    // �p�X���L�q����ĂȂ���� basePath �𑫂�
    if Pos(':\', s) = 0 then s := basePath + s;

    // �t�H���_�݂̂̎w��Ȃ�� ���C���h�J�[�h�𑫂�
    if Copy(s, Length(s), 1) = '\' then s := s + '*';

    _enum(s);

    if path = '' then Break;
  end;

  if hmain > 0 then
  begin
    SetWindowText(hmain, PAnsiChar(smain));
  end;

end;

function EnumAllDirs(path: AnsiString): THStringList;
var
  hmain: THandle;
  smain: AnsiString;

  procedure _enum(path: AnsiString);
  var
    title: AnsiString;
    dirs: THStringList;
    base, f, n: AnsiString;
    i: Integer;
  begin
    base := ExtractFilePath(path);
    f    := ExtractFileName(path);
    if hmain > 0 then
    begin
      title := '������:' + path;
      SetWindowText(hmain, PAnsiChar(title));
    end;

    // �t�H���_���
    dirs := EnumDirs(path);
    for i := 0 to dirs.Count - 1 do
    begin
      n := base + dirs.Strings[i] + '\';
      Result.Add(n);
      _enum(n + '*');
    end;
    dirs.Free;
  end;

begin
  Result := THStringList.Create;

  // path ���t�H���_���H
  if DirectoryExists(path) then
  begin
    path := CheckPathYen(path);
    Result.Add(path);
  end else
  begin
    Exit;
  end;

  hmain := MainWindowHandle;
  if hmain > 0 then
  begin
    SetLength(smain, 1024);
    GetWindowTextA(hmain, PAnsiChar(smain), 1023);
  end;

  _enum(path+'*');

  if hmain > 0 then
  begin
    SetWindowText(hmain, PAnsiChar(smain));
  end;

end;


function EnumDirs(const path: AnsiString): THStringList;
var
  rec: TSearchRec;
  s: AnsiString;
begin
  Result := THStringList.Create;
  //
  s := path;
  if DirectoryExists(s) then
  begin
    s := CheckPathYen(s) + '*';
  end;
  //
  if FindFirst(s, FaAnyFile, rec) = 0 then
  begin
    repeat
      if ((rec.Attr and FaDirectory) > 0) then
      begin
        if (rec.Name = '.') or (rec.Name = '..') then Continue;
        Result.Add(rec.Name);
      end;
    until FindNext(rec) <> 0;
    FindClose(rec);
  end;
end;

function CreateShortCut(SavePath, TargetApp, Arg, WorkDir: AnsiString; State: TWindowState2): Boolean;
var
  IU: IUnknown;
  W: PWideChar;
const
  ShowCmd: array[TWindowState2] of Integer =
    (SW_SHOWNORMAL, SW_MINIMIZE, SW_MAXIMIZE);
begin
  Result := False;
  try
    IU := CreateComObject(CLSID_ShellLink);
    with IU as IShellLinkA do begin
      if SetPath(PAnsiChar(TargetApp)) <> NOERROR then Abort;
      if SetArguments(PAnsiChar(Arg)) <> NOERROR then Abort;
      if SetWorkingDirectory(PAnsiChar(WorkDir)) <> NOERROR then Abort;
      if SetShowCmd(ShowCmd[State]) <> NOERROR then Abort
    end;
    W := PWChar(WideString(SavePath));
    if (IU as IPersistFile).Save(W, False) <> S_OK then Abort;
    Result := True
  except
  end
end;

function CreateShortCutEx(SavePath, TargetApp, Arg, WorkDir, IconPath: AnsiString;
    IconNo:Integer;Comment: AnsiString;Hotkey:Word; State: TWindowState2): Boolean;
var
  IU: IUnknown;
  W: PWideChar;
const
  ShowCmd: array[TWindowState2] of Integer =
    (SW_SHOWNORMAL, SW_MINIMIZE, SW_MAXIMIZE);
begin
  Result := False;
  try
    IU := CreateComObject(CLSID_ShellLink);
    with IU as IShellLinkA do begin
      if SetPath(PAnsiChar(TargetApp)) <> NOERROR then Abort;
      if SetArguments(PAnsiChar(Arg)) <> NOERROR then Abort;
      if SetWorkingDirectory(PAnsiChar(WorkDir)) <> NOERROR then Abort;
      if (IconPath <> '') and (SetIconLocation(PAnsiChar(IconPath),IconNo) <> NOERROR) then Abort;
      if (HotKey <> 0) and (SetHotkey(Hotkey) <> NOERROR) then Abort;
      if SetDescription(PAnsiChar(Comment)) <> NOERROR then Abort;
      if SetShowCmd(ShowCmd[State]) <> NOERROR then Abort
    end;
    W := PWChar(WideString(SavePath));
    if (IU as IPersistFile).Save(W, False) <> S_OK then Abort;
    Result := True
  except
  end
end;

function GetShortCutLink(Path : AnsiString): AnsiString;
var
  IU: IUnknown;
  IP: IPersistFile;
  buf: AnsiString;
  fd:_WIN32_FIND_DATAA;
begin
  Result := '';
  SetLength(buf,260);
  try
    IU := CreateComObject(CLSID_ShellLink);
    with IU as IShellLinkA do begin
      if QueryInterface(IPersistFile,IP) <> NOERROR then Abort;
      if IP.Load(PWChar(WideString(Path)),STGM_READWRITE) <> NOERROR then Abort;
      if GetPath(PAnsiChar(buf),260,fd,0) <> NOERROR then Abort;
    end;
    Result := PAnsiChar(buf);
  except
  end
end;

end.
