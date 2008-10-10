library nako_qrcode;

uses
  Windows,
  SysUtils,
  Classes,
  dnako_import in 'hi_unit\dnako_import.pas',
  dnako_import_types in 'hi_unit\dnako_import_types.pas',
  dll_plugin_helper in 'hi_unit\dll_plugin_helper.pas',
  unit_qrcode in 'pro_unit\unit_qrcode.pas',
  QRCode in 'pro_unit\QRCODE.PAS',
  unit_string2 in 'hi_unit\unit_string2.pas';

//------------------------------------------------------------------------------
// �ȉ��֐�
//------------------------------------------------------------------------------

function qr_make(h: DWORD): PHiValue; stdcall;
var
  code,
  fname: string;
  bairitu: Integer;
begin
  Result  := nil;
  code    := getArgStr(h, 0, True );
  fname   := getArgStr(h, 1, False);
  bairitu := getArgInt(h, 2, False);
  qr_makeCode(PChar(code), PChar(fname), bairitu);
end;
function qr_setOption(h: DWORD): PHiValue; stdcall;
begin
  Result := nil;
  qr_option := getArgStr(h, 0);
end;
function qr_setVersion(h: DWORD): PHiValue; stdcall;
begin
  Result := nil;
  qr_version := getArgInt(h, 0);
end;
function qr_makeStr(h: DWORD): PHiValue; stdcall;
var
  code,
  ret: string;
  qr: TQRCode;
begin
  Result  := nil;
  code    := getArgStr(h, 0, True );
  qr := TQRCode.Create(nil);
  try
    qr_setOpt(qr, code);
    ret := qr.PBM.Text;
    ret := JReplace_(ret, ' ','');
    getToken_s(ret, #13#10);
    getToken_s(ret, #13#10);
    Result := hi_newStr(ret);
  finally
    FreeAndNil(qr);
  end;
end;

//------------------------------------------------------------------------------
// �ȉ���΂ɕK�v�Ȋ֐�
//------------------------------------------------------------------------------
// �֐��ǉ��p
procedure ImportNakoFunction; stdcall;
begin
  // �Ȃł����V�X�e���Ɋ֐���ǉ�
  // nako_qrcode.dll,6560-6569
  // <����>
  //+�o�[�R�[�h[�f���b�N�X�ł̂�](nako_qrcode.dll)
  //-QR�R�[�h
  AddFunc('QR�R�[�h�쐬', 'CODE��FILE��BAIRITU��', 6560, qr_make, 'CODE��FILE�֔{��BAIRITU�̑傫���ō쐬����B', 'QR�R�[�h��������');
  AddFunc('QR�R�[�h�I�v�V�����ݒ�', 'S��', 6561, qr_setOption,  '', 'QR���[�ǂ��Ղ���񂹂��Ă�');
  AddFunc('QR�R�[�h�o�[�W�����ݒ�', 'V��', 6562, qr_setVersion, '', 'QR���[�ǂ΁[����񂹂��Ă�');
  AddFunc('QR�R�[�h������擾', 'CODE��|CODE��', 6563, qr_makeStr, 'CODE��0��1�̕�����ł���Ƃ�����', 'QR�R�[�h���������Ƃ�');
  // </����>
end;

//------------------------------------------------------------------------------
// �v���O�C���̏��
function PluginInfo(str: PChar; len: Integer): Integer; stdcall;
const STR_INFO = 'QR�R�[�h�v���O�C�� by �N�W����s��';
begin
  Result := Length(STR_INFO);
  if (str <> nil)and(len > 0) then
  begin
    StrLCopy(str, STR_INFO, len);
  end;
end;

//------------------------------------------------------------------------------
// �v���O�C���̃o�[�W����
function PluginVersion: DWORD; stdcall;
begin
  Result := 2; // �v���O�C�����̂̃o�[�W����
end;

//------------------------------------------------------------------------------
// �Ȃł����v���O�C���o�[�W����
function PluginRequire: DWORD; stdcall;
begin
  Result := 2; // �K��2��Ԃ�����
end;

procedure PluginInit(Handle: DWORD); stdcall;
begin
  dnako_import_initFunctions(Handle);
end;
function PluginFin: DWORD; stdcall;
begin
  Result := 0;
end;



exports
  ImportNakoFunction,
  PluginInfo,
  PluginVersion,
  PluginRequire,
  PluginInit;


begin
end.
