use Test::More;
use Test::Exception;
use utf8;

use Data::Dumper;

BEGIN {
    use_ok( 'WWW::AzimuthAero::RouteMap', qw(:all) );
}

dies_ok { WWW::AzimuthAero::RouteMap->new( [] ) }
'expecting to die if not a hash';

my $rm_raw = {
    'РОВ' => {
        'IATA'   => 'ROV',
        'NAME'   => 'Ростов-на-Дону',
        'ROUTES' => { 'СПТ' => 'СПТ', 'ПСК' => 'ПСК' }
        ,    # + 'МОВ' => 'МОВ' for causing bug
        'COUNTRY' => 'Россия'
    },
    'СПТ' => {
        'IATA'    => 'LED',
        'ROUTES'  => { 'РОВ' => 'РОВ', 'ЭЛИ' => 'ЭЛИ' },
        'COUNTRY' => 'Россия',
        'NAME'    => 'Санкт-Петербург'
    },
    'ПСК' => {
        'NAME'    => 'Псков',
        'ROUTES'  => { 'ЭЛИ' => 'ЭЛИ', 'РОВ' => 'РОВ' },
        'COUNTRY' => 'Россия',
        'IATA'    => 'PKV'
    },
    'ЭЛИ' => {
        'ROUTES'  => { 'ПСК' => 'ПСК', 'РОВ' => 'РОВ' },
        'COUNTRY' => 'Россия',
        'IATA'    => 'ESL',
        'NAME'    => 'Элиста'
    }
};

my $rm = WWW::AzimuthAero::RouteMap->new($rm_raw);

subtest 'all_cities' => sub {

    is_deeply(
        [ map { $_->{NAME} } $rm->all_cities() ],
        [qw/Псков Ростов-на-Дону Санкт-Петербург Элиста/]
    );

};

subtest 'route_map_iata' => sub {

    is_deeply(
        $rm->route_map_iata(),
        {
            'LED' => [ 'ESL', 'ROV' ],
            'ESL' => [ 'PKV', 'ROV' ],
            'ROV' => [ 'LED', 'PKV' ],
            'PKV' => [ 'ESL', 'ROV' ]
        },
    );

};

subtest 'get_neighbor_airports_iata' => sub {

    is_deeply [ $rm->get_neighbor_airports_iata('LED') ], ['PKV'],
      'Return Pskov for St.Petersburg as neighbor';

};

# subtest '_all_paths_btw_vertexes_w_l2' => sub {
#
# }

done_testing();

