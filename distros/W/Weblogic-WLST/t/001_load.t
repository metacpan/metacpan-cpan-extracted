# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Weblogic::WLST' ); }

my $object = Weblogic::WLST->new ();
isa_ok ($object, 'Weblogic::WLST');


