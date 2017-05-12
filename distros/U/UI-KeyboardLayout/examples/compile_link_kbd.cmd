@if not exist %Keyboard_Layout_Creator%\bin\i386\kbdutool.exe (
  echo Set Keyboard_Layout_Creator=SOMETHING
  echo so that %%Keyboard_Layout_Creator%%\bin\i386\kbdutool.exe exists
  exit
)

set extra_c_files=
set extra_obj_files=
if "%1" == "--with-extra-c" (
  set extra_c_files=%2.c
  set extra_obj_files=%2.obj
  shift
  shift
)

set process_kbd=%1
set cl_opts=-nologo -I%Keyboard_Layout_Creator%\inc -DNOGDICAPMASKS -DNOWINMESSAGES -DNOWINSTYLES -DNOSYSMETRICS -DNOMENUS -DNOICONS -DNOSYSCOMMANDS -DNORASTEROPS -DNOSHOWWINDOW -DOEMRESOURCE -DNOATOM -DNOCLIPBOARD -DNOCOLOR -DNOCTLMGR -DNODRAWTEXT -DNOGDI -DNOKERNEL -DNONLS -DNOMB -DNOMEMMGR -DNOMETAFILE -DNOMINMAX -DNOMSG -DNOOPENFILE -DNOSCROLL -DNOSERVICE -DNOSOUND -DNOTEXTMETRIC -DNOWINOFFSETS -DNOWH -DNOCOMM -DNOKANJI -DNOHELP -DNOPROFILER -DNODEFERWINDOWPOS -DNOMCX -DWIN32_LEAN_AND_MEAN -DRoster -DSTD_CALL -D_WIN32_WINNT=0x0500 /DWINVER=0x0500 -D_WIN32_IE=0x0500 /MD /c /Zp8 /Gy /W3 /WX /Gz /Gm- /EHs-c- /GR- /GF -Z7 /Oxs
set rc_opts=-r -i%Keyboard_Layout_Creator%\inc -DSTD_CALL -DCONDITION_HANDLING=1 -DNT_UP=1 -DNT_INST=0 -DWIN32=100 -D_NT1X_=100 -DWINNT=1 -D_WIN32_WINNT=0x0500 /DWINVER=0x0400 -D_WIN32_IE=0x0400 -DWIN32_LEAN_AND_MEAN=1 -DDEVL=1 -DFPO=1 -DNDEBUG -l 409
set link_opts=-nologo -merge:.edata=.data
set link_opts2=-merge:.text=.data -merge:.bss=.data -section:.data,re -MERGE:_PAGE=PAGE -MERGE:_TEXT=.text
set link_opts3=-SECTION:INIT,d -OPT:REF -OPT:ICF -IGNORE:4039,4078 -noentry -dll
set link_opts4=-subsystem:native,5.0 -merge:.rdata=.text -PDBPATH:NONE -STACK:0x40000,0x1000 /opt:nowin98 -osversion:4.0 -version:4.0 /release -def:%process_kbd%.def %process_kbd%.res %extra_obj_files% %process_kbd%.obj

del %process_kbd%\i386\%process_kbd%.dll
del %process_kbd%\ia64\%process_kbd%.dll
del %process_kbd%\amd64\%process_kbd%.dll
del %process_kbd%\wow64\%process_kbd%.dll

@REM perl -pe0 ooo-us >ooo-us-dosish
@REM %Keyboard_Layout_Creator%\bin\i386\kbdutool.exe -v -w -s ooo-us-dosish
@REM ..\compile_link_kbd.cmd  iz-la-ru 2>&1 | tee 00c3

mkdir %process_kbd%
if not "%extra_c_files%" == "" %Keyboard_Layout_Creator%\bin\i386\cl.exe      %cl_opts% %extra_c_files%
%Keyboard_Layout_Creator%\bin\i386\cl.exe      %cl_opts% %process_kbd%.c
%Keyboard_Layout_Creator%\bin\i386\rc.exe %rc_opts% %process_kbd%.rc
%Keyboard_Layout_Creator%\bin\i386\link.exe %link_opts% -merge:.rdata=.data %link_opts2% -MACHINE:IX86 %link_opts3% -libpath:%Keyboard_Layout_Creator%\lib\i386 %link_opts4%
mkdir %process_kbd%\i386
move /y %process_kbd%.dll %process_kbd%\i386\%process_kbd%.dll
del %extra_obj_files% %process_kbd%.obj %process_kbd%.exp %process_kbd%.lib %process_kbd%.res

if not "%extra_c_files%" == "" %Keyboard_Layout_Creator%\bin\i386\IA64\cl.exe      %cl_opts% %extra_c_files%
%Keyboard_Layout_Creator%\bin\i386\IA64\cl.exe %cl_opts% %process_kbd%.c
%Keyboard_Layout_Creator%\bin\i386\rc.exe %rc_opts% %process_kbd%.rc
%Keyboard_Layout_Creator%\bin\i386\link.exe %link_opts% -merge:.srdata=.data %link_opts2% /MACHINE:IA64 %link_opts3% -libpath:%Keyboard_Layout_Creator%\lib\ia64 %link_opts4%
mkdir %process_kbd%\ia64
move /y %process_kbd%.dll %process_kbd%\ia64\%process_kbd%.dll
del %extra_obj_files% %process_kbd%.obj %process_kbd%.exp %process_kbd%.lib %process_kbd%.res

if not "%extra_c_files%" == "" %Keyboard_Layout_Creator%\bin\i386\amd64\cl.exe      %cl_opts% %extra_c_files%
%Keyboard_Layout_Creator%\bin\i386\amd64\cl.exe %cl_opts% %process_kbd%.c
%Keyboard_Layout_Creator%\bin\i386\rc.exe %rc_opts% %process_kbd%.rc
%Keyboard_Layout_Creator%\bin\i386\link.exe %link_opts% -merge:.rdata=.data %link_opts2% -MACHINE:AMD64 %link_opts3% -libpath:%Keyboard_Layout_Creator%\lib\amd64 %link_opts4%
mkdir %process_kbd%\amd64
move /y %process_kbd%.dll %process_kbd%\amd64\%process_kbd%.dll
del %extra_obj_files% %process_kbd%.obj %process_kbd%.exp %process_kbd%.lib %process_kbd%.res

if not "%extra_c_files%" == "" %Keyboard_Layout_Creator%\bin\i386\cl.exe      %cl_opts% -DBUILD_WOW6432 -D_WOW6432_ %extra_c_files%
%Keyboard_Layout_Creator%\bin\i386\cl.exe %cl_opts% -DBUILD_WOW6432 -D_WOW6432_ %process_kbd%.c
%Keyboard_Layout_Creator%\bin\i386\rc.exe %rc_opts% %process_kbd%.rc
%Keyboard_Layout_Creator%\bin\i386\link.exe %link_opts% -merge:.rdata=.data %link_opts2% -MACHINE:IX86 %link_opts3% -libpath:%Keyboard_Layout_Creator%\lib\i386 %link_opts4%
mkdir %process_kbd%\wow64
move /y %process_kbd%.dll %process_kbd%\wow64\%process_kbd%.dll
del %extra_obj_files% %process_kbd%.obj %process_kbd%.exp %process_kbd%.lib %process_kbd%.res
