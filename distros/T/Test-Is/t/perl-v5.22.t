# Generic test dependent on its filename

use strict;
use warnings;

use File::Spec ();

my $arg;
BEGIN {
    $arg = substr(File::Spec->splitpath(__FILE__), 0, -2)
}

use Test::Is $arg;

use Test::More tests => 1;
pass "$arg test";
