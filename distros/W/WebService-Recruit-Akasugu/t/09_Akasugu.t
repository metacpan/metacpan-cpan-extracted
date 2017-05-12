#
# Test case for WebService::Recruit::Akasugu
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
plan tests => 164;

use_ok('WebService::Recruit::Akasugu');

my $obj = WebService::Recruit::Akasugu->new();

ok(ref $obj, 'new WebService::Recruit::Akasugu()');


# item / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'large_category_cd' => '2',
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
    can_ok( $data->item->[0], 'company' );
    if ( $data->item->[0]->can('company') ) {
        ok( $data->item->[0]->company, 'item / Test[0]: company' );
    }
    can_ok( $data->item->[0], 'name' );
    if ( $data->item->[0]->can('name') ) {
        ok( $data->item->[0]->name, 'item / Test[0]: name' );
    }
    can_ok( $data->item->[0], 'price' );
    if ( $data->item->[0]->can('price') ) {
        ok( $data->item->[0]->price, 'item / Test[0]: price' );
    }
    can_ok( $data->item->[0], 'catch_copy' );
    if ( $data->item->[0]->can('catch_copy') ) {
        ok( $data->item->[0]->catch_copy, 'item / Test[0]: catch_copy' );
    }
    can_ok( $data->item->[0], 'desc' );
    if ( $data->item->[0]->can('desc') ) {
        ok( $data->item->[0]->desc, 'item / Test[0]: desc' );
    }
    can_ok( $data->item->[0], 'image' );
    if ( $data->item->[0]->can('image') ) {
        ok( $data->item->[0]->image, 'item / Test[0]: image' );
    }
    can_ok( $data->item->[0], 'large_category' );
    if ( $data->item->[0]->can('large_category') ) {
        ok( $data->item->[0]->large_category, 'item / Test[0]: large_category' );
    }
    can_ok( $data->item->[0], 'middle_category' );
    if ( $data->item->[0]->can('middle_category') ) {
        ok( $data->item->[0]->middle_category, 'item / Test[0]: middle_category' );
    }
    can_ok( $data->item->[0], 'small_category' );
    if ( $data->item->[0]->can('small_category') ) {
        ok( $data->item->[0]->small_category, 'item / Test[0]: small_category' );
    }
    can_ok( $data->item->[0], 'urls' );
    if ( $data->item->[0]->can('urls') ) {
        ok( $data->item->[0]->urls, 'item / Test[0]: urls' );
    }
    can_ok( $data->item->[0]->image, 'pc' );
    if ( $data->item->[0]->image->can('pc') ) {
        ok( $data->item->[0]->image->pc, 'item / Test[0]: pc' );
    }
    can_ok( $data->item->[0]->image, 'mobile' );
    if ( $data->item->[0]->image->can('mobile') ) {
        ok( $data->item->[0]->image->mobile, 'item / Test[0]: mobile' );
    }
    can_ok( $data->item->[0]->large_category, 'code' );
    if ( $data->item->[0]->large_category->can('code') ) {
        ok( $data->item->[0]->large_category->code, 'item / Test[0]: code' );
    }
    can_ok( $data->item->[0]->large_category, 'name' );
    if ( $data->item->[0]->large_category->can('name') ) {
        ok( $data->item->[0]->large_category->name, 'item / Test[0]: name' );
    }
    can_ok( $data->item->[0]->middle_category, 'code' );
    if ( $data->item->[0]->middle_category->can('code') ) {
        ok( $data->item->[0]->middle_category->code, 'item / Test[0]: code' );
    }
    can_ok( $data->item->[0]->middle_category, 'name' );
    if ( $data->item->[0]->middle_category->can('name') ) {
        ok( $data->item->[0]->middle_category->name, 'item / Test[0]: name' );
    }
    can_ok( $data->item->[0]->small_category, 'code' );
    if ( $data->item->[0]->small_category->can('code') ) {
        ok( $data->item->[0]->small_category->code, 'item / Test[0]: code' );
    }
    can_ok( $data->item->[0]->small_category, 'name' );
    if ( $data->item->[0]->small_category->can('name') ) {
        ok( $data->item->[0]->small_category->name, 'item / Test[0]: name' );
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



# large_category / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->large_category(%$params); };
    ok( ! $@, 'large_category / Test[0]: die' );
    ok( ! $res->is_error, 'large_category / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'large_category / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'large_category / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'large_category / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'large_category / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'large_category / Test[0]: results_start' );
    }
    can_ok( $data, 'large_category' );
    if ( $data->can('large_category') ) {
        ok( $data->large_category, 'large_category / Test[0]: large_category' );
        ok( ref $data->large_category eq 'ARRAY', 'large_category / Test[0]: large_category' );
    }
    can_ok( $data->large_category->[0], 'code' );
    if ( $data->large_category->[0]->can('code') ) {
        ok( $data->large_category->[0]->code, 'large_category / Test[0]: code' );
    }
    can_ok( $data->large_category->[0], 'name' );
    if ( $data->large_category->[0]->can('name') ) {
        ok( $data->large_category->[0]->name, 'large_category / Test[0]: name' );
    }
}

# large_category / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->large_category(%$params); };
    ok( $@, 'large_category / Test[1]: die' );
}



# middle_category / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->middle_category(%$params); };
    ok( ! $@, 'middle_category / Test[0]: die' );
    ok( ! $res->is_error, 'middle_category / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'middle_category / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'middle_category / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'middle_category / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'middle_category / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'middle_category / Test[0]: results_start' );
    }
    can_ok( $data, 'middle_category' );
    if ( $data->can('middle_category') ) {
        ok( $data->middle_category, 'middle_category / Test[0]: middle_category' );
        ok( ref $data->middle_category eq 'ARRAY', 'middle_category / Test[0]: middle_category' );
    }
    can_ok( $data->middle_category->[0], 'code' );
    if ( $data->middle_category->[0]->can('code') ) {
        ok( $data->middle_category->[0]->code, 'middle_category / Test[0]: code' );
    }
    can_ok( $data->middle_category->[0], 'name' );
    if ( $data->middle_category->[0]->can('name') ) {
        ok( $data->middle_category->[0]->name, 'middle_category / Test[0]: name' );
    }
    can_ok( $data->middle_category->[0], 'large_category' );
    if ( $data->middle_category->[0]->can('large_category') ) {
        ok( $data->middle_category->[0]->large_category, 'middle_category / Test[0]: large_category' );
    }
    can_ok( $data->middle_category->[0]->large_category, 'code' );
    if ( $data->middle_category->[0]->large_category->can('code') ) {
        ok( $data->middle_category->[0]->large_category->code, 'middle_category / Test[0]: code' );
    }
    can_ok( $data->middle_category->[0]->large_category, 'name' );
    if ( $data->middle_category->[0]->large_category->can('name') ) {
        ok( $data->middle_category->[0]->large_category->name, 'middle_category / Test[0]: name' );
    }
}

# middle_category / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->middle_category(%$params); };
    ok( $@, 'middle_category / Test[1]: die' );
}



# small_category / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->small_category(%$params); };
    ok( ! $@, 'small_category / Test[0]: die' );
    ok( ! $res->is_error, 'small_category / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'small_category / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'small_category / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'small_category / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'small_category / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'small_category / Test[0]: results_start' );
    }
    can_ok( $data, 'small_category' );
    if ( $data->can('small_category') ) {
        ok( $data->small_category, 'small_category / Test[0]: small_category' );
        ok( ref $data->small_category eq 'ARRAY', 'small_category / Test[0]: small_category' );
    }
    can_ok( $data->small_category->[0], 'code' );
    if ( $data->small_category->[0]->can('code') ) {
        ok( $data->small_category->[0]->code, 'small_category / Test[0]: code' );
    }
    can_ok( $data->small_category->[0], 'name' );
    if ( $data->small_category->[0]->can('name') ) {
        ok( $data->small_category->[0]->name, 'small_category / Test[0]: name' );
    }
    can_ok( $data->small_category->[0], 'large_category' );
    if ( $data->small_category->[0]->can('large_category') ) {
        ok( $data->small_category->[0]->large_category, 'small_category / Test[0]: large_category' );
    }
    can_ok( $data->small_category->[0], 'middle_category' );
    if ( $data->small_category->[0]->can('middle_category') ) {
        ok( $data->small_category->[0]->middle_category, 'small_category / Test[0]: middle_category' );
    }
    can_ok( $data->small_category->[0]->large_category, 'code' );
    if ( $data->small_category->[0]->large_category->can('code') ) {
        ok( $data->small_category->[0]->large_category->code, 'small_category / Test[0]: code' );
    }
    can_ok( $data->small_category->[0]->large_category, 'name' );
    if ( $data->small_category->[0]->large_category->can('name') ) {
        ok( $data->small_category->[0]->large_category->name, 'small_category / Test[0]: name' );
    }
    can_ok( $data->small_category->[0]->middle_category, 'code' );
    if ( $data->small_category->[0]->middle_category->can('code') ) {
        ok( $data->small_category->[0]->middle_category->code, 'small_category / Test[0]: code' );
    }
    can_ok( $data->small_category->[0]->middle_category, 'name' );
    if ( $data->small_category->[0]->middle_category->can('name') ) {
        ok( $data->small_category->[0]->middle_category->name, 'small_category / Test[0]: name' );
    }
}

# small_category / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->small_category(%$params); };
    ok( $@, 'small_category / Test[1]: die' );
}



# age / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->age(%$params); };
    ok( ! $@, 'age / Test[0]: die' );
    ok( ! $res->is_error, 'age / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'age / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'age / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'age / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'age / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'age / Test[0]: results_start' );
    }
    can_ok( $data, 'age' );
    if ( $data->can('age') ) {
        ok( $data->age, 'age / Test[0]: age' );
        ok( ref $data->age eq 'ARRAY', 'age / Test[0]: age' );
    }
    can_ok( $data->age->[0], 'code' );
    if ( $data->age->[0]->can('code') ) {
        ok( $data->age->[0]->code, 'age / Test[0]: code' );
    }
    can_ok( $data->age->[0], 'name' );
    if ( $data->age->[0]->can('name') ) {
        ok( $data->age->[0]->name, 'age / Test[0]: name' );
    }
}

# age / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->age(%$params); };
    ok( $@, 'age / Test[1]: die' );
}



1;
