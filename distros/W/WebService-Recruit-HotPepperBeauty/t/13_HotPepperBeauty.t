#
# Test case for WebService::Recruit::HotPepperBeauty
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
plan tests => 284;

use_ok('WebService::Recruit::HotPepperBeauty');

my $obj = WebService::Recruit::HotPepperBeauty->new();

ok(ref $obj, 'new WebService::Recruit::HotPepperBeauty()');


# salon / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'name' => 'サロン',
        'order' => '3',
    };
    my $res = eval { $obj->salon(%$params); };
    ok( ! $@, 'salon / Test[0]: die' );
    ok( ! $res->is_error, 'salon / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'salon / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'salon / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'salon / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'salon / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'salon / Test[0]: results_start' );
    }
    can_ok( $data, 'salon' );
    if ( $data->can('salon') ) {
        ok( $data->salon, 'salon / Test[0]: salon' );
        ok( ref $data->salon eq 'ARRAY', 'salon / Test[0]: salon' );
    }
    can_ok( $data->salon->[0], 'id' );
    if ( $data->salon->[0]->can('id') ) {
        ok( $data->salon->[0]->id, 'salon / Test[0]: id' );
    }
    can_ok( $data->salon->[0], 'last_update' );
    if ( $data->salon->[0]->can('last_update') ) {
        ok( $data->salon->[0]->last_update, 'salon / Test[0]: last_update' );
    }
    can_ok( $data->salon->[0], 'name' );
    if ( $data->salon->[0]->can('name') ) {
        ok( $data->salon->[0]->name, 'salon / Test[0]: name' );
    }
    can_ok( $data->salon->[0], 'name_kana' );
    if ( $data->salon->[0]->can('name_kana') ) {
        ok( $data->salon->[0]->name_kana, 'salon / Test[0]: name_kana' );
    }
    can_ok( $data->salon->[0], 'urls' );
    if ( $data->salon->[0]->can('urls') ) {
        ok( $data->salon->[0]->urls, 'salon / Test[0]: urls' );
    }
    can_ok( $data->salon->[0], 'coupon_urls' );
    if ( $data->salon->[0]->can('coupon_urls') ) {
        ok( $data->salon->[0]->coupon_urls, 'salon / Test[0]: coupon_urls' );
    }
    can_ok( $data->salon->[0], 'address' );
    if ( $data->salon->[0]->can('address') ) {
        ok( $data->salon->[0]->address, 'salon / Test[0]: address' );
    }
    can_ok( $data->salon->[0], 'service_area' );
    if ( $data->salon->[0]->can('service_area') ) {
        ok( $data->salon->[0]->service_area, 'salon / Test[0]: service_area' );
    }
    can_ok( $data->salon->[0], 'middle_area' );
    if ( $data->salon->[0]->can('middle_area') ) {
        ok( $data->salon->[0]->middle_area, 'salon / Test[0]: middle_area' );
    }
    can_ok( $data->salon->[0], 'small_area' );
    if ( $data->salon->[0]->can('small_area') ) {
        ok( $data->salon->[0]->small_area, 'salon / Test[0]: small_area' );
    }
    can_ok( $data->salon->[0], 'open' );
    if ( $data->salon->[0]->can('open') ) {
        ok( $data->salon->[0]->open, 'salon / Test[0]: open' );
    }
    can_ok( $data->salon->[0], 'close' );
    if ( $data->salon->[0]->can('close') ) {
        ok( $data->salon->[0]->close, 'salon / Test[0]: close' );
    }
    can_ok( $data->salon->[0], 'credit_card' );
    if ( $data->salon->[0]->can('credit_card') ) {
        ok( $data->salon->[0]->credit_card, 'salon / Test[0]: credit_card' );
    }
    can_ok( $data->salon->[0], 'price' );
    if ( $data->salon->[0]->can('price') ) {
        ok( $data->salon->[0]->price, 'salon / Test[0]: price' );
    }
    can_ok( $data->salon->[0], 'stylist_num' );
    if ( $data->salon->[0]->can('stylist_num') ) {
        ok( $data->salon->[0]->stylist_num, 'salon / Test[0]: stylist_num' );
    }
    can_ok( $data->salon->[0], 'capacity' );
    if ( $data->salon->[0]->can('capacity') ) {
        ok( $data->salon->[0]->capacity, 'salon / Test[0]: capacity' );
    }
    can_ok( $data->salon->[0], 'parking' );
    if ( $data->salon->[0]->can('parking') ) {
        ok( $data->salon->[0]->parking, 'salon / Test[0]: parking' );
    }
    can_ok( $data->salon->[0], 'kodawari' );
    if ( $data->salon->[0]->can('kodawari') ) {
        ok( $data->salon->[0]->kodawari, 'salon / Test[0]: kodawari' );
    }
    can_ok( $data->salon->[0], 'lat' );
    if ( $data->salon->[0]->can('lat') ) {
        ok( $data->salon->[0]->lat, 'salon / Test[0]: lat' );
    }
    can_ok( $data->salon->[0], 'lng' );
    if ( $data->salon->[0]->can('lng') ) {
        ok( $data->salon->[0]->lng, 'salon / Test[0]: lng' );
    }
    can_ok( $data->salon->[0], 'catch_copy' );
    if ( $data->salon->[0]->can('catch_copy') ) {
        ok( $data->salon->[0]->catch_copy, 'salon / Test[0]: catch_copy' );
    }
    can_ok( $data->salon->[0], 'description' );
    if ( $data->salon->[0]->can('description') ) {
        ok( $data->salon->[0]->description, 'salon / Test[0]: description' );
    }
    can_ok( $data->salon->[0], 'main' );
    if ( $data->salon->[0]->can('main') ) {
        ok( $data->salon->[0]->main, 'salon / Test[0]: main' );
    }
    can_ok( $data->salon->[0], 'feature' );
    if ( $data->salon->[0]->can('feature') ) {
        ok( $data->salon->[0]->feature, 'salon / Test[0]: feature' );
        ok( ref $data->salon->[0]->feature eq 'ARRAY', 'salon / Test[0]: feature' );
    }
    can_ok( $data->salon->[0]->urls, 'pc' );
    if ( $data->salon->[0]->urls->can('pc') ) {
        ok( $data->salon->[0]->urls->pc, 'salon / Test[0]: pc' );
    }
    can_ok( $data->salon->[0]->coupon_urls, 'pc' );
    if ( $data->salon->[0]->coupon_urls->can('pc') ) {
        ok( $data->salon->[0]->coupon_urls->pc, 'salon / Test[0]: pc' );
    }
    can_ok( $data->salon->[0]->service_area, 'code' );
    if ( $data->salon->[0]->service_area->can('code') ) {
        ok( $data->salon->[0]->service_area->code, 'salon / Test[0]: code' );
    }
    can_ok( $data->salon->[0]->service_area, 'name' );
    if ( $data->salon->[0]->service_area->can('name') ) {
        ok( $data->salon->[0]->service_area->name, 'salon / Test[0]: name' );
    }
    can_ok( $data->salon->[0]->middle_area, 'code' );
    if ( $data->salon->[0]->middle_area->can('code') ) {
        ok( $data->salon->[0]->middle_area->code, 'salon / Test[0]: code' );
    }
    can_ok( $data->salon->[0]->middle_area, 'name' );
    if ( $data->salon->[0]->middle_area->can('name') ) {
        ok( $data->salon->[0]->middle_area->name, 'salon / Test[0]: name' );
    }
    can_ok( $data->salon->[0]->small_area, 'code' );
    if ( $data->salon->[0]->small_area->can('code') ) {
        ok( $data->salon->[0]->small_area->code, 'salon / Test[0]: code' );
    }
    can_ok( $data->salon->[0]->small_area, 'name' );
    if ( $data->salon->[0]->small_area->can('name') ) {
        ok( $data->salon->[0]->small_area->name, 'salon / Test[0]: name' );
    }
    can_ok( $data->salon->[0]->main, 'photo' );
    if ( $data->salon->[0]->main->can('photo') ) {
        ok( $data->salon->[0]->main->photo, 'salon / Test[0]: photo' );
    }
    can_ok( $data->salon->[0]->main, 'caption' );
    if ( $data->salon->[0]->main->can('caption') ) {
        ok( $data->salon->[0]->main->caption, 'salon / Test[0]: caption' );
    }
    can_ok( $data->salon->[0]->feature->[0], 'name' );
    if ( $data->salon->[0]->feature->[0]->can('name') ) {
        ok( $data->salon->[0]->feature->[0]->name, 'salon / Test[0]: name' );
    }
    can_ok( $data->salon->[0]->feature->[0], 'caption' );
    if ( $data->salon->[0]->feature->[0]->can('caption') ) {
        ok( $data->salon->[0]->feature->[0]->caption, 'salon / Test[0]: caption' );
    }
    can_ok( $data->salon->[0]->feature->[0], 'description' );
    if ( $data->salon->[0]->feature->[0]->can('description') ) {
        ok( $data->salon->[0]->feature->[0]->description, 'salon / Test[0]: description' );
    }
    can_ok( $data->salon->[0]->main->photo, 's' );
    if ( $data->salon->[0]->main->photo->can('s') ) {
        ok( $data->salon->[0]->main->photo->s, 'salon / Test[0]: s' );
    }
    can_ok( $data->salon->[0]->main->photo, 'm' );
    if ( $data->salon->[0]->main->photo->can('m') ) {
        ok( $data->salon->[0]->main->photo->m, 'salon / Test[0]: m' );
    }
    can_ok( $data->salon->[0]->main->photo, 'l' );
    if ( $data->salon->[0]->main->photo->can('l') ) {
        ok( $data->salon->[0]->main->photo->l, 'salon / Test[0]: l' );
    }
}

# salon / Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->salon(%$params); };
    ok( ! $@, 'salon / Test[1]: die' );
    ok( ! $res->is_error, 'salon / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'salon / Test[1]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'salon / Test[1]: api_version' );
    }
    can_ok( $data, 'error' );
    if ( $data->can('error') ) {
        ok( $data->error, 'salon / Test[1]: error' );
    }
    can_ok( $data->error, 'message' );
    if ( $data->error->can('message') ) {
        ok( $data->error->message, 'salon / Test[1]: message' );
    }
}

# salon / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->salon(%$params); };
    ok( $@, 'salon / Test[2]: die' );
}



# service_area / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->service_area(%$params); };
    ok( ! $@, 'service_area / Test[0]: die' );
    ok( ! $res->is_error, 'service_area / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'service_area / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'service_area / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'service_area / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'service_area / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'service_area / Test[0]: results_start' );
    }
    can_ok( $data, 'service_area' );
    if ( $data->can('service_area') ) {
        ok( $data->service_area, 'service_area / Test[0]: service_area' );
        ok( ref $data->service_area eq 'ARRAY', 'service_area / Test[0]: service_area' );
    }
    can_ok( $data->service_area->[0], 'code' );
    if ( $data->service_area->[0]->can('code') ) {
        ok( $data->service_area->[0]->code, 'service_area / Test[0]: code' );
    }
    can_ok( $data->service_area->[0], 'name' );
    if ( $data->service_area->[0]->can('name') ) {
        ok( $data->service_area->[0]->name, 'service_area / Test[0]: name' );
    }
}

# service_area / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->service_area(%$params); };
    ok( $@, 'service_area / Test[1]: die' );
}



# middle_area / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->middle_area(%$params); };
    ok( ! $@, 'middle_area / Test[0]: die' );
    ok( ! $res->is_error, 'middle_area / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'middle_area / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'middle_area / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'middle_area / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'middle_area / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'middle_area / Test[0]: results_start' );
    }
    can_ok( $data, 'middle_area' );
    if ( $data->can('middle_area') ) {
        ok( $data->middle_area, 'middle_area / Test[0]: middle_area' );
        ok( ref $data->middle_area eq 'ARRAY', 'middle_area / Test[0]: middle_area' );
    }
    can_ok( $data->middle_area->[0], 'code' );
    if ( $data->middle_area->[0]->can('code') ) {
        ok( $data->middle_area->[0]->code, 'middle_area / Test[0]: code' );
    }
    can_ok( $data->middle_area->[0], 'name' );
    if ( $data->middle_area->[0]->can('name') ) {
        ok( $data->middle_area->[0]->name, 'middle_area / Test[0]: name' );
    }
    can_ok( $data->middle_area->[0], 'service_area' );
    if ( $data->middle_area->[0]->can('service_area') ) {
        ok( $data->middle_area->[0]->service_area, 'middle_area / Test[0]: service_area' );
    }
    can_ok( $data->middle_area->[0]->service_area, 'code' );
    if ( $data->middle_area->[0]->service_area->can('code') ) {
        ok( $data->middle_area->[0]->service_area->code, 'middle_area / Test[0]: code' );
    }
    can_ok( $data->middle_area->[0]->service_area, 'name' );
    if ( $data->middle_area->[0]->service_area->can('name') ) {
        ok( $data->middle_area->[0]->service_area->name, 'middle_area / Test[0]: name' );
    }
}

# middle_area / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->middle_area(%$params); };
    ok( $@, 'middle_area / Test[1]: die' );
}



# small_area / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->small_area(%$params); };
    ok( ! $@, 'small_area / Test[0]: die' );
    ok( ! $res->is_error, 'small_area / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'small_area / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'small_area / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'small_area / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'small_area / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'small_area / Test[0]: results_start' );
    }
    can_ok( $data, 'small_area' );
    if ( $data->can('small_area') ) {
        ok( $data->small_area, 'small_area / Test[0]: small_area' );
        ok( ref $data->small_area eq 'ARRAY', 'small_area / Test[0]: small_area' );
    }
    can_ok( $data->small_area->[0], 'code' );
    if ( $data->small_area->[0]->can('code') ) {
        ok( $data->small_area->[0]->code, 'small_area / Test[0]: code' );
    }
    can_ok( $data->small_area->[0], 'name' );
    if ( $data->small_area->[0]->can('name') ) {
        ok( $data->small_area->[0]->name, 'small_area / Test[0]: name' );
    }
    can_ok( $data->small_area->[0], 'middle_area' );
    if ( $data->small_area->[0]->can('middle_area') ) {
        ok( $data->small_area->[0]->middle_area, 'small_area / Test[0]: middle_area' );
    }
    can_ok( $data->small_area->[0], 'service_area' );
    if ( $data->small_area->[0]->can('service_area') ) {
        ok( $data->small_area->[0]->service_area, 'small_area / Test[0]: service_area' );
    }
    can_ok( $data->small_area->[0]->middle_area, 'code' );
    if ( $data->small_area->[0]->middle_area->can('code') ) {
        ok( $data->small_area->[0]->middle_area->code, 'small_area / Test[0]: code' );
    }
    can_ok( $data->small_area->[0]->middle_area, 'name' );
    if ( $data->small_area->[0]->middle_area->can('name') ) {
        ok( $data->small_area->[0]->middle_area->name, 'small_area / Test[0]: name' );
    }
    can_ok( $data->small_area->[0]->service_area, 'code' );
    if ( $data->small_area->[0]->service_area->can('code') ) {
        ok( $data->small_area->[0]->service_area->code, 'small_area / Test[0]: code' );
    }
    can_ok( $data->small_area->[0]->service_area, 'name' );
    if ( $data->small_area->[0]->service_area->can('name') ) {
        ok( $data->small_area->[0]->service_area->name, 'small_area / Test[0]: name' );
    }
}

# small_area / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->small_area(%$params); };
    ok( $@, 'small_area / Test[1]: die' );
}



# hair_image / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->hair_image(%$params); };
    ok( ! $@, 'hair_image / Test[0]: die' );
    ok( ! $res->is_error, 'hair_image / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'hair_image / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'hair_image / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'hair_image / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'hair_image / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'hair_image / Test[0]: results_start' );
    }
    can_ok( $data, 'hair_image' );
    if ( $data->can('hair_image') ) {
        ok( $data->hair_image, 'hair_image / Test[0]: hair_image' );
        ok( ref $data->hair_image eq 'ARRAY', 'hair_image / Test[0]: hair_image' );
    }
    can_ok( $data->hair_image->[0], 'code' );
    if ( $data->hair_image->[0]->can('code') ) {
        ok( $data->hair_image->[0]->code, 'hair_image / Test[0]: code' );
    }
    can_ok( $data->hair_image->[0], 'name' );
    if ( $data->hair_image->[0]->can('name') ) {
        ok( $data->hair_image->[0]->name, 'hair_image / Test[0]: name' );
    }
}

# hair_image / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->hair_image(%$params); };
    ok( $@, 'hair_image / Test[1]: die' );
}



# hair_length / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->hair_length(%$params); };
    ok( ! $@, 'hair_length / Test[0]: die' );
    ok( ! $res->is_error, 'hair_length / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'hair_length / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'hair_length / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'hair_length / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'hair_length / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'hair_length / Test[0]: results_start' );
    }
    can_ok( $data, 'hair_length' );
    if ( $data->can('hair_length') ) {
        ok( $data->hair_length, 'hair_length / Test[0]: hair_length' );
        ok( ref $data->hair_length eq 'ARRAY', 'hair_length / Test[0]: hair_length' );
    }
    can_ok( $data->hair_length->[0], 'code' );
    if ( $data->hair_length->[0]->can('code') ) {
        ok( $data->hair_length->[0]->code, 'hair_length / Test[0]: code' );
    }
    can_ok( $data->hair_length->[0], 'name' );
    if ( $data->hair_length->[0]->can('name') ) {
        ok( $data->hair_length->[0]->name, 'hair_length / Test[0]: name' );
    }
}

# hair_length / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->hair_length(%$params); };
    ok( $@, 'hair_length / Test[1]: die' );
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



# kodawari_setsubi / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->kodawari_setsubi(%$params); };
    ok( ! $@, 'kodawari_setsubi / Test[0]: die' );
    ok( ! $res->is_error, 'kodawari_setsubi / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'kodawari_setsubi / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'kodawari_setsubi / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'kodawari_setsubi / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'kodawari_setsubi / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'kodawari_setsubi / Test[0]: results_start' );
    }
    can_ok( $data, 'kodawari_setsubi' );
    if ( $data->can('kodawari_setsubi') ) {
        ok( $data->kodawari_setsubi, 'kodawari_setsubi / Test[0]: kodawari_setsubi' );
        ok( ref $data->kodawari_setsubi eq 'ARRAY', 'kodawari_setsubi / Test[0]: kodawari_setsubi' );
    }
    can_ok( $data->kodawari_setsubi->[0], 'code' );
    if ( $data->kodawari_setsubi->[0]->can('code') ) {
        ok( $data->kodawari_setsubi->[0]->code, 'kodawari_setsubi / Test[0]: code' );
    }
    can_ok( $data->kodawari_setsubi->[0], 'name' );
    if ( $data->kodawari_setsubi->[0]->can('name') ) {
        ok( $data->kodawari_setsubi->[0]->name, 'kodawari_setsubi / Test[0]: name' );
    }
}

# kodawari_setsubi / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->kodawari_setsubi(%$params); };
    ok( $@, 'kodawari_setsubi / Test[1]: die' );
}



# kodawari_menu / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->kodawari_menu(%$params); };
    ok( ! $@, 'kodawari_menu / Test[0]: die' );
    ok( ! $res->is_error, 'kodawari_menu / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'kodawari_menu / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'kodawari_menu / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'kodawari_menu / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'kodawari_menu / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'kodawari_menu / Test[0]: results_start' );
    }
    can_ok( $data, 'kodawari_menu' );
    if ( $data->can('kodawari_menu') ) {
        ok( $data->kodawari_menu, 'kodawari_menu / Test[0]: kodawari_menu' );
        ok( ref $data->kodawari_menu eq 'ARRAY', 'kodawari_menu / Test[0]: kodawari_menu' );
    }
    can_ok( $data->kodawari_menu->[0], 'code' );
    if ( $data->kodawari_menu->[0]->can('code') ) {
        ok( $data->kodawari_menu->[0]->code, 'kodawari_menu / Test[0]: code' );
    }
    can_ok( $data->kodawari_menu->[0], 'name' );
    if ( $data->kodawari_menu->[0]->can('name') ) {
        ok( $data->kodawari_menu->[0]->name, 'kodawari_menu / Test[0]: name' );
    }
    can_ok( $data->kodawari_menu->[0], 'category' );
    if ( $data->kodawari_menu->[0]->can('category') ) {
        ok( $data->kodawari_menu->[0]->category, 'kodawari_menu / Test[0]: category' );
        ok( ref $data->kodawari_menu->[0]->category eq 'ARRAY', 'kodawari_menu / Test[0]: category' );
    }
    can_ok( $data->kodawari_menu->[0]->category->[0], 'code' );
    if ( $data->kodawari_menu->[0]->category->[0]->can('code') ) {
        ok( $data->kodawari_menu->[0]->category->[0]->code, 'kodawari_menu / Test[0]: code' );
    }
    can_ok( $data->kodawari_menu->[0]->category->[0], 'name' );
    if ( $data->kodawari_menu->[0]->category->[0]->can('name') ) {
        ok( $data->kodawari_menu->[0]->category->[0]->name, 'kodawari_menu / Test[0]: name' );
    }
}

# kodawari_menu / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->kodawari_menu(%$params); };
    ok( $@, 'kodawari_menu / Test[1]: die' );
}



1;
