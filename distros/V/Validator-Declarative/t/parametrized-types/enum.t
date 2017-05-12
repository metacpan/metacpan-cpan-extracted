#!/usr/bin/env perl

use strict;
use warnings;

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
    type => {
        'enum' => [
            1, 100,
            sub { return ref( $_[0] ) eq 'VSTRING' },
            qr/Class/,
            't1', 't4',
        ]
    },
    aliased_to => 'any_of',
    good       => [
        '1.00', 1, 100,
        \v5.10.2,    # ref to v-string
        ( map { ref( bless( [undef], $_ ) ) } qw/ ClassOne ClassTwo ClassThree ClassFour / ),
        't1', 't4',
    ],
    bad => [
        '',               # empty string
        'some string',    # arbitrary string
        sub { return 'TRUE' },
        bless( [ -1, -10, -123.456e10 ], 'test' ),
        11, 1001,
        \0, ['0.1'], { '-1.00', '-0.1' },
        qw/ classone classtwo classthree classfour /,
        't2', 't3',
    ]
);

