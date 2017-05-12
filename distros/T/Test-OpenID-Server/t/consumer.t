use warnings;
use strict;

use Test::More tests => 6;

use_ok('Test::OpenID::Server');
my $s   = Test::OpenID::Server->new;
my $URL = $s->started_ok("started server");

use_ok('Test::OpenID::Consumer');
my $c    = Test::OpenID::Consumer->new;
my $CURL = $c->started_ok("started consumer");

$c->verify_ok( "$URL/test" );
$c->verify_invalid( "$URL/unknown" );

