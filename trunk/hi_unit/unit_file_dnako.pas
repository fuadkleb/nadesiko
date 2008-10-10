unit unit_file_dnako;
//------------------------------------------------------------------------------
// �t�@�C�����o�͂Ɋւ���ėp�I�ȃ��j�b�g(mini)
// [�쐬] �N�W����s��
// [�A��] http://kujirahand.com
// [���t] 2004/07/28
//
interface

uses
  Windows, SysUtils, hima_types;

type
  TWindowState = (wsNormal, wsMinimized, wsMaximized);

// ������Ƀt�@�C���̓��e��S���J��
function FileLoadAll(Filename: string): string;

// ������Ƀt�@�C���̓��e��S����������
procedure FileSaveAll(s, Filename: string);

implementation

uses
  unit_windows_api, unit_string;

// ������Ƀt�@�C���̓��e��S���J��
function FileLoadAll(Filename: string): string;
var
  f: THandle;
  size, rsize: DWORD;
begin
  // open
  f := CreateFile(PChar(Filename), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,0);
  if f = INVALID_HANDLE_VALUE then
    raise EInOutError.Create('�t�@�C��"' + Filename + '"���J���܂���B' + GetLastErrorStr);
  try
    // set pointer
    SetFilePointer(f, 0, nil, FILE_BEGIN); // ���߂���[���̈ʒu��

    // read
    size := GetFileSize(f, nil); // 4G �ȉ�����
    SetLength(Result, size);
    if not ReadFile(f, Result[1], size, rsize, nil) then
    begin // ���s
      raise EInOutError.Create('�t�@�C��"' + Filename + '"�̓ǂݎ��Ɏ��s���܂����B' + GetLastErrorStr);
    end;
  finally
    // close
    CloseHandle(f);
  end;
end;

// ������Ƀt�@�C���̓��e��S����������
procedure FileSaveAll(s, Filename: string);
var
  f: THandle;
  size, rsize: DWORD;
begin
  // open
  f := CreateFile(PChar(Filename), GENERIC_WRITE, 0, nil,
    CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,0);
  if f = INVALID_HANDLE_VALUE then
    raise EInOutError.Create('�t�@�C��"' + Filename + '"���J���܂���B' + GetLastErrorStr);
  try
    // set pointer
    SetFilePointer(f, 0, nil, FILE_BEGIN); // ���߂���[���̈ʒu��

    // write
    size := Length(s);
    if size > 0 then
    begin
      if not WriteFile(f, s[1], size, rsize, nil) then
      begin // ���s
        raise EInOutError.Create('�t�@�C��"' + Filename + '"�̓ǂݎ��Ɏ��s���܂����B' + GetLastErrorStr);
      end;
    end;
  finally
    // close
    CloseHandle(f);
  end;
end;

end.
