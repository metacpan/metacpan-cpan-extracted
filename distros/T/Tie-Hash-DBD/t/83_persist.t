#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

require "./t/persist.pl";

persisttests ("Firebird", 83);

done_testing;
