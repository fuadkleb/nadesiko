unit hima_variable_lib;

// �Ђ܂Q���L�̌^�ł��� PHiValue �Ɋւ��鏈�����܂Ƃ߂�����

interface

uses
  hima_variable, hima_variable_ex;


// ������ str �� ������ splitter �ŕ����Ĕz��`���� PHiValue �ɕԂ�
function hi_split(str, splitter: PHiValue): PHiValue;

implementation

uses hima_string, unit_string;

// ������ str �� ������ splitter �ŕ����Ĕz��`���� PHiValue �ɕԂ�
function hi_split(str, splitter: PHiValue): PHiValue;
var
  s, kugiri, ss: string; sp, sp_last: PAnsiChar;
  p: PHiValue;
begin
  s := hi_str(str);
  kugiri := hi_str(splitter);
  sp := PAnsiChar(s);
  sp_last := sp + Length(s);

  // �z��Ƃ��ĕԂ�
  Result := hi_var_new;
  hi_ary_create(Result);

  // ��؂菈��
  while sp < sp_last do
  begin
    ss := getTokenStr(sp, kugiri);
    p := hi_var_new;
    hi_setStr(p, ss);
    hi_ary(Result).Add(p);
  end;
end;

end.
