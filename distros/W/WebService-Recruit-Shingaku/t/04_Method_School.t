#
# Test case for WebService::Recruit::Shingaku::School
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
plan tests => 74;

use_ok('WebService::Recruit::Shingaku::School');

my $service = new WebService::Recruit::Shingaku::School();

ok( ref $service, 'new WebService::Recruit::Shingaku::School()' );


# Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'keyword' => '数学',
        'pref_cd' => '12',
    };
    my $res = new WebService::Recruit::Shingaku::School();
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
    can_ok( $data, 'school' );
    ok( eval { $data->school }, 'Test[0]: school' );
    ok( eval { ref $data->school } eq 'ARRAY', 'Test[0]: school' );
    can_ok( $data->school->[0], 'code' );
    ok( eval { $data->school->[0]->code }, 'Test[0]: code' );
    can_ok( $data->school->[0], 'name' );
    ok( eval { $data->school->[0]->name }, 'Test[0]: name' );
    can_ok( $data->school->[0], 'kana' );
    ok( eval { $data->school->[0]->kana }, 'Test[0]: kana' );
    can_ok( $data->school->[0], 'campus' );
    ok( eval { $data->school->[0]->campus }, 'Test[0]: campus' );
    ok( eval { ref $data->school->[0]->campus } eq 'ARRAY', 'Test[0]: campus' );
    can_ok( $data->school->[0], 'category' );
    ok( eval { $data->school->[0]->category }, 'Test[0]: category' );
    can_ok( $data->school->[0], 'faculty' );
    ok( eval { $data->school->[0]->faculty }, 'Test[0]: faculty' );
    ok( eval { ref $data->school->[0]->faculty } eq 'ARRAY', 'Test[0]: faculty' );
    can_ok( $data->school->[0], 'pref' );
    ok( eval { $data->school->[0]->pref }, 'Test[0]: pref' );
    can_ok( $data->school->[0], 'urls' );
    ok( eval { $data->school->[0]->urls }, 'Test[0]: urls' );
    can_ok( $data->school->[0]->campus->[0], 'name' );
    ok( eval { $data->school->[0]->campus->[0]->name }, 'Test[0]: name' );
    can_ok( $data->school->[0]->campus->[0], 'address' );
    ok( eval { $data->school->[0]->campus->[0]->address }, 'Test[0]: address' );
    can_ok( $data->school->[0]->campus->[0], 'datum' );
    ok( eval { $data->school->[0]->campus->[0]->datum }, 'Test[0]: datum' );
    can_ok( $data->school->[0]->campus->[0], 'latitude' );
    ok( eval { $data->school->[0]->campus->[0]->latitude }, 'Test[0]: latitude' );
    can_ok( $data->school->[0]->campus->[0], 'longitude' );
    ok( eval { $data->school->[0]->campus->[0]->longitude }, 'Test[0]: longitude' );
    can_ok( $data->school->[0]->campus->[0], 'station' );
    ok( eval { $data->school->[0]->campus->[0]->station }, 'Test[0]: station' );
    can_ok( $data->school->[0]->category, 'code' );
    ok( eval { $data->school->[0]->category->code }, 'Test[0]: code' );
    can_ok( $data->school->[0]->category, 'name' );
    ok( eval { $data->school->[0]->category->name }, 'Test[0]: name' );
    can_ok( $data->school->[0]->faculty->[0], 'name' );
    ok( eval { $data->school->[0]->faculty->[0]->name }, 'Test[0]: name' );
    can_ok( $data->school->[0]->faculty->[0], 'department' );
    ok( eval { $data->school->[0]->faculty->[0]->department }, 'Test[0]: department' );
    can_ok( $data->school->[0]->pref, 'code' );
    ok( eval { $data->school->[0]->pref->code }, 'Test[0]: code' );
    can_ok( $data->school->[0]->pref, 'name' );
    ok( eval { $data->school->[0]->pref->name }, 'Test[0]: name' );
    can_ok( $data->school->[0]->urls, 'mobile' );
    ok( eval { $data->school->[0]->urls->mobile }, 'Test[0]: mobile' );
    can_ok( $data->school->[0]->urls, 'pc' );
    ok( eval { $data->school->[0]->urls->pc }, 'Test[0]: pc' );
    can_ok( $data->school->[0]->urls, 'qr' );
    ok( eval { $data->school->[0]->urls->qr }, 'Test[0]: qr' );
}

# Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = new WebService::Recruit::Shingaku::School();
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
    my $res = new WebService::Recruit::Shingaku::School();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[2]: die' );
}


1;
