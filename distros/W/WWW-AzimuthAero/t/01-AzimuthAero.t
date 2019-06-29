use Test::More;
use Data::Dumper;
use Mojo::UserAgent::Mockable;
use WWW::AzimuthAero::Mock;

BEGIN {
    use_ok('WWW::AzimuthAero');
}

my $az = WWW::AzimuthAero->new();

subtest 'get_schedule_dates' => sub {

    my @res = $az->get_schedule_dates( from => 'ROV', to => 'MOW' );
    ok(
        scalar @res > 1,
'no network problems, API endpoint is active and ROV->MOW flights has schedule'
    );
    ok( ref( $res[0] ) eq '', 'return array of strings' );
};

subtest 'get' => sub {

    my $ua_mock = Mojo::UserAgent::Mockable->new(
        mode         => 'playback',
        file         => WWW::AzimuthAero::Mock->filename,
        unrecognized => 'exception'
    );

    $az = WWW::AzimuthAero->new( ua_obj => $ua_mock );

    is_deeply(
        $az->get( %{ WWW::AzimuthAero::Mock->mock_data->{get} } ),
        [
            WWW::AzimuthAero::Flight->new(
                'flight_date'    => '23.06.2019',
                'departure_time' => '07:45',
                'arrival_time'   => '09:45',
                'fares'          => {
                    'lowest'     => 5980,
                    'svobodnyy'  => 10980,
                    'optimalnyy' => 5980
                },
                'from_city'  => 'ROV',
                'to_city'    => 'MOW',
                'flight_num' => 'A4 201'
            )
        ]
    );

};

done_testing();
