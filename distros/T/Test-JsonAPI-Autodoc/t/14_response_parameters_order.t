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

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    return [
        200,
        [ 'Content-Type' => 'application/json' ],
        [
            '{
                "hoge": {
                    "A": "AA",
                    "B": "BB",
                    "C": "CC",
                    "D": "DD",
                    "E": "EE",
                    "F": "FF",
                    "G": "GG",
                    "H": "HH",
                    "I": "II",
                    "J": "JJ",
                    "K": "KK",
                    "L": "LL",
                    "M": "MM",
                    "N": "NN",
                    "O": "OO",
                    "P": "PP",
                    "Q": "QQ",
                    "R": "RR",
                    "S": "SS",
                    "T": "TT",
                    "U": "UU",
                    "V": "VV",
                    "W": "WW",
                    "X": "XX",
                    "Y": "YY",
                    "Z": "ZZ",
                    "a": "aa",
                    "b": "bb",
                    "c": "cc",
                    "d": "dd",
                    "e": "ee",
                    "f": "ff",
                    "g": "gg",
                    "h": "hh",
                    "i": "ii",
                    "j": "jj",
                    "k": "kk",
                    "l": "ll",
                    "m": "mm",
                    "n": "nn",
                    "o": "oo",
                    "p": "pp",
                    "q": "qq",
                    "r": "rr",
                    "s": "ss",
                    "t": "tt",
                    "u": "uu",
                    "v": "vv",
                    "w": "ww",
                    "x": "xx",
                    "y": "yy",
                    "z": "zz"
                }
            }'
        ],
        ['{ "message" : "success" }']
    ];
};

my $tempdir = Path::Tiny->tempdir('test-jsonapi-autodoc-XXXXXXXX');
set_documents_path($tempdir);

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
};

(my $filename = path($0)->basename) =~ s/\.t$//;
$filename .= ".md";
my $fh = path("$tempdir/$filename")->openr_utf8;

<$fh>; # skip a time stamp row (Unnecessary to check this at this test)
<$fh>; # skip a blank row
my $got = do { local $/; <$fh> };
my $expected = do { local $/; <DATA> };
is $got, $expected, 'Response parameters should be ordered';

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
   "hoge" : {
      "A" : "AA",
      "B" : "BB",
      "C" : "CC",
      "D" : "DD",
      "E" : "EE",
      "F" : "FF",
      "G" : "GG",
      "H" : "HH",
      "I" : "II",
      "J" : "JJ",
      "K" : "KK",
      "L" : "LL",
      "M" : "MM",
      "N" : "NN",
      "O" : "OO",
      "P" : "PP",
      "Q" : "QQ",
      "R" : "RR",
      "S" : "SS",
      "T" : "TT",
      "U" : "UU",
      "V" : "VV",
      "W" : "WW",
      "X" : "XX",
      "Y" : "YY",
      "Z" : "ZZ",
      "a" : "aa",
      "b" : "bb",
      "c" : "cc",
      "d" : "dd",
      "e" : "ee",
      "f" : "ff",
      "g" : "gg",
      "h" : "hh",
      "i" : "ii",
      "j" : "jj",
      "k" : "kk",
      "l" : "ll",
      "m" : "mm",
      "n" : "nn",
      "o" : "oo",
      "p" : "pp",
      "q" : "qq",
      "r" : "rr",
      "s" : "ss",
      "t" : "tt",
      "u" : "uu",
      "v" : "vv",
      "w" : "ww",
      "x" : "xx",
      "y" : "yy",
      "z" : "zz"
   }
}

```

