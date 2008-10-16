unit dll_net_function;

interface

uses
  Windows, SysUtils, Classes, UrlMon, WinInet, kskFtp,
  dll_plugin_helper, dnako_import, dnako_import_types,
  winsock,unit_eml,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdFTPCommon,
  IdFTP, IdFTPList, IdHttp, IdTcpServer, IdSNTP;

const
  NAKONET_DLL_VERSION = '1.509';

type
  TNetDialog = class(TComponent)
  private
    hParent: HWND;
    hProgress: HWND;
    WorkCount: Integer;
  public
    target: string;
    errormessage: string;
    procedure WorkBegin(Sender: TObject; AWorkMode: TWorkMode; const AWorkCountMax: Integer);
    procedure WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
    procedure Work(Sender: TObject; AWorkMode: TWorkMode; const AWorkCount: Integer);
    function ShowDialog(stext, sinfo: string; Visible: Boolean): Boolean;
    procedure setInfo(s: string);
    procedure setText(s: string);
  end;

  TNetThread = class(TThread)
  protected
    procedure Execute; override;
  public
    method: procedure (Sender: TNetThread; ptr: Pointer);
    arg0: Pointer;
    arg1: Pointer;
    arg2: Pointer;
    arg3: Pointer;
    arg4: Pointer;
  end;

function NetDialog:TNetDialog;
function get_on_off(str: string): Boolean;

procedure RegistFunction;

implementation

uses mini_file_utils, unit_file, KPop3, KSmtp, KTcp, KTCPW, unit_string2,
  WSockUtils, Icmp, KHttp, jconvert, md5, nako_dialog_function,
  nadesiko_version, messages, nako_dialog_const, CommCtrl, unit_kabin,
  hima_types, unit_content_type;

var pProgDialog: PHiValue = nil;
var FNetDialog: TNetDialog = nil;
var net_dialog_cancel:   Boolean = False;
var net_dialog_complete: Boolean = False;

const NAKO_HTTP_OPTION = 'HTTP�I�v�V����';

function NetDialog:TNetDialog;
begin
  if FNetDialog = nil then
  begin
    FNetDialog := TNetDialog.Create(nil);
  end;
  Result := FNetDialog;
end;

function nako_http_opt_get(name:string): string;
var
  p: PHiValue;
  s: TStringList;
begin
  p := nako_getVariable(NAKO_HTTP_OPTION);
  s := TStringList.Create;
  s.Text := hi_str(p);
  Result := Trim(s.Values[name]);
  s.Free;
end;

function http_opt_useBasicAuth: Boolean;
var
  s: string;
begin
  s := nako_http_opt_get('BASIC�F��');
  if (s = '�I�t') or (s = '0') or (s = '�O') or (s = '������') or (s = '')then
  begin
    Result := False;
  end else
  begin
    Result := True;
  end;
end;

function http_opt_getId: string;
begin
  Result := nako_http_opt_get('ID');
end;

function http_opt_getPassword: string;
begin
  Result := nako_http_opt_get('�p�X���[�h');
  if Result = '' then
  begin
    Result := nako_http_opt_get('PASSWORD');
  end;
end;

function http_opt_getUA: string;
begin
  Result := nako_http_opt_get('UA');
  if Result = '' then
  begin
    Result := 'nadesiko';
  end;
end;


function sys_http_download(args: DWORD): PHiValue; stdcall;
var
  a, b: PHiValue;
  url, local: string;
  h: TkskHttpDialog;

begin
  a := nako_getFuncArg(args, 0);
  b := nako_getFuncArg(args, 1);

  url   := hi_str(a);
  local := hi_str(b);

  // �X���b�h���g���ăA�N�Z�X
  h := TkskHttpDialog.Create;
  try
    kskFtp.MainWindowHandle := nako_getMainWindowHandle;
    h.UseBasicAuth  := http_opt_useBasicAuth;
    h.id            := http_opt_getId;
    h.password      := http_opt_getPassword;
    h.UserAgent     := http_opt_getUA;
    h.UseDialog     := hi_bool(pProgDialog);
    h.DownloadDialog(url);
    h.Stream.SaveToFile(local);
  finally
    h.Free;
  end;

  Result := nil;
end;

function sys_http_downloaddata(args: DWORD): PHiValue; stdcall;
var
  a: PHiValue;
  url, local, s: string;
  h: TkskHttpDialog;

  procedure subDownload;
  begin
    // ���炩�̗��R�ŕW�����߂��g���Ȃ������Ƃ��Ɏg���T�u���\�b�h
    local := TempDir + 'temp';
    if URLDownloadToFile(nil, PChar(url), PChar(local), 0, nil) <> s_ok then
    begin
      raise Exception.Create(url+'���_�E�����[�h�ł��܂���ł����B');
    end;
    s := FileLoadAll(local);
    if FileExists(local) then DeleteFile(local);
  end;

  procedure _download;
  var
    h: TkskHttpDialog;
  begin
    // �X���b�h���g���ăA�N�Z�X
    h := TkskHttpDialog.Create;
    try
      kskFtp.MainWindowHandle := nako_getMainWindowHandle;
      h.UseBasicAuth := http_opt_useBasicAuth;
      h.id       := http_opt_getId;
      h.password := http_opt_getPassword;
      h.UserAgent     := http_opt_getUA;
      h.UseDialog     := hi_bool(pProgDialog);
      if h.DownloadDialog(url) then
      begin
        SetLength(s, h.Stream.Size);
        h.Stream.Position := 0;
        h.Stream.Read(s[1], h.Stream.Size);
      end else
      begin
        s := '';
      end;
    finally
      h.Free;
    end;
  end;

begin
  a := nako_getFuncArg(args, 0);

  url   := hi_str(a);

  try
    _download;
  except
    subDownload;
  end;
  Result := hi_newStr(s);
  
end;

function sys_http_downloadhead(args: DWORD): PHiValue; stdcall;
var
  a: PHiValue;
  url, s: string;
  http: TkskHttp; // WinInet �g�p
begin
  a := nako_getFuncArg(args, 0);
  url   := hi_str(a);

  http := TkskHttp.Create;
  try
    s := http.GetHeader(url);
  except on E: Exception do
    // ���炩�̗��R�ŕW�����߂��g���Ȃ������Ƃ�
    raise Exception.Create('�w�b�_���擾�ł��܂���ł����B' + e.Message);
  end;
  http.Free;

  Result := hi_newStr(s);
end;

function sys_http_downloadhead2(args: DWORD): PHiValue; stdcall;
var
  a: PHiValue;
  url, s: string;
  http: TKHttpClient; // �Ǝ��d�l
begin
  a := nako_getFuncArg(args, 0);
  url   := hi_str(a);

  http :=TKHttpClient.Create(nil);
  try
    try
      http.GetProxySettingFromRegistry; // ���W�X�g������Proxy��ǂ�
      s := http.Head(url);
    except
      on E: Exception do
        // ���炩�̗��R�ŕW�����߂��g���Ȃ������Ƃ�
        raise Exception.Create('�w�b�_���擾�ł��܂���ł����B' + e.Message);
    end;
  finally
    http.Free;
  end;

  Result := hi_newStr(s);
end;

var _kskFtp: TkskFtp = nil;
var _idftp: Tidftp = nil;

function get_on_off(str: string): Boolean;
begin
  str := JReplace_(str, '�I��','1');
  str := JReplace_(str, '�I�t','0');
  str := JReplace_(str, '�͂�','1');
  str := JReplace_(str, '������','0');
  str := JReplace_(str, '�P','1');
  str := JReplace_(str, '�O','0');
  Result := (StrToIntDef(str, 0) <> 0);
end;

function sys_ftp_connect(args: DWORD): PHiValue; stdcall;
var
  ps: PHiValue;
  s : TStringList;
begin
  ps := nako_getFuncArg(args, 0);
  s  := TStringList.Create;
  s.Text := hi_str(ps);

  _idftp := Tidftp.Create(nil);

  _idftp.Username  := Trim(s.Values['ID']);
  _idftp.Password  := Trim(s.Values['�p�X���[�h']);
  if _idftp.Password = '' then _idftp.Password := Trim(s.Values['PASSWORD']);
  _idftp.Host      := Trim(s.Values['�z�X�g']);
  if _idftp.Host = '' then _idftp.Host := Trim(s.Values['HOST']);
  _idftp.Port      := StrToIntDef(Trim(s.Values['PORT']), 21);
  _idftp.Passive   := get_on_off(Trim(s.Values['PASV']));
  if _idftp.Username = '' then raise Exception.Create('FTP�̐ݒ��ID�����ݒ�ł��B');
  if _idftp.Password = '' then raise Exception.Create('FTP�̐ݒ��PASSWORD�����ݒ�ł��B');
  if _idftp.Host     = '' then raise Exception.Create('FTP�̐ݒ��HOST�����ݒ�ł��B');
  try
    _idftp.Connect(True);
    _idftp.OnWorkBegin := NetDialog.WorkBegin;
    _idftp.OnWork      := NetDialog.Work;
    _idftp.OnWorkEnd   := NetDialog.WorkEnd;
  except
    on e: Exception do
      raise Exception.Create('FTP�Őڑ����ł��܂���ł����B' + e.Message);
  end;

  FreeAndNil(s);
  Result := nil;
end;

function sys_ftp_disconnect(args: DWORD): PHiValue; stdcall;
begin
  //FreeAndNil(_kskFtp);
  if _idftp <> nil then try if _idftp.Connected then _idftp.DisconnectSocket; except end;
  FreeAndNil(_idftp);
  Result := nil;
end;

procedure proc_ftp_upload(Sender: TNetThread; ptr: Tidftp);
var
  dat: TMemoryStream;
  ps: PString;
begin
  dat := TMemoryStream(Sender.arg1);
  ps  := Sender.arg2;
  ptr.Put(dat, ps^);
  net_dialog_complete := True;
end;

procedure proc_ftp_uploadDir(Sender: TNetThread; ftp: Tidftp);
var
  local, remote: String;

  procedure _upload(local, remote: string);
  var
    dirs, files: THStringList;
    tmp: string;
    i: Integer;
    flgSubDir: Boolean;
  begin
    // make dir
    flgSubDir := False;
    if remote <> '' then
    begin
      try
        ftp.MakeDir(remote);
      except
      end;
      ftp.ChangeDir(remote);
      flgSubDir := True;
    end;
    // file
    files := EnumFiles(local + '*');
    try
      for i := 0 to files.Count - 1 do
      begin
        tmp := files.Strings[i];
        ftp.Put(local + tmp, tmp);
      end;
    finally
      files.Free;
    end;
    // dir
    dirs := EnumDirs(local + '*');
    try
      for i := 0 to dirs.Count - 1 do
      begin
        tmp := dirs.Strings[i];
        _upload(local + tmp + '\', tmp);
      end;
    finally
      dirs.Free;
    end;
    if flgSubDir then
    begin
      ftp.ChangeDirUp;
    end;
  end;

begin
  local  := PString(Sender.arg1)^;
  remote := PString(Sender.arg2)^;

  if Copy(local, Length(local), 1) <> '\' then
  begin
    local := local + '\';
  end;

  if DirectoryExists(local) = False then
  begin
    raise Exception.Create('�u' + local + '�v�͑��݂��Ȃ��t�H���_���ł��B');
  end;

  _upload(local, remote);

  net_dialog_complete := True;
end;

function sys_ftp_setTimeout(args: DWORD): PHiValue; stdcall;
var
  i: Integer;
begin
  i := getArgInt(args, 0);
  if _idftp = nil then raise Exception.Create('���̖��߂̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  _idftp.ReadTimeout := i;
  Result := nil;
end;

function sys_ftp_upload(args: DWORD): PHiValue; stdcall;
var
  pLocal, pRemote: PHiValue;
  dat: TMemoryStream;
  fname,remote: string;
  uploader: TNetThread;
  bShow: Boolean;
begin
  pLocal  := nako_getFuncArg(args, 0);
  pRemote := nako_getFuncArg(args, 1);

  if _idftp = nil then raise Exception.Create('�A�b�v���[�h�̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  _idftp.Tag := hi_int(pProgDialog);
  try
    fname := hi_str(pLocal);
    if CheckFileExists(fname) = False then
    begin
      raise Exception.CreateFmt('�A�b�v���[�h�Ώۃt�@�C��"%s"������܂���B',[fname]);
    end;
    remote := hi_str(pRemote);
    dat := TMemoryStream.Create;
    try
    try
      dat.LoadFromFile(fname);
      if _idftp.Connected = False then raise Exception.Create('�ڑ����Ă��܂���B');
      uploader := TNetThread.Create(True);
      bShow := hi_bool(nako_getVariable('�o�߃_�C�A���O'));
      uploader.arg0 := _idftp;
      uploader.arg1 := dat;
      uploader.arg2 := @remote;
      uploader.method := @proc_ftp_upload;
      uploader.FreeOnTerminate := True;
      uploader.Resume;
      if False = NetDialog.ShowDialog('FTP�A�b�v���[�h', hi_str(pRemote)+'�փA�b�v��', bShow) then
      begin
        try
          _idftp.Abort;
        except end;
        raise Exception.Create('���[�U�[�ɂ�蒆�f�{�^����������܂����B');
      end;
    except
      raise;
    end;
    finally
      dat.Free;
    end;
  except
    on e: Exception do
    begin
      raise Exception.Create('FTP�A�b�v���[�h�Ɏ��s�B' + e.Message);
    end;
  end;
  Result := nil;
end;

function sys_ftp_uploadDir(args: DWORD): PHiValue; stdcall;
var
  pLocal, pRemote: PHiValue;
  fname, remote: string;
  uploader: TNetThread;
  bShow: Boolean;
begin
  pLocal  := nako_getFuncArg(args, 0);
  pRemote := nako_getFuncArg(args, 1);

  if _idftp = nil then raise Exception.Create('�A�b�v���[�h�̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  _idftp.Tag := hi_int(pProgDialog);
  try
    fname := hi_str(pLocal);
    if DirectoryExists(fname) = False then
    begin
      raise Exception.CreateFmt('�A�b�v���[�h�Ώۃt�@�C��"%s"������܂���B',[fname]);
    end;
    remote := hi_str(pRemote);
    try
    try
      if _idftp.Connected = False then raise Exception.Create('�ڑ����Ă��܂���B');
      uploader := TNetThread.Create(True);
      bShow := hi_bool(nako_getVariable('�o�߃_�C�A���O'));
      uploader.arg0 := _idftp;
      uploader.arg1 := @fname;
      uploader.arg2 := @remote;
      uploader.method := @proc_ftp_uploadDir;
      uploader.FreeOnTerminate := True;
      uploader.Resume;
      if False = NetDialog.ShowDialog('FTP�ꊇ�A�b�v���[�h', hi_str(pRemote)+'�փA�b�v��', bShow) then
      begin
        try
          _idftp.Abort;
        except end;
        raise Exception.Create('���[�U�[�ɂ�蒆�f�{�^����������܂����B');
      end;
    except
      raise;
    end;
    finally
    end;
  except
    on e: Exception do
    begin
      raise Exception.Create('FTP�A�b�v���[�h�Ɏ��s�B' + e.Message);
    end;
  end;
  Result := nil;
end;


function sys_ftp_mode(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
  s: string;
begin
  p  := nako_getFuncArg(args, 0);
  s  := hi_str(p);

  //if _kskFtp = nil then raise Exception.Create('���[�h�ݒ�̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  if _idftp = nil then raise Exception.Create('���[�h�ݒ�̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');

  //if s <> '�A�X�L�[' then _kskFtp.Mode := FTP_TRANSFER_TYPE_BINARY
  //                   else _kskFtp.Mode := FTP_TRANSFER_TYPE_ASCII;

  if s <> '�A�X�L�[' then _idftp.TransferType := ftBinary
                     else _idftp.TransferType := ftAscii;

  Result := nil;
end;


function sys_ftp_upCurDir(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
  s: string;
begin
  p  := nako_getFuncArg(args, 0);
  s  := hi_str(p);

  if _idftp = nil then raise Exception.Create('���[�h�ݒ�̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  _idftp.ChangeDirUp;
  Result := nil;
end;


procedure proc_ftp_download(Sender: TNetThread; ptr: Tidftp);
var
  dat: TMemoryStream;
  ps: PString;
begin
  dat := TMemoryStream(Sender.arg1);
  ps  := Sender.arg2;
  _idftp.Get(ps^, dat);
  net_dialog_complete := True;
end;

procedure proc_ftp_downloadDir(Sender: TNetThread; ftp: Tidftp);
var
  local, remote: string;
  isError: Boolean;
  errors: string;

  procedure _getDir(_local, _remote: string);
  var
    tmp, tmp_d: string;
    dirs, saiki: TStringList;
    i: Integer;
    p: PChar;
    item: TIdFTPListItem;
    f: TSearchRec;
  begin
    if isError then Exit;
    if Sender.Terminated then Exit;

    // enum dirs
    saiki := TStringList.Create;
    dirs  := TStringList.Create;
    try
      try
        NetDialog.setInfo('����:' + _remote);
        NetDialog.target := '�ړ�:' + _remote;
        ftp.ChangeDir(_remote);
        NetDialog.target := '�ꗗ�̎擾:' + _remote;
        ftp.List(dirs);
        if dirs.Count = 0 then Exit;

        for i := 0 to ftp.DirectoryListing.Count - 1 do
        begin
          item := ftp.DirectoryListing.Items[i];
          if (item.ItemType = ditFile) and
             (item.ModifiedDate > 0) then
          begin
            tmp := item.FileName;
            if tmp <> '' then
            begin
              p := PChar(tmp);
              tmp_d := sjis_copyByte(p,24);
              if tmp <> tmp_d then tmp_d := tmp_d + '..';
              NetDialog.target :=
                IntToStr(i+1) + '/' + IntToStr(ftp.DirectoryListing.Count) + ',' +
                tmp_d;
            end;
            // --- �����_�E�����[�h
            if FileExists(_local + tmp) then
            begin
              if FindFirst(_local + tmp, faAnyFile, f) = 0 then
              begin
                if FileTimeToDateTimeEx(f.FindData.ftLastWriteTime) = item.ModifiedDate then
                begin
                  if f.Size = item.Size then
                  begin
                    FindClose(f);
                    Continue;
                  end;
                end;
                DeleteFile(_local + tmp);
              end;
              FindClose(f);
            end;
            // --- �_�E�����[�h
            try
              ftp.Get(tmp, _local + tmp);
              SetFileTimeEx(_local + tmp, item.ModifiedDate, item.ModifiedDate, item.ModifiedDate);
            except
              on e: Exception do
              begin
                errors := errors + tmp + ':' + e.Message + #13#10;
                // continue;
              end;
            end;
          end else
          if (item.ItemType = ditDirectory) and
             (item.ModifiedDate > 0) then
          begin
            tmp := item.FileName;
            if (tmp = '.')or(tmp = '..') then Continue;
            saiki.Add(tmp);
          end;
        end;
        for i := 0 to saiki.Count - 1 do
        begin
          tmp := saiki.Strings[i];
          ForceDirectories(_local + tmp + '\');
          _getDir(_local + tmp + '\', tmp);
        end;
        NetDialog.setText('�f�B���N�g������Ɉړ�');
        ftp.ChangeDirUp;
      except
        on e:Exception do
        begin
          isError := True;
          errors := errors + _remote + ':' + e.Message + #13#10;
          Exit;
        end;
      end;
    finally
      dirs.Free;
      saiki.Free;
    end;
  end;

begin
  //
  local  := PString(Sender.arg1)^;
  remote := PString(Sender.arg2)^;

  isError := False;
  errors := '';

  if Copy(local, Length(local), 1) <> '\' then
  begin
    local := local + '\';
  end;
  if not DirectoryExists(local) then
  begin
    ForceDirectories(local);
  end;
  _getDir(local, remote);
  //
  NetDialog.errormessage := errors;
  net_dialog_complete := True;
end;


function sys_ftp_download(args: DWORD): PHiValue; stdcall;
var
  pLocal, pRemote: PHiValue;
  dat: TMemoryStream;
  fname, remote: string;
  thread: TNetThread;
  bShow: Boolean;
begin
  pRemote := nako_getFuncArg(args, 0);
  pLocal  := nako_getFuncArg(args, 1);

  if _idftp = nil then raise Exception.Create('�_�E�����[�h�̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');

  _idftp.Tag := hi_int(pProgDialog);
  dat := TMemoryStream.Create;
  try
    fname  := hi_str(pLocal);
    remote := hi_str(pRemote);

    NetDialog.errormessage := '';
    net_dialog_cancel      := False;
    net_dialog_complete    := False;

    thread  := TNetThread.Create(True);
    bShow   := hi_bool(nako_getVariable('�o�߃_�C�A���O'));
    thread.arg0 := _idftp;
    thread.arg1 := dat;
    thread.arg2 := @remote;
    thread.method := @proc_ftp_download;
    thread.FreeOnTerminate := True;
    thread.Resume;
    if False = NetDialog.ShowDialog('FTP�_�E�����[�h', hi_str(pRemote)+'����_�E�����[�h��', bShow) then
    begin
      try
        _idftp.Abort;
      except end;
      raise Exception.Create('���[�U�[�ɂ�蒆�f�{�^����������܂����B');
    end;

    dat.SaveToFile(fname);
  except
    on e: Exception do
    begin
      raise Exception.Create('FTP�_�E�����[�h�Ɏ��s�B' + e.Message);
    end;
  end;
  FreeAndNil(dat);

  Result := nil;
end;

function sys_ftp_downloadDir(args: DWORD): PHiValue; stdcall;
var
  pLocal, pRemote: PHiValue;
  fname, remote: string;
  thread: TNetThread;
  bShow: Boolean;
begin
  pRemote := nako_getFuncArg(args, 0);
  pLocal  := nako_getFuncArg(args, 1);

  if (_idftp = nil)or(not _idftp.Connected) then raise Exception.Create('�_�E�����[�h�̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');

  _idftp.Tag := hi_int(pProgDialog);
  try
    fname  := hi_str(pLocal);
    remote := hi_str(pRemote);
    
    NetDialog.errormessage := '';
    net_dialog_cancel      := False;
    net_dialog_complete    := False;

    thread  := TNetThread.Create(True);
    bShow   := hi_bool(nako_getVariable('�o�߃_�C�A���O'));
    thread.arg0 := _idftp;
    thread.arg1 := @fname;
    thread.arg2 := @remote;
    thread.method := @proc_ftp_downloadDir;
    thread.FreeOnTerminate := True;
    thread.Resume;
    if False = NetDialog.ShowDialog('FTP�ꊇ�_�E�����[�h', hi_str(pRemote)+'����_�E�����[�h��', bShow) then
    begin
      try
        _idftp.Abort;
      except end;
      raise Exception.Create('���[�U�[�ɂ�蒆�f�{�^����������܂����B');
    end;
    if NetDialog.errormessage <> '' then
    begin
      raise Exception.Create(NetDialog.errormessage);
    end;
  except
    on e: Exception do
    begin
      raise Exception.Create('FTP�_�E�����[�h�Ɏ��s�B' + e.Message);
    end;
  end;

  Result := nil;
end;



function sys_ftp_glob(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
  s, res, tmp: string;
  sl: TStringList;
  i: Integer;
begin
  p := nako_getFuncArg(args, 0);
  s := hi_str(p);

  if _idftp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  sl := TStringList.Create;
  try
    _idftp.List(sl, s);
    res := '';
    for i := 0 to _idftp.DirectoryListing.Count - 1 do
    begin
      if (_idftp.DirectoryListing.Items[i].ItemType = ditFile) and
         (_idftp.DirectoryListing.Items[i].ModifiedDate > 0) then
      begin
        tmp := _idftp.DirectoryListing.Items[i].FileName;
        if (tmp = '.')or(tmp = '..') then Continue;
        res := res + tmp + #13#10;
      end;
    end;
    Result := hi_newStr(res);
  except
    Result := hi_newStr('');
    sl.Free;
  end;
  sl.Free;
end;



function sys_ftp_glob2(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
  s, res: string;
  sl: TStringList;
begin
  p := nako_getFuncArg(args, 0);
  s := hi_str(p);

  if _idftp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  sl := TStringList.Create;
  try
    _idftp.List(sl, s);
    res := sl.Text;
    Result := hi_newStr(res);
  except
    Result := hi_newStr('');
    sl.Free;
  end;
  sl.Free;
end;


function sys_ftp_globDir(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
  s, res, tmp: string;
  sl: TStringList;
  i: Integer;
begin
  p := nako_getFuncArg(args, 0);
  s := hi_str(p);

  //if _kskFtp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  //Result := hi_newStr(Trim(_kskFtp.GlobDir(s)));

  if _idftp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  sl := TStringList.Create;
  try
    _idftp.List(sl, s);
    res := '';
    for i := 0 to _idftp.DirectoryListing.Count - 1 do
    begin
      if (_idftp.DirectoryListing.Items[i].ItemType = ditDirectory) and
         (_idftp.DirectoryListing.Items[i].ModifiedDate > 0) then
      begin
        tmp := _idftp.DirectoryListing.Items[i].FileName;
        if (tmp = '.')or(tmp = '..') then Continue;
        res := res + tmp + #13#10;
      end;
    end;
    Result := hi_newStr(res);
  except
    Result := hi_newStr('');
    sl.Free;
  end;
  sl.Free;
end;

function sys_ftp_mkdir(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
  s: string;
begin
  p := nako_getFuncArg(args, 0);
  s := hi_str(p);

  //if _kskFtp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  //_kskFtp.CreateDir(s);
  if _idftp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  _idftp.MakeDir(s);

  Result := nil;
end;

function sys_ftp_rmdir(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
  s: string;
begin
  p := nako_getFuncArg(args, 0);
  s := hi_str(p);

  //if _kskFtp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  //_kskFtp.DeleteDir(s);

  if _idftp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  _idftp.RemoveDir(s);

  Result := nil;
end;

function sys_ftp_changeDir(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
  s: string;
begin
  p := nako_getFuncArg(args, 0);
  s := hi_str(p);

  //if _kskFtp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  //_kskFtp.ChangeDir(s);

  if _idftp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  _idftp.ChangeDir(s);

  Result := nil;
end;

function sys_ftp_getCurDir(args: DWORD): PHiValue; stdcall;
begin
  //if _kskFtp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  //s := _kskFtp.CurrentDir;
  if _idftp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  //
  Result := hi_newStr(_idftp.RetrieveCurrentDir);
end;

function sys_ftp_delFile(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
  s: string;
begin
  p := nako_getFuncArg(args, 0);
  s := hi_str(p);

  //if _kskFtp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  //_kskFtp.DeleteFile(s);
  if _idftp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  _idftp.Delete(s);

  Result := nil;
end;

function sys_ftp_rename(args: DWORD): PHiValue; stdcall;
var
  pa, pb: PHiValue;
begin
  pa := nako_getFuncArg(args, 0);
  pb := nako_getFuncArg(args, 1);

  //if _kskFtp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  //_kskFtp.RanemeFile(hi_str(pa), hi_str(pb));

  if _idftp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  _idftp.Rename(hi_str(pa), hi_str(pb));


  Result := nil;
end;

function sys_ftp_command(args: DWORD): PHiValue; stdcall;
var
  ps: PHiValue;
  i:smallint;
  res:string;
begin
  ps := nako_getFuncArg(args, 0);
  res:='';
  {
  if _kskFtp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  if not _kskFtp.Command(hi_str(ps), True, res) then
  begin
    raise Exception.Create('�R�}���h"' + hi_str(ps) + '"�Ɏ��s�B');
  end;
  }
  if _idftp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  try
    i:=_idftp.Quote(hi_str(ps));
  except
    raise Exception.Create('�R�}���h"' + hi_str(ps) + '"�Ɏ��s�B');
  end;
  Result := hi_newStr(IntToStr(i)+' '+_idftp.LastCmdResult.Text.Text);
end;

function sys_ftp_chmod(args: DWORD): PHiValue; stdcall;
var
  ps, pa: PHiValue;
  s, a, cmd: string;
begin
  ps := nako_getFuncArg(args, 0);
  pa := nako_getFuncArg(args, 1);

  s := Trim(hi_str(ps));
  a := Trim(hi_str(pa));

  //if _kskFtp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');

  if _idftp = nil then raise Exception.Create('FTP�����̑O�ɁwFTP�ڑ��x�Őڑ����Ă��������B');
  cmd := 'CHMOD ' + a + ' ' + s;
  {
  if not _kskFtp.Command(cmd, False, res) then
  begin
    raise Exception.Create('�����ύX�Ɏ��s�B');
  end;
  }
  try
    _idftp.Site(cmd);
  except
    raise Exception.Create('�R�}���h"' + cmd + '"�Ɏ��s�B');
  end;
  //
  Result := nil;
end;

procedure getPop3Info(pop3: TKPop3Dialog);
var
  option: string;
begin
  pop3.Host       := hi_str(nako_getVariable('���[���z�X�g'));
  pop3.Port       := StrToIntDef(hi_str(nako_getVariable('���[���|�[�g')), 110);
  pop3.User       := hi_str(nako_getVariable('���[��ID'));
  pop3.Password   := hi_str(nako_getVariable('���[���p�X���[�h'));
  option          := UpperCase(hi_str(nako_getVariable('���[���I�v�V����')));
  if Pos('APOP',option) > 0 then pop3.APop := True;
  // CHECK
  if pop3.Host = '' then raise Exception.Create('���[���z�X�g����ł��B');
  if pop3.Port < 0  then raise Exception.Create('���[���|�[�g���s���Ȑ��l�ł��B');
  if pop3.User = '' then raise Exception.Create('���[�����[�U�[����ł��B');
  if pop3.Password = '' then raise Exception.Create('���[���p�X���[�h����ł��B');
end;

function sys_pop3_recv(args: DWORD): PHiValue; stdcall;
var
  tmpDir, dir, fname, afile, txtFile,emlFile: string;
  from, replyto: string;
  pop3: TKPop3Dialog;
  i, j, sid: Integer;
  eml, sub: TEml;
  txt, msgid: string;
  msgids: TStringList;
const
  FILE_MSGIDS = 'msgids.___';
begin
  //===================
  // �����̎擾
  dir := hi_str(nako_getFuncArg(args, 0));
  if Copy(dir, Length(dir), 1) <> '\' then dir := dir + '\';

  //===================
  // ��M�t�H���_�̃`�F�b�N
  if not ForceDirectories(dir) then
  begin
    raise Exception.Create('�t�H���_�w'+dir+'�x���쐬�ł��܂���ł����B');
  end;

  //===================
  // �ꎞ�t�H���_�֎�M
  tmpDir := TempDir + 'pop3_' + FormatDateTime('yymmddhhnnsszzz',Now) + '\';
  ForceDirectories(tmpDir);

  //===================
  msgids := TStringList.Create;
  pop3 := TKPop3Dialog.Create(nil);
  try
    // ���b�Z�[�WID�̈ꗗ���`�F�b�N
    if FileExists(dir + FILE_MSGIDS) then msgids.LoadFromFile(dir + FILE_MSGIDS);
    //
    pop3.ShowDialog := hi_bool(nako_getVariable('�o�߃_�C�A���O'));
    getPop3Info(pop3);
    // ��M����
    try
      Result := hi_newInt(
        pop3.Pop3RecvAll(tmpDir, hi_bool(nako_getVariable('���[����M���폜')))
      );
    except
      raise;
    end;
    // ��͏���
    sid := 1;
    for i := 1 to hi_int(Result) do
    begin
      fname := tmpDir + IntToStr(i) + '.eml';
      try
        txt := '';
        eml := TEml.Create(nil);
        eml.LoadFromFile(fname);
        msgid := eml.Header.Items['Message-Id'];
        if msgid = '' then begin msgid := MD5FileS(fname); end;
        if msgids.IndexOf(msgid) >= 0 then Continue;// ���Ɏ�M�ς݂Ȃ�X�L�b�v
        msgids.Add(msgid);
        // �w�b�_�����擾
        from    := ExtractMailAddress(eml.Header.GetDecodeValue('From'));
        replyto := ExtractMailAddress(eml.Header.GetDecodeValue('Reply-To'));
        txt := txt + '���o�l: ' + eml.Header.GetDecodeValue('From')   + #13#10;
        if (from <> replyto)and(replyto <> '') then txt := txt + '�ԐM��: ' + replyto + #13#10;
        txt := txt + '����: '   + eml.Header.GetDecodeValue('To')     + #13#10;
        txt := txt + '����: '   + eml.Header.GetDecodeValue('Subject')+ #13#10;
        txt := txt + '���t: '   + FormatDateTime('yyyy/mm/dd hh:nn:ss', eml.Header.GetDateTime('Date')) + #13#10;
        // �Y�t�t�@�C�������邩
        if eml.GetPartsCount > 0 then
        begin
          // �Y�t�t�@�C�����P���ۑ����Ă���
          for j := 0 to eml.GetPartsCount - 1 do
          begin
            sub := eml.GetParts(j);
            if (sub.EmlType = typeApplication)or(sub.EmlType = typeImage) then
            begin
              afile := sub.GetAttachFilename;
              while FileExists(dir + afile) do afile := '_' + afile;
              sub.BodySaveAsAttachment(dir + afile);
              txt := txt + '�Y�t�t�@�C��:' + afile + #13#10;
            end;
          end;
        end;
        txt := txt + #13#10;
        txt := txt + ConvertJCode(eml.GetTextBody, SJIS_OUT);
        //=== SaveFileName
        while True do
        begin
          txtFile := dir + IntToStr(sid) + '.txt';
          emlFile := dir + IntToStr(sid) + '.eml';
          if FileExists(txtFile) then begin Inc(sid); Continue; end;
          Break;
        end;
        StrWriteFile(txtFile, txt);
        CopyFile(PChar(fname), PChar(emlFile), False);
        //---
        eml.Free;
      except on e: Exception do
        raise Exception.Create('���[����M�Ŏ�M�������[��'+IntToStr(i)+'�̉�͂ŃG���[�B' + e.Message);
      end;
    end;
    msgids.SaveToFile(dir + FILE_MSGIDS); // ���b�Z�[�WID�̈ꗗ��ۑ�
  finally
    //======
    // �ꎞ�t�H���_���폜
    tmpDir := Copy(tmpDir, 1, Length(tmpDir) - 1);
    SHFileDeleteComplete(tmpDir);
    //======
    pop3.Free;
    msgids.Free;
  end;

end;

function sys_pop3_list(args: DWORD): PHiValue; stdcall;
var
  pop3: TKPop3Dialog;
begin
  //Result := nil;
  pop3 := TKPop3Dialog.Create(nil);
  try
    pop3.ShowDialog := hi_bool(nako_getVariable('�o�߃_�C�A���O'));
    getPop3Info(pop3);
    Result := hi_newStr(pop3.Pop3List);
  finally
    pop3.Free;
  end;
end;

function sys_ping(args: DWORD): PHiValue; stdcall;
var
  p: TICMP;
begin
  p := TICMP.Create;
  try
    try
      p.Address := getArgStr(args, 0, True);
      Result := hi_newInt(p.Ping);
    except
      Result := hi_newInt(0);
    end;
  finally
    p.Free;
  end;
end;

function sys_tcp_command(args: DWORD): PHiValue; stdcall;
var
  obj, group, command, value: PHiValue;
  cmd, s: string; i: Integer;
  p: TNakoTcpClient;
begin
  Result := nil;

  group     := nako_getFuncArg(args, 0);
  command   := nako_getFuncArg(args, 1);
  value     := nako_getFuncArg(args, 2);

  cmd := LowerCase(hi_str(command));
  if cmd = 'create' then
  begin
    p := TNakoTcpClient.Create(nil);
    p.InstanceVar := group;
    Result := hi_newInt(Integer(p));
  end else
  begin
    // �I�u�W�F�N�g������
    obj := nako_group_findMember(group, '�I�u�W�F�N�g');
    if obj = nil then raise Exception.Create('�I�u�W�F�N�g������ł��܂���B');
    i   := hi_int(obj);
    p := TNakoTcpClient(Integer(i));

    if cmd = 'connect' then
    begin
      s := hi_str(value);
      try
        p.ServerAddr := PInAddr(GetHostEnt(getToken_s(s, ':')).h_addr_list^)^;
      except on e: Exception do
        raise Exception.Create('�z�X�g���������ł��܂���B');
      end;
      //---
      p.Port := StrToIntDef(s, 80);
      try
        p.Connect;
      except on e: Exception do
        raise Exception.Create('�ڑ��Ɏ��s�B' + e.Message);
      end;
    end else
    if cmd = 'disconnect' then p.Close else
    if cmd = 'send' then
    begin
      s := hi_str(value);
      try
        p.SendString(s);
      except
        raise;
      end;
    end else
    if cmd = 'recv' then
    begin
      Result := hi_newStr(p.RecvString);
    end else
    if cmd = 'recvbyte' then
    begin
      Result := hi_newStr(p.RecvStrByte(i));
    end else
    ;
  end;
end;

function sys_udp_command(args: DWORD): PHiValue; stdcall;
var
  obj, group, command, value: PHiValue;
  cmd, s: string; i: Integer;
  p: TNakoUdp;
begin
  Result := nil;

  group     := nako_getFuncArg(args, 0);
  command   := nako_getFuncArg(args, 1);
  value     := nako_getFuncArg(args, 2);

  cmd := LowerCase(hi_str(command));
  if cmd = 'create' then
  begin
    p := TNakoUdp.Create(nil);
    p.InstanceVar := group;
    Result := hi_newInt(Integer(p));
  end else
  begin
    // �I�u�W�F�N�g������
    obj := nako_group_findMember(group, '�I�u�W�F�N�g');
    if obj = nil then raise Exception.Create('�I�u�W�F�N�g������ł��܂���B');
    i   := hi_int(obj);
    p := TNakoUdp(Integer(i));

    if cmd = 'connect' then
    begin
      s := hi_str(value);
      try
        p.Host := getToken_s(s, ':');
      except on e: Exception do
        raise Exception.Create('�z�X�g���������ł��܂���B');
      end;
      //---
      p.PortNo := StrToIntDef(s, 80);
      try
        p.Open;
      except on e: Exception do
        raise Exception.Create('�ڑ��Ɏ��s�B' + e.Message);
      end;
    end else
    if cmd = 'send' then
    begin
      s := hi_str(value);
      try
        if s <> '' then p.Send(s[1], Length(s));
      except
        raise;
      end;
    end else
    if cmd = 'disconnect' then p.Close else
    if cmd = 'multicast'  then p.AddMultiCast else
    ;
  end;
end;

function sys_get_ip(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr( GetIpAddressStr( getArgStr(args,0,True) ) );
end;

function sys_get_host(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr( GetHostNameByAddr( getArgStr(args,0,True) ) );
end;

function sys_tcp_svr_command(args: DWORD): PHiValue; stdcall;
var
  obj, group, command, value: PHiValue;
  cmd, cmd2: string; i: Integer;
  p: TNakoTcpServer;
begin
  Result := nil;

  group     := nako_getFuncArg(args, 0);
  command   := nako_getFuncArg(args, 1);
  value     := nako_getFuncArg(args, 2);

  cmd := LowerCase(hi_str(command));
  if cmd = 'create' then
  begin
    p := TNakoTcpServer.Create(nil);
    p.InstanceVar := group;
    Result := hi_newInt(Integer(p));
  end else
  begin
    // �R�}���h�����
    cmd2 := cmd;
    cmd := getToken_s(cmd2, ' ');
    // �I�u�W�F�N�g������
    obj := nako_group_findMember(group, '�I�u�W�F�N�g');
    if obj = nil then raise Exception.Create('�I�u�W�F�N�g������ł��܂���B');
    i   := hi_int(obj);
    p := TNakoTcpServer(Integer(i));
    //---
    if cmd = 'active' then
    begin
      i := hi_int(value);
      p.Port := StrToIntDef(cmd2, 10001);
      p.Active := (i <> 0);
    end
    else if cmd = 'close' then
    begin
      p.CloseFromIp(hi_str(value));
    end
    else if cmd = 'list' then
    begin
      Result := hi_newStr(p.getClientList);
    end
    else if cmd = 'send' then
    begin
      p.SendToData(cmd2, hi_str(value))
    end
    else
    ;
  end;
end;

function sys_pop3_dele(args: DWORD): PHiValue; stdcall;
var
  pop3: TKPop3Dialog;
  no: PHiValue;
begin
  Result := nil;
  no   := nako_getFuncArg(args, 0);
  pop3 := TKPop3Dialog.Create(nil);
  try
    pop3.ShowDialog := hi_bool(nako_getVariable('�o�߃_�C�A���O'));
    getPop3Info(pop3);
    pop3.Pop3Dele(hi_int(no));
  finally
    pop3.Free;
  end;
end;


function sys_smtp_send(args: DWORD): PHiValue; stdcall;
var
  smtp: TKSmtpDialog;
  addHead, option, from, rcptto, title, body, attach, html, cc, bcc: string;
begin
  smtp := TKSmtpDialog.Create(nil);
  try
    smtp.ShowDialog := hi_bool(nako_getVariable('�o�߃_�C�A���O'));

    // �T�[�o�[���
    smtp.Host       := hi_str(nako_getVariable('���[���z�X�g'));
    smtp.Port       := StrToIntDef(hi_str(nako_getVariable('���[���|�[�g')), 25);
    smtp.User       := hi_str(nako_getVariable('���[��ID'));
    smtp.Password   := hi_str(nako_getVariable('���[���p�X���[�h'));
    addHead         := hi_str(nako_getVariable('���[���w�b�_'));
    // CHECK
    if smtp.Host = '' then raise Exception.Create('���[���z�X�g����ł��B');
    // �F��
    option := UpperCase(hi_str(nako_getVariable('���[���I�v�V����')));
    if Pos('LOGIN',    option) > 0 then smtp.AuthLogin := True;
    if Pos('CRAM-MD5', option) > 0 then smtp.AuthMD5   := True;
    if Pos('PLAIN',    option) > 0 then smtp.AuthPlain := True;
    // ����Ȃ�
    from   := hi_str(nako_getVariable('���[�����o�l'));
    rcptto := hi_str(nako_getVariable('���[������'));
    title  := hi_str(nako_getVariable('���[������'));
    body   := hi_str(nako_getVariable('���[���{��'));
    attach := hi_str(nako_getVariable('���[���Y�t�t�@�C��'));
    html   := hi_str(nako_getVariable('���[��HTML'));
    cc     := hi_str(nako_getVariable('���[��CC'));
    bcc    := hi_str(nako_getVariable('���[��BCC'));
    // ���ۂɑ��M
    smtp.Send(from, rcptto, title, body, attach, html, cc, bcc, addHead);
  finally
    smtp.Free;
  end;

  Result := nil;
end;


var eml: TEml = nil; // EML�����̂��߂̕ϐ�

function sys_eml_load(args: DWORD): PHiValue; stdcall;
var f: PHiValue;
begin
  Result := nil;
  f := nako_getFuncArg(args, 0);
  FreeAndNil(eml);
  eml := TEml.Create(nil);
  eml.LoadFromFile(hi_str(f));
end;
function sys_eml_part_count(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newInt(eml.GetPartsCount);
end;
function sys_eml_part_type(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(eml.GetPartTypeList);
end;
function sys_eml_getText(args: DWORD): PHiValue; stdcall;
var i: PHiValue;
begin
  i := nako_getFuncArg(args, 0);
  Result := hi_newStr(eml.GetParts(hi_int(i)-1).GetTextBody);
end;
function sys_eml_getAttach(args: DWORD): PHiValue; stdcall;
var a,f: PHiValue;
begin
  Result := nil;
  a := nako_getFuncArg(args, 0);
  f := nako_getFuncArg(args, 1);
  eml.GetParts(hi_int(a)-1).BodySaveAsAttachment(hi_str(f));
end;
function sys_eml_getAllText(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(eml.GetTextBody);
end;
function sys_eml_getHeader(args: DWORD): PHiValue; stdcall;
var
  i: Integer;
  e: TEmlHeaderRec;
  s: string;
begin
  Result := hi_var_new;
  nako_hash_create(Result);
  for i := 0 to eml.Header.Count - 1 do
  begin
    e := eml.Header.Get(i);
    s := e.Name;
    nako_hash_set(Result, PChar(s), hi_newStr(eml.Header.GetDecodeValue(s)));
  end;
end;


function sys_http_head2hash(args: DWORD): PHiValue; stdcall;
var
  e: THttpHeadList;
  i: Integer;
  h: THttpHead;
  k, v: string;
begin
  // set hash
  Result := hi_var_new;
  nako_hash_create(Result);
  //
  e := THttpHeadList.Create;
  try
    e.SetAsText(getArgStr(args, 0, True));
    for i := 0 to e.Count - 1 do
    begin
      h := e.Items[i];
      k := h.Key;
      v := h.Value;
      nako_hash_set(Result, PChar(k), hi_newStr(v));
    end;
    if e.HttpVersion <> '' then
    begin
      v := e.HttpVersion;
      nako_hash_set(Result, 'HTTP.Version', hi_newStr(v));
    end;
    if e.Response >= 0 then
    begin
      nako_hash_set(Result, 'HTTP.Response', hi_newInt(e.Response));
    end;
  finally
    e.Free;
  end;
end;

function sys_http_post(args: DWORD): PHiValue; stdcall;
var
  http: TKHttpClient;
  url, head,body: string;
begin
  head := getArgStr(args, 0, True);
  body := getArgStr(args, 1, False);
  url  := getArgStr(args, 2);

  http := TKHttpClient.Create(nil);
  try
    // http �Z�b�e�B���O�𓾂�
    http.GetProxySettingFromRegistry;
    http.Port := 80;
    // post
    Result := hi_newStr(http.Post(url, head, body));
  finally
    http.Free;
  end;
end;


function sys_http_post_easy(args: DWORD): PHiValue; stdcall;
var
  http: TKHttpClient;
  url, body, head: string;
  key, keys: string;
  value, fname, name, mime: string;
  hash, pv: PHiValue;
  sl: TStringList;
  i: Integer;
begin
  url  := getArgStr(args, 0, True);
  hash := nako_getFuncArg(args, 1);
  nako_hash_create(hash);

  SetLength(keys, 65536);
  nako_hash_keys(hash, PChar(keys), 65535);

  sl := TStringList.Create;
  http := TKHttpClient.Create(nil);
  try
    sl.Text := Trim(keys);
    head := 'Content-Type: multipart/form-data; boundary=---------------------------1870989367997'#13#10;
    for i := 0 to sl.Count - 1 do
    begin
      key := sl.Strings[i];
      pv := nako_hash_get(hash, PChar(key));
      value := hi_str(pv);
      if key = '' then Continue;
      // value is file ?
      if (copy(value, 1, 6)) = '@file=' then
      begin
        System.Delete(value,1,6);
        value := Trim(value);
        fname := getToken_s(value, ';');
        name  := getToken_s(value, ';');
        name  := Trim(name);
        if name = '' then name := ExtractFileName(fname);
        mime := getToken_s(value, ';');
        mime := Trim(mime);
        if mime = '' then mime := getContentType(fname);
        try
          value := FileLoadAll(fname);
        except
          raise Exception.Create('�wHTTP�ȈՃ|�X�g�x�Ńt�@�C���̖��ߍ��݂Ɏ��s:' + fname);
        end;
        body := body + '-----------------------------1870989367997' + #13#10 +
          'Content-Disposition: form-data; name="' + key + '"; filename="' + name + '"' + #13#10 +
          'Content-Type:' + mime + #13#10#13#10 +
          value + #13#10;
      end else
      begin
        body := body + '-----------------------------1870989367997' + #13#10 +
          'Content-Disposition: form-data; name="' + key + '"'#13#10#13#10 +
          value + #13#10;
      end;
    end;
    body := body + '-----------------------------1870989367997--'#13#10;
    // FileSaveAll(body, DesktopDir + 'test.txt');
    //
    // http �Z�b�e�B���O�𓾂�
    http.GetProxySettingFromRegistry;
    http.Port := 80;
    if http_opt_useBasicAuth then
    begin
      http.AuthMode := httpBASIC;
      http.Username := http_opt_getId;
      http.Password := http_opt_getPassword;
    end;
    // post
    Result := hi_newStr(http.Post(url, head, body));
  finally
    sl.Free;
    http.Free;
  end;
end;


function sys_http_get(args: DWORD): PHiValue; stdcall;
var
  http: TKHttpClient;
  url, head: string;
begin
  head := getArgStr(args, 0, True);
  url  := getArgStr(args, 1);

  http := TKHttpClient.Create(nil);
  try
    // http �Z�b�e�B���O�𓾂�
    http.GetProxySettingFromRegistry;
    http.Port := 80;
    // post
    Result := hi_newStr(http.Get(url, head));
  finally
    http.Free;
  end;
end;

function sys_ntp_sync(args: DWORD): PHiValue; stdcall;
var
  s: PHiValue;
  server: string;
  IdNTP:TIdSNTP;
begin
  s := nako_getFuncArg(args, 0);
  if s = nil then server := 'ntp.ring.gr.jp'
             else server := hi_str(s);
  IdNTP := TIdSNTP.Create(nil);
  IdNtp.Host := server;

  Result := hi_newBool(IdNTP.SyncTime);
  IdNTP.Free;
end;


var kabin_server:TKabin = nil;

function sys_kabin_open(args: DWORD): PHiValue; stdcall;
begin
  Result := nil;
  if (kabin_server <> nil) then FreeAndNil(kabin_server);
  kabin_server := TKabin.Create;
  kabin_server.port := hi_int(nako_getVariable('�ԕrPORT'));
  kabin_server.password := hi_str(nako_getVariable('�ԕr�p�X���[�h'));
  kabin_server.Open;
end;

function sys_kabin_close(args: DWORD): PHiValue; stdcall;
begin
  Result := nil;
  if (kabin_server <> nil) then
  begin
    FreeAndNil(kabin_server);
  end;
end;


function sys_json_encode(args: DWORD): PHiValue; stdcall;
var
  p: PHiValue;
begin
  p := getArg(args, 0, True);
  Result := hi_newStr(PHiValue2Json(p));
end;

function sys_json_decode(args: DWORD): PHiValue; stdcall;
begin
  Result := Json2PHiValue(getArgStr(args,0,True));
end;


function get_nakonet_dll_version(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(NAKONET_DLL_VERSION);
end;


procedure RegistFunction;

  procedure _option;
  begin
    nako_dialog_function.DialogParent := nako_getMainWindowHandle;
    MainWindowHandle := nako_getMainWindowHandle;
    pProgDialog := nako_getVariable('�o�߃_�C�A���O');
  end;

begin
  //todo: ���ߒǉ�
  //<����>
  //+�l�b�g���[�N(nakonet.dll)
  //-HTTP
  AddFunc  ('HTTP�_�E�����[�h', 'URL��FILE��|URL����FILE��',  4010, sys_http_download,      'URL�����[�J��FILE�փ_�E�����[�h����B',          'HTTP�������[��');
  AddFunc  ('HTTP�f�[�^�擾',   'URL����|URL��|URL��',        4011, sys_http_downloaddata,  'URL����f�[�^���_�E�����[�h���ē��e��Ԃ��B',    'HTTP�Ł[������Ƃ�');
  AddFunc  ('HTTP�w�b�_�擾',   'URL����|URL��|URL��',        4012, sys_http_downloadhead,  'URL����w�b�_���擾���ē��e��Ԃ��B(WinInet�֐����g�p�Blocation������΍Ď擾)', 'HTTP�ւ�������Ƃ�');
  AddFunc  ('HTTP�ȈՃw�b�_�擾','URL����|URL��|URL��',       4013, sys_http_downloadhead2,  'URL����w�b�_���擾���ē��e��Ԃ��B(�P����HEAD�R�}���h�̉�����Ԃ�)', 'HTTP���񂢂ւ�������Ƃ�');
  AddFunc  ('HTTP�w�b�_�n�b�V���ϊ�','{=?}S��|S��|S��',       4014, sys_http_head2hash, 'HTTP�Ŏ擾�����w�b�_�����n�b�V���ɕϊ����ĕԂ��B', 'HTTP�ւ����͂�����ւ񂩂�');
  AddFunc  ('HTTP�|�X�g','{������=?}HEAD��BODY��URL��|BODY��',4015, sys_http_post, '�|�X�g���������e��HEAD��BODY��URL�փ|�X�g�����̌��ʂ�Ԃ��B', 'HTTP�ۂ���');
  AddFunc  ('HTTP�Q�b�g','{������=?}HEAD��URL��|HEAD��',      4016, sys_http_get, '���M�w�b�_HEAD���w�肵��URL��GET�R�}���h�𔭍s����B�����Ă��̌��ʂ�Ԃ��B', 'HTTP������');
  AddFunc  ('HTTP�ȈՃ|�X�g','URL��VALUES��|URL��',4017, sys_http_post_easy, '�|�X�g�������l(�n�b�V���`��)VALUES��URL�փ|�X�g�����̌��ʂ�Ԃ��B', 'HTTP���񂢂ۂ���');
  AddStrVar('HTTP�I�v�V����',   '',                4018, 'HTTP�Ɋւ���I�v�V�������n�b�V���`���Őݒ肷��BBASIC�F�؂́uBASIC�F��=�I��{~}ID=xxx{~}�p�X���[�h=xxx�v�Ə����BUA�̕ύX�́uUA=nadesiko�v�̂悤�ɏ����B','HTTP���Ղ����');

  //-FTP
  AddFunc  ('FTP�ڑ�',          'S��',                        4020, sys_ftp_connect,        '�ڑ����u�z�X�g=xxx{~}ID=xxx{~}�p�X���[�h=xxx{~}PORT=xx{~}PASV=�I��|�I�t�v��FTP�ɐڑ�����', 'FTP������');
  AddFunc  ('FTP�ؒf',          '',                           4021, sys_ftp_disconnect,     'FTP�̐ڑ���ؒf����',                                      'FTP������');
  AddFunc  ('FTP�A�b�v���[�h',  'A��B��|A����B��',            4022, sys_ftp_upload,         '���[�J���t�@�C��A�������[�h�t�@�C��B�փA�b�v���[�h����',   'FTP�����Ղ�[��');
  AddFunc  ('FTP�t�H���_�A�b�v���[�h',  'A��B��|A����B��',    4038, sys_ftp_uploadDir,      '���[�J���t�H���_A�������[�h�t�H���_B�փA�b�v���[�h����',   'FTP�ӂ��邾�����Ղ�[��');
  AddFunc  ('FTP�]�����[�h�ݒ�','S��',                        4023, sys_ftp_mode,           'FTP�̓]�����[�h���u�o�C�i��|�A�X�L�[�v�ɕύX����',   'FTP�Ă񂻂����[�ǂ����Ă�');
  AddFunc  ('FTP�_�E�����[�h',  'A��B��|A����B��',            4024, sys_ftp_download,       '�����[�g�t�@�C��A�����[�J���t�@�C��B�փ_�E�����[�h����',   'FTP�������[��');
  AddFunc  ('FTP�t�H���_�_�E�����[�h',  'A��B��|A����B��',    4037, sys_ftp_downloadDir,    '�����[�g�p�XA�����[�J���t�H���_B�ֈꊇ�_�E�����[�h����','FTP�ӂ��邾�������[��');
  AddFunc  ('FTP�t�@�C����',  'S��|S��',                    4025, sys_ftp_glob,           'FTP�z�X�g�̃t�@�C��S��񋓂���',   'FTP�ӂ�����������');
  AddFunc  ('FTP�t�H���_��',  'S��|S��',                    4026, sys_ftp_globDir,        'FTP�z�X�g�̃t�H���_S��񋓂���',   'FTP�ӂ��邾�������');
  AddFunc  ('FTP�t�H���_�쐬',  'S��|S��|S��',                4027, sys_ftp_mkdir,          'FTP�z�X�g��S�̃t�H���_�����',     'FTP�ӂ��邾��������');
  AddFunc  ('FTP�t�H���_�폜',  'S��',                        4028, sys_ftp_rmdir,          'FTP�z�X�g��S�̃t�H���_���폜����', 'FTP�ӂ��邾��������');
  AddFunc  ('FTP��ƃt�H���_�ύX',  'S��|S��',                4029, sys_ftp_changeDir,      'FTP��ƃt�H���_��S�ɕύX����',     'FTP�����傤�ӂ��邾�ւ񂱂�');
  AddFunc  ('FTP��ƃt�H���_�擾',  '',                       4030, sys_ftp_getCurDir,      'FTP��ƃt�H���_���擾���ĕԂ�',    'FTP�����傤�ӂ��邾����Ƃ�');
  AddFunc  ('FTP�t�@�C���폜',  'S��|S��',                    4031, sys_ftp_delFile,        'FTP�t�@�C��S���폜����',           'FTP�ӂ����邳������');
  AddFunc  ('FTP�t�@�C�����ύX','A��B��|A����B��',            4032, sys_ftp_rename,         'FTP�t�@�C��A��B�ɕύX����',        'FTP�ӂ�����߂��ւ񂱂�');
  AddFunc  ('FTP�R�}���h���M',  'S��|S��|S��',                4033, sys_ftp_command,        'FTP�R�}���hS�𑗐M�����̌��ʂ�Ԃ��B',           'FTP���܂�ǂ�������');
  AddFunc  ('FTP�����ύX',      'FILE��S��|S��',              4034, sys_ftp_chmod,          'FTP�t�@�C����FILE�̑�����A(���=644/CGI=755)�ɕύX', 'FTP���������ւ񂱂�');
  AddFunc  ('FTP��ƃt�H���_��ړ�',  '',                     4035, sys_ftp_upCurDir,       'FTP�Ώۃt�H���_����Ɉړ�', 'FTP�����傤�ӂ��邾�������ǂ�');
  AddFunc  ('FTP�t�@�C���ڍח�',  'S��|S��',                4036, sys_ftp_glob2,          'FTP�z�X�g�̃t�@�C��S���ڍׂɗ񋓂���',   'FTP�ӂ����邵�傤�����������');
  AddFunc  ('FTP�^�C���A�E�g�ݒ�',  'V��|V��|V��',            4039, sys_ftp_setTimeout,     '�ڑ�����FTP�̃^�C���A�E�g���Ԃ��~���b�P�ʂŐݒ肷��',   'FTP�����ނ����Ƃ����Ă�');
  //-���[��
  AddFunc  ('���[����M',        'DIR��|DIR��',  4050, sys_pop3_recv, 'POP3�Ńt�H���_DIR�փ��[������M���A��M�������[���̌�����Ԃ��B', '�߁[�邶�サ��');
  AddFunc  ('���[�����M',        '',             4051, sys_smtp_send, 'SMTP�Ń��[���𑗐M����', '�߁[�邻������');
  AddStrVar('���[���z�X�g',      '',4052,'','�߁[��ق���');
  AddStrVar('���[��ID',          '',4053,'','�߁[��ID');
  AddStrVar('���[���p�X���[�h',  '',4054,'','�߁[��ς���[��');
  AddStrVar('���[���|�[�g',      '',4055,'','�߁[��ہ[��');
  AddIntVar('���[����M���폜',   0,4056,'','�߁[�邶�サ�񂶂�������');
  AddStrVar('���[�����o�l',      '',4057,'','�߁[�邳�������ɂ�');
  AddStrVar('���[������',        '',4058,'','�߁[�邠�Ă���');
  AddStrVar('���[������',        '',4059,'','�߁[�邯��߂�');
  AddStrVar('���[���{��',        '',4060,'','�߁[��ق�Ԃ�');
  AddStrVar('���[���Y�t�t�@�C��','',4061,'','�߁[��Ă�Ղӂ�����');
  AddStrVar('���[��HTML',        '',4065,'HTML���[�������Ƃ���HTML��ݒ�','�߁[��HTML');
  AddStrVar('���[��CC',          '',4066,'','�߁[��CC');
  AddStrVar('���[��BCC',         '',4067,'','�߁[��BCC');
  AddStrVar('���[���w�b�_',      '',4068,'���M���ɒǉ��������w�b�_���n�b�V���`���ő�����Ă����B','�߁[��ւ���');
  AddStrVar('���[���I�v�V����',  '',4062,'���[����M��(APOP)�A���[�����M��(LOGIN|CRAM-MD5|PLAIN)�𕡐��w��\�B','�߁[�邨�Ղ����');
  AddFunc  ('���[�����X�g�擾',  '',4063, sys_pop3_list, 'POP3�Ń��[���̌����ƃT�C�Y�̈ꗗ���擾����', '�߁[��肷�Ƃ���Ƃ�');
  AddFunc  ('���[���폜',     'A��',4064, sys_pop3_dele, 'POP3��A�Ԗڂ̃��[�����폜����', '�߁[�邳������');
  //-EML
  AddFunc  ('EML�t�@�C���J��', 'F��',4080, sys_eml_load , 'EML�t�@�C�����J��', 'EML�ӂ�����Ђ炭');
  AddFunc  ('EML�p�[�g���擾','',4081, sys_eml_part_count, 'EML�t�@�C���ɂ����p�[�g�����邩���擾���ĕԂ��B', 'EML�ρ[�Ƃ�������Ƃ�');
  AddFunc  ('EML�p�[�g�ꗗ�擾','',4082, sys_eml_part_type, 'EML�t�@�C���̃p�[�g��ނ̈ꗗ�擾���ĕԂ��B', 'EML�ρ[�Ƃ�����񂵂�Ƃ�');
  AddFunc  ('EML�e�L�X�g�擾','A��',4083, sys_eml_getText, 'EML�t�@�C����A�Ԗڂ̃p�[�g���e�L�X�g�Ƃ��Ď擾����B', 'EML�Ă����Ƃ���Ƃ�');
  AddFunc  ('EML�Y�t�t�@�C���ۑ�','A��F��|F��',4084,sys_eml_getAttach,'EML�t�@�C����A�Ԗ�(1~n)�̃p�[�g�����o����F�֕ۑ�����B', 'EML�Ă�Ղӂ�����ق���');
  AddFunc  ('EML�S�e�L�X�g�擾','',4085,sys_eml_getAllText,'EML�t�@�C���Ɋ܂܂��e�L�X�g��S���擾���ĕԂ��B', 'EML����Ă����Ƃ���Ƃ�');
  AddFunc  ('EML�w�b�_�擾','',4086,sys_eml_getHeader,'EML�t�@�C���̃w�b�_���n�b�V���`���ɂ��ĕԂ�', 'EML�ւ�������Ƃ�');

  //-TCP/IP
  AddFunc  ('IP�A�h���X�擾','{=?}S��|S��|S����', 4073, sys_get_ip, '�h���C��S��IP�A�h���X���擾����', 'IP���ǂꂷ����Ƃ�');
  AddFunc  ('�z�X�g���擾','{=?}S��|S��|S����', 4074, sys_get_host, 'IP�A�h���XS����z�X�g�����擾����', '�ق��Ƃ߂�����Ƃ�');
  AddFunc  ('TCP_COMMAND','{�O���[�v}S,A,B', 4070, sys_tcp_command, 'lib\nakonet.nako��TCP�N���C�A���g�Ŏg��', 'TCP_COMMAND');
  AddFunc  ('TCP_SVR_COMMAND','{�O���[�v}S,A,B', 4071, sys_tcp_svr_command, 'lib\nakonet.nako��TCP�T�[�o�[�Ŏg��', 'TCP_SVR_COMMAND');
  AddFunc  ('UDP_COMMAND','{�O���[�v}S,A,B', 4075, sys_udp_command, 'lib\nakonet.nako��UDP�Ŏg��', 'UDP_COMMAND');

  //-NTP
  AddFunc  ('NTP��������','{=?}S��', 4076, sys_ntp_sync, 'NTP�T�[�o�[S�ɐڑ����Č��ݎ������C������B�����ȗ�����ƁAring�T�[�o�[�𗘗p����B���������1�A���s�����0��Ԃ�', 'NTP�������ǂ���');

  //-PING
  AddFunc  ('PING','{=?}S��|S��|S��', 4072, sys_ping, 'S��PING���ʂ邩�m�F����B�ʂ�Ȃ����0��Ԃ�', 'PING');
  //-�I�v�V����
  AddIntVar('�o�߃_�C�A���O',1, 4090, 'FTP/HTTP�Ōo�߃_�C�A���O��\�����邩�ǂ����B', '�������������낮');

  //-JSON
  AddFunc  ('JSON�G���R�[�h','{=?}V��|V��',     4130, sys_json_encode, '�lV��JSON�`���ɕϊ�����', 'JSON���񂱁[��');
  AddFunc  ('JSON�f�R�[�h','{=?}JSON��|JSON��', 4131, sys_json_decode, '������JSON��ϐ��ɕϊ�����', 'JSON�ł��[��');

  //-nakonet.dll
  AddFunc  ('NAKONET_DLL�o�[�W����','', 4132, get_nakonet_dll_version, 'nakonet.dll�̃o�[�W�����𓾂�', 'NAKONET_DLL�΁[�����');

  //+�ԕr�T�[�r�X/���A�g(nakonet.dll)
  //-�ݒ�
  AddStrVar('�ԕrPORT',      '5029',    4100, '', '���т�PORT');
  AddStrVar('�ԕr�p�X���[�h','',          4101, '', '���т�ς���[��');
  //-�ԕr�T�[�r�X�̎��s��~
  AddFunc  ('�ԕr�T�[�r�X�N��','', 4105, sys_kabin_open, '�ԕr�T�[�r�X(���A�g�p)���J�n����', '���т񂳁[�т�������');
  AddFunc  ('�ԕr�T�[�r�X�I��','', 4106, sys_kabin_close, '�ԕr�T�[�r�X(���A�g�p)���I������', '���т񂳁[�т����イ��傤');
  //</����>

  _option;
end;

{ TNetDialog }

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
          net_dialog_cancel := True;
        end;
      end;
  end;
end;

procedure TNetDialog.setInfo(s: string);
begin
  SetDlgWinText(hProgress, IDC_EDIT_INFO, s);
end;

procedure TNetDialog.setText(s: string);
begin
  SetDlgWinText(hProgress, IDC_EDIT_TEXT, s);
end;

function TNetDialog.ShowDialog(stext, sinfo: string; Visible: Boolean): Boolean;
var
  msg: TMsg;
begin
  if hParent = 0 then hParent := nako_getMainWindowHandle;
  net_dialog_complete := False;

  // �_�C�A���O�̕\��
  hProgress  := CreateDialog(
      hInstance, PChar(IDD_DIALOG_PROGRESS), hParent, @procProgress);

  // �_�C�A���O�ɏ���\��
  SetDlgWinText(hProgress, IDC_EDIT_TEXT, stext);
  SetDlgWinText(hProgress, IDC_EDIT_INFO, sinfo);
  if Visible then
    ShowWindow(hProgress, SW_SHOW)
  else
    ShowWindow(hProgress, SW_HIDE);

  // �_�E�����[�h���I������܂Ń_�C�A���O��\��
  while (net_dialog_cancel = False)and(net_dialog_complete = False) do
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
      sleep(10);
    end;
  end;

  DestroyWindow(hProgress);
  Result := net_dialog_complete;
end;

procedure TNetDialog.Work(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCount: Integer);
var
  s: string;
begin
  if hProgress = 0 then Exit;

  // download text
  s := '�ʐM�� (' + IntToStr(Trunc(AWorkCount/1024)) + '/' + IntToStr(Trunc(Self.WorkCount/1024)) + 'KB) ' + target;
  setText(s);

  // progress bar
  SendMessage(GetDlgItem(hProgress, IDC_PROGRESS1),
    PBM_SETSTEP, 1, 0);
  // range
  SendMessage(GetDlgItem(hProgress, IDC_PROGRESS1),
    PBM_SETRANGE, 0, MakeLong(0, 100));
  // set pos
  if AWorkCount > 0 then
  begin
    SendMessage(GetDlgItem(hProgress, IDC_PROGRESS1),
      PBM_SETPOS, Trunc(AWorkCount/Self.WorkCount*100) , LParam(BOOL(True)));
  end else
  begin
    SendMessage(GetDlgItem(hProgress, IDC_PROGRESS1),
      PBM_SETPOS, 100 , LParam(BOOL(True)));
  end;
end;

procedure TNetDialog.WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCountMax: Integer);
begin
  hParent := nako_getMainWindowHandle;
  Self.WorkCount := AWorkCountMax;
  // �����ݒ�
  net_dialog_cancel   := False;
  net_dialog_complete := False;
end;

procedure TNetDialog.WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
begin
  Work(Self, AWorkMode, Self.WorkCount);
end;

{ TNetThread }

procedure TNetThread.Execute;
begin
  if Terminated then Exit;
  method(Self, arg0);
end;

initialization
  //

finalization
  FreeAndNil(FNetDialog);

end.
