# $Id$

use Test::More tests => 9;
use WebService::Validator::HTML::W3C;
use HTTP::Response;

my $v = WebService::Validator::HTML::W3C->new( );

ok ($v, 'object created');

if ( $ENV{ 'TEST_AUTHOR' } ) {
	my $r = $v->validate( uri => 'http://exo.org.uk/code/www-w3c-validator/invalid.html' );

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
X-W3C-Validator-Errors: 1
X-W3C-Validator-Recursion: 1
X-W3C-Validator-Status: Invalid
END
	);

	$v->_response( $resp );
	$v->_parse_validator_response();	
}

ok (!$v->is_valid, 'page is not valid');
is ($v->errorcount, 1, 'correct number of errors');

SKIP: {
    skip "TEST_AUTHOR environment variable not defined", 4 unless $ENV{ 'TEST_AUTHOR' };
	
	my $valid = qq{<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "DTD/xhtml1-strict.dtd">
	<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
	<title></title>
	</head>
	<body>

	</body>
	</html>
	};
	
	my $r = $v->validate( string => $valid );

    unless ($r) {
        if ($v->validator_error eq "Could not contact validator")
        {
            skip "failed to contact validator", 2;
        }
    }

    ok($r, 'validated valid scalar');
    ok($v->is_valid(), 'valid scalar is valid');

    $r = $v->validate( file => 't/valid.html' );

    unless ($r) {
        if ($v->validator_error eq "Could not contact validator")
        {
            skip "failed to contact validator", 2;
        }
    }

    ok($r, 'validated valid file');
    ok($v->is_valid(), 'valid file is valid');
}

ok( !$v->validate( wrong => 'wrong' ), 'returns false is pass in wrong arguments');
is( $v->validator_error, 'You need to provide a uri, string or file to validate', 'correct error about wrong arguments' );
