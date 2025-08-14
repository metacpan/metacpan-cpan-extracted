use strict;
use warnings;
use Test::More tests => 10;
use XS::Base qw(has del def clr);

clr();
ok(!has("x"), "empty read returns undef");
ok(!has("x->y"), "empty read returns undef");
has("x->y", "v1");
is(has("x->y"), "v1", "write and read scalar");
ok(ref has("x") eq 'HASH', "hashref stored/read");

ok(has("x","value"), "hashref can not update to scalar");
is(has("x"), "value", "hashref can not update to scalar");

has("a->b->c", {k=>1});
ok(ref has("a->b->c") eq 'HASH', "hashref stored/read");
ok(ref has("a->b") eq 'HASH', "hashref stored/read");
# del
ok(del("a->b->c") == 1, "del returned 1");
ok(!has("a->b->c"), "deleted");

# del non-exist
#ok(del("no->such") == 0, "del non-exist returns 0");

