#!perl -T

use strict;
use warnings;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use Test::Leaner 'no_plan';

pass;
