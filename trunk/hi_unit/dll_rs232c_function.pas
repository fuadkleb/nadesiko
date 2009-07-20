unit dll_rs232c_function;

interface
uses
  classes, windows, rs232c, comthd,
  dll_plugin_helper, dnako_import, dnako_import_types, SysUtils;

type
  Trs232cN = class(Trs232c)
  public
    rxdata_cnt: Integer;       // �ǉ�
    rxdata_packet: String;     // �ǉ�
  public
    group: PHiValue;
    procedure FFOnBREAK(Sender: TObject);
    procedure FFOnCTS(Sender: TObject);
    procedure FFOnDSR(Sender: TObject);
    procedure FFOnERR(Sender: TObject);
    procedure FFOnRING(Sender: TObject);
    procedure FFOnRLSD(Sender: TObject);
    procedure FFOnRXCHAR(Sender: TObject);
    procedure FFOnRXFLAG(Sender: TObject);
    procedure FFOnTXEMPTY(Sender: TObject);
    procedure FFOnCreate(Sender: TObject);
    procedure FFOnOpen(Sender: TObject);
    procedure FFOnClose(Sender: TObject);
    procedure FFOnPACKET(Sender: TObject);
    procedure FFOnError(Sender: TObject);
    procedure OnEvent(ename: string);
    constructor Create(AOwner: TComponent); override;
  end;

procedure RegistFunction;

implementation


function rs232c_cmd(arg: DWORD): PHiValue; stdcall;
var
  g, p: PHiValue;
  cmd, v: string;
  Frs232c: Trs232cN;
begin
  Result := nil;
  // �����̎擾
  g   := nako_getFuncArg(arg, 0);
  cmd := hi_str( nako_getFuncArg(arg, 1) );
  v   := hi_str( nako_getFuncArg(arg, 2) );

  // �R�}���h�̉��
  if cmd = 'create' then
  begin
    p := nako_group_findMember(g, '�I�u�W�F�N�g');
    if p = nil then raise Exception.Create('�I�u�W�F�N�g������ł��܂���B');
    //
    Frs232c := Trs232cN.Create(nil);
    Frs232c.group := g;
    hi_setInt(p, Integer(Frs232c));
    //
    Exit;
  end;

  p := nako_group_findMember(g, '�I�u�W�F�N�g');
  if p = nil then raise Exception.Create('�I�u�W�F�N�g������ł��܂���B');
  Frs232c := Trs232cN(hi_int(p));

  if cmd = 'open' then
  begin
    // �ݒ�
    Frs232c.bps         := hi_int(nako_group_findMember(g, 'BPS'));
    Frs232c.charbit     := hi_int(nako_group_findMember(g, 'CHARBIT'));
    Frs232c.stopbit     := hi_str(nako_group_findMember(g, 'STOPBIT'));
    Frs232c.paritymode  := hi_str(nako_group_findMember(g, 'PARITYMODE'));
    Frs232c.rxtimeout   := hi_int(nako_group_findMember(g, '�^�C���A�E�g'));
    Frs232c.txtimeout   := hi_int(nako_group_findMember(g, '�^�C���A�E�g'));
    Frs232c.portname    := hi_str(nako_group_findMember(g, '�|�[�g'));
    Frs232c.packetsize  := hi_int(nako_group_findMember(g, '�p�P�b�g�T�C�Y'));
    Frs232c.XonLim      := hi_int(nako_group_findMember(g, 'XonLim'));
    Frs232c.XoffLim     := hi_int(nako_group_findMember(g, 'Xoff'));
    Frs232c.XonChar     := Char(hi_int(nako_group_findMember(g,'XonChar')));
    Frs232c.XoffChar    := Char(hi_int(nako_group_findMember(g,'XoffChar')));
    Frs232c.ErrorChar   := Char(hi_int(nako_group_findMember(g,'ErrorChar')));
    Frs232c.EvtChar     := Char(hi_int(nako_group_findMember(g,'EvtChar')));
    Frs232c.EofChar     := Char(hi_int(nako_group_findMember(g,'EofChar')));

    if not Frs232c.rsopen then raise Exception.Create('RS232C�̃|�[�g���J���܂���B');
  end else
  if cmd = 'close' then
  begin
    Frs232c.rsclose;
  end else
  if cmd = 'send' then
  begin
    if v <> '' then
    begin
      Frs232c.rswrite(v[1], Length(v));
    end;
  end else
  ;
end;

procedure RegistFunction;
begin
  //4400-4499
  AddFunc('RS232C_COMMAND','{�O���[�v}G,CMD,V',  4400, rs232c_cmd, 'RS232C�̐ݒ���s��', 'RS232C_COMMAND');
end;


{ Trs232cN }

constructor Trs232cN.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  rxdata_cnt := 0;         // �ǉ�
  rxdata_packet := '';     // �ǉ�


  // ���ׂ�Ƃ��Ƃ����
  OnBREAK := FFOnBREAK;
  OnCTS := FFOnCTS;
  OnDSR := FFOnDSR;
  OnERR := FFOnERR;
  OnRING := FFOnRING;
  OnRLSD := FFOnRLSD;
  OnRXCHAR := FFOnRXCHAR;
  OnRXFLAG := FFOnRXFLAG;
  OnTXEMPTY := FFOnTXEMPTY;
  OnCreate := FFOnCreate;
  OnOpen := FFOnOpen;
  OnClose := FFOnClose;
  OnPACKET := FFOnPACKET;
  OnError := FFOnError;
end;

procedure Trs232cN.FFOnBREAK(Sender: TObject);
begin
  OnEvent('BREAK���o������');
end;

procedure Trs232cN.FFOnClose(Sender: TObject);
begin
  OnEvent('������');
end;

procedure Trs232cN.FFOnCreate(Sender: TObject);
begin
  OnEvent('����������');
end;

procedure Trs232cN.FFOnCTS(Sender: TObject);
begin
  OnEvent('CTS�ω�������');
end;

procedure Trs232cN.FFOnDSR(Sender: TObject);
begin
  OnEvent('DSR�ω�������');
end;

procedure Trs232cN.FFOnERR(Sender: TObject);
begin
  OnEvent('�G���[����������');
end;

procedure Trs232cN.FFOnError(Sender: TObject);
begin
  OnEvent('�G���[����������');
end;

procedure Trs232cN.FFOnOpen(Sender: TObject);
begin
  OnEvent('�J������');
end;

procedure Trs232cN.FFOnRING(Sender: TObject);
begin
  OnEvent('RING���o������');
end;

procedure Trs232cN.FFOnRLSD(Sender: TObject);
begin
  OnEvent('RLSD�ω�������');
end;

procedure Trs232cN.FFOnPACKET(Sender: TObject);
var
  s: string;
  p: PHiValue;
  c: Char;
  max_data_len: integer;
begin

  // ���L��while���̂ɏ��������Ȃ���
  // ��M�f�[�^����肱�ڂ����肵��
  while 0 < rxdatalen do
  begin
    self.rsread(c, 1);
    rxdata_packet := rxdata_packet + c;

    max_data_len := Length(rxdata_packet);

    // �w�肵���p�P�b�g�T�C�Y����M������A
    // �p�P�b�g�T�C�Y���؂����āA�C�x���g����������
    if (max_data_len >= packetsize) then begin
      s := Copy(rxdata_packet,1,packetsize);

      p := nako_group_findMember(group, '��M�f�[�^');
      if p = nil then Exit;

      hi_setStr(p, s);

      OnEvent('�p�P�b�g��M������');

      rxdata_packet := '';
      rxdata_packet := Copy(rxdata_packet,packetsize+1,max_data_len-packetsize);
    end;
  end;
end;


procedure Trs232cN.FFOnRXCHAR(Sender: TObject);
var
  s: string;
  p: PHiValue;
  c: Char;
begin

  s := '';
  while 0 < rxdatalen do
  begin
    self.rsread(c, 1);
    s := s + c;
  end;

  // ��M�f�[�^�������Ƃ��́A�C�x���g�𔭐������Ȃ�
  // ��M�f�[�^������ΌĂ΂��Ǝv���̂ł����E�E�E
  // ������A����Ă����Ȃ��ƃC�x���g�͔������邯��
  // ��M�f�[�^������ۂɂȂ�܂��B
  if s = '' then
    Exit;

  p := nako_group_findMember(group, '��M�f�[�^');
  if p = nil then Exit;

  hi_setStr(p, s);

  OnEvent('��M������');
end;

procedure Trs232cN.FFOnTXEMPTY(Sender: TObject);
begin
  OnEvent('���M����������');
end;

procedure Trs232cN.OnEvent(ename: string);
var
  p: PHiValue;
begin
  p := nako_group_findMember(group, PChar(ename));
  if p = nil then Exit;
  //if p^.VType = varFunc then
  if (p<>nil)and(p.ptr <> nil) then
  begin
    nako_continue;
    nako_group_exec(group, PChar(ename));
  end;
end;

procedure Trs232cN.FFOnRXFLAG(Sender: TObject);
var
  s: string;
  p: PHiValue;
begin
  if rxdatalen > 0 then
  begin
    SetLength(s, rxdatalen);
    self.rsread(s[1], Length(s));

    p := nako_group_findMember(group, '��M�f�[�^');
    if p = nil then Exit;
    hi_setStr(p, s);
    OnEvent('�C�x���g������M������');
  end;
end;

end.
