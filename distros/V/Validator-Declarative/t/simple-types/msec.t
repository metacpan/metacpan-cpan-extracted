#!/usr/bin/env perl

use strict;
use warnings;

use Test::Validator::Declarative qw/ check_type_validation /;

check_type_validation(
    type       => 'msec',
    aliased_to => 'timestamp',
    good       => [ 0, 1, 0.1, 123.456e10, '0', '1.00', '0.1' ],
    bad        => [
        '',               # empty string
        'some string',    # arbitrary string
        v5.10.2,          # v-string
        '15-0.8',         # expressions should be not evaluated
        sub { return 'TRUE' },    # coderef
        -1, -0.1, '-1.00', '-0.1'
    ],
);

