#
# Test case for WebService::Recruit::AbRoad::Hotel
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
plan tests => 56;

use_ok('WebService::Recruit::AbRoad::Hotel');

my $service = new WebService::Recruit::AbRoad::Hotel();

ok( ref $service, 'new WebService::Recruit::AbRoad::Hotel()' );


# Test[0]
{
    my $params = {
        'area' => 'EUR',
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::AbRoad::Hotel();
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
    can_ok( $data, 'hotel' );
    ok( eval { $data->hotel }, 'Test[0]: hotel' );
    ok( eval { ref $data->hotel } eq 'ARRAY', 'Test[0]: hotel' );
    can_ok( $data->hotel->[0], 'code' );
    ok( eval { $data->hotel->[0]->code }, 'Test[0]: code' );
    can_ok( $data->hotel->[0], 'name' );
    ok( eval { $data->hotel->[0]->name }, 'Test[0]: name' );
    can_ok( $data->hotel->[0], 'name_en' );
    ok( eval { $data->hotel->[0]->name_en }, 'Test[0]: name_en' );
    can_ok( $data->hotel->[0], 'tour_count' );
    ok( eval { $data->hotel->[0]->tour_count }, 'Test[0]: tour_count' );
    can_ok( $data->hotel->[0], 'city' );
    ok( eval { $data->hotel->[0]->city }, 'Test[0]: city' );
    can_ok( $data->hotel->[0]->city, 'code' );
    ok( eval { $data->hotel->[0]->city->code }, 'Test[0]: code' );
    can_ok( $data->hotel->[0]->city, 'name' );
    ok( eval { $data->hotel->[0]->city->name }, 'Test[0]: name' );
    can_ok( $data->hotel->[0]->city, 'name_en' );
    ok( eval { $data->hotel->[0]->city->name_en }, 'Test[0]: name_en' );
    can_ok( $data->hotel->[0]->city, 'area' );
    ok( eval { $data->hotel->[0]->city->area }, 'Test[0]: area' );
    can_ok( $data->hotel->[0]->city, 'country' );
    ok( eval { $data->hotel->[0]->city->country }, 'Test[0]: country' );
    can_ok( $data->hotel->[0]->city->area, 'code' );
    ok( eval { $data->hotel->[0]->city->area->code }, 'Test[0]: code' );
    can_ok( $data->hotel->[0]->city->area, 'name' );
    ok( eval { $data->hotel->[0]->city->area->name }, 'Test[0]: name' );
    can_ok( $data->hotel->[0]->city->country, 'code' );
    ok( eval { $data->hotel->[0]->city->country->code }, 'Test[0]: code' );
    can_ok( $data->hotel->[0]->city->country, 'name' );
    ok( eval { $data->hotel->[0]->city->country->name }, 'Test[0]: name' );
    can_ok( $data->hotel->[0]->city->country, 'name_en' );
    ok( eval { $data->hotel->[0]->city->country->name_en }, 'Test[0]: name_en' );
}

# Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::AbRoad::Hotel();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( ! $@, 'Test[1]: die' );
    ok( ! $res->is_error, 'Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'Test[1]: root' );
    can_ok( $data, 'api_version' );
    ok( eval { $data->api_version }, 'Test[1]: api_version' );
    can_ok( $data, 'error' );
    ok( eval { $data->error }, 'Test[1]: error' );
    can_ok( $data->error, 'message' );
    ok( eval { $data->error->message }, 'Test[1]: message' );
}

# Test[2]
{
    my $params = {
    };
    my $res = new WebService::Recruit::AbRoad::Hotel();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[2]: die' );
}


1;
