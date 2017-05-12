# $Id$

use Test::More;

use WebService::Validator::HTML::W3C;
use HTTP::Response;

if ( $ENV{ 'TEST_AUTHOR'} ) {
	plan tests => 7;
} else {
	plan tests => 5;
}

my $v = WebService::Validator::HTML::W3C->new( );

ok($v, 'Object created');

is($v->validator_uri(), 'http://validator.w3.org/check', 'correct default validator uri');

if ( $ENV{ 'TEST_AUTHOR'} ) {
    my $r = $v->validate('http://exo.org.uk/code/www-w3c-validator/valid.html');

    unless ($r) {
        if ($v->validator_error eq "Could not contact validator")
        {
            skip "failed to contact validator", 5;
        }
    }

	ok($r, 'validates page');
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
X-W3C-Validator-Errors: 0
X-W3C-Validator-Recursion: 1
X-W3C-Validator-Status: Valid
END
	);

	$v->_response( $resp );
	$v->_parse_validator_response();
}

   ok($v->is_valid, 'page is valid');
   is($v->num_errors, 0, 'no errors in valid page');
   is($v->errors, undef, 'no information on errors returned');

if ( $ENV{ 'TEST_AUTHOR' } ) {
	is($v->uri, 'http://exo.org.uk/code/www-w3c-validator/valid.html', 'uri correct');
}
