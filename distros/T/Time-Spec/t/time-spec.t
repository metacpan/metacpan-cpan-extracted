#! perl

use strict;
use warnings;

use Test::More;

use Time::Spec;

my $spec1 = Time::Spec->new(3.6);
is $spec1->sec, 3;
is $spec1->nsec, 600000000;
is $spec1->to_float, 3.6;
is $spec1 + 1, 4.6;

my $spec2 = Time::Spec->new(3600);
is $spec2->sec, 3600;
is $spec2->nsec, 0;

done_testing;
