# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use strict;
my $loaded;

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use Win32API::Const qw(:WM_ :SW_ WS_POPUPWINDOW :SE_);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print "not " unless WM_CLOSE()==16;
print "ok 2\n";

print "not " unless WS_POPUPWINDOW()==2156396544;
print "ok 3\n";

print "not " unless Win32API::Const::COLOROKSTRING() eq "commdlg_ColorOK";
print "ok 4\n";

print "not " unless Win32API::Const::COLOROKSTRINGA() eq "commdlg_ColorOK";
print "ok 5\n";

print "not " unless SW_SHOWMINNOACTIVE()==7;
print "ok 6\n";

print "not " unless Win32API::Const::ACCESS_SYSTEM_SECURITY()==16777216;
print "ok 7\n";

print "not " unless Win32API::Const::ANIMATE_CLASS() eq "SysAnimate32";
print "ok 8\n";

print "not " if defined Win32API::Const::constant("WM_CLOSE_FOO");
print "ok 9\n";

print "not " if defined Win32API::Const::constant("wm_close");
print "ok 10\n";

print "not " unless SE_GROUP_ENABLED() ==4;
print "ok 11\n";

print "not " unless SE_SELF_RELATIVE() ==32768;
print "ok 12\n";

print "not " unless SE_GROUP_LOGON_ID() == 0xC0000000;
print "ok 13\n";

print "not " unless SE_SHUTDOWN_NAME() eq "SeShutdownPrivilege";
print "ok 14\n";
