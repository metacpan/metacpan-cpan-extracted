# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Xymon::DB::Schema' ); }

my $object = Xymon::DB::Schema->new ();
isa_ok ($object, 'Xymon::DB::Schema');


