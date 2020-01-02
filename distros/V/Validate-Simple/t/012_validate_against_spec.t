use strict;
use warnings;

use Test::More;

my @tests = (
    {
        name  => "Bad params",
        specs => {
            foo => {
                type => 'any'
            }
        },
        params => [
            [ 1, 0 ],
        ],
    },
    {
        name => "Required params",
        specs => {
            foo => {
                type => 'any',
                required => 1,
            },
        },
        params => [
            [ { foo => 1 }, 1 ],
            [ { bar => 1 }, 0 ],
        ],
    },
    {
        name => "Not required",
        specs => {
            foo => {
                type => 'any',
                required => 1
            },
            bar => {
                type => 'any'
            },
        },
        params => [
            [ { foo => 1 }, 1 ],
        ],
    },
    {
        name => "Unknown params",
        specs => {
            foo => {
                type => 'any',
                required => 1,
            },
        },
        params => [
            [ { foo => 1 }, 1 ],
            [ {
                foo => 1,
                bar => 1 }, 0 ],
        ],
    },
    {
        name => 'Any',
        specs => {
            any => {
                type => 'any',
            },
        },
        params => [
            [ { any => 1 },          1 ],
            [ { any => 'text' },     1 ],
            [ { any => undef },      1 ],
            [ { any => [] },         1 ],
            [ { any => {} },         1 ],
            [ { any => sub { 1; } }, 1 ],
        ],
    },
    {
        name => 'Number',
        specs => {
            num => {
                type => 'number',
            },
            num_gt5 => {
                type => 'number',
                gt   => 5,
            },
            num_ge5 => {
                type => 'number',
                ge   => 5,
            },
            num_lt5 => {
                type => 'number',
                lt   => 5,
            },
            num_le5 => {
                type => 'number',
                le   => 5,
            },
        },
        params => [
            # Number
            [ { num => 10 },     1 ],
            [ { num => 5 },      1 ],
            [ { num => '-10'},   1 ],
            [ { num => 'text' }, 0 ],
            [ { num => undef },  0 ],
            [ { num => [] },     0 ],
            # Number greater than
            [ { num_gt5 => 10 },     1 ],
            [ { num_gt5 => 5 },      0 ],
            [ { num_gt5 => '-10'},   0 ],
            [ { num_gt5 => 'text' }, 0 ],
            [ { num_gt5 => undef },  0 ],
            [ { num_gt5 => [] },     0 ],
            # Number greater or equal
            [ { num_ge5 => 10 },     1 ],
            [ { num_ge5 => 5 },      1 ],
            [ { num_ge5 => '-10'},   0 ],
            [ { num_ge5 => 'text' }, 0 ],
            [ { num_ge5 => undef },  0 ],
            [ { num_ge5 => [] },     0 ],
            # Number less than
            [ { num_lt5 => 10 },     0 ],
            [ { num_lt5 => 5 },      0 ],
            [ { num_lt5 => '-10'},   1 ],
            [ { num_lt5 => 'text' }, 0 ],
            [ { num_lt5 => undef },  0 ],
            [ { num_lt5 => [] },     0 ],
            # Number less or equal
            [ { num_le5 => 10 },     0 ],
            [ { num_le5 => 5 },      1 ],
            [ { num_le5 => '-10'},   1 ],
            [ { num_le5 => 'text' }, 0 ],
            [ { num_le5 => undef },  0 ],
            [ { num_le5 => [] },     0 ],
        ],
    },
    {
        name => 'Positive',
        specs => {
            pos => {
                type => 'positive',
            },
            pos_gt5 => {
                type => 'positive',
                gt   => 5,
            },
            pos_ge5 => {
                type => 'positive',
                ge   => 5,
            },
            pos_lt5 => {
                type => 'positive',
                lt   => 5,
            },
            pos_le5 => {
                type => 'positive',
                le   => 5,
            },
        },
        params => [
            # Positive
            [ { pos => 10 },     1 ],
            [ { pos => 5 },      1 ],
            [ { pos => '-10'},   0 ],
            [ { pos => 'text' }, 0 ],
            [ { pos => undef },  0 ],
            [ { pos => [] },     0 ],
            # Positive greater than
            [ { pos_gt5 => 10 },     1 ],
            [ { pos_gt5 => 5 },      0 ],
            [ { pos_gt5 => '-10'},   0 ],
            [ { pos_gt5 => 'text' }, 0 ],
            [ { pos_gt5 => undef },  0 ],
            [ { pos_gt5 => [] },     0 ],
            # Positive greater or equal
            [ { pos_ge5 => 10 },     1 ],
            [ { pos_ge5 => 5 },      1 ],
            [ { pos_ge5 => '-10'},   0 ],
            [ { pos_ge5 => 'text' }, 0 ],
            [ { pos_ge5 => undef },  0 ],
            [ { pos_ge5 => [] },     0 ],
            # Positive less than
            [ { pos_lt5 => 10 },     0 ],
            [ { pos_lt5 => 5 },      0 ],
            [ { pos_lt5 => 1 },      1 ],
            [ { pos_lt5 => 0 },      0 ],
            [ { pos_lt5 => '-10'},   0 ],
            [ { pos_lt5 => 'text' }, 0 ],
            [ { pos_lt5 => undef },  0 ],
            [ { pos_lt5 => [] },     0 ],
            # Positive less or equal
            [ { pos_le5 => 10 },     0 ],
            [ { pos_le5 => 5 },      1 ],
            [ { pos_le5 => 1 },      1 ],
            [ { pos_le5 => 0 },      0 ],
            [ { pos_le5 => '-10'},   0 ],
            [ { pos_le5 => 'text' }, 0 ],
            [ { pos_le5 => undef },  0 ],
            [ { pos_le5 => [] },     0 ],
        ],
    },
    {
        name => 'Non-negative',
        specs => {
            nn => {
                type => 'non_negative',
            },
            nn_gt5 => {
                type => 'non_negative',
                gt   => 5,
            },
            nn_ge5 => {
                type => 'non_negative',
                ge   => 5,
            },
            nn_lt5 => {
                type => 'non_negative',
                lt   => 5,
            },
            nn_le5 => {
                type => 'non_negative',
                le   => 5,
            },
        },
        params => [
            # Non-negative
            [ { nn => 10 },     1 ],
            [ { nn => 5 },      1 ],
            [ { nn => 0 },      1 ],
            [ { nn => '-10'},   0 ],
            [ { nn => 'text' }, 0 ],
            [ { nn => undef },  0 ],
            [ { nn => [] },     0 ],
            # Non-negative greater than
            [ { nn_gt5 => 10 },     1 ],
            [ { nn_gt5 => 5 },      0 ],
            [ { nn_gt5 => 0 },      0 ],
            [ { nn_gt5 => '-10'},   0 ],
            [ { nn_gt5 => 'text' }, 0 ],
            [ { nn_gt5 => undef },  0 ],
            [ { nn_gt5 => [] },     0 ],
            # Non-negative greater or equal
            [ { nn_ge5 => 10 },     1 ],
            [ { nn_ge5 => 5 },      1 ],
            [ { nn_ge5 => 0 },      0 ],
            [ { nn_ge5 => '-10'},   0 ],
            [ { nn_ge5 => 'text' }, 0 ],
            [ { nn_ge5 => undef },  0 ],
            [ { nn_ge5 => [] },     0 ],
            # Non-negative less than
            [ { nn_lt5 => 10 },     0 ],
            [ { nn_lt5 => 5 },      0 ],
            [ { nn_lt5 => 1 },      1 ],
            [ { nn_lt5 => 0 },      1 ],
            [ { nn_lt5 => '-10'},   0 ],
            [ { nn_lt5 => 'text' }, 0 ],
            [ { nn_lt5 => undef },  0 ],
            [ { nn_lt5 => [] },     0 ],
            # Non-negative less or equal
            [ { nn_le5 => 10 },     0 ],
            [ { nn_le5 => 5 },      1 ],
            [ { nn_le5 => 1 },      1 ],
            [ { nn_le5 => 0 },      1 ],
            [ { nn_le5 => '-10'},   0 ],
            [ { nn_le5 => 'text' }, 0 ],
            [ { nn_le5 => undef },  0 ],
            [ { nn_le5 => [] },     0 ],
        ],
    },
    {
        name => 'Negative',
        specs => {
            neg => {
                type => 'negative',
            },
            neg_gt5 => {
                type => 'negative',
                gt   => -5,
            },
            neg_ge5 => {
                type => 'negative',
                ge   => -5,
            },
            neg_lt5 => {
                type => 'negative',
                lt   => -5,
            },
            neg_le5 => {
                type => 'negative',
                le   => -5,
            },
        },
        params => [
            # Negative
            [ { neg => 10 },     0 ],
            [ { neg => -3 },     1 ],
            [ { neg => 0 },      0 ],
            [ { neg => '-5'},    1 ],
            [ { neg => 'text' }, 0 ],
            [ { neg => undef },  0 ],
            [ { neg => [] },     0 ],
            # Negative greater than
            [ { neg_gt5 => 10 },     0 ],
            [ { neg_gt5 => -3 },     1 ],
            [ { neg_gt5 => 0 },      0 ],
            [ { neg_gt5 => '-5'},    0 ],
            [ { neg_gt5 => 'text' }, 0 ],
            [ { neg_gt5 => undef },  0 ],
            [ { neg_gt5 => [] },     0 ],
            # Negative greater or equal
            [ { neg_ge5 => 10 },     0 ],
            [ { neg_ge5 => -3 },     1 ],
            [ { neg_ge5 => 0 },      0 ],
            [ { neg_ge5 => '-5'},    1 ],
            [ { neg_ge5 => 'text' }, 0 ],
            [ { neg_ge5 => undef },  0 ],
            [ { neg_ge5 => [] },     0 ],
            # Negative less than
            [ { neg_lt5 => 10 },     0 ],
            [ { neg_lt5 => -3 },     0 ],
            [ { neg_lt5 => 0 },      0 ],
            [ { neg_lt5 => '-5'},    0 ],
            [ { neg_lt5 => -10},     1 ],
            [ { neg_lt5 => 'text' }, 0 ],
            [ { neg_lt5 => undef },  0 ],
            [ { neg_lt5 => [] },     0 ],
            # Negative less or equal
            [ { neg_le5 => 10 },     0 ],
            [ { neg_le5 => -3 },     0 ],
            [ { neg_le5 => 0 },      0 ],
            [ { neg_le5 => '-5'},    1 ],
            [ { neg_le5 => -10},     1 ],
            [ { neg_le5 => 'text' }, 0 ],
            [ { neg_le5 => undef },  0 ],
            [ { neg_le5 => [] },     0 ],
        ],
    },
    {
        name => 'Non-positive',
        specs => {
            np => {
                type => 'non_positive',
            },
            np_gt5 => {
                type => 'non_positive',
                gt   => -5,
            },
            np_ge5 => {
                type => 'non_positive',
                ge   => -5,
            },
            np_lt5 => {
                type => 'non_positive',
                lt   => -5,
            },
            np_le5 => {
                type => 'non_positive',
                le   => -5,
            },
        },
        params => [
            # Non-positive
            [ { np => 10 },     0 ],
            [ { np => -3 },     1 ],
            [ { np => 0 },      1 ],
            [ { np => '-5'},    1 ],
            [ { np => 'text' }, 0 ],
            [ { np => undef },  0 ],
            [ { np => [] },     0 ],
            # Non-positive greater than
            [ { np_gt5 => 10 },     0 ],
            [ { np_gt5 => -3 },     1 ],
            [ { np_gt5 => 0 },      1 ],
            [ { np_gt5 => '-5'},    0 ],
            [ { np_gt5 => 'text' }, 0 ],
            [ { np_gt5 => undef },  0 ],
            [ { np_gt5 => [] },     0 ],
            # Non-positive greater or equal
            [ { np_ge5 => 10 },     0 ],
            [ { np_ge5 => -3 },     1 ],
            [ { np_ge5 => 0 },      1 ],
            [ { np_ge5 => '-5'},    1 ],
            [ { np_ge5 => 'text' }, 0 ],
            [ { np_ge5 => undef },  0 ],
            [ { np_ge5 => [] },     0 ],
            # Non-positive less than
            [ { np_lt5 => 10 },     0 ],
            [ { np_lt5 => -3 },     0 ],
            [ { np_lt5 => 0 },      0 ],
            [ { np_lt5 => '-5'},    0 ],
            [ { np_lt5 => -10},     1 ],
            [ { np_lt5 => 'text' }, 0 ],
            [ { np_lt5 => undef },  0 ],
            [ { np_lt5 => [] },     0 ],
            # Non-positive less or equal
            [ { np_le5 => 10 },     0 ],
            [ { np_le5 => -3 },     0 ],
            [ { np_le5 => 0 },      0 ],
            [ { np_le5 => '-5'},    1 ],
            [ { np_le5 => -10},     1 ],
            [ { np_le5 => 'text' }, 0 ],
            [ { np_le5 => undef },  0 ],
            [ { np_le5 => [] },     0 ],
        ],
    },
    {
        name => 'Integer',
        specs => {
            int => {
                type => 'integer',
            },
            int_gt5 => {
                type => 'integer',
                gt   => 5,
            },
            int_ge5 => {
                type => 'integer',
                ge   => 5,
            },
            int_lt5 => {
                type => 'integer',
                lt   => 5,
            },
            int_le5 => {
                type => 'integer',
                le   => 5,
            },
        },
        params => [
            # Integer
            [ { int => 10 },     1 ],
            [ { int => 3.14 },   0 ],
            [ { int => 5 },      1 ],
            [ { int => '-10'},   1 ],
            [ { int => 'text' }, 0 ],
            [ { int => undef },  0 ],
            [ { int => [] },     0 ],
            # Integer greater than
            [ { int_gt5 => 10 },     1 ],
            [ { int_gt5 => 3.14 },   0 ],
            [ { int_gt5 => 5 },      0 ],
            [ { int_gt5 => '-10'},   0 ],
            [ { int_gt5 => 'text' }, 0 ],
            [ { int_gt5 => undef },  0 ],
            [ { int_gt5 => [] },     0 ],
            # Integer greater or equal
            [ { int_ge5 => 10 },     1 ],
            [ { int_ge5 => 3.14 },   0 ],
            [ { int_ge5 => 5 },      1 ],
            [ { int_ge5 => '-10'},   0 ],
            [ { int_ge5 => 'text' }, 0 ],
            [ { int_ge5 => undef },  0 ],
            [ { int_ge5 => [] },     0 ],
            # Integer less than
            [ { int_lt5 => 10 },     0 ],
            [ { int_lt5 => 3.14 },   0 ],
            [ { int_lt5 => 5 },      0 ],
            [ { int_lt5 => '-10'},   1 ],
            [ { int_lt5 => 'text' }, 0 ],
            [ { int_lt5 => undef },  0 ],
            [ { int_lt5 => [] },     0 ],
            # Integer less or equal
            [ { int_le5 => 10 },     0 ],
            [ { int_le5 => 3.14 },   0 ],
            [ { int_le5 => 5 },      1 ],
            [ { int_le5 => '-10'},   1 ],
            [ { int_le5 => 'text' }, 0 ],
            [ { int_le5 => undef },  0 ],
            [ { int_le5 => [] },     0 ],
        ],
    },
    {
        name => 'Positive Int',
        specs => {
            pin => {
                type => 'positive_int',
            },
            pin_gt5 =>{
                type => 'positive_int',
                gt   => 5,
            },
            pin_ge5 => {
                type => 'positive_int',
                ge   => 5,
            },
            pin_lt5 => {
                type => 'positive_int',
                lt   => 5,
            },
            pin_le5 => {
                type => 'positive_int',
                le   => 5,
            },
        },
        params => [
            # Positive integer
            [ { pin => 10 },     1 ],
            [ { pin =>  0 },     0 ],
            [ { pin => 3.14 },   0 ],
            [ { pin => 5 },      1 ],
            [ { pin => '-10'},   0 ],
            [ { pin => 'text' }, 0 ],
            [ { pin => undef },  0 ],
            [ { pin => [] },     0 ],
            # Positive integer greater than
            [ { pin_gt5 => 10 },     1 ],
            [ { pin_gt5 => 3.14 },   0 ],
            [ { pin_gt5 => 5 },      0 ],
            [ { pin_gt5 => '-10'},   0 ],
            [ { pin_gt5 => 'text' }, 0 ],
            [ { pin_gt5 => undef },  0 ],
            [ { pin_gt5 => [] },     0 ],
            # Positive integer greater or equal
            [ { pin_ge5 => 10 },     1 ],
            [ { pin_ge5 => 3.14 },   0 ],
            [ { pin_ge5 => 5 },      1 ],
            [ { pin_ge5 => '-10'},   0 ],
            [ { pin_ge5 => 'text' }, 0 ],
            [ { pin_ge5 => undef },  0 ],
            [ { pin_ge5 => [] },     0 ],
            # Positive integer less than
            [ { pin_lt5 => 10 },     0 ],
            [ { pin_lt5 => 3.14 },   0 ],
            [ { pin_lt5 => 3 },      1 ],
            [ { pin_lt5 => 5 },      0 ],
            [ { pin_lt5 => '-10'},   0 ],
            [ { pin_lt5 => 'text' }, 0 ],
            [ { pin_lt5 => undef },  0 ],
            [ { pin_lt5 => [] },     0 ],
            # Positive integer less or equal
            [ { pin_le5 => 10 },     0 ],
            [ { pin_le5 => 3.14 },   0 ],
            [ { pin_le5 => 5 },      1 ],
            [ { pin_le5 => '-10'},   0 ],
            [ { pin_le5 => 'text' }, 0 ],
            [ { pin_le5 => undef },  0 ],
            [ { pin_le5 => [] },     0 ],
        ],
    },
    {
        name => 'Non-negative Int',
        specs => {
            nni => {
                type => 'non_negative_int',
            },
            nni_gt5 =>{
                type => 'non_negative_int',
                gt   => 5,
            },
            nni_ge5 => {
                type => 'non_negative_int',
                ge   => 5,
            },
            nni_lt5 => {
                type => 'non_negative_int',
                lt   => 5,
            },
            nni_le5 => {
                type => 'non_negative_int',
                le   => 5,
            },
        },
        params => [
            # Non-negative integer
            [ { nni => 10 },     1 ],
            [ { nni =>  0 },     1 ],
            [ { nni => 3.14 },   0 ],
            [ { nni => 5 },      1 ],
            [ { nni => '-10'},   0 ],
            [ { nni => 'text' }, 0 ],
            [ { nni => undef },  0 ],
            [ { nni => [] },     0 ],
            # Non-negative integer greater than
            [ { nni_gt5 => 10 },     1 ],
            [ { nni_gt5 => 3.14 },   0 ],
            [ { nni_gt5 => 5 },      0 ],
            [ { nni_gt5 => '-10'},   0 ],
            [ { nni_gt5 => 'text' }, 0 ],
            [ { nni_gt5 => undef },  0 ],
            [ { nni_gt5 => [] },     0 ],
            # Non-negative integer greater or equal
            [ { nni_ge5 => 10 },     1 ],
            [ { nni_ge5 => 3.14 },   0 ],
            [ { nni_ge5 => 5 },      1 ],
            [ { nni_ge5 => '-10'},   0 ],
            [ { nni_ge5 => 'text' }, 0 ],
            [ { nni_ge5 => undef },  0 ],
            [ { nni_ge5 => [] },     0 ],
            # Non-negative integer less than
            [ { nni_lt5 => 10 },     0 ],
            [ { nni_lt5 =>  0 },     1 ],
            [ { nni_lt5 => 3.14 },   0 ],
            [ { nni_lt5 => 3 },      1 ],
            [ { nni_lt5 => 5 },      0 ],
            [ { nni_lt5 => '-10'},   0 ],
            [ { nni_lt5 => 'text' }, 0 ],
            [ { nni_lt5 => undef },  0 ],
            [ { nni_lt5 => [] },     0 ],
            # Non-negative integer less or equal
            [ { nni_le5 => 10 },     0 ],
            [ { nni_le5 => 3.14 },   0 ],
            [ { nni_le5 => 5 },      1 ],
            [ { nni_le5 => '-10'},   0 ],
            [ { nni_le5 => 'text' }, 0 ],
            [ { nni_le5 => undef },  0 ],
            [ { nni_le5 => [] },     0 ],
        ],
    },
    {
        name => 'Negative Int',
        specs => {
            nin => {
                type => 'negative_int',
            },
            nin_gt5 =>{
                type => 'negative_int',
                gt   => -5,
            },
            nin_ge5 => {
                type => 'negative_int',
                ge   => -5,
            },
            nin_lt5 => {
                type => 'negative_int',
                lt   => -5,
            },
            nin_le5 => {
                type => 'negative_int',
                le   => -5,
            },
        },
        params => [
            # Negative integer
            [ { nin => 10 },     0 ],
            [ { nin =>  0 },     0 ],
            [ { nin => 3.14 },   0 ],
            [ { nin => -5 },     1 ],
            [ { nin => '-10'},   1 ],
            [ { nin => 'text' }, 0 ],
            [ { nin => undef },  0 ],
            [ { nin => [] },     0 ],
            # Negative integer greater than
            [ { nin_gt5 => 10 },     0 ],
            [ { nin_gt5 =>  0 },     0 ],
            [ { nin_gt5 => 3.14 },   0 ],
            [ { nin_gt5 => -5 },     0 ],
            [ { nin_gt5 => -3 },     1 ],
            [ { nin_gt5 => '-10'},   0 ],
            [ { nin_gt5 => 'text' }, 0 ],
            [ { nin_gt5 => undef },  0 ],
            [ { nin_gt5 => [] },     0 ],
            # Negative integer greater or equal
            [ { nin_ge5 => 10 },     0 ],
            [ { nin_ge5 =>  0 },     0 ],
            [ { nin_ge5 => 3.14 },   0 ],
            [ { nin_ge5 => -5 },     1 ],
            [ { nin_ge5 => -3 },     1 ],
            [ { nin_ge5 => '-10'},   0 ],
            [ { nin_ge5 => 'text' }, 0 ],
            [ { nin_ge5 => undef },  0 ],
            [ { nin_ge5 => [] },     0 ],
            # Negative integer less than
            [ { nin_lt5 => 10 },     0 ],
            [ { nin_lt5 =>  0 },     0 ],
            [ { nin_lt5 => 3.14 },   0 ],
            [ { nin_lt5 => -5 },     0 ],
            [ { nin_lt5 => -3 },     0 ],
            [ { nin_lt5 => '-10'},   1 ],
            [ { nin_lt5 => 'text' }, 0 ],
            [ { nin_lt5 => undef },  0 ],
            [ { nin_lt5 => [] },     0 ],
            # Negative integer less or equal
            [ { nin_le5 => 10 },     0 ],
            [ { nin_le5 =>  0 },     0 ],
            [ { nin_le5 => 3.14 },   0 ],
            [ { nin_le5 => -5 },     1 ],
            [ { nin_le5 => -3 },     0 ],
            [ { nin_le5 => '-10'},   1 ],
            [ { nin_le5 => 'text' }, 0 ],
            [ { nin_le5 => undef },  0 ],
            [ { nin_le5 => [] },     0 ],
        ],
    },
    {
        name => 'Non-positive Int',
        specs => {
            npi => {
                type => 'non_positive_int',
            },
            npi_gt5 =>{
                type => 'non_positive_int',
                gt   => -5,
            },
            npi_ge5 => {
                type => 'non_positive_int',
                ge   => -5,
            },
            npi_lt5 => {
                type => 'non_positive_int',
                lt   => -5,
            },
            npi_le5 => {
                type => 'non_positive_int',
                le   => -5,
            },
        },
        params => [
            # Non-positive integer
            [ { npi => 10 },     0 ],
            [ { npi =>  0 },     1 ],
            [ { npi => 3.14 },   0 ],
            [ { npi => -5 },     1 ],
            [ { npi => '-10'},   1 ],
            [ { npi => 'text' }, 0 ],
            [ { npi => undef },  0 ],
            [ { npi => [] },     0 ],
            # Non-positive integer greater than
            [ { npi_gt5 => 10 },     0 ],
            [ { npi_gt5 =>  0 },     1 ],
            [ { npi_gt5 => 3.14 },   0 ],
            [ { npi_gt5 => -5 },     0 ],
            [ { npi_gt5 => -3 },     1 ],
            [ { npi_gt5 => '-10'},   0 ],
            [ { npi_gt5 => 'text' }, 0 ],
            [ { npi_gt5 => undef },  0 ],
            [ { npi_gt5 => [] },     0 ],
            # Non-positive integer greater or equal
            [ { npi_ge5 => 10 },     0 ],
            [ { npi_ge5 =>  0 },     1 ],
            [ { npi_ge5 => 3.14 },   0 ],
            [ { npi_ge5 => -5 },     1 ],
            [ { npi_ge5 => -3 },     1 ],
            [ { npi_ge5 => '-10'},   0 ],
            [ { npi_ge5 => 'text' }, 0 ],
            [ { npi_ge5 => undef },  0 ],
            [ { npi_ge5 => [] },     0 ],
            # Non-positive integer less than
            [ { npi_lt5 => 10 },     0 ],
            [ { npi_lt5 =>  0 },     0 ],
            [ { npi_lt5 => 3.14 },   0 ],
            [ { npi_lt5 => -5 },     0 ],
            [ { npi_lt5 => -3 },     0 ],
            [ { npi_lt5 => '-10'},   1 ],
            [ { npi_lt5 => 'text' }, 0 ],
            [ { npi_lt5 => undef },  0 ],
            [ { npi_lt5 => [] },     0 ],
            # Non-positive integer less or equal
            [ { npi_le5 => 10 },     0 ],
            [ { npi_le5 =>  0 },     0 ],
            [ { npi_le5 => 3.14 },   0 ],
            [ { npi_le5 => -5 },     1 ],
            [ { npi_le5 => -3 },     0 ],
            [ { npi_le5 => '-10'},   1 ],
            [ { npi_le5 => 'text' }, 0 ],
            [ { npi_le5 => undef },  0 ],
            [ { npi_le5 => [] },     0 ],
        ],
    },
    {
        name => 'String',
        specs => {
            str => {
                type => 'string',
            },
            str_min => {
                type => 'string',
                min_length => 2,
            },
            str_max => {
                type => 'string',
                max_length => 2,
            },
        },
        params => [
            # String
            [ { str => 'text' }, 1 ],
            [ { str => '' },     1 ],
            [ { str => 5 },      1 ],
            [ { str => undef },  0 ],
            [ { str => {} },     0 ],
            # String min length
            [ { str_min => 'text' }, 1 ],
            [ { str_min => '' },     0 ],
            [ { str_min => 5 },      0 ],
            [ { str_min => 500 },    1 ],
            [ { str_min => undef },  0 ],
            [ { str_min => {} },     0 ],
            # String max length
            [ { str_max => 'text' }, 0 ],
            [ { str_max => '' },     1 ],
            [ { str_max => 5 },      1 ],
            [ { str_max => 500 },    0 ],
            [ { str_max => undef },  0 ],
            [ { str_max => {} },     0 ],
        ],
    },
    {
        name => 'Maybe string',
        specs => {
            str => {
                type => 'string',
                undef => 1,
            },
            str_min => {
                type => 'string',
                min_length => 2,
                undef => 1,
            },
            str_max => {
                type => 'string',
                max_length => 2,
                undef => 1,
            },
        },
        params => [
            # Maybe string
            [ { str => 'text' }, 1 ],
            [ { str => '' },     1 ],
            [ { str => 5 },      1 ],
            [ { str => undef },  1 ],
            [ { str => {} },     0 ],
            # Maybe string min length
            [ { str_min => 'text' }, 1 ],
            [ { str_min => '' },     0 ],
            [ { str_min => 5 },      0 ],
            [ { str_min => 500 },    1 ],
            [ { str_min => undef },  1 ],
            [ { str_min => {} },     0 ],
            # Maybe string max length
            [ { str_max => 'text' }, 0 ],
            [ { str_max => '' },     1 ],
            [ { str_max => 5 },      1 ],
            [ { str_max => 500 },    0 ],
            [ { str_max => undef },  1 ],
            [ { str_max => {} },     0 ],
        ],
    },
    {
        name => 'Array',
        specs => {
            arr => {
                type => 'array',
                of   => {
                    type => 'any',
                },
            },
            arr_num => {
                type => 'array',
                of   => {
                    type => 'number',
                },
            },
            arr_empty => {
                type => 'array',
                of   => {
                    type => 'any',
                },
                empty => 1,
            },
            arr_of_arr => {
                type => 'array',
                of => {
                    type => 'array',
                    of => {
                        type => 'number',
                    },
                },
            }
        },
        params => [
            # Array
            [ { arr => [] },             0 ],
            [ { arr => [ 1..5 ] },       1 ],
            [ { arr => [ qw/1 2 3/ ] },  1 ],
            [ { arr => 1 },              0 ],
            [ { arr => {} },             0 ],
            [ { arr => sub { [ 1 ]; } }, 0 ],
            # Array of type
            [ { arr_num => [] },             0 ],
            [ { arr_num => [ 1..5 ] },       1 ],
            [ { arr_num => [ qw/1 2 3/ ] },  1 ],
            [ { arr_num => 1 },              0 ],
            [ { arr_num => {} },             0 ],
            [ { arr_num => sub { [ 1 ]; } }, 0 ],
            # Array empty
            [ { arr_empty => [] },             1 ],
            [ { arr_empty => [ 1..5 ] },       1 ],
            [ { arr_empty => [ qw/1 2 3/ ] },  1 ],
            [ { arr_empty => 1 },              0 ],
            [ { arr_empty => {} },             0 ],
            [ { arr_empty => sub { [ 1 ]; } }, 0 ],
            # Array of array
            [ { arr_of_arr => [] },             0 ],
            [ { arr_of_arr => [ [1..5 ] ] },    1 ],
            [ { arr_of_arr => [ [qw/a b/ ]] },  0 ],
            [ { arr_of_arr => 1 },              0 ],
            [ { arr_of_arr => [ [] ] },         0 ],
            [ { arr_of_arr => sub { [ 1 ]; } }, 0 ],
        ],
    },
    {
        name => 'Hash',
        specs => {
            hash => {
                type => 'hash',
                of => {
                    type => 'any',
                },
            },
            hash_num => {
                type => 'hash',
                of => {
                    type => 'number',
                },
            },
            hash_empty => {
                type => 'hash',
                of => {
                    type => 'any',
                },
                empty => 1,
            },
            hash_of_hash => {
                type => 'hash',
                of => {
                    type => 'hash',
                    of => {
                        type => 'any'
                    },
                    empty => 1,
                },
            },
        },
        params => [
            # Hash
            [ { hash => [] },             0 ],
            [ { hash => { 1 => 5 } },     1 ],
            [ { hash => [ qw/1 2 3/ ] },  0 ],
            [ { hash => 1 },              0 ],
            [ { hash => {} },             0 ],
            [ { hash => sub { {5=>6};} }, 0 ],
            # Hash of type
            [ { hash_num => [] },             0 ],
            [ { hash_num => { 1 => 5 } },     1 ],
            [ { hash_num => [ qw/1 2 3/ ] },  0 ],
            [ { hash_num => 1 },              0 ],
            [ { hash_num => {1=>'q'} },       0 ],
            [ { hash_num => sub { {5=>6};} }, 0 ],
            # Hash empty
            [ { hash_empty => [] },             0 ],
            [ { hash_empty => { 1 => 5 } },     1 ],
            [ { hash_empty => [ qw/1 2 3/ ] },  0 ],
            [ { hash_empty => 1 },              0 ],
            [ { hash_empty => {} },             1 ],
            [ { hash_empty => sub { {5=>6};} }, 0 ],
            # Hash of hash
            [ { hash_of_hash => { 1 => 5 } },     0 ],
            [ { hash_of_hash => { 1=>{2=>3} } },  1 ],
            [ { hash_of_hash => [ qw/1 2 3/ ] },  0 ],
            [ { hash_of_hash => 1 },              0 ],
            [ { hash_of_hash => { 4=>{} } },      1 ],
        ],
    },
    {
        name => 'Enum',
        specs => {
            enum_var => {
                type => 'enum',
                values => [ 1..5 ],
            },
        },
        params => [
            [ { enum_var => 1 },          1 ],
            [ { enum_var => '2' },        1 ],
            [ { enum_var => [] },         0 ],
            [ { enum_var => {} },         0 ],
            [ { enum_var => sub { 3; } }, 0 ],
        ],
    },
    {
        name => 'Callback',
        specs => {
            number => {
                type => 'number',
                callback => sub { $_[0] > -10 },
            },
            array => {
                type => 'array',
                of => {
                    type => 'any',
                },
                callback => sub { @{ $_[0] } < 5 }
            },
            enum => {
                type => 'enum',
                values => [ qw/ yes no / ],
                undef => 1,
            },
        },
        params => [
            # Number
            [ { number => 'string' },    0 ],
            [ { number => 10 },          1 ],
            [ { number => -100 },        0 ],
            [ { number => sub { 10; } }, 0 ],
            [ { number => undef },       0 ],
            # Array
            [ { array => 1 },                 0 ],
            [ { array => [ 1..3 ] },          1 ],
            [ { array => [ 1..5 ] },          0 ],
            [ { array => sub { [ 1..10 ] } }, 0 ],
            [ { array => [] },                0 ],
            # Enum
            [ { enum => 1 },            0 ],
            [ { enum => 'yes' },        1 ],
            [ { enum => [] },           0 ],
            [ { enum => undef },        1 ],
            [ { enum => sub { 'no' } }, 0 ],
        ],
    },
);

my $test_count = 0;
for my $test ( @tests ) {
    $test_count += scalar ( @{ $test->{params} } );
}

plan tests =>
    1              # Use the class
    + 1            # Create an object
    + 4            # Validate with empty params
    + 3 * $test_count;  # Various validations

use_ok( 'Validate::Simple' );
my $validate = new_ok( 'Validate::Simple' );

ok( !$validate->validate(),          "Empty params" );
ok( !$validate->validate(undef),     "Empty params" );
ok( !$validate->validate({}),        "Empty specs" );
ok( !$validate->validate({}, undef), "Empty specs" );



for my $test ( @tests ) {
    my $specs = $test->{specs};
    my $name  = $test->{name};
    for my $par ( @{ $test->{params} } ) {
        my ( $params, $expected_true ) = @$par;
        # Test pass specs to validate() method
        if ( $expected_true ) {
            ok( $validate->validate( $params, $specs ),
                "Validation '$name': Passed as expected"
                    . " - "
                    . join(';', $validate->delete_errors())
                );
        }
        else {
            ok( !$validate->validate( $params, $specs ),
                "Validation '$name': Did not pass as expected"
                    . " - "
                    . join(';', $validate->delete_errors())
                );
        }

        # Create object with specs
        my $val = new_ok(
            'Validate::Simple' => [ $specs ],
            "Create object with specs '$name'" );

        # Validate against object specs
        if ( $expected_true ) {
            ok( $val->validate( $params ),
                "Validation again '$name': Passed as expected"
                    . " - "
                    . join(';', $val->errors() )
                );
        }
        else {
            ok( !$val->validate( $params ),
                "Validation again '$name': Did not passed as expected"
                    . " - "
                    . join(';', $val->errors() )
                );
        }
    }
}

1;
