#
# compare v3 to v3.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# binary, default namespace/name
    generate_v3(my $u0, dns => 'www.example.com');
    generate_v3(my $u1, dns => 'www.example.com');
    ok !is_null($u0),        'is null 0';
    ok !is_null($u1),        'is null 1';
    is variant($u0), 1,      'variant 0';
    is variant($u1), 1,      'variant 1';
    is type($u0), 3,         'type 0';
    is type($u1), 3,         'type 1';
    is compare($u0, $u0), 0, 'compare binary equal 0';
    is compare($u1, $u1), 0, 'compare binary equal 1';
    is $u0, $u1,             'binary equal';

    my $t0 = compare($u0, $u1);
    my $t1 = compare($u1, $u0);
    is $t0, -$t1, 'opposites';
}

{# binary, with namespace/name
    generate_v3(my $u0, dns => 'www.example.com');
    generate_v3(my $u1, dns => 'www.example.com');
    ok !is_null($u0),        'is null 0';
    ok !is_null($u1),        'is null 1';
    is variant($u0), 1,      'variant 0';
    is variant($u1), 1,      'variant 1';
    is type($u0), 3,         'type 0';
    is type($u1), 3,         'type 1';
    is compare($u0, $u0), 0, 'compare binary equal 0';
    is compare($u1, $u1), 0, 'compare binary equal 1';
    is $u0, $u1,             'binary equal';

    my $t0 = compare($u0, $u1);
    my $t1 = compare($u1, $u0);
    is $t0, -$t1, 'opposites';
}

{# string, default namespace/name
    my $u0 = uuid3(dns => 'www.example.com');
    my $u1 = uuid3(dns => 'www.example.com');
    is $u0, $u1, 'string equal 0';

    my $t0 = compare($u0, $u1);
    my $t1 = compare($u1, $u0);
    is $t0, 0,    'string equal 1';
    is $t1, 0,    'string equal 2';
    is $t0, -$t1, 'compare string equal';
}

{# string, with namespace/name
    my $u0 = uuid3(dns => 'www.example.com');
    my $u1 = uuid3(dns => 'www.example.com');
    is $u0, $u1, 'string equal 0';

    my $t0 = compare($u0, $u1);
    my $t1 = compare($u1, $u0);
    is $t0, 0,    'string equal 1';
    is $t1, 0,    'string equal 2';
    is $t0, -$t1, 'compare string equal';
}

done_testing;
