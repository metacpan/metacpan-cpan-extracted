#
# Test case for WebService::Recruit::CarSensor::Pref
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
plan tests => 39;

use_ok('WebService::Recruit::CarSensor::Pref');

my $service = new WebService::Recruit::CarSensor::Pref();

ok( ref $service, 'new WebService::Recruit::CarSensor::Pref()' );


# Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::CarSensor::Pref();
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
    can_ok( $data, 'pref' );
    ok( eval { $data->pref }, 'Test[0]: pref' );
    ok( eval { ref $data->pref } eq 'ARRAY', 'Test[0]: pref' );
    can_ok( $data->pref->[0], 'code' );
    ok( eval { $data->pref->[0]->code }, 'Test[0]: code' );
    can_ok( $data->pref->[0], 'name' );
    ok( eval { $data->pref->[0]->name }, 'Test[0]: name' );
}

# Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'large_area' => '1',
    };
    my $res = new WebService::Recruit::CarSensor::Pref();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( ! $@, 'Test[1]: die' );
    ok( ! $res->is_error, 'Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'Test[1]: root' );
    can_ok( $data, 'api_version' );
    ok( eval { $data->api_version }, 'Test[1]: api_version' );
    can_ok( $data, 'results_available' );
    ok( eval { $data->results_available }, 'Test[1]: results_available' );
    can_ok( $data, 'results_returned' );
    ok( eval { $data->results_returned }, 'Test[1]: results_returned' );
    can_ok( $data, 'results_start' );
    ok( eval { $data->results_start }, 'Test[1]: results_start' );
    can_ok( $data, 'pref' );
    ok( eval { $data->pref }, 'Test[1]: pref' );
    ok( eval { ref $data->pref } eq 'ARRAY', 'Test[1]: pref' );
    can_ok( $data->pref->[0], 'code' );
    ok( eval { $data->pref->[0]->code }, 'Test[1]: code' );
    can_ok( $data->pref->[0], 'name' );
    ok( eval { $data->pref->[0]->name }, 'Test[1]: name' );
}

# Test[2]
{
    my $params = {
    };
    my $res = new WebService::Recruit::CarSensor::Pref();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[2]: die' );
}


1;
