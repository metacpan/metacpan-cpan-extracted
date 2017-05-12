use strict;
use warnings;
use Test::More;

BEGIN {
  if (defined $ENV{ECHONEST_API_KEY}) {
      plan tests => 13;
  } else {
      plan skip_all => 'ECHONEST_API_KEY environemnt variable is not defined';
  }
 
  use_ok 'WebService::EchoNest'
}

my ($METHOD, $ARTIST, $ARTIST_ID) = 
  qw(artist/search Radiohead ARH6W4X1187B99274F);

my $KEY = $ENV{ECHONEST_API_KEY};

my $echonest = new_ok('WebService::EchoNest', [api_key => $KEY]);
my $root = $echonest->api_root;

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