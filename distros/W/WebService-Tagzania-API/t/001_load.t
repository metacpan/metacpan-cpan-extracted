# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'WebService::Tagzania::API' ); }

my $object = WebService::Tagzania::API->new ();
isa_ok ($object, 'WebService::Tagzania::API');


