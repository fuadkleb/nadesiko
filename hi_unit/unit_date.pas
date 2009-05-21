unit unit_date;

interface
uses
  SysUtils, DateUtils, unit_string, Variants;



{TDateTime���A�a��ɕϊ�����}
function DateToWareki(d: TDateTime): AnsiString;
// ������(���t)��a��ɕϊ�����
function DateToWarekiS(d: AnsiString): AnsiString;
{���t�̉��Z ex)�R������ IncDate('2001/10/30','0/3/0') �O���O IncDate('2001/1/1','-0/0/3')}
function IncDate(BaseDate: TDateTime; AddDate: AnsiString): TDateTime;
{���Ԃ̉��Z ex)�R���Ԍ� IncTime('15:0:0','3:0:0') �O�b�O IncTime('12:45:0','-0:0:3')}
function IncTime(BaseTime: TDateTime; AddTime: AnsiString): TDateTime;
function StrToDateEx(str: AnsiString): TDateTime;
{����A�a��ɑΉ��������t�ϊ��p�֐�}
function StrToDateStr(str: AnsiString): AnsiString;

implementation

{����A�a��ɑΉ��������t�ϊ��p�֐�}
function StrToDateStr(str: AnsiString): AnsiString;
begin
    Result:='';
    if str='' then Exit;
    Result := FormatDateTime(
        'yyyy/mm/dd',
        StrToDateEx(str)
    );
end;

function StrToDateEx(str: AnsiString): TDateTime;
begin
    Result := Now;
    str := convToHalf(str);
    if str='' then Exit;
    if Pos('.',str)>0 then str := JReplace(str,'.','/');
    Result := VarToDateTime(str);
end;

{���Ԃ̉��Z ex)�R���Ԍ� IncTime('15:0:0','3:0:0') �O�b�O IncTime('12:45:0','-0:0:3')}
function IncTime(BaseTime: TDateTime; AddTime: AnsiString): TDateTime;
var
    flg: AnsiString;
    hh,nn,ss: Word;
begin
    // �f���t�@�C�̕W���֐����g���悤�ɕύX 2003/2/19
    // ���������������f
    flg := Copy(AddTime,1,1);
    if (flg='-')or(flg='+') then Delete(AddTime, 1,1);

    hh := StrToIntDef(getToken_s(AddTime,':'),0);
    nn := StrToIntDef(getToken_s(AddTime,':'),0);
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
function IncDate(BaseDate: TDateTime; AddDate: AnsiString): TDateTime;
var
    flg: AnsiString;
    yy,mm,dd: Word;
begin
    // �f���t�@�C�̕W���֐����g���悤�ɕύX 2003/2/19
    // �������������̔��f
    flg := Copy(AddDate,1,1);
    if (flg='-')or(flg='+') then Delete(AddDate, 1,1);

    // �������t�𕪉�����
    yy := StrToIntDef(getToken_s(AddDate,'/'),0);
    mm := StrToIntDef(getToken_s(AddDate,'/'),0);
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


const
  MEIJI  = 1868; //* �C�� 2003/09/28
  TAISYO = 1912;
  SYOWA  = 1926;
  HEISEI = 1989;

{TDateTime���A�a��ɕϊ�����}
function DateToWareki(d: TDateTime): AnsiString;
var y, yy, mm, dd: Word; sy: AnsiString;
begin
    DecodeDate(d, yy, mm, dd);
    if ((MEIJI<=yy)and(yy<TAISYO))or((TAISYO=yy)and((mm<=6)or((mm=7)and(dd<=30)))) then
    begin
        y := yy-MEIJI+1;
        if y=1 then sy := '���N' else sy := IntToStr(y)+'�N';
        Result := Format('����'+sy+'%d��%d��',[mm,dd]);
    end else
    if ((TAISYO<=yy)and(yy<SYOWA))or((SYOWA=yy)and((mm<=11)or((mm=12)and(dd<=25)))) then
    begin
        y := yy-TAISYO+1;
        if y=1 then sy := '���N' else sy := IntToStr(y)+'�N';
        Result := Format('�吳'+sy+'%d��%d��',[mm,dd]);
    end else
    if ((SYOWA<=yy)and(yy<HEISEI))or((HEISEI=yy)and((mm=1)and(dd<=7))) then
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

function DateToWarekiS(d: AnsiString): AnsiString;
var y, yy: Word; sy: AnsiString;
begin
    // �P���ɐ�������w�肳�ꂽ������
    d := convToHalf(d);
    if IsNumber(d) then
    begin
      yy := StrToIntDef(d, 0);
      if yy < MEIJI then begin Result := ''; Exit; end;
    end else
    begin
      Result := DateToWareki(StrToDateEx(d)); Exit;
    end;

    if (MEIJI<=yy)and(yy<TAISYO) then
    begin
        y := yy-MEIJI+1;
        if y=1 then sy := '���N' else sy := IntToStr(y)+'�N';
        Result := '����'+sy;
    end else
    if (TAISYO<=yy)and(yy<SYOWA) then
    begin
        y := yy-TAISYO+1;
        if y=1 then sy := '���N' else sy := IntToStr(y)+'�N';
        Result := '�吳'+sy;
    end else
    if (SYOWA<=yy)and(yy<HEISEI) then
    begin
        y := yy-SYOWA+1;
        if y=1 then sy := '���N' else sy := IntToStr(y)+'�N';
        Result := '���a'+sy;
    end else
    if (HEISEI<=yy) then
    begin
        y := yy-HEISEI+1;
        if y=1 then sy := '���N' else sy := IntToStr(y)+'�N';
        Result := '����'+sy;
    end;
end;

end.