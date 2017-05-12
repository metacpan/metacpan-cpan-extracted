#
# Test case for WebService::Recruit::AkasuguUchiiwai::Item
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
plan tests => 80;

use_ok('WebService::Recruit::AkasuguUchiiwai::Item');

my $service = new WebService::Recruit::AkasuguUchiiwai::Item();

ok( ref $service, 'new WebService::Recruit::AkasuguUchiiwai::Item()' );


# Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'target' => '1',
    };
    my $res = new WebService::Recruit::AkasuguUchiiwai::Item();
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
    can_ok( $data->item->[0], 'brand' );
    ok( eval { $data->item->[0]->brand }, 'Test[0]: brand' );
    can_ok( $data->item->[0], 'name' );
    ok( eval { $data->item->[0]->name }, 'Test[0]: name' );
    can_ok( $data->item->[0], 'price' );
    ok( eval { $data->item->[0]->price }, 'Test[0]: price' );
    can_ok( $data->item->[0], 'desc' );
    ok( eval { $data->item->[0]->desc }, 'Test[0]: desc' );
    can_ok( $data->item->[0], 'spec' );
    ok( eval { $data->item->[0]->spec }, 'Test[0]: spec' );
    can_ok( $data->item->[0], 'image' );
    ok( eval { $data->item->[0]->image }, 'Test[0]: image' );
    can_ok( $data->item->[0], 'category' );
    ok( eval { $data->item->[0]->category }, 'Test[0]: category' );
    can_ok( $data->item->[0], 'target' );
    ok( eval { $data->item->[0]->target }, 'Test[0]: target' );
    can_ok( $data->item->[0], 'feature' );
    ok( eval { $data->item->[0]->feature }, 'Test[0]: feature' );
    can_ok( $data->item->[0], 'start_date' );
    ok( eval { $data->item->[0]->start_date }, 'Test[0]: start_date' );
    can_ok( $data->item->[0], 'end_date' );
    ok( eval { $data->item->[0]->end_date }, 'Test[0]: end_date' );
    can_ok( $data->item->[0], 'urls' );
    ok( eval { $data->item->[0]->urls }, 'Test[0]: urls' );
    can_ok( $data->item->[0]->image, 'pc_l' );
    ok( eval { $data->item->[0]->image->pc_l }, 'Test[0]: pc_l' );
    can_ok( $data->item->[0]->image, 'pc_m' );
    ok( eval { $data->item->[0]->image->pc_m }, 'Test[0]: pc_m' );
    can_ok( $data->item->[0]->image, 'pc_s' );
    ok( eval { $data->item->[0]->image->pc_s }, 'Test[0]: pc_s' );
    can_ok( $data->item->[0]->image, 'mobile_l' );
    ok( eval { $data->item->[0]->image->mobile_l }, 'Test[0]: mobile_l' );
    can_ok( $data->item->[0]->image, 'mobile_s' );
    ok( eval { $data->item->[0]->image->mobile_s }, 'Test[0]: mobile_s' );
    can_ok( $data->item->[0]->category, 'code' );
    ok( eval { $data->item->[0]->category->code }, 'Test[0]: code' );
    can_ok( $data->item->[0]->category, 'name' );
    ok( eval { $data->item->[0]->category->name }, 'Test[0]: name' );
    can_ok( $data->item->[0]->target, 'code' );
    ok( eval { $data->item->[0]->target->code }, 'Test[0]: code' );
    can_ok( $data->item->[0]->target, 'name' );
    ok( eval { $data->item->[0]->target->name }, 'Test[0]: name' );
    can_ok( $data->item->[0]->feature, 'code' );
    ok( eval { $data->item->[0]->feature->code }, 'Test[0]: code' );
    can_ok( $data->item->[0]->feature, 'name' );
    ok( eval { $data->item->[0]->feature->name }, 'Test[0]: name' );
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
    my $res = new WebService::Recruit::AkasuguUchiiwai::Item();
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
    my $res = new WebService::Recruit::AkasuguUchiiwai::Item();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[2]: die' );
}


1;
