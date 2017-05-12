#
# Test case for WebService::Recruit::Shingaku::License
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
plan tests => 54;

use_ok('WebService::Recruit::Shingaku::License');

my $service = new WebService::Recruit::Shingaku::License();

ok( ref $service, 'new WebService::Recruit::Shingaku::License()' );


# Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'keyword' => '数学',
    };
    my $res = new WebService::Recruit::Shingaku::License();
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
    can_ok( $data, 'license' );
    ok( eval { $data->license }, 'Test[0]: license' );
    ok( eval { ref $data->license } eq 'ARRAY', 'Test[0]: license' );
    can_ok( $data->license->[0], 'code' );
    ok( eval { $data->license->[0]->code }, 'Test[0]: code' );
    can_ok( $data->license->[0], 'name' );
    ok( eval { $data->license->[0]->name }, 'Test[0]: name' );
    can_ok( $data->license->[0], 'desc' );
    ok( eval { $data->license->[0]->desc }, 'Test[0]: desc' );
    can_ok( $data->license->[0], 'subject' );
    ok( eval { $data->license->[0]->subject }, 'Test[0]: subject' );
    ok( eval { ref $data->license->[0]->subject } eq 'ARRAY', 'Test[0]: subject' );
    can_ok( $data->license->[0], 'work' );
    ok( eval { $data->license->[0]->work }, 'Test[0]: work' );
    ok( eval { ref $data->license->[0]->work } eq 'ARRAY', 'Test[0]: work' );
    can_ok( $data->license->[0], 'urls' );
    ok( eval { $data->license->[0]->urls }, 'Test[0]: urls' );
    can_ok( $data->license->[0]->subject->[0], 'code' );
    ok( eval { $data->license->[0]->subject->[0]->code }, 'Test[0]: code' );
    can_ok( $data->license->[0]->subject->[0], 'name' );
    ok( eval { $data->license->[0]->subject->[0]->name }, 'Test[0]: name' );
    can_ok( $data->license->[0]->work->[0], 'code' );
    ok( eval { $data->license->[0]->work->[0]->code }, 'Test[0]: code' );
    can_ok( $data->license->[0]->work->[0], 'name' );
    ok( eval { $data->license->[0]->work->[0]->name }, 'Test[0]: name' );
    can_ok( $data->license->[0]->urls, 'mobile' );
    ok( eval { $data->license->[0]->urls->mobile }, 'Test[0]: mobile' );
    can_ok( $data->license->[0]->urls, 'pc' );
    ok( eval { $data->license->[0]->urls->pc }, 'Test[0]: pc' );
    can_ok( $data->license->[0]->urls, 'qr' );
    ok( eval { $data->license->[0]->urls->qr }, 'Test[0]: qr' );
}

# Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::Shingaku::License();
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
    my $res = new WebService::Recruit::Shingaku::License();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[2]: die' );
}


1;
