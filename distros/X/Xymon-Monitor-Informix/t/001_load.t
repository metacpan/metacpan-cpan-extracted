# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;
use Xymon::Client;

BEGIN { use_ok( 'Xymon::Monitor::Informix' ); }

my $object = Xymon::Monitor::Informix->new ();
isa_ok ($object, 'Xymon::Monitor::Informix');


