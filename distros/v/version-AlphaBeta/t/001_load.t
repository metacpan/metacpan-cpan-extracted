# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'version::AlphaBeta' ); }

my $object = version::AlphaBeta->new ('1.0');
isa_ok ($object, 'version::AlphaBeta');


