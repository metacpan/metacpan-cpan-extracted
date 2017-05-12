use Test::More tests=>4;
use Test::Tail::Multi files=>[qw(t/baz t/quux)];
is int @Test::Tail::Multi::monitored, 2, "right number of entries";

add_file('t/foo');
add_file('t/bar',"added bar");

is int @Test::Tail::Multi::monitored, 4, "right new number of entries";

eval {add_file 'nonexistent', "try to add nonexistent one"};
ok $@, 'failed as expected';
like $@, qr/Error opening nonexistent:/, "right message";
