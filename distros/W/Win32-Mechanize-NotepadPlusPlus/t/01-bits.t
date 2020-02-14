########################################################################
# Try to determine Notepad++'s bitness, and compare it to Perl's
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;
use Win32;
use Win32::GuiTest 1.64 qw':FUNC !SendMessage';     # 1.64 required for 64-bit SendMessage

use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;

use FindBin;
use lib $FindBin::Bin;
use myTestHelpers qw/:userSession/;
use Path::Tiny 0.018 qw/path tempfile/;

#   if any unsaved buffers, HALT test and prompt user to save any critical
#       files, then re-run test suite.
my $EmergencySessionHash;
BEGIN { $EmergencySessionHash = saveUserSession(); }
END { restoreUserSession( $EmergencySessionHash ); }

BEGIN {
    notepad()->closeAll();
}

SetForegroundWindow( notepad->{_hwnd} );
sleep(1);
is GetForegroundWindow(), notepad->{_hwnd}, 'right foreground window';
note sprintf "\tGetForegroundWindow(): %s\n", GetForegroundWindow()//'<undef>';

notepad()->menuCommand($nppidm{IDM_DEBUGINFO});
sleep(1);
isnt my $hwnd = GetForegroundWindow(), notepad->{_hwnd}, 'Debug Info should be foreground window';
note sprintf "\tGetForegroundWindow(): %s\n", GetForegroundWindow()//'<undef>';
is my $dlgname = GetWindowText(GetForegroundWindow()), 'Debug Info', 'Debug Info: check dialog name';
note sprintf "\tGetWindowText = \"%s\"\n", $dlgname;

# need some way to click the "Copy debug info into clipboard" button...
#PushButton("Copy debug info into clipboard");
#sleep(1);
my $debugInfo;
for my $c (GetChildWindows($hwnd)) {
    $debugInfo = WMGetText($c),last if GetClassName($c) eq 'Edit';
}

# done with dialog
PushButton("OK", 0.25);

# extract version and bits from debugInfo
my ($ver, $bits) = $debugInfo =~ m/^Notepad\+\+ (v[\d\.]+)\s*\((\d+)-bit\)\s*$/m;
ok $ver, 'DebugInfo:Notepad++ ver';
ok $bits, 'DebugInfo:Notepad++ bits';
note sprintf "\tNotepad++ %s %s-bit", $ver//'<undef>', $bits//'<undef>';

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
        or BAIL_OUT sprintf "Notepad++ (%s-bit) and Perl (%s-bit) must match!", $bits, notepad->getPerlBits();
}

done_testing;