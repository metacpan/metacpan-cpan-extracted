#!perl

use strict;
use warnings;
use utf8;
use HTTP::Request::Common;
use HTTP::Response;
use Path::Tiny;
use Test::Mock::LWP::Conditional;

use Test::More;
use Test::JsonAPI::Autodoc;

BEGIN {
    $ENV{TEST_JSONAPI_AUTODOC} = 1;
}

my $tempdir = Path::Tiny->tempdir('test-jsonapi-autodoc-XXXXXXXX');
set_documents_path($tempdir);

my $ok_res = HTTP::Response->new(200);
$ok_res->content('{ "message" : "success" }');
$ok_res->content_type('application/json');

Test::Mock::LWP::Conditional->stub_request(
    "/foobar" => $ok_res,
);

subtest 'Non JSON request parameters' => sub {
    describe 'POST /foobar' => sub {
        my $req = POST '/foobar', [ id => 1, message => 'blah blah' ];
        http_ok($req, 200, "get 200 ok");
    };
};

(my $filename = path($0)->basename) =~ s/\.t$//;
$filename .= '.md';
my $fh = path("$tempdir/$filename")->openr_utf8;

chomp (my $generated_at_line = <$fh>);
<$fh>; # blank
like $generated_at_line, qr/generated at: \d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d/, 'generated at ok';
my $got      = do { local $/; <$fh> };
my $expected = do { local $/; <DATA> };
is $got, $expected, 'result ok';

done_testing;
__DATA__
## POST /foobar

get 200 ok

### Parameters

__application/x-www-form-urlencoded__

- `id`
- `message`

### Request

POST /foobar

### Response

- Status:       200
- Content-Type: application/json

```json
{
   "message" : "success"
}

```

