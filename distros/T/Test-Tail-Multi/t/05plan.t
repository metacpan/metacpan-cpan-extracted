use Test::Tail::Multi files=>'t/bar', tests=>1;
use Test::More;
is int @Test::Tail::Multi::monitored, 1, "can handle 'tests'";
