#
# make sure delayed persist works in forks.
#
# Note that this test is really misleading. It seems to indicate a
# behavior that is correct, which is incorrect. What it really does is
# document the behavior of defer as it is now, in case it changes
# somehow in the future.
#
# Ideally, deferrals should work by delaying writes across all processes
# based on the last write by any process. To do that though, would mean
# each potential write would need to read the persist file first, which
# defeats the purpose of defer.
#
# Instead, deferrals work based on internal timestamps in each process.
#
# Interestingly though, this test fails on psuedofork platforms.
# Apparently the underlying threads keep the internal timestamps in sync
# across "processes".
#
use strict;
use warnings;
use Test::More;
use MyNote;
use Config;
use File::Temp;

use vars qw(@OPTS $tmpdir $fn0 $fn1 $fn2);

BEGIN {
    plan skip_all => 'pseudofork platform'
        if $Config{d_pseudofork};

    $tmpdir = File::Temp->newdir(CLEANUP => 0);
    $fn0 = File::Temp::tempnam($tmpdir, 'UUID.test');
    $fn1 = File::Temp::tempnam($tmpdir, 'UUID.test.');
    $fn2 = File::Temp::tempnam($tmpdir, 'UUID.test.');
    @OPTS = ('uuid1', ':persist='.$fn0, ':defer=999999');
    ok 1, 'began';
}

use UUID @OPTS;

ok 1, 'loaded';

my ($ts0, $ts1);

ok -d $tmpdir, 'tmpdir exists';
ok !-e $fn0,   'start persist missing';
ok !-e $fn1,   'later persist missing';
ok !-e $fn2,   'last persist missing';
is UUID::_defer(), 999999, 'defer init long';

{
    my $kid = fork;
    if (!defined $kid) {
        fail 'fork1';
    }
    elsif ($kid == 0) {
        uuid1();
        exit 0;
    }
    else {
        pass 'fork1';
        waitpid $kid, 0;
    }
}

ok -e $fn0, 'start persist found';

UUID::_persist($fn1);

uuid1();

ok -e $fn1, 'later persist found';

ok UUID::_defer(0.00000001), 'defer changed';
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
