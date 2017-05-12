@if not exist %Keyboard_Layout_Creator%\bin\i386\kbdutool.exe (
  echo Set Keyboard_Layout_Creator=SOMETHING
  echo so that %%Keyboard_Layout_Creator%%\bin\i386\kbdutool.exe exists
  exit
)

perl -wlpe0 ../ooo-ru >ooo-ru.klc
perl -wlpe0 ../ooo-us >ooo-us.klc
cp -p ../coverage-1prefix-Cyrillic.html ../coverage-1prefix-Latin.html src
set kbd1=iz-ru-la
set kbd2=iz-la-ru
cd %kbd1%
..\mkkbd.cmd %kbd1% ..\ooo-ru.klc 2>&1 | tee 00m
mv -i 00m ../00m-ru
cd ..
cd %kbd2%
..\mkkbd.cmd %kbd2% ..\ooo-us.klc 2>&1 | tee 00m
mv -i 00m ../00m-us
cd ..
mv -i %kbd1%/backup.zip backups/backup-ru.zip
mv -i %kbd2%/backup.zip backups/backup-la.zip
cp -p *.klc src
for %%f in (*.zip) do zip -f %%f
