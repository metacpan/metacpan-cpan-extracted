# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WebService-BR-AceitaFacil.t'

#########################

use Test::More tests => 10;
BEGIN { use_ok('WebService::BR::AceitaFacil') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Make sure we have all these installed:
use_ok( 'MIME::Base64' );
use_ok( 'JSON::XS' );
use_ok( 'LWP::UserAgent' );
use_ok( 'HTTP::Request::Common' );
use_ok( 'IO::Socket::SSL' );

# Very besic things we need working
ok( WebService::BR::AceitaFacil->new(), 'new object' );
ok( WebService::BR::AceitaFacil->new()->{json}->encode( {a=>1} ) =~ /{"a":"?1"?}/, 'JSON::XS encode' );
ok( WebService::BR::AceitaFacil->new()->{json}->decode( '{"a":"1"}' )->{a} == 1, 'JSON::XS decode' );
ok( MIME::Base64::encode_base64('Simple stuff','') eq 'U2ltcGxlIHN0dWZm',  'MIME::Base64 encode' );
