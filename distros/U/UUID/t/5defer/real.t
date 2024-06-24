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

uuid1();

ok -e $fn0, 'start persist found';

UUID::_persist($fn1);

uuid1();

ok !-e $fn1, 'later persist still missing';

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
