#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

require "./t/autoc.pl";

autoctests ("SQLite", 26);

done_testing;
