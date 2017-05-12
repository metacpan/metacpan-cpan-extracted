#
# Test case for WebService::Recruit::Shingaku
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
plan tests => 268;

use_ok('WebService::Recruit::Shingaku');

my $obj = WebService::Recruit::Shingaku->new();

ok(ref $obj, 'new WebService::Recruit::Shingaku()');


# school / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'keyword' => '数学',
        'pref_cd' => '12',
    };
    my $res = eval { $obj->school(%$params); };
    ok( ! $@, 'school / Test[0]: die' );
    ok( ! $res->is_error, 'school / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'school / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'school / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'school / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'school / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'school / Test[0]: results_start' );
    }
    can_ok( $data, 'school' );
    if ( $data->can('school') ) {
        ok( $data->school, 'school / Test[0]: school' );
        ok( ref $data->school eq 'ARRAY', 'school / Test[0]: school' );
    }
    can_ok( $data->school->[0], 'code' );
    if ( $data->school->[0]->can('code') ) {
        ok( $data->school->[0]->code, 'school / Test[0]: code' );
    }
    can_ok( $data->school->[0], 'name' );
    if ( $data->school->[0]->can('name') ) {
        ok( $data->school->[0]->name, 'school / Test[0]: name' );
    }
    can_ok( $data->school->[0], 'kana' );
    if ( $data->school->[0]->can('kana') ) {
        ok( $data->school->[0]->kana, 'school / Test[0]: kana' );
    }
    can_ok( $data->school->[0], 'campus' );
    if ( $data->school->[0]->can('campus') ) {
        ok( $data->school->[0]->campus, 'school / Test[0]: campus' );
        ok( ref $data->school->[0]->campus eq 'ARRAY', 'school / Test[0]: campus' );
    }
    can_ok( $data->school->[0], 'category' );
    if ( $data->school->[0]->can('category') ) {
        ok( $data->school->[0]->category, 'school / Test[0]: category' );
    }
    can_ok( $data->school->[0], 'faculty' );
    if ( $data->school->[0]->can('faculty') ) {
        ok( $data->school->[0]->faculty, 'school / Test[0]: faculty' );
        ok( ref $data->school->[0]->faculty eq 'ARRAY', 'school / Test[0]: faculty' );
    }
    can_ok( $data->school->[0], 'pref' );
    if ( $data->school->[0]->can('pref') ) {
        ok( $data->school->[0]->pref, 'school / Test[0]: pref' );
    }
    can_ok( $data->school->[0], 'urls' );
    if ( $data->school->[0]->can('urls') ) {
        ok( $data->school->[0]->urls, 'school / Test[0]: urls' );
    }
    can_ok( $data->school->[0]->campus->[0], 'name' );
    if ( $data->school->[0]->campus->[0]->can('name') ) {
        ok( $data->school->[0]->campus->[0]->name, 'school / Test[0]: name' );
    }
    can_ok( $data->school->[0]->campus->[0], 'address' );
    if ( $data->school->[0]->campus->[0]->can('address') ) {
        ok( $data->school->[0]->campus->[0]->address, 'school / Test[0]: address' );
    }
    can_ok( $data->school->[0]->campus->[0], 'datum' );
    if ( $data->school->[0]->campus->[0]->can('datum') ) {
        ok( $data->school->[0]->campus->[0]->datum, 'school / Test[0]: datum' );
    }
    can_ok( $data->school->[0]->campus->[0], 'latitude' );
    if ( $data->school->[0]->campus->[0]->can('latitude') ) {
        ok( $data->school->[0]->campus->[0]->latitude, 'school / Test[0]: latitude' );
    }
    can_ok( $data->school->[0]->campus->[0], 'longitude' );
    if ( $data->school->[0]->campus->[0]->can('longitude') ) {
        ok( $data->school->[0]->campus->[0]->longitude, 'school / Test[0]: longitude' );
    }
    can_ok( $data->school->[0]->campus->[0], 'station' );
    if ( $data->school->[0]->campus->[0]->can('station') ) {
        ok( $data->school->[0]->campus->[0]->station, 'school / Test[0]: station' );
    }
    can_ok( $data->school->[0]->category, 'code' );
    if ( $data->school->[0]->category->can('code') ) {
        ok( $data->school->[0]->category->code, 'school / Test[0]: code' );
    }
    can_ok( $data->school->[0]->category, 'name' );
    if ( $data->school->[0]->category->can('name') ) {
        ok( $data->school->[0]->category->name, 'school / Test[0]: name' );
    }
    can_ok( $data->school->[0]->faculty->[0], 'name' );
    if ( $data->school->[0]->faculty->[0]->can('name') ) {
        ok( $data->school->[0]->faculty->[0]->name, 'school / Test[0]: name' );
    }
    can_ok( $data->school->[0]->faculty->[0], 'department' );
    if ( $data->school->[0]->faculty->[0]->can('department') ) {
        ok( $data->school->[0]->faculty->[0]->department, 'school / Test[0]: department' );
    }
    can_ok( $data->school->[0]->pref, 'code' );
    if ( $data->school->[0]->pref->can('code') ) {
        ok( $data->school->[0]->pref->code, 'school / Test[0]: code' );
    }
    can_ok( $data->school->[0]->pref, 'name' );
    if ( $data->school->[0]->pref->can('name') ) {
        ok( $data->school->[0]->pref->name, 'school / Test[0]: name' );
    }
    can_ok( $data->school->[0]->urls, 'mobile' );
    if ( $data->school->[0]->urls->can('mobile') ) {
        ok( $data->school->[0]->urls->mobile, 'school / Test[0]: mobile' );
    }
    can_ok( $data->school->[0]->urls, 'pc' );
    if ( $data->school->[0]->urls->can('pc') ) {
        ok( $data->school->[0]->urls->pc, 'school / Test[0]: pc' );
    }
    can_ok( $data->school->[0]->urls, 'qr' );
    if ( $data->school->[0]->urls->can('qr') ) {
        ok( $data->school->[0]->urls->qr, 'school / Test[0]: qr' );
    }
}

# school / Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->school(%$params); };
    ok( ! $@, 'school / Test[1]: die' );
    ok( ! $res->is_error, 'school / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'school / Test[1]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'school / Test[1]: api_version' );
    }
    can_ok( $data, 'error' );
    if ( $data->can('error') ) {
        ok( $data->error, 'school / Test[1]: error' );
    }
    can_ok( $data->error, 'message' );
    if ( $data->error->can('message') ) {
        ok( $data->error->message, 'school / Test[1]: message' );
    }
}

# school / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->school(%$params); };
    ok( $@, 'school / Test[2]: die' );
}



# subject / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'keyword' => '数学',
    };
    my $res = eval { $obj->subject(%$params); };
    ok( ! $@, 'subject / Test[0]: die' );
    ok( ! $res->is_error, 'subject / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'subject / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'subject / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'subject / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'subject / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'subject / Test[0]: results_start' );
    }
    can_ok( $data, 'subject' );
    if ( $data->can('subject') ) {
        ok( $data->subject, 'subject / Test[0]: subject' );
        ok( ref $data->subject eq 'ARRAY', 'subject / Test[0]: subject' );
    }
    can_ok( $data->subject->[0], 'code' );
    if ( $data->subject->[0]->can('code') ) {
        ok( $data->subject->[0]->code, 'subject / Test[0]: code' );
    }
    can_ok( $data->subject->[0], 'name' );
    if ( $data->subject->[0]->can('name') ) {
        ok( $data->subject->[0]->name, 'subject / Test[0]: name' );
    }
    can_ok( $data->subject->[0], 'desc' );
    if ( $data->subject->[0]->can('desc') ) {
        ok( $data->subject->[0]->desc, 'subject / Test[0]: desc' );
    }
    can_ok( $data->subject->[0], 'license' );
    if ( $data->subject->[0]->can('license') ) {
        ok( $data->subject->[0]->license, 'subject / Test[0]: license' );
        ok( ref $data->subject->[0]->license eq 'ARRAY', 'subject / Test[0]: license' );
    }
    can_ok( $data->subject->[0], 'work' );
    if ( $data->subject->[0]->can('work') ) {
        ok( $data->subject->[0]->work, 'subject / Test[0]: work' );
        ok( ref $data->subject->[0]->work eq 'ARRAY', 'subject / Test[0]: work' );
    }
    can_ok( $data->subject->[0], 'urls' );
    if ( $data->subject->[0]->can('urls') ) {
        ok( $data->subject->[0]->urls, 'subject / Test[0]: urls' );
    }
    can_ok( $data->subject->[0]->license->[0], 'code' );
    if ( $data->subject->[0]->license->[0]->can('code') ) {
        ok( $data->subject->[0]->license->[0]->code, 'subject / Test[0]: code' );
    }
    can_ok( $data->subject->[0]->license->[0], 'name' );
    if ( $data->subject->[0]->license->[0]->can('name') ) {
        ok( $data->subject->[0]->license->[0]->name, 'subject / Test[0]: name' );
    }
    can_ok( $data->subject->[0]->work->[0], 'code' );
    if ( $data->subject->[0]->work->[0]->can('code') ) {
        ok( $data->subject->[0]->work->[0]->code, 'subject / Test[0]: code' );
    }
    can_ok( $data->subject->[0]->work->[0], 'name' );
    if ( $data->subject->[0]->work->[0]->can('name') ) {
        ok( $data->subject->[0]->work->[0]->name, 'subject / Test[0]: name' );
    }
    can_ok( $data->subject->[0]->urls, 'mobile' );
    if ( $data->subject->[0]->urls->can('mobile') ) {
        ok( $data->subject->[0]->urls->mobile, 'subject / Test[0]: mobile' );
    }
    can_ok( $data->subject->[0]->urls, 'pc' );
    if ( $data->subject->[0]->urls->can('pc') ) {
        ok( $data->subject->[0]->urls->pc, 'subject / Test[0]: pc' );
    }
    can_ok( $data->subject->[0]->urls, 'qr' );
    if ( $data->subject->[0]->urls->can('qr') ) {
        ok( $data->subject->[0]->urls->qr, 'subject / Test[0]: qr' );
    }
}

# subject / Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->subject(%$params); };
    ok( ! $@, 'subject / Test[1]: die' );
    ok( ! $res->is_error, 'subject / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'subject / Test[1]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'subject / Test[1]: api_version' );
    }
    can_ok( $data, 'error' );
    if ( $data->can('error') ) {
        ok( $data->error, 'subject / Test[1]: error' );
    }
    can_ok( $data->error, 'message' );
    if ( $data->error->can('message') ) {
        ok( $data->error->message, 'subject / Test[1]: message' );
    }
}

# subject / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->subject(%$params); };
    ok( $@, 'subject / Test[2]: die' );
}



# work / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'keyword' => '財務',
    };
    my $res = eval { $obj->work(%$params); };
    ok( ! $@, 'work / Test[0]: die' );
    ok( ! $res->is_error, 'work / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'work / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'work / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'work / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'work / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'work / Test[0]: results_start' );
    }
    can_ok( $data, 'work' );
    if ( $data->can('work') ) {
        ok( $data->work, 'work / Test[0]: work' );
        ok( ref $data->work eq 'ARRAY', 'work / Test[0]: work' );
    }
    can_ok( $data->work->[0], 'code' );
    if ( $data->work->[0]->can('code') ) {
        ok( $data->work->[0]->code, 'work / Test[0]: code' );
    }
    can_ok( $data->work->[0], 'name' );
    if ( $data->work->[0]->can('name') ) {
        ok( $data->work->[0]->name, 'work / Test[0]: name' );
    }
    can_ok( $data->work->[0], 'desc' );
    if ( $data->work->[0]->can('desc') ) {
        ok( $data->work->[0]->desc, 'work / Test[0]: desc' );
    }
    can_ok( $data->work->[0], 'license' );
    if ( $data->work->[0]->can('license') ) {
        ok( $data->work->[0]->license, 'work / Test[0]: license' );
        ok( ref $data->work->[0]->license eq 'ARRAY', 'work / Test[0]: license' );
    }
    can_ok( $data->work->[0], 'subject' );
    if ( $data->work->[0]->can('subject') ) {
        ok( $data->work->[0]->subject, 'work / Test[0]: subject' );
        ok( ref $data->work->[0]->subject eq 'ARRAY', 'work / Test[0]: subject' );
    }
    can_ok( $data->work->[0], 'urls' );
    if ( $data->work->[0]->can('urls') ) {
        ok( $data->work->[0]->urls, 'work / Test[0]: urls' );
    }
    can_ok( $data->work->[0]->license->[0], 'code' );
    if ( $data->work->[0]->license->[0]->can('code') ) {
        ok( $data->work->[0]->license->[0]->code, 'work / Test[0]: code' );
    }
    can_ok( $data->work->[0]->license->[0], 'name' );
    if ( $data->work->[0]->license->[0]->can('name') ) {
        ok( $data->work->[0]->license->[0]->name, 'work / Test[0]: name' );
    }
    can_ok( $data->work->[0]->subject->[0], 'code' );
    if ( $data->work->[0]->subject->[0]->can('code') ) {
        ok( $data->work->[0]->subject->[0]->code, 'work / Test[0]: code' );
    }
    can_ok( $data->work->[0]->subject->[0], 'name' );
    if ( $data->work->[0]->subject->[0]->can('name') ) {
        ok( $data->work->[0]->subject->[0]->name, 'work / Test[0]: name' );
    }
    can_ok( $data->work->[0]->urls, 'mobile' );
    if ( $data->work->[0]->urls->can('mobile') ) {
        ok( $data->work->[0]->urls->mobile, 'work / Test[0]: mobile' );
    }
    can_ok( $data->work->[0]->urls, 'pc' );
    if ( $data->work->[0]->urls->can('pc') ) {
        ok( $data->work->[0]->urls->pc, 'work / Test[0]: pc' );
    }
    can_ok( $data->work->[0]->urls, 'qr' );
    if ( $data->work->[0]->urls->can('qr') ) {
        ok( $data->work->[0]->urls->qr, 'work / Test[0]: qr' );
    }
}

# work / Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->work(%$params); };
    ok( ! $@, 'work / Test[1]: die' );
    ok( ! $res->is_error, 'work / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'work / Test[1]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'work / Test[1]: api_version' );
    }
    can_ok( $data, 'error' );
    if ( $data->can('error') ) {
        ok( $data->error, 'work / Test[1]: error' );
    }
    can_ok( $data->error, 'message' );
    if ( $data->error->can('message') ) {
        ok( $data->error->message, 'work / Test[1]: message' );
    }
}

# work / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->work(%$params); };
    ok( $@, 'work / Test[2]: die' );
}



# license / Test[0]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'keyword' => '数学',
    };
    my $res = eval { $obj->license(%$params); };
    ok( ! $@, 'license / Test[0]: die' );
    ok( ! $res->is_error, 'license / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'license / Test[0]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'license / Test[0]: api_version' );
    }
    can_ok( $data, 'results_available' );
    if ( $data->can('results_available') ) {
        ok( $data->results_available, 'license / Test[0]: results_available' );
    }
    can_ok( $data, 'results_returned' );
    if ( $data->can('results_returned') ) {
        ok( $data->results_returned, 'license / Test[0]: results_returned' );
    }
    can_ok( $data, 'results_start' );
    if ( $data->can('results_start') ) {
        ok( $data->results_start, 'license / Test[0]: results_start' );
    }
    can_ok( $data, 'license' );
    if ( $data->can('license') ) {
        ok( $data->license, 'license / Test[0]: license' );
        ok( ref $data->license eq 'ARRAY', 'license / Test[0]: license' );
    }
    can_ok( $data->license->[0], 'code' );
    if ( $data->license->[0]->can('code') ) {
        ok( $data->license->[0]->code, 'license / Test[0]: code' );
    }
    can_ok( $data->license->[0], 'name' );
    if ( $data->license->[0]->can('name') ) {
        ok( $data->license->[0]->name, 'license / Test[0]: name' );
    }
    can_ok( $data->license->[0], 'desc' );
    if ( $data->license->[0]->can('desc') ) {
        ok( $data->license->[0]->desc, 'license / Test[0]: desc' );
    }
    can_ok( $data->license->[0], 'subject' );
    if ( $data->license->[0]->can('subject') ) {
        ok( $data->license->[0]->subject, 'license / Test[0]: subject' );
        ok( ref $data->license->[0]->subject eq 'ARRAY', 'license / Test[0]: subject' );
    }
    can_ok( $data->license->[0], 'work' );
    if ( $data->license->[0]->can('work') ) {
        ok( $data->license->[0]->work, 'license / Test[0]: work' );
        ok( ref $data->license->[0]->work eq 'ARRAY', 'license / Test[0]: work' );
    }
    can_ok( $data->license->[0], 'urls' );
    if ( $data->license->[0]->can('urls') ) {
        ok( $data->license->[0]->urls, 'license / Test[0]: urls' );
    }
    can_ok( $data->license->[0]->subject->[0], 'code' );
    if ( $data->license->[0]->subject->[0]->can('code') ) {
        ok( $data->license->[0]->subject->[0]->code, 'license / Test[0]: code' );
    }
    can_ok( $data->license->[0]->subject->[0], 'name' );
    if ( $data->license->[0]->subject->[0]->can('name') ) {
        ok( $data->license->[0]->subject->[0]->name, 'license / Test[0]: name' );
    }
    can_ok( $data->license->[0]->work->[0], 'code' );
    if ( $data->license->[0]->work->[0]->can('code') ) {
        ok( $data->license->[0]->work->[0]->code, 'license / Test[0]: code' );
    }
    can_ok( $data->license->[0]->work->[0], 'name' );
    if ( $data->license->[0]->work->[0]->can('name') ) {
        ok( $data->license->[0]->work->[0]->name, 'license / Test[0]: name' );
    }
    can_ok( $data->license->[0]->urls, 'mobile' );
    if ( $data->license->[0]->urls->can('mobile') ) {
        ok( $data->license->[0]->urls->mobile, 'license / Test[0]: mobile' );
    }
    can_ok( $data->license->[0]->urls, 'pc' );
    if ( $data->license->[0]->urls->can('pc') ) {
        ok( $data->license->[0]->urls->pc, 'license / Test[0]: pc' );
    }
    can_ok( $data->license->[0]->urls, 'qr' );
    if ( $data->license->[0]->urls->can('qr') ) {
        ok( $data->license->[0]->urls->qr, 'license / Test[0]: qr' );
    }
}

# license / Test[1]
{
    my $params = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = eval { $obj->license(%$params); };
    ok( ! $@, 'license / Test[1]: die' );
    ok( ! $res->is_error, 'license / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'license / Test[1]: root' );
    can_ok( $data, 'api_version' );
    if ( $data->can('api_version') ) {
        ok( $data->api_version, 'license / Test[1]: api_version' );
    }
    can_ok( $data, 'error' );
    if ( $data->can('error') ) {
        ok( $data->error, 'license / Test[1]: error' );
    }
    can_ok( $data->error, 'message' );
    if ( $data->error->can('message') ) {
        ok( $data->error->message, 'license / Test[1]: message' );
    }
}

# license / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->license(%$params); };
    ok( $@, 'license / Test[2]: die' );
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
    };
    my $res = eval { $obj->pref(%$params); };
    ok( $@, 'pref / Test[1]: die' );
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



1;
