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

@rem Shorten (but do not cut in the middle of utf-8 char

perl -wlpe "s/^(.{250}[\x80-\xBF]*).*/$1/s" %src%/ooo-us >ooo-us-shorten
perl -wlpe "s/^(.{250}[\x80-\xBF]*).*/$1/s" %src%/ooo-ru >ooo-ru-shorten
perl -wlpe "s/^(.{250}[\x80-\xBF]*).*/$1/s" %src%/ooo-gr >ooo-gr-shorten
perl -wlpe "s/^(.{250}[\x80-\xBF]*).*/$1/s" %src%/ooo-hb >ooo-hb-shorten

set ARROWSK=qw(HOME UP PRIOR DIVIDE LEFT F13 RIGHT MULTIPLY END DOWN NEXT SUBTRACT INSERT F15 F14 ADD)

@rem -C31 BEGIN {binmode STDOUT q(:raw:encoding(UTF-16LE):crlf); print chr 0xfeff}
@rem Remove Fkeys, NUMPADn, CLEAR from oo-LANG-shorten
perl -i~ -wlpe "BEGIN {@K = %ARROWSK%; $k = join q(|), @K[1..$#K]; $rx = qr/\b(F\d\d?|NUMPAD\d|CLEAR|(NON)?CONVERT)\b/} $_ = q() if /^[0-9A-F]{2,4}\s+$rx/" ooo-us-shorten ooo-ru-shorten ooo-gr-shorten ooo-hb-shorten

for %%f in (ooo-us-shorten ooo-ru-shorten ooo-gr-shorten ooo-hb-shorten) do (
  ( perl -we "print qq(\xff\xfe)" && iconv -f UTF-8 -t UTF-16LE %%f ) > %%f-16
  %Keyboard_Layout_Creator%\bin\i386\kbdutool.exe -v -w -s -u %%f-16
)

for %%f in (iz-la-4s.C iz-ru-4s.C iz-gr-p4.C iz-hb-4s.C) do (
  @rem mv %%f %%f-16
  @rem iconv -f UTF-16 -t UTF-8 %%f-16 > %%f
)

@rem INSERT is handled OK by kbdutool ...  Replace #ERROR# by F2 and elts of ARROWSK (except Fn and INSERT) in order; "?" is replaced later by ???
perl -i~ -wlpe "BEGIN { @ARGV = <*.[CH]>; $c=1; @K = (%ARROWSK%); @KK = (map(qq(F$_), 0), grep(!/^F\d+$/ && !/^INSERT$/, @K), map(qq(F$_), 1 .. 10), q(SUBTRACT), map(qq(NUMPAD$_),5,5,0,0,0), q(?)); }; $vk = ($ARGV =~ /C$/i && q(VK_)); warn qq($c vs $#KK; $_) unless defined $KK[$c]; s/#ERROR#/${vk}$KK[$c]/ and $c++; $c=1 if eof"

@@@@rem Not needed now:
goto post_try_edit

@rem the "old" short rows contain -1 instead of WCH_NONE
@@@rem perl -i~~ -wlpe "BEGIN { @ARGV = <*.C>; $k = {qw( ADD '+' SUBTRACT '-' MULTIPLY '*' DIVIDE '/' RETURN '\r' )}; $rx = join q(|), keys %%$k; }; s/^(\s+\{VK_($rx)\s*,\s*0\s*,\s*)'\S*\s+\S+\s+\S+\s*$//"
perl -i~~ -wlpe "BEGIN { @ARGV = <*.C>; $k = {qw( ADD '+' SUBTRACT '-' MULTIPLY '*' DIVIDE '/' RETURN '\r' )}; $rx = join q(|), keys %%$k; }; s/^(\s+\{VK_($rx)\s*,\s*0\s*,\s*)'\S*\s+\S+\s+\S+\s*$//; s/^static\s+(?=.*([a-zA-Z]\[\]|\bCharModifiers\b))//"

copy iz-la-4s.C iz-la-4s.C~~~
copy iz-ru-4s.C iz-ru-4s.C~~~
copy iz-gr-p4.C iz-gr-p4.C~~~
copy iz-hb-4s.C iz-hb-4s.C~~~

@rem patch -p0 -b <%ex%\izKeys.pre-convert-fix.patch

@rem Fix the limitations of to-C converter kbdutool: convert LAYOUT manually (with main/secondary keys having 29/25 bindings)
perl %ex%\test-klc-tr.pl %src%/ooo-us iz-la-4s.C~~~ 45 46 >iz-la-4s.C
perl %ex%\test-klc-tr.pl %src%/ooo-ru iz-ru-4s.C~~~ 45 46 >iz-ru-4s.C
perl %ex%\test-klc-tr.pl %src%/ooo-gr iz-gr-p4.C~~~ 45 46 >iz-gr-p4.C
perl %ex%\test-klc-tr.pl %src%/ooo-hb iz-hb-4s.C~~~ 45 46 >iz-hb-4s.C

:post_try_edit

patch -p0 -b <%ex%\h_files.patch
perl %ex%\klc2c.pl %src%/ooo-us >iz-la-4s.C
perl %ex%\klc2c.pl %src%/ooo-ru >iz-ru-4s.C
perl %ex%\klc2c.pl %src%/ooo-gr >iz-gr-p4.C
perl %ex%\klc2c.pl %src%/ooo-hb >iz-hb-4s.C

@@@@rem unzip -u %ex%\extra_c.zip
for %%f in (msklc_altgr.c msklc_lig4.h msklc_altgr_r2l.c) do copy %ex%\%%f .

%ex%\compile_link_kbd.cmd --with-extra-c msklc_altgr iz-la-4s 2>&1 | tee 00cl
%ex%\compile_link_kbd.cmd --with-extra-c msklc_altgr iz-ru-4s 2>&1 | tee 00cr
%ex%\compile_link_kbd.cmd --with-extra-c msklc_altgr iz-gr-p4 2>&1 | tee 00cg
%ex%\compile_link_kbd.cmd --with-extra-c msklc_altgr_r2l iz-hb-4s 2>&1 | tee 00ch

zip -ru iz-la-4s iz-la-4s
zip -ru iz-ru-4s iz-ru-4s
zip -ru iz-gr-p4 iz-gr-p4
zip -ru iz-hb-4s iz-hb-4s
zip -ju src %src%/ooo-us %src%/ooo-ru %src%/ooo-gr %src%/ooo-hb %ex%\izKeys.kbdd %ex%\build-iz.pl %ex%\compile_link_kbd.cmd %ex%\izKeys.patch %ex%\test-klc-tr.pl %~f0 *.C *.H *.RC *.DEF %ex%\extra_c.zip %src%/text-tables
copy %src%\izKeys-visual-maps-out.html izKeys-visual-maps.html
zip -ju html izKeys-visual-maps.html %src%/coverage-1prefix-Cyrillic.html %src%/coverage-1prefix-Latin.html %src%/coverage-1prefix-Hebrew.html %src%/coverage-1prefix-Greek.html %src%/izKeys-front-out.html

for %%f in ( Latin CyrillicPhonetic GreekPoly Hebrew ) do zip -ju iz-%%f %src%/iz-%%f.keylayout && zip -m apple iz-%%f.zip
zip -ju apple %src%/README--INSTALL-apple

for %%d in (iz-la-4s iz-ru-4s iz-gr-p4 iz-hb-4s) do ls -l %%d\i386\%%d.dll %%d\ia64\%%d.dll %%d\amd64\%%d.dll %%d\wow64\%%d.dll
