use strict; use warnings;
use Test::More;

use immutable::0 ':all';



my $m1 = iobj {};

ok $m1->is_empty,
    '$m->is_empty works on empty map';

is $m1->size, 0,
    '->size of empty map is 0';

eval { $m1->{x} = 111 };

like $@, qr{^Not valid to set a key/value on an immutable::map object},
    "Adding data to a map causes an error";



my $id1 = $m1->id;

my $m2 = $m1->set(x => 111);

ok $m1->id != $m2->id,
    '->set() returns a different map';

ok $m1->id == $id1,
    'map id remains the same after a ->set() call';

ok $m1->is_empty,
    'First map is still empty';

is $m2->get('x'), 111,
   'New map has key from method access';

is $m2->{x}, 111,
   'New map has key from tied access';



eval { delete $m2->{x} };

like $@, qr{^Not valid to delete a key from an immutable::map object},
    "Deleting data from a map causes an error";

my $m3 = $m2->del('x');

is $m2->{x}, 111,
    "Key not deleted from original";

ok $m3->is_empty,
    "Key deleted from new object";



my $m4 = imap(x => 111, y => 222);

is $m4->{x}, 111,
    "HashRef get works";

is $m4->get('y'), 222,
    "->get method works";

like "$m4", qr/^<immutable::map 2 \d+>/,
    "imap stringifies to '$m4'";

$m4 ? pass "imap used as boolean works"
    : fail "imap used as boolean works";
not($m1)
    ? pass "imap used as boolean works for empty map"
    : fail "imap used as boolean works for empty map";



my $m5 = $m4->set(aaa => 333, bbb => 444);
is $m5+0, 4, "->set() works for multiple pairs";
is join(',', $m5->keys), 'x,y,aaa,bbb',
    "->keys() method works";



my $m6 = $m5->set(x => 1234);
is join(',', $m5->keys), 'x,y,aaa,bbb',
    "->set() preserves key order";



done_testing;
