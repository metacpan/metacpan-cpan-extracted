# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'WebService::Basecamp' ); }

my $object = WebService::Basecamp->new ( url => 'test', user => 'test', pass => 'test' );
isa_ok ($object, 'WebService::Basecamp');


