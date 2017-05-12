# -*- perl -*-

# t/001_load.t - check module loading and create testing directory
use strict;

use Test::More tests => 2;

BEGIN { use_ok( 'WebService::CRUST' ); }

my $object = WebService::CRUST->new ();
isa_ok ($object, 'WebService::CRUST');


