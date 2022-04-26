#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More 0.98;
use Test2::Tools::Exception qw/dies lives/;

BEGIN { use_ok('UK::Vehicle') };

done_testing;
