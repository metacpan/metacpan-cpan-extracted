use strict;
use warnings;

use Test::Most;
use File::Spec;

use lib::ini::plugin::dir ();

my @dirs = qw(foo bar);

is_deeply ( [lib::ini::plugin::dir->generate_inc( dir => \@dirs)], \@dirs, 'got requested directories' );

done_testing;
