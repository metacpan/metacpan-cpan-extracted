#
# make sure delayed persist works.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use Config;
use File::Temp;

use vars qw(@OPTS $tmpdir $fn0 $fn1 $fn2);

BEGIN {
    $tmpdir = File::Temp->newdir(
        TEMPLATE => 'asserttestXXXXXXXX', CLEANUP => 0,
    );
    $fn0 = File::Temp::tempnam($tmpdir, 'asserttest');
    $fn1 = File::Temp::tempnam($tmpdir, 'asserttest');
    $fn2 = File::Temp::tempnam($tmpdir, 'asserttest');
    @OPTS = ('uuid1', ':persist='.$fn0);
    ok 1, 'began';
}

use UUID @OPTS;

ok 1, 'loaded';

my ($ts0, $ts1);

ok -d $tmpdir, 'tmpdir exists';
ok !-e $fn0,   'start persist missing';
ok !-e $fn1,   'later persist missing';
ok !-e $fn2,   'last persist missing';
is UUID::_defer(), 0, 'defer init 0';

uuid1();

ok -e $fn0, 'start persist found';

ok UUID::_defer(999999),   'defer changed';
is UUID::_defer(), 999999, 'long defer ok';
UUID::_persist($fn1);

uuid1();

ok !-e $fn1, 'later persist still missing';

ok UUID::_defer(0.00000001), 'defer changed again';
UUID::_persist($fn2);

uuid1();

ok -e $fn2, 'last persist found';

# close state so Win32 can cleanup
UUID::_persist(undef);
unlink $fn0;
unlink $fn1;
unlink $fn2;
rmdir  $tmpdir;

done_testing;

sub gettime {
    my ($fn) = @_;
    open my $fh, '<', $fn or return 0;
    #clock: 3735 tv: 0000001707180262 00390359 adj: 00000000
    my $dat = <$fh>;
    undef $fh;
    note $dat;
    my @vals = (split /\s+/, $dat)[3,4,6];

    # sleep here so the timestamps actually change.
    if (Time::HiRes::d_nanosleep()) {
        Time::HiRes::nanosleep(10_000_000); # 10ms
    }
    elsif (Time::HiRes::d_usleep()) {
        Time::HiRes::usleep(10_000); # 10ms
    }
    elsif ($Config{d_select}) {
        select undef, undef, undef, 0.01; # 10ms
    }
    else {
        sleep 1;
    }

    return sprintf '%d.%07d', $vals[0], $vals[1]*10+$vals[2];
}
