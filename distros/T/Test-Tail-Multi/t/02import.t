use Test::More tests=>3;
use Test::Tail::Multi;

ok(defined \&add_file);
ok(defined \&contents_like);
ok(defined \&contents_unlike);
