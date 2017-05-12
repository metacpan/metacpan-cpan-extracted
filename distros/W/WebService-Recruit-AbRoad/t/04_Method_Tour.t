#
# Test case for WebService::Recruit::AbRoad::Tour
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
plan tests => 112;

use_ok('WebService::Recruit::AbRoad::Tour');

my $service = new WebService::Recruit::AbRoad::Tour();

ok( ref $service, 'new WebService::Recruit::AbRoad::Tour()' );


# Test[0]
{
    my $params = {
        'area' => 'EUR',
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::AbRoad::Tour();
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
    can_ok( $data, 'tour' );
    ok( eval { $data->tour }, 'Test[0]: tour' );
    ok( eval { ref $data->tour } eq 'ARRAY', 'Test[0]: tour' );
    can_ok( $data->tour->[0], 'id' );
    ok( eval { $data->tour->[0]->id }, 'Test[0]: id' );
    can_ok( $data->tour->[0], 'last_update' );
    ok( eval { $data->tour->[0]->last_update }, 'Test[0]: last_update' );
    can_ok( $data->tour->[0], 'term' );
    ok( eval { $data->tour->[0]->term }, 'Test[0]: term' );
    can_ok( $data->tour->[0], 'title' );
    ok( eval { $data->tour->[0]->title }, 'Test[0]: title' );
    can_ok( $data->tour->[0], 'airline' );
    ok( eval { $data->tour->[0]->airline }, 'Test[0]: airline' );
    ok( eval { ref $data->tour->[0]->airline } eq 'ARRAY', 'Test[0]: airline' );
    can_ok( $data->tour->[0], 'airline_summary' );
    ok( eval { $data->tour->[0]->airline_summary }, 'Test[0]: airline_summary' );
    can_ok( $data->tour->[0], 'brand' );
    ok( eval { $data->tour->[0]->brand }, 'Test[0]: brand' );
    can_ok( $data->tour->[0], 'city_summary' );
    ok( eval { $data->tour->[0]->city_summary }, 'Test[0]: city_summary' );
    can_ok( $data->tour->[0], 'dept_city' );
    ok( eval { $data->tour->[0]->dept_city }, 'Test[0]: dept_city' );
    can_ok( $data->tour->[0], 'hotel' );
    ok( eval { $data->tour->[0]->hotel }, 'Test[0]: hotel' );
    ok( eval { ref $data->tour->[0]->hotel } eq 'ARRAY', 'Test[0]: hotel' );
    can_ok( $data->tour->[0], 'hotel_summary' );
    ok( eval { $data->tour->[0]->hotel_summary }, 'Test[0]: hotel_summary' );
    can_ok( $data->tour->[0], 'kodawari' );
    ok( eval { $data->tour->[0]->kodawari }, 'Test[0]: kodawari' );
    ok( eval { ref $data->tour->[0]->kodawari } eq 'ARRAY', 'Test[0]: kodawari' );
    can_ok( $data->tour->[0], 'price' );
    ok( eval { $data->tour->[0]->price }, 'Test[0]: price' );
    can_ok( $data->tour->[0], 'sche' );
    ok( eval { $data->tour->[0]->sche }, 'Test[0]: sche' );
    ok( eval { ref $data->tour->[0]->sche } eq 'ARRAY', 'Test[0]: sche' );
    can_ok( $data->tour->[0], 'urls' );
    ok( eval { $data->tour->[0]->urls }, 'Test[0]: urls' );
    can_ok( $data->tour->[0]->airline->[0], 'code' );
    ok( eval { $data->tour->[0]->airline->[0]->code }, 'Test[0]: code' );
    can_ok( $data->tour->[0]->airline->[0], 'name' );
    ok( eval { $data->tour->[0]->airline->[0]->name }, 'Test[0]: name' );
    can_ok( $data->tour->[0]->brand, 'code' );
    ok( eval { $data->tour->[0]->brand->code }, 'Test[0]: code' );
    can_ok( $data->tour->[0]->brand, 'name' );
    ok( eval { $data->tour->[0]->brand->name }, 'Test[0]: name' );
    can_ok( $data->tour->[0]->dept_city, 'name' );
    ok( eval { $data->tour->[0]->dept_city->name }, 'Test[0]: name' );
    can_ok( $data->tour->[0]->dept_city, 'code' );
    ok( eval { $data->tour->[0]->dept_city->code }, 'Test[0]: code' );
    can_ok( $data->tour->[0]->hotel->[0], 'name' );
    ok( eval { $data->tour->[0]->hotel->[0]->name }, 'Test[0]: name' );
    can_ok( $data->tour->[0]->hotel->[0], 'city' );
    ok( eval { $data->tour->[0]->hotel->[0]->city }, 'Test[0]: city' );
    can_ok( $data->tour->[0]->kodawari->[0], 'code' );
    ok( eval { $data->tour->[0]->kodawari->[0]->code }, 'Test[0]: code' );
    can_ok( $data->tour->[0]->kodawari->[0], 'name' );
    ok( eval { $data->tour->[0]->kodawari->[0]->name }, 'Test[0]: name' );
    can_ok( $data->tour->[0]->price, 'all_month' );
    ok( eval { $data->tour->[0]->price->all_month }, 'Test[0]: all_month' );
    can_ok( $data->tour->[0]->price, 'min' );
    ok( eval { $data->tour->[0]->price->min }, 'Test[0]: min' );
    can_ok( $data->tour->[0]->price, 'max' );
    ok( eval { $data->tour->[0]->price->max }, 'Test[0]: max' );
    can_ok( $data->tour->[0]->sche->[0], 'day' );
    ok( eval { $data->tour->[0]->sche->[0]->day }, 'Test[0]: day' );
    can_ok( $data->tour->[0]->sche->[0], 'city' );
    ok( eval { $data->tour->[0]->sche->[0]->city }, 'Test[0]: city' );
    can_ok( $data->tour->[0]->urls, 'mobile' );
    ok( eval { $data->tour->[0]->urls->mobile }, 'Test[0]: mobile' );
    can_ok( $data->tour->[0]->urls, 'pc' );
    ok( eval { $data->tour->[0]->urls->pc }, 'Test[0]: pc' );
    can_ok( $data->tour->[0]->urls, 'qr' );
    ok( eval { $data->tour->[0]->urls->qr }, 'Test[0]: qr' );
    can_ok( $data->tour->[0]->hotel->[0]->city, 'code' );
    ok( eval { $data->tour->[0]->hotel->[0]->city->code }, 'Test[0]: code' );
    can_ok( $data->tour->[0]->hotel->[0]->city, 'name' );
    ok( eval { $data->tour->[0]->hotel->[0]->city->name }, 'Test[0]: name' );
    can_ok( $data->tour->[0]->price->all_month, 'min' );
    ok( eval { $data->tour->[0]->price->all_month->min }, 'Test[0]: min' );
    can_ok( $data->tour->[0]->price->all_month, 'max' );
    ok( eval { $data->tour->[0]->price->all_month->max }, 'Test[0]: max' );
    can_ok( $data->tour->[0]->sche->[0]->city, 'code' );
    ok( eval { $data->tour->[0]->sche->[0]->city->code }, 'Test[0]: code' );
    can_ok( $data->tour->[0]->sche->[0]->city, 'name' );
    ok( eval { $data->tour->[0]->sche->[0]->city->name }, 'Test[0]: name' );
    can_ok( $data->tour->[0]->sche->[0]->city, 'area' );
    ok( eval { $data->tour->[0]->sche->[0]->city->area }, 'Test[0]: area' );
    can_ok( $data->tour->[0]->sche->[0]->city, 'country' );
    ok( eval { $data->tour->[0]->sche->[0]->city->country }, 'Test[0]: country' );
}

# Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::AbRoad::Tour();
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
    my $res = new WebService::Recruit::AbRoad::Tour();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[2]: die' );
}


1;
