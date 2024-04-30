#
# compare v5 to v0.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# binary
    generate_v5(my $u5, dns => 'www.example.com');
    generate_v0(my $u0);
    ok   is_null($u0),         'is null';
    isnt $u5, $u0,             'binary not null';
    is   compare($u5, $u0), 1, 'greater than binary';
}

{# string
    my $u5 = uuid5(dns => 'www.example.com');
    my $u0 = uuid0();
    isnt $u5, $u0,             'string not null';
    is   compare($u5, $u0), 1, 'greater than string';
}

done_testing;
