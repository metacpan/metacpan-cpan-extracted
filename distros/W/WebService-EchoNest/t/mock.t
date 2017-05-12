use strict;
use warnings;
use Test::More tests => 13;
use Test::LWP::UserAgent;

BEGIN {
  use_ok 'WebService::EchoNest'
}

my ($METHOD, $ARTIST, $ARTIST_ID, $KEY) = 
  qw(artist/search Radiohead ARH6W4X1187B99274F XXX);

my $ua = Test::LWP::UserAgent->new;

my $echonest = new_ok('WebService::EchoNest', [ua => $ua, api_key => $KEY]);

my $root = $echonest->api_root;

$echonest->ua->map_response(qr{$root}, 
  HTTP::Response->new(
    200, 'OK', ['Content-Type' => 'application/json'], qq(
{
    "response": {
        "status": {
            "version": "4.2",
            "code": 0,
            "message": "Success"
        },
        "artists": [
            {
                "name": "$ARTIST",
                "id": "$ARTIST_ID"
            }
        ]
    }
})
  )
);

my $req = $echonest->create_http_request($METHOD, name => $ARTIST, results => 1);
isa_ok($req, 'HTTP::Request', 'Request');
like($req->uri, qr{^$root}, 'Request URI root is correct');
like($req->uri, qr{name=$ARTIST}, 'Request URI contains artist param');
like($req->uri, qr{api_key=$KEY}, 'Request URI contains api_key param');
like($req->uri, qr{results=1}, 'Request URI contains results param');

my $data = $echonest->request($METHOD, name => $ARTIST, results => 1);
isa_ok($data => 'HASH', 'Response data');
is($data->{response}->{status}->{message} => 'Success', 'Status is success');

my $artists = $data->{response}->{artists};
isa_ok($artists => 'ARRAY', 'Artist list');
is(@$artists => 1, 'There is a single artist in the list');

my $artist = @$artists[0];
is($artist->{name} => $ARTIST, 'Artsit name is correct');
is($artist->{id} => $ARTIST_ID, 'Artsit id is correct');

done_testing();