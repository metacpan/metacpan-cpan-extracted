#
# Test case for WebService::Recruit::AbRoad::City
#

use strict;
use Test::More;

{
    my $errs = [];
    foreach my $key ('WEBSERVICE_RECRUIT_KEY') {
        next if exists $ENV{$key};
        push(@$errs, $key);
    }
    plan skip_all => sprintf('set %s env to test this', join(", ", @$errs))
        if @$errs;
}
plan tests => 43;

use_ok('WebService::Recruit::AbRoad::City');

my $service = new WebService::Recruit::AbRoad::City();

ok( ref $service, 'new WebService::Recruit::AbRoad::City()' );


# Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::AbRoad::City();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( ! $@, 'Test[0]: die' );
    ok( ! $res->is_error, 'Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'Test[0]: root' );
    can_ok( $data, 'api_version' );
    ok( eval { $data->api_version }, 'Test[0]: api_version' );
    can_ok( $data, 'results_available' );
    ok( eval { $data->results_available }, 'Test[0]: results_available' );
    can_ok( $data, 'results_returned' );
    ok( eval { $data->results_returned }, 'Test[0]: results_returned' );
    can_ok( $data, 'results_start' );
    ok( eval { $data->results_start }, 'Test[0]: results_start' );
    can_ok( $data, 'city' );
    ok( eval { $data->city }, 'Test[0]: city' );
    ok( eval { ref $data->city } eq 'ARRAY', 'Test[0]: city' );
    can_ok( $data->city->[0], 'code' );
    ok( eval { $data->city->[0]->code }, 'Test[0]: code' );
    can_ok( $data->city->[0], 'name' );
    ok( eval { $data->city->[0]->name }, 'Test[0]: name' );
    can_ok( $data->city->[0], 'name_en' );
    ok( eval { $data->city->[0]->name_en }, 'Test[0]: name_en' );
    can_ok( $data->city->[0], 'tour_count' );
    ok( eval { $data->city->[0]->tour_count }, 'Test[0]: tour_count' );
    can_ok( $data->city->[0], 'lat' );
    ok( eval { $data->city->[0]->lat }, 'Test[0]: lat' );
    can_ok( $data->city->[0], 'lng' );
    ok( eval { $data->city->[0]->lng }, 'Test[0]: lng' );
    can_ok( $data->city->[0], 'area' );
    ok( eval { $data->city->[0]->area }, 'Test[0]: area' );
    can_ok( $data->city->[0], 'country' );
    ok( eval { $data->city->[0]->country }, 'Test[0]: country' );
    can_ok( $data->city->[0]->area, 'code' );
    ok( eval { $data->city->[0]->area->code }, 'Test[0]: code' );
    can_ok( $data->city->[0]->area, 'name' );
    ok( eval { $data->city->[0]->area->name }, 'Test[0]: name' );
    can_ok( $data->city->[0]->country, 'code' );
    ok( eval { $data->city->[0]->country->code }, 'Test[0]: code' );
    can_ok( $data->city->[0]->country, 'name' );
    ok( eval { $data->city->[0]->country->name }, 'Test[0]: name' );
    can_ok( $data->city->[0]->country, 'name_en' );
    ok( eval { $data->city->[0]->country->name_en }, 'Test[0]: name_en' );
}

# Test[1]
{
    my $params = {
    };
    my $res = new WebService::Recruit::AbRoad::City();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[1]: die' );
}


1;
