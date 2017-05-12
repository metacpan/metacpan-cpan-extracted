# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Xymon::Client' ); }

my $object = Xymon::Client->new ();
isa_ok ($object, 'Xymon::Client');


