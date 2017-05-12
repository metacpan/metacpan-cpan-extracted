use strict;
use warnings;
use Test::More tests => 5;

# the order is important
use WWW::Hashbang::Pastebin;
use Dancer::Plugin::DBIC;
use Dancer::Test;

schema->deploy;

my $rand = rand();
route_exists [POST => '/'], 'a route handler is defined for POST /';
my $response = dancer_response('POST', '/', { params  => {p => $rand} });
like $response->content, qr{^http://.+/.+} or diag explain $response;

my $paste_id = $response->header('X-Pastebin-ID');
route_exists            [GET => "/$paste_id"],              "route /$paste_id exists";
response_status_is      [GET => "/$paste_id"], 200,         "200 for /$paste_id";

$rand = quotemeta $rand;
response_content_like   [GET => "/$paste_id"], qr/$rand/,   "$rand appears in the content";
