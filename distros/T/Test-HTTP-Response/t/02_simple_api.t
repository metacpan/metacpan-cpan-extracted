use strict;
use HTTP::Response;
use HTTP::Message;

use Data::Dumper;

use CGI::Cookie;

use Test::More tests => 8;
use Test::HTTP::Response;

# Create new cookies, headers, etc
my $cookie = new CGI::Cookie(-name=>'ID',-value=>123456);
my $headers = ['set_cookie' => $cookie->as_string, 'content_type', 'Text/HTML'];
my $message = HTTP::Message->new( $headers, '<HTML><BODY><h1>Hello World</h1></BODY></HTML>');
my $response = HTTP::Response->new( 200, $message, $message->headers );

#
# check matching cookie(s) found in response

cookie_matches($response, { key => 'ID' },'ID exists ok');
cookie_matches($response, { key => 'ID', value=>"123456" }, 'ID value correct');

my $cookies = extract_cookies($response);
my $expected_cookie = {
		       'discard' => undef,
		       'value' => '123456',
		       'version' => 0,
		       'path' => 1,
		       'port' => undef,
		       'key' => 'ID',
		       'hash' => undef,
		       'domain' => undef,
		       'path_spec' => 1,
		       'expires' => undef
		      };
is_deeply ( [@{$cookies->{ID}}{sort keys %$expected_cookie}], [@{$expected_cookie}{sort keys %$expected_cookie}], 'extracted cookie data matches');

#
# check status codes

status_matches($response, 200, 'Response is ok');
status_ok($response);

# my $actual_failures = 0;
# TODO: {
#     local $TODO = 'These tests should always fail';
#     $actual_failures++ unless status_redirect($response);
#     $actual_failures++ unless status_not_found($response);
#     $actual_failures++ unless status_error($response);
# }
# is ($actual_failures, 3 ,'other status codes failed as expected');

header_matches($response, 'Content-type', 'Text/HTML', 'correct content type');

my $cookie2 = new CGI::Cookie(-name=>'ID',-value=>123456789);
my $headers2 = ['set_cookie' => $cookie2->as_string, 'content_type', 'Text/HTML'];
my $message2 = HTTP::Message->new( $headers2, '<HTML><BODY><h1>Hello World</h1></BODY></HTML>');
my $response2 = HTTP::Response->new( 200, $message2, $message2->headers );

cookie_matches($response2, { key => 'ID' },'ID exists ok');
cookie_matches($response2, { key => 'ID', value=>"123456789" }, 'ID value correct');
