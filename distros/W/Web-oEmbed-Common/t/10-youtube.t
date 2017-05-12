#!perl 

use strict;
use Test::More tests => 10;

BEGIN { use_ok 'Web::oEmbed::Common' || print "Bail out!" }

use Web::oEmbed::Common;

my $oembedder = Web::oEmbed::Common->new();

isa_ok( $oembedder, 'Web::oEmbed::Common' );

my $youtube_id = '5iAIM02kv0g';
my $target_url = "http://www.youtube.com/watch?v=$youtube_id";

my $request_url = $oembedder->request_url( $target_url );

ok( defined $request_url, "Generated request URL" );

like( $request_url, qr/\Qwww.youtube.com%2Fwatch%3Fv%3D$youtube_id\E/, "URL contains target" );

like( $request_url, qr/\Qhttp:\/\/www.youtube.com\/oembed\E/, "URL contains endpoint" );

my $result = $oembedder->embed( $target_url );

ok( defined $result, "Received oEmbed response" );
isa_ok( $result, 'Web::oEmbed::Response', "Received expected response type" );

if ( ! $result ) {
	
	# Unable to retrieve oEmbed result; is the 'Net connection active?
	
	fail( "No response to check" );
	fail( "No response to check" );
	fail( "No response to check" );
	
} else {
	is( $result->type, "video", "Response is a video" );
	like( $result->thumbnail_url, qr/^http(.*)jpg/sx, "Response has thumbnail" );
	like( $result->html, qr/<object .*? movie /sx, "Response has embed code" );	
}

1;
