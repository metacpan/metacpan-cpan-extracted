package WM::Bar;

use strict;
use warnings;

use File::Basename;

use Test::More;

my ($name, $path, $suffix) = fileparse($_, qr/\.[^.]*/);
is("Bar",   $name);
is($suffix, ".t");

done_testing;
