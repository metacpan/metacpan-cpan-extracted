#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

require "./t/autoc.pl";

autoctests ("MariaDB", 56);

done_testing;
