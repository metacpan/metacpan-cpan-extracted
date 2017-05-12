# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Test::VCR::LWP' ); }

my $object = Test::VCR::LWP->new ();
isa_ok ($object, 'Test::VCR::LWP');


