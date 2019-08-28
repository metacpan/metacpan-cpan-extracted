#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

require "./t/persist.pl";

persisttests ("CSV", 43);

done_testing;
