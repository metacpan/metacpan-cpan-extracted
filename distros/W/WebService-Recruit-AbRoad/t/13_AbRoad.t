#
# Test case for WebService::Recruit::AbRoad
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
plan tests => 384;

use_ok('WebService::Recruit::AbRoad');

my $obj = WebService::Recruit::AbRoad->new();

ok(ref $obj, 'new WebService::Recruit::AbRoad()');


# tour / Test[0]
{
    my $params = {
        'area' => 'EUR',
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->tour(%$params); };
    ok( ! $@, 'tour / Test[0]: die' );
    ok( ! $res->is_error, 'tour / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'tour / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'tour / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'tour / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'tour / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'tour / Test[0]: results_start' );
    }
    can_ok( $data, 'tour' );
    if ( $data->can('tour') ) {
        ok( $data->tour, 'tour / Test[0]: tour' );
        ok( ref $data->tour eq 'ARRAY', 'tour / Test[0]: tour' );
    }
    can_ok( $data->tour->[0], 'id' );
    if ( $data->tour->[0]->can('id') ) {
        ok( $data->tour->[0]->id, 'tour / Test[0]: id' );
    }
    can_ok( $data->tour->[0], 'last_update' );
    if ( $data->tour->[0]->can('last_update') ) {
        ok( $data->tour->[0]->last_update, 'tour / Test[0]: last_update' );
    }
    can_ok( $data->tour->[0], 'term' );
    if ( $data->tour->[0]->can('term') ) {
        ok( $data->tour->[0]->term, 'tour / Test[0]: term' );
    }
    can_ok( $data->tour->[0], 'title' );
    if ( $data->tour->[0]->can('title') ) {
        ok( $data->tour->[0]->title, 'tour / Test[0]: title' );
    }
    can_ok( $data->tour->[0], 'airline' );
    if ( $data->tour->[0]->can('airline') ) {
        ok( $data->tour->[0]->airline, 'tour / Test[0]: airline' );
        ok( ref $data->tour->[0]->airline eq 'ARRAY', 'tour / Test[0]: airline' );
    }
    can_ok( $data->tour->[0], 'airline_summary' );
    if ( $data->tour->[0]->can('airline_summary') ) {
        ok( $data->tour->[0]->airline_summary, 'tour / Test[0]: airline_summary' );
    }
    can_ok( $data->tour->[0], 'brand' );
    if ( $data->tour->[0]->can('brand') ) {
        ok( $data->tour->[0]->brand, 'tour / Test[0]: brand' );
    }
    can_ok( $data->tour->[0], 'city_summary' );
    if ( $data->tour->[0]->can('city_summary') ) {
        ok( $data->tour->[0]->city_summary, 'tour / Test[0]: city_summary' );
    }
    can_ok( $data->tour->[0], 'dept_city' );
    if ( $data->tour->[0]->can('dept_city') ) {
        ok( $data->tour->[0]->dept_city, 'tour / Test[0]: dept_city' );
    }
    can_ok( $data->tour->[0], 'hotel' );
    if ( $data->tour->[0]->can('hotel') ) {
        ok( $data->tour->[0]->hotel, 'tour / Test[0]: hotel' );
        ok( ref $data->tour->[0]->hotel eq 'ARRAY', 'tour / Test[0]: hotel' );
    }
    can_ok( $data->tour->[0], 'hotel_summary' );
    if ( $data->tour->[0]->can('hotel_summary') ) {
        ok( $data->tour->[0]->hotel_summary, 'tour / Test[0]: hotel_summary' );
    }
    can_ok( $data->tour->[0], 'kodawari' );
    if ( $data->tour->[0]->can('kodawari') ) {
        ok( $data->tour->[0]->kodawari, 'tour / Test[0]: kodawari' );
        ok( ref $data->tour->[0]->kodawari eq 'ARRAY', 'tour / Test[0]: kodawari' );
    }
    can_ok( $data->tour->[0], 'price' );
    if ( $data->tour->[0]->can('price') ) {
        ok( $data->tour->[0]->price, 'tour / Test[0]: price' );
    }
    can_ok( $data->tour->[0], 'sche' );
    if ( $data->tour->[0]->can('sche') ) {
        ok( $data->tour->[0]->sche, 'tour / Test[0]: sche' );
        ok( ref $data->tour->[0]->sche eq 'ARRAY', 'tour / Test[0]: sche' );
    }
    can_ok( $data->tour->[0], 'urls' );
    if ( $data->tour->[0]->can('urls') ) {
        ok( $data->tour->[0]->urls, 'tour / Test[0]: urls' );
    }
    can_ok( $data->tour->[0]->airline->[0], 'code' );
    if ( $data->tour->[0]->airline->[0]->can('code') ) {
        ok( $data->tour->[0]->airline->[0]->code, 'tour / Test[0]: code' );
    }
    can_ok( $data->tour->[0]->airline->[0], 'name' );
    if ( $data->tour->[0]->airline->[0]->can('name') ) {
        ok( $data->tour->[0]->airline->[0]->name, 'tour / Test[0]: name' );
    }
    can_ok( $data->tour->[0]->brand, 'code' );
    if ( $data->tour->[0]->brand->can('code') ) {
        ok( $data->tour->[0]->brand->code, 'tour / Test[0]: code' );
    }
    can_ok( $data->tour->[0]->brand, 'name' );
    if ( $data->tour->[0]->brand->can('name') ) {
        ok( $data->tour->[0]->brand->name, 'tour / Test[0]: name' );
    }
    can_ok( $data->tour->[0]->dept_city, 'name' );
    if ( $data->tour->[0]->dept_city->can('name') ) {
        ok( $data->tour->[0]->dept_city->name, 'tour / Test[0]: name' );
    }
    can_ok( $data->tour->[0]->dept_city, 'code' );
    if ( $data->tour->[0]->dept_city->can('code') ) {
        ok( $data->tour->[0]->dept_city->code, 'tour / Test[0]: code' );
    }
    can_ok( $data->tour->[0]->hotel->[0], 'name' );
    if ( $data->tour->[0]->hotel->[0]->can('name') ) {
        ok( $data->tour->[0]->hotel->[0]->name, 'tour / Test[0]: name' );
    }
    can_ok( $data->tour->[0]->hotel->[0], 'city' );
    if ( $data->tour->[0]->hotel->[0]->can('city') ) {
        ok( $data->tour->[0]->hotel->[0]->city, 'tour / Test[0]: city' );
    }
    can_ok( $data->tour->[0]->kodawari->[0], 'code' );
    if ( $data->tour->[0]->kodawari->[0]->can('code') ) {
        ok( $data->tour->[0]->kodawari->[0]->code, 'tour / Test[0]: code' );
    }
    can_ok( $data->tour->[0]->kodawari->[0], 'name' );
    if ( $data->tour->[0]->kodawari->[0]->can('name') ) {
        ok( $data->tour->[0]->kodawari->[0]->name, 'tour / Test[0]: name' );
    }
    can_ok( $data->tour->[0]->price, 'all_month' );
    if ( $data->tour->[0]->price->can('all_month') ) {
        ok( $data->tour->[0]->price->all_month, 'tour / Test[0]: all_month' );
    }
    can_ok( $data->tour->[0]->price, 'min' );
    if ( $data->tour->[0]->price->can('min') ) {
        ok( $data->tour->[0]->price->min, 'tour / Test[0]: min' );
    }
    can_ok( $data->tour->[0]->price, 'max' );
    if ( $data->tour->[0]->price->can('max') ) {
        ok( $data->tour->[0]->price->max, 'tour / Test[0]: max' );
    }
    can_ok( $data->tour->[0]->sche->[0], 'day' );
    if ( $data->tour->[0]->sche->[0]->can('day') ) {
        ok( $data->tour->[0]->sche->[0]->day, 'tour / Test[0]: day' );
    }
    can_ok( $data->tour->[0]->sche->[0], 'city' );
    if ( $data->tour->[0]->sche->[0]->can('city') ) {
        ok( $data->tour->[0]->sche->[0]->city, 'tour / Test[0]: city' );
    }
    can_ok( $data->tour->[0]->urls, 'mobile' );
    if ( $data->tour->[0]->urls->can('mobile') ) {
        ok( $data->tour->[0]->urls->mobile, 'tour / Test[0]: mobile' );
    }
    can_ok( $data->tour->[0]->urls, 'pc' );
    if ( $data->tour->[0]->urls->can('pc') ) {
        ok( $data->tour->[0]->urls->pc, 'tour / Test[0]: pc' );
    }
    can_ok( $data->tour->[0]->urls, 'qr' );
    if ( $data->tour->[0]->urls->can('qr') ) {
        ok( $data->tour->[0]->urls->qr, 'tour / Test[0]: qr' );
    }
    can_ok( $data->tour->[0]->hotel->[0]->city, 'code' );
    if ( $data->tour->[0]->hotel->[0]->city->can('code') ) {
        ok( $data->tour->[0]->hotel->[0]->city->code, 'tour / Test[0]: code' );
    }
    can_ok( $data->tour->[0]->hotel->[0]->city, 'name' );
    if ( $data->tour->[0]->hotel->[0]->city->can('name') ) {
        ok( $data->tour->[0]->hotel->[0]->city->name, 'tour / Test[0]: name' );
    }
    can_ok( $data->tour->[0]->price->all_month, 'min' );
    if ( $data->tour->[0]->price->all_month->can('min') ) {
        ok( $data->tour->[0]->price->all_month->min, 'tour / Test[0]: min' );
    }
    can_ok( $data->tour->[0]->price->all_month, 'max' );
    if ( $data->tour->[0]->price->all_month->can('max') ) {
        ok( $data->tour->[0]->price->all_month->max, 'tour / Test[0]: max' );
    }
    can_ok( $data->tour->[0]->sche->[0]->city, 'code' );
    if ( $data->tour->[0]->sche->[0]->city->can('code') ) {
        ok( $data->tour->[0]->sche->[0]->city->code, 'tour / Test[0]: code' );
    }
    can_ok( $data->tour->[0]->sche->[0]->city, 'name' );
    if ( $data->tour->[0]->sche->[0]->city->can('name') ) {
        ok( $data->tour->[0]->sche->[0]->city->name, 'tour / Test[0]: name' );
    }
    can_ok( $data->tour->[0]->sche->[0]->city, 'area' );
    if ( $data->tour->[0]->sche->[0]->city->can('area') ) {
        ok( $data->tour->[0]->sche->[0]->city->area, 'tour / Test[0]: area' );
    }
    can_ok( $data->tour->[0]->sche->[0]->city, 'country' );
    if ( $data->tour->[0]->sche->[0]->city->can('country') ) {
        ok( $data->tour->[0]->sche->[0]->city->country, 'tour / Test[0]: country' );
    }
}

# tour / Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->tour(%$params); };
    ok( ! $@, 'tour / Test[1]: die' );
    ok( ! $res->is_error, 'tour / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'tour / Test[1]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'tour / Test[1]: api_version' );
    }
    can_ok( $data, 'error' );
    if ( $data->can('error') ) {
        ok( $data->error, 'tour / Test[1]: error' );
    }
    can_ok( $data->error, 'message' );
    if ( $data->error->can('message') ) {
        ok( $data->error->message, 'tour / Test[1]: message' );
    }
}

# tour / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->tour(%$params); };
    ok( $@, 'tour / Test[2]: die' );
}



# area / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->area(%$params); };
    ok( ! $@, 'area / Test[0]: die' );
    ok( ! $res->is_error, 'area / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'area / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'area / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'area / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'area / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'area / Test[0]: results_start' );
    }
    can_ok( $data, 'area' );
    if ( $data->can('area') ) {
        ok( $data->area, 'area / Test[0]: area' );
        ok( ref $data->area eq 'ARRAY', 'area / Test[0]: area' );
    }
    can_ok( $data->area->[0], 'code' );
    if ( $data->area->[0]->can('code') ) {
        ok( $data->area->[0]->code, 'area / Test[0]: code' );
    }
    can_ok( $data->area->[0], 'name' );
    if ( $data->area->[0]->can('name') ) {
        ok( $data->area->[0]->name, 'area / Test[0]: name' );
    }
    can_ok( $data->area->[0], 'tour_count' );
    if ( $data->area->[0]->can('tour_count') ) {
        ok( $data->area->[0]->tour_count, 'area / Test[0]: tour_count' );
    }
}

# area / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->area(%$params); };
    ok( $@, 'area / Test[1]: die' );
}



# country / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->country(%$params); };
    ok( ! $@, 'country / Test[0]: die' );
    ok( ! $res->is_error, 'country / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'country / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'country / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'country / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'country / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'country / Test[0]: results_start' );
    }
    can_ok( $data, 'country' );
    if ( $data->can('country') ) {
        ok( $data->country, 'country / Test[0]: country' );
        ok( ref $data->country eq 'ARRAY', 'country / Test[0]: country' );
    }
    can_ok( $data->country->[0], 'code' );
    if ( $data->country->[0]->can('code') ) {
        ok( $data->country->[0]->code, 'country / Test[0]: code' );
    }
    can_ok( $data->country->[0], 'name' );
    if ( $data->country->[0]->can('name') ) {
        ok( $data->country->[0]->name, 'country / Test[0]: name' );
    }
    can_ok( $data->country->[0], 'name_en' );
    if ( $data->country->[0]->can('name_en') ) {
        ok( $data->country->[0]->name_en, 'country / Test[0]: name_en' );
    }
    can_ok( $data->country->[0], 'tour_count' );
    if ( $data->country->[0]->can('tour_count') ) {
        ok( $data->country->[0]->tour_count, 'country / Test[0]: tour_count' );
    }
    can_ok( $data->country->[0], 'area' );
    if ( $data->country->[0]->can('area') ) {
        ok( $data->country->[0]->area, 'country / Test[0]: area' );
    }
    can_ok( $data->country->[0]->area, 'code' );
    if ( $data->country->[0]->area->can('code') ) {
        ok( $data->country->[0]->area->code, 'country / Test[0]: code' );
    }
    can_ok( $data->country->[0]->area, 'name' );
    if ( $data->country->[0]->area->can('name') ) {
        ok( $data->country->[0]->area->name, 'country / Test[0]: name' );
    }
}

# country / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->country(%$params); };
    ok( $@, 'country / Test[1]: die' );
}



# city / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->city(%$params); };
    ok( ! $@, 'city / Test[0]: die' );
    ok( ! $res->is_error, 'city / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'city / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'city / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'city / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'city / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'city / Test[0]: results_start' );
    }
    can_ok( $data, 'city' );
    if ( $data->can('city') ) {
        ok( $data->city, 'city / Test[0]: city' );
        ok( ref $data->city eq 'ARRAY', 'city / Test[0]: city' );
    }
    can_ok( $data->city->[0], 'code' );
    if ( $data->city->[0]->can('code') ) {
        ok( $data->city->[0]->code, 'city / Test[0]: code' );
    }
    can_ok( $data->city->[0], 'name' );
    if ( $data->city->[0]->can('name') ) {
        ok( $data->city->[0]->name, 'city / Test[0]: name' );
    }
    can_ok( $data->city->[0], 'name_en' );
    if ( $data->city->[0]->can('name_en') ) {
        ok( $data->city->[0]->name_en, 'city / Test[0]: name_en' );
    }
    can_ok( $data->city->[0], 'tour_count' );
    if ( $data->city->[0]->can('tour_count') ) {
        ok( $data->city->[0]->tour_count, 'city / Test[0]: tour_count' );
    }
    can_ok( $data->city->[0], 'lat' );
    if ( $data->city->[0]->can('lat') ) {
        ok( $data->city->[0]->lat, 'city / Test[0]: lat' );
    }
    can_ok( $data->city->[0], 'lng' );
    if ( $data->city->[0]->can('lng') ) {
        ok( $data->city->[0]->lng, 'city / Test[0]: lng' );
    }
    can_ok( $data->city->[0], 'area' );
    if ( $data->city->[0]->can('area') ) {
        ok( $data->city->[0]->area, 'city / Test[0]: area' );
    }
    can_ok( $data->city->[0], 'country' );
    if ( $data->city->[0]->can('country') ) {
        ok( $data->city->[0]->country, 'city / Test[0]: country' );
    }
    can_ok( $data->city->[0]->area, 'code' );
    if ( $data->city->[0]->area->can('code') ) {
        ok( $data->city->[0]->area->code, 'city / Test[0]: code' );
    }
    can_ok( $data->city->[0]->area, 'name' );
    if ( $data->city->[0]->area->can('name') ) {
        ok( $data->city->[0]->area->name, 'city / Test[0]: name' );
    }
    can_ok( $data->city->[0]->country, 'code' );
    if ( $data->city->[0]->country->can('code') ) {
        ok( $data->city->[0]->country->code, 'city / Test[0]: code' );
    }
    can_ok( $data->city->[0]->country, 'name' );
    if ( $data->city->[0]->country->can('name') ) {
        ok( $data->city->[0]->country->name, 'city / Test[0]: name' );
    }
    can_ok( $data->city->[0]->country, 'name_en' );
    if ( $data->city->[0]->country->can('name_en') ) {
        ok( $data->city->[0]->country->name_en, 'city / Test[0]: name_en' );
    }
}

# city / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->city(%$params); };
    ok( $@, 'city / Test[1]: die' );
}



# hotel / Test[0]
{
    my $params = {
        'area' => 'EUR',
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->hotel(%$params); };
    ok( ! $@, 'hotel / Test[0]: die' );
    ok( ! $res->is_error, 'hotel / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'hotel / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'hotel / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'hotel / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'hotel / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'hotel / Test[0]: results_start' );
    }
    can_ok( $data, 'hotel' );
    if ( $data->can('hotel') ) {
        ok( $data->hotel, 'hotel / Test[0]: hotel' );
        ok( ref $data->hotel eq 'ARRAY', 'hotel / Test[0]: hotel' );
    }
    can_ok( $data->hotel->[0], 'code' );
    if ( $data->hotel->[0]->can('code') ) {
        ok( $data->hotel->[0]->code, 'hotel / Test[0]: code' );
    }
    can_ok( $data->hotel->[0], 'name' );
    if ( $data->hotel->[0]->can('name') ) {
        ok( $data->hotel->[0]->name, 'hotel / Test[0]: name' );
    }
    can_ok( $data->hotel->[0], 'name_en' );
    if ( $data->hotel->[0]->can('name_en') ) {
        ok( $data->hotel->[0]->name_en, 'hotel / Test[0]: name_en' );
    }
    can_ok( $data->hotel->[0], 'tour_count' );
    if ( $data->hotel->[0]->can('tour_count') ) {
        ok( $data->hotel->[0]->tour_count, 'hotel / Test[0]: tour_count' );
    }
    can_ok( $data->hotel->[0], 'city' );
    if ( $data->hotel->[0]->can('city') ) {
        ok( $data->hotel->[0]->city, 'hotel / Test[0]: city' );
    }
    can_ok( $data->hotel->[0]->city, 'code' );
    if ( $data->hotel->[0]->city->can('code') ) {
        ok( $data->hotel->[0]->city->code, 'hotel / Test[0]: code' );
    }
    can_ok( $data->hotel->[0]->city, 'name' );
    if ( $data->hotel->[0]->city->can('name') ) {
        ok( $data->hotel->[0]->city->name, 'hotel / Test[0]: name' );
    }
    can_ok( $data->hotel->[0]->city, 'name_en' );
    if ( $data->hotel->[0]->city->can('name_en') ) {
        ok( $data->hotel->[0]->city->name_en, 'hotel / Test[0]: name_en' );
    }
    can_ok( $data->hotel->[0]->city, 'area' );
    if ( $data->hotel->[0]->city->can('area') ) {
        ok( $data->hotel->[0]->city->area, 'hotel / Test[0]: area' );
    }
    can_ok( $data->hotel->[0]->city, 'country' );
    if ( $data->hotel->[0]->city->can('country') ) {
        ok( $data->hotel->[0]->city->country, 'hotel / Test[0]: country' );
    }
    can_ok( $data->hotel->[0]->city->area, 'code' );
    if ( $data->hotel->[0]->city->area->can('code') ) {
        ok( $data->hotel->[0]->city->area->code, 'hotel / Test[0]: code' );
    }
    can_ok( $data->hotel->[0]->city->area, 'name' );
    if ( $data->hotel->[0]->city->area->can('name') ) {
        ok( $data->hotel->[0]->city->area->name, 'hotel / Test[0]: name' );
    }
    can_ok( $data->hotel->[0]->city->country, 'code' );
    if ( $data->hotel->[0]->city->country->can('code') ) {
        ok( $data->hotel->[0]->city->country->code, 'hotel / Test[0]: code' );
    }
    can_ok( $data->hotel->[0]->city->country, 'name' );
    if ( $data->hotel->[0]->city->country->can('name') ) {
        ok( $data->hotel->[0]->city->country->name, 'hotel / Test[0]: name' );
    }
    can_ok( $data->hotel->[0]->city->country, 'name_en' );
    if ( $data->hotel->[0]->city->country->can('name_en') ) {
        ok( $data->hotel->[0]->city->country->name_en, 'hotel / Test[0]: name_en' );
    }
}

# hotel / Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->hotel(%$params); };
    ok( ! $@, 'hotel / Test[1]: die' );
    ok( ! $res->is_error, 'hotel / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'hotel / Test[1]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'hotel / Test[1]: api_version' );
    }
    can_ok( $data, 'error' );
    if ( $data->can('error') ) {
        ok( $data->error, 'hotel / Test[1]: error' );
    }
    can_ok( $data->error, 'message' );
    if ( $data->error->can('message') ) {
        ok( $data->error->message, 'hotel / Test[1]: message' );
    }
}

# hotel / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->hotel(%$params); };
    ok( $@, 'hotel / Test[2]: die' );
}



# airline / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->airline(%$params); };
    ok( ! $@, 'airline / Test[0]: die' );
    ok( ! $res->is_error, 'airline / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'airline / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'airline / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'airline / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'airline / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'airline / Test[0]: results_start' );
    }
    can_ok( $data, 'airline' );
    if ( $data->can('airline') ) {
        ok( $data->airline, 'airline / Test[0]: airline' );
        ok( ref $data->airline eq 'ARRAY', 'airline / Test[0]: airline' );
    }
    can_ok( $data->airline->[0], 'code' );
    if ( $data->airline->[0]->can('code') ) {
        ok( $data->airline->[0]->code, 'airline / Test[0]: code' );
    }
    can_ok( $data->airline->[0], 'name' );
    if ( $data->airline->[0]->can('name') ) {
        ok( $data->airline->[0]->name, 'airline / Test[0]: name' );
    }
}

# airline / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->airline(%$params); };
    ok( $@, 'airline / Test[1]: die' );
}



# kodawari / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->kodawari(%$params); };
    ok( ! $@, 'kodawari / Test[0]: die' );
    ok( ! $res->is_error, 'kodawari / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'kodawari / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'kodawari / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'kodawari / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'kodawari / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'kodawari / Test[0]: results_start' );
    }
    can_ok( $data, 'kodawari' );
    if ( $data->can('kodawari') ) {
        ok( $data->kodawari, 'kodawari / Test[0]: kodawari' );
        ok( ref $data->kodawari eq 'ARRAY', 'kodawari / Test[0]: kodawari' );
    }
    can_ok( $data->kodawari->[0], 'code' );
    if ( $data->kodawari->[0]->can('code') ) {
        ok( $data->kodawari->[0]->code, 'kodawari / Test[0]: code' );
    }
    can_ok( $data->kodawari->[0], 'name' );
    if ( $data->kodawari->[0]->can('name') ) {
        ok( $data->kodawari->[0]->name, 'kodawari / Test[0]: name' );
    }
}

# kodawari / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->kodawari(%$params); };
    ok( $@, 'kodawari / Test[1]: die' );
}



# spot / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->spot(%$params); };
    ok( ! $@, 'spot / Test[0]: die' );
    ok( ! $res->is_error, 'spot / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'spot / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'spot / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'spot / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'spot / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'spot / Test[0]: results_start' );
    }
    can_ok( $data, 'spot' );
    if ( $data->can('spot') ) {
        ok( $data->spot, 'spot / Test[0]: spot' );
        ok( ref $data->spot eq 'ARRAY', 'spot / Test[0]: spot' );
    }
    can_ok( $data->spot->[0], 'code' );
    if ( $data->spot->[0]->can('code') ) {
        ok( $data->spot->[0]->code, 'spot / Test[0]: code' );
    }
    can_ok( $data->spot->[0], 'name' );
    if ( $data->spot->[0]->can('name') ) {
        ok( $data->spot->[0]->name, 'spot / Test[0]: name' );
    }
    can_ok( $data->spot->[0], 'title' );
    if ( $data->spot->[0]->can('title') ) {
        ok( $data->spot->[0]->title, 'spot / Test[0]: title' );
    }
    can_ok( $data->spot->[0], 'description' );
    if ( $data->spot->[0]->can('description') ) {
        ok( $data->spot->[0]->description, 'spot / Test[0]: description' );
    }
    can_ok( $data->spot->[0], 'lat' );
    if ( $data->spot->[0]->can('lat') ) {
        ok( $data->spot->[0]->lat, 'spot / Test[0]: lat' );
    }
    can_ok( $data->spot->[0], 'lng' );
    if ( $data->spot->[0]->can('lng') ) {
        ok( $data->spot->[0]->lng, 'spot / Test[0]: lng' );
    }
    can_ok( $data->spot->[0], 'map_scale' );
    if ( $data->spot->[0]->can('map_scale') ) {
        ok( $data->spot->[0]->map_scale, 'spot / Test[0]: map_scale' );
    }
    can_ok( $data->spot->[0], 'area' );
    if ( $data->spot->[0]->can('area') ) {
        ok( $data->spot->[0]->area, 'spot / Test[0]: area' );
    }
    can_ok( $data->spot->[0], 'country' );
    if ( $data->spot->[0]->can('country') ) {
        ok( $data->spot->[0]->country, 'spot / Test[0]: country' );
    }
    can_ok( $data->spot->[0], 'city' );
    if ( $data->spot->[0]->can('city') ) {
        ok( $data->spot->[0]->city, 'spot / Test[0]: city' );
    }
    can_ok( $data->spot->[0], 'url' );
    if ( $data->spot->[0]->can('url') ) {
        ok( $data->spot->[0]->url, 'spot / Test[0]: url' );
    }
    can_ok( $data->spot->[0]->area, 'code' );
    if ( $data->spot->[0]->area->can('code') ) {
        ok( $data->spot->[0]->area->code, 'spot / Test[0]: code' );
    }
    can_ok( $data->spot->[0]->area, 'name' );
    if ( $data->spot->[0]->area->can('name') ) {
        ok( $data->spot->[0]->area->name, 'spot / Test[0]: name' );
    }
    can_ok( $data->spot->[0]->country, 'code' );
    if ( $data->spot->[0]->country->can('code') ) {
        ok( $data->spot->[0]->country->code, 'spot / Test[0]: code' );
    }
    can_ok( $data->spot->[0]->country, 'name' );
    if ( $data->spot->[0]->country->can('name') ) {
        ok( $data->spot->[0]->country->name, 'spot / Test[0]: name' );
    }
    can_ok( $data->spot->[0]->city, 'code' );
    if ( $data->spot->[0]->city->can('code') ) {
        ok( $data->spot->[0]->city->code, 'spot / Test[0]: code' );
    }
    can_ok( $data->spot->[0]->city, 'name' );
    if ( $data->spot->[0]->city->can('name') ) {
        ok( $data->spot->[0]->city->name, 'spot / Test[0]: name' );
    }
}

# spot / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->spot(%$params); };
    ok( $@, 'spot / Test[1]: die' );
}



# tour_tally / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'keyword' => '登山',
    };
    my $res = eval { $obj->tour_tally(%$params); };
    ok( ! $@, 'tour_tally / Test[0]: die' );
    ok( ! $res->is_error, 'tour_tally / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'tour_tally / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'tour_tally / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'tour_tally / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'tour_tally / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'tour_tally / Test[0]: results_start' );
    }
    can_ok( $data, 'tour_tally' );
    if ( $data->can('tour_tally') ) {
        ok( $data->tour_tally, 'tour_tally / Test[0]: tour_tally' );
        ok( ref $data->tour_tally eq 'ARRAY', 'tour_tally / Test[0]: tour_tally' );
    }
    can_ok( $data->tour_tally->[0], 'type' );
    if ( $data->tour_tally->[0]->can('type') ) {
        ok( $data->tour_tally->[0]->type, 'tour_tally / Test[0]: type' );
    }
    can_ok( $data->tour_tally->[0], 'code' );
    if ( $data->tour_tally->[0]->can('code') ) {
        ok( $data->tour_tally->[0]->code, 'tour_tally / Test[0]: code' );
    }
    can_ok( $data->tour_tally->[0], 'name' );
    if ( $data->tour_tally->[0]->can('name') ) {
        ok( $data->tour_tally->[0]->name, 'tour_tally / Test[0]: name' );
    }
    can_ok( $data->tour_tally->[0], 'tour_count' );
    if ( $data->tour_tally->[0]->can('tour_count') ) {
        ok( $data->tour_tally->[0]->tour_count, 'tour_tally / Test[0]: tour_count' );
    }
    can_ok( $data->tour_tally->[0], 'lat' );
    if ( $data->tour_tally->[0]->can('lat') ) {
        ok( $data->tour_tally->[0]->lat, 'tour_tally / Test[0]: lat' );
    }
    can_ok( $data->tour_tally->[0], 'lng' );
    if ( $data->tour_tally->[0]->can('lng') ) {
        ok( $data->tour_tally->[0]->lng, 'tour_tally / Test[0]: lng' );
    }
    can_ok( $data->tour_tally->[0], 'area' );
    if ( $data->tour_tally->[0]->can('area') ) {
        ok( $data->tour_tally->[0]->area, 'tour_tally / Test[0]: area' );
    }
    can_ok( $data->tour_tally->[0], 'country' );
    if ( $data->tour_tally->[0]->can('country') ) {
        ok( $data->tour_tally->[0]->country, 'tour_tally / Test[0]: country' );
    }
    can_ok( $data->tour_tally->[0]->area, 'code' );
    if ( $data->tour_tally->[0]->area->can('code') ) {
        ok( $data->tour_tally->[0]->area->code, 'tour_tally / Test[0]: code' );
    }
    can_ok( $data->tour_tally->[0]->area, 'name' );
    if ( $data->tour_tally->[0]->area->can('name') ) {
        ok( $data->tour_tally->[0]->area->name, 'tour_tally / Test[0]: name' );
    }
    can_ok( $data->tour_tally->[0]->country, 'code' );
    if ( $data->tour_tally->[0]->country->can('code') ) {
        ok( $data->tour_tally->[0]->country->code, 'tour_tally / Test[0]: code' );
    }
    can_ok( $data->tour_tally->[0]->country, 'name' );
    if ( $data->tour_tally->[0]->country->can('name') ) {
        ok( $data->tour_tally->[0]->country->name, 'tour_tally / Test[0]: name' );
    }
}

# tour_tally / Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->tour_tally(%$params); };
    ok( $@, 'tour_tally / Test[1]: die' );
}

# tour_tally / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->tour_tally(%$params); };
    ok( $@, 'tour_tally / Test[2]: die' );
}



1;
