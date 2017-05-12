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

my $res = HTTP::Response->new(200);
$res->content('{ "message" : "success" }');
$res->content_type('application/json');

Test::Mock::LWP::Conditional->stub_request(
    "/foobar" => $res
);

describe 'POST /foobar' => sub {
    my $req = POST '/foobar';
    $req->header('Content-Type' => 'application/json');
    $req->content(q{
        {
            "id": 1,
            "parent": {
                "child": {
                    "article_id": 123,
                    "text": "foobar"
                }
            },
            "message": "hello"
        }
    });
    http_ok($req, 200, "get message");
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

get message

### Parameters

__application/json__

- `id`: Number (e.g. 1)
- `message`: String (e.g. "hello")
- `parent`: JSON
    - `child`: JSON
        - `article_id`: Number (e.g. 123)
        - `text`: String (e.g. "foobar")

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

