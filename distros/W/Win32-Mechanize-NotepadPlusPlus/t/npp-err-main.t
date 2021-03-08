########################################################################
# Coverage tests for NotepadPlusPlus.pm error conditions
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

use FindBin;
BEGIN { my $f = $FindBin::Bin . '/nppPath.inc'; require $f if -f $f; }

use lib $FindBin::Bin;
use myTestHelpers qw/:all/;
myTestHelpers::setChildEndDelay(2);

use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;

throws_ok { no warnings qw/redefine/; local *Win32::Mechanize::NotepadPlusPlus::Notepad::notepad = sub { undef }; Win32::Mechanize::NotepadPlusPlus::notepad() } qr/\Qdefault Notepad++ application object not initialized\E/, 'missing notepad object';
throws_ok { no warnings qw/redefine/; local *Win32::Mechanize::NotepadPlusPlus::Notepad::editor1 = sub { undef }; Win32::Mechanize::NotepadPlusPlus::editor1() } qr/\Qdefault editor1 object not initialized\E/, 'missing editor1 object';
throws_ok { no warnings qw/redefine/; local *Win32::Mechanize::NotepadPlusPlus::Notepad::editor2 = sub { undef }; Win32::Mechanize::NotepadPlusPlus::editor2() } qr/\Qdefault editor2 object not initialized\E/, 'missing editor2 object';
throws_ok { no warnings qw/redefine/; local *Win32::Mechanize::NotepadPlusPlus::Notepad::editor  = sub { undef }; Win32::Mechanize::NotepadPlusPlus::editor()  } qr/\Qdefault editor object not initialized\E/, 'missing editor object';

done_testing;