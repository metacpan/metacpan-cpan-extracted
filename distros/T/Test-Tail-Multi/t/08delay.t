use Test::More tests=>3;
use Test::Tail::Multi;

is($Test::Tail::Multi::tail_delay, 5, '5-second default');
delay(10);
is($Test::Tail::Multi::tail_delay, 10, 'now a 10-second delay');
delay(2,"resetting delay to 2 seconds");
is($Test::Tail::Multi::tail_delay, 2,  '2-second delay');
