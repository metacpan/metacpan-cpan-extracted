########################################################################
# Try to determine Notepad++'s bitness, and compare it to Perl's
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;
use Win32;
use Win32::GuiTest 1.64 qw':FUNC !SendMessage';     # 1.64 required for 64-bit SendMessage

use FindBin;
BEGIN { my $f = $FindBin::Bin . '/nppPath.inc'; require $f if -f $f; }

use lib $FindBin::Bin;
use myTestHelpers qw/:userSession/;
use Path::Tiny 0.018 qw/path tempfile/;

use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;

#   if any unsaved buffers, HALT test and prompt user to save any critical
#       files, then re-run test suite.
my $EmergencySessionHash;
BEGIN { $EmergencySessionHash = saveUserSession(); }
END { restoreUserSession( $EmergencySessionHash ); }

BEGIN {
    notepad()->closeAll();
}

ok notepad->hwnd(), sprintf('ensure Notepad++ has an hWnd: %s', notepad->hwnd()//'<undef>')
    or BAIL_OUT "could not find Notepad++ hWnd, which will make the rest of this test meaningless";

SetForegroundWindow( notepad->hwnd() );
select(undef,undef,undef,0.1);   # wait 100ms for response
note sprintf "\tOriginal GetForegroundWindow(): %s\n", GetForegroundWindow()//'<undef>';

notepad()->menuCommand($NPPIDM{IDM_DEBUGINFO});
my $hWnd = WaitWindowLike(0, 'Debug Info', undef, undef, undef, 2); #wait up to 2 seconds for the DebugInfo
note sprintf "\tWaitWindowLike: GetForegroundWindow(): %s\n", GetForegroundWindow()//'<undef>';
note sprintf "\tWaitWindowLike: hWnd = '%s'", $hWnd//'<undef>';
note sprintf "\tWaitWindowLike: wmGETTEXT= '%s'", WMGetText($hWnd)//'<undef>';
note sprintf "\tWaitWindowLike: text= '%s'", GetWindowText($hWnd)//'<undef>';
note sprintf "\tWaitWindowLike: class= '%s'", GetClassName($hWnd)//'<undef>';
isnt $hWnd, notepad->hwnd(), 'Debug Info should have popped up by now';
is my $dlgname = GetWindowText($hWnd), 'Debug Info', 'Debug Info: check dialog name';

# need some way to click the "Copy debug info into clipboard" button...
#PushButton("Copy debug info into clipboard");
#sleep(1);
my $debugInfo;
for my $c (GetChildWindows($hWnd)) {
    $debugInfo = WMGetText($c),last if GetClassName($c) eq 'Edit';
}

# done with dialog
PushButton("OK", 0.5);

# extract version and bits from debugInfo
my ($ver, $bits) = $debugInfo =~ m/^Notepad\+\+ (v[\d\.]+)(?:\s*\((\d+)-bit\))?\s*$/m;
ok $ver, 'DebugInfo:Notepad++ ver';
ok $bits, 'DebugInfo:Notepad++ bits';
diag sprintf "\n\nDEBUG INFO: Notepad++ %s %s-bit\n\n\n", $ver//'<undef>', $bits//'<undef>';
note sprintf "\n\n%s\n\n\n", $debugInfo//'<undef>';

# perl bits
like notepad->getPerlBits(), qr/^(32|64)$/, 'getPerlBits()';
note sprintf "\tgetPerlBits() = %s\n", notepad->getPerlBits()//'<undef>';

if(0) {
    use Config;
    diag "Perl $]\n";
    diag sprintf "* Config{%s} = %s\n", $_, $Config{$_} for qw/ptrsize ivsize myuname/;
    diag "__ptrBytes => ", notepad->__ptrBytes;
    diag "__ptrPack  => ", notepad->__ptrPack;
}

# bits must be equal, unless environment variable ignores bits
SKIP: {
    skip "compare Notepad++ and Perl bits: WMNPP_IGNORE_BITS set true", 1 if $ENV{WMNPP_IGNORE_BITS};

    is notepad->getPerlBits(), $bits, 'Notepad++ and Perl need same compiled bits'
        or BAIL_OUT sprintf "OS unsupported because Notepad++ (%s-bit) and Perl (%s-bit) must match!", $bits//'<undef>', notepad->getPerlBits()//'<undef>';
}

done_testing;
