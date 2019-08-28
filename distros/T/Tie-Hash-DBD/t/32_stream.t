#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

require "./t/streamtest.pl";

streamtests ("Pg", "Storable");

done_testing;
