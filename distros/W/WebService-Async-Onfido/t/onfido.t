use strict;
use warnings;
use Test::More tests => 72;
use Test::Exception;
use Test::NoWarnings;
use Test::MockModule;
use Path::Tiny;

use IO::Async::Loop;

use WebService::Async::Onfido;
use URI;
use FindBin     qw($Bin);
use URI::Escape qw(uri_escape_utf8);
use MIME::Base64;

my $pid = fork();
die "fork error " unless defined($pid);

unless ($pid) {
    my $mock_server = "$Bin/../bin/mock_onfido.pl";
    open(STDOUT, '>/dev/null');
    open(STDERR, '>/dev/null');
    exec($^X, $mock_server);
}

sleep 3;
my $loop = IO::Async::Loop->new;
my @api_hits;

$loop->add(
    my $onfido = WebService::Async::Onfido->new(
        token      => 'test_token',
        base_uri   => 'http://localhost:3000',
        on_api_hit => sub {
            my ($data) = @_;

            push @api_hits, $data;
        }));

# applicant create
@api_hits = ();
my $app;
my $applicant_create = {
    title      => 'Mr',
    first_name => 'John',
    last_name  => 'Smith',
    email      => 'john@example.com',
    gender     => 'male',
    dob        => '1980-01-22',
    country    => 'GBR',
    address    => {
        building_number => '100',
        street          => 'Main Street',
        town            => 'London',
        postcode        => 'SW4 6EH',
        country         => 'GBR',
    },
};

lives_ok {
    $app = $onfido->applicant_create($applicant_create->%*)->get;
}
'create applicant ok';
like($app->as_string, qr/^John Smith/, 'application string is correct');
isa_ok($app, 'WebService::Async::Onfido::Applicant', 'object type is ok');

# applicant_update
my $applicant_update = {
    first_name   => 'Jack',
    applicant_id => $app->id
};
lives_ok { $onfido->applicant_update($applicant_update->%*)->get; }
"update applicant ok ";

my $applicant_get = {applicant_id => $app->id};
$app = $onfido->applicant_get($applicant_update->%*)->get;
like($app->as_string, qr/^Jack Smith/, 'application string is correct');

# applicant_list
my $src;
lives_ok { $src = $onfido->applicant_list; } "get applicant list ok ";
isa_ok($src, 'Ryu::Source', 'the applicant list is a Ryu::Source');
is_deeply($src->as_arrayref->get->[0], $app, 'the most recent applicants is the one we created just now');

# get applicant
my $app2;
lives_ok { $app2 = $onfido->applicant_get(applicant_id => $app->id)->get; }
"get applicant ok ";
isa_ok($app2, 'WebService::Async::Onfido::Applicant', 'the applicant type is ok');
is_deeply($app2, $app, 'get applicant result ok');

# document upload
my $doc;
my $content         = 'x' x 500;
my $document_upload = {
    applicant_id    => $app->id,
    filename        => "document1.png",
    type            => 'passport',
    issuing_country => 'China',
    data            => $content,
};
lives_ok {
    $doc = $onfido->document_upload($document_upload->%*)->get
}
"upload document ok";
isa_ok($doc, 'WebService::Async::Onfido::Document', "document type is ok");
is($doc->type, 'passport', 'data is correct');

delete $document_upload->{data};

# document list
my $document_list     = {applicant_id => $app->id};
my $document_list_uri = $onfido->endpoint('documents');
$document_list_uri->query('applicant_id=' . uri_escape_utf8($app->id));

lives_ok { $src = $onfido->document_list($document_list->%*) }
"document list ok";
isa_ok($src, 'Ryu::Source', 'the document list is a Ryu::Source');
is_deeply($src->as_arrayref->get->[0], $doc, 'the most recent doc is the one we created just now');

# get document
my $doc2;
my $document_details = {
    applicant_id => $app->id,
    document_id  => $doc->id
};
lives_ok { $doc2 = $onfido->get_document_details($document_details->%*)->get }
'get doc ok';
is_deeply($doc2, $doc, 'get doc result is right');

# download_document
my $content2;
my $download_document = {
    applicant_id => $app->id,
    document_id  => $doc->id
};
lives_ok {
    $content2 = $onfido->download_document($download_document->%*)->get
}
'download doc ok';

is($content2, $content, "the content is right");

# photo upload
my $photo;
my $live_photo_upload = {
    applicant_id => $app->id,
    filename     => 'photo1.jpg',
    data         => 'photo ' x 50
};
lives_ok { $photo = $onfido->live_photo_upload($live_photo_upload->%*)->get }
'upload photo ok';
isa_ok($photo, 'WebService::Async::Onfido::Photo', 'result type is ok');
is($photo->file_name, 'photo1.jpg', 'result is ok');

$live_photo_upload->{advanced_validation} = 'false';
delete $live_photo_upload->{data};

# photo list
my $photo_list = {applicant_id => $app->id};
lives_ok { $src = $onfido->photo_list($photo_list->%*) } "photo list ok";
isa_ok($src, 'Ryu::Source', 'the applicant list is a Ryu::Source');
is_deeply($src->as_arrayref->get->[0], $photo, 'the most recent photo is the one we created just now');

# get document
my $photo2;
my $get_photo_details = {live_photo_id => $photo->id};

lives_ok { $photo2 = $onfido->get_photo_details($get_photo_details->%*)->get }
'get photo ok';
is_deeply($photo2, $photo, 'get result is right');

# download_photo
my $photo_download = {live_photo_id => $photo->id};
lives_ok { $content = $onfido->download_photo($photo_download->%*)->get }
'download doc ok';

is($content, 'photo ' x 50, "the content is right");

# applicant_check
my $check;
my $applicant_check = {
    applicant_id               => $app->id,
    report_names               => ['document', 'facial_similarity',],
    documents_ids              => ['0001',     '0002'],
    tags                       => ['tag1',     'tag2'],
    suppress_from_email        => 0,
    asynchronous               => 1,
    charge_applicant_for_check => 0,
};
lives_ok {
    $check = $onfido->applicant_check($applicant_check->%*)->get;
}
"create check ok";
isa_ok($check, "WebService::Async::Onfido::Check", "check class is right");
is_deeply($check->tags, ['tag1', 'tag2'], 'result is ok');
is $check->download_uri, $onfido->endpoint('check_download', check_id => $check->id), 'Expected download uri';

# get check
my $check2;
my $check_get = {
    applicant_id => $app->id,
    check_id     => $check->id,
};
lives_ok {
    $check2 = $onfido->check_get($check_get->%*)->get
}
"get check ok";

isa_ok($check2, "WebService::Async::Onfido::Check", "check class is right");
$check->{status} = 'complete';    # after get check, it will be 'complete';
is_deeply($check2, $check, 'result is ok');
is $check->applicant_id, $app->id, 'Expected applicant id';

# download the check as PDF
my $pdf;

lives_ok {
    $pdf = $check2->download()->get;
}
"get pdf check ok";

ok encode_base64($pdf) =~ /^JVBERi0xL/, 'Somehow a PDF';

lives_ok {
    $pdf = $onfido->download_check($check_get->%*)->get;
}
"get pdf check ok";

ok encode_base64($pdf) =~ /^JVBERi0xL/, 'Somehow a PDF';

# check list
my $check_list     = {applicant_id => $app->id};
my $check_list_uri = $onfido->endpoint('checks');
$check_list_uri->query('applicant_id=' . uri_escape_utf8($app->id));

lives_ok { $src = $onfido->check_list($check_list->%*) } "check list ok";

isa_ok($src, 'Ryu::Source', 'the applicant list is a Ryu::Source');

is_deeply($src->as_arrayref->get->[0], $check, 'the most recent check is the one we created just now');

# get report
my ($report, $report2);
lives_ok {
    $report = $check->reports->filter(name => 'document')->as_arrayref->get->[0]
}
"get report from check ok";
isa_ok($report, 'WebService::Async::Onfido::Report');
is $report->name, 'document';

my $report_get = {
    check_id  => $check->id,
    report_id => $report->{id},
};
my $report_list_uri = $onfido->endpoint('reports', check_id => $check->id);
$report_list_uri->query('check_id=' . uri_escape_utf8($check->id));
lives_ok {
    $report2 = $onfido->report_get($report_get->%*)->get
}
"get report ok";

isa_ok($report2, 'WebService::Async::Onfido::Report');
$report2->{check} = $check;    # set check for test.
is_deeply($report2, $report, 'id is correct');

# sdk_token
my $sdk_token = {
    applicant_id => $app->id,
    referrer     => 'https://*.example.com/example_page/*'
};
my $token;
lives_ok { $token = $onfido->sdk_token($sdk_token->%*)->get };
ok($token->{token}, 'there is a token in the result');
is($token->{referrer}, 'https://*.example.com/example_page/*', 'referrer is ok in the result');

# applicant delete
my $applicant_delete = {applicant_id => $app->id};
lives_ok { $onfido->applicant_delete($applicant_delete->%*)->get }
"delete ok";

is_deeply(
    [@api_hits],
    [{
            POST => $onfido->endpoint('applicants'),
            body => $applicant_create
        },
        {
            PUT  => $onfido->endpoint('applicant', $applicant_update->%*),
            body => $applicant_update
        },
        {GET => $onfido->endpoint('applicant', $applicant_get->%*)},
        {GET => $onfido->endpoint('applicants')},
        {GET => $onfido->endpoint('applicant', $applicant_get->%*)},
        {
            POST => $onfido->endpoint('documents'),
            body => $document_upload
        },
        {GET => $document_list_uri},
        {GET => $onfido->endpoint('document',          $document_details->%*)},
        {GET => $onfido->endpoint('document_download', $download_document->%*)},
        {
            POST => $onfido->endpoint('photo_upload'),
            body => $live_photo_upload
        },
        {GET => $onfido->endpoint('photos',         $photo_list->%*)},
        {GET => $onfido->endpoint('photo',          $get_photo_details->%*)},
        {GET => $onfido->endpoint('photo_download', $photo_download->%*)},
        {
            POST => $onfido->endpoint('checks'),
            body => $applicant_check
        },
        {GET => $onfido->endpoint('check',          $check_get->%*)},
        {GET => $onfido->endpoint('check_download', $check_get->%*)},
        {GET => $onfido->endpoint('check_download', $check_get->%*)},
        {GET => $check_list_uri},
        {GET => $report_list_uri},
        {GET => $onfido->endpoint('report', $report_get->%*)},
        {
            POST => $onfido->endpoint('sdk_token'),
            body => $sdk_token
        },
        {DELETE => $onfido->endpoint('applicant', $applicant_delete->%*)},
    ],
    'expected API hits so far'
);

# api hit hook is undefined

$loop->add(
    my $onfido2 = WebService::Async::Onfido->new(
        token    => 'test_token',
        base_uri => 'http://localhost:3000'
    ));

lives_ok { $src = $onfido2->check_list($check_list->%*) } "check list ok";

isa_ok($src, 'Ryu::Source', 'the applicant list is a Ryu::Source');

is_deeply($src->as_arrayref->get->[0]->id, $check->id, 'expected check returned');

# api hit hook is not a code ref

$loop->add(
    my $onfido3 = WebService::Async::Onfido->new(
        token      => 'test_token',
        base_uri   => 'http://localhost:3000',
        on_api_hit => 'test'
    ));

lives_ok { $src = $onfido3->check_list($check_list->%*) } "check list ok";

isa_ok($src, 'Ryu::Source', 'the applicant list is a Ryu::Source');

is_deeply($src->as_arrayref->get->[0]->id, $check->id, 'expected check returned');

# rate limit hook

my @rate_limit;

$loop->add(
    my $onfido4 = WebService::Async::Onfido->new(
        token               => 'test_token',
        base_uri            => 'http://localhost:3000',
        requests_per_minute => 1,
        rate_limit_delay    => 1,
        on_rate_limit       => sub {
            my ($data) = @_;

            push @rate_limit, $data;
        }));

lives_ok { $src = $onfido4->check_list($check_list->%*) } "check list ok";

isa_ok($src, 'Ryu::Source', 'the applicant list is a Ryu::Source');

is_deeply($src->as_arrayref->get->[0]->id, $check->id, 'expected check returned');

is_deeply(
    [@rate_limit],
    [{
            requests_per_minute => 1,
            requests_count      => 1,
        }
    ],
    'rate limit hit'
);

lives_ok { $src = $onfido4->check_list($check_list->%*) } "check list ok";

isa_ok($src, 'Ryu::Source', 'the applicant list is a Ryu::Source');

is_deeply($src->as_arrayref->get->[0]->id, $check->id, 'expected check returned');

is_deeply(
    [@rate_limit],
    [{
            requests_per_minute => 1,
            requests_count      => 1,
        },
        {
            requests_per_minute => 1,
            requests_count      => 1,
        }
    ],
    'rate limit hits'
);

kill('TERM', $pid);
