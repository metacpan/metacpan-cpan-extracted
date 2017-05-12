# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Xymon::Monitor::SNMP' ); }

my $object = Xymon::Monitor::SNMP->new ();
isa_ok ($object, 'Xymon::Monitor::SNMP');


