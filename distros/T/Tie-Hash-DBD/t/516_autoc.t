#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

require "./t/autoc.pl";

autoctests ("mysql", 56);

done_testing;
