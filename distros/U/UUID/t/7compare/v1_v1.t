#
# compare v1 to v1.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# binary
    generate_v1(my $u0);
    generate_v1(my $u1);
    ok   !is_null($u0),        'is null 0';
    ok   !is_null($u1),        'is null 1';
    is   variant($u0), 1,      'variant 0';
    is   variant($u1), 1,      'variant 1';
    is   type($u0), 1,         'type 0';
    is   type($u1), 1,         'type 1';
    is   compare($u0, $u0), 0, 'compare binary equal 0';
    is   compare($u1, $u1), 0, 'compare binary equal 1';
    isnt $u0, $u1,             'binary equal';

    my $t0 = compare($u0, $u1);
    my $t1 = compare($u1, $u0);
    is $t0, -$t1, 'opposites';
}

{# string
    my $u0 = uuid1();
    my $u1 = uuid1();
    isnt $u0, $u1, 'string equal 0';

    my $t0 = compare($u0, $u1);
    my $t1 = compare($u1, $u0);
    isnt $t0, 0,    'string equal 1';
    isnt $t1, 0,    'string equal 2';
    is   $t0, -$t1, 'compare string equal';
}

done_testing;
