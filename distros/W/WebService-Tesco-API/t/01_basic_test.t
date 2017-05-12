#!perl

BEGIN {
    unless ($ENV{'TESCO_APP_KEY'}
        && $ENV{'TESCO_DEVELOPER_KEY'}
        && $ENV{'TESCO_EMAIL'}
        && $ENV{'TESCO_PASSWORD'})
    {
        require Test::More;
        Test::More::plan(skip_all =>
              'Set the following environment variables or these tests are skipped: '
              . "\n"
              . q/ $ENV{'TESCO_APP_KEY'} $ENV{'TESCO_DEVELOPER_KEY'} $ENV{'TESCO_EMAIL'} $ENV{'TESCO_PASSWORD'} /
        );
    }
}

use strict;
use warnings;

use Test::Most tests => 18;
use lib 'lib';

use_ok('WebService::Tesco::API');


my $tesco = WebService::Tesco::API->new(
    app_key       => $ENV{'TESCO_APP_KEY'},
    developer_key => $ENV{'TESCO_DEVELOPER_KEY'},
);

isa_ok($tesco, 'WebService::Tesco::API', 'Create a new instance');

can_ok(
    $tesco,
    qw ( new get login session_get amend_order cancel_amend_order
      change_basket choose_delivery_slot latest_app_version
      list_delivery_slots list_basket list_basket_summary
      list_favourites list_pending_orders list_product_categories
      list_product_offers list_products_by_category product_search
      ready_for_checkout server_date_time save_amend_order )
);

my $result = $tesco->login(
    {   email    => $ENV{'TESCO_EMAIL'},
        password => $ENV{'TESCO_PASSWORD'},
    }
);


is($result->{StatusCode}, 0, 'Correct status code for login');
is($tesco->list_delivery_slots()->{StatusCode},
    0, 'Correct status code for list_delivery_slots');
is($tesco->list_basket()->{StatusCode},
    0, 'Correct status code for list_basket');
is($tesco->list_basket({fast => 'Y'})->{StatusCode},
    0, 'Correct status code for list_basket with fast results');
is($tesco->list_basket_summary()->{StatusCode},
    0, 'Correct status code for list_basket_summary');
is($tesco->list_basket_summary({includeproducts => 'Y'})->{StatusCode},
    0, 'Correct status code for list_basket_summary with products included');
is($tesco->list_favourites({page => 1})->{StatusCode},
    0, 'Correct status code for list_favourites');
is($tesco->list_pending_orders()->{StatusCode},
    0, 'Correct status code for list_pending_orders');
is($tesco->list_product_categories()->{StatusCode},
    0, 'Correct status code for list_product_categories');
is($tesco->list_product_offers({page => 1})->{StatusCode},
    0, 'Correct status code for list_product_offers');
is($tesco->list_products_by_category({category => 18})->{StatusCode},
    0, 'Correct status code for list_products_by_category');
is($tesco->list_products_by_category()->{StatusCode}, 150,
    'Correct status code for list_products_by_category with no category passed'
);
is( $tesco->product_search({searchtext => 'Turnip', extendedinfo => 'Y'})
      ->{StatusCode},
    0,
    'Correct status code for product_search'
);
is($tesco->ready_for_checkout()->{StatusCode},
    100, 'Correct status code for checkout, No delivery slot reserved');
is($tesco->server_date_time()->{StatusCode},
    0, 'Correct status code for server_date_time');
