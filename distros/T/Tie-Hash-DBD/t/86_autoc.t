#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

require "./t/autoc.pl";

autoctests ("Firebird", 86);

done_testing;
