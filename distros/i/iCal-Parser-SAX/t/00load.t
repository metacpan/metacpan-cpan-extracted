# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'iCal::Parser::SAX' ); }

my $object = iCal::Parser::SAX->new ();
isa_ok ($object, 'iCal::Parser::SAX');
