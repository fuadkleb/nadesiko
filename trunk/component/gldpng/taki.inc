//********************************************
//    �R���p�C���w�߁��o�[�W�����`�F�b�N
//                           2001.07.04 ����
//********************************************

//---------------------------------------------------------
// �R���p�C���I�v�V�����ݒ�
//---------------------------------------------------------

{$EXTENDEDSYNTAX ON}
{$LONGSTRINGS ON}
{$OPTIMIZATION ON}
{$WARNINGS OFF}
{$HINTS OFF}
{$BOOLEVAL OFF}
{$RANGECHECKS OFF}
{$OVERFLOWCHECKS OFF}


//---------------------------------------------------------
// �R���p�C�����
//
// VER80  Delphi1
// VER90  Delphi2
// VER93  C++Builder1
// VER100 Delphi3
// VER110 C++Builder3
// VER120 Delphi4
// VER130 Delphi5
//---------------------------------------------------------

// �R���p�C���̎�ރ`�F�b�N1
{$IFDEF VER80}
 Delphi1�ł͎g���܂���B
 ����������Ă��\�����邾���ł��B
 ���ʂȂ��Ƃ͂��Ȃ���Delphi3(C++Builder3)�ȏ�Ŏg���Ă��������B
{$ENDIF}

{$IFDEF VER90}
  {$DEFINE DEL2}
{$ELSE}
 {$IFDEF VER93}
   {$DEFINE DEL2}
 {$ELSE}
  {$IFDEF VER100}
    {$DEFINE DEL3}
  {$ELSE}
   {$IFDEF VER110}
     {$DEFINE DEL3}
   {$ELSE}
     {$DEFINE DEL4}
   {$ENDIF}
  {$ENDIF}
 {$ENDIF}
{$ENDIF}

{$IFDEF VER110}
 {$DEFINE BCB3}
{$ENDIF}

// �R���p�C���̎�ރ`�F�b�N2
{$IFDEF DEL2}
 Delphi2�܂���C++builder1�ł͎g���܂���B
 ����������Ă��\�����邾���ł��B
 ���ʂȂ��Ƃ͂��Ȃ���Delphi3(C++builder3)�ȏ�Ŏg���Ă��������B
{$ENDIF}

{$IFDEF DEL4}
 // Delphi4�ȍ~�̒ǉ������p
 {$DEFINE SUPPORT_D4}
{$ENDIF}

{$IFNDEF DEL2}
 {$ObjExportAll ON}  // C++Builder3�ȏ�ł͂��ꂢ��Ȃ��Ƃ��߂Ȃ悤���B
{$ENDIF}

