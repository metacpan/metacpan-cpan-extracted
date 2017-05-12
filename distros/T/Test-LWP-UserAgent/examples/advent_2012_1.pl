use strict;
use warnings;
use feature 'say';

use Test::LWP::UserAgent;

my $useragent = Test::LWP::UserAgent->new;
$useragent->map_response(qr/example.com/, HTTP::Response->new('200'));

my $response = $useragent->get('http://example.com');
# prints 200
say $response->code;

$response = $useragent->get('http://google.com');
# prints 404
say $response->code;

