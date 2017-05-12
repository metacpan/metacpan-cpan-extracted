#!perl

use strict;
use warnings;
use utf8;
use HTTP::Request::Common;
use Path::Tiny;
use Plack::Test;
use Plack::Request;

use Test::More;
use Test::JsonAPI::Autodoc;

BEGIN {
    $ENV{TEST_JSONAPI_AUTODOC} = 1;
}

my $tempdir = Path::Tiny->tempdir('test-jsonapi-autodoc-XXXXXXXX');
set_documents_path($tempdir);

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    if ($req->path eq '/') {
        return [ 200, [ 'Content-Type' => 'application/json' ], ['{ "message" : "success" }'] ];
    }
    return [ 404, [ 'Content-Type' => 'text/plain' ], [ "Not found" ] ];
};

subtest 'Not use test_psgi' => sub {
    my $test_app = Plack::Test->create($app);
    describe 'POST /' => sub {
        my $req = POST '/';
        $req->header('Content-Type' => 'application/json');
        $req->content(q{
            {
            "id": 1,
            "message": "blah blah"
            }
        });
        plack_ok($test_app, $req, 200, "get message ok");
    };
};

subtest 'Use test_psgi' => sub {
    test_psgi $app, sub {
        my $cb = shift;

        describe 'POST /' => sub {
            my $req = POST '/';
            $req->header('Content-Type' => 'application/json');
            $req->content(q{
                {
                    "id": 1,
                    "message": "blah blah"
                }
            });
            plack_ok($cb, $req, 200, "get message ok");
        };

        describe 'POST /not-exist' => sub {
            my $req = POST '/not-exist';
            $req->header('Content-Type' => 'application/json');
            $req->content(q{
                {
                    "id": 1,
                    "message": "blah blah"
                }
            });
            plack_ok($cb, $req, 404, "not found");
        };
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
## POST /

get message ok

### Target Server

http://localhost

(Plack application)

### Parameters

__application/json__

- `id`: Number (e.g. 1)
- `message`: String (e.g. "blah blah")

### Request

POST /

### Response

- Status:       200
- Content-Type: application/json

```json
{
   "message" : "success"
}

```

## POST /

get message ok

### Target Server

http://localhost

(Plack application)

### Parameters

__application/json__

- `id`: Number (e.g. 1)
- `message`: String (e.g. "blah blah")

### Request

POST /

### Response

- Status:       200
- Content-Type: application/json

```json
{
   "message" : "success"
}

```

## POST /not-exist

not found

### Target Server

http://localhost

(Plack application)

### Parameters

__application/json__

- `id`: Number (e.g. 1)
- `message`: String (e.g. "blah blah")

### Request

POST /not-exist

### Response

- Status:       404
- Content-Type: text/plain

```json
Not found
```

