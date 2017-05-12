#
# Test case for WebService::Recruit::CarSensor::Usedcar
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
plan tests => 89;

use_ok('WebService::Recruit::CarSensor::Usedcar');

my $service = new WebService::Recruit::CarSensor::Usedcar();

ok( ref $service, 'new WebService::Recruit::CarSensor::Usedcar()' );


# Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'pref' => '13',
    };
    my $res = new WebService::Recruit::CarSensor::Usedcar();
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
    can_ok( $data, 'usedcar' );
    ok( eval { $data->usedcar }, 'Test[0]: usedcar' );
    ok( eval { ref $data->usedcar } eq 'ARRAY', 'Test[0]: usedcar' );
    can_ok( $data->usedcar->[0], 'id' );
    ok( eval { $data->usedcar->[0]->id }, 'Test[0]: id' );
    can_ok( $data->usedcar->[0], 'brand' );
    ok( eval { $data->usedcar->[0]->brand }, 'Test[0]: brand' );
    can_ok( $data->usedcar->[0], 'model' );
    ok( eval { $data->usedcar->[0]->model }, 'Test[0]: model' );
    can_ok( $data->usedcar->[0], 'grade' );
    ok( eval { $data->usedcar->[0]->grade }, 'Test[0]: grade' );
    can_ok( $data->usedcar->[0], 'price' );
    ok( eval { $data->usedcar->[0]->price }, 'Test[0]: price' );
    can_ok( $data->usedcar->[0], 'desc' );
    ok( eval { $data->usedcar->[0]->desc }, 'Test[0]: desc' );
    can_ok( $data->usedcar->[0], 'body' );
    ok( eval { $data->usedcar->[0]->body }, 'Test[0]: body' );
    can_ok( $data->usedcar->[0], 'odd' );
    ok( eval { $data->usedcar->[0]->odd }, 'Test[0]: odd' );
    can_ok( $data->usedcar->[0], 'year' );
    ok( eval { $data->usedcar->[0]->year }, 'Test[0]: year' );
    can_ok( $data->usedcar->[0], 'shop' );
    ok( eval { $data->usedcar->[0]->shop }, 'Test[0]: shop' );
    can_ok( $data->usedcar->[0], 'color' );
    ok( eval { $data->usedcar->[0]->color }, 'Test[0]: color' );
    can_ok( $data->usedcar->[0], 'photo' );
    ok( eval { $data->usedcar->[0]->photo }, 'Test[0]: photo' );
    can_ok( $data->usedcar->[0], 'urls' );
    ok( eval { $data->usedcar->[0]->urls }, 'Test[0]: urls' );
    can_ok( $data->usedcar->[0]->brand, 'code' );
    ok( eval { $data->usedcar->[0]->brand->code }, 'Test[0]: code' );
    can_ok( $data->usedcar->[0]->brand, 'name' );
    ok( eval { $data->usedcar->[0]->brand->name }, 'Test[0]: name' );
    can_ok( $data->usedcar->[0]->body, 'code' );
    ok( eval { $data->usedcar->[0]->body->code }, 'Test[0]: code' );
    can_ok( $data->usedcar->[0]->body, 'name' );
    ok( eval { $data->usedcar->[0]->body->name }, 'Test[0]: name' );
    can_ok( $data->usedcar->[0]->shop, 'name' );
    ok( eval { $data->usedcar->[0]->shop->name }, 'Test[0]: name' );
    can_ok( $data->usedcar->[0]->shop, 'pref' );
    ok( eval { $data->usedcar->[0]->shop->pref }, 'Test[0]: pref' );
    can_ok( $data->usedcar->[0]->shop, 'lat' );
    ok( eval { $data->usedcar->[0]->shop->lat }, 'Test[0]: lat' );
    can_ok( $data->usedcar->[0]->shop, 'lng' );
    ok( eval { $data->usedcar->[0]->shop->lng }, 'Test[0]: lng' );
    can_ok( $data->usedcar->[0]->shop, 'datum' );
    ok( eval { $data->usedcar->[0]->shop->datum }, 'Test[0]: datum' );
    can_ok( $data->usedcar->[0]->photo, 'main' );
    ok( eval { $data->usedcar->[0]->photo->main }, 'Test[0]: main' );
    can_ok( $data->usedcar->[0]->photo, 'sub' );
    ok( eval { $data->usedcar->[0]->photo->sub }, 'Test[0]: sub' );
    ok( eval { ref $data->usedcar->[0]->photo->sub } eq 'ARRAY', 'Test[0]: sub' );
    can_ok( $data->usedcar->[0]->urls, 'pc' );
    ok( eval { $data->usedcar->[0]->urls->pc }, 'Test[0]: pc' );
    can_ok( $data->usedcar->[0]->urls, 'mobile' );
    ok( eval { $data->usedcar->[0]->urls->mobile }, 'Test[0]: mobile' );
    can_ok( $data->usedcar->[0]->urls, 'qr' );
    ok( eval { $data->usedcar->[0]->urls->qr }, 'Test[0]: qr' );
    can_ok( $data->usedcar->[0]->shop->pref, 'code' );
    ok( eval { $data->usedcar->[0]->shop->pref->code }, 'Test[0]: code' );
    can_ok( $data->usedcar->[0]->shop->pref, 'name' );
    ok( eval { $data->usedcar->[0]->shop->pref->name }, 'Test[0]: name' );
    can_ok( $data->usedcar->[0]->photo->main, 'l' );
    ok( eval { $data->usedcar->[0]->photo->main->l }, 'Test[0]: l' );
    can_ok( $data->usedcar->[0]->photo->main, 's' );
    ok( eval { $data->usedcar->[0]->photo->main->s }, 'Test[0]: s' );
}

# Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::CarSensor::Usedcar();
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
    my $res = new WebService::Recruit::CarSensor::Usedcar();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[2]: die' );
}


1;
