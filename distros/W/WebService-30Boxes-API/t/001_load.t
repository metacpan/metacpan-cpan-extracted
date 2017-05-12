# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'WebService::30Boxes::API' ); }

my $object = WebService::30Boxes::API->new (api_key => 'foobar');
isa_ok ($object, 'WebService::30Boxes::API');


