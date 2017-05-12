#
# Test case for WebService::Recruit::Aikento::Item
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
plan tests => 70;

use_ok('WebService::Recruit::Aikento::Item');

my $service = new WebService::Recruit::Aikento::Item();

ok( ref $service, 'new WebService::Recruit::Aikento::Item()' );


# Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'large_category' => '202',
    };
    my $res = new WebService::Recruit::Aikento::Item();
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
    can_ok( $data, 'item' );
    ok( eval { $data->item }, 'Test[0]: item' );
    ok( eval { ref $data->item } eq 'ARRAY', 'Test[0]: item' );
    can_ok( $data->item->[0], 'code' );
    ok( eval { $data->item->[0]->code }, 'Test[0]: code' );
    can_ok( $data->item->[0], 'shop_code' );
    ok( eval { $data->item->[0]->shop_code }, 'Test[0]: shop_code' );
    can_ok( $data->item->[0], 'name' );
    ok( eval { $data->item->[0]->name }, 'Test[0]: name' );
    can_ok( $data->item->[0], 'price' );
    ok( eval { $data->item->[0]->price }, 'Test[0]: price' );
    can_ok( $data->item->[0], 'catch_copy' );
    ok( eval { $data->item->[0]->catch_copy }, 'Test[0]: catch_copy' );
    can_ok( $data->item->[0], 'desc' );
    ok( eval { $data->item->[0]->desc }, 'Test[0]: desc' );
    can_ok( $data->item->[0], 'image' );
    ok( eval { $data->item->[0]->image }, 'Test[0]: image' );
    can_ok( $data->item->[0], 'large_category' );
    ok( eval { $data->item->[0]->large_category }, 'Test[0]: large_category' );
    can_ok( $data->item->[0], 'small_category' );
    ok( eval { $data->item->[0]->small_category }, 'Test[0]: small_category' );
    can_ok( $data->item->[0], 'page' );
    ok( eval { $data->item->[0]->page }, 'Test[0]: page' );
    can_ok( $data->item->[0], 'start_date' );
    ok( eval { $data->item->[0]->start_date }, 'Test[0]: start_date' );
    can_ok( $data->item->[0], 'end_date' );
    ok( eval { $data->item->[0]->end_date }, 'Test[0]: end_date' );
    can_ok( $data->item->[0], 'urls' );
    ok( eval { $data->item->[0]->urls }, 'Test[0]: urls' );
    can_ok( $data->item->[0]->image, 'pc' );
    ok( eval { $data->item->[0]->image->pc }, 'Test[0]: pc' );
    can_ok( $data->item->[0]->image, 'mobile' );
    ok( eval { $data->item->[0]->image->mobile }, 'Test[0]: mobile' );
    can_ok( $data->item->[0]->large_category, 'code' );
    ok( eval { $data->item->[0]->large_category->code }, 'Test[0]: code' );
    can_ok( $data->item->[0]->large_category, 'name' );
    ok( eval { $data->item->[0]->large_category->name }, 'Test[0]: name' );
    can_ok( $data->item->[0]->small_category, 'code' );
    ok( eval { $data->item->[0]->small_category->code }, 'Test[0]: code' );
    can_ok( $data->item->[0]->small_category, 'name' );
    ok( eval { $data->item->[0]->small_category->name }, 'Test[0]: name' );
    can_ok( $data->item->[0]->urls, 'mobile' );
    ok( eval { $data->item->[0]->urls->mobile }, 'Test[0]: mobile' );
    can_ok( $data->item->[0]->urls, 'pc' );
    ok( eval { $data->item->[0]->urls->pc }, 'Test[0]: pc' );
    can_ok( $data->item->[0]->urls, 'qr' );
    ok( eval { $data->item->[0]->urls->qr }, 'Test[0]: qr' );
}

# Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::Aikento::Item();
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
    my $res = new WebService::Recruit::Aikento::Item();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[2]: die' );
}


1;
