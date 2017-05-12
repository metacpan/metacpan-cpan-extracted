@if not exist %Keyboard_Layout_Creator%\bin\i386\kbdutool.exe (
  echo Set Keyboard_Layout_Creator=SOMETHING
  echo so that %%Keyboard_Layout_Creator%%\bin\i386\kbdutool.exe exists
  exit
)
if not exist backup.zip zip backup.zip */*.dll
%Keyboard_Layout_Creator%\bin\i386\kbdutool.exe -v -w -x %2 && move %1.dll i386\%1.dll
%Keyboard_Layout_Creator%\bin\i386\kbdutool.exe -v -w -i %2 && move %1.dll ia64\%1.dll
%Keyboard_Layout_Creator%\bin\i386\kbdutool.exe -v -w -m %2 && move %1.dll amd64\%1.dll
%Keyboard_Layout_Creator%\bin\i386\kbdutool.exe -v -w -o %2 && move %1.dll wow64\%1.dll
dir i386\%1.dll ia64\%1.dll amd64\%1.dll wow64\%1.dll
 