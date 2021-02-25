use Test2::V0;
use Unit::Duration;

my $ud;

ok( lives { $ud = Unit::Duration->new }, 'new' ) or note $@;

isa_ok( $ud, 'Unit::Duration' );

my $table = q{
    y | yr  | year    =  4 qtrs
    q | qtr | quarter =  3 mons
    o | mon | month   =  4 wks
    w | wk  | week    =  5 days
    d | day           =  8 hrs
    h | hr  | hour    = 60 mins
    m | min | minute  = 60 secs
    s | sec | second
};

ok( lives { $ud = Unit::Duration->new(
    name        => 'alpha',
    table       => $table,
    intra_space => ' ',
    extra_space => ', ',
    pluralize   => 1,
    unit_type   => 'short',
    compress    => 0,
) }, 'new(...)' ) or note $@;

isa_ok( $ud, 'Unit::Duration' );

like( dies { $ud->set_table }, qr/^no name provided to set_table\(\)/, 'set_table()' );
like( dies { $ud->set_table('name') }, qr/^no table data provided to set_table\(\)/, 'set_table()' );

$ud->set_table( 'bravo', $table );

my $structure = [
    {
        duration => '4 qtr',
        letter   => 'y',
        long     => 'year',
        short    => 'yr',
    },
    {
        duration => '3 mon',
        letter   => 'q',
        long     => 'quarter',
        short    => 'qtr',
    },
    {
        duration => '4 wk',
        letter   => 'o',
        long     => 'month',
        short    => 'mon',
    },
    {
        duration => '5 day',
        letter   => 'w',
        long     => 'week',
        short    => 'wk',
    },
    {
        duration => '8 hr',
        letter   => 'd',
        short    => 'day',
    },
    {
        duration => '60 min',
        letter   => 'h',
        long     => 'hour',
        short    => 'hr',
    },
    {
        duration => '60 sec',
        letter   => 'm',
        long     => 'minute',
        short    => 'min',
    },
    {
        letter => 's',
        long   => 'second',
        short  => 'sec',
    },
];

$ud->set_table( 'charlie', $structure );

is(
    $ud->get_table_string($_),
    join( "\n",
        'y | yr | year = 4 qtr',
        'q | qtr | quarter = 3 mon',
        'o | mon | month = 4 wk',
        'w | wk | week = 5 day',
        'd | day = 8 hr',
        'h | hr | hour = 60 min',
        'm | min | minute = 60 sec',
        's | sec | second',
    ),
    qq{get_table_string('$_')},
) for ( qw( default alpha bravo charlie ) );

is(
    $ud->get_table_structure($_),
    $structure,
    qq{get_table_structure('$_')},
) for ( qw( default alpha bravo charlie ) );

$structure->[4]{duration} = '7 hr';
$ud->set_table( 'france', $structure );

is(
    $ud->get_table_string('france'),
    join( "\n",
        'y | yr | year = 4 qtr',
        'q | qtr | quarter = 3 mon',
        'o | mon | month = 4 wk',
        'w | wk | week = 5 day',
        'd | day = 7 hr',
        'h | hr | hour = 60 min',
        'm | min | minute = 60 sec',
        's | sec | second',
    ),
    qq{get_table_string('france')},
);

is( $ud->canonicalize('4d 6h 4d 3h'), '8 days, 9 hrs', q{canonicalize('4d 6h 4d 3h')} );

is(
    $ud->canonicalize( '4d 6h 4d 3h', { compress => 1 } ),
    '1 wk, 4 days, 1 hr',
    'canonicalize with compress',
);

is(
    $ud->canonicalize(
        '4d 6h 4d 3h',
        {
            intra_space => '',
            extra_space => ' ',
            pluralize   => 0,
            unit_type   => 'letter',
            compress    => 1,
        },
    ),
    '1w 4d 1h',
    'canonicalize with altered settings',
);

is(
    $ud->canonicalize(
        '3d 6h 1d 2h',
        {
            intra_space => ' ',
            extra_space => ', ',
            pluralize   => 1,
            unit_type   => 'short',
            compress    => 1,
        },
        $_->[0],
    ),
    $_->[1],
    qq{canonicalize with "$_->[0]" table},
) for (
    [ default => '1 wk' ],
    [ alpha   => '1 wk' ],
    [ bravo   => '1 wk' ],
    [ charlie => '1 wk' ],
    [ france  => '1 wk, 1 hr' ],
);

is( $ud->sum_as( hours => '2 days -6h' ), 10, 'sum_as' );
is( $ud->sum_as( hours => '2 days -6h', 'default' ), 10, 'sum_as with default' );
is( $ud->sum_as( hours => '2 days -6h', 'france' ), 8, 'sum_as with france' );

done_testing;
