unit unit_text_file;

interface

uses
  SysUtils, Classes;

type
  // バッファリングのあるFileStream
  TKTextFileStream = class(TFileStream)
  private
    FBuf          : string;
    FReadBufSize  : Integer;
    FEOF          : Boolean;
    preEOF        : Boolean;
  public
    constructor Create(const FileName: string; Mode: Word);
    destructor Destroy; override;
    function ReadLn: string;
    property ReadBufSize: Integer read FReadBufSize write FReadBufSize;
    property EOF: Boolean read FEOF;
  end;

implementation

{ TKTextFileStream }

constructor TKTextFileStream.Create(const FileName: string; Mode: Word);
begin
  inherited Create(FileName, Mode);
  FReadBufSize := 4096 * 2; // 適当
  FBuf := ''; // バッファなし
  FEOF := False;
  preEOF := False;
end;

destructor TKTextFileStream.Destroy;
begin
  inherited;
end;

function TKTextFileStream.ReadLn: string;
var
  i: Integer;
  tmp, retcode: string;

  procedure ReadNewBuf;
  var sz: Integer; prebuf: string;
  begin
    // 新規バッファサイズを確保
    SetLength(FBuf, FReadBufSize);
    // バッファいっぱいにデータを読む
    sz := Self.Read(FBuf[1], FReadBufSize);


    if sz < FReadBufSize then
    begin
      preEof := True;
    end else
    begin
      preEof := False;
    end;
    if sz > 0 then
    begin
      SetLength(FBuf, sz);
      if (sz > 1)and(FBuf[sz] in [#13,#10]) then // 境界に改行があればさらにバッファを読む
      begin
        SetLength(prebuf, FReadBufSize);
        sz := Self.Read(prebuf[1], FReadBufSize);
        if sz > 0 then
        begin
          SetLength(prebuf, sz);
          FBuf := FBuf + prebuf;
        end;
      end;
    end else
    begin
      FBuf := '';
    end;
  end;

  function findRetCode(s: string): Integer;
  var
    i: Integer;
  begin
    Result := 0;
    i := 1;
    while (i <= Length(s)) do
    begin
      if s[i] in LeadBytes then
      begin
        Inc(i,2); Continue;
      end else
      if s[i] in [#13,#10] then
      begin
        Result := i;
        if Copy(s,i,2) = #13#10 then
        begin
          retcode := #13#10;
        end else
        begin
          retcode := s[1];
        end;
        Break;
      end;
      Inc(i);
    end;
  end;

begin
  Result := ''; retcode := #13#10;
  if (Length(FBuf) <= 0) then
  begin
    // 新規バッファ読み取り
    ReadNewBuf;
  end;

  // バッファ内に改行があるか？
  i := findRetCode(FBuf);
  while (i = 0) do // バッファ内に改行がない
  begin
    // 新規バッファの読み取り
    tmp := FBuf; ReadNewBuf; FBuf := tmp + FBuf;
    i := findRetCode(FBuf);
    if (i = 0)and(preEOF)and(FBuf = '') then Break;
    if preEof then Break;
  end;
  // 改行まで切り取る
  if (i > 0) then
  begin
    // 改行の前までを得る
    Result := Result + Copy(FBuf, 1, (i-1));
    // 改行の後までバッファから削除
    FBuf := Copy(FBuf, i + Length(retcode), Length(FBuf));
  end else
  begin
    Result := FBuf; // 全部
    FBuf   := '';
  end;

  if preEOF and (FBuf = '') then
  begin
    FEOF := True;
  end;
end;

end.
