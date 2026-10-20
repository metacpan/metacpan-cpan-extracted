use strict;
use warnings;
use Test::More;

use lib 'lib', 't/lib';

use Test::FitNesse::Slim::StatementExecutor;
use Test::FitNesse::Slim::Statement;

my $executor = Test::FitNesse::Slim::StatementExecutor->new;
$executor->add_import('fitnesse.slim.test');

is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'make', 'make', 'sleep', 'Sleep'),
    ['make', 'OK'],
    'construct Sleep with its default zero-millisecond timer',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'zero', 'call', 'sleep', 'doSleep'),
    ['zero', 'WakeUp 0'],
    'doSleep reports the timer value',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'set', 'call', 'sleep', 'setTimer', 10),
    ['set', 'null'],
    'setTimer stores milliseconds and returns no value',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'short', 'call', 'sleep', 'doSleep'),
    ['short', 'WakeUp 10'],
    'doSleep waits for the configured duration and returns its message',
);

is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'negative', 'call', 'sleep', 'setTimer', -1),
    ['negative', 'null'],
    'setTimer accepts a value and leaves validation to Thread.sleep behavior',
);
like(
    Test::FitNesse::Slim::Statement->execute($executor, 'negative-call', 'call', 'sleep', 'doSleep')->[1],
    qr/IllegalArgumentException.*timeout value is negative/,
    'negative durations raise the upstream Java exception',
);

done_testing;
