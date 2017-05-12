# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-Unicode-Shortcut.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Cwd;
use Win32;
use File::Spec;

use Test::More tests => 24;
BEGIN { use_ok('Win32::Unicode::Shortcut') };

#########################

# Adapted sample.pl from the Win32::Shortcut Package

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
is($L->Save("test1.lnk"), 1, "Save test1.lnk");
$L->Close(); 

# Reload the shortcut and modify it

my $L2 = new Win32::Unicode::Shortcut("test1.lnk");
isnt(undef, $L2, 'new Win32::Unicode::Shortcut');
cmp_ok(lc($L2->{'Path'}),             'eq', lc($L->{'Path'}), 'Path');
cmp_ok(lc($L2->{'WorkingDirectory'}), 'eq', lc($L->{'WorkingDirectory'}), 'WorkingDirectory');
cmp_ok($L2->{'ShowCmd'},              '==', $L->{'ShowCmd'}, 'ShowCmd');
$L2->Set($windows."\\Write.exe",
	 "",
	 $windows,
	 "This is a description",
	 1,
	 hex('0x0337'),
	 "",
	 0);
is($L2->Save("test2.lnk"), 1, "Save test2.lnk");

# Reload the shortcut

my $L3 = new Win32::Unicode::Shortcut("test2.lnk");
isnt(undef, $L3, 'new Win32::Unicode::Shortcut');
cmp_ok(lc($L3->{'Path'}),             'eq', lc($windows."\\Write.exe"), 'Path');
cmp_ok($L3->{'Arguments'},            'eq', "", 'Arguments');
cmp_ok($L3->{'WorkingDirectory'},     'eq', $windows, 'WorkingDirectory');
cmp_ok($L3->{'Description'},          'eq', "This is a description", 'Description');
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
is($L->Save("test3.lnk"), 1, "Save test3.lnk");
rename("dummy.txt", "dummy2.txt");
isnt($L->Resolve(), undef, "Resolve");
isnt(-f $L->{'Path'}, 0, "Existence of resolved path");
is($L->Save(), 1, "Save test3.lnk");
is($L->Close(), 1, "Close");

END { Win32::Unicode::Shortcut->CoUninitialize();
      unlink qw[dummy.txt dummy2.txt test1.lnk test2.lnk test3.lnk]; }
