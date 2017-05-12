#!perl -T

use strict;
use warnings;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use Test::Leaner;

plan skip_all => 'testing plan skip_all';

die 'should not be reached';
