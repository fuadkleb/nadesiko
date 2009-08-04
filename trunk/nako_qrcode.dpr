library nako_qrcode;

uses
  Windows,
  SysUtils,
  Classes,
  Graphics,
  dnako_import in 'hi_unit\dnako_import.pas',
  dnako_import_types in 'hi_unit\dnako_import_types.pas',
  dll_plugin_helper in 'hi_unit\dll_plugin_helper.pas',
  unit_qrcode in 'pro_unit\unit_qrcode.pas',
  QRCODE in 'pro_unit\QRCODE.PAS',
  unit_string2 in 'hi_unit\unit_string2.pas',
  gldpng in 'component\gldpng\gldpng.pas',
  BARCODE in 'pro_unit\BARCODE.PAS';

// path ��ǉ����邱��

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

function jan_makeStr(h: DWORD): PHiValue; stdcall;
begin
  Result  := hi_newStr(
    Make_JAN(getArgStr(h, 0, True)));
end;
function code39_makeStr(h: DWORD): PHiValue; stdcall;
begin
  Result  := hi_newStr(
    Make_CODE39(
      getArgStr(h, 0, True),
      getArgBool(h, 1)
      )
    );
end;
function nw7_makeStr(h: DWORD): PHiValue; stdcall;
var
  code, c: string;
  c_start,c_end: Char;
  cd: Boolean;
begin
  code := getArgStr(h, 0, True);
  c := getArgStr(h, 1) + ' ';
  c_start := c[1];
  c := getArgStr(h, 2) + ' ';
  c_end := c[1];
  cd := getArgBool(h, 3);
  //
  Result  := hi_newStr(
    Make_NW7(code, c_start, c_end, cd)
  );
end;
function itf_makeStr(h: DWORD): PHiValue; stdcall;
begin
  Result  := hi_newStr(
    Make_ITF(
      getArgStr(h, 0, True),
      getArgBool(h,1)));
end;
function customercode_makeStr(h: DWORD): PHiValue; stdcall;
begin
  Result  := hi_newStr('customer:'+Make_Customer(getArgStr(h, 0, True)));
end;
function code128_makeStr(h: DWORD): PHiValue; stdcall;
var
  code, c: string;
  start_code: Char;
begin
  code := getArgStr(h, 0, True);
  c    := getArgStr(h, 1) + ' ';
  start_code := c[1];
  Result  := hi_newStr(Make_Code128(code, start_code));
end;

function save_barcode_image(h: DWORD): PHiValue; stdcall;
var
  code: string;
  fname: string;
  bairitu, i, n, len, x: Integer;
  Position, Counter, LineWidth: Integer;
  bCustomer: Boolean;
  bmp: TBitmap;
  png: TGLDPNG;
begin
  code    := getArgStr(h, 0, True);
  fname   := getArgStr(h, 1);
  bairitu := getArgInt(h, 2);
  Result  := nil;
  //
  bCustomer := False;
  if Copy(code,1,7) = 'custom:' then
  begin
    bCustomer := true;
    Delete(code, 1, 7);
  end;
  len := Length(code);
  //
  bmp := TBitmap.Create;
  try
    bmp.Width  := 30 * 2 + (bairitu+1) * len;
    bmp.Height := bairitu * 30;
    with bmp.Canvas do
    begin
      Pen.Style := psSolid;
      Pen.Color := clBlack;
      Pen.Width := 1;
      Brush.Style := bsSolid;
      Brush.Color := Pen.Color;
    end;
    with bmp do
    begin
      if not bCustomer then
      begin
        Position := 0;
        n := bairitu;
        for Counter:=1 to Length(code) do
        begin
            LineWidth := ((StrToInt(code[Counter]) div 2) + 1) * n;
            if (StrToInt(code[Counter]) mod 2) = 0 then
              // ��
              begin
              end
            else
              // �o�[
              begin
                for i:=1 to LineWidth do
                  begin
                    //DrawLine(Position);
                    Canvas.MoveTo(30+Position+i, 0);
                    Canvas.LineTo(30+Position+i, bmp.Height);
                  end;
              end;
            Inc(Position, LineWidth);
        end;
        //bmp.Width := 30 * 2 + Position + 1;
      end else
      begin
        for i := 0 to len - 1 do
        begin
          if code[i+1] = '1' then
          begin
            x := i * bairitu;
            Canvas.Rectangle(x,0, x+bairitu, bmp.Height);
          end;
        end;
        bmp.Width := len * bairitu + 1;
      end;
    end;
    //
    png := TGLDPNG.Create;
    try
      png.Assign(bmp);
      png.SaveToFile(fname);
    finally
      FreeAndNil(png);
    end;
  finally
    FreeAndNil(bmp);
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
  AddFunc('QR�R�[�h������擾', 'CODE��|CODE��', 6563, qr_makeStr, 'CODE��0��1�̕�����Ŏ擾����', 'QR���[�ǂ��������Ƃ�');
  //-�e��o�[�R�[�h
  AddFunc('�o�[�R�[�h�摜�ۑ�', '{=?}CODESTR��FILE��BAIRITU��|FILE��', 6570, save_barcode_image, '�e��A���S���Y���ɂ�萶�������o�[�R�[�h��������摜�Ƃ���FILE�֕ۑ�����', '�΁[���[�ǂ������ق���');
  AddFunc('JAN�R�[�h������擾', 'CODE��|CODE��', 6576, jan_makeStr, 'CODE��0��1�̕�����Ŏ擾����', 'JAN���[�ǂ��������Ƃ�');
  AddFunc('CODE39������擾', '{=?}CODE��CD��', 6571, code39_makeStr, 'CODE��CD(�`�F�b�N�f�B�W�b�g=�I��|�I�t)��0��1�̕�����Ŏ擾����', 'CODE39���������Ƃ�');
  AddFunc('NW7�o�[�R�[�h������擾', '{=?}CODE��CH1,CH2��CD��', 6572, nw7_makeStr, 'CODE��0��1�̕�����Ŏ擾����', 'NW7�΁[���[�ǂ��������Ƃ�');
  AddFunc('ITF�o�[�R�[�h������擾', '{=?}CODE��CD��', 6573, itf_makeStr, 'CODE��CD(�`�F�b�N�f�B�W�b�g=�I��|�I�t)��0��1�̕�����Ŏ擾����', 'ITF�΁[���[�ǂ��������Ƃ�');
  AddFunc('�J�X�^�}�[�o�[�R�[�h������擾', 'CODE��|CODE��', 6574, customercode_makeStr, 'CODE��0��1�̕�����Ŏ擾����', '�������܁[�΁[���[�ǂ��������Ƃ�');
  AddFunc('CODE128������擾', 'CODE��ST��', 6575, code128_makeStr, 'CODE��ST(�J�n����)�Ńo�[�R�[�h��0��1�̕�����Ŏ擾����', 'CODE128�R�[�h���������Ƃ�');
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
