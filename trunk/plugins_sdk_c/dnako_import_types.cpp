/*
dnako.dll�̊֐����ԐړI�Ɏg���֐��̒�`
*/
#include <windows.h>
#include <iostream>
#include "dnako_import_types.h"
#include "dnako_import.h"

using namespace std;

PHiValue hi_var_new(string name);
// �V�K�ϐ��𐶐�����
PHiValue hi_clone(PHiValue v); // �֐��Ƃ܂������������̂𐶐�����
PHiValue hi_newInt(int value); // �V�K����
PHiValue hi_newStr(string value);  // �V�K������
PHiValue hi_newFloat(HFloat value);// �V�K������
// �������Z�b�g����
void hi_setInt  (PHiValue v,int num);
void hi_setFloat(PHiValue v,HFloat num);
// BOOL�^���Z�b�g����
void hi_setBool(PHiValue v,BOOL b);
// ��������Z�b�g����
void hi_setStr(PHiValue v,string s);
// �L���X�g���Ďg����悤��
BOOL hi_bool(PHiValue value);
int hi_int  (PHiValue value);
double hi_float(PHiValue value);
string hi_str(PHiValue p);


PHiValue hi_var_new(string name= ""){// �V�K�ϐ��𐶐�����
	if (name.empty()) 
		return nako_var_new(NULL);
	else
		return nako_var_new(const_cast<char *>(name.c_str()));
}
PHiValue hi_clone(PHiValue v){ // �֐��Ƃ܂������������̂𐶐�����
	PHiValue Result = hi_var_new();
	nako_varCopyGensi(v, Result);
	return Result;
}
PHiValue hi_newInt(int value){ // �V�K����
	PHiValue Result = hi_var_new();
	hi_setInt(Result, value);
	return Result;
}
PHiValue hi_newStr(string value){  // �V�K������
	PHiValue Result = hi_var_new();
	hi_setStr(Result, value);
	return Result;
}
PHiValue hi_newFloat(HFloat value){// �V�K������
	PHiValue Result = hi_var_new();
	hi_setFloat(Result, value);
	return Result;
}
// �������Z�b�g����
void hi_setInt  (PHiValue v,int num){
	nako_int2var(num, v);
}
void hi_setFloat(PHiValue v,HFloat num){
	nako_double2var(num, v);
}
// BOOL�^���Z�b�g����
void hi_setBool(PHiValue v,BOOL b){
	if(b)
		nako_int2var(1, v);
	else
		nako_int2var(0, v);
}
// ��������Z�b�g����
void hi_setStr(PHiValue v,string s){
	if (s.empty())
		nako_str2var(const_cast<char *>(s.c_str()), v);
	else
		nako_bin2var(const_cast<char *>(s.c_str())/*&s[0]*/, s.length(), v);
}
// �L���X�g���Ďg����悤��
BOOL hi_bool(PHiValue value){
	return (nako_var2int(value) != 0);
}
int hi_int  (PHiValue value){
	return nako_var2int(value);
}
double hi_float(PHiValue value){
	return nako_var2double(value);
}
string hi_str(PHiValue p){
	const int MAX_STR = 255;
	DWORD len;
	string Result;
	if(p == NULL){
		return "";
	}	
	// �K���Ɋm�ۂ��ĕ�������R�s�[
	Result.resize(MAX_STR+1);
	len = nako_var2str(p,const_cast<char *>(Result.c_str())/*&Result[1]*/, MAX_STR);
	
	if (len > MAX_STR){
	  Result.resize(len);
	  nako_var2str(p, const_cast<char *>(Result.c_str())/*&Result[1]*/, len);
	} else{
	  Result.resize(len); // ���T�C�Y
	  /*if (len == 0) {
		return 0;
	  }*/
	}
	return Result;
}
