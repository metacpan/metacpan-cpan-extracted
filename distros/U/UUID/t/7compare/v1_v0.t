#
# compare v1 to v0.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# binary
    generate_v1(my $u1);
    generate_v0(my $u0);
    ok   is_null($u0),         'is null';
    isnt $u1, $u0,             'binary not null';
    is   compare($u1, $u0), 1, 'greater than binary';
}

{# string
    my $u1 = uuid1();
    my $u0 = uuid0();
    isnt $u1, $u0,             'string not null';
    is   compare($u1, $u0), 1, 'greater than string';
}

done_testing;
