#
# compare v0 to v0.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# binary
    generate_v0(my $u0);
    generate_v0(my $u1);
    ok is_null($u0),         'is null 0';
    ok is_null($u1),         'is null 1';
    is $u0, $u1,             'binary equal';
    is compare($u0, $u1), 0, 'compare binary equal';
}

{# string
    my $u0 = uuid0();
    my $u1 = uuid0();
    is $u0, $u1,             'string equal';
    is compare($u0, $u1), 0, 'compare string equal';
}

done_testing;
