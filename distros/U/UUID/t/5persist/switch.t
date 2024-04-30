#
# start with persist on.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use Config;
use File::Temp;
use Time::HiRes ();

use vars qw(@OPTS $tmpdir $fn0 $fn1);

BEGIN {
    $tmpdir = File::Temp->newdir(
        TEMPLATE => 'asserttestXXXXXXXX', CLEANUP => 0,
    );
    $fn0 = File::Temp::tempnam($tmpdir, 'asserttest');
    $fn1 = File::Temp::tempnam($tmpdir, 'asserttest');
    @OPTS = ('uuid1', ':mac=random', ':persist='.$fn0);
}

use UUID @OPTS;

my ($ts0, $ts1);

ok 1, 'loaded';

ok -d $tmpdir, 'tmpdir exists';
ok !-e $fn0,   'start persist missing';
ok !-e $fn1,   'later persist missing';

uuid1();

ok -e $fn0, 'start persist found';
$ts0 = gettime($fn0);
#note $ts0;

UUID::_persist(undef);
uuid1();

$ts1 = gettime($fn0);
is $ts1, $ts0, 'start persist unchanged';

UUID::_persist($fn1);
uuid1();

ok -e $fn1, 'later persist found';
$ts1 = gettime($fn1);
cmp_ok $ts1, '>', $ts0, 'later larger than start';

UUID::_persist($fn0);
uuid1();

$ts0 = gettime($fn0);
cmp_ok $ts0, '>', $ts1, 'latest largest';

# close state so Win32 can cleanup
UUID::_persist(undef);
unlink $fn0;
unlink $fn1;
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
