#!perl 

use strict;
use Test::More tests => 10;

BEGIN { use_ok 'Web::oEmbed::Common' || print "Bail out!" }

use Web::oEmbed::Common;

my $oembedder = Web::oEmbed::Common->new();

isa_ok( $oembedder, 'Web::oEmbed::Common' );

my $target_url = 'http://xkcd.com/730/';

my $request_url = $oembedder->request_url( $target_url );

ok( defined $request_url, "Generated request URL" );

like( $request_url, qr/2Fxkcd.com%2F730%2F\E/, "URL contains target" );

my $result = $oembedder->embed( $target_url );

ok( defined $result, "Received oEmbed response" );
isa_ok( $result, 'Web::oEmbed::Response', "Received expected response type" );

if ( ! $result ) {
	
	# Unable to retrieve oEmbed result; is the 'Net connection active?
	
	fail( "No response to check" );
	fail( "No response to check" );
	fail( "No response to check" );
	
} else {
	is( $result->type, "photo", "Response is a photo" );
	like( $result->url, qr/circuit_diagram/, "Found expected filename" );

	ok( $result->thumbnail_url, "Response has thumbnail" );
	like( $result->thumbnail_url, qr/^http(.*)[.](jpg|gif|png)/sx, "Response thumbnail looks normal" );
}

1;
