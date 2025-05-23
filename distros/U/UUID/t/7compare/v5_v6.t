#
# compare v5 to v6.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ':all';

ok 1, 'loaded';

{# binary
    generate_v5(my $u0, dns => 'www.example.com');
    generate_v6(my $u1);
    ok   !is_null($u0),        'is null 0';
    ok   !is_null($u1),        'is null 1';
    is   variant($u0), 1,      'variant 0';
    is   variant($u1), 1,      'variant 1';
    is   type($u0), 5,         'type 0';
    is   type($u1), 6,         'type 1';
    is   compare($u0, $u0), 0, 'compare binary equal 0';
    is   compare($u1, $u1), 0, 'compare binary equal 1';
    isnt $u0, $u1,             'binary equal';

    my $t0 = compare($u0, $u1);
    my $t1 = compare($u1, $u0);
    is $t0, -$t1, 'opposites';
    is $t1, 1,    'higher binary version';
}

{# string
    my $u0 = uuid5(dns => 'www.example.com');
    my $u1 = uuid6();
    isnt $u0, $u1, 'string equal 0';

    my $t0 = compare($u0, $u1);
    my $t1 = compare($u1, $u0);
    isnt $t0, 0,    'string equal 1';
    isnt $t1, 0,    'string equal 2';
    is   $t0, -$t1, 'compare string equal';

    # string compare not supported.. yet?
    #is   $t1, 1,    'higher string version';
}

done_testing;
