# $Id$

use Test::More tests => 3;
use WebService::Validator::HTML::W3C;
use HTTP::Response;

my $v = WebService::Validator::HTML::W3C->new( );

ok ($v, 'object created');
my $err_count = 4;

if ( $ENV{ 'TEST_AUTHOR' } ) {
	my $r = $v->validate('http://exo.org.uk/code/www-w3c-validator/invalid.html');

    $err_count = 1;
	unless ($r) {
	    if ($v->validator_error eq "Could not contact validator")
	    {
	        skip "failed to contact validator", 2;
	    }
	}
} else {
	my $resp = HTTP::Response->parse( <<END
200 OK
Connection: close
Date: Sun, 05 Aug 2007 14:38:36 GMT
Server: Apache/2.2.3 (Debian)
Content-Language: en
Content-Type: text/html; charset=utf-8
Client-Date: Sun, 05 Aug 2007 14:36:53 GMT
Client-Peer: 133.27.228.132:80
Client-Response-Num: 1
X-W3C-Validator-Errors: 4
X-W3C-Validator-Recursion: 1
X-W3C-Validator-Status: Invalid
END
	);

	$v->_response( $resp );
	$v->_parse_validator_response();	
}

ok (!$v->is_valid, 'page is not valid');
is ($v->num_errors, $err_count, 'correct number of errors');
