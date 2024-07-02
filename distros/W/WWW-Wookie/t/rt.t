# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.020;
use strict;
use warnings;
use utf8;
use Test::More 'tests' => 2 + 1 + ( $ENV{'AUTHOR_TESTING'} ? 0 : 1 );
use Test::NoWarnings;
use Readonly;

our $VERSION = v1.1.6;

## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $TEST_WARNINGS => $ENV{'AUTHOR_TESTING'}
## no critic (RequireCheckingReturnValueOfEval)
  && eval { require Test::NoWarnings };
Readonly::Scalar my $WOOKIE_SERVER_CIRCUM => q{http://localhost:8080/wookie};
Readonly::Scalar my $WOOKIE_SERVER        => q{http://localhost:8080/wookie/};
Readonly::Scalar my $API_KEY              => q{TEST};
Readonly::Scalar my $SHARED_DATA_KEY      => q{localhost_dev};
use WWW::Wookie::Server::Connection;

my $connection =
  WWW::Wookie::Server::Connection->new( $WOOKIE_SERVER_CIRCUM, $API_KEY,
    $SHARED_DATA_KEY, );
Test::More::is( $connection->getURL, $WOOKIE_SERVER, q{RT#63231} );
$connection = WWW::Wookie::Server::Connection->new( $WOOKIE_SERVER, $API_KEY,
    $SHARED_DATA_KEY, );
Test::More::is( $connection->getURL, $WOOKIE_SERVER, q{RT#63231} );

## no critic (RequireInterpolationOfMetachars)
my $msg = q{Author test. Install Test::NoWarnings and set }
  . q{$ENV{AUTHOR_TESTING} to a true value to run.};
SKIP: {
    if ( !$TEST_WARNINGS ) {
        Test::More::skip $msg, 1;
    }
}
$TEST_WARNINGS && Test::NoWarnings::had_no_warnings();
