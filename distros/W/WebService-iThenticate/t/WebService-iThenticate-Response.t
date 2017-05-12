#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;

my $pkg;

BEGIN {
    $pkg = 'WebService::iThenticate::Response';
    use_ok( $pkg );
}

can_ok( $pkg, qw( _new errors sid as_xml timestamp api_status id report document account folder uploaded documents groups folders users messages ) );

my $response;
eval { $response = $pkg->_new };

like( $@, qr/need a response/, '_new exception thrown' );

