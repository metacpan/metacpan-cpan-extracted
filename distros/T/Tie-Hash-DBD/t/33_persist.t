#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

require "./t/persist.pl";

persisttests ("Pg", 33);

done_testing;
