# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Xymon::Server' ); }

my $object = Xymon::Server->new ();
isa_ok ($object, 'Xymon::Server');


