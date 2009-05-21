unit dll_plugin_helper;

interface
uses
  windows, SysUtils, dnako_import, dnako_import_types;


// 関数が正しく登録できるかチェックする
procedure _checkTag(tag, name: DWORD);
// 関数を登録する
procedure AddFunc(name, argStr: string; tag: Integer; func: THimaSysFunction;
  kaisetu, yomigana: string; IzonFiles: string = '');
// 文字列を登録する
procedure AddStrVar(name, value: string; tag: Integer; kaisetu,
  yomigana: string);
// 整数を登録する
procedure AddIntVar(name: string; value, tag: Integer; kaisetu,
  yomigana: string);
// セッター・ゲッターをセットする
procedure SetSetterGetter(name, setter, getter: string; tag: DWORD; desc, yomi: string);

//-----------------------------------------------------
// ファイルの有無をチェック
function CheckFileExists(var fname: string): Boolean;
// エラー文字列を取得
function nako_getErrorStr: string;
//-----------------------------------------------------
// 引数を簡単に取得する
function getArg(h: DWORD; Index: Integer; UseHokan: Boolean = False): PHiValue;
function getArgInt(h: DWORD; Index: Integer; UseHokan: Boolean = False): Integer;
function getArgIntDef(h: DWORD; Index: Integer; Def:Integer): Integer;
function getArgStr(h: DWORD; Index: Integer; UseHokan: Boolean = False): string;
function getArgBool(h: DWORD; Index: Integer; UseHokan: Boolean = False): Boolean;
function getArgFloat(h: DWORD; Index: Integer; UseHokan: Boolean = False): HFloat;
// 動詞の語尾変化を削除
function DeleteGobi(key: string): string;
// 実行ファイルに埋め込まれたファイルを取りだす
function _getEmbedFile(var f:string): Boolean;


implementation

function _getEmbedFile(var f:string): Boolean;
var
  path: string;
begin
  SetLength(path, 4096);
  if (nako_getEmbedFile(PChar(f), PChar(path), 4095)) then
  begin
    f := string(path);
    Result := True;
  end else
  begin
    Result := False;
  end;
end;

function nako_getErrorStr: string;
var
  len: Integer;
begin
  len := nako_getError(nil, 0);
  SetLength(Result, len + 1);
  nako_getError(PChar(Result), len);
  Result := PChar(Result);
end;

// 文字コードの範囲内かどうか調べる
function CharInRange(p: PChar; fromCH, toCH: string): Boolean;
var
  code: Integer;
  fromCode, toCode: Integer;
begin
  // 判別対象のコードを得る
  if p^ in LeadBytes then code := (Ord(p^) shl 8) + Ord((p+1)^) else code := Ord(p^);

  // 範囲初め
  if fromCH = '' then
  begin
    fromCode := 0;
  end else
  begin
    if fromCH[1] in LeadBytes then
      fromCode := (Ord(fromCH[1]) shl 8) + Ord(fromCH[2])
    else
      fromCode := Ord(fromCH[1]);
  end;

  // 範囲終わり
  if toCH = '' then
  begin
    toCode := $FCFC;
  end else
  begin
    if toCH[1] in LeadBytes then
      toCode := (Ord(toCH[1]) shl 8) + Ord(toCH[2])
    else
      toCode := Ord(toCH[1]);
  end;

  Result := (fromCode <= code)and(code <= toCode);
end;

// 動詞の語尾変化を削除
function DeleteGobi(key: string): string;
var p: PChar;
begin
  //key := HimaSourceConverter(0, key);
  p := PChar(key);

  if CharInRange(p, 'ぁ','ん') then // ひらがなから始まれば語尾を消さない
  begin
    Result := key;
    Exit;
  end;

  //
  Result := '';
  while p^ <> #0 do
  begin
    if p^ in LeadBytes then
    begin
      if not CharInRange(p, 'ぁ','ん') then Result := Result + p^ + (p+1)^;
      Inc(p, 2);
    end else
    begin
      Result := Result + p^;
      Inc(p);
    end;
  end;
end;
{//old
function DeleteGobi(key: string): string;
var
  p, pS: PChar;
  pp: PChar;
  s: string;
begin
  p := PChar(key); pS := p; pp := p;

  // ひらがな以外が最後に現れた位置(+1文字の所)を記録
  while p^ <> #0 do begin
    if p^ in LeadBytes then
    begin
      if False = CharInRange(p, 'ぁ','ん') then // ひらがな以外
      begin
        pp := p + 2;
      end;
      Inc(p,2);
    end else
    begin
      Inc(p);
      pp := p;
    end;
  end;

  // もし全部ひらがなだったら...
  if pp = pS then
  begin
    // 語尾の特定句を削除                     1234|5678|
    s := Copy(key, Length(key) - 4 + 1, 4); //ひま|する|
    //if Pos(s, 'する しろ') > 0 then
    if ((s='する')or(s='しろ'))and(key<>s) then
    begin
      Result := Copy(key,1,Length(key)-4);
    end else
      Result := key;
    Exit;
  end;

  // 最後にひらがな以外が出た場所まで得る
  Result := Copy(key, 1, (pp - pS));
end;
}

// 引数を簡単に取得する
function getArg(h: DWORD; Index: Integer; UseHokan: Boolean = False): PHiValue;
begin
  Result := nako_getFuncArg(h, Index);
  if (Result = nil)and(UseHokan) then
  begin
    Result := nako_getSore;
  end;
end;
function getArgInt(h: DWORD; Index: Integer; UseHokan: Boolean = False): Integer;
begin
  Result := hi_int(getArg(h, Index,UseHokan));
end;
function getArgIntDef(h: DWORD; Index: Integer; Def:Integer): Integer;
var p:PHiValue;
begin
  p := nako_getFuncArg(h, Index);
  if p = nil then
  begin
    Result := Def;
  end else
  begin
    Result := hi_int(p);
  end;
end;
function getArgStr(h: DWORD; Index: Integer; UseHokan: Boolean = False): string;
begin
  Result := hi_str(getArg(h, Index,UseHokan));
end;
function getArgBool(h: DWORD; Index: Integer; UseHokan: Boolean = False): Boolean;
begin
  Result := hi_bool(getArg(h, Index,UseHokan));
end;
function getArgFloat(h: DWORD; Index: Integer; UseHokan: Boolean = False): HFloat;
begin
  Result := hi_float(getArg(h, Index,UseHokan));
end;


// ファイルの有無をチェック
function CheckFileExists(var fname: string): Boolean;
var
  f: string;

  function chk(f: string): Boolean;
  begin
    Result := FileExists(f);
    if Result then
    begin
      fname := f;
    end;
  end;

  function path(f: string): string;
  begin
    if Copy(f,Length(f),1) <> '\' then
    begin
      Result := f + '\';
    end;
  end;

begin
  Result := True;

  // 絶対パス指定なら抜ける
  if (Pos(':\', fname) > 0)or(Pos('\\', fname) > 0) then
  begin
    Result := FileExists(fname);
    Exit;
  end;

  // curdir
  if chk(path(GetCurrentDir) + fname) then Exit;
  // bokan
  f := hi_str(nako_getVariable('母艦パス'));
  if chk(f + fname) then Exit;
  // bokan + lib
  if chk(f + 'lib\' + fname) then Exit;
  // apppath
  if chk(ExtractFilePath(ParamStr(0)) + fname) then Exit;
  // apppath + lib
  if chk(ExtractFilePath(ParamStr(0)) + 'lib\' + fname) then Exit;
  // plug-ins
  f := nako_getPluginsDir;
  if chk(f + fname) then Exit;
  
  // 最後まで見つからなかった
  Result := False;
end;

procedure AddFunc(name, argStr: string; tag: Integer; func: THimaSysFunction;
  kaisetu, yomigana: string; IzonFiles: string = '');
begin
  try
    _checkTag(tag, 0);
  except
    on e:Exception do
    begin
      raise;
      //raise Exception.Create('『'+name+'』(tag='+IntToStr(tag)+')が重複しています。');
    end;
  end;
  nako_addFunction2(PChar(name), PChar(argStr), func, tag, PChar(IzonFiles));
end;

procedure AddStrVar(name, value: string; tag: Integer; kaisetu,
  yomigana: string);
begin
  _checkTag(tag, 0);
  nako_addStrVar(PChar(name), PChar(value), tag);
end;

procedure AddIntVar(name: string; value, tag: Integer; kaisetu,
  yomigana: string);
begin
  _checkTag(tag, 0);
  nako_addIntVar(PChar(name), value, tag);
end;

// セッター・ゲッターをセットする
procedure SetSetterGetter(name, setter, getter: string; tag: DWORD; desc, yomi: string);
begin
  nako_addSetterGetter(PChar(name), PChar(setter), PChar(getter), tag);
end;

// 関数が正しく登録できるかチェックする
procedure _checkTag(tag, name: DWORD);
begin
  nako_check_tag(tag, name);
end;


end.

