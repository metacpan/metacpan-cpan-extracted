#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

require "./t/persist.pl";

persisttests ("Oracle", 63);

done_testing;
