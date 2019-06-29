use Test::More;
use Test::Exception;
use utf8;

use Data::Dumper;

BEGIN {
    use_ok( 'WWW::AzimuthAero::Flight', qw(:all) );
}

my $flight = WWW::AzimuthAero::Flight->new(
    from_city   => 'ROV',
    to_city     => 'KLF',
    flight_date => '16.06.2019',
    foo         => 'bar'
);

subtest 'as_hash' => sub {

    is_deeply(
        {
            'stop_at_city'   => undef,
            'arrival_time'   => undef,
            'has_stops'      => undef,
            'flight_num'     => undef,
            'from_city'      => 'ROV',
            'flight_date'    => '16.06.2019',
            'to_city'        => 'KLF',
            'departure_time' => undef,
            'fares'          => undef,
            'trip_duration'  => undef
        },
        $flight->as_hashref,
'Fill other methods by undef in no values provided and values which are not valid properties'
    );

    is_deeply(
        {
            'from_city'   => 'ROV',
            'flight_date' => '16.06.2019'
        },
        $flight->as_hashref( only => [qw/from_city flight_date/] ),
        'only property is working'
    );

    is_deeply(
        {
            'stop_at_city'   => undef,
            'arrival_time'   => undef,
            'has_stops'      => undef,
            'flight_num'     => undef,
            'from_city'      => 'ROV',
            'flight_date'    => '16.06.2019',
            'departure_time' => undef,
            'trip_duration'  => undef
        },
        $flight->as_hashref( skip => [qw/to_city fares/] ),
        'skip property is working'
    );

    is_deeply(
        {
            'from_city'  => 'ROV',
            'flight_num' => undef,
        },
        $flight->as_hashref(
            only => [qw/flight_date from_city flight_num/],
            skip => [qw/flight_date/]
        ),
        'skip and only properties are working together'
    );

};

subtest 'as_string' => sub {

    my $flight = WWW::AzimuthAero::Flight->new(
        {
            'arrival_time'   => '21:45',
            'departure_time' => '19:45',
            'flight_date'    => '15.10.2019',
            'flight_num'     => 'A4 231',
            'from_city'      => 'ROV',
            'to_city'        => 'VOG',
            'fares'          => {
                'svobodnyy'  => '2580',
                'lowest'     => '888',
                'vygodnyy'   => '1380',
                'komfort'    => '10080',
                'optimalnyy' => '1780',
                'legkiy'     => '888'
            },
        },
    );

    is(
        $flight->as_string,
        '21:45 19:45 888 15.10.2019 A4 231 ROV VOG',
        'as_string is sorting alphabetically by default'
    );

    is(
        $flight->as_string( order => [qw/flight_date flight_num/] ),
        '15.10.2019 A4 231 21:45 19:45 888 ROV VOG',
        'order param is working fine'
    );
};

done_testing;

