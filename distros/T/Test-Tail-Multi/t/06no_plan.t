use Test::Tail::Multi files=>'t/bar', 'no_plan';
use Test::More;
is int @Test::Tail::Multi::monitored, 1, "can handle 'no_plan'";
