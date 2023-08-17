use strict; use warnings;
use Test::More;

use immutable::0 ':all';



my $a1 = iobj [];

# is ref($a1), 'ARRAY';

ok $a1->is_empty,
    '$a->is_empty works on empty seq';

is $a1->size, 0,
    '->size of empty seq is 0';

eval { $a1->[0] = 111 };

like $@, qr{^Not valid to set a value on an immutable::seq object},
    "Adding data to a seq causes an error";

ok not(defined($a1->[-1])),
    "->[-1] returns undef on empty seq";



my $id1 = $a1->id;

my $a2 = $a1->set(0, 111);

ok $a1->id != $a2->id,
    '->set() returns a different seq';

ok $a1->id == $id1,
    'seq id remains the same after a ->set() call';

ok $a1->is_empty,
    'First seq is still empty';

is $a2->get(0), 111,
   'New seq has key from method access';

is $a2->get(0), 111,
   'New seq has key from tied access';



eval { pop @$a2 };

like $@, qr{^Not valid to pop a value from an immutable::seq object},
    "Deleting data from a seq causes an error";

my $a3 = $a2->pop;

is $a2->[0], 111,
    "Value not popped from original";

ok $a3->is_empty,
    "Value popped from new object";



my $a4 = iseq(111, 222);

is $a4->[0], 111,
    "ArrayRef get works";

is $a4->get(1), 222,
    "->get method works";

like "$a4", qr/^<immutable::seq 2 \d+>/,
    "iseq stringifies to '$a4'";

$a4 ? pass "iseq used as boolean works"
    : fail "iseq used as boolean works";
not($a1)
    ? pass "iseq used as boolean works for empty seq"
    : fail "iseq used as boolean works for empty seq";



eval { push @$a4, 333 };

like $@, qr{^Not valid to push values onto an immutable::seq object},
    "Calling push on a seq causes an error";

my $a5 = $a4->push(333, 444);
is join('-', @$a5), '111-222-333-444',
    "->push(...) works on seq";

my ($a6, $v6) = $a5->shift;
is $v6, '111',
    "->shift() returns correct val";
is join('-', @$a6), '222-333-444',
    "->shift() returns correct new seq";

my $a7 = $a6->unshift(999, 888);
is join('-', @$a7), '999-888-222-333-444',
    "->unshift() works on seq";



done_testing;
