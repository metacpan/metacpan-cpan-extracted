# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Text::CSV::Slurp' ); }

my $object = Text::CSV::Slurp->new ();
isa_ok ($object, 'Text::CSV::Slurp');


