#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test::Sah;

is_valid(1.1, "float");
is_invalid(1.1, "int");
done_testing;
