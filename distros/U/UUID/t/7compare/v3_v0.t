#
# compare v3 to v0.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# binary
    generate_v3(my $u3, dns => 'www.example.com');
    generate_v0(my $u0);
    ok   is_null($u0),         'is null';
    isnt $u3, $u0,             'binary not null';
    is   compare($u3, $u0), 1, 'greater than binary';
}

{# string
    my $u3 = uuid3(dns => 'www.example.com');
    my $u0 = uuid0();
    isnt $u3, $u0,             'string not null';
    is   compare($u3, $u0), 1, 'greater than string';
}

done_testing;
