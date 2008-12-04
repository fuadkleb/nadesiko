unit common_function;
// �e�v���W�F�N�g�Ŏg��������Ƃ����֐����W�߂����j�b�g
interface

uses
  Windows, SysUtils, imm;

function ImeStr2ImeMode(s: AnsiString): DWORD;

implementation

function ImeStr2ImeMode(s: AnsiString): DWORD;
begin
  s := Copy(s,1,7);
  if s = 'IME�I��' then
  begin
    Result := IME_CMODE_JAPANESE or IME_CMODE_FULLSHAPE;
  end else
  if s = 'IME�I�t' then
  begin
    Result := IME_CMODE_ALPHANUMERIC;
  end else
  if (s = 'IME�Ђ�')or(s = 'IME����') then
  begin
    Result := IME_CMODE_JAPANESE or IME_CMODE_FULLSHAPE;
  end else
  if (s = 'IME�J�^')or(s = 'IME�J�i') then
  begin
    Result := IME_CMODE_LANGUAGE or IME_CMODE_FULLSHAPE;
  end else
  if s = 'IME���p' then
  begin
    Result := IME_CMODE_LANGUAGE;
  end else
  begin
    Result := 0;
  end;
end;

end.
