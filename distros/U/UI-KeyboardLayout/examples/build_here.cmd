@if not exist %Keyboard_Layout_Creator%\bin\i386\kbdutool.exe (
  echo Set Keyboard_Layout_Creator=SOMETHING
  echo so that %%Keyboard_Layout_Creator%%\bin\i386\kbdutool.exe exists
  exit
)

@rem Sometimes it may be better to make these into .   ...
set ex=..\UI-KeyboardLayout\examples
set src=..

@rem It is assumed that in the parent directory the .klc are already constructed as
@rem perl -wC31 -I UI-KeyboardLayout/lib UI-KeyboardLayout/examples/build-iz.pl UI-KeyboardLayout/examples/izKeys.kbdd

@rem For best results, put the previous version of the distribution into subdirectories of this directory
@rem For the initial build, remove everything in SHIFTSTATE, LAYOUT and DEADKEY sections, load in MSKLC, and build from GUI
@rem (There may be problems on 64-bit systems???)

perl %ex%\klc2c.pl --comment-vkcodes=OEM_8 %src%/ooo-us >iz-la-4s.C
perl %ex%\klc2c.pl                         %src%/ooo-ru >iz-ru-4s.C
perl %ex%\klc2c.pl                         %src%/ooo-gr >iz-gr-p4.C
perl %ex%\klc2c.pl                         %src%/ooo-hb >iz-hb-4s.C

%ex%\compile_link_kbd.cmd --with-extra-c   iz-la-4s_extra   iz-la-4s 2>&1 | tee 00cl
%ex%\compile_link_kbd.cmd --with-extra-c   iz-ru-4s_extra   iz-ru-4s 2>&1 | tee 00cr
%ex%\compile_link_kbd.cmd --with-extra-c   iz-gr-p4_extra   iz-gr-p4 2>&1 | tee 00cg
%ex%\compile_link_kbd.cmd --with-extra-c   iz-hb-4s_extra   iz-hb-4s 2>&1 | tee 00ch

zip -ru iz-la-4s iz-la-4s
zip -ru iz-ru-4s iz-ru-4s
zip -ru iz-gr-p4 iz-gr-p4
zip -ru iz-hb-4s iz-hb-4s
zip -ju src %src%/ooo-us %src%/ooo-ru %src%/ooo-gr %src%/ooo-hb %ex%\izKeys.kbdd %ex%\build-iz.pl %ex%\compile_link_kbd.cmd %ex%\klc2c.pl %~f0 *.C *.H *.RC *.DEF %src%/text-tables
copy %src%\izKeys-visual-maps-out.html izKeys-visual-maps.html
zip -ju html izKeys-visual-maps.html %src%/coverage-1prefix-Cyrillic.html %src%/coverage-1prefix-Latin.html %src%/coverage-1prefix-Hebrew.html %src%/coverage-1prefix-Greek.html %src%/izKeys-front-out.html

for %%f in ( Latin CyrillicPhonetic GreekPoly Hebrew ) do zip -ju iz-%%f %src%/iz-%%f.keylayout && zip -m apple iz-%%f.zip
zip -ju apple %src%/README--INSTALL-apple

for %%d in (iz-la-4s iz-ru-4s iz-gr-p4 iz-hb-4s) do ls -l %%d\i386\%%d.dll %%d\ia64\%%d.dll %%d\amd64\%%d.dll %%d\wow64\%%d.dll
