
///
/// dnako.dll の API を代入するもの
/// generated by DLL宣言抜き出しC.nako
///

	nako_resetAll = (void(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_resetAll");
	nako_free = (void(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_free");
	nako_load = (DWORD(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_load");
	nako_loadSource = (DWORD(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_loadSource");
	nako_run = (DWORD(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_run");
	nako_run_ex = (PHiValue(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_run_ex");
	nako_error_continue = (DWORD(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_error_continue");
	nako_getError = (DWORD(__stdcall*)(char*,int)) ::GetProcAddress( hDll,"nako_getError");
	nako_clearError = (void(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_clearError");
	nako_eval = (PHiValue(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_eval");
	nako_evalEx = (BOOL(__stdcall*)(char*,PHiValue*)) ::GetProcAddress( hDll,"nako_evalEx");
	nako_addFileCommand = (void(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_addFileCommand");
	nako_getVariable = (PHiValue(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_getVariable");
	nako_setVariable = (void(__stdcall*)(char*,PHiValue)) ::GetProcAddress( hDll,"nako_setVariable");
	nako_addFunction = (DWORD(__stdcall*)(char*,char*,THimaSysFunction,int)) ::GetProcAddress( hDll,"nako_addFunction");
	nako_addFunction2 = (DWORD(__stdcall*)(char*,char*,THimaSysFunction,int,char*)) ::GetProcAddress( hDll,"nako_addFunction2");
	nako_getFuncArg = (PHiValue(__stdcall*)(DWORD,int)) ::GetProcAddress( hDll,"nako_getFuncArg");
	nako_getSore = (PHiValue(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_getSore");
	nako_addIntVar = (void(__stdcall*)(char*,int,int)) ::GetProcAddress( hDll,"nako_addIntVar");
	nako_addStrVar = (void(__stdcall*)(char*,char*,int)) ::GetProcAddress( hDll,"nako_addStrVar");
	nako_stop = (void(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_stop");
	nako_continue = (void(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_continue");
	nako_id2tango = (DWORD(__stdcall*)(DWORD,char*,DWORD)) ::GetProcAddress( hDll,"nako_id2tango");
	nako_tango2id = (DWORD(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_tango2id");
	nako_var2str = (DWORD(__stdcall*)(PHiValue,char*,DWORD)) ::GetProcAddress( hDll,"nako_var2str");
	nako_var2cstr = (DWORD(__stdcall*)(PHiValue,char*,DWORD)) ::GetProcAddress( hDll,"nako_var2cstr");
	nako_var2int = (int(__stdcall*)(PHiValue)) ::GetProcAddress( hDll,"nako_var2int");
	nako_var2double = (Double(__stdcall*)(PHiValue)) ::GetProcAddress( hDll,"nako_var2double");
	nako_var2extended = (Extended(__stdcall*)(PHiValue)) ::GetProcAddress( hDll,"nako_var2extended");
	nako_str2var = (void(__stdcall*)(char*,PHiValue)) ::GetProcAddress( hDll,"nako_str2var");
	nako_bin2var = (void(__stdcall*)(char*,DWORD,PHiValue)) ::GetProcAddress( hDll,"nako_bin2var");
	nako_int2var = (void(__stdcall*)(int,PHiValue)) ::GetProcAddress( hDll,"nako_int2var");
	nako_double2var = (void(__stdcall*)(Double,PHiValue)) ::GetProcAddress( hDll,"nako_double2var");
	nako_var_new = (PHiValue(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_var_new");
	nako_var_clear = (void(__stdcall*)(PHiValue)) ::GetProcAddress( hDll,"nako_var_clear");
	nako_var_free = (void(__stdcall*)(PHiValue)) ::GetProcAddress( hDll,"nako_var_free");
	nako_ary_get = (PHiValue(__stdcall*)(PHiValue,int)) ::GetProcAddress( hDll,"nako_ary_get");
	nako_ary_getCsv = (PHiValue(__stdcall*)(PHiValue,int,int)) ::GetProcAddress( hDll,"nako_ary_getCsv");
	nako_ary_count = (int(__stdcall*)(PHiValue)) ::GetProcAddress( hDll,"nako_ary_count");
	nako_varCopyData = (void(__stdcall*)(PHiValue,PHiValue)) ::GetProcAddress( hDll,"nako_varCopyData");
	nako_varCopyGensi = (void(__stdcall*)(PHiValue,PHiValue)) ::GetProcAddress( hDll,"nako_varCopyGensi");
	nako_setMainWindowHandle = (void(__stdcall*)(int)) ::GetProcAddress( hDll,"nako_setMainWindowHandle");
	nako_getMainWindowHandle = (DWORD(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_getMainWindowHandle");
	nako_getGroupMember = (PHiValue(__stdcall*)(char*,char*)) ::GetProcAddress( hDll,"nako_getGroupMember");
	nako_hasEvent = (PHiValue(__stdcall*)(char*,char*)) ::GetProcAddress( hDll,"nako_hasEvent");
	nako_addSetterGetter = (void(__stdcall*)(char*,char*,char*,DWORD)) ::GetProcAddress( hDll,"nako_addSetterGetter");
	nako_setDebugEditorHandle = (void(__stdcall*)(DWORD)) ::GetProcAddress( hDll,"nako_setDebugEditorHandle");
	nako_setDebugLineNo = (void(__stdcall*)(BOOL)) ::GetProcAddress( hDll,"nako_setDebugLineNo");
	nako_group_create = (void(__stdcall*)(PHiValue)) ::GetProcAddress( hDll,"nako_group_create");
	nako_group_addMember = (void(__stdcall*)(PHiValue,PHiValue)) ::GetProcAddress( hDll,"nako_group_addMember");
	nako_group_findMember = (PHiValue(__stdcall*)(PHiValue,char*)) ::GetProcAddress( hDll,"nako_group_findMember");
	nako_group_exec = (PHiValue(__stdcall*)(PHiValue,char*)) ::GetProcAddress( hDll,"nako_group_exec");
	nako_debug_nadesiko = (DWORD(__stdcall*)(char*,DWORD)) ::GetProcAddress( hDll,"nako_debug_nadesiko");
	nako_ary_create = (void(__stdcall*)(PHiValue)) ::GetProcAddress( hDll,"nako_ary_create");
	nako_ary_add = (void(__stdcall*)(PHiValue,PHiValue)) ::GetProcAddress( hDll,"nako_ary_add");
	nako_check_tag = (void(__stdcall*)(DWORD,DWORD)) ::GetProcAddress( hDll,"nako_check_tag");
	nako_DebugNextStop = (void(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_DebugNextStop");
	nako_LoadPlugins = (void(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_LoadPlugins");
	nako_openPackfile = (int(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_openPackfile");
	nako_runPackfile = (DWORD(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_runPackfile");
	nako_openPackfileBin = (int(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_openPackfileBin");
	nako_closePackfile = (int(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_closePackfile");
	nako_getPackFileHandle = (int(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_getPackFileHandle");
	nako_setPackFileHandle = (void(__stdcall*)(DWORD)) ::GetProcAddress( hDll,"nako_setPackFileHandle");
	nako_makeReport = (void(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_makeReport");
	nako_reportDLL = (void(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_reportDLL");
	nako_hasPlugins = (BOOL(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_hasPlugins");
	nako_hash_create = (void(__stdcall*)(PHiValue)) ::GetProcAddress( hDll,"nako_hash_create");
	nako_hash_get = (PHiValue(__stdcall*)(PHiValue,char*)) ::GetProcAddress( hDll,"nako_hash_get");
	nako_hash_set = (void(__stdcall*)(PHiValue,char*,PHiValue)) ::GetProcAddress( hDll,"nako_hash_set");
	nako_hash_keys = (int(__stdcall*)(PHiValue,char*,int)) ::GetProcAddress( hDll,"nako_hash_keys");
	nako_getLineNo = (void(__stdcall*)(int*,int*)) ::GetProcAddress( hDll,"nako_getLineNo");
	nako_getSourceText = (DWORD(__stdcall*)(int,char*,DWORD)) ::GetProcAddress( hDll,"nako_getSourceText");
	nako_getFilename = (DWORD(__stdcall*)(int,char*,DWORD)) ::GetProcAddress( hDll,"nako_getFilename");
	nako_pushRunFlag = (void(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_pushRunFlag");
	nako_popRunFlag = (void(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_popRunFlag");
	nako_callSysFunction = (PHiValue(__stdcall*)(DWORD,PHiValue)) ::GetProcAddress( hDll,"nako_callSysFunction");
	nako_setDNAKO_DLL_handle = (void(__stdcall*)(DWORD)) ::GetProcAddress( hDll,"nako_setDNAKO_DLL_handle");
	nako_setPluginsDir = (void(__stdcall*)(char*)) ::GetProcAddress( hDll,"nako_setPluginsDir");
	nako_getPluginsDir = (char*(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_getPluginsDir");
	test = (void(__stdcall*)(void)) ::GetProcAddress( hDll,"test");
	nako_getVersion = (char*(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_getVersion");
	nako_getUpdateDate = (char*(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_getUpdateDate");
	nako_getNADESIKO_GUID = (char*(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_getNADESIKO_GUID");
	nako_getEmbedFile = (BOOL(__stdcall*)(char*,char*,DWORD)) ::GetProcAddress( hDll,"nako_getEmbedFile");
	nako_getLastUserFuncID = (DWORD(__stdcall*)(void)) ::GetProcAddress( hDll,"nako_getLastUserFuncID");
	nako_checkLicense = (DWORD(__stdcall*)(char*,char*)) ::GetProcAddress( hDll,"nako_checkLicense");
	nako_registerLicense = (DWORD(__stdcall*)(char*,char*)) ::GetProcAddress( hDll,"nako_registerLicense");

