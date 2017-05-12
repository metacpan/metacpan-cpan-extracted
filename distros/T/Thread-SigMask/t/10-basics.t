#!perl -T

use Test::More tests => 13;
use Thread::SigMask qw/sigmask/;
use POSIX qw/SIG_BLOCK SIG_UNBLOCK SIGUSR1 SIGUSR2/;

my $counter1 = 0;
my $counter2 = 0;

$SIG{USR1} = sub { $counter1++ };
$SIG{USR2} = sub { $counter2++ };

is $counter1, 0, 'Counter1 starts at zero';
is $counter2, 0, 'Counter2 starts at zero';

ok kill(SIGUSR1, $$), 'Sent usr1 signal';

is $counter1, 1, 'Counter1 is 1 now';
is $counter2, 0, 'Counter2 is still 0';

ok sigmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR1)), 'Masking succeeded';

ok kill(SIGUSR1, $$), 'Sent usr1 signal';
ok kill(SIGUSR2, $$), 'Sent usr2 signal';

is $counter1, 1, 'Counter1 is still 1';
is $counter2, 1, 'Counter2 is now 1';

ok sigmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1)), 'Unmasking succeeded';

is $counter1, 2, 'Counter is 2 now';
is $counter2, 1, 'Counter is still 1';
