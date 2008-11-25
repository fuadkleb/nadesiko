unit kskFtp;
// ���@���FFTP,HTTP�֘A�N���X�̃��j�b�g
// ��@�ҁF�N�W����s��(http://kujirahand.com)
// ���J���F2001/10/21 ��{�쐬
//         2004/12/03 �X���b�h�ɑΉ�

// ���̃��C�u�����쐬�̂��߂ɁA
// http://user.ecc.u-tokyo.ac.jp/~t00664/delphi/
// ���Q�l�ɂ��܂����B���ӁB

interface

uses
  SysUtils, Classes, Wininet, Windows, messages, commctrl, mmsystem;

type

  TkskProgress = procedure (var readByte: Cardinal; var totalByte: Cardinal;
    var flagStop: Boolean) of Object;

  TkskFtpWriter = class(TThread)
  private
    hFTPSession : HINTERNET;
    FStream: TStream;
    FName: string;
    OnError: TNotifyEvent;
    OnProgress: TkskProgress;
    FMode: DWORD;
  protected
    procedure Execute; override;
  public
    status: string;
    constructor Create(AhFTPSession: HINTERNET; AName: string; AStream: TStream;
      AMode: DWORD ; AOnError, AOnComplate: TNotifyEvent; AOnProgress: TkskProgress);
  end;

  TkskFtpReader = class(TThread)
  private
    hFTPSession : HINTERNET;
    FStream: TStream;
    FRemoteFile: string;
    OnError: TNotifyEvent;
    OnProgress: TkskProgress;
    FMode: DWORD;
  protected
    procedure Execute; override;
  public
    status: string;
    constructor Create(AhFTPSession: HINTERNET; ARemoteFile: string;
      AStream: TStream; AMode: DWORD ;
      AOnError, AOnComplate: TNotifyEvent; AOnProgress: TkskProgress);
  end;

  TkskFTP = class
  private
    FCurrentDir : string;
    FPort : Integer;
    FHost : String;
    FUserID : String;
    FPassword : String;
    FConnected : boolean;
    hInternetSession : HINTERNET;
    hFTPSession : HINTERNET;
    FMode : Cardinal;
    // EVENT DIALOG
    hProgress: HWND;
    FCompleteFlag: Boolean;
    FCancel: Boolean;
    procedure OnProgress(var readByte: Cardinal; var totalByte: Cardinal;
      var flagStop: Boolean);
    procedure OnError(Sender: TObject);
    procedure OnComplate(Sender: TObject);
  public
    useDialog: Boolean;
    ErrorMsg: string;
    constructor Create;
    destructor Destroy; override;
    procedure Initialize;
    procedure Uninitialize;

    function Connect : boolean;
    function Disconnect : boolean;
    function Upload( ALocalFile, ARemoteFile : string ) : Boolean;
    function Download( ARemoteFile, ALocalFile : string ) : boolean;
    function CheckConfig : Integer;
    function CreateDir(DirName : string) : boolean;
    function ChangeDir(DirName : string) : boolean;
    function DeleteDir(DirName : string) : boolean;
    function DeleteFile(FileName : string) : boolean;
    function RanemeFile(OldName, NewName: string) : boolean;
    function Command(s: string; UseRes: Boolean; var res: string) : boolean;
    function Glob(path: string): string;        //�t�@�C����񋓂���Ƃ�
    function GlobDir(path: string): string;     //�t�H���_��񋓂���Ƃ�
    procedure ShowDialog(title, text, info: string); // �_�C�A���O

    property Connected : Boolean read FConnected;
    property CurrentDir : string read FCurrentDir;
    property Mode : Cardinal read FMode write FMode default FTP_TRANSFER_TYPE_BINARY;

  published
    property Port : Integer read FPort write FPort default INTERNET_DEFAULT_FTP_PORT;
    property UserID : string read FUserID write FUserID;
    property Host : string read FHost write FHost;
    property Password : string read FPassword write FPassword;
  end;

  //----------------------------------------------------------------------------
  TkskHttp = class
  public
    procProgress: TkskProgress;
    UserAgent: string;
    HTTP_VERSION: string;
    TimeOut: Integer;
    constructor Create;
    function Get(const URL, FileName: string): Boolean;
    function GetAsText(const URL: string): string;
    function GetAsMem(const URL: string; mem: TMemoryStream): Boolean;
    function GetHeader(const URL: string): string;
    function Post(const URL, Data, boundary, USER, PW: string; port: Integer): string;
  end;

  THTTPSyncFileDownloader = class(TThread)
  private
    FUserAgent, FURL, FHeaders: String;
    FOnError: TNotifyEvent;
    FOnProgress: TkskProgress;
    Stream: TStream;
    FHttpVersion: string;
  protected
    procedure Execute; override;
  public
    ErrorMsg: string;
    constructor Create(aUserAgent, aURL, aHeaders, aHttpVersion: String; aStream: TStream;
      AOnComplete, AOnError: TNotifyEvent; AOnProgress: TkskProgress);
  end;

  TkskHttpDialog = class
  private
    hProgress: HWND;
    FCompleteFlag: Boolean;
    FCancel: Boolean;
    downloader: THTTPSyncFileDownloader;
    procedure OnComplete(Sender: TObject);
    procedure OnError(Sender: TObject);
    procedure OnProgress(var readByte: Cardinal; var totalByte: Cardinal;
      var flagStop: Boolean);
  public
    Stream: TMemoryStream;
    id: string;
    password: string;
    UseBasicAuth: Boolean;
    UseDialog: Boolean;
    UserAgent: string;
    httpVersion: string;
    constructor Create;
    destructor Destroy; override;
    function DownloadDialog(const URL: string): Boolean;
  end;

var MainWindowHandle: THandle = 0;

function IsGlobalOffline: boolean;
function IsInternetConnected: boolean;
procedure splitURL(url:string; var protocol:string; var domain:string; var path:string; var port:Integer);
procedure SetTimeOut(hSession:HINTERNET; Seconds: Integer); //TimeOut�̐ݒ�

implementation

uses nako_dialog_const, unit_windows_api, unit_string,
  nako_dialog_function, jconvert;

// �Q�l)
// http://www.ichibachi.com/delphi/wininet.html
function IsGlobalOffline: boolean;
var
  State, Size: DWORD;
begin
  Result := False;
  State := 0;
  Size := SizeOf(DWORD);
  if InternetQueryOption(nil, INTERNET_OPTION_CONNECTED_STATE, @State, Size) then
    if (State and INTERNET_STATE_DISCONNECTED_BY_USER) <> 0 then
      Result := True;
end;

function IsInternetConnected: boolean;
var
  ConnectType : DWORD;
begin
  ConnectType := INTERNET_CONNECTION_MODEM + INTERNET_CONNECTION_LAN + INTERNET_CONNECTION_PROXY;
  Result := InternetGetConnectedState(@ConnectType, 0);
end;


function getMainWindowHandle: THandle;
begin
  if MainWindowHandle = 0 then
  begin
    MainWindowHandle := GetForegroundWindow;
  end;
  Result := MainWindowHandle;
end;

function GetHttpStatus(hRequest:HINTERNET): Integer;
var
  Len, r: DWORD;
begin
  Len := SizeOf(Result);
  r := 0;
  HttpQueryInfo(hRequest, HTTP_QUERY_STATUS_CODE or HTTP_QUERY_FLAG_NUMBER,
    @Result, Len, r);
end;

procedure SetTimeOut(hSession:HINTERNET; Seconds: Integer); //TimeOut�̐ݒ�
var
  TimeOut: integer;
begin
  TimeOut := Seconds * 1000; //�P�ʂ�ms -> �b�ɕϊ�
  InternetSetOption(
    hSession,
    INTERNET_OPTION_RECEIVE_TIMEOUT,
    @TimeOut,
    SizeOf(TimeOut));
end;

procedure splitURL(url:string; var protocol:string; var domain:string; var path:string; var port:Integer);
var
  sport: string;
begin
  protocol := getToken_s(url, '://');
  domain   := getToken_s(url, '/');
  path     := '/' + url;
  // Check Port
  port := INTERNET_DEFAULT_HTTP_PORT;
  if protocol = 'https' then
  begin
    port := INTERNET_DEFAULT_HTTPS_PORT;
  end;
  if Pos(':', domain) > 0 then
  begin
    sport  := domain;
    domain := getToken_s(sport, ':');
    port   := StrToIntDef(sport, port);
  end;
end;

type
  FtpCommand_IE5 = function (
    hConnect: HINTERNET;
    fExpectResponse: BOOL;
    dwFlags: DWORD;
    lpszCommand: PChar;
    dwContext: DWORD;
    phFtpCommand: PHINTERNET): BOOL; stdcall;

var kskFlagStop: Boolean = False;

function procProgress(
    hDlg: HWND;    // handle to dialog box
    uMsg: UINT;    // message
    wp  : WPARAM;  // first message parameter
    lp  : LPARAM   // second message parameter
   ): BOOL; stdcall;
var id: WORD;
begin
  Result := False;
  case uMsg of
    WM_COMMAND:
      begin
        id := LOWORD(wp);
        if id = IDCANCEL then
        begin
          kskFlagStop := True;
        end;
      end;
  end;
end;


constructor TkskFTP.Create;
begin
  useDialog     := False;
  FCompleteFlag := False;
  Mode          := FTP_TRANSFER_TYPE_BINARY;
  FCurrentDir   := '';
  Initialize;
end;

destructor TkskFTP.Destroy;
begin
  // �s�v: Disconnect;
  Uninitialize;
  inherited;
end;

procedure TkskFTP.Initialize;
begin
  hInternetSession := InternetOpen({PChar(Application.Exename)}'ftp.exe',
                              INTERNET_OPEN_TYPE_DIRECT,
                              nil, nil, 0 );
end;

procedure TkskFTP.Uninitialize;
begin
  InternetCloseHandle(hInternetSession);
end;


function TkskFTP.CheckConfig : Integer;
// �ݒ肪�Ȃ���Ă��邩�ǂ������ׂ܂��B
// hostname=$0001,port=$0002,username=$0004,password=$0008;
// ���ꂼ��t���O�������Ă�����ݒ肳��Ă��Ȃ��B
// ����= 0
begin
  result := 0;
  if( Host = '' ) then Result := Result or $0001;
  if( Port = 0 ) then Result := Result or $0002;
  if( UserID = '' ) then Result := Result or $0004;
  if( Password = '' ) then Result := Result or $0008;
end;


function TkskFTP.Connect : boolean;
// ftp�ڑ�������B����I����true��Ԃ��B
var   buf : array[0..MAX_PATH-1] of char;
      bufsize : DWORD;
begin
  // �ݒ肪�s���S���A���łɐڑ�����Ă����Exit
  if( (CheckConfig <> $0000) ) then begin Result := false; Exit end;
  if( Connected ) then begin Result := True; Exit end;
  // �����łȂ���ΐڑ������݂�B
  hFTPSession := InternetConnect(hInternetSession,
                                 PChar(Host),
                                 Port,
                                 PChar(UserID),
                                 PChar(Password),
                                 INTERNET_SERVICE_FTP,
                                 INTERNET_FLAG_PASSIVE,
                                 0
                                 );
  if(hFTPSession<>nil) then begin
    FConnected := true;
    Result := true;
    FtpGetCurrentDirectory(hFTPSession,buf,bufsize);
    FCurrentDir := buf;
  end
  else Result := false
end;


function TkskFTP.Disconnect : Boolean;
// �ؒf����B����I����true��Ԃ��B
begin
  if not connected then begin Result := false; Exit end;
  Result := InternetCloseHandle(hFTPSession);
  FConnected := false;
end;


function TkskFTP.Upload(ALocalFile, ARemoteFile : string) : boolean;
var
  uploader: TkskFtpWriter;
  stream: TMemoryStream;
begin
  if useDialog then
  begin
    // loacal
    stream := TMemoryStream.Create;
    try
      stream.LoadFromFile(ALocalFile);
      Result := False;
      FCompleteFlag := False;

      uploader := TkskFtpWriter.Create(hFTPSession, ARemotefile, stream, Mode,
        OnError, OnComplate, OnProgress);

      // �_�E�����[�h���I������܂Ń_�C�A���O��\��
      showDialog(
        'FTP�A�b�v���[�h�o�ߕ\��',
        'FTP�A�b�v���[�h������',
        ExtractFileName(ALocalFile) + '��' + ARemoteFile);

      Result := (FCancel = False);
      ErrorMsg := uploader.status;
      uploader.Free;

    finally
      stream.Free;
    end;
  end else
  begin
    // not useDialog
    if(not FtpPutFile(hFTPSession,
                    PChar(ALocalfile),
                    PChar(ARemotefile),
                    Mode or INTERNET_FLAG_RELOAD,
                    0 )
    ) then Result := false else Result := true;
  end;
end;

function TkskFTP.Download(ARemotefile,ALocalfile : string) : boolean;
var
  stream: TMemoryStream;
  downloader: TkskFtpReader;
begin

  if useDialog then
  begin
    // loacal
    stream := TMemoryStream.Create;
    try
      Result := False;
      FCompleteFlag := False;

      downloader := TkskFtpReader.Create(hFTPSession, ARemotefile, stream, Mode,
        OnError, OnComplate, OnProgress);

      // �_�E�����[�h���I������܂Ń_�C�A���O��\��
      showDialog(
        'FTP�_�E�����[�h�o�ߕ\��',
        'FTP�_�E�����[�h������',
        ARemoteFile + '��' + ExtractFileName(ALocalFile));

      Result := (FCancel = False);
      ErrorMsg := downloader.status;
      downloader.Free;
      if Result then stream.SaveToFile(ALocalfile);
    finally
      stream.Free;
    end;
  end else
  begin
    if( not FtpGetFile(hFTPSession,
          PChar(ARemotefile),
          PChar(ALocalfile),
          false, // �㏑���G���[���o�����ǂ���
          FILE_ATTRIBUTE_NORMAL,
          Mode,
          0 ) ) then Result:=false else Result:=true;
  end;
end;

function TkskFTP.ChangeDir(DirName : string) : boolean;
var buf : array[0..MAX_PATH] of char;
    bufsize : DWORD;
begin
  Result := FtpSetCurrentDirectory(hFTPSession,PChar(DirName));
  if Result then
  begin
    bufsize := MAX_PATH;
    FtpGetCurrentDirectory(hFTPSession,buf,bufsize);
    FCurrentDir := buf;
  end;
end;


{ TkskHttp }

function TkskHttp.Get(const URL, FileName: string): Boolean;
var
  mem: TMemoryStream;
begin
  mem := TMemoryStream.Create;
  try
    Result := GetAsMem(URL, mem);
    mem.SaveToFile(FileName);
  finally
    mem.Free;
  end;
end;

function TkskFTP.DeleteDir(DirName: string): boolean;
begin
    Result := FtpRemoveDirectory(hFTPSession, PChar(DirName));
end;

function TkskFTP.DeleteFile(FileName: string): boolean;
begin
    Result := FtpDeleteFile(hFTPSession, PChar(FileName));
end;

function TkskFTP.Glob(path: string): string;
var
    fd: TWin32FindData;
    //res: Cardinal ;
    hDir: HINTERNET;
begin
    Result := '';
    hDir := FtpFindFirstFile(
        hFTPSession,
        PChar(path),
        fd,
        INTERNET_FLAG_RELOAD,
        0);
    if GetLastError = ERROR_NO_MORE_FILES then Exit;
    if fd.dwFileAttributes <> FILE_ATTRIBUTE_DIRECTORY then Result := fd.cFileName ;
    while True do
    begin
        if not InternetFindNextFile(hDir, @fd) then
        begin
            //res := GetLastError ;
            //if res = ERROR_NO_MORE_FILES then Break;
            //raise ;
            Break;
        end else
        begin
            if fd.dwFileAttributes <> FILE_ATTRIBUTE_DIRECTORY then Result := Result + #13#10 + fd.cFileName ;
        end;
    end;
end;

function TkskFTP.GlobDir(path: string): string;
var
    fd: TWin32FindData;
    //res: Cardinal ;
    hDir: HINTERNET;
begin
    Result := '';
    hDir := FtpFindFirstFile(
        hFTPSession,
        PChar(path),
        fd,
        INTERNET_FLAG_RELOAD,
        0);
    if GetLastError = ERROR_NO_MORE_FILES then Exit;
    if fd.dwFileAttributes = FILE_ATTRIBUTE_DIRECTORY then Result := fd.cFileName ;

    while True do
    begin
        if not InternetFindNextFile(hDir, @fd) then
        begin
            //res := GetLastError ;
            //if res = ERROR_NO_MORE_FILES then Break;
            //raise ;
            Break;
        end else
        begin
            if fd.dwFileAttributes = FILE_ATTRIBUTE_DIRECTORY then Result := Result + #13#10 + fd.cFileName ;
        end;
    end;
end;

function TkskFTP.CreateDir(DirName: string): boolean;
var buf : array[0..MAX_PATH] of char;
    bufsize : DWORD;
begin
  Result := FtpCreateDirectory(hFTPSession, PChar(DirName));
  if Result then
  begin
    bufsize := MAX_PATH;
    FtpGetCurrentDirectory(hFTPSession,buf,bufsize);
    FCurrentDir := buf;
  end;
end;

function TkskHttp.GetAsText(const URL: string): string;
var
  mem: TMemoryStream;
begin
  Result := '';
  mem := TMemoryStream.Create;
  try
    if GetAsMem(URL, mem) = False then raise Exception.Create(URL+'�̎擾�Ɏ��s���܂����B');
    if mem.Size > 0 then
    begin
      SetLength(Result,    mem.Size);
      mem.Position := 0;
      mem.Read (Result[1], mem.Size);
    end;
  finally
    mem.Free;
  end;
end;

function TkskHttp.GetAsMem(const URL: string; mem: TMemoryStream): Boolean;
var
  hHttpSession, hReqUrl: HInternet;
  Buffer: array[0..1023]of Char;
  nRead, nCount, nTotal: Cardinal;
  d: DWORD;
  res: BOOL;
  flagStop: Boolean;
begin
  Result := False;

  // InternetOpen
  hHttpSession := InternetOpen('HTTP', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if hHttpSession = nil then Exit; // ERROR
  try
    // OpenURL
    hReqUrl := InternetOpenURL(hHttpSession, PChar(URL), nil, 0,0,0);
    if hReqUrl = nil then Exit;
    try
      // Query Head
      nRead := Length(Buffer);
      HttpQueryInfo(hReqUrl, HTTP_QUERY_CONTENT_LENGTH, @Buffer[0], nRead, d);
      nTotal := StrToIntDef(PChar(@Buffer[0]), 0); // ?w?b?_?(c)?c,???^(3)?????3/4
      nCount := 0;
      // get data
      repeat
        // progress
        if Assigned(procProgress) then
        begin
          procProgress(nCount, nTotal, flagStop);
          if flagStop then Exit;
        end;
        // read
        res := InternetReadFile(hReqUrl, @Buffer, sizeof(Buffer), nRead);
        if res then
        begin
          mem.Write(buffer, nRead); // ?o?b?t?@?O"?C,?A'
          Inc(nCount, nRead);
        end else
        begin
          Exit;
        end;
      until nRead = 0;
      Result := True;
    finally
      InternetCloseHandle(hReqUrl);
    end;
  finally
      InternetCloseHandle(hHttpSession);
  end;
end;

function TkskHttp.GetHeader(const URL: string): string;
var
  hHttpSession, hReqUrl: HInternet;
  Buffer: array[0..4095]of Char;
  nRead: Cardinal;
  d: DWORD;
begin
  Result := '';

  // InternetOpen
  hHttpSession := InternetOpen('HTTP', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if hHttpSession = nil then Exit; // ERROR
  try
    // OpenURL
    hReqUrl := InternetOpenURL(hHttpSession, PChar(URL), nil, 0,0,0);
    if hReqUrl = nil then raise Exception.Create('URL���J���܂���B');
    try
      // Query Head
      nRead := Length(Buffer); d := 0;
      HttpQueryInfo(hReqUrl, HTTP_QUERY_RAW_HEADERS_CRLF, @Buffer[0], nRead, d);
      Result := String( PChar( @Buffer[0] ) );
    finally
      InternetCloseHandle(hReqUrl);
    end;
  finally
      InternetCloseHandle(hHttpSession);
  end;
end;

function TkskHttp.Post(const URL, Data, boundary, USER, PW: string; port: Integer): string;
const
  BUFFSIZE = 500;

var
  hSession, hConnect, hReq: HINTERNET;
  server, path: string;
  buf: string;
  dwBytesRead: DWORD;
  pcBuffer: Array [0..BUFFSIZE-1] of Char;

  function UseHttpSendReqEx: Boolean;
  var
    BufferIn: INTERNET_BUFFERS;
    dwBytesWritten: DWORD;
    bRet: Boolean;
  begin
    ZeroMemory(@BufferIn, SizeOf(BufferIn));
    BufferIn.dwStructSize   := SizeOf(INTERNET_BUFFERS);
    BufferIn.dwBufferTotal  := Length(Data);

    if not HttpSendRequestEx(hReq, @BufferIn, nil, 0, 0) then
    begin
      raise Exception.Create('Error on HttpSendRequestEx ' + IntToStr(GetLastError));
    end;

    bRet := InternetWriteFile(hReq, @Data[1], Length(Data), dwBytesWritten);
    if not bRet then raise Exception.Create('Error on InternetWriteFile ' + IntToStr(GetLastError));

    HttpEndRequest(hReq, nil, 0, 0);
    Result := True;
  end;

begin
  Result := '';

  path := URL;
  getToken_s(path, '//');
  server := getToken_s(path, '/');
  //boundary := '--------------------__com.nadesiko.2005.01__' + IntToHex(timeGetTime,4);

  // InternetOpen
  hSession := InternetOpen('HttpSendRequestEx', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if hSession = nil then raise Exception.Create('WinInet�𗘗p�ł��܂���B');
  try
    // session
    if (USER='')and(PW='') then
    begin
      hConnect := InternetConnect(
        hSession, PChar(server), port, nil, nil, INTERNET_SERVICE_HTTP, 0, 0);
    end else
    begin
      hConnect := InternetConnect(
        hSession, PChar(server), port, PChar(USER), PChar(PW),
        INTERNET_SERVICE_HTTP, 0, 0);
    end;
    if hConnect = nil then raise Exception.Create(URL+'���J���܂���B' + GetLastErrorStr);
    try

      hReq := HttpOpenRequest(
        hConnect, 'POST', PChar(path), nil, nil, nil,
        INTERNET_FLAG_NO_CACHE_WRITE, 0);

      if UseHttpSendReqEx then
      begin
        repeat
          dwBytesRead := 0;
          if InternetReadFile(hReq, @pcBuffer[0], BUFFSIZE-1, dwBytesRead) then
          begin
            pcBuffer[dwBytesRead] := #0;
            SetLength(buf, dwBytesRead);
            Move(pcBuffer[0], buf[1], dwBytesRead);
            Result := Result + buf;
          end else
          begin
            Break;
          end;
        until (dwBytesRead > 0);
      end;
    finally
      InternetCloseHandle(hConnect);
    end;
  finally
    InternetCloseHandle(hSession);
  end;

end;

constructor TkskHttp.Create;
begin
  UserAgent := 'kskHttp';
  HTTP_VERSION := 'HTTP/1.1';
  TimeOut := 60;
end;

{ THTTPSyncFileDownloader }

constructor THTTPSyncFileDownloader.Create(aUserAgent, aURL, aHeaders,
  aHttpVersion: String; aStream: TStream; AOnComplete, AOnError: TNotifyEvent;
  AOnProgress: TkskProgress);
begin
  inherited Create(False);

  FreeOnTerminate := False;

  FUserAgent := aUserAgent;
  FURL       := aURL;
  FHeaders   := aHeaders;
  FHttpVersion := aHttpVersion;
  Stream     := aStream;
  ErrorMsg   := '';

  OnTerminate := AOnComplete;
  FOnError    := AOnError;
  FOnProgress := AOnProgress;
end;

procedure THTTPSyncFileDownloader.Execute;
var
  hSession: HINTERNET;
  hRequest: HINTERNET;
  hcon: HINTERNET;
  lpBuffer: array[0..65535] of Byte;
  dwBytesRead: DWORD;
  szHeader: string;
  dwTotal, dwRead, Reserved: DWORD;
  flagStop: Boolean;
  dwFlags: DWORD;
  dwBuffLen: DWORD;
  protocol, domain, path: string;
  b: BOOL;

  procedure closeHandleAll;
  begin
    if Assigned(hcon) then InternetCloseHandle(hcon);
    if Assigned(hRequest) then InternetCloseHandle(hRequest);
    if Assigned(hSession) then InternetCloseHandle(hSession);
  end;

  procedure err(msg: string);
  begin
    //
    closeHandleAll;
    ErrorMsg := msg;
    if Assigned(FOnError) then FOnError(Self);
  end;

  function _httpsDownload: Boolean;
  var code, port: Integer;
  begin
    Result := False;
    splitURL(FUrl, protocol, domain, path, port);
    // connect
    hcon := InternetConnect(hSession, PChar(domain),
      port,
      '',// username
      '',// password
      INTERNET_SERVICE_HTTP, 0, 0);
    if not Assigned(hcon) then begin err('�ڑ��G���['); Exit; end;
    // request
    hRequest := HttpOpenRequest(
      hcon,
      'GET',
      PChar(path),
      PChar(FHttpVersion),
      nil,
      nil,
      INTERNET_FLAG_SECURE,
      0);
    if not Assigned(hRequest) then
    begin
      err('���N�G�X�g���̃G���['); Exit;
    end;
    // request option
    dwFlags := 0;
    dwBuffLen := sizeof(dwFlags);
    InternetQueryOption(hRequest, INTERNET_OPTION_SECURITY_FLAGS,
      @dwFlags, dwBuffLen);
    dwFlags := dwFlags or SECURITY_FLAG_IGNORE_UNKNOWN_CA;
    dwFlags := dwFlags or SECURITY_FLAG_IGNORE_CERT_CN_INVALID;
    dwFlags := dwFlags or SECURITY_FLAG_IGNORE_CERT_DATE_INVALID;
    dwFlags := dwFlags or SECURITY_FLAG_IGNORE_REDIRECT_TO_HTTP;
    dwFlags := dwFlags or SECURITY_FLAG_IGNORE_REDIRECT_TO_HTTPS;
    if not InternetSetOption (hRequest, INTERNET_OPTION_SECURITY_FLAGS,
      @dwFlags, sizeof(dwFlags)) then
    begin
      err('�F�؂Ɋւ���G���['); Exit;
    end;

    if FHeaders <> '' then
    begin
      b := HttpAddRequestHeaders(hRequest, PChar(FHeaders), Length(FHeaders),
        HTTP_ADDREQ_FLAG_REPLACE or HTTP_ADDREQ_FLAG_ADD);
      if not b then begin err('�w�b�_�̐ݒ�Ɏ��s���܂����B'); exit; end;
    end;

    if not HttpSendRequest(hRequest, nil, 0, nil, 0) then
    begin
      err('���N�G�X�g���M���̃G���['); Exit;
    end;

    code := GetHttpStatus(hRequest);
    if code <> HTTP_STATUS_OK then
    begin
      err('�X�e�[�^�X�R�[�h�ُ̈�:' + IntToStr(code)); Exit;
    end;

    Result := True;
  end;

begin
  inherited;

  flagStop := False;
  hSession := InternetOpen(PChar(FUserAgent), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if not Assigned(hSession) then
  begin
    err('�Z�b�V�������J���܂���B'); Exit;
  end;

  // InternetOpenUrl
  szheader := FHeaders;
  SetLength(szHeader, Length(szHeader));
  hRequest := InternetOpenUrl(hSession, PChar(FUrl),
                PChar(szheader), Length(szheader),
                INTERNET_FLAG_RELOAD, 0);

  // CA(�F��)�G���[�̏ꍇ�A�����I�v�V�������Z�b�g����
  if not Assigned(hRequest) then
  begin
    if (GetLastError = ERROR_INTERNET_INVALID_CA) or
       (GetLastError = ERROR_INTERNET_CLIENT_AUTH_CERT_NEEDED) then
    begin
      if not _httpsDownload then Exit;
    end;
  end;
  if not Assigned(hRequest) then
  begin
    err('���N�G�X�g���̃G���['); Exit;
  end;

  // �w�b�_�̎擾
  dwBytesRead := Length(lpBuffer);
  ZeroMemory(@lpBuffer, dwBytesRead);
  HttpQueryInfo(hRequest, HTTP_QUERY_CONTENT_LENGTH,
      @lpBuffer, dwBytesRead, Reserved);
  dwTotal := StrToIntDef(string( @lpBuffer ), 0);
  dwRead  := 0;

  dwBytesRead := Length(lpBuffer);
  while dwBytesRead <> 0 do
  begin

    if Terminated or kskFlagStop then
    begin
      err('���[�U�[�ɂ�钆�f');
      Break;
    end;

    if Assigned(FOnProgress) then
    begin
      FOnProgress(dwRead, dwTotal, flagStop);
      if flagStop then
      begin
        err('���[�U�[�ɂ�钆�f');
        Break;
        Break;
      end;
    end;

    if InternetReadFile(hRequest, @lpBuffer, Length(lpBuffer), dwBytesRead) then
    begin
      stream.WriteBuffer(lpBuffer, dwBytesRead);
      Inc(dwRead, dwBytesRead);
    end else
    begin
      err('�f�[�^���ǂݎ��܂���B');
      Break;
    end;

    Sleep(10);
  end;

  if Assigned(OnTerminate) then
  begin
    OnTerminate(Self);
    Exit;
  end;
  closeHandleAll;
end;


{ TkskHttpDialog }

constructor TkskHttpDialog.Create;
begin
  UserAgent := '';
  downloader := nil;
  FCancel := False;
  Stream := TMemoryStream.Create;
  UseDialog := True;
end;

destructor TkskHttpDialog.Destroy;
begin
  Stream.Free;
  inherited;
end;

function TkskHttpDialog.DownloadDialog(const URL: string): Boolean;
var
  hParent: HWND;
  msg: TMsg;
  head: string;
begin
  //Result := False;
  hParent := getMainWindowHandle;

  FCompleteFlag := False;
  FCancel := False;
  kskFlagStop := False;

  if UseDialog then
  begin
    // �_�C�A���O�̕\��
    hProgress  := CreateDialog(
        hInstance, PChar(IDD_DIALOG_PROGRESS), hParent, @procProgress);

    // �_�C�A���O�ɏ���\��
    SetDlgWinText(hProgress, IDC_EDIT_TEXT, '�_�E�����[�h������');
    SetDlgWinText(hProgress, IDC_EDIT_INFO, URL);
    ShowWindow(hProgress, SW_SHOW);
  end;

  // �_�E�����[�h�p�̃X���b�h�̍쐬
  if UseBasicAuth then
  begin
    head := 'Authorization: Basic ' + EncodeBase64(id + ':' + password) + #0;
  end;
  downloader := THTTPSyncFileDownloader.Create(UserAgent, url, head, httpVersion,
    Stream, OnComplete, OnError, OnProgress);
  try
    // �_�E�����[�h���I������܂Ń_�C�A���O��\��
    if UseDialog then
    begin
      while FCompleteFlag = False do
      begin
        if PeekMessage(msg, hProgress, 0, 0, PM_REMOVE) then
        begin
          if not IsDialogMessage(hProgress, msg) then
          begin
            TranslateMessage(msg);
            DispatchMessage (msg);
          end;
        end else
        begin
          // �A�C�h��
          sleep(1);
        end;
      end;

      DestroyWindow(hProgress);
      hProgress := 0;
    end else
    begin
      while FCompleteFlag = False do
      begin
        sleep(200);
      end;
    end;

    if FCancel then
    begin
      Stream.Clear;
      raise Exception.Create('�_�E�����[�h�Ɏ��s���܂����B' + downloader.ErrorMsg);
    end;
  finally
    downloader.Free;
  end;
  Result := True;
end;

procedure TkskHttpDialog.OnComplete(Sender: TObject);
begin
  FCompleteFlag := True;
end;

procedure TkskHttpDialog.OnError(Sender: TObject);
begin
  FCompleteFlag := True;
  FCancel := True;
end;

procedure TkskHttpDialog.OnProgress(var readByte, totalByte: Cardinal;
  var flagStop: Boolean);
var
  s: string;
begin
  // download text
  s := '�_�E�����[�h�� (' + IntToStr(Trunc(readByte/1024)) + '/' + IntToStr(Trunc(totalByte/1024)) + 'KB)';
  SetDlgWinText(hProgress, IDC_EDIT_TEXT, s);

  // progress bar
  SendMessage(GetDlgItem(hProgress, IDC_PROGRESS1),
    PBM_SETSTEP, 1, 0);
  // range
  SendMessage(GetDlgItem(hProgress, IDC_PROGRESS1),
    PBM_SETRANGE, 0, MakeLong(0, 100));

  // pos
  if totalByte > 0 then
  begin
    SendMessage(GetDlgItem(hProgress, IDC_PROGRESS1),
      PBM_SETPOS, Trunc(readByte/totalByte*100) , LParam(BOOL(True)));
  end;
end;

{ TkskFtpWriter }

constructor TkskFtpWriter.Create(AhFTPSession: HINTERNET; AName: string;
  AStream: TStream; AMode: DWORD;
  AOnError, AOnComplate: TNotifyEvent; AOnProgress: TkskProgress);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  hFTPSession := AhFTPSession;
  FStream     := AStream;
  FMode       := AMode;
  FName       := AName;
  OnError     := AOnError;
  OnTerminate := AOnComplate;
  OnProgress  := AOnProgress;
end;

procedure TkskFtpWriter.Execute;
var
  hFile : HINTERNET;
  buf   : Array [0..4096] of Char;
  len, total, writeByte : DWORD;
  flagStop : Boolean;
begin
  inherited;

  hFile := FtpOpenFile(
    hFTPSession,
    PChar(FName),
    GENERIC_WRITE, FMode, 0);

  if hFile = nil then
  begin
    status := '�t�@�C�����J���܂���';
    OnError(Self); Exit;
  end;

  FStream.Position := 0; // top
  total     := FStream.Size;
  writeByte := 0;
  try
    // ��������
    while not Terminated do
    begin
      // event
      if Assigned(OnProgress) then
      begin
        OnProgress(writeByte, total, flagStop);
        if flagStop or kskFlagStop then
        begin
          status := '���[�U�[�ɂ�钆�f';
          OnError(Self); Exit;
        end;
      end;
      // read buf
      len := FStream.Read(buf[0], Length(buf));
      if len = 0 then Break; // �Ō�܂ŏ�������ł��܂����甲����

      // write buf
      if InternetWriteFile(hFile, @buf, len, len) then
      begin
        Inc(writeByte, len);
      end else
      begin
        status := '�������߂܂���B';
        if Assigned(OnError) then OnError(Self);
      end;
    end;
    if Assigned(OnTerminate) then
    begin
      OnTerminate(Self);
      Exit;
    end;
  finally
    InternetCloseHandle(hFile);
  end;
end;

procedure TkskFTP.OnComplate(Sender: TObject);
begin
  FCompleteFlag := True;
end;

procedure TkskFTP.OnError(Sender: TObject);
begin
  FCancel := True;
  FCompleteFlag := True;
end;

procedure TkskFTP.OnProgress(var readByte, totalByte: Cardinal;
  var flagStop: Boolean);
var
  s: string;
begin
  // download text
  s := '�]���� (' + IntToStr(Trunc(readByte/1024)) + '/' + IntToStr(Trunc(totalByte/1024)) + ')';
  SetDlgWinText(hProgress, IDC_EDIT_TEXT, s);

  // progress bar
  SendMessage(GetDlgItem(hProgress, IDC_PROGRESS1),
    PBM_SETSTEP, 1, 0);
  // range
  SendMessage(GetDlgItem(hProgress, IDC_PROGRESS1),
    PBM_SETRANGE, 0, MakeLong(0, 100));

  // pos
  if totalByte > 0 then
  begin
    SendMessage(GetDlgItem(hProgress, IDC_PROGRESS1),
      PBM_SETPOS, Trunc(readByte/totalByte*100) , LParam(BOOL(True)));
  end;
end;

procedure TkskFTP.ShowDialog(title, text, info: string);
var
  hParent: HWND;
  msg: TMsg;
begin
  hParent   := getMainWindowHandle;
  hProgress := CreateDialog(hInstance, PChar(IDD_DIALOG_PROGRESS),
                hParent, @procProgress);

  SetDlgWinText(hProgress, IDC_EDIT_TEXT, text);
  SetDlgWinText(hProgress, IDC_EDIT_INFO, info);
  SetWindowText(hProgress, PChar(title));

  ShowWindow(hProgress, SW_SHOW);

  while FCompleteFlag = False do
  begin
    if PeekMessage(msg, hProgress, 0, 0, PM_REMOVE) then
    begin
      if not IsDialogMessage(hProgress, msg) then
      begin
        TranslateMessage(msg);
        DispatchMessage (msg);
      end;
    end else
    begin
      // �A�C�h��
      sleep(1);
    end;
  end;

  DestroyWindow(hProgress);
  hProgress := 0;
end;

{ TkskFtpReader }

constructor TkskFtpReader.Create(AhFTPSession: HINTERNET;
  ARemoteFile: string; AStream: TStream; AMode: DWORD; AOnError,
  AOnComplate: TNotifyEvent; AOnProgress: TkskProgress);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  hFTPSession := AhFTPSession;
  FStream     := AStream;
  FMode       := AMode;
  FRemoteFile := ARemoteFile;
  OnError     := AOnError;
  OnTerminate := AOnComplate;
  OnProgress  := AOnProgress;
end;

procedure TkskFtpReader.Execute;
var
  hFile : HINTERNET;
  buf   : Array [0..4096] of Char;
  len, total, readByte : DWORD;
  flagStop : Boolean;
  // fd: WIN32_FIND_DATA;
begin
  inherited;
{ // FtpGetFileSize �ŉ���
  // �t�@�C���̃g�[�^���T�C�Y�����߂�
  hFile := FtpFindFirstFile(
    hFTPSession, PChar(FRemoteFile),
    fd, 0, 0);
  if hFile = nil then
  begin
    status := '�t�@�C�����J���܂���';
    OnError(Self); Exit;
  end;
  total := fd.nFileSizeLow;
  InternetCloseHandle(hFile);
}

  // �ǂݎ��t�@�C�����J��
  hFile := FtpOpenFile(
    hFTPSession,
    PChar(FRemoteFile),
    GENERIC_READ, FMode or INTERNET_FLAG_RELOAD, 0);

  if hFile = nil then
  begin
    status := '�t�@�C�����J���܂���';
    OnError(Self); Exit;
  end;

  FtpGetFileSize(hFile, @total);

  FStream.Position := 0; // top
  readByte := 0;
  try
    // ��������
    while not Terminated do
    begin
      // event
      if Assigned(OnProgress) then
      begin
        OnProgress(readByte, total, flagStop);
        if flagStop or kskFlagStop then
        begin
          status := '���[�U�[�ɂ�钆�f';
          OnError(Self); Exit;
        end;
      end;

      // read file
      if InternetReadFile(hFile, @buf, Length(buf), len) then
      begin
        FStream.Write(buf, len);
        Inc(readByte, len);
      end else
      begin
        status := '�ǂݎ��܂���B';
        if Assigned(OnError) then OnError(Self);
      end;

      if DWORD(Length(buf)) > len then Break;
    end;
    if Assigned(OnTerminate) then
    begin
      OnTerminate(Self);
      Exit;
    end;
  finally
    InternetCloseHandle(hFile);
  end;
end;

function TkskFTP.RanemeFile(OldName, NewName: string): boolean;
begin
  Result := FtpRenameFile(hFTPSession, PChar(OldName), PChar(NewName));
end;

function TkskFTP.Command(s: string; UseRes: Boolean; var res: string): boolean;
var
  hRes: HINTERNET;
  hLib: THandle;
  proc: FtpCommand_IE5;
  buf : Array [0..4096] of Char;
  len : DWORD;
  stream: TMemoryStream;
begin
  hLib := LoadLibrary('wininet.dll'); // IE5�ȍ~
  proc := GetProcAddress(hLib, 'FtpCommandA');
  if not Assigned(proc) then raise Exception.Create('���̖��߂�IE5�ȍ~�ŃT�|�[�g����܂��B');

  res := ''; hRes := nil;

  Result := proc( hFTPSession, UseRes,
    FTP_TRANSFER_TYPE_ASCII, PChar(s), 0, @hRes);
  if not Result then Exit;
  if UseRes = False then Exit;

  // res �̎擾
  stream := TMemoryStream.Create;
  try
    while hRes <> nil do
    begin
      if not InternetReadFile(hRes, @buf, Length(buf), len) then
      begin
        Exit;
        //raise Exception.Create('FtpCommand�̖߂�l�������܂���B');
      end;
      if len <= 0 then Break;
      stream.Write(buf[0], len);
    end;
    stream.Position := 0;
    SetLength(res, stream.Size);
    stream.Read(res[1], Length(res));
  finally
    stream.Free;
  end;

end;

end.
