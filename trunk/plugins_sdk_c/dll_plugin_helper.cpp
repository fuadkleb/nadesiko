/*
�v���O�C������邤���ŕ֗��Ȗ��߂̎���
*/
#include <iostream>
//#include <stdlib.h>
#include <stdio.h>

#include	"dnako_import_types.h"
#include	"dnako_import.h"

using namespace std;

// �֐����������o�^�ł��邩�`�F�b�N����
void _checkTag(DWORD tag,DWORD name);
// �֐���o�^����
void AddFunc(string name,string argStr,int tag,THimaSysFunction func,
  string kaisetu,string yomigana);
// �������o�^����
void AddStrVar(string name,string value,int tag,string kaisetu,
  string yomigana);
// ������o�^����
void AddIntVar(string name,int value,int tag,string kaisetu,
  string yomigana);
// �Z�b�^�[�E�Q�b�^�[���Z�b�g����
void SetSetterGetter(string name,string setter,string getter,
     DWORD tag,string desc,string yomi);


void _checkTag(DWORD tag,DWORD name){
	nako_check_tag(tag, name);
}
void AddFunc(string name,string argStr,int tag,THimaSysFunction func,
  string kaisetu,string yomigana){
	try{
		_checkTag(tag, 0);
	}catch(...){
		/*���Ӂ@�G���[�����͎b��ł�*/
		//RAISE(Exception.Create('�w'+name+'�x(tag='+IntToStr(tag)+')���d�����Ă��܂��B');
		/*char tag_c[6];
		itoa(tag,tag_c,10);
		throw domain_error(("�w"+name+"�x(tag="+tag_c+")���d�����Ă��܂��B").c_str());*/
		char mes[50];
		sprintf(mes,"�w%s�x(tag=%d)���d�����Ă��܂��B",name.c_str(),tag);
		throw domain_error(mes);
	}
	nako_addFunction(const_cast<char *>(name.c_str()),
	   const_cast<char *>(argStr.c_str()),func, tag);
}
// �������o�^����
void AddStrVar(string name,string value,int tag,string kaisetu,
  string yomigana){
	_checkTag(tag, 0);
	nako_addStrVar(const_cast<char *>(name.c_str()), const_cast<char *>(value.c_str()), tag);
}
// ������o�^����
void AddIntVar(string name,int value,int tag,string kaisetu,
  string yomigana){
	_checkTag(tag, 0);
	nako_addIntVar(const_cast<char *>(name.c_str()), value, tag);
}
// �Z�b�^�[�E�Q�b�^�[���Z�b�g����
void SetSetterGetter(string name,string setter,string getter,
     DWORD tag,string desc,string yomi){
	 nako_addSetterGetter(const_cast<char *>(name.c_str()), const_cast<char *>(setter.c_str()),
	  const_cast<char *>(getter.c_str()), tag);
}

