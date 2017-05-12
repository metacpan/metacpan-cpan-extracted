use strict;
use warnings;
use Test::More tests => 3;

# the order is important
use WWW::Hashbang::Pastebin;
use Dancer::Plugin::DBIC;
use Dancer::Test;

schema->deploy;

route_exists        [GET => '/'],       'a route handler is defined for GET /';
response_status_is  [GET => '/'], 200,  'response status is 200 for GET /';
response_content_like
    [GET => '/'],
    qr/WWW::Hashbang::Pastebin\(3\)/,
    'main page renders OK';
