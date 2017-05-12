#!/usr/bin/env perl

use strict;
use warnings;

use Test::Validator::Declarative qw/ check_type_validation /;

my $min = 1970;
my $max = 3000;
check_type_validation(
    type => 'year',
    good => [ $min .. $max ],
    bad  => [
        -100 .. $min - 1,
        $max + 1 .. $max + 100,
        '',               # empty string
        'some string',    # arbitrary string
        v5.10.2,          # v-string
        sub { return 'TRUE' },    # coderef
        0, '1.00', '0.1', '-1.00', '-0.1', -1, -10, -123.456e10,
    ]
);

