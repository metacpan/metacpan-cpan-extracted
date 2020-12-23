#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

require "./t/autoc.pl";

autoctests ("Pg", 36);

done_testing;
