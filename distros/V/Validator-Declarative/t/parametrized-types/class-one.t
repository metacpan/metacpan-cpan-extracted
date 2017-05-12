#!/usr/bin/env perl

use strict;
use warnings;
use lib './t/lib';

use Test::Validator::Declarative qw/ check_type_validation /;

{

    package ClassOne; sub t1 { }
}
{

    package ClassTwo; sub t2 { }
}
{

    package ClassThree; sub t3 { }
}
{

    package ClassFour; use base qw/ ClassOne /; sub t4 { }
}

check_type_validation(
    type => { 'class' => 'ClassOne' },
    good => [
        bless( [undef], 'ClassOne' ),
        bless( [undef], 'ClassFour' ),
    ],
    bad => [
        '',               # empty string
        'some string',    # arbitrary string
        v5.10.2,          # v-string
        '1.00', 100,
        \0, ['0.1'], { '-1.00', '-0.1' },
        sub { return 'TRUE' },
        bless( [ -1, -10, -123.456e10 ], 'test' ),
        bless( [undef], 'ClassTwo' ),
        bless( [undef], 'ClassThree' ),
    ]
);

