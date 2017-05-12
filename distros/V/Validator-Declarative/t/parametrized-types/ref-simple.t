#!/usr/bin/env perl

use strict;
use warnings;

use Test::Validator::Declarative qw/ check_type_validation /;

check_type_validation(
    type => 'ref',
    good => [ \0, ['0.1'], { '-1.00', '-0.1' }, bless( [ -1, -10, -123.456e10 ], 'test' ), sub { return 'TRUE' }, ],
    bad  => [
        '',               # empty string
        'some string',    # arbitrary string
        v5.10.2,          # v-string
        '1.00', 100,
    ]
);

