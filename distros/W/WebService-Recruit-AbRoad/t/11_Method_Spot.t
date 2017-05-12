#
# Test case for WebService::Recruit::AbRoad::Spot
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
plan tests => 51;

use_ok('WebService::Recruit::AbRoad::Spot');

my $service = new WebService::Recruit::AbRoad::Spot();

ok( ref $service, 'new WebService::Recruit::AbRoad::Spot()' );


# Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::AbRoad::Spot();
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
    can_ok( $data, 'spot' );
    ok( eval { $data->spot }, 'Test[0]: spot' );
    ok( eval { ref $data->spot } eq 'ARRAY', 'Test[0]: spot' );
    can_ok( $data->spot->[0], 'code' );
    ok( eval { $data->spot->[0]->code }, 'Test[0]: code' );
    can_ok( $data->spot->[0], 'name' );
    ok( eval { $data->spot->[0]->name }, 'Test[0]: name' );
    can_ok( $data->spot->[0], 'title' );
    ok( eval { $data->spot->[0]->title }, 'Test[0]: title' );
    can_ok( $data->spot->[0], 'description' );
    ok( eval { $data->spot->[0]->description }, 'Test[0]: description' );
    can_ok( $data->spot->[0], 'lat' );
    ok( eval { $data->spot->[0]->lat }, 'Test[0]: lat' );
    can_ok( $data->spot->[0], 'lng' );
    ok( eval { $data->spot->[0]->lng }, 'Test[0]: lng' );
    can_ok( $data->spot->[0], 'map_scale' );
    ok( eval { $data->spot->[0]->map_scale }, 'Test[0]: map_scale' );
    can_ok( $data->spot->[0], 'area' );
    ok( eval { $data->spot->[0]->area }, 'Test[0]: area' );
    can_ok( $data->spot->[0], 'country' );
    ok( eval { $data->spot->[0]->country }, 'Test[0]: country' );
    can_ok( $data->spot->[0], 'city' );
    ok( eval { $data->spot->[0]->city }, 'Test[0]: city' );
    can_ok( $data->spot->[0], 'url' );
    ok( eval { $data->spot->[0]->url }, 'Test[0]: url' );
    can_ok( $data->spot->[0]->area, 'code' );
    ok( eval { $data->spot->[0]->area->code }, 'Test[0]: code' );
    can_ok( $data->spot->[0]->area, 'name' );
    ok( eval { $data->spot->[0]->area->name }, 'Test[0]: name' );
    can_ok( $data->spot->[0]->country, 'code' );
    ok( eval { $data->spot->[0]->country->code }, 'Test[0]: code' );
    can_ok( $data->spot->[0]->country, 'name' );
    ok( eval { $data->spot->[0]->country->name }, 'Test[0]: name' );
    can_ok( $data->spot->[0]->city, 'code' );
    ok( eval { $data->spot->[0]->city->code }, 'Test[0]: code' );
    can_ok( $data->spot->[0]->city, 'name' );
    ok( eval { $data->spot->[0]->city->name }, 'Test[0]: name' );
}

# Test[1]
{
    my $params = {
    };
    my $res = new WebService::Recruit::AbRoad::Spot();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[1]: die' );
}


1;
