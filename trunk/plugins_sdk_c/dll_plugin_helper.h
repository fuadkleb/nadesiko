/*
�v���O�C������邤���ŕ֗��Ȗ��߂��`
*/
#ifndef	__HELPER__
#define	__HELPER__
#include<windows.h>
#include<iostream>

#include "dnako_import_types.h"

using namespace std;

// �֐����������o�^�ł��邩�`�F�b�N����
extern void _checkTag(DWORD tag,DWORD name);
// �֐���o�^����
extern void AddFunc(string name,string argStr,int tag,THimaSysFunction func,
  string kaisetu,string yomigana);
// �������o�^����
extern void AddStrVar(string name,string value,int tag,string kaisetu,
  string yomigana);
// ������o�^����
extern void AddIntVar(string name,int value,int tag,string kaisetu,
  string yomigana);
// �Z�b�^�[�E�Q�b�^�[���Z�b�g����
extern void SetSetterGetter(string name,string setter,string getter,
     DWORD tag,string desc,string yomi);

#endif /*__HELPER__*/
