use Test::More tests=>1;
use Test::Tail::Multi files=>[qw()];
ok 1, "empty list of files handled";
