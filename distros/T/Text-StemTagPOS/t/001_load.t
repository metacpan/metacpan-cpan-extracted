# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Text::StemTagPOS' ); }

my $object = Text::StemTagPOS->new ();
isa_ok ($object, 'Text::StemTagPOS');
