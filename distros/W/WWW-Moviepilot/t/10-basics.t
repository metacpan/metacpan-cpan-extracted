use warnings;
use strict;

use Test::More;

use_ok( 'WWW::Moviepilot' );

BEGIN {
    plan skip_all => 'set WWW_MOVIEPILOT_APIKEY to enable this test'
        unless $ENV{WWW_MOVIEPILOT_APIKEY};
    plan tests => 9;
}

# no API key
eval { my $m = WWW::Moviepilot->new };
like( $@, qr/api_key is missing/ );

# with API key
my $m = WWW::Moviepilot->new({ api_key => $ENV{WWW_MOVIEPILOT_APIKEY} });
isa_ok( $m, 'WWW::Moviepilot' );

# default host
is( $m->host, 'http://www.moviepilot.de' );

# custom host without scheme
$m = WWW::Moviepilot->new({ api_key => $ENV{WWW_MOVIEPILOT_APIKEY}, host => 'www.example.com' });
isa_ok( $m, 'WWW::Moviepilot' );
is( $m->host, 'http://www.example.com' );

# custom host with scheme
$m = WWW::Moviepilot->new({ api_key => $ENV{WWW_MOVIEPILOT_APIKEY}, host => 'http://www.example.com' });
isa_ok( $m, 'WWW::Moviepilot' );
is( $m->host, 'http://www.example.com' );

# user agent
isa_ok( $m->ua, 'LWP::UserAgent' );
