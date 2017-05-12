#!perl -T

use strict;
use warnings;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use Test::Leaner;

plan tests => 2;

pass;
pass 'another one';

done_testing(2);
