#
# Test case for WebService::Recruit::CarSensor::Catalog
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
plan tests => 84;

use_ok('WebService::Recruit::CarSensor::Catalog');

my $service = new WebService::Recruit::CarSensor::Catalog();

ok( ref $service, 'new WebService::Recruit::CarSensor::Catalog()' );


# Test[0]
{
    my $params = {
        'country' => 'JPN',
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::CarSensor::Catalog();
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
    can_ok( $data, 'catalog' );
    ok( eval { $data->catalog }, 'Test[0]: catalog' );
    ok( eval { ref $data->catalog } eq 'ARRAY', 'Test[0]: catalog' );
    can_ok( $data->catalog->[0], 'brand' );
    ok( eval { $data->catalog->[0]->brand }, 'Test[0]: brand' );
    can_ok( $data->catalog->[0], 'model' );
    ok( eval { $data->catalog->[0]->model }, 'Test[0]: model' );
    can_ok( $data->catalog->[0], 'grade' );
    ok( eval { $data->catalog->[0]->grade }, 'Test[0]: grade' );
    can_ok( $data->catalog->[0], 'price' );
    ok( eval { $data->catalog->[0]->price }, 'Test[0]: price' );
    can_ok( $data->catalog->[0], 'body' );
    ok( eval { $data->catalog->[0]->body }, 'Test[0]: body' );
    can_ok( $data->catalog->[0], 'person' );
    ok( eval { $data->catalog->[0]->person }, 'Test[0]: person' );
    can_ok( $data->catalog->[0], 'period' );
    ok( eval { $data->catalog->[0]->period }, 'Test[0]: period' );
    can_ok( $data->catalog->[0], 'series' );
    ok( eval { $data->catalog->[0]->series }, 'Test[0]: series' );
    can_ok( $data->catalog->[0], 'width' );
    ok( eval { $data->catalog->[0]->width }, 'Test[0]: width' );
    can_ok( $data->catalog->[0], 'height' );
    ok( eval { $data->catalog->[0]->height }, 'Test[0]: height' );
    can_ok( $data->catalog->[0], 'length' );
    ok( eval { $data->catalog->[0]->length }, 'Test[0]: length' );
    can_ok( $data->catalog->[0], 'photo' );
    ok( eval { $data->catalog->[0]->photo }, 'Test[0]: photo' );
    can_ok( $data->catalog->[0], 'urls' );
    ok( eval { $data->catalog->[0]->urls }, 'Test[0]: urls' );
    can_ok( $data->catalog->[0], 'desc' );
    ok( eval { $data->catalog->[0]->desc }, 'Test[0]: desc' );
    can_ok( $data->catalog->[0]->brand, 'code' );
    ok( eval { $data->catalog->[0]->brand->code }, 'Test[0]: code' );
    can_ok( $data->catalog->[0]->brand, 'name' );
    ok( eval { $data->catalog->[0]->brand->name }, 'Test[0]: name' );
    can_ok( $data->catalog->[0]->body, 'code' );
    ok( eval { $data->catalog->[0]->body->code }, 'Test[0]: code' );
    can_ok( $data->catalog->[0]->body, 'name' );
    ok( eval { $data->catalog->[0]->body->name }, 'Test[0]: name' );
    can_ok( $data->catalog->[0]->photo, 'front' );
    ok( eval { $data->catalog->[0]->photo->front }, 'Test[0]: front' );
    can_ok( $data->catalog->[0]->photo, 'inpane' );
    ok( eval { $data->catalog->[0]->photo->inpane }, 'Test[0]: inpane' );
    can_ok( $data->catalog->[0]->urls, 'pc' );
    ok( eval { $data->catalog->[0]->urls->pc }, 'Test[0]: pc' );
    can_ok( $data->catalog->[0]->urls, 'mobile' );
    ok( eval { $data->catalog->[0]->urls->mobile }, 'Test[0]: mobile' );
    can_ok( $data->catalog->[0]->urls, 'qr' );
    ok( eval { $data->catalog->[0]->urls->qr }, 'Test[0]: qr' );
    can_ok( $data->catalog->[0]->photo->front, 'caption' );
    ok( eval { $data->catalog->[0]->photo->front->caption }, 'Test[0]: caption' );
    can_ok( $data->catalog->[0]->photo->front, 'l' );
    ok( eval { $data->catalog->[0]->photo->front->l }, 'Test[0]: l' );
    can_ok( $data->catalog->[0]->photo->front, 's' );
    ok( eval { $data->catalog->[0]->photo->front->s }, 'Test[0]: s' );
    can_ok( $data->catalog->[0]->photo->inpane, 'caption' );
    ok( eval { $data->catalog->[0]->photo->inpane->caption }, 'Test[0]: caption' );
    can_ok( $data->catalog->[0]->photo->inpane, 'l' );
    ok( eval { $data->catalog->[0]->photo->inpane->l }, 'Test[0]: l' );
    can_ok( $data->catalog->[0]->photo->inpane, 's' );
    ok( eval { $data->catalog->[0]->photo->inpane->s }, 'Test[0]: s' );
}

# Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::CarSensor::Catalog();
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
    my $res = new WebService::Recruit::CarSensor::Catalog();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[2]: die' );
}


1;
