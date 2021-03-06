#
# Test case for WebService::Recruit::CarSensor::LargeArea
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
plan tests => 21;

use_ok('WebService::Recruit::CarSensor::LargeArea');

my $service = new WebService::Recruit::CarSensor::LargeArea();

ok( ref $service, 'new WebService::Recruit::CarSensor::LargeArea()' );


# Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::CarSensor::LargeArea();
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
    can_ok( $data, 'large_area' );
    ok( eval { $data->large_area }, 'Test[0]: large_area' );
    ok( eval { ref $data->large_area } eq 'ARRAY', 'Test[0]: large_area' );
    can_ok( $data->large_area->[0], 'code' );
    ok( eval { $data->large_area->[0]->code }, 'Test[0]: code' );
    can_ok( $data->large_area->[0], 'name' );
    ok( eval { $data->large_area->[0]->name }, 'Test[0]: name' );
}

# Test[1]
{
    my $params = {
    };
    my $res = new WebService::Recruit::CarSensor::LargeArea();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[1]: die' );
}


1;
