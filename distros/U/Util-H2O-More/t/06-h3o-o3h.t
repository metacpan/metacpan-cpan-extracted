use strict;
use warnings;

use Test::More q//;
use Util::H2O::More qw/h2o o2h h3o o3h/;

# for included module required for testing
use FindBin qw/$Bin/;
use lib qq{$Bin/lib};
use Foo;

my $origin_ref = {
    somewhere => q{over},
    the       => { rainbow => { way => { out => q{there} } } },
};

my $ref = {
    somewhere => q{over},
    the       => { rainbow => { way => { out => q{there} } } },
};

h2o $ref;

is_deeply o2h($ref), $origin_ref, q{'o2h' does inverse of h2o};
is ref o2h($ref), q{HASH}, q{making sure test ref really is just a 'HASH'};

my $ref2 = o2h $ref;

h2o -recurse, $ref2;
is_deeply o2h($ref2), $origin_ref, q{'o2h' does inverse of 'h2o --recurse'};

my $ref3 = o2h $ref2;

# composing h2o/o2h in one line
is_deeply o2h( h2o $ref3), $origin_ref, q{'o2h' does inverse of 'h2o --recurse'};

my $foo = Foo->new( a => 1 );
is ref o2h($foo), q{HASH}, q{'o2h' works on baptised module-based object};

my $_foo = {
    somewhere => q{over},
    the       => { rainbow => { way => { out => q{there} } } },
};

my $foo2 = o2h( Foo->new(%$_foo) );

is_deeply $foo2, $_foo, q{'o2h' does invere of a package built with 'baptise -recurse'};

my $HoA1 = {
    one => [qw/1 2 3 4 5/],
    two => [qw/6 7 8 9 0/],
};

my $HoA2 = {
    one => [qw/1 2 3 4 5/],
    two => [qw/6 7 8 9 0/],
};

h2o $HoA1;
h3o $HoA2;

is_deeply o2h $HoA1, o3h $HoA2, q{HASH refs cleaned inline by h2o and h3o are identical};

# o2h/o3h returns unblessed datastructures, but doesn't
# affect the structure by reference, lik h2o/h3o does
# - this is for consistency with Util::H2O

$HoA1 = o2h $HoA1;
$HoA2 = o3h $HoA2;

is_deeply $HoA1, $HoA2, q{HASH refs purified by o2h and o3h are identical};

h2o $HoA1;
h3o $HoA2;

is_deeply $HoA1, $HoA2, q{h2o object is identical to h3o object};

my $HoAoH = {
    one   => [qw/1 2 3 4 5/],
    two   => [qw/6 7 8 9 0/],
    three => [ { four => 4, five => 5, six => 6 }, { seven => 7, eight => 8, nine => 9 }, ],
    ten   => {
        eleven    => [qw/11 12 13 14 15 16 17 18 19 20/],
        twentyone => [
            {
                twentytwo => 22,
            },
            {
                twentythree => 23,
            },
            {
                twentyfour => 24,
                twentyfive => 25,
                twentysix  => 26,
            },
        ],
        thirteen => 13,
    },
};

h3o $HoAoH;

is $HoAoH->one->[0],                       1,  q{ARRAY ref by index found via accessor};
is $HoAoH->ten->twentyone->[0]->twentytwo, 22, q{accessor deeply contained inside of ARRAY found};

PUSH_POP:
{
    my $twentyone = [
        {
            twentytwo => 22,
        },
        {
            twentythree => 23,
        },
        {
            twentyfour => 24,
            twentyfive => 25,
            twentysix  => 26,
        },
    ];

    my $i = 0;
    foreach my $e ( $HoAoH->ten->twentyone->all ) {
        like ref $e, qr/Util::H2O/, q{Found HASH ref as 'Util::H2O' reference, in list};
        foreach my $k ( keys %$e ) {
            can_ok $e, ($k);
            is $e->$k, $twentyone->[$i]->{$k}, qq{Got expected value for HASH deeply inside of an ARRAY};
        }
        ++$i;
    }

    $i = 0;
    while ( my $e = $HoAoH->ten->twentyone->pop ) {
        like ref $e, qr/Util::H2O/, q{(pop) Found HASH ref as 'Util::H2O' reference, in list};
        foreach my $k ( keys %$e ) {
            can_ok $e, ($k);
        }
        ++$i;
    }
    is $HoAoH->ten->twentyone->scalar, 0, q{ARRAY vmethod 'pop' emptied out entire array};

    for my $i ( 1 .. 5 ) {
        $HoAoH->ten->twentyone->push( { foo => $i } );    # note: for the astute observer, this hash is undecorated
        is $HoAoH->ten->twentyone->scalar, $i, qq{(item $i) ARRAY vmethod 'push' added something to the array};
    }
    $HoAoH->ten->twentyone->push( { foo => 6 }, { foo => 7 } );

    is $HoAoH->ten->twentyone->scalar, 7, q{'scalar' ARRAY vmethod works};
}

UNSHIFT_SHIFT:
{
    my $twentyone = [ { foo => 1 }, { foo => 2 }, { foo => 3 }, { foo => 4 }, { foo => 5 }, { foo => 6 }, { foo => 7 }, ];

    my $i = 0;
    foreach my $e ( $HoAoH->ten->twentyone->all ) {
        like ref $e, qr/Util::H2O/, q{Found HASH ref as 'Util::H2O' reference, in list};
        foreach my $k ( keys %$e ) {
            can_ok $e, ($k);
            is $e->$k, $twentyone->[$i]->{$k}, qq{Got expected value for HASH deeply inside of an ARRAY};
        }
        ++$i;
    }

    $i = 0;
    while ( my $e = $HoAoH->ten->twentyone->shift ) {
        like ref $e, qr/Util::H2O/, q{(shift) Found HASH ref as 'Util::H2O' reference, in list};
        foreach my $k ( keys %$e ) {
            can_ok $e, ($k);
        }
        ++$i;
    }
    is $HoAoH->ten->twentyone->scalar, 0, q{ARRAY vmethod 'shift' emptied out entire array};

    for my $i ( 1 .. 5 ) {
        $HoAoH->ten->twentyone->unshift( { foo => $i } );    # note: for the astute observer, this hash is undecorated
        is $HoAoH->ten->twentyone->scalar, $i, qq{(item $i) ARRAY vmethod 'unshift' added something to the array};
    }

    $HoAoH->ten->twentyone->unshift( { foo => 6 }, { foo => 7 } );

    is $HoAoH->ten->twentyone->scalar, 7, q{'scalar' ARRAY vmethod works};
}

my $mixed1 = [
    {
        one => 1,
        two => 2,
    },
    q{string},
    143,
    sub { 1 },
    undef,
];

my $mixed2 = [
    {
        one => 1,
        two => 2,
    },
    q{string},
    143,
    sub { 1 },
    undef,
];

h3o $mixed1;

is ref $mixed1->[3], ref $mixed2->[3], q{CODE refs have been preserved and are unaffected};

my $code1 = splice @$mixed1, 3, 1;
my $code2 = splice @$mixed2, 3, 1;

is $code1->(), $code2->(), q{CODE refs work};

is_deeply $mixed1, $mixed2, q{Mixed array, including undef and CODE ref treated properly};

done_testing;
