#!perl

use strict;
use warnings;

use Test::Synopsis::Expectation;

Test::Synopsis::Expectation::set_ignorings(['done_testing;']);
all_synopsis_ok;

done_testing;
