#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

require "./t/persist.pl";

persisttests ("SQLite", 23);

done_testing;
