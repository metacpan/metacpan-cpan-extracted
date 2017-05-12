#
# Test case for WebService::Recruit::HotPepperBeauty::Salon
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
plan tests => 107;

use_ok('WebService::Recruit::HotPepperBeauty::Salon');

my $service = new WebService::Recruit::HotPepperBeauty::Salon();

ok( ref $service, 'new WebService::Recruit::HotPepperBeauty::Salon()' );


# Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'name' => 'サロン',
        'order' => '3',
    };
    my $res = new WebService::Recruit::HotPepperBeauty::Salon();
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
    can_ok( $data, 'salon' );
    ok( eval { $data->salon }, 'Test[0]: salon' );
    ok( eval { ref $data->salon } eq 'ARRAY', 'Test[0]: salon' );
    can_ok( $data->salon->[0], 'id' );
    ok( eval { $data->salon->[0]->id }, 'Test[0]: id' );
    can_ok( $data->salon->[0], 'last_update' );
    ok( eval { $data->salon->[0]->last_update }, 'Test[0]: last_update' );
    can_ok( $data->salon->[0], 'name' );
    ok( eval { $data->salon->[0]->name }, 'Test[0]: name' );
    can_ok( $data->salon->[0], 'name_kana' );
    ok( eval { $data->salon->[0]->name_kana }, 'Test[0]: name_kana' );
    can_ok( $data->salon->[0], 'urls' );
    ok( eval { $data->salon->[0]->urls }, 'Test[0]: urls' );
    can_ok( $data->salon->[0], 'coupon_urls' );
    ok( eval { $data->salon->[0]->coupon_urls }, 'Test[0]: coupon_urls' );
    can_ok( $data->salon->[0], 'address' );
    ok( eval { $data->salon->[0]->address }, 'Test[0]: address' );
    can_ok( $data->salon->[0], 'service_area' );
    ok( eval { $data->salon->[0]->service_area }, 'Test[0]: service_area' );
    can_ok( $data->salon->[0], 'middle_area' );
    ok( eval { $data->salon->[0]->middle_area }, 'Test[0]: middle_area' );
    can_ok( $data->salon->[0], 'small_area' );
    ok( eval { $data->salon->[0]->small_area }, 'Test[0]: small_area' );
    can_ok( $data->salon->[0], 'open' );
    ok( eval { $data->salon->[0]->open }, 'Test[0]: open' );
    can_ok( $data->salon->[0], 'close' );
    ok( eval { $data->salon->[0]->close }, 'Test[0]: close' );
    can_ok( $data->salon->[0], 'credit_card' );
    ok( eval { $data->salon->[0]->credit_card }, 'Test[0]: credit_card' );
    can_ok( $data->salon->[0], 'price' );
    ok( eval { $data->salon->[0]->price }, 'Test[0]: price' );
    can_ok( $data->salon->[0], 'stylist_num' );
    ok( eval { $data->salon->[0]->stylist_num }, 'Test[0]: stylist_num' );
    can_ok( $data->salon->[0], 'capacity' );
    ok( eval { $data->salon->[0]->capacity }, 'Test[0]: capacity' );
    can_ok( $data->salon->[0], 'parking' );
    ok( eval { $data->salon->[0]->parking }, 'Test[0]: parking' );
    can_ok( $data->salon->[0], 'kodawari' );
    ok( eval { $data->salon->[0]->kodawari }, 'Test[0]: kodawari' );
    can_ok( $data->salon->[0], 'lat' );
    ok( eval { $data->salon->[0]->lat }, 'Test[0]: lat' );
    can_ok( $data->salon->[0], 'lng' );
    ok( eval { $data->salon->[0]->lng }, 'Test[0]: lng' );
    can_ok( $data->salon->[0], 'catch_copy' );
    ok( eval { $data->salon->[0]->catch_copy }, 'Test[0]: catch_copy' );
    can_ok( $data->salon->[0], 'description' );
    ok( eval { $data->salon->[0]->description }, 'Test[0]: description' );
    can_ok( $data->salon->[0], 'main' );
    ok( eval { $data->salon->[0]->main }, 'Test[0]: main' );
    can_ok( $data->salon->[0], 'feature' );
    ok( eval { $data->salon->[0]->feature }, 'Test[0]: feature' );
    ok( eval { ref $data->salon->[0]->feature } eq 'ARRAY', 'Test[0]: feature' );
    can_ok( $data->salon->[0]->urls, 'pc' );
    ok( eval { $data->salon->[0]->urls->pc }, 'Test[0]: pc' );
    can_ok( $data->salon->[0]->coupon_urls, 'pc' );
    ok( eval { $data->salon->[0]->coupon_urls->pc }, 'Test[0]: pc' );
    can_ok( $data->salon->[0]->service_area, 'code' );
    ok( eval { $data->salon->[0]->service_area->code }, 'Test[0]: code' );
    can_ok( $data->salon->[0]->service_area, 'name' );
    ok( eval { $data->salon->[0]->service_area->name }, 'Test[0]: name' );
    can_ok( $data->salon->[0]->middle_area, 'code' );
    ok( eval { $data->salon->[0]->middle_area->code }, 'Test[0]: code' );
    can_ok( $data->salon->[0]->middle_area, 'name' );
    ok( eval { $data->salon->[0]->middle_area->name }, 'Test[0]: name' );
    can_ok( $data->salon->[0]->small_area, 'code' );
    ok( eval { $data->salon->[0]->small_area->code }, 'Test[0]: code' );
    can_ok( $data->salon->[0]->small_area, 'name' );
    ok( eval { $data->salon->[0]->small_area->name }, 'Test[0]: name' );
    can_ok( $data->salon->[0]->main, 'photo' );
    ok( eval { $data->salon->[0]->main->photo }, 'Test[0]: photo' );
    can_ok( $data->salon->[0]->main, 'caption' );
    ok( eval { $data->salon->[0]->main->caption }, 'Test[0]: caption' );
    can_ok( $data->salon->[0]->feature->[0], 'name' );
    ok( eval { $data->salon->[0]->feature->[0]->name }, 'Test[0]: name' );
    can_ok( $data->salon->[0]->feature->[0], 'caption' );
    ok( eval { $data->salon->[0]->feature->[0]->caption }, 'Test[0]: caption' );
    can_ok( $data->salon->[0]->feature->[0], 'description' );
    ok( eval { $data->salon->[0]->feature->[0]->description }, 'Test[0]: description' );
    can_ok( $data->salon->[0]->main->photo, 's' );
    ok( eval { $data->salon->[0]->main->photo->s }, 'Test[0]: s' );
    can_ok( $data->salon->[0]->main->photo, 'm' );
    ok( eval { $data->salon->[0]->main->photo->m }, 'Test[0]: m' );
    can_ok( $data->salon->[0]->main->photo, 'l' );
    ok( eval { $data->salon->[0]->main->photo->l }, 'Test[0]: l' );
}

# Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::HotPepperBeauty::Salon();
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
    my $res = new WebService::Recruit::HotPepperBeauty::Salon();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[2]: die' );
}


1;
