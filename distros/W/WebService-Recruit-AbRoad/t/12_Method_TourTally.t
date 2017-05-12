#
# Test case for WebService::Recruit::AbRoad::TourTally
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
plan tests => 42;

use_ok('WebService::Recruit::AbRoad::TourTally');

my $service = new WebService::Recruit::AbRoad::TourTally();

ok( ref $service, 'new WebService::Recruit::AbRoad::TourTally()' );


# Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'keyword' => '登山',
    };
    my $res = new WebService::Recruit::AbRoad::TourTally();
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
    can_ok( $data, 'tour_tally' );
    ok( eval { $data->tour_tally }, 'Test[0]: tour_tally' );
    ok( eval { ref $data->tour_tally } eq 'ARRAY', 'Test[0]: tour_tally' );
    can_ok( $data->tour_tally->[0], 'type' );
    ok( eval { $data->tour_tally->[0]->type }, 'Test[0]: type' );
    can_ok( $data->tour_tally->[0], 'code' );
    ok( eval { $data->tour_tally->[0]->code }, 'Test[0]: code' );
    can_ok( $data->tour_tally->[0], 'name' );
    ok( eval { $data->tour_tally->[0]->name }, 'Test[0]: name' );
    can_ok( $data->tour_tally->[0], 'tour_count' );
    ok( eval { $data->tour_tally->[0]->tour_count }, 'Test[0]: tour_count' );
    can_ok( $data->tour_tally->[0], 'lat' );
    ok( eval { $data->tour_tally->[0]->lat }, 'Test[0]: lat' );
    can_ok( $data->tour_tally->[0], 'lng' );
    ok( eval { $data->tour_tally->[0]->lng }, 'Test[0]: lng' );
    can_ok( $data->tour_tally->[0], 'area' );
    ok( eval { $data->tour_tally->[0]->area }, 'Test[0]: area' );
    can_ok( $data->tour_tally->[0], 'country' );
    ok( eval { $data->tour_tally->[0]->country }, 'Test[0]: country' );
    can_ok( $data->tour_tally->[0]->area, 'code' );
    ok( eval { $data->tour_tally->[0]->area->code }, 'Test[0]: code' );
    can_ok( $data->tour_tally->[0]->area, 'name' );
    ok( eval { $data->tour_tally->[0]->area->name }, 'Test[0]: name' );
    can_ok( $data->tour_tally->[0]->country, 'code' );
    ok( eval { $data->tour_tally->[0]->country->code }, 'Test[0]: code' );
    can_ok( $data->tour_tally->[0]->country, 'name' );
    ok( eval { $data->tour_tally->[0]->country->name }, 'Test[0]: name' );
}

# Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::AbRoad::TourTally();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[1]: die' );
}

# Test[2]
{
    my $params = {
    };
    my $res = new WebService::Recruit::AbRoad::TourTally();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[2]: die' );
}


1;
