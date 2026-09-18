use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('WebService::Litportnet::FreeProxy');
}

is( $WebService::Litportnet::FreeProxy::VERSION, '0.001', 'module reports the expected version' );
