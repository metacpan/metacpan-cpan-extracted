use strict;
use warnings;

use Test::Most;
use File::Spec;

use lib::ini::plugin::libdir ();

my @dirs = qw(foo bar);
my @libdirs = map File::Spec->catdir($_, 'lib'), @dirs;

is_deeply ( [lib::ini::plugin::libdir->generate_inc( dir => \@dirs)], \@libdirs, 'got requested lib directories' );

done_testing;
