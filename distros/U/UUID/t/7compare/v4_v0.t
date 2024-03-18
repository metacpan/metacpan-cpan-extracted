#
# compare v4 to v0.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# binary
    generate_v4(my $u4);
    generate_v0(my $u0);
    ok   is_null($u0),         'is null';
    isnt $u4, $u0,             'binary not null';
    is   compare($u4, $u0), 1, 'greater than binary';
}

{# string
    my $u4 = uuid4();
    my $u0 = uuid0();
    isnt $u4, $u0,             'string not null';
    is   compare($u4, $u0), 1, 'greater than string';
}

done_testing;
