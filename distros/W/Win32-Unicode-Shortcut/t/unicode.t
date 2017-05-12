# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-Unicode-Shortcut.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Cwd;
use Win32;
use File::Spec;
use charnames ':full';
use Encode;
my $has_Win32API__File = eval {use Win32API::File qw/DeleteFileW/; return(1);} || 0;
use Test::More tests => 24;
BEGIN { use_ok('Win32::Unicode::Shortcut') };

#########################

# Adapted sample.pl from the Win32::Shortcut Package
# in the target:      \N{HEBREW LETTER ALEF} (U+05D0)
# in the description: \N{CYRILLIC CAPITAL LETTER YA} (U+042F)
# in the arguments:   \N{WON SIGN} (U+20A9)
# and will append them to four fields, preceded by a " unicode character: "
my $endtarget = " unicode character: \N{HEBREW LETTER ALEF}";
my $enddescription = " unicode character: \N{CYRILLIC CAPITAL LETTER YA}";
my $endarguments = " unicode character: \N{WON SIGN}";

BEGIN {
    no warnings 'once';
    $Win32::Unicode::Shortcut::CROAK_ON_ERROR = 1;
    Win32::Unicode::Shortcut->CoInitialize();
}


my $L = new Win32::Unicode::Shortcut();
isnt(undef, $L, 'new Win32::Unicode::Shortcut');

my $windows = $ENV{'SYSTEMROOT'} || $ENV{'WINDIR'} || "C:\\Windows";
$L->Path("$windows\\Notepad.exe");
my $temp = $ENV{'TEMP'} || File::Spec->tmpdir();

# Create a shortcut

$L->WorkingDirectory($temp);
$L->ShowCmd(3);
is($L->Save("test1".$endtarget.".lnk"), 1, "Save test1.lnk");
$L->Close(); 

# Reload the shortcut and modify it

my $L2 = new Win32::Unicode::Shortcut("test1".$endtarget.".lnk");
isnt(undef, $L2, 'new Win32::Unicode::Shortcut');
cmp_ok(lc($L2->{'Path'}),             'eq', lc($L->{'Path'}), 'Path');
cmp_ok(lc($L2->{'WorkingDirectory'}), 'eq', lc($L->{'WorkingDirectory'}), 'WorkingDirectory');
cmp_ok($L2->{'ShowCmd'},              '==', $L->{'ShowCmd'}, 'ShowCmd');
$L2->Set($windows."\\Write.exe",
	 $endarguments,
	 $windows,
	 "This is a description".$enddescription,
	 1,
	 hex('0x0337'),
	 "",
	 0);
is($L2->Save("test2".$endtarget.".lnk"), 1, "Save test2.lnk");

# Reload the shortcut

my $L3 = new Win32::Unicode::Shortcut("test2".$endtarget.".lnk");
isnt(undef, $L3, 'new Win32::Unicode::Shortcut');
cmp_ok(lc($L3->{'Path'}),             'eq', lc($windows."\\Write.exe"), 'Path');
cmp_ok($L3->{'Arguments'},            'eq', $endarguments, 'Arguments');
cmp_ok($L3->{'WorkingDirectory'},     'eq', $windows, 'WorkingDirectory');
cmp_ok($L3->{'Description'},          'eq', "This is a description".$enddescription, 'Description');
cmp_ok($L3->{'ShowCmd'},              '==', 1, 'ShowCmd');
cmp_ok($L3->{'Hotkey'},               '==', hex('0x0337'), 'HotKey');
cmp_ok(lc($L3->{'IconLocation'}),     'eq', lc(""), 'IconLocation');
cmp_ok($L3->{'IconNumber'},           '==', 0, 'IconNumber');
is($L3->Close(), 1, "Close");
undef $L;

$L = new Win32::Unicode::Shortcut();
isnt(undef, $L, 'new Win32::Unicode::Shortcut');

my $pathto = Win32::GetCwd();
$L->Path("$pathto\\dummy.txt");
$L->WorkingDirectory($pathto);
is($L->Save("test3".$endtarget.".lnk"), 1, "Save test3.lnk");
rename("dummy.txt", "dummy2.txt");
isnt($L->Resolve(), undef, "Resolve");
isnt(-f $L->{'Path'}, 0, "Existence of resolved path");
is($L->Save(), 1, "Save test3.lnk");
is($L->Close(), 1, "Close");

END {
    Win32::Unicode::Shortcut->CoUninitialize();
    unlink qw[dummy.txt dummy2.txt];
    if ($has_Win32API__File) {
	my $utf16le = find_encoding('UTF-16LE');
	if (defined($utf16le)) {
	    foreach (1..3) {
		DeleteFileW $utf16le->encode("test$_$endtarget.lnk\0");
	    }
	}
    }
}
