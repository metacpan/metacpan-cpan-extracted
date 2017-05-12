use Test::More tests => 2 + 2;
use Test::NoWarnings;

use Readonly;
Readonly::Scalar my $WOOKIE_SERVER_CIRCUM => q{http://localhost:8080/wookie};
Readonly::Scalar my $WOOKIE_SERVER        => q{http://localhost:8080/wookie/};
Readonly::Scalar my $API_KEY              => q{TEST};
Readonly::Scalar my $SHARED_DATA_KEY      => q{localhost_dev};
use WWW::Wookie::Server::Connection;

my $obj = WWW::Wookie::Server::Connection->new( $WOOKIE_SERVER_CIRCUM, $API_KEY,
    $SHARED_DATA_KEY );
is( $obj->getURL, $WOOKIE_SERVER, q{RT#63231} );
$obj = WWW::Wookie::Server::Connection->new( $WOOKIE_SERVER, $API_KEY,
    $SHARED_DATA_KEY );
is( $obj->getURL, $WOOKIE_SERVER, q{RT#63231} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
