# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-Unicode-Shortcut.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use File::Temp qw/tmpnam/;
use Encode;
use threads;

use Test::More tests => 21;
BEGIN { use_ok('Win32::Unicode::Shortcut') };
Win32::Unicode::Shortcut->import('COINIT_APARTMENTTHREADED');

#########################

BEGIN {
    no warnings 'once';
    $Win32::Unicode::Shortcut::CROAK_ON_ERROR = 1;
}

my @thr = ();
foreach (0..19) {
    push(@thr, threads->create('start_thread'));
}
foreach (0..19) {
    isnt(0, $thr[$_]->join, 'thread join');
}

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
sub start_thread {
    Win32::Unicode::Shortcut->CoInitializeEx(COINIT_APARTMENTTHREADED);

    my $LINK = new Win32::Unicode::Shortcut;
    die "Undefined object\n" if (! defined($LINK));
    my $lnk = tmpnam() . threads->tid;
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
    $LINK->Save($target) || die "Save failure\n";
    $LINK->Close() || die "Close failure\n";

    my $LINK2 = new Win32::Unicode::Shortcut($target);
    die "Path not the same\n" if ($LINK->{'Path'} ne $lnk);
    die "Description not the samen" if ($LINK->{'Description'} ne $description);
    die "Arguments not the same\n" if ($LINK->{'Arguments'} ne $arguments);
    die "WorkingDirectory not the same\n" if ($LINK->{'WorkingDirectory'} ne $dir);
    die "ShowCmd not the same\n" if ($LINK->{'ShowCmd'} != $show);
    die "HotKey not the same\n" if ($LINK->{'Hotkey'} != $key);
    die "IconLocation not the same\n" if ($LINK->{'IconLocation'} ne $iconlocation);
    die "IconNumber not the same\n" if ($LINK->{'IconNumber'} != $iconnumber);
    $LINK2->Close() || die "Close failure\n";
    Win32::Unicode::Shortcut->CoUninitialize();

    unlink($target);

}
