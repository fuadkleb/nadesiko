unit unit_windows_api;

interface

uses
  Windows, SysUtils, messages;

// �G���[���b�Z�[�W���擾����
function GetLastErrorStr: AnsiString;
function GetLastErrorMessage(ErrorCode: Integer): AnsiString;

function ClipbrdGetAsText: AnsiString;
function ClipbrdSetAsText(s: AnsiString): AnsiString;
procedure ClipbrdSetAsBuffer(Format: Word; var Buffer; Size: Integer);

procedure SendCOPYDATA(hwnd: THandle; str: AnsiString; msgid: DWORD; SelfHandle: THandle);

function getWinVersion: AnsiString;
function getWinVersionN: AnsiString;

implementation

function getWinVersionN: AnsiString;
var
  i: TOSVersionInfo;
begin
  i.dwOSVersionInfoSize := SizeOf(i);
  GetVersionEx(i);
  Result := Format('%d.%d(%d:%d)',[
    i.dwMajorVersion,
    i.dwMinorVersion,
    i.dwBuildNumber,
    i.dwPlatformId]);
end;


function getWinVersion: AnsiString;
var
  //s: AnsiString;
  major,minor: LongInt;
  Info: TOSVersionInfo;
begin
  Info.dwOSVersionInfoSize := SizeOf(Info);
  GetVersionEx(Info);
  Major := Info.dwMajorVersion ;
  Minor := Info.dwMinorVersion ;
  case major of
      4://95/98/ME/NT
          begin
              if Info.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS then
              begin
                  case Minor of
                      0 :Result := 'Windows 95';
                      10:Result := 'Windows 98';
                      90:Result := 'Windows Me';
                  end;
              end else
              if Info.dwPlatformId = VER_PLATFORM_WIN32_NT then
              begin
                  Result := 'Windows NT 4.0';
              end;
          end;
      3://NT 3.51
          begin
              Result := 'Windows NT 3.51';
          end;
      5://2000/XP/.NET Server
          begin
              case Minor of
                  0: Result := 'Windows 2000';
                  1: Result := 'Windows XP';
                  2: Result := 'Windows Server 2003';
              end;
          end;
      6://Vista
          begin
            Result := 'Windows Vista';
          end;
      else begin
          Result := AnsiString('�s�� Version = '+ IntToStr(GetVersion));
      end;
  end;
  {��肭�����Ȃ�
  s := string(PAnsiChar(@Info.szCSDVersion[1]));
  if s<>'' then
  begin
      Result := Result + s;
  end;}
end;


{WM_COPYDATA���ȒP�ɑ��M����}
procedure SendCOPYDATA(hwnd: THandle; str: AnsiString; msgid: DWORD; SelfHandle: THandle);
var
  cd  : TCopyDataStruct;
  len : integer;
  Msg : PAnsiChar;
begin
  if hwnd <> 0 then
  begin
    //���郁�b�Z�[�W
    len :=  Length(str) + 1;
    cd.dwData :=  msgid;
    cd.cbData :=  len;
    GetMem(Msg, len);
    try
      StrPCopy(Msg, str);
      cd.lpData := Msg;
      //���M��E�B���h�E���A�N�e�B�u�ɂ���
      // SetForegroundWindow(hwnd);
      //���M
      SendMessage(hwnd, WM_COPYDATA, SelfHandle, LParam(@cd));
    finally
      FreeMem(Msg, len);
    end;
  end;
end;

procedure ClipbrdOpen;
begin
  if not OpenClipboard(0) then raise Exception.Create('�N���b�v�{�[�h���J���܂���B');
end;

procedure ClipbrdClose;
begin
  CloseClipboard;
end;

function ClipbrdGetAsText: AnsiString;
var
  Data: THandle;
begin
  ClipbrdOpen;
  Data := GetClipboardData(CF_TEXT);
  try
    if Data <> 0 then
      Result := PAnsiChar(GlobalLock(Data))
    else
      Result := '';
  finally
    if Data <> 0 then GlobalUnlock(Data);
    ClipbrdClose;
  end;
end;

function ClipbrdSetAsText(s: AnsiString): AnsiString;
begin
  s := s + #0;
  ClipbrdSetAsBuffer(CF_TEXT, s[1], Length(s));
end;

procedure ClipbrdSetAsBuffer(Format: Word; var Buffer; Size: Integer);
var
  Data: THandle;
  DataPtr: Pointer;
begin
  ClipbrdOpen;    // �N���b�v�{�[�h���J��
  EmptyClipboard; // �N���b�v�{�[�h�ɕύX�̏��L����^����
  try
    Data := GlobalAlloc(GMEM_MOVEABLE+GMEM_DDESHARE, Size);
    try
      DataPtr := GlobalLock(Data);
      try
        Move(Buffer, DataPtr^, Size);
        //Adding;
        if SetClipboardData(Format, Data) = 0 then raise Exception.Create('�R�s�[���s');
      finally
        GlobalUnlock(Data);
      end;
    except
      GlobalFree(Data);
      raise;
    end;
  finally
    ClipbrdClose;
  end;
end;


function GetLastErrorMessage(ErrorCode: Integer): AnsiString;
const
  MAX_MES = 512;
var
  Buf: PAnsiChar;
begin
  Buf := AllocMem(MAX_MES);
  try
    FormatMessageA(Format_Message_From_System, Nil, ErrorCode,
                  (SubLang_Default shl 10) + Lang_Neutral,
                  Buf, MAX_MES, Nil);
  finally
    Result := Buf;
    FreeMem(Buf);
  end;
end;

function GetLastErrorStr: AnsiString;
begin
  Result := GetLastErrorMessage(GetLastError);
end;

end.
