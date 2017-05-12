# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-Unicode-Shortcut.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use File::Temp qw/tmpnam/;
use Encode;

use Test::More tests => 14;
BEGIN { use_ok('Win32::Unicode::Shortcut') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

BEGIN {
    no warnings 'once';
    $Win32::Unicode::Shortcut::CROAK_ON_ERROR = 1;
}

isnt(Win32::Unicode::Shortcut->CoInitialize(), 0, "CoInitialize");
my $LINK = new Win32::Unicode::Shortcut;
isnt(undef, $LINK, 'new Win32::Unicode::Shortcut');
my $lnk = tmpnam();
my $target = tmpnam() . '.lnk';
my $arguments = "Arg1 Arg2 euro-sign:" . chr(8364) . ", three chinese characters: 1=" . chr(25105) . ", 2=" . chr(29233) . ", 3=" . chr(20320);
my $dir = "C:\\";
my $description = "Target Description";
my $show = 1;
my $key = 115;
my $iconlocation = "%SystemRoot%\\system32\\SHELL32.dll";
my $iconnumber = 10;

$LINK->{'Path'} = $lnk;
$LINK->{'Description'} = $description;
$LINK->{'Arguments'} = $arguments;
$LINK->{'WorkingDirectory'} = $dir;
$LINK->{'ShowCmd'} = $show;
$LINK->{'Hotkey'} = $key;
$LINK->{'IconLocation'} = $iconlocation;
$LINK->{'IconNumber'} = $iconnumber;
$LINK->Save($target);
is($LINK->Save($target), 1, "Save");
is($LINK->Close(), 1, "Close");

my $LINK2 = new Win32::Unicode::Shortcut($target);
cmp_ok($LINK->{'Path'},             'eq', $lnk, 'Path');
cmp_ok($LINK->{'Description'},      'eq', $description, 'Description');
cmp_ok($LINK->{'Arguments'},        'eq', $arguments, 'Arguments');
cmp_ok($LINK->{'WorkingDirectory'}, 'eq', $dir, 'WorkingDirectory');
cmp_ok($LINK->{'ShowCmd'},          '==', $show, 'ShowCmd');
cmp_ok($LINK->{'Hotkey'},           '==', $key, 'HotKey');
cmp_ok($LINK->{'IconLocation'},     'eq', $iconlocation, 'IconLocation');
cmp_ok($LINK->{'IconNumber'},       '==', $iconnumber, 'IconNumber');
is($LINK2->Close(), 1, "Close");
Win32::Unicode::Shortcut->CoUninitialize();

unlink($target);
