use Test::Lib;
use Test::WebService::ValidSign;

use WebService::ValidSign::Types qw(WebServiceValidSignURI);
use URI;

my $endpoint = 'https://try.validsign.nl/api';

my $uri = URI->new($endpoint);

ok(
    WebServiceValidSignURI->check($uri),
    "URI->new($endpoint) is a valid URI object"
);

isa_ok(
    WebServiceValidSignURI->coerce($endpoint),
    'URI',
    "... and also coerces nicely"
);

done_testing;
