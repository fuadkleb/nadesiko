unit hima_token;
//------------------------------------------------------------------------------
// �g�[�N���A�n�b�V�����Ǘ�����
//------------------------------------------------------------------------------
interface

uses
  Windows, SysUtils, hima_string, hima_types, hima_error, unit_string;

const
  IndentChars:    TChars   = [' ',#9];
  AlphabetChars1: TChars   = ['A'..'Z','a'..'z','_'];
  AlphabetChars2: TChars   = ['A'..'Z','a'..'z','_','0'..'9'];
  NumberChars1:   TChars   = ['-','0'..'9','$'];
  EnzansiChar1:   TChars   = ['+','-','*','/','%','^','>','<','=','!','&','|'];
  EnzansiChar2:   TChars   = ['=','>','<','&','|'];
  HimaMark:       TChars   = ['@','~','.',':','?',',','\'];

  // �������̑������ɕ��ׂ邱��
  HimaJosuusi: Array [0..17] of string = (
    //<�P��>
    '���[�g��','�h�b�g','��','��','��','��','�~','��','�{','��','�l','px','pt','cm','mm','m','kg','g'
    //</�P��>
  );


type
  THimaBlock = class;
  THimaFile  = class;
  THimaFiles = class;

  TTokenType = (
    tokenTango,
    tokenOperator,
    tokenNumber,
    tokenParenthesis,
    tokenString,
    tokenMark
  );

  THimaToken = class(TObject)
  public
    TokenID : DWORD;
    JosiID  : Integer;
    Token, Josi: string;
    NumberToken: Extended;
    Parent: THimaBlock;
    TokenType: TTokenType;
    NextToken: THimaToken; // ���̃g�[�N��
    constructor Create(Parent: THimaBlock);
    function CheckNextBlock: THimaToken;
    function GetConstStr: string;
    function GetConstPtr: Pointer;
    function UCToken: string; // �啶���ϊ����ăg�[�N���𓾂�
    function LineNo: Integer; // �e�𒲂ׂċ��߂�
    function Indent: Integer;
    function FileNo: Integer;
    function DebugInfo: TDebugInfo;
    function GetAsText: string;
  end;

  THimaBlock = class(THObjectList)
  private
    function GetToken(Index: Integer): THimaToken;
    procedure SetToken(Index: Integer; const Value: THimaToken);
  public
    Parent: THimaFile;
    Indent: Integer; // �C���f���g�̃��x��
    LineNo: Integer;
    NextBlock: THimaBlock;
    TopToken, CurToken: THimaToken;
    constructor Create(Parent: THimaFile);
    destructor Destroy; override;
    property Tokens[Index: Integer]: THimaToken read GetToken write SetToken;
    function GetAsText(kugiri: string): string;
    procedure Add(item: THimaToken);
  end;

  THimaFile = class(THObjectList)
  private
    procedure Analize(src: string); //<--- �g�[�N������؂�֐� ---------------- ***
  public
    Parent    : THimaFiles;
    Path, Filename : string;
    Fileno    : Integer;
    TopBlock,
    CurBlock  : THimaBlock;
    constructor Create(Parent: THimaFiles; Fileno: Integer);
    function GetAsText: string;
    function TopToken: THimaToken;
    procedure Add(item: THimaBlock);
    //
    procedure LoadFromFile(Filename: string);
    procedure SetSource(src: string);
  end;

  THimaFiles = class(THObjectList)
  public
    function FindFile(Filename: string): THimaFile;
    function LoadAndAdd(Filename: string): THimaFile;
    function LoadSourceAdd(SourceText: string; Filename: string): THimaFile;
    function FindFileNo(no: Integer): THimaFile;
  end;

  THimaTango = class(THHashItem)
  public
    ID: Integer;
  end;

  THimaTangoList = class(THHash)
  private
    FLastID: Integer;
    FFindID: Integer; //**�����p
    FFindKey: string; //**�����p
    function subEnumKeys(item: THHashItem): Boolean;
    function subFindKey(item: THHashItem): Boolean;
    function GetTango(key: string): THimaTango;
    procedure SetTango(key: string; const Value: THimaTango);
  public
    constructor Create;
    function GetID(key: string; DefaultID: Integer = -1): Integer;
    procedure SetID(key: string; Value: Integer);
    function FindKey(id: Integer): string;
    function EnumKeys: string;
    property Tangos[key: string]: THimaTango read GetTango write SetTango;
  end;

  THimaJosiList = class(THObjectList)
  private
    FLastID: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function GetID(key: string): Integer;
    procedure SetID(key: string; Value: Integer);
    function AddID(key: string): Integer;
    function Find(var p: PChar): string;
    function ID2Str(id: WORD): string;
    procedure SortByLen;
    function EnumKeys: string;
  end;

  THiKuraidori = class
  public
    kurai: string;
    bai: Extended;
    function Comp(var p: PChar): Boolean;
    constructor Create(akurai: string; abai: Extended);
  end;

  THiKuraidoriList = class(THObjectList)
  public
    function FindKurai(var p: PChar; var num: Extended): Boolean;
  end;



// �g�[�N����؂�o��
function HimaGetWord(var p: PChar; var tokenJosi: string): string;
// �����̐؂�o��
function HimaGetNumber(var p: PChar; var tokenJosuusi: string): Extended;
// ������̐؂�o��
function HimaGetString(var p: PChar; var lineNo: Integer): string;
// �����Ɉ�v����ꂪ����Δ����o��
function HimaGetJosi(var p: PChar): string;

// �����o�^�P��̍쐬
procedure setTokenList(sys: TObject);
// �����ꗗ�̍쐬
procedure setJosiList(sys: TObject);

// �t�@�C���̌���
function HiFindFile(var fname: string): Boolean;


const
//------------------------------------------------------------------------------
// �\���̓o�^
//------------------------------------------------------------------------------
  // �L���� 99xxx
  token_kakko_begin      = 99100;
  token_kakko_end        = 99101;
  token_kaku_kakko_begin = 99102;
  token_kaku_kakko_end   = 99103;
  token_nami_kakko_begin = 99104;
  token_nami_kakko_end   = 99105;

  token_plus      = 99110;
  token_minus     = 99111;
  token_mul       = 99112; token_mark_function = 99112;
  token_div       = 99113;
  token_mod       = 99114;
  token_Eq        = 99115;
  token_NotEq     = 99116;
  token_Gt        = 99117;
  token_GtEq      = 99118;
  token_Lt        = 99119;
  token_LtEq      = 99120;
  token_ShiftL    = 99121;
  token_ShiftR    = 99122;
  token_tilde     = 99123;
  token_power     = 99124;
  token_plus_str  = 99125;
  token_or        = 99126;
  token_and       = 99127;
  token_katu      = 99128;
  token_matawa    = 99129;
  token_vLine     = 99130;
  token_Colon     = 99131;
  token_Semicolon = 99132;
  token_comma     = 99133;
  token_yen       = 99134;

  token_mark_option = 99150;
  token_mark_at     = 99151;
  token_mark_sikaku = 99152;
  token_mark_nakaten= 99153;

  // �P��� 99xxx
  token_mosi      = 99200;
  token_naraba    = 99201;
  token_tagaeba   = 99202;
  token_aida      = 99203;
  token_hanpuku   = 99204;
  token_kai       = 99205;
  token_kurikaesu = 99206;
  token_err_kansi = 99207;
  token_err       = 99208;
  token_loop      = 99209;
  token_joukenbunki = 99210;
  token_koko      = 99211;

  token_mojiretu = 99250;
  token_suuti    = 99251;
  token_seisu    = 99252;
  token_hensuu   = 99253;
  token_hairetu  = 99254;
  token_hash     = 99255;
  token_hensuu_sengen = 99256;
  token_hituyou       = 99257;
  token_huyou         = 99258;
  token_private  = 99259;
  token_event    = 99260;
  token_jissuu   = 99261;
  token_group    = 99262;
  token_ByVal    = 99263; // �l�n��
  token_ByRef    = 99264; // �Q�Ɠn��
  token_system   = 99265; // �V�X�e��
  token_user     = 99266; // ���[�U�[
  token_hensuu_syokika = 99267; // �ϐ�������

  token_tukuru  = 99271;
  token_name    = 99272;
  token_include = 99273;
  token_default = 99274;
  token_kaisu   = 99275;
  token_errMsg  = 99276;
  token_taisyou = 99277; // �Ώ�
  token_namespace_henkou = 99278; // �l�[���X�y�[�X�ύX
  token_kowasu = 99279;

  token_sore  = 99300;
  token_s     = 99301;
  token_v     = 99302;
  token_cnt   = 99303;
  token_a     = 99304;
  token_b     = 99305;
  token_c     = 99306;
  token_f     = 99307;
  token_x     = 99308;
  token_y     = 99309;
  token_sono  = 99310;
  token_jisin = 99311;
  token_kore  = 99312;

  token_left  = 99350;
  token_right = 99351;

  token_dainyu = 99352;
  token_question = 99353;


//------------------------------------------------------------------------------
// �����̓o�^
//------------------------------------------------------------------------------
  josi_wa         = 50;
  josi_nituite    = 51;
  josi_naraba     = 52;
  josi_denakereba = 53;
  josi_wo         = 54;
  josi_ga         = 55;
  josi_no         = 56;
  josi_kara       = 57;
  josi_made       = 58;
  josi_madewo     = 59;
  josi_de         = 60;
  josi_towa       = 61;
  josi_ni         = 62;
  josi_he         = 63;
  josi_te         = 64;

implementation

uses unit_file_dnako, hima_system, unit_pack_files, mini_file_utils;

var
  KuraidoriList: THiKuraidoriList;


function HiFindFile(var fname: string): Boolean;
var
  rawpath, path: string;
  name: string;

  function check(testpath: string): Boolean;
  begin
    Result := False;
    if FileExists(testpath + name) then
    begin
      Result := True;
      fname := testpath + name;
    end;
  end;

begin
  Result := True;

  rawpath := ExtractFilePath(fname);
  name := ExtractFileName(fname);

  // ��Ύw�肩�H
  if (Pos(':\', rawpath) > 0)or(Pos('\\', rawpath) > 0) then
  begin
    Result := FileExists(fname); Exit;
  end;

  // ��̂����Ύw��̂͂�
  //-------------------------------------
  // include�̊�{�p�X
  path := CheckPathYen( GetAbsolutePath(rawpath, HiSystem.FIncludeBasePath, '\') );
  if check(path) then Exit;
  // include�̊�{�p�X\lib
  path := path + 'lib\';
  if check(path) then Exit;
  // runtime�p�X
  path := CheckPathYen( GetAbsolutePath(rawpath, ExtractFilePath(ParamStr(0)), '\') );
  if check(path) then Exit;
  // runtime�p�X\lib
  path := path + 'lib\';
  if check(path) then Exit;
  // bokan�p�X
  path := CheckPathYen( GetAbsolutePath(rawpath, HiSystem.BokanPath, '\') );
  if check(path) then Exit;
  // bokan\lib
  path := path + 'lib\';
  if check(path) then Exit;
  // other
  path := FindDLLFile(fname);
  if FileExists(path) then
  begin
    Result := True;
    Exit;
  end;

  Result := False;
end;

// �g�[�N����؂�o��
function HimaGetWord(var p: PChar; var tokenJosi: string): string;

  procedure HimaGetToJosi; // �i�����܂�
  begin
    while p^ <> #0 do
    begin
      if p^ in LeadBytes then
      // �Q�o�C�g�����̏���
      begin
        if CharInRange(p, '��', '��') then
        begin // �����̉\��
          if Length(Result) >= 1 then // �P�����ڂ��珕���Ȃ�Ă��Ƃ͂��肦�Ȃ�
          begin
            tokenJosi := HiSystem.JosiList.Find(p);
            if tokenJosi <> '' then Break;
          end;
          // �����ł͂Ȃ�����
          Result := Result + getOneChar(p);
          Continue;
        end;
        if CharInRange(p, '�@','') or (StrLComp(p,'�[',2)=0) then
        begin
          Result := Result + getOneChar(p);
          Continue;
        end else
          Break;
      end else
      // �P�o�C�g�����̏���
      begin
        if not(p^ in AlphabetChars2) then Exit;
        while p^ in AlphabetChars2 do
        begin
          Result := Result + p^;
          Inc(p);
        end;
      end;
    end;
  end;

  procedure HimaGetAlphabet;
  begin
    Result := p^; Inc(p);
    HimaGetToJosi;
  end;

begin
  // �A���t�@�x�b�g ('A'..'Z'|'a'..'z'|'_')+ ('A'..'Z'|'a'..'z'|'0'..'9'|'_')*
  // �����J�^�J�i   ('�@'..|'�[')+ [$8340 .. $FCFC]
  // �Ђ炪��       ('��'..'��','�[')+ [$82A0 .. $82F1]

  Result := ''; tokenJosi := '';

  //============================================================================
  // ���ʂȗ\���傩��n�܂��Ă���΂����ŕK��������؂�
  if StrLComp(p,'�܂���',6)=0 then
  begin
    Result := '�܂���'; Inc(p,6);
    tokenJosi := '';
    Exit;
  end else
  if StrLComp(p,'����',4)=0 then
  begin
    Result := '����'; Inc(p,4);
    tokenJosi := '';
    Exit;
  end else
  if StrLComp(p,'�Ⴆ�΂���',10)=0 then
  begin
    Result := '��'; Inc(p,6);
    tokenJosi := '';
    Exit;
  end else
  if StrLComp(p,'����',4)=0 then
  begin
    Result := '����'; Inc(p,4);
    tokenJosi := '';
    Exit;
  end else
  if StrLComp(p,'�܂�',4)=0 then
  begin
    Result := '�܂�'; Inc(p,4);
    tokenJosi := '';
    Exit;
  end else
  if StrLComp(p,'�ɂ���',8)=0 then
  begin
    Result := '�ɂ���'; Inc(p,8);
    tokenJosi := '';
    Exit;
  end else
  if StrLComp(p,'�Ȃł���',8)=0 then
  begin
    Result := '�Ȃł���'; Inc(p,8);
    tokenJosi := '';
    Exit;
  end else
  if StrLComp(p,'�Ђ炪��',8)=0 then
  begin
    Result := '�Ђ炪��'; Inc(p,8);
    tokenJosi := '';
    Exit;
  end else
  ;
  //============================================================================
  // �A���t�@�x�b�g���H
  if (p^ in AlphabetChars1) then
  begin
    HimaGetAlphabet;
    Exit;
  end;
  // �����J�^�J�i�Ђ炪�Ȃ���n�܂��͏����܂Ő؂���
  if CharInRange(p, '��', '') then
  begin
    HimaGetToJosi;
    Exit;
  end else
  // ����ȊO�͋L���Ƃ݂Ȃ�
  Exit;
end;

// �����̐؂�o��
function HimaGetNumber(var p: PChar; var tokenJosuusi: string): Extended;
var
  res: string;

  procedure get16sin;
  begin
    res := res + p^; Inc(p);
    while p^ in ['0'..'9','A'..'F','a'..'f'] do
    begin
      res := res + p^;
      Inc(p);
    end;
    Result := StrToIntDef(res,0);
  end;

  procedure get10sin;
  begin
    // �ʏ�̌`��
    // 123.456
    // �w���`��
    // 7.89E+08 7.89e-2

    // ��������
    while p^ in ['0'..'9'] do begin
      res := res + p^; Inc(p);
    end;
    // �����_
    if (p^ <> '.') then
    begin
      if (p^ in ['e','E']) and ((p+1)^ in ['+','-']) and ((p+2)^ in ['0'..'9']) then
      begin
        res := res + p^ + (p+1)^ + (p+2)^;
        Inc(p,3);
        while p^ in ['0'..'9'] do
        begin
          res := res + p^;
          Inc(p);
        end;
        Result := StrToFloat(res);
      end else
      begin
        Result := StrToFloat(res);
      end;
      Exit;
    end;
    res := res + p^; Inc(p);
    // �����_�ȉ�
    while p^ in ['0'..'9'] do begin
      res := res + p^; Inc(p);
    end;
    // �w���`��
    if (p^ in ['e','E']) and ((p+1)^ in ['+','-']) and ((p+2)^ in ['0'..'9']) then
    begin
      res := res + p^ + (p+1)^ + (p+2)^;
      Inc(p,3);
      while p^ in ['0'..'9'] do
      begin
        res := res + p^;
        Inc(p);
      end;
    end;

    Result := StrToFloat(res);
  end;

  procedure getJosuusi;
  var
    i: Integer;
    s: string;
  begin
    //---------------------
    if (p^ in LeadBytes) or (p^ in ['A'..'Z','a'..'z']) then
    begin
      for i := Low(HimaJosuusi) to High(HimaJosuusi) do
      begin
        s := HimaJosuusi[i];
        if StrLComp(p, PChar(s), Length(s)) = 0 then
        begin
          tokenJosuusi := s;
          //Result := Result + s;
          Inc(p, Length(s));
          Break;
        end;
      end;
    end;
    //---------------------
  end;

begin
  res := ''; tokenJosuusi := ''; Result := 0;

  // �}�C�i�X�\�L�H
  if (p^='-')and((p+1)^ in ['0'..'9','$']) then
  begin
    res := p^; Inc(p);
  end;

  // 16�i�@���H
  if p^ = '$' then get16sin else

  // 10�i�@���H
  if p^ in ['0'..'9'] then get10sin else Exit; // ���l�ȊO

  // �P�ʁi�ʎ��j
  KuraidoriList.FindKurai(p, Result);

  // ������
  getJosuusi;

end;

// ������̐؂�o��
function HimaGetString(var p: PChar; var lineNo: Integer): string;
var
  c: string;
begin
  Result := '';
  if p^ = '"' then
  begin
    Result := Result + p^;
    Inc(p); // skip '"'
    while not (p^ in [#0,'"']) do begin
      Result := Result + getOneChar(p);
    end;
    if p^ = '"' then begin Result := Result + p^; Inc(p); Exit; end;
  end else
  if p^ = '`' then
  begin
    Result := Result + p^;
    Inc(p); // skip '"'
    while not (p^ in [#0,'`']) do begin
      Result := Result + getOneChar(p);
    end;
    if p^ = '`' then begin Result := Result + p^; Inc(p); Exit; end;
  end else
  if (p^ + (p+1)^) = '�u' then
  begin
    while p^ <> #0 do
    begin
      c := getOneChar(p);
      if (c = #13)or(c = #10) then
      begin
        if p^ = #10 then Inc(p);
        Result := Result + #13#10;
        Inc(lineNo);
        Continue;
      end else
      if c = '�v' then
      begin
        Result := Result + c;
        Exit;
      end;
      Result := Result + c;
    end;
  end else
  if (p^ + (p+1)^) = '�w' then
  begin
    while p^ <> #0 do
    begin
      c := getOneChar(p);
      if (c = #13)or(c = #10) then
      begin
        Result := Result + #13#10;
        if p^ = #10 then Inc(p);
        Inc(lineNo);
        Continue;
      end else
      if c = '�x' then begin
        Result := Result + c;
        Exit;
      end;
      Result := Result + c;
    end;
  end;
end;


function HimaGetJosi(var p: PChar): string;
begin
  Result := '';
  if p^ = #0 then Exit;
  Result := HiSystem.JosiList.Find(p);
end;


{ THimaBlock }

procedure THimaBlock.Add(item: THimaToken);
begin
  inherited Add(item);

  if TopToken = nil then
  begin
    TopToken := item;
    CurToken := item;
  end else
  begin
    CurToken.NextToken := item;
    CurToken := item;
  end;
  CurToken.NextToken := nil;
end;

constructor THimaBlock.Create(Parent: THimaFile);
begin
  self.Parent := Parent;
  TopToken    := nil;
  NextBlock   := nil;
  CurToken    := nil;
end;


destructor THimaBlock.Destroy;
begin

  inherited;
end;

function THimaBlock.GetAsText(kugiri: string): string;
var
  i: Integer;
  token: THimaToken;
begin
  Result := '';
  for i := 0 to FCount - 1 do
  begin
    token := Tokens[i];
    Result := Result + token.GetAsText + token.Josi;
    if i <> (FCount-1) then Result := Result + kugiri;
  end;
end;


function THimaBlock.GetToken(Index: Integer): THimaToken;
begin
  Result := Items[Index];
end;


procedure THimaBlock.SetToken(Index: Integer; const Value: THimaToken);
begin
  Objects[Index] := Value;
end;

{ THimaFile }

procedure THimaFile.Add(item: THimaBlock);
begin
  inherited Add(item);
  
  if TopBlock = nil then
  begin
    TopBlock := item;
    CurBlock := item;
  end else
  begin
    CurBlock.NextBlock := item;
    CurBlock := item;
  end;
  CurBlock.NextBlock := nil;
end;

procedure THimaFile.Analize(src: string);
var
  lineNo: Integer;
  indent: Integer;
  p: PChar;
  block: THimaBlock;
  token: THimaToken;
  s, tokenJosi: string;

  function countIndent: Integer;
  var tab: Integer;
  begin
    // �C���f���g�̐������o
    Result := 0;
    // �^�u��4�����ŃJ�E���g
    while p^ <> #0 do
    begin
      if p^ = ' ' then
      begin
        Inc(Result);
        Inc(p);
      end else
      if p^ = #9  then
      begin
        tab := 4-(Result mod 4);
        if tab = 0 then tab := 4;
        Inc(Result, tab);
        Inc(p);
        //|1...2...|
        //|___>    |
      end else
      begin
        Break;
      end;
    end;
  end;

  function newBlock(indent: Integer): THimaBlock;
  begin
    Result := THimaBlock.Create(self);
    Result.Indent := indent;
    Result.LineNo := lineNo;
    Self.Add(Result);
  end;

  function _chkContinueNextLine:Boolean;

    function chkWord(word:string): Boolean;
    var
      pp: PChar;
    begin
      Result := False;
      pp := p;
      Dec(pp, Length(word));
      if StrLComp(pp, PChar(word), Length(word)) = 0 then
      begin
        Result := True;
      end;
    end;

  begin
    Result := False;
    if StrLComp(p,','#13#10, 3) = 0 then
    begin
      // ��O���`�F�b�N
      Result := True;
      if
        chkWord('����') or
        chkWord('�Ȃ��') or chkWord('�Ȃ�') or chkWord('��������') or
        chkWord('�Ⴆ��') or chkWord('��') or
        chkWord('����Ȃ�������') or chkWord('��������') or
        chkWord('�łȂ����') or
        chkWord('��') or
        chkWord('���[�v')   or
        chkWord('��')  or
        chkWord('����')  or
        chkWord('�J��Ԃ�')  or
        chkWord('�J�Ԃ�')  or
        chkWord('�J��Ԃ�')  or
        chkWord('�J��')  or
        chkWord('�G���[�Ď�')  or
        chkWord('�G���[')  or
        chkWord('��������')  or
        chkWord('��������')
      then
      begin
        Inc(p);
        Exit;
      end;
      Inc(p,3);
      Result := True;
    end;
  end;

begin
  //todo 4: �\�[�X���g�[�N���ɐ؂�
  p := PChar(src);
  lineNo := 1; // 1 ����͂��߂�

  // ��ԏ��߂̃u���b�N�����
  indent := countIndent;
  block  := newBlock(indent);

  while p^ <> #0 do
  begin
    // (1) ���s��
    if StrLComp(p, #13#10, 2) = 0 then
    begin
      Inc(p, 2); Inc(lineNo); // skip #13#10
      indent := countIndent;
      if p^ = #13 then Continue; // ��s�Ȃ玟�̃C���f���g�𐔂���
      // �������݂̃u���b�N����Ȃ�A�V�K�쐬���Ȃ�
      if block.Count <> 0 then block := newBlock(indent)
                          else block.Indent := indent;
      block.LineNo := lineNo;
      Continue;
    end;
    // (2) ���̍s�֑�����
    // �V���[���F�Ȃ�΁A�Ⴆ�΁A��A�����̌�͖�������
    if _chkContinueNextLine then
    // old rule => if StrLComp(p,','#13#10, 3) = 0 then
    begin
      Continue;
    end;
    // ���̋�؂� - �u���b�N��ς���
    if p^ = ';' then
    begin
      {
      Inc(p);
      block := newBlock(indent);
      block.LineNo := lineNo;
      }
      // �u���b�N��ς����ɁA�L����o�^����
      token := THimaToken.Create(block); block.Add(token);
      token.Token := p^; Inc(p);
      token.TokenType := tokenMark;
      token.TokenID := token_Semicolon;
      Continue;
    end;

    // �J�b�R(�͂��܂�)���H
    if p^ in ['(','{','['] then
    begin
      token := THimaToken.Create(block); block.Add(token);
      token.TokenID := HiSystem.TangoList.GetID(p^);
      token.Token := p^; Inc(p);
      // �I�I�J�b�R�͂��߂ɂ͏����͂��Ȃ��͂��I�I�@... �֐�(�͂�) �ŁA�u�́v�������Ƃ݂Ȃ��Ȃ����ƁI
      // token.Josi := HimaGetJosi(p);
      // token.JosiID := HiSYstem.JosiList.GetID(token.Josi);
      token.TokenType := tokenParenthesis;
      Continue;
    end else
    // �J�b�R(��)���H
    if p^ in [')','}',']'] then
    begin
      token := THimaToken.Create(block); block.Add(token);
      token.TokenID := HiSystem.TangoList.GetID(p^);
      token.Token := p^; Inc(p);
      token.Josi := HimaGetJosi(p); // ���������
      token.JosiID := HiSYstem.JosiList.GetID(token.Josi);
      token.TokenType := tokenParenthesis;
      Continue;
    end;
    // ���Z�q��
    if p^ in EnzansiChar1 then
    begin
      s := p^; Inc(p);
      if p^ in EnzansiChar2 then
      begin
        s := s + p^; Inc(p);
      end;
      //for DEBUG
      // Writeln(HiSystem.TangoList.EnumKeys); Readln;

      token := THimaToken.Create(block); block.Add(token);
      token.Token := s;
      token.TokenType := tokenOperator;
      token.TokenID := HiSystem.TangoList.GetID(s);

      Continue;
    end;
    // �}�[�N���H
    if p^ in HimaMark then
    begin
      token := THimaToken.Create(block); block.Add(token);
      token.Token := p^;
      token.TokenID := HiSystem.TangoList.GetID(token.Token);
      token.TokenType := tokenMark;
      Inc(p);
      Continue;
    end;
    // ���l���H
    if (p^ in NumberChars1) then
    begin
      token := THimaToken.Create(block); block.Add(token);
      token.NumberToken := HimaGetNumber(p, s);
      //token.Josuusi := s;
      skipSpace(p); // (ex)"-1 �Ȃ��"�Ə������Ƃ�����̂ŏ����`�F�b�N�̑O�ɃX�y�[�X��i�߂�
      token.Josi  := HimaGetJosi(p); // ���������
      token.TokenType := tokenNumber;
      token.TokenID := 0;
      token.JosiID := HiSystem.JosiList.GetID(token.Josi);
      Continue;
    end else
    // ������u�v�w�x"" `` ��?
    if (p^ = '`')or(p^ = '"')or(StrLComp(p,'�u',2) = 0)or(StrLComp(p,'�w',2) = 0) then
    begin
      token := THimaToken.Create(block); block.Add(token);
      token.Token := HimaGetString(p,lineNo);
      token.Josi  := HimaGetJosi(p);
      token.TokenType := tokenString;
      token.TokenID := 0;
      token.JosiID  := HiSystem.JosiList.GetID(token.Josi);
      Continue;
    end;
    // ��؂�L�����X�y�[�X
    if p^ in [' ', #9] then // ',' �̓}�[�N�ɂ���
    begin
      while p^ in [' ',#9] do Inc(p);
      Continue;
    end;
    // ��ʃg�[�N����؂�o��
    s := HimaGetWord(p, tokenJosi);
    if s <> '' then
    begin
      if (p <> nil) and (p^ = '.') then Inc(p); // "(�P��)." �Ȃ� skip
      token := THimaToken.Create(block); block.Add(token);
      token.Token := DeleteGobi(s); // ���߂���P��̌�����ȗ����ēo�^
      token.TokenID := HiSystem.TangoList.GetID(token.Token);
      token.Josi  := tokenJosi;
      token.JosiID := HiSystem.JosiList.GetID(token.Josi);
      token.TokenType := tokenTango;
      // �����񉉎Z�q�`�F�b�N
      if token.TokenID = token_katu then
      begin
        token.Token     := '&&';
        token.TokenID   := token_and;
        token.TokenType := tokenOperator;
      end else
      if token.TokenID = token_matawa then
      begin
        token.Token     := '||';
        token.TokenID   := token_or;
        token.TokenType := tokenOperator;
      end else
      ;
      Continue;
    end;
    // ��͕s���ȋL��
    s := getOneChar(p);
    if Pos(s, '���E����') > 0 then
    begin
      token := THimaToken.Create(block); block.Add(token);
      token.Token := s;
      token.TokenID := HiSystem.TangoList.GetID(s);
      token.TokenType := tokenMark;
      Continue;
    end;
    raise EHimaSyntax.Create(FileNo, lineNo, ERR_S_SOURCE_DUST+'(�����R�[�h='+IntToStr(Ord(p^))+')', [s]);
  end;

  if block.Count = 0 then // �Ō�̗]���ȃu���b�N���폜
  begin
    Self.Delete(Self.Count - 1);
    if Self.Count > 0 then
    begin
      block := Self.Items[ Self.Count - 1 ];
      if block <> nil then block.NextBlock := nil;
    end;
  end;
end;

constructor THimaFile.Create(Parent: THimaFiles; Fileno: Integer);
begin
  self.Parent := Parent;
  self.Fileno := Fileno;
  Path := '';
  TopBlock := nil;
  CurBlock := nil;
end;


function THimaFile.GetAsText: string;
var
  i,j: Integer;
  block: THimaBlock;
begin
  Result := '';
  for i := 0 to FCount - 1 do
  begin
    block := Items[i];
    // lineNo
    Result := Result + IntToStr(block.LineNo) + ':';
    // indent
    for j := 1 to block.Indent do Result := Result + ' ';
    // text
    Result := Result + block.GetAsText(' ') + #13#10;
  end;
end;




procedure THimaFile.LoadFromFile(Filename: string);
var
  src, fname, path: string;

begin
  // �p�X�ƃt�@�C�����𕪉�
  path := ExtractFilePath(Filename);
  fname := ExtractFileName(Filename);

  // ���O�ƃt�@�C���ԍ���ݒ�
  Self.Filename := fname;
  Self.Fileno   := setSourceFileName(fname);

  // �t�@�C����������
  if (unit_pack_files.FileMixReader = nil) or
     (not unit_pack_files.FileMixReader.ReadFileAsString(fname, src)) then
  begin
    //--------------------------------------------------------------------------
    // ���[�J�����`�F�b�N
    if HiFindFile(Filename) = False then
    begin
      raise Exception.Create('�t�@�C�����ǂݍ��߂܂���B�w'+fname+'�x');
    end;
    // �\�[�X�̃��[�h
    src := FileLoadAll(Filename);
    Self.Path := ExtractFilePath(Filename);
    //--------------------------------------------------------------------------
  end;

  // �ꎞ���
  src := HimaSourceConverter(FileNo, src);
  try
    Analize(src);
  except on e: Exception do
    raise Exception.Create('�g�[�N���̉�͒��ɃG���[�B'+e.Message);
  end;
end;

procedure THimaFile.SetSource(src: string);
begin
  src := HimaSourceConverter(-1, src);
  Self.Filename := '';
  Self.Fileno := -1;
  Analize(src);
end;

function THimaFile.TopToken: THimaToken;
begin
  Result := nil;
  // ��ԏ��߂̃g�[�N���𓾂�
  if Self.Count = 0 then Exit;
  Result := TopBlock.TopToken;
end;

{ THimaFiles }

function THimaFiles.FindFile(Filename: string): THimaFile;
var
  i: Integer;
  h: THimaFile;

  function fp(s: string): string;
  begin
    s := ExtractFileName(s);
    s := getToken_s(s, '.'); // �g���q�̑O�������L��
    s := UpperCase(s);
    Result := s;
  end;

begin
  Result := nil;
  for i := 0 to FCount - 1 do
  begin
    h := Items[i];
    if fp(h.Filename) = fp(Filename) then
    begin
      Result := h;
      Break;
    end;
  end;
end;

function THimaFiles.FindFileNo(no: Integer): THimaFile;
var
  i: Integer;
  h: THimaFile;
begin
  Result := nil;
  for i := 0 to FCount - 1 do
  begin
    h := Items[i];
    if no = h.Fileno then
    begin
      Result := h;
      Break;
    end;
  end;
end;

function THimaFiles.LoadAndAdd(Filename: string):THimaFile;
var
  himaFile: THimaFile;
begin
  Result := FindFile(Filename);

  if nil = Result then
  begin
    himaFile := THimaFile.Create(self, FCount);
    himaFile.LoadFromFile(Filename);
    Result := himaFile;
    self.Add(Result);
  end;
end;

function THimaFiles.LoadSourceAdd(SourceText, Filename: string): THimaFile;
var
  himaFile: THimaFile;
  src: string;
begin
  himaFile := THimaFile.Create(self, FCount);
  himaFile.Filename := Filename;
  himaFile.Fileno   := setSourceFileName(Filename);

  // �ꎞ���
  src := HimaSourceConverter(himaFile.FileNo, SourceText);
  himaFile.Analize(src);

  Result := himaFile;
  self.Add(Result);
end;

{ THimaToken }

function THimaToken.CheckNextBlock: THimaToken;
var
  b: THimaBlock;
begin
  Result := nil;
  b := Self.Parent;
  b := b.NextBlock; // ���̃u���b�N
  if b = nil then Exit;
  Result := b.TopToken;
end;

constructor THimaToken.Create(Parent: THimaBlock);
begin
  self.Parent  := Parent;
  self.Token   := '';
  self.Josi    := '';
  self.JosiID  := -1;
  Self.TokenID := 0;
  NextToken    := nil;
end;


function THimaToken.DebugInfo: TDebugInfo;
begin
  Result.FileNo := FileNo;
  Result.LineNo := LineNo;
end;

function THimaToken.FileNo: Integer;
begin
  Result := Self.Parent.Parent.Fileno;
end;

{
function THimaToken.GetConstNum: Extended;
begin
  Result := HimaStrToNum(token);
end;
}

function THimaToken.GetAsText: string;
begin
  if Self.TokenType = tokenNumber then
  begin
    Result := FloatToStr(Self.NumberToken);
  end else
  begin
    Result := Self.Token;
  end;
end;

function THimaToken.GetConstPtr: Pointer;
begin
  if token = 'NULL' then
    Result := nil
  else
    raise EHimaSyntax.Create(Self.FileNo, Self.LineNo, 'NULL', []);
end;

function THimaToken.GetConstStr: string;
begin
  if (Copy(token,1,1) = '"') and (Copy(token,Length(token),1) = '"') then
  begin
    // "12345"
    Result := Copy(token, 2, Length(token) - 2);
  end else
  if (Copy(token,1,2) = '�u') and (Copy(token,Length(token)-1,2) = '�v') then
  begin
    Result := Copy(token, 3, Length(token) - 4);
  end else
  if (Copy(token,1,2) = '�w') and (Copy(token,Length(token)-1,2) = '�x') then
  begin
    Result := Copy(token, 3, Length(token) - 4);
  end else
  if (Copy(token,1,1) = '�') and (Copy(token,Length(token),1) = '�') then
  begin
    Result := Copy(token, 2, Length(token) - 2);
  end else
  if (Copy(token,1,1) = '`') and (Copy(token,Length(token),1) = '`') then
  begin
    Result := Copy(token, 2, Length(token) - 2);
  end else
  begin
    Result := token;
  end;
end;

function THimaToken.Indent: Integer;
begin
  Result := Self.Parent.Indent;
end;

function THimaToken.LineNo: Integer;
begin
  Result := Self.Parent.LineNo;
end;

function THimaToken.UCToken: string;
begin
  Result := UpperCaseEx(token);
end;

{ THimaTangoList }

constructor THimaTangoList.Create;
begin
  FLastID := 100000 {99xxx}; // �K���ȍŏ��l
  inherited;
end;

function THimaTangoList.GetID(key: string; DefaultID: Integer): Integer;
var
  tango: THimaTango;
begin
  // �P��ID�𒲂ׂ�
  tango := GetTango(key);

  // �����o�^����ĂȂ��P�ꂾ������...
  if tango = nil then
  begin
    tango := THimaTango.Create;
    tango.Key := key;

    if DefaultID <= 0 then
    begin
      tango.ID  := FLastID;
      Inc(FLastID);
    end else
    begin
      tango.ID := DefaultID;
    end;

    SetTango(key, tango);
  end;

  //
  Result := tango.ID;
end;

function THimaTangoList.FindKey(id: Integer): string;
begin
  FFindKey := '';
  FFindID  := id;
  Each(subFindKey);
  Result := FFindKey;
end;

function THimaTangoList.GetTango(key: string): THimaTango;
begin
  Result := THimaTango(Items[key]);
end;

procedure THimaTangoList.SetID(key: string; Value: Integer);
var
  g: THimaTango;
begin
  key := DeleteGobi(key);
  g := GetTango(key);
  if g = nil then
  begin
    g := THimaTango.Create;
    g.Key := key;
    g.ID := Value;
    Add(g);
  end else
  begin
    g.ID := Value; // �㏑��
  end;
end;

procedure THimaTangoList.SetTango(key: string; const Value: THimaTango);
begin
  Items[key] := Value;
end;


function THimaTangoList.subFindKey(item: THHashItem): Boolean;
var
  p: THimaTango;
begin
  p := item as THimaTango;
  if (p.ID = FFindID) then
  begin
    Result := False; // break
    FFindKey := p.Key;
  end else
  begin
    Result := True; // continue
  end;
end;

function THimaTangoList.EnumKeys: string;
begin
  FFindKey := '';
  Each(subEnumKeys);
  Result := FFindKey;
end;

function THimaTangoList.subEnumKeys(item: THHashItem): Boolean;
var
  p: THimaTango;
begin
  p := THimaTango(item);
  FFindKey := FFindKey + inttostr(p.ID) + ':' + item.Key + #13#10;
  Result := True;
end;

{ THimaJosiList }

function THimaJosiList.AddID(key: string): Integer;
begin
  Result := GetID(key);
  if Result < 0 then
  begin
    Result := FLastID;
    SetID(key, FLastID);
    Inc(FLastID);
  end;
end;

constructor THimaJosiList.Create;
begin
  inherited;
  FLastID := 1000;
end;

destructor THimaJosiList.Destroy;
begin
  Clear;
  inherited;
end;

function THimaJosiList.EnumKeys: string;
var
  i: Integer;
  w: THimaTango;
begin
  Result := '';
  for i := 0 to Count - 1 do
  begin
    w := Items[i];
    Result := Result + w.Key + #13#10;
  end;
  Result := Trim(Result);
end;

function THimaJosiList.Find(var p: PChar): string;
var
  i: Integer;
  w: THimaTango;
begin
  Result := '';
  for i := 0 to Count - 1 do
  begin
    w := Items[i];
    if StrLComp(p, PChar(w.Key), Length(w.Key)) = 0 then
    begin
      Result := w.Key;
      Inc(p, Length(w.Key));
      Break;  
    end;
  end;
end;

function THimaJosiList.GetID(key: string): Integer;
var
  i: Integer;
  p: THimaTango;
begin
  Result := -1; if key = '' then Exit;
  for i := 0 to Count - 1 do
  begin
    p := Items[i];
    if p.Key = key then
    begin
      Result := p.ID; Break;
    end;
  end;
end;

function THimaJosiList.ID2Str(id: WORD): string;
var
  i: Integer;
  p: THimaTango;
begin
  Result := '';
  for i := 0 to Count - 1 do
  begin
    p := Items[i];
    if p.ID = id then
    begin
      Result := p.Key;
      Break;
    end;
  end;
end;

procedure THimaJosiList.SetID(key: string; Value: Integer);
var
  i: Integer;
  p: THimaTango;
begin
  i := GetID(key);
  if i < 0 then
  begin
    p     := THimaTango.Create;
    p.ID  := Value;
    p.Key := key;
    Add(p);
  end else
  begin
    p    := Items[i];
    p.ID := Value;
  end;
end;

function comp_by_len(A, B: Pointer): Integer; // A>B �Ȃ�0�ȏ�
var
  ta, tb: THimaTango;
begin
  ta := THimaTango(A);
  tb := THimaTango(B);
  Result := Length(tb.Key) - Length(ta.Key);
end;

procedure THimaJosiList.SortByLen;
begin
  MergeSort(comp_by_len);
end;

{ THiKuraidori }

constructor THiKuraidori.Create(akurai: string; abai: Extended);
begin
  kurai := akurai;
  bai   := abai;
end;

function THiKuraidori.Comp(var p: PChar): Boolean;
begin
  if StrLComp(p, PChar(kurai), Length(kurai)) = 0 then
  begin
    Result := True;
    Inc(p, Length(kurai));
  end else
  begin
    Result := False;
  end;
end;

{ THiKuraidoriList }

function THiKuraidoriList.FindKurai(var p: PChar;
  var num: Extended): Boolean;
var
  i: Integer;
  k: THiKuraidori;
begin
  Result := False;
  for i := 0 to Count - 1 do
  begin
    k := Items[i];
    if k.Comp(p) then
    begin
      Result := True;
      num := num * k.bai;
      Break;
    end;
  end;
  // �P�ʂ̑g�ݍ��킹�ɑΉ�����
  if Result then
  begin
    FindKurai(p, num);
  end;
end;

procedure setKuraidoriList;

  procedure _add(name: string; bai: Extended);
  begin
    KuraidoriList.Add(THiKuraidori.Create(name, bai));
  end;

begin
  //<SI�P�ʌn>
  _add('�\',10);
  _add('_D',10);
  _add('�S',100);
  _add('_h',100);
  _add('��',1000);
  _add('_k',1000);
  _add('��',10000);
  _add('_M' ,1000000);
  _add('��',100000000);
  _add('_B' ,1);
  _add('KB',1024);
  _add('MB',1024*1024); // = 1024KB
  _add('GB',1024*1024*1024); // = 1024MB = 1024^3

  _add('��',0.1);
  _add('_d',0.1);
  _add('��',0.01);
  _add('_c',0.01);
  _add('��',0.001);
  _add('_m',0.001);
  _add('��',0.000001);
  //</SI�P�ʌn>
end;

procedure setTokenList(sys: TObject);
begin

  //todo 1: �\���̓o�^
  with THiSystem(sys).TangoList do
  begin
    SetID('(', token_kakko_begin);
    SetID(')', token_kakko_end);
    SetID('[', token_kaku_kakko_begin);
    SetID(']', token_kaku_kakko_end);
    SetID('{', token_nami_kakko_begin);
    SetID('}', token_nami_kakko_end);

    SetID('+', token_plus);
    SetID('-', token_minus);
    SetID('*', token_mul);
    SetID('/', token_div);
    SetID('%', token_mod);
    SetID('=', token_Eq);
    SetID('==', token_Eq);
    SetID('<>', token_NotEq);
    SetID('!=', token_NotEq);
    SetID('>',  token_Gt);
    SetID('>=', token_GtEq);
    SetID('<',  token_Lt);
    SetID('<=', token_LtEq);
    SetID('<<', token_ShiftL);
    SetID('>>', token_ShiftR);
    SetID('~', token_tilde);
    SetID('^', token_power);
    SetID('|', token_vLine);
    SetID(':', token_Colon);
    SetID(';', token_Semicolon);
    SetID('?', token_question);

    SetID('&',  token_plus_str);
    SetID('&&', token_and);
    SetID('||', token_or);
    SetID('����',   token_katu);
    SetID('�܂���', token_matawa);
    SetID('�܂�',   token_matawa);

    SetID('!', token_mark_option);
    SetID('@', token_mark_at);
    SetID('��', token_mark_sikaku);
    SetID('�E', token_mark_nakaten);
    SetID(',',  token_comma);
    SetID('\',  token_yen);

    SetID('����', token_mosi);
    SetID('�Ȃ��', token_naraba);
    SetID('�Ȃ�',   token_naraba);
    SetID('��', token_tagaeba);
    SetID('����Ȃ�������', token_tagaeba);
    SetID('��������', token_tagaeba);
    SetID('�łȂ����', token_tagaeba);
    SetID('��',         token_aida);
    SetID('���[�v',     token_loop);
    SetID('��',         token_kai);
    SetID('����',       token_hanpuku);
    SetID('�J���',     token_kurikaesu);
    SetID('�J��',       token_kurikaesu);
    SetID('�G���[�Ď�', token_err_kansi);
    SetID('�G���[',     token_err);
    SetID('��������',   token_joukenbunki);
    SetID('����',       token_koko);

    SetID('������',   token_mojiretu);
    SetID('���l',     token_suuti);
    SetID('����',     token_seisu);
    SetID('�ϐ�',     token_hensuu);
    SetID('�z��',     token_hairetu);
    SetID('����',     token_jissuu);
    SetID('�O���[�v', token_group);
    SetID('�n�b�V��', token_hash);
    SetID('�l�n'  ,   token_ByVal);
    SetID('�Q�Ɠn',   token_ByRef);
    SetID('�ϐ��錾', token_hensuu_sengen);
    SetID('�ϐ�������', token_hensuu_syokika);
    SetID('�K�v',     token_hituyou);
    SetID('�s�v',     token_huyou);
    SetID('��',       token_tukuru);
    SetID('��',       token_kowasu);
    SetID('����J',     token_private);
    SetID('�C�x���g',   token_event);
    SetID('���O',       token_name);
    SetID('�捞',     token_include);
    SetID('�f�t�H���g', token_default);
    SetID('�l�[���X�y�[�X�ύX',token_namespace_henkou);
    SetID('��', token_kaisu);
    SetID('�G���[���b�Z�[�W', token_errMsg);
    SetID('�Ώ�', token_taisyou);
    SetID('�V�X�e��',     token_system);
    SetID('���[�U�[',     token_user);


    SetID('��', token_left);
    SetID('��', token_right);

    SetID('���', token_dainyu);

    SetID('����', token_sore);
    SetID('S',    token_s);
    SetID('V',    token_v);
    SetID('CNT',  token_cnt);
    SetID('A',    token_a);
    SetID('B',    token_b);
    SetID('C',    token_c);
    SetID('F',    token_f);
    SetID('X',    token_x);
    SetID('Y',    token_y);
    SetID('��',   token_sono);
    SetID('���g', token_jisin);
    SetID('����', token_kore); // �� = ����

    //Writeln(EnumKeys);
    //ReadLn;
  end;

end;

procedure setJosiList(sys: TObject);
begin
  //todo 1:�����̓o�^
  with THiSystem(sys).JosiList do
  begin
    //<�����̓o�^>
    //�\���Ƃ��ĈӖ��̂��鏕��
    SetID('�Ƃ�', josi_towa);
    SetID('��',         josi_wa);

    SetID('�ɂ���',   josi_nituite);

    SetID('�������',   josi_naraba);
    SetID('�Ȃ��',     josi_naraba);
    SetID('�Ȃ�',       josi_naraba);
    SetID('�łȂ����', josi_denakereba);

    // ���߂̈����Ƃ��āA�������鏕��
    SetID('����', josi_kara);
    SetID('�܂�', josi_made);
    SetID('�܂ł�',josi_madewo);
    AddID('�܂ł�');
    SetID('��', josi_de);
    SetID('��', josi_wo);
    SetID('��', josi_no);
    SetID('��', josi_ga);
    SetID('��', josi_ni);
    SetID('��', josi_he);
    AddID('��');

    // ���{��炵���݂��邽�߂̕⏕����
    AddID('����');
    AddID('����');
    AddID('���炢');
    AddID('�Ȃ̂�');
    AddID('�Ƃ���');
    AddID('���');
    AddID('�ق�');
    AddID('�Ȃ�');

    // �ȉ��A2004/11/07 �ɒǉ���������
    AddID('����');
    AddID('�ł�');

    // �ȉ��A2005/01/26 �ɒǉ���������
    SetID('��', josi_te);
    //</�����̓o�^>

    SortByLen; // �K�v
  end;

end;


initialization
  // �ʎ�� ... ���̃��X�g�͕s��
  KuraidoriList := THiKuraidoriList.Create;
  setKuraidoriList;

finalization
  FreeAndNil(KuraidoriList);

end.