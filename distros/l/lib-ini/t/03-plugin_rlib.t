use strict;
use warnings;

use Test::Most;
use File::Spec;

use lib::ini::plugin::rlib ();

my $libdir = File::Spec->catdir(File::Spec->curdir, 'lib');
is( lib::ini::plugin::rlib->generate_inc, $libdir, 'got lib directory' );

done_testing;
