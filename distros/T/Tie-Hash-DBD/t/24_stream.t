#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

require "./t/streamtest.pl";

streamtests ("SQLite");

done_testing;
