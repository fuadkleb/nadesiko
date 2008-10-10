unit StrUnit;
(*------------------------------------------------------------------------------
�ėp�����񏈗����`�������j�b�g

�S�Ă̊֐��́A�}���`�o�C�g����(S-JIS)�ɑΉ����Ă���

�쐬�ҁF�N�W����s��(http://kujirahand.com)
�쐬���F2001/11/24

�����F
2002/04/09 �r����#0���܂ޕ�����ł������u���ł���悤�ɏC��

------------------------------------------------------------------------------*)
interface
uses
  Windows, SysUtils, Classes {$IFDEF VER140},Variants{$ENDIF}
  {$IFDEF VER150},Variants{$ENDIF},imm, Forms;

type
  TCharSet = set of Char;

{------------------------------------------------------------------------------}
{�}���`�o�C�g�ɑΉ����������u���֐�}

{�����񌟍� // ���o�C�g�ڂ̕����̈ʒu��Ԃ�}
function JPosEx(const sub, str:string; idx:Integer): Integer;
{������u��}
function JReplace(const Str, oldStr, newStr:string; repAll:Boolean): string;
{������u���g����}
function JReplaceEx(const Str, oldStr, newStr:string; repAll:Boolean; useCase:Boolean): string;
{�w��ڂ�oldStr���AnewStr�ɒu������}
function JReplaceCnt(const Str, oldStr, newStr:string; Index: Integer): string;
{�f���~�^������܂ł̒P���؂�o���B�i�؂�o�����P��Ƀf���~�^�͊܂܂Ȃ��B�j
�؂�o����́A���̕�����str����A�؂�o����������{�f���~�^�����폜����B}
function GetToken(const delimiter: String; var str: string): String;
{�}���`�o�C�g�������𓾂�}
function JLength(const str: string): Integer;
{�}���`�o�C�g�������؂�o��}
function JCopy(const str: string; Index, Count: Integer): string;
{�}���`�o�C�g���������������}
function JPosM(const sub, str: string): Integer;

{------------------------------------------------------------------------------}
{������ނ̕ϊ�}

{ LCMapString ���ȒP�Ɏg�����߂̊֐� �ϊ���̕�����́Astr * 2 �ȓ�}
function LCMapStringEx(const str: string; MapFlag: DWORD): string;
{ LCMapString ���ȒP�Ɏg�����߂̊֐� �ϊ���̕�����́Astr �ȓ�}
function LCMapStringExHalf(const str: string; MapFlag: DWORD): string;
{�S�p�ϊ�}
function convToFull(const str: string): string;
{���p�ϊ�}
function convToHalf(const str: string): string;
{�����ƃA���t�@�x�b�g�ƋL���̂ݔ��p�ɕϊ�����/�A���x��}
function convToHalfAnk(const str: string): string;
{�Ђ炪�ȁE�J�^�J�i�̕ϊ�}
function convToHiragana(const str: string): string;
function convToKatakana(const str: string): string;
function ConvToHurigana(const str: string): string; // �U�艼���ɕϊ�
{�}���`�o�C�g���l�������啶���A��������}
function LowerCaseEx(const str: string): string;
function UpperCaseEx(const str: string): string;
function UpperCaseOne(const str: string): string;//�ꕶ���ڂ����啶��
{���[�}���\�L�𔼊p�J�i�ɕϊ�}
function RomajiToKana(romaji: String): String;
{� ���m�� �̂悤�ȍs���̔��p�J�i���폜���ĕԂ�}
function TrimLeftKana(str: string): string;

{------------------------------------------------------------------------------}
{������ނ̔���}
function IsHiragana(const str: string): Boolean;
function IsKatakana(const str: string): Boolean;
function Asc(const str: string): Integer; //�����R�[�h�𓾂�
function IsNumStr(const str: string): Boolean; //�����񂪑S�Đ��l���ǂ������f

{------------------------------------------------------------------------------}
{HTML����}

{HTML ���� �^�O����菜��}
function DeleteTag(const html: string): String;
{HTML�̎w��^�O�ň͂�ꂽ�����𔲂��o��}
function GetTag(var html:string; tag: string): string;
function GetTags(html:string; tag: string): string;
function GetAbsolutePath(soutai, base: string; Delimiter: Char): string;
function HtmlColorToColorCode(s: string): Integer;
function ColorCodeToHtmlColor(c: Integer): string;

{------------------------------------------------------------------------------}
{�g�[�N������}

{�g�[�N���؂�o���^��؂蕶������i�߂�}
function GetTokenChars(delimiter: TCharSet; var ptr:PChar): string;
function GetTokenPtr(delimiter: Char; var ptr:PChar): string;
function SplitChar(delimiter: Char; str: string): TStringList;
{�l�X�g����i�j�̓��e�𔲂��o��}
function GetKakko(var pp: PChar): string;

{------------------------------------------------------------------------------}
{��������}

{���t�̉��Z ex)�R������ IncDate('2001/10/30','0/3/0') �O���O IncDate('2001/1/1','-0/0/3')}
function IncDate(BaseDate: TDateTime; AddDate: string): TDateTime;
{���Ԃ̉��Z ex)�R���Ԍ� IncTime('15:0:0','3:0:0') �O�b�O IncTime('12:45:0','-0:0:3')}
function IncTime(BaseTime: TDateTime; AddTime: string): TDateTime;
{����A�a��ɑΉ��������t�ϊ��p�֐�}
function StrToDateStr(const str: string): string;
{����A�a��ɑΉ��������t�ϊ��p�֐�}
function StrToDateEx(str: string): TDateTime;
{TDateTime���A�a��ɕϊ�����}
function DateToWareki(d: TDateTime): string;

{------------------------------------------------------------------------------}
{���̑�}

{3����؂�ŃJ���}��}������}
function InsertYenComma(const yen: string): string;
{�������o������萔�l�ɕϊ�����}
function StrToValue(const str: string): Extended;
{�s��������}
function CutLine(line: string; cnt,tabCnt: Integer; kinsoku: string): string;


{------------------------------------------------------------------------------}
implementation

uses DateUtils, gui_benri;


{�s��������}
function CutLine(line: string; cnt,tabCnt: Integer; kinsoku: string): string;
(*
const
  GYOUTOU_KINSI = '�A�B�C�D�E�H�I�J�K�R�S�T�U�X�[�j�n�p�v�x!),.:;?]}�������';
*)
var
  p: PChar;
  i: Integer;

  procedure CopyOne;
  begin
    Result := Result + p^;
    Inc(p);
  end;

  procedure InsCrLf;
  var next_c: string;
  begin
    //�֑�����(�s���֑�����)
    if kinsoku<>'' then
    begin
      if p^ in LeadBytes then
      begin
        next_c := p^ + (p+1)^;
      end else
      begin
        next_c := p^;
      end;

      if JPosEx(next_c, kinsoku, 1) > 0 then
      begin
        if p^ in LeadBytes then
        begin
          CopyOne; CopyOne;
        end else
        begin
          CopyOne;
        end;
      end;
    end;

    Result := Result + #13#10;
    i := 0;
  end;

begin
  if cnt<=0 then
  begin
    Result := line;
    Exit;
  end;

  p  := PChar(line);
  i := 0;
  while p^ <> #0 do
  begin
    if p^ in LeadBytes then
    begin
      if (i+2) > cnt then InsCrLf;
      CopyOne;
      CopyOne;
      Inc(i,2);
    end else
    begin
      if i >= cnt then InsCrLf;
      if p^ in [#13,#10] then
      begin
          Inc(p);
          if p^ in[#13,#10] then Inc(p);
          InsCrLf;
      end else
      if p^ = #9 then
      begin
          CopyOne;
          Inc(i, tabCnt);
      end else
      begin
          CopyOne;
          Inc(i);
      end;
    end;
  end;
end;

{TDateTime���A�a��ɕϊ�����}
function DateToWareki(d: TDateTime): string;
var y, yy, mm, dd: Word; sy: string;

const
  MEIJI  = 1868; //* �C�� 2003/09/28
  TAISYO = 1912;
  SYOWA  = 1926;
  HEISEI = 1989;
begin
    DecodeDate(d, yy, mm, dd);
    if (MEIJI<=yy)and(yy<TAISYO) then
    begin
        y := yy-MEIJI+1;
        if y=1 then sy := '���N' else sy := IntToStr(y)+'�N';
        Result := Format('����'+sy+'%d��%d��',[mm,dd]);
    end else
    if (TAISYO<=yy)and(yy<SYOWA) then
    begin
        y := yy-TAISYO+1;
        if y=1 then sy := '���N' else sy := IntToStr(y)+'�N';
        Result := Format('�吳'+sy+'%d��%d��',[mm,dd]);
    end else
    if (SYOWA<=yy)and(yy<HEISEI) then
    begin
        y := yy-SYOWA+1;
        if y=1 then sy := '���N' else sy := IntToStr(y)+'�N';
        Result := Format('���a'+sy+'%d��%d��',[mm,dd]);
    end else
    if (HEISEI<=yy) then
    begin
        y := yy-HEISEI+1;
        if y=1 then sy := '���N' else sy := IntToStr(y)+'�N';
        Result := Format('����'+sy+'%d��%d��',[mm,dd]);
    end;
end;

{�}���`�o�C�g�������𓾂�}
function JLength(const str: string): Integer;
var
    p: PChar;
begin
    p := PChar(str);
    Result := 0;
    while p^ <> #0 do
    begin
        if p^ in LeadBytes then
            Inc(p,2)
        else
            Inc(p);
        Inc(Result);
    end;
end;

{�}���`�o�C�g�������؂�o��}
function JCopy(const str: string; Index, Count: Integer): string;
var
    i, iTo: Integer;
    p: PChar;
    ch: string;
begin
    i   := 1;
    iTo := Index + Count -1;
    p := PChar(str);
    Result := '';
    while (p^ <> #0) do
    begin
        if p^ in LeadBytes then
        begin
            ch := p^ + (p+1)^;
            Inc(p,2);
        end else
        begin
            ch :=p^;
            Inc(p);
        end;
        if (Index <= i) and (i <= iTo) then
        begin
            Result := Result + ch;
        end;
        Inc(i);
        if iTo < i then Break;
    end;
end;

{�}���`�o�C�g���������������}
function JPosM(const sub, str: string): Integer;
var
    i, len: Integer;
    p: PChar;
begin
    i := 1;
    Result := 0;
    p := PChar(str);
    len := Length(sub);
    while p^ <> #0 do
    begin
        if StrLComp(p, PChar(sub), len) = 0 then
        begin
            Result := i; Break;
        end;
        if p^ in LeadBytes then
        begin
            Inc(p,2);
        end else
        begin
            Inc(p);
        end;
        Inc(i);
    end;
end;

function Asc(const str: string): Integer; //�����R�[�h�𓾂�
begin
    if str='' then begin
        Result := 0;
        Exit;
    end;

    if str[1] in LeadBytes then
    begin
        Result := (Ord(str[1]) shl 8) + Ord(str[2]);
    end else
        Result := Ord(str[1]);
end;

{����A�a��ɑΉ��������t�ϊ��p�֐�}
function StrToDateStr(const str: string): string;
begin
    Result:='';
    if str='' then Exit;
    Result := FormatDateTime(
        'yyyy/mm/dd',
        StrToDateEx(str)
    );
end;

function StrToDateEx(str: string): TDateTime;
begin
    Result := Now;
    if str='' then Exit;
    if Pos('.',str)>0 then str := JReplace(str,'.','/',True);
    Result := VarToDateTime(str);
end;

{���Ԃ̉��Z ex)�R���Ԍ� IncTime('15:0:0','3:0:0') �O�b�O IncTime('12:45:0','-0:0:3')}
function IncTime(BaseTime: TDateTime; AddTime: string): TDateTime;
var
    flg: string;
    hh,nn,ss: Word;
begin
    // �f���t�@�C�̕W���֐����g���悤�ɕύX 2003/2/19
    // ���������������f
    flg := Copy(AddTime,1,1);
    if (flg='-')or(flg='+') then Delete(AddTime, 1,1);

    hh := StrToIntDef(getToken(':', AddTime),0);
    nn := StrToIntDef(getToken(':', AddTime),0);
    ss := StrToIntDef(AddTime, 0);
    if flg <> '-' then
    begin
      Result := IncHour(BaseTime, hh);
      Result := IncMinute(Result, nn);
      Result := IncSecond(Result, ss);
    end else
    begin
      Result := IncHour(BaseTime, hh*-1);
      Result := IncMinute(Result, nn*-1);
      Result := IncSecond(Result, ss*-1);
      if(Result<0)then Result := IncHour(Result, 24);
    end;
end;

{���t�̉��Z ex)�R������ IncDate('2001/10/30','0/3/0') �O���O IncDate('2001/1/1','-0/0/3')}
function IncDate(BaseDate: TDateTime; AddDate: string): TDateTime;
var
    flg: string;
    yy,mm,dd: Word;
begin
    // �f���t�@�C�̕W���֐����g���悤�ɕύX 2003/2/19
    // �������������̔��f
    flg := Copy(AddDate,1,1);
    if (flg='-')or(flg='+') then Delete(AddDate, 1,1);

    // �������t�𕪉�����
    yy := StrToIntDef(getToken('/', AddDate),0);
    mm := StrToIntDef(getToken('/', AddDate),0);
    dd := StrToIntDef(AddDate, 0);
    if flg <> '-' then
    begin
      // ����
      Result := IncYear(BaseDate, yy);
      Result := IncMonth(Result, mm);
      Result := IncDay(Result, dd);
    end else
    begin
      // ����
      Result := IncYear(BaseDate, yy*-1);
      Result := IncMonth(Result, mm*-1);
      Result := IncDay(Result, dd*-1);
    end;
end;

procedure skipSpace(var p: PChar);
begin
    while p^ in [' ',#9] do Inc(p);
end;

{�l�X�g����i�j�̓��e�𔲂��o��}
function GetKakko(var pp: PChar): string;
const
    CH_STR1 = '"';
    CH_STR2 = '''';
var
    nest, len: Integer;
    tmp, buf: PChar;
    IsStr, IsStr2: Boolean;
begin
    Result := '';
    skipSpace(pp);
    nest := 0;
    IsStr := False;
    IsStr2 := False;
    if pp^ = '(' then
    begin
        Inc(nest);
        Inc(pp);
    end;
    tmp := pp;
    while pp^ <> #0 do
    begin
        if pp^ in LeadBytes then
        begin
            Inc(pp,2); continue;
        end else
        case pp^ of
            CH_STR1:
            begin
                if IsStr2 = False then
                    IsStr := not IsStr;
                Inc(pp);
            end;
            CH_STR2:
            begin
                if IsStr = False then
                    IsStr2 := not IsStr2;
                Inc(pp);
            end;
            '\':
            begin
                Inc(pp);
                if IsStr then if pp^ in LeadBytes then Inc(pp,2) else Inc(pp);
            end;
            '(':
            begin
                Inc(pp);
                if (IsStr=False)and(IsStr2=False) then
                begin
                    Inc(nest); continue;
                end;
            end;
            ')':
            begin
                Inc(pp);
                if (IsStr=False)and(IsStr2=False) then
                begin
                    Dec(nest);
                    if nest = 0 then Break;
                    continue;
                end;
            end;
            else
                Inc(pp);
        end;
    end;
    len := pp - tmp -1;
    if len<=0 then
    begin
        if nest <> 0 then
        begin
            pp := tmp;
            raise Exception.Create('")"���Ή����Ă��܂���B');
        end;
        Exit;
    end;
    if nest > 0 then raise Exception.Create('")"���Ή����Ă��܂���B');
    GetMem(buf, len + 1);
    try
        StrLCopy(buf, tmp, len);
        (buf+len)^ := #0;
        Result := string( PChar(buf) );
    finally
        FreeMem(buf);
    end;
end;

{������𐔒l�ɕϊ�����}
function StrToValue(const str: string): Extended;
var
    st,p,mem: PChar;
    len, sig: Integer;
    buf: string;

    function convToHalfMini(sSrc: string): string;
    var
      cSrc : array [0..255] of char;
      cDst : array [0..255] of char;
    begin
      StrLCopy( cSrc, PChar(sSrc), 254  );
      FillChar( cDst, sizeof(cDst), 0);
      LCMapString( LOCALE_SYSTEM_DEFAULT, LCMAP_HALFWIDTH, cSrc, strlen(cSrc),cDst, sizeof(cDst) );
      Result := cDst;
    end;

begin

    // �͂��߂ɁA�����𔼊p�ɂ���
    if Trim(str)='' then begin Result := 0; Exit; end;

    buf := Trim(JReplace(ConvToHalfMini(str),',','',True));//�J���}���폜
    if Copy(buf,1,1) = '\' then System.Delete(buf,1,1);

    p := PChar(buf);
    while p^ in [' ',#9] do Inc(p);
    if p^='$' then
    begin
        Result := StrToIntDef(buf,0);
        Exit;
    end;

    sig := 1;

    if p^ = '+' then Inc(p) else
    if p^ ='-' then
    begin
        Inc(p);
        sig := -1;
    end;

    st := p;
    // ����
    while p^ in ['0'..'9'] do Inc(p);
    // �����_
    if p^ = '.' then Inc(p);
    while p^ in ['0'..'9'] do Inc(p);
    // �w���`��
    if (p^ in ['e','E']) and ((p+1)^ in ['+','-']) and ((p+2)^ in ['0'..'9']) then
    begin
      Inc(p,3);
      while p^ in ['0'..'9'] do Inc(p);
    end;

    len := p - st;
    if len=0 then begin Result:=0; Exit; end;

    GetMem(mem, len+1);
    try
        StrLCopy(mem, st, len);
        (mem+len)^ := #0;
        Result := sig * StrToFloat(string(mem));
    finally
        FreeMem(mem);
    end;
end;


function GetToken(const delimiter: String; var str: string): String;
var
    i: Integer;
begin
    i := JPosEx(delimiter, str,1);
    if i=0 then
    begin
        Result := str;
        str := '';
        Exit;
    end;
    Result := Copy(str, 1, i-1);
    Delete(str,1,i + Length(delimiter) -1);
end;

{HTML ���� �^�O����菜��}
function DeleteTag(const html: string): String;
var
  i: Integer;
  txt: String;
  TagIn: Boolean;
begin
    txt := Trim(html);
    if txt = '' then Exit;

    i := 1;
    Result := '';

    TagIn := False;
    while i <= Length(txt) do
    begin

        if txt[i] in SysUtils.LeadBytes then
        begin
            if TagIn=False then
            begin
                Result := Result + Copy(txt,i,2);
            end;
            Inc(i,2);
            Continue;
        end;
        case txt[i] of
            '<': //TAG in
            begin
                TagIn := True;
                Inc(i);
            end;
            '>': //TAG out
            begin
                TagIn := False;
                Inc(i);
            end;
            else
            begin
                if TagIn then
                begin // to skip
                    Inc(i);
                end else
                begin
                    Result := Result + txt[i];
                    Inc(i);
                end;
            end;
        end;

    end;
end;

{HTML�̎w��^�O�ň͂�ꂽ�����𔲂��o��}
function GetTag(var html:string; tag: string): string;
var
  p, pp, pFrom, pEnd: PChar;
  nest, len: Integer;
  s: string;

  function getTagName(var p: PChar): string;
  begin
    Result := '';
    while p^ <> #0 do
    begin
      if p^ in LeadBytes then
      begin
        Result := Result + p^ + (p+1)^;
        Inc(p,2);
      end else
      begin
        if p^ in ['/', 'A'..'Z','a'..'z','0'..'9','_','-'] then
        begin
          Result := Result + p^; Inc(p);
        end else
          Break;
      end;
    end;
  end;

  procedure skipToChar(ch: Char; var p: PChar);
  begin
    while p^ <> #0 do
    begin
      if p^ = ch then
      begin
        Inc(p);
        break;
      end;
      if p^ in LeadBytes then Inc(p,2) else Inc(p);
    end;
  end;

  procedure skipTagEnd(var p: PChar);
  begin
    while p^ <> #0 do
    begin
      if p^ = '>' then
      begin
        Inc(p);
        Break;
      end else
      if p^ = '"' then
      begin
        Inc(p); skipToChar('"', p);
      end else
      if p^ = '''' then
      begin
        Inc(p); skipToChar('''', p);
      end else
      if p^ in LeadBytes then Inc(p,2) else Inc(p);
    end;
  end;

begin
  // �^�O��啶���ɐ؂肻�낦��B�^�O�L���͍폜����
  tag := UpperCase(tag);
  tag := JReplace(tag, '<','', True);
  tag := JReplace(tag, '>','', True);

  // �^�O�̎n�܂��T��
  p := PChar(html);
  nest := 0;
  pFrom := nil;
  while p^ <> #0 do
  begin
    if p^ in LeadBytes then
    begin
      Inc(p,2); Continue;
    end;
    if p^ <> '<' then begin Inc(p); Continue; end;
    pp := p;
    Inc(pp);
    s := getTagName(pp);
    skipTagEnd(pp);
    if UpperCase(s) = tag then
    begin
      pFrom := p; // �^�O�� < �̑O
      nest := 1;
      Break;
    end;
    p := pp;
  end;
  if nest=0 then
  begin
    Result := '';
    html := '';
    Exit;
  end;

  // �^�O�̏I����T��
  p := pp;
  pEnd := nil;
  while p^ <> #0 do
  begin
    if p^ in LeadBytes then
    begin
      Inc(p,2); Continue;
    end;
    if p^ <> '<' then begin Inc(p); Continue; end;
    Inc(p);
    s := getTagName(p);
    skipTagEnd(p);

    // �^�O�̃l�X�g�����o
    if UpperCase(s) = tag then
    begin
      Inc(nest);
      Continue;
    end;

    // �^�O�̏I�[�����o
    if (UpperCase(s) = '/'+tag) then
    begin
      Dec(nest);
      if nest <= 0 then
      begin
        pEnd := p;
        Break;
      end;
    end;
  end;
  if pEnd = nil then pEnd := p;

  // �؂��茋��
  len := (pEnd - pFrom);
  SetLength(Result, len);
  StrLCopy(PChar(Result), pFrom, len);

  // html �̎c����Z�b�g
  html := string( PChar( pEnd ) );
end;
function GetTags(html:string; tag: string): string;
var
    s: string;
begin
    Result := '';
    while html <> '' do
    begin
        s := GetTag(html, tag);
        if s<>'' then
            Result := Result + s + #13#10;
    end;
end;

function GetAbsolutePath(soutai, base: string; Delimiter: Char): string;
var
  slSoutai, slBase: TStringList;
  rel, s: string;
  i: Integer;
begin
  // �s�v�̏ꍇ
  if Delimiter = '/' then
  begin
    i := Pos('/', soutai);
    if Copy(soutai,i,2) = '//' then
    begin
      Result := soutai; Exit;
    end;
  end else
  begin
    if Copy(soutai, 2,2) = ':\' then
    begin
      Result := soutai; Exit;
    end;
  end;

  slSoutai := SplitChar(Delimiter, soutai);
  slBase   := SplitChar(Delimiter, base);

  while (slSoutai.Count >= 1) or (slBase.Count >= 1) do
  begin
    rel := slSoutai.Strings[0];
    if rel = '.' then
    begin
      slSoutai.Delete(0);Continue;
    end else
    if rel = '..' then
    begin
      slSoutai.Delete(0);
      slBase.Delete(slBase.Count-1);
    end else
    begin
      Break;
    end;
  end;

  Result := '';
  for i := 0 to slBase.Count - 1 do
  begin
    s := slBase.Strings[i];
    Result := Result + s + Delimiter ;
  end;
  for i := 0 to slSoutai.Count - 1 do
  begin
    s := slSoutai.Strings[i];
    Result := Result + s + Delimiter;
  end;
  if Copy(Result, Length(Result), 1) = Delimiter then
  begin
    System.Delete(Result, Length(Result), 1);
  end;
end;

function InsertYenComma(const yen: string): string;
begin
    if Pos('.',yen)=0 then
    begin
        Result := FormatCurr('#,##0', StrToValue(yen));
    end else
    begin
        Result := FormatCurr('#,##0.00', StrToValue(yen));
    end;
end;

function HtmlColorToColorCode(s: string): Integer;
var
  r,g,b: string;
begin
  Result := -1;
  s := Trim(UpperCase(s));
  if s='' then Exit;
  if s[1] <> '#' then
  begin
    Result := StrToIntDef(s,-1); Exit;
  end;
  // 1234567
  // #RRGGBB
  r := Copy(s, 2, 2);
  g := Copy(s, 4, 2);
  b := Copy(s, 6, 2);
  try
    Result := RGB(StrToInt('$'+r), StrToInt('$'+g), StrToInt('$'+b));
  except
    Result := -1;
  end;
end;

function ColorCodeToHtmlColor(c: Integer): string;
var
  r,g,b: Byte;
begin
  // COL -> HTML
  // B G R
  r := c and $FF;
  g := BYTE( (c and $FF00) shr 8 );
  b := BYTE( (c and $FF0000) shr 16);
  Result := '#'+IntToHex(r,2)+IntToHex(g,2)+IntToHex(b,2); 
end;

function RomajiToKana(romaji: String): String;
const
    kana_list = 'k,�����,s,�����,t,�����,n,�����,h,�����,m,�����,y,2� � � ��� ,r,�����,w,2� ��� ��� ,'+
    'g,2�޷޸޹޺�,z,2�޼޽޾޿�,d,2����������,b,2����������,p,2����������,'+
    'q,2����� ����,f,2̧̨� ̪̫,j,3�ެ�� �ޭ�ު�ޮ,l,�����,x,�����,c,�����,'+
    'v,3�ާ�ި�� �ު�ޫ,f,�����'+
    'ky,2����������,sy,2����������,ty,2����������,ny,2ƬƨƭƪƮ,hy,2ˬ˨˭˪ˮ,'+
    'my,2ЬШЭЪЮ,by,3�ެ�ި�ޭ�ު�ޮ,cy,2����������,ch,2��� ������,sh,2��� ������';
var
    p: PChar;
    siin: string;
    siin_s, siin_k: array [0..50] of string;

    function GetBoinNo(c: Char): Integer;
    begin
        case c of
        'a': Result := 0;
        'i': Result := 1;
        'u': Result := 2;
        'e': Result := 3;
        'o': Result := 4;
        else Result := 0;
        end;
    end;

    function GetSiinCh(s: string; c: Char): string;
    var i,len: Integer;
    begin
        Result := '';
        if s='' then Exit;
        i := GetBoinNo(c);
        if s[1] in ['1'..'9'] then
        begin
            len := StrToIntDef(s[1],1);
            Delete(s,1,1);
            Result := Trim(Copy(s, i*2+1, len));
        end else
        begin
            Result := s[i+1];
        end;
    end;

    procedure DecideChar(c: Char);
    var i:Integer;
    begin
        if siin = '' then begin
            Result := Result + Copy('�����',GetBoinNo(c)+1,1);
        end else
        begin
            for i:=0 to High(siin_k) do
            begin
                if siin = siin_s[i] then
                begin
                    Result := Result + GetSiinCh( siin_k[i], c);
                    Break;
                end;
            end;
        end;

    end;

    procedure getKanaList;
    var i: Integer; s,ss: string;
    begin
        ss := kana_list; i:=0;
        while ss<>'' do
        begin
            s := GetToken(',', ss);
            siin_s[i] := s;
            s := GetToken(',', ss);
            siin_k[i] := s;
            Inc(i);
        end;
    end;

begin
    Result := '';
    romaji := LowerCase(convToHalf(romaji));
    if romaji='' then Exit;

    getKanaList;

    siin := '';
    p := PChar(romaji);
    while p^ <> #0 do
    begin
        if p^='-' then
        begin
            Result := Result + '�';
            Inc(p); siin := '';
            Continue;
        end else
        if p^ in ['a','i','u','e','o'] then
        begin //�ꉹ�Ȃ̂Ō���
            DecideChar(p^);
            Inc(p);
            siin := '';
            Continue;
        end else
        if p^ in ['a'..'z'] then
        begin
            if (siin='n')and(p^<>'y') then
            begin
                Result := Result + '�';
                siin := p^;
                Inc(p);
                Continue;
            end;
            if Copy(siin,Length(siin),1)=p^ then
            begin
                Inc(p);
                Result := Result + '�';
                Continue;
            end;
            siin := siin + p^;
            Inc(p);
        end else
        begin //�L�������Ȃ�
            Result := Result + p^;
            Inc(p);
        end;
    end;

end;

{� ���m�� �̂悤�ȍs���̔��p�J�i���폜���ĕԂ�}
function TrimLeftKana(str: string): string;
begin
    Result := '';
    if str='' then Exit;

    if (str[1] in ['�'..'�'])and(Copy(str,2,1)=' ') then
    begin
        Delete(str,1,1);
    end;
    Result := Trim(str);
end;

function JPosEx(const sub, str:string; idx:Integer): Integer;
var
  len_sub, len_str: Integer;
  p, pSub, pStart: PChar;
begin
  Result  := 0;
  if (sub = '')or(str = '') then Exit;

  len_sub := Length(sub);
  len_str := Length(str);
  if idx > len_str then Exit; // ������̒������C���f�b�N�X�����ɂ���ꍇ�͔�����

  // �P��������v��T�����߂Ƀ|�C���^���擾
  p := PChar(str);
  pStart := p;
  pSub := PChar(sub);

  // idx �� �|�C���^��i�߂�
  Dec(idx);
  while idx > 0 do
  begin
    if p^ in LeadBytes then
    begin
      Inc(p, 2); Dec(idx, 2);
    end else
    begin
      Inc(p); Dec(idx);
    end;
  end;

  // �J��Ԃ�����
  try
    while p^ <> #0 do
    begin
      if StrLComp(p, pSub, len_sub) = 0 then
      begin
        Result := (p - pStart) + 1;
        Break;
      end;
      if p^ in LeadBytes then Inc(p, 2) else Inc(p);
    end;
  except
    raise Exception.Create('������̌������ɃG���[�B'); 
  end;
end;

function JReplace(const Str, oldStr, newStr:string; repAll:Boolean): string;
var
    i, idx:Integer;
begin
    Result := Str;
    // ****
    i := JPosEx(oldStr, Str, 1);
    if i=0 then Exit;
    Delete(result, i, Length(oldStr));
    Insert(newStr, result, i);
    idx := i + Length(newStr);
    if repAll = False then Exit;
    // *** Loop
    while True do
    begin
        i := JPosEx(oldStr, result, idx);
        if i=0 then Exit;
        Delete(result, i, Length(oldStr));
        Insert(newStr, result, i);
        idx := i + Length(newStr);
    end;
end;

//�w��ڂ�oldStr���AnewStr�ɒu������
function JReplaceCnt(const Str, oldStr, newStr:string; Index: Integer): string;
var
  i, idx:Integer;
  p, pp: PChar;
begin
  idx := 0;
  p := PChar(str);
  pp := p;
  while p^ <> #0 do
  begin
    if StrLComp(p, PChar(oldStr), Length(oldStr)) = 0 then
    begin
      Inc(idx);
      if idx = Index then
      begin
        i := (p - pp);
        Result := Copy(Str, 1, i); // �O������
        Result := Result + newStr; // �u������
        Result := Result + Copy(Str, 1 + i + Length(oldStr), Length(Str));
        Exit;
      end;
      Inc(p, Length(oldStr));
    end else
    begin
      if p^ in LeadBytes then
        Inc(p,2)
      else
        Inc(p);
    end;
  end;
  Result := Str;
end;

function JReplaceEx(const Str, oldStr, newStr:string; repAll:Boolean; useCase:Boolean): string;
var
    i, idx:Integer;
    oldStrFind: string;
    strFind: string;
begin
    Result := Str;
    oldStrFind := UpperCaseEx(oldStr);
    strFind := UpperCaseEx(Result);
    // ****
    i := JPosEx(oldStrFind, strFind, 1);
    if i=0 then Exit;
    Delete(result, i, Length(oldStr));
    Insert(newStr, result, i);
    idx := i + Length(newStr);
    if repAll = False then Exit;
    // *** Loop
    while True do
    begin
        oldStrFind := UpperCaseEx(oldStr);
        strFind := UpperCaseEx(Result);
        i := JPosEx(oldStrFind, strFind, idx);
        if i=0 then Exit;
        Delete(result, i, Length(oldStr));
        Insert(newStr, result, i);
        idx := i + Length(newStr);
    end;
end;


{LCMapString-------------------------------------------------------------------}
function LCMapStringEx(const str: string; MapFlag: DWORD): string;
var
    pDes: PChar;
    len,len2: Integer;
begin
    if str='' then begin Result := ''; Exit; end;
    len  := Length(str);
    len2 := len*2+2;
    GetMem(pDes, len2);//half -> full
    FillChar( pDes^, len2, 0 );
    LCMapString( LOCALE_SYSTEM_DEFAULT, MapFlag, PChar(str), len, pDes, len2-1);
    Result := string( pDes );
end;
function LCMapStringExHalf(const str: string; MapFlag: DWORD): string;
var
    pDes: PChar;
    len,len2: Integer;
begin
    if str='' then begin Result := ''; Exit; end;
    len  := Length(str);
    len2 := len+2;
    GetMem(pDes, len2);
    FillChar( pDes^, len2, 0 );
    LCMapString( LOCALE_SYSTEM_DEFAULT, MapFlag, PChar(str), len, pDes, len2-1);
    Result := string( pDes );
end;
function convToFull(const str: string): string;
begin
    Result := LCMapStringEx( str, LCMAP_FULLWIDTH );
end;

function convToHalf(const str: string): string;
begin
    Result := LCMapStringEx( str, LCMAP_HALFWIDTH );
end;
{�Ђ炪�ȁE�J�^�J�i�̕ϊ�}
function convToHiragana(const str: string): string;
begin
    Result := LCMapStringEx( str, LCMAP_HIRAGANA );
end;
function convToKatakana(const str: string): string;
begin
    Result := LCMapStringEx( str, LCMAP_KATAKANA );
end;
function ConvToHurigana(const str: string): string;
var
  hIMC: THandle;    // ���̓R���e�L�X�g�n���h��
  hKL: THandle;    // �L�[�{�[�h���C�A�E�g�n���h��
  lngSize: Integer; // �ϊ���o�b�t�@�T�C�Y
  lngOffset: Integer;// �ϊ���������I�t�Z�b�g�A�h���X
  byCandiateArray: array of Byte; // �ϊ����ʃo�b�t�@
  CandiateList: TCANDIDATELIST;
  osvi: TOSVERSIONINFO;
  w: WideString;
begin
  Result := '';
  if str = '' then Exit; //�󕶎���̏ꍇ�͏������Ȃ�

  // OS����
  osvi.dwOSVersionInfoSize := sizeof(osvi);
  GetVersionEx(osvi);

  // IME �R���e�L�X�g�擾
  hIMC := ImmGetContext(Application.Handle);
  hKL := GetKeyboardLayout(0);

  if osvi.dwPlatformId = VER_PLATFORM_WIN32_NT then
  begin
    //WindowsNT�n:SJIFT-JIS�̂܂�
    lngSize := ImmGetConversionListA(hKL, hIMC, PChar(str), nil, 0, GCL_REVERSECONVERSION);
    if lngSize > 0 Then
    begin
      SetLength(byCandiateArray, lngSize);
      // �ϊ����ʂ��擾
      ImmGetConversionList(hKL, hIMC, PChar(str), @byCandiateArray[0],
                    lngSize, GCL_REVERSECONVERSION);
      // �o�b�t�@���e���Q�Ƃ��邽�ߍ\���̂ɃR�s-
      Move(byCandiateArray[0], CandiateList, sizeof(CandiateList));
      if CandiateList.dwCount > 0 then
      begin
        // �擪���̃I�t�Z�b�g�擾
        lngOffset := CandiateList.dwOffset[1];
        // '"�ӂ肪��"�擾
        Result := PChar( @byCandiateArray[lngOffset] );
      end;
    end;
  end else
  begin
    //Windows95�n:�V�t�gJIS�ɕϊ�
    //Windows98�ł� ImmGetConversionListA API �� Shift-JIS��Unicode �̕ϊ��Ɏg���邱�Ƃ��������܂����B�_�O�Z�O�^
    //�i"��"�͂��܂��܁A���̕����̓_���ł�����{���͎g���܂���B�Ȃ��A�ϊ��ɂ� MultiByteToWideChar API ���p�ӂ���Ă��܂��B�j
    //Windows 2000 ���}�g���Ȃ̂ɔ�� Windows98 �͖{���g��Ȃ��Ǝv���� ImmGetConversionListW �łȂ���Εϊ��ł��܂���B
    //����ɓn���̂� Shift-JIS �Ŗ߂��Ă���̂� Unicode�B�}�C�N���\�t�g�̌����ꕔ�T�|�[�g�Ƃ͂����������ƂȂ�ł��傤���H
    lngSize := ImmGetConversionListA(hKL, hIMC, PChar(str), nil, 0, GCL_REVERSECONVERSION);
    if lngSize > 0 Then
    begin
      SetLength(byCandiateArray, lngSize);
      // �ϊ����ʂ��擾 in: SJIS out: UNICODE
      ImmGetConversionList(hKL, hIMC, PChar(str), @byCandiateArray[0],
                    lngSize, GCL_REVERSECONVERSION);
      // �o�b�t�@���e���Q�Ƃ��邽�ߍ\���̂ɃR�s-
      Move(byCandiateArray[0], CandiateList, sizeof(CandiateList));
      if CandiateList.dwCount > 0 then
      begin
        // �擪���̃I�t�Z�b�g�擾
        lngOffset := CandiateList.dwOffset[1];
        // '"�ӂ肪��"�擾 --- �߂�� UNICODE �������� wideString �ɃL���X�g
        w := PWideChar( @byCandiateArray[lngOffset] );
        Result := w; // Delphi �����͊y�`�������ϊ��̊�
      end;
    end;
  end;
  //�J��
  ImmReleaseContext(Application.Handle, hIMC);
end;

{�}���`�o�C�g���l�������啶���A��������}
function LowerCaseEx(const str: string): string;
begin
    Result := LCMapStringExHalf( str, LCMAP_LOWERCASE );
end;
function UpperCaseEx(const str: string): string;
begin
    Result := LCMapStringExHalf( str, LCMAP_UPPERCASE );
end;
function UpperCaseOne(const str: string): string;//�ꕶ���ڂ����啶��
var
  s: WideString; c: WideString;
begin
  if Length(str) > 0 then
  begin
    s := LowerCaseEx(str);
    c := s[1];
    c := UpperCase(c);
    s[1] := c[1];
    Result := s;
  end else
  begin
    Result := '';
  end;
end;

function convToHalfAnk(const str: string): string;
var
    p,pr: PChar;
    s: string;
    i: Integer;
const
    HALF_JOUKEN = '�O�P�Q�R�S�T�U�V�W�X'+
        '����������������������������������������������������'+
        '�`�a�b�c�d�e�f�g�h�i�j�k�l�m�n�o�p�q�r�s�t�u�v�w�x�y'+
        '�I�h���������f�i�j���|���m�n�o�p�Q�^�����C�D���e�@';

begin
    SetLength(Result, Length(str)*2+1);//�Ƃ肠�����K���ȑ傫�����m��
    p  := PChar(str);
    pr := PChar(Result);

    while p^ <> #0 do
    begin
        if p^ in LeadBytes then
        begin
            s := p^ + (p+1)^;
            i := Pos(s, HALF_JOUKEN);
            if (i>0)and(((i-1)mod 2)=0) then //�������r���ŕ��f����Ă���̂�h�����߁Amod 2=0 �Ń`�F�b�N
            begin
                s := convToHalf(s);
                pr^ := s[1]; Inc(pr);
                Inc(p,2);
            end else
            begin
                pr^ := p^; Inc(pr); Inc(p);
                pr^ := p^; Inc(pr); Inc(p);
            end;
        end else
        begin // ���� ank
            //���p�J�^�J�i�͑S�p��(( 0xA0-0xDF ))
            if (#$A0 <= p^)and(p^ <= #$DF) then
            begin
              s := convToFull(p^);
              pr^ := s[1]; Inc(pr);
              pr^ := s[2]; Inc(pr);
              Inc(p);
            end else
            begin
              pr^ := p^ ; Inc(pr); Inc(p);
            end;
        end;
    end;
    pr^ := #0;
    Result := string(PChar(Result));
end;


{�g�[�N������}
{�g�[�N���؂�o���^��؂蕶������i�߂�}
function GetTokenChars(delimiter: TCharSet; var ptr:PChar): string;
begin
  Result := '';
  while ptr^ <> #0 do
  begin
    if ptr^ in LeadBytes then
    begin
      Result := Result + ptr^ + (ptr+1)^;
      Inc(ptr,2);
    end else
    begin
      if ptr^ in delimiter then
      begin
        Inc(ptr);
        Break;
      end;
      Result := Result + ptr^;
      Inc(ptr);
    end;
  end;
end;

function GetTokenPtr(delimiter: Char; var ptr:PChar): string;
begin
  Result := '';
  while ptr^ <> #0 do
  begin
    if ptr^ in LeadBytes then
    begin
      Result := Result + (ptr^) + (ptr+1)^;
      Inc(ptr,2);
    end else
    begin
      if ptr^ = delimiter then
      begin
        Inc(ptr);
        Break;
      end else
      begin
        Result := Result + ptr^;
        Inc(ptr);
      end;
    end;
  end;
end;

function SplitChar(delimiter: Char; str: string): TStringList;
var
  p: PChar; s: string;
begin
  Result := TStringList.Create ;
  p := PChar(str);
  while p^ <> #0 do
  begin
    s := GetTokenPtr(delimiter, p);
    Result.Add(s); 
  end;
end;

function IsHiragana(const str: string): Boolean;
var code: Integer;
begin
    Result := False;
    if Length(str)<2 then Exit;
    code := (Ord(str[1])shl 8) + Ord(str[2]);
    if ($82A0 <= code)and(code <= $833E) then Result := True;
end;

function IsKatakana(const str: string): Boolean;
var code: Integer;
begin
    Result := False;
    if Length(str)<2 then Exit;
    code := (Ord(str[1])shl 8) + Ord(str[2]);
    if ($8340 <= code)and(code <= $839D) then Result := True;
end;

function IsNumStr(const str: string): Boolean; //�����񂪑S�Đ��l���ǂ������f
var
    p: PChar;
begin
    Result := False;
    p := PChar(str);

    if not (p^ in ['0'..'9']) then Exit;
    Inc(p);

    while p^ <> #0 do
    begin
        if p^ in ['0'..'9','e','E','+','-','.'] then //���������_�ɑΉ�
            Inc(p)
        else
            Exit;
    end;
    Result := True;
end;

end.
