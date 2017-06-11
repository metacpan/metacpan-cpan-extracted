# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WebService-BR-Vindi.t'

#########################

use Test::More tests => 6;
BEGIN { use_ok('WebService::BR::Vindi') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Make sure we have all these installed:
use_ok( 'MIME::Base64' );
use_ok( 'JSON::XS' );
use_ok( 'LWP::UserAgent' );
use_ok( 'HTTP::Request::Common' );
use_ok( 'IO::Socket::SSL' );

