#
# Test case for WebService::Recruit::AkasuguUchiiwai
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
plan tests => 137;

use_ok('WebService::Recruit::AkasuguUchiiwai');

my $obj = WebService::Recruit::AkasuguUchiiwai->new();

ok(ref $obj, 'new WebService::Recruit::AkasuguUchiiwai()');


# item / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'target' => '1',
    };
    my $res = eval { $obj->item(%$params); };
    ok( ! $@, 'item / Test[0]: die' );
    ok( ! $res->is_error, 'item / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'item / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'item / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'item / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'item / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'item / Test[0]: results_start' );
    }
    can_ok( $data, 'item' );
    if ( $data->can('item') ) {
        ok( $data->item, 'item / Test[0]: item' );
        ok( ref $data->item eq 'ARRAY', 'item / Test[0]: item' );
    }
    can_ok( $data->item->[0], 'code' );
    if ( $data->item->[0]->can('code') ) {
        ok( $data->item->[0]->code, 'item / Test[0]: code' );
    }
    can_ok( $data->item->[0], 'brand' );
    if ( $data->item->[0]->can('brand') ) {
        ok( $data->item->[0]->brand, 'item / Test[0]: brand' );
    }
    can_ok( $data->item->[0], 'name' );
    if ( $data->item->[0]->can('name') ) {
        ok( $data->item->[0]->name, 'item / Test[0]: name' );
    }
    can_ok( $data->item->[0], 'price' );
    if ( $data->item->[0]->can('price') ) {
        ok( $data->item->[0]->price, 'item / Test[0]: price' );
    }
    can_ok( $data->item->[0], 'desc' );
    if ( $data->item->[0]->can('desc') ) {
        ok( $data->item->[0]->desc, 'item / Test[0]: desc' );
    }
    can_ok( $data->item->[0], 'spec' );
    if ( $data->item->[0]->can('spec') ) {
        ok( $data->item->[0]->spec, 'item / Test[0]: spec' );
    }
    can_ok( $data->item->[0], 'image' );
    if ( $data->item->[0]->can('image') ) {
        ok( $data->item->[0]->image, 'item / Test[0]: image' );
    }
    can_ok( $data->item->[0], 'category' );
    if ( $data->item->[0]->can('category') ) {
        ok( $data->item->[0]->category, 'item / Test[0]: category' );
    }
    can_ok( $data->item->[0], 'target' );
    if ( $data->item->[0]->can('target') ) {
        ok( $data->item->[0]->target, 'item / Test[0]: target' );
    }
    can_ok( $data->item->[0], 'feature' );
    if ( $data->item->[0]->can('feature') ) {
        ok( $data->item->[0]->feature, 'item / Test[0]: feature' );
    }
    can_ok( $data->item->[0], 'start_date' );
    if ( $data->item->[0]->can('start_date') ) {
        ok( $data->item->[0]->start_date, 'item / Test[0]: start_date' );
    }
    can_ok( $data->item->[0], 'end_date' );
    if ( $data->item->[0]->can('end_date') ) {
        ok( $data->item->[0]->end_date, 'item / Test[0]: end_date' );
    }
    can_ok( $data->item->[0], 'urls' );
    if ( $data->item->[0]->can('urls') ) {
        ok( $data->item->[0]->urls, 'item / Test[0]: urls' );
    }
    can_ok( $data->item->[0]->image, 'pc_l' );
    if ( $data->item->[0]->image->can('pc_l') ) {
        ok( $data->item->[0]->image->pc_l, 'item / Test[0]: pc_l' );
    }
    can_ok( $data->item->[0]->image, 'pc_m' );
    if ( $data->item->[0]->image->can('pc_m') ) {
        ok( $data->item->[0]->image->pc_m, 'item / Test[0]: pc_m' );
    }
    can_ok( $data->item->[0]->image, 'pc_s' );
    if ( $data->item->[0]->image->can('pc_s') ) {
        ok( $data->item->[0]->image->pc_s, 'item / Test[0]: pc_s' );
    }
    can_ok( $data->item->[0]->image, 'mobile_l' );
    if ( $data->item->[0]->image->can('mobile_l') ) {
        ok( $data->item->[0]->image->mobile_l, 'item / Test[0]: mobile_l' );
    }
    can_ok( $data->item->[0]->image, 'mobile_s' );
    if ( $data->item->[0]->image->can('mobile_s') ) {
        ok( $data->item->[0]->image->mobile_s, 'item / Test[0]: mobile_s' );
    }
    can_ok( $data->item->[0]->category, 'code' );
    if ( $data->item->[0]->category->can('code') ) {
        ok( $data->item->[0]->category->code, 'item / Test[0]: code' );
    }
    can_ok( $data->item->[0]->category, 'name' );
    if ( $data->item->[0]->category->can('name') ) {
        ok( $data->item->[0]->category->name, 'item / Test[0]: name' );
    }
    can_ok( $data->item->[0]->target, 'code' );
    if ( $data->item->[0]->target->can('code') ) {
        ok( $data->item->[0]->target->code, 'item / Test[0]: code' );
    }
    can_ok( $data->item->[0]->target, 'name' );
    if ( $data->item->[0]->target->can('name') ) {
        ok( $data->item->[0]->target->name, 'item / Test[0]: name' );
    }
    can_ok( $data->item->[0]->feature, 'code' );
    if ( $data->item->[0]->feature->can('code') ) {
        ok( $data->item->[0]->feature->code, 'item / Test[0]: code' );
    }
    can_ok( $data->item->[0]->feature, 'name' );
    if ( $data->item->[0]->feature->can('name') ) {
        ok( $data->item->[0]->feature->name, 'item / Test[0]: name' );
    }
    can_ok( $data->item->[0]->urls, 'mobile' );
    if ( $data->item->[0]->urls->can('mobile') ) {
        ok( $data->item->[0]->urls->mobile, 'item / Test[0]: mobile' );
    }
    can_ok( $data->item->[0]->urls, 'pc' );
    if ( $data->item->[0]->urls->can('pc') ) {
        ok( $data->item->[0]->urls->pc, 'item / Test[0]: pc' );
    }
    can_ok( $data->item->[0]->urls, 'qr' );
    if ( $data->item->[0]->urls->can('qr') ) {
        ok( $data->item->[0]->urls->qr, 'item / Test[0]: qr' );
    }
}

# item / Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->item(%$params); };
    ok( ! $@, 'item / Test[1]: die' );
    ok( ! $res->is_error, 'item / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'item / Test[1]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'item / Test[1]: api_version' );
    }
    can_ok( $data, 'error' );
    if ( $data->can('error') ) {
        ok( $data->error, 'item / Test[1]: error' );
    }
    can_ok( $data->error, 'message' );
    if ( $data->error->can('message') ) {
        ok( $data->error->message, 'item / Test[1]: message' );
    }
}

# item / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->item(%$params); };
    ok( $@, 'item / Test[2]: die' );
}



# category / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->category(%$params); };
    ok( ! $@, 'category / Test[0]: die' );
    ok( ! $res->is_error, 'category / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'category / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'category / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'category / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'category / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'category / Test[0]: results_start' );
    }
    can_ok( $data, 'category' );
    if ( $data->can('category') ) {
        ok( $data->category, 'category / Test[0]: category' );
        ok( ref $data->category eq 'ARRAY', 'category / Test[0]: category' );
    }
    can_ok( $data->category->[0], 'code' );
    if ( $data->category->[0]->can('code') ) {
        ok( $data->category->[0]->code, 'category / Test[0]: code' );
    }
    can_ok( $data->category->[0], 'name' );
    if ( $data->category->[0]->can('name') ) {
        ok( $data->category->[0]->name, 'category / Test[0]: name' );
    }
}

# category / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->category(%$params); };
    ok( $@, 'category / Test[1]: die' );
}



# target / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->target(%$params); };
    ok( ! $@, 'target / Test[0]: die' );
    ok( ! $res->is_error, 'target / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'target / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'target / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'target / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'target / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'target / Test[0]: results_start' );
    }
    can_ok( $data, 'target' );
    if ( $data->can('target') ) {
        ok( $data->target, 'target / Test[0]: target' );
        ok( ref $data->target eq 'ARRAY', 'target / Test[0]: target' );
    }
    can_ok( $data->target->[0], 'code' );
    if ( $data->target->[0]->can('code') ) {
        ok( $data->target->[0]->code, 'target / Test[0]: code' );
    }
    can_ok( $data->target->[0], 'name' );
    if ( $data->target->[0]->can('name') ) {
        ok( $data->target->[0]->name, 'target / Test[0]: name' );
    }
}

# target / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->target(%$params); };
    ok( $@, 'target / Test[1]: die' );
}



# feature / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->feature(%$params); };
    ok( ! $@, 'feature / Test[0]: die' );
    ok( ! $res->is_error, 'feature / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'feature / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'feature / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'feature / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'feature / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'feature / Test[0]: results_start' );
    }
    can_ok( $data, 'feature' );
    if ( $data->can('feature') ) {
        ok( $data->feature, 'feature / Test[0]: feature' );
        ok( ref $data->feature eq 'ARRAY', 'feature / Test[0]: feature' );
    }
    can_ok( $data->feature->[0], 'code' );
    if ( $data->feature->[0]->can('code') ) {
        ok( $data->feature->[0]->code, 'feature / Test[0]: code' );
    }
    can_ok( $data->feature->[0], 'name' );
    if ( $data->feature->[0]->can('name') ) {
        ok( $data->feature->[0]->name, 'feature / Test[0]: name' );
    }
}

# feature / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->feature(%$params); };
    ok( $@, 'feature / Test[1]: die' );
}



1;
