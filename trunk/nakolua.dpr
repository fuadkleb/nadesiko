library nakolua;

uses
  Windows,
  SysUtils,
  dll_plugin_helper in 'hi_unit\dll_plugin_helper.pas',
  dnako_import in 'hi_unit\dnako_import.pas',
  dnako_import_types in 'hi_unit\dnako_import_types.pas',
  kuLuaUtils in 'component\luautils\kuLuaUtils.pas',
  LauxLib in 'component\luautils\LauxLib.pas',
  Lua in 'component\luautils\Lua.pas',
  LuaLib in 'component\luautils\LuaLib.pas',
  LuaUtils in 'component\luautils\LuaUtils.pas';

//------------------------------------------------------------------------------
// Lua���ɓo�^����֐�
//------------------------------------------------------------------------------
function nakolua_getVar(L: Plua_State): Integer; cdecl;
var
  res, vname: AnsiString;
  p: PHiValue;
begin
  vname := LuaToString(L, 1); // arg 1
  p := nako_getVariable(PAnsiChar(vname));
  if p = nil then
  begin
    lua_pushstring(L, '');
  end else
  begin
    res := hi_str(p);
    LuaPushString(L, res);
  end;
  Result := 1;              // �߂�l��1��
end;

function nakolua_setVar(L: Plua_State): Integer; cdecl;
var
  vname, value: AnsiString;
  p: PHiValue;
begin
  vname := LuaToString(L, 1); // arg 1
  value := LuaToString(L, 2); // arg 2
  p := nako_getVariable(PAnsiChar(vname));
  if p = nil then
  begin
    p := nako_var_new(PAnsiChar(vname));
  end;
  hi_setStr(p, value);
  Result := 0;              // �߂�l��0
end;

//------------------------------------------------------------------------------
// �o�^����֐�
//------------------------------------------------------------------------------
var _lua_loaded: Boolean = False;

procedure init_my_lua;
var
  dll: string;
begin
  if _lua_loaded = False then
  begin
    dll := 'lua5.1.dll';
    if not CheckFileExists(dll) then
      raise Exception.Create('lua5.1.dll������܂���B');
    Lua_LoadLibrary(dll);
    _lua_loaded := True;
  end;
  // library
  KLua.OpenLibs;
  // add function
  lua_register(KLua.Handle, 'nako_get', nakolua_getVar);
  lua_register(KLua.Handle, 'nako_set', nakolua_setVar);
end;

function procExecLua(h: DWORD): PHiValue; stdcall;
var
  src: string;
begin
  // (1) �����̎擾
  src := getArgStr(h, 0, True);

  // (2) ����
  init_my_lua;
  try
    KLua.DoString(src);
  except
    raise;
  end;
  // (3) �߂�l�̐ݒ�
  Result := nil; // �����^�̖߂�l���w�肷��
end;

function procGetLuaValue(h: DWORD): PHiValue; stdcall;
var
  r, v: string;
begin
  // (1) �����̎擾
  v := getArgStr(h, 0, True);

  // (2) ����
  init_my_lua;
  r := KLua.GetVarStr(v);
  
  // (3) �߂�l�̐ݒ�
  Result := hi_newStr(r); // �����^�̖߂�l���w�肷��
end;


//------------------------------------------------------------------------------
// �v���O�C���Ƃ��ĕK�v�Ȋ֐��ꗗ
//------------------------------------------------------------------------------
// �ݒ肷��v���O�C���̏��
const S_PLUGIN_INFO = 'Lua���C�u���� by �N�W����s��';

function PluginVersion: DWORD; stdcall;
begin
  Result := 2; //�v���O�C�����g�̃o�[�W����
end;

procedure ImportNakoFunction; stdcall;
begin
  // �֐���ǉ������
  //<����>
  //+Lua�g��(nakolua)
  //-Lua����
  AddFunc('LUA����','{=?}S��',7200,procExecLua,'Lua�̃v���O���������s����','LUA����','lua.dll');
  AddFunc('LUA�l','{=?}V��',7201,procGetLuaValue,'Lua�̕ϐ�V�̒l�𓾂ĕԂ�','LUA������','lua.dll');
  //</����>
end;

//------------------------------------------------------------------------------
// ���܂肫�������
function PluginRequire: DWORD; stdcall; //�Ȃł����v���O�C���o�[�W����
begin
  Result := 2;
end;
function PluginInfo(str: PChar; len: Integer): Integer; stdcall;
begin
  Result := Length(S_PLUGIN_INFO);
  if (str <> nil)and(len > 0) then
  begin
    StrLCopy(str, S_PLUGIN_INFO, len);
  end;
end;
procedure PluginInit(Handle: DWORD); stdcall;
begin
  dnako_import_initFunctions(Handle);
end;
function PluginFin: DWORD; stdcall;
begin
  Result := 0;
end;

//------------------------------------------------------------------------------
// �O���ɃG�N�X�|�[�g�Ƃ���֐��̈ꗗ(Delphi�ŕK�v)
exports
  ImportNakoFunction,
  PluginInfo,
  PluginVersion,
  PluginRequire,
  PluginInit,
  PluginFin;

begin
end.
