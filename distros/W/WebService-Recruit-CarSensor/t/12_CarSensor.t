#
# Test case for WebService::Recruit::CarSensor
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
plan tests => 321;

use_ok('WebService::Recruit::CarSensor');

my $obj = WebService::Recruit::CarSensor->new();

ok(ref $obj, 'new WebService::Recruit::CarSensor()');


# usedcar / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'pref' => '13',
    };
    my $res = eval { $obj->usedcar(%$params); };
    ok( ! $@, 'usedcar / Test[0]: die' );
    ok( ! $res->is_error, 'usedcar / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'usedcar / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'usedcar / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'usedcar / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'usedcar / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'usedcar / Test[0]: results_start' );
    }
    can_ok( $data, 'usedcar' );
    if ( $data->can('usedcar') ) {
        ok( $data->usedcar, 'usedcar / Test[0]: usedcar' );
        ok( ref $data->usedcar eq 'ARRAY', 'usedcar / Test[0]: usedcar' );
    }
    can_ok( $data->usedcar->[0], 'id' );
    if ( $data->usedcar->[0]->can('id') ) {
        ok( $data->usedcar->[0]->id, 'usedcar / Test[0]: id' );
    }
    can_ok( $data->usedcar->[0], 'brand' );
    if ( $data->usedcar->[0]->can('brand') ) {
        ok( $data->usedcar->[0]->brand, 'usedcar / Test[0]: brand' );
    }
    can_ok( $data->usedcar->[0], 'model' );
    if ( $data->usedcar->[0]->can('model') ) {
        ok( $data->usedcar->[0]->model, 'usedcar / Test[0]: model' );
    }
    can_ok( $data->usedcar->[0], 'grade' );
    if ( $data->usedcar->[0]->can('grade') ) {
        ok( $data->usedcar->[0]->grade, 'usedcar / Test[0]: grade' );
    }
    can_ok( $data->usedcar->[0], 'price' );
    if ( $data->usedcar->[0]->can('price') ) {
        ok( $data->usedcar->[0]->price, 'usedcar / Test[0]: price' );
    }
    can_ok( $data->usedcar->[0], 'desc' );
    if ( $data->usedcar->[0]->can('desc') ) {
        ok( $data->usedcar->[0]->desc, 'usedcar / Test[0]: desc' );
    }
    can_ok( $data->usedcar->[0], 'body' );
    if ( $data->usedcar->[0]->can('body') ) {
        ok( $data->usedcar->[0]->body, 'usedcar / Test[0]: body' );
    }
    can_ok( $data->usedcar->[0], 'odd' );
    if ( $data->usedcar->[0]->can('odd') ) {
        ok( $data->usedcar->[0]->odd, 'usedcar / Test[0]: odd' );
    }
    can_ok( $data->usedcar->[0], 'year' );
    if ( $data->usedcar->[0]->can('year') ) {
        ok( $data->usedcar->[0]->year, 'usedcar / Test[0]: year' );
    }
    can_ok( $data->usedcar->[0], 'shop' );
    if ( $data->usedcar->[0]->can('shop') ) {
        ok( $data->usedcar->[0]->shop, 'usedcar / Test[0]: shop' );
    }
    can_ok( $data->usedcar->[0], 'color' );
    if ( $data->usedcar->[0]->can('color') ) {
        ok( $data->usedcar->[0]->color, 'usedcar / Test[0]: color' );
    }
    can_ok( $data->usedcar->[0], 'photo' );
    if ( $data->usedcar->[0]->can('photo') ) {
        ok( $data->usedcar->[0]->photo, 'usedcar / Test[0]: photo' );
    }
    can_ok( $data->usedcar->[0], 'urls' );
    if ( $data->usedcar->[0]->can('urls') ) {
        ok( $data->usedcar->[0]->urls, 'usedcar / Test[0]: urls' );
    }
    can_ok( $data->usedcar->[0]->brand, 'code' );
    if ( $data->usedcar->[0]->brand->can('code') ) {
        ok( $data->usedcar->[0]->brand->code, 'usedcar / Test[0]: code' );
    }
    can_ok( $data->usedcar->[0]->brand, 'name' );
    if ( $data->usedcar->[0]->brand->can('name') ) {
        ok( $data->usedcar->[0]->brand->name, 'usedcar / Test[0]: name' );
    }
    can_ok( $data->usedcar->[0]->body, 'code' );
    if ( $data->usedcar->[0]->body->can('code') ) {
        ok( $data->usedcar->[0]->body->code, 'usedcar / Test[0]: code' );
    }
    can_ok( $data->usedcar->[0]->body, 'name' );
    if ( $data->usedcar->[0]->body->can('name') ) {
        ok( $data->usedcar->[0]->body->name, 'usedcar / Test[0]: name' );
    }
    can_ok( $data->usedcar->[0]->shop, 'name' );
    if ( $data->usedcar->[0]->shop->can('name') ) {
        ok( $data->usedcar->[0]->shop->name, 'usedcar / Test[0]: name' );
    }
    can_ok( $data->usedcar->[0]->shop, 'pref' );
    if ( $data->usedcar->[0]->shop->can('pref') ) {
        ok( $data->usedcar->[0]->shop->pref, 'usedcar / Test[0]: pref' );
    }
    can_ok( $data->usedcar->[0]->shop, 'lat' );
    if ( $data->usedcar->[0]->shop->can('lat') ) {
        ok( $data->usedcar->[0]->shop->lat, 'usedcar / Test[0]: lat' );
    }
    can_ok( $data->usedcar->[0]->shop, 'lng' );
    if ( $data->usedcar->[0]->shop->can('lng') ) {
        ok( $data->usedcar->[0]->shop->lng, 'usedcar / Test[0]: lng' );
    }
    can_ok( $data->usedcar->[0]->shop, 'datum' );
    if ( $data->usedcar->[0]->shop->can('datum') ) {
        ok( $data->usedcar->[0]->shop->datum, 'usedcar / Test[0]: datum' );
    }
    can_ok( $data->usedcar->[0]->photo, 'main' );
    if ( $data->usedcar->[0]->photo->can('main') ) {
        ok( $data->usedcar->[0]->photo->main, 'usedcar / Test[0]: main' );
    }
    can_ok( $data->usedcar->[0]->photo, 'sub' );
    if ( $data->usedcar->[0]->photo->can('sub') ) {
        ok( $data->usedcar->[0]->photo->sub, 'usedcar / Test[0]: sub' );
        ok( ref $data->usedcar->[0]->photo->sub eq 'ARRAY', 'usedcar / Test[0]: sub' );
    }
    can_ok( $data->usedcar->[0]->urls, 'pc' );
    if ( $data->usedcar->[0]->urls->can('pc') ) {
        ok( $data->usedcar->[0]->urls->pc, 'usedcar / Test[0]: pc' );
    }
    can_ok( $data->usedcar->[0]->urls, 'mobile' );
    if ( $data->usedcar->[0]->urls->can('mobile') ) {
        ok( $data->usedcar->[0]->urls->mobile, 'usedcar / Test[0]: mobile' );
    }
    can_ok( $data->usedcar->[0]->urls, 'qr' );
    if ( $data->usedcar->[0]->urls->can('qr') ) {
        ok( $data->usedcar->[0]->urls->qr, 'usedcar / Test[0]: qr' );
    }
    can_ok( $data->usedcar->[0]->shop->pref, 'code' );
    if ( $data->usedcar->[0]->shop->pref->can('code') ) {
        ok( $data->usedcar->[0]->shop->pref->code, 'usedcar / Test[0]: code' );
    }
    can_ok( $data->usedcar->[0]->shop->pref, 'name' );
    if ( $data->usedcar->[0]->shop->pref->can('name') ) {
        ok( $data->usedcar->[0]->shop->pref->name, 'usedcar / Test[0]: name' );
    }
    can_ok( $data->usedcar->[0]->photo->main, 'l' );
    if ( $data->usedcar->[0]->photo->main->can('l') ) {
        ok( $data->usedcar->[0]->photo->main->l, 'usedcar / Test[0]: l' );
    }
    can_ok( $data->usedcar->[0]->photo->main, 's' );
    if ( $data->usedcar->[0]->photo->main->can('s') ) {
        ok( $data->usedcar->[0]->photo->main->s, 'usedcar / Test[0]: s' );
    }
}

# usedcar / Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->usedcar(%$params); };
    ok( ! $@, 'usedcar / Test[1]: die' );
    ok( ! $res->is_error, 'usedcar / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'usedcar / Test[1]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'usedcar / Test[1]: api_version' );
    }
    can_ok( $data, 'error' );
    if ( $data->can('error') ) {
        ok( $data->error, 'usedcar / Test[1]: error' );
    }
    can_ok( $data->error, 'message' );
    if ( $data->error->can('message') ) {
        ok( $data->error->message, 'usedcar / Test[1]: message' );
    }
}

# usedcar / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->usedcar(%$params); };
    ok( $@, 'usedcar / Test[2]: die' );
}



# catalog / Test[0]
{
    my $params = {
        'country' => 'JPN',
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->catalog(%$params); };
    ok( ! $@, 'catalog / Test[0]: die' );
    ok( ! $res->is_error, 'catalog / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'catalog / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'catalog / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'catalog / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'catalog / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'catalog / Test[0]: results_start' );
    }
    can_ok( $data, 'catalog' );
    if ( $data->can('catalog') ) {
        ok( $data->catalog, 'catalog / Test[0]: catalog' );
        ok( ref $data->catalog eq 'ARRAY', 'catalog / Test[0]: catalog' );
    }
    can_ok( $data->catalog->[0], 'brand' );
    if ( $data->catalog->[0]->can('brand') ) {
        ok( $data->catalog->[0]->brand, 'catalog / Test[0]: brand' );
    }
    can_ok( $data->catalog->[0], 'model' );
    if ( $data->catalog->[0]->can('model') ) {
        ok( $data->catalog->[0]->model, 'catalog / Test[0]: model' );
    }
    can_ok( $data->catalog->[0], 'grade' );
    if ( $data->catalog->[0]->can('grade') ) {
        ok( $data->catalog->[0]->grade, 'catalog / Test[0]: grade' );
    }
    can_ok( $data->catalog->[0], 'price' );
    if ( $data->catalog->[0]->can('price') ) {
        ok( $data->catalog->[0]->price, 'catalog / Test[0]: price' );
    }
    can_ok( $data->catalog->[0], 'body' );
    if ( $data->catalog->[0]->can('body') ) {
        ok( $data->catalog->[0]->body, 'catalog / Test[0]: body' );
    }
    can_ok( $data->catalog->[0], 'person' );
    if ( $data->catalog->[0]->can('person') ) {
        ok( $data->catalog->[0]->person, 'catalog / Test[0]: person' );
    }
    can_ok( $data->catalog->[0], 'period' );
    if ( $data->catalog->[0]->can('period') ) {
        ok( $data->catalog->[0]->period, 'catalog / Test[0]: period' );
    }
    can_ok( $data->catalog->[0], 'series' );
    if ( $data->catalog->[0]->can('series') ) {
        ok( $data->catalog->[0]->series, 'catalog / Test[0]: series' );
    }
    can_ok( $data->catalog->[0], 'width' );
    if ( $data->catalog->[0]->can('width') ) {
        ok( $data->catalog->[0]->width, 'catalog / Test[0]: width' );
    }
    can_ok( $data->catalog->[0], 'height' );
    if ( $data->catalog->[0]->can('height') ) {
        ok( $data->catalog->[0]->height, 'catalog / Test[0]: height' );
    }
    can_ok( $data->catalog->[0], 'length' );
    if ( $data->catalog->[0]->can('length') ) {
        ok( $data->catalog->[0]->length, 'catalog / Test[0]: length' );
    }
    can_ok( $data->catalog->[0], 'photo' );
    if ( $data->catalog->[0]->can('photo') ) {
        ok( $data->catalog->[0]->photo, 'catalog / Test[0]: photo' );
    }
    can_ok( $data->catalog->[0], 'urls' );
    if ( $data->catalog->[0]->can('urls') ) {
        ok( $data->catalog->[0]->urls, 'catalog / Test[0]: urls' );
    }
    can_ok( $data->catalog->[0], 'desc' );
    if ( $data->catalog->[0]->can('desc') ) {
        ok( $data->catalog->[0]->desc, 'catalog / Test[0]: desc' );
    }
    can_ok( $data->catalog->[0]->brand, 'code' );
    if ( $data->catalog->[0]->brand->can('code') ) {
        ok( $data->catalog->[0]->brand->code, 'catalog / Test[0]: code' );
    }
    can_ok( $data->catalog->[0]->brand, 'name' );
    if ( $data->catalog->[0]->brand->can('name') ) {
        ok( $data->catalog->[0]->brand->name, 'catalog / Test[0]: name' );
    }
    can_ok( $data->catalog->[0]->body, 'code' );
    if ( $data->catalog->[0]->body->can('code') ) {
        ok( $data->catalog->[0]->body->code, 'catalog / Test[0]: code' );
    }
    can_ok( $data->catalog->[0]->body, 'name' );
    if ( $data->catalog->[0]->body->can('name') ) {
        ok( $data->catalog->[0]->body->name, 'catalog / Test[0]: name' );
    }
    can_ok( $data->catalog->[0]->photo, 'front' );
    if ( $data->catalog->[0]->photo->can('front') ) {
        ok( $data->catalog->[0]->photo->front, 'catalog / Test[0]: front' );
    }
    can_ok( $data->catalog->[0]->photo, 'inpane' );
    if ( $data->catalog->[0]->photo->can('inpane') ) {
        ok( $data->catalog->[0]->photo->inpane, 'catalog / Test[0]: inpane' );
    }
    can_ok( $data->catalog->[0]->urls, 'pc' );
    if ( $data->catalog->[0]->urls->can('pc') ) {
        ok( $data->catalog->[0]->urls->pc, 'catalog / Test[0]: pc' );
    }
    can_ok( $data->catalog->[0]->urls, 'mobile' );
    if ( $data->catalog->[0]->urls->can('mobile') ) {
        ok( $data->catalog->[0]->urls->mobile, 'catalog / Test[0]: mobile' );
    }
    can_ok( $data->catalog->[0]->urls, 'qr' );
    if ( $data->catalog->[0]->urls->can('qr') ) {
        ok( $data->catalog->[0]->urls->qr, 'catalog / Test[0]: qr' );
    }
    can_ok( $data->catalog->[0]->photo->front, 'caption' );
    if ( $data->catalog->[0]->photo->front->can('caption') ) {
        ok( $data->catalog->[0]->photo->front->caption, 'catalog / Test[0]: caption' );
    }
    can_ok( $data->catalog->[0]->photo->front, 'l' );
    if ( $data->catalog->[0]->photo->front->can('l') ) {
        ok( $data->catalog->[0]->photo->front->l, 'catalog / Test[0]: l' );
    }
    can_ok( $data->catalog->[0]->photo->front, 's' );
    if ( $data->catalog->[0]->photo->front->can('s') ) {
        ok( $data->catalog->[0]->photo->front->s, 'catalog / Test[0]: s' );
    }
    can_ok( $data->catalog->[0]->photo->inpane, 'caption' );
    if ( $data->catalog->[0]->photo->inpane->can('caption') ) {
        ok( $data->catalog->[0]->photo->inpane->caption, 'catalog / Test[0]: caption' );
    }
    can_ok( $data->catalog->[0]->photo->inpane, 'l' );
    if ( $data->catalog->[0]->photo->inpane->can('l') ) {
        ok( $data->catalog->[0]->photo->inpane->l, 'catalog / Test[0]: l' );
    }
    can_ok( $data->catalog->[0]->photo->inpane, 's' );
    if ( $data->catalog->[0]->photo->inpane->can('s') ) {
        ok( $data->catalog->[0]->photo->inpane->s, 'catalog / Test[0]: s' );
    }
}

# catalog / Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->catalog(%$params); };
    ok( ! $@, 'catalog / Test[1]: die' );
    ok( ! $res->is_error, 'catalog / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'catalog / Test[1]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'catalog / Test[1]: api_version' );
    }
    can_ok( $data, 'error' );
    if ( $data->can('error') ) {
        ok( $data->error, 'catalog / Test[1]: error' );
    }
    can_ok( $data->error, 'message' );
    if ( $data->error->can('message') ) {
        ok( $data->error->message, 'catalog / Test[1]: message' );
    }
}

# catalog / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->catalog(%$params); };
    ok( $@, 'catalog / Test[2]: die' );
}



# brand / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->brand(%$params); };
    ok( ! $@, 'brand / Test[0]: die' );
    ok( ! $res->is_error, 'brand / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'brand / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'brand / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'brand / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'brand / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'brand / Test[0]: results_start' );
    }
    can_ok( $data, 'brand' );
    if ( $data->can('brand') ) {
        ok( $data->brand, 'brand / Test[0]: brand' );
        ok( ref $data->brand eq 'ARRAY', 'brand / Test[0]: brand' );
    }
    can_ok( $data->brand->[0], 'code' );
    if ( $data->brand->[0]->can('code') ) {
        ok( $data->brand->[0]->code, 'brand / Test[0]: code' );
    }
    can_ok( $data->brand->[0], 'name' );
    if ( $data->brand->[0]->can('name') ) {
        ok( $data->brand->[0]->name, 'brand / Test[0]: name' );
    }
}

# brand / Test[1]
{
    my $params = {
        'country' => 'JPN',
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->brand(%$params); };
    ok( ! $@, 'brand / Test[1]: die' );
    ok( ! $res->is_error, 'brand / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'brand / Test[1]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'brand / Test[1]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'brand / Test[1]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'brand / Test[1]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'brand / Test[1]: results_start' );
    }
    can_ok( $data, 'brand' );
    if ( $data->can('brand') ) {
        ok( $data->brand, 'brand / Test[1]: brand' );
        ok( ref $data->brand eq 'ARRAY', 'brand / Test[1]: brand' );
    }
    can_ok( $data->brand->[0], 'code' );
    if ( $data->brand->[0]->can('code') ) {
        ok( $data->brand->[0]->code, 'brand / Test[1]: code' );
    }
    can_ok( $data->brand->[0], 'name' );
    if ( $data->brand->[0]->can('name') ) {
        ok( $data->brand->[0]->name, 'brand / Test[1]: name' );
    }
}

# brand / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->brand(%$params); };
    ok( $@, 'brand / Test[2]: die' );
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
}

# country / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->country(%$params); };
    ok( $@, 'country / Test[1]: die' );
}



# large_area / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->large_area(%$params); };
    ok( ! $@, 'large_area / Test[0]: die' );
    ok( ! $res->is_error, 'large_area / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'large_area / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'large_area / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'large_area / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'large_area / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'large_area / Test[0]: results_start' );
    }
    can_ok( $data, 'large_area' );
    if ( $data->can('large_area') ) {
        ok( $data->large_area, 'large_area / Test[0]: large_area' );
        ok( ref $data->large_area eq 'ARRAY', 'large_area / Test[0]: large_area' );
    }
    can_ok( $data->large_area->[0], 'code' );
    if ( $data->large_area->[0]->can('code') ) {
        ok( $data->large_area->[0]->code, 'large_area / Test[0]: code' );
    }
    can_ok( $data->large_area->[0], 'name' );
    if ( $data->large_area->[0]->can('name') ) {
        ok( $data->large_area->[0]->name, 'large_area / Test[0]: name' );
    }
}

# large_area / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->large_area(%$params); };
    ok( $@, 'large_area / Test[1]: die' );
}



# pref / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->pref(%$params); };
    ok( ! $@, 'pref / Test[0]: die' );
    ok( ! $res->is_error, 'pref / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'pref / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'pref / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'pref / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'pref / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'pref / Test[0]: results_start' );
    }
    can_ok( $data, 'pref' );
    if ( $data->can('pref') ) {
        ok( $data->pref, 'pref / Test[0]: pref' );
        ok( ref $data->pref eq 'ARRAY', 'pref / Test[0]: pref' );
    }
    can_ok( $data->pref->[0], 'code' );
    if ( $data->pref->[0]->can('code') ) {
        ok( $data->pref->[0]->code, 'pref / Test[0]: code' );
    }
    can_ok( $data->pref->[0], 'name' );
    if ( $data->pref->[0]->can('name') ) {
        ok( $data->pref->[0]->name, 'pref / Test[0]: name' );
    }
}

# pref / Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'large_area' => '1',
    };
    my $res = eval { $obj->pref(%$params); };
    ok( ! $@, 'pref / Test[1]: die' );
    ok( ! $res->is_error, 'pref / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'pref / Test[1]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'pref / Test[1]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'pref / Test[1]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'pref / Test[1]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'pref / Test[1]: results_start' );
    }
    can_ok( $data, 'pref' );
    if ( $data->can('pref') ) {
        ok( $data->pref, 'pref / Test[1]: pref' );
        ok( ref $data->pref eq 'ARRAY', 'pref / Test[1]: pref' );
    }
    can_ok( $data->pref->[0], 'code' );
    if ( $data->pref->[0]->can('code') ) {
        ok( $data->pref->[0]->code, 'pref / Test[1]: code' );
    }
    can_ok( $data->pref->[0], 'name' );
    if ( $data->pref->[0]->can('name') ) {
        ok( $data->pref->[0]->name, 'pref / Test[1]: name' );
    }
}

# pref / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->pref(%$params); };
    ok( $@, 'pref / Test[2]: die' );
}



# body / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->body(%$params); };
    ok( ! $@, 'body / Test[0]: die' );
    ok( ! $res->is_error, 'body / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'body / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'body / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'body / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'body / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'body / Test[0]: results_start' );
    }
    can_ok( $data, 'body' );
    if ( $data->can('body') ) {
        ok( $data->body, 'body / Test[0]: body' );
        ok( ref $data->body eq 'ARRAY', 'body / Test[0]: body' );
    }
    can_ok( $data->body->[0], 'code' );
    if ( $data->body->[0]->can('code') ) {
        ok( $data->body->[0]->code, 'body / Test[0]: code' );
    }
    can_ok( $data->body->[0], 'name' );
    if ( $data->body->[0]->can('name') ) {
        ok( $data->body->[0]->name, 'body / Test[0]: name' );
    }
}

# body / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->body(%$params); };
    ok( $@, 'body / Test[1]: die' );
}



# color / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->color(%$params); };
    ok( ! $@, 'color / Test[0]: die' );
    ok( ! $res->is_error, 'color / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'color / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'color / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'color / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'color / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'color / Test[0]: results_start' );
    }
    can_ok( $data, 'color' );
    if ( $data->can('color') ) {
        ok( $data->color, 'color / Test[0]: color' );
        ok( ref $data->color eq 'ARRAY', 'color / Test[0]: color' );
    }
    can_ok( $data->color->[0], 'code' );
    if ( $data->color->[0]->can('code') ) {
        ok( $data->color->[0]->code, 'color / Test[0]: code' );
    }
    can_ok( $data->color->[0], 'name' );
    if ( $data->color->[0]->can('name') ) {
        ok( $data->color->[0]->name, 'color / Test[0]: name' );
    }
}

# color / Test[1]
{
    my $params = {
    };
    my $res = eval { $obj->color(%$params); };
    ok( $@, 'color / Test[1]: die' );
}



1;
