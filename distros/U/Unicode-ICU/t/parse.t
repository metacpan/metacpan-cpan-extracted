#!/usr/bin/env perl

# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

# We traffic exclusively in UTF-8-encoded characters, so this makes sense.
use utf8;

use Test2::V0;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Explain;

use Unicode::ICU::MessagePattern ();
use Unicode::ICU::MessagePatternPart ();

if (!Unicode::ICU::MessagePattern->can('new')) {
    plan skip_all => sprintf('This ICU version (%s) can’t parse messages.', Unicode::ICU::ICU_VERSION);
}

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my @parses = (
    {
        pattern => "\x{1f60a} {0}",
        parse   => [
            {
                'arg_type' => 'NONE',
                'index'    => 0,
                'length'   => 0,
                'limit'    => 0,
                'type'     => 'MSG_START',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 2,
                'length'   => 1,
                'limit'    => 3,
                'type'     => 'ARG_START',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 3,
                'length'   => 1,
                'limit'    => 4,
                'type'     => 'ARG_NUMBER',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 4,
                'length'   => 1,
                'limit'    => 5,
                'type'     => 'ARG_LIMIT',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 5,
                'length'   => 0,
                'limit'    => 5,
                'type'     => 'MSG_LIMIT',
                'value'    => 0
            },
        ],
    },
    {
        pattern =>
'{0} has {1, plural, =1 {# {2}} other {# apples ({2})}}, and it is {3, time}.',
        parse => [
            {
                'arg_type' => 'NONE',
                'index'    => 0,
                'length'   => 0,
                'limit'    => 0,
                'type'     => 'MSG_START',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 0,
                'length'   => 1,
                'limit'    => 1,
                'type'     => 'ARG_START',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 1,
                'length'   => 1,
                'limit'    => 2,
                'type'     => 'ARG_NUMBER',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 2,
                'length'   => 1,
                'limit'    => 3,
                'type'     => 'ARG_LIMIT',
                'value'    => 0
            },
            {
                'arg_type' => 'PLURAL',
                'index'    => 8,
                'length'   => 1,
                'limit'    => 9,
                'type'     => 'ARG_START',
                'value'    => 3
            },
            {
                'arg_type' => 'NONE',
                'index'    => 9,
                'length'   => 1,
                'limit'    => 10,
                'type'     => 'ARG_NUMBER',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 20,
                'length'   => 2,
                'limit'    => 22,
                'type'     => 'ARG_SELECTOR',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 21,
                'length'   => 1,
                'limit'    => 22,
                'type'     => 'ARG_INT',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 23,
                'length'   => 1,
                'limit'    => 24,
                'type'     => 'MSG_START',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 24,
                'length'   => 1,
                'limit'    => 25,
                'type'     => 'REPLACE_NUMBER',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 26,
                'length'   => 1,
                'limit'    => 27,
                'type'     => 'ARG_START',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 27,
                'length'   => 1,
                'limit'    => 28,
                'type'     => 'ARG_NUMBER',
                'value'    => 2
            },
            {
                'arg_type' => 'NONE',
                'index'    => 28,
                'length'   => 1,
                'limit'    => 29,
                'type'     => 'ARG_LIMIT',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 29,
                'length'   => 1,
                'limit'    => 30,
                'type'     => 'MSG_LIMIT',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 31,
                'length'   => 5,
                'limit'    => 36,
                'type'     => 'ARG_SELECTOR',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 37,
                'length'   => 1,
                'limit'    => 38,
                'type'     => 'MSG_START',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 38,
                'length'   => 1,
                'limit'    => 39,
                'type'     => 'REPLACE_NUMBER',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 48,
                'length'   => 1,
                'limit'    => 49,
                'type'     => 'ARG_START',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 49,
                'length'   => 1,
                'limit'    => 50,
                'type'     => 'ARG_NUMBER',
                'value'    => 2
            },
            {
                'arg_type' => 'NONE',
                'index'    => 50,
                'length'   => 1,
                'limit'    => 51,
                'type'     => 'ARG_LIMIT',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 52,
                'length'   => 1,
                'limit'    => 53,
                'type'     => 'MSG_LIMIT',
                'value'    => 1
            },
            {
                'arg_type' => 'PLURAL',
                'index'    => 53,
                'length'   => 1,
                'limit'    => 54,
                'type'     => 'ARG_LIMIT',
                'value'    => 3
            },
            {
                'arg_type' => 'SIMPLE',
                'index'    => 66,
                'length'   => 1,
                'limit'    => 67,
                'type'     => 'ARG_START',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 67,
                'length'   => 1,
                'limit'    => 68,
                'type'     => 'ARG_NUMBER',
                'value'    => 3
            },
            {
                'arg_type' => 'NONE',
                'index'    => 70,
                'length'   => 4,
                'limit'    => 74,
                'type'     => 'ARG_TYPE',
                'value'    => 0
            },
            {
                'arg_type' => 'SIMPLE',
                'index'    => 74,
                'length'   => 1,
                'limit'    => 75,
                'type'     => 'ARG_LIMIT',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 76,
                'length'   => 0,
                'limit'    => 76,
                'type'     => 'MSG_LIMIT',
                'value'    => 0
            },
        ],
    },
    {
        pattern => "It is {z, time}.",
        parse   => [
            {
                'arg_type' => 'NONE',
                'index'    => 0,
                'length'   => 0,
                'limit'    => 0,
                'type'     => 'MSG_START',
                'value'    => 0
            },
            {
                'arg_type' => 'SIMPLE',
                'index'    => 6,
                'length'   => 1,
                'limit'    => 7,
                'type'     => 'ARG_START',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 7,
                'length'   => 1,
                'limit'    => 8,
                'type'     => 'ARG_NAME',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 10,
                'length'   => 4,
                'limit'    => 14,
                'type'     => 'ARG_TYPE',
                'value'    => 0
            },
            {
                'arg_type' => 'SIMPLE',
                'index'    => 14,
                'length'   => 1,
                'limit'    => 15,
                'type'     => 'ARG_LIMIT',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 16,
                'length'   => 0,
                'limit'    => 16,
                'type'     => 'MSG_LIMIT',
                'value'    => 0
            },
        ],
    },
    {
        pattern => "{0}: {1, number, double}",
        parse   => [
            {
                'arg_type' => 'NONE',
                'index'    => 0,
                'length'   => 0,
                'limit'    => 0,
                'type'     => 'MSG_START',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 0,
                'length'   => 1,
                'limit'    => 1,
                'type'     => 'ARG_START',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 1,
                'length'   => 1,
                'limit'    => 2,
                'type'     => 'ARG_NUMBER',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 2,
                'length'   => 1,
                'limit'    => 3,
                'type'     => 'ARG_LIMIT',
                'value'    => 0
            },
            {
                'arg_type' => 'SIMPLE',
                'index'    => 5,
                'length'   => 1,
                'limit'    => 6,
                'type'     => 'ARG_START',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 6,
                'length'   => 1,
                'limit'    => 7,
                'type'     => 'ARG_NUMBER',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 9,
                'length'   => 6,
                'limit'    => 15,
                'type'     => 'ARG_TYPE',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 16,
                'length'   => 7,
                'limit'    => 23,
                'type'     => 'ARG_STYLE',
                'value'    => 0
            },
            {
                'arg_type' => 'SIMPLE',
                'index'    => 23,
                'length'   => 1,
                'limit'    => 24,
                'type'     => 'ARG_LIMIT',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 24,
                'length'   => 0,
                'limit'    => 24,
                'type'     => 'MSG_LIMIT',
                'value'    => 0
            },
        ],
    },
    {
        pattern => "{0}: {1, number}",
        parse   => [
            {
                'arg_type' => 'NONE',
                'index'    => 0,
                'length'   => 0,
                'limit'    => 0,
                'type'     => 'MSG_START',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 0,
                'length'   => 1,
                'limit'    => 1,
                'type'     => 'ARG_START',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 1,
                'length'   => 1,
                'limit'    => 2,
                'type'     => 'ARG_NUMBER',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 2,
                'length'   => 1,
                'limit'    => 3,
                'type'     => 'ARG_LIMIT',
                'value'    => 0
            },
            {
                'arg_type' => 'SIMPLE',
                'index'    => 5,
                'length'   => 1,
                'limit'    => 6,
                'type'     => 'ARG_START',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 6,
                'length'   => 1,
                'limit'    => 7,
                'type'     => 'ARG_NUMBER',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 9,
                'length'   => 6,
                'limit'    => 15,
                'type'     => 'ARG_TYPE',
                'value'    => 0
            },
            {
                'arg_type' => 'SIMPLE',
                'index'    => 15,
                'length'   => 1,
                'limit'    => 16,
                'type'     => 'ARG_LIMIT',
                'value'    => 1
            },
            {
                'arg_type' => 'NONE',
                'index'    => 16,
                'length'   => 0,
                'limit'    => 16,
                'type'     => 'MSG_LIMIT',
                'value'    => 0
            },
        ],
    },
    {
        pattern => "You “have” {0, plural, =1 {# thing} other {# things}}.",
        parse   => [
            {
                'arg_type' => 'NONE',
                'index'    => 0,
                'length'   => 0,
                'limit'    => 0,
                'type'     => 'MSG_START',
                'value'    => 0
            },
            {
                'arg_type' => 'PLURAL',
                'index'    => 11,
                'length'   => 1,
                'limit'    => 12,
                'type'     => 'ARG_START',
                'value'    => 3
            },
            {
                'arg_type' => 'NONE',
                'index'    => 12,
                'length'   => 1,
                'limit'    => 13,
                'type'     => 'ARG_NUMBER',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 23,
                'length'   => 2,
                'limit'    => 25,
                'type'     => 'ARG_SELECTOR',
                'value'    => 0
            },
            {
                'arg_type' => 'NONE',
                'index'    => 24,
                'length'   => 1,
                'limit'    => 25,
                'type'     => 'ARG_INT',
                'value'    => 1
            },

            # sub-message:
            (
                {
                    'arg_type' => 'NONE',
                    'index'    => 26,
                    'length'   => 1,
                    'limit'    => 27,
                    'type'     => 'MSG_START',
                    'value'    => 1
                },
                {
                    'arg_type' => 'NONE',
                    'index'    => 27,
                    'length'   => 1,
                    'limit'    => 28,
                    'type'     => 'REPLACE_NUMBER',
                    'value'    => 0
                },
                {
                    'arg_type' => 'NONE',
                    'index'    => 34,
                    'length'   => 1,
                    'limit'    => 35,
                    'type'     => 'MSG_LIMIT',
                    'value'    => 1
                },
            ),

            {
                'arg_type' => 'NONE',
                'index'    => 36,
                'length'   => 5,
                'limit'    => 41,
                'type'     => 'ARG_SELECTOR',
                'value'    => 0
            },

            # sub-message:
            (
                {
                    'arg_type' => 'NONE',
                    'index'    => 42,
                    'length'   => 1,
                    'limit'    => 43,
                    'type'     => 'MSG_START',
                    'value'    => 1
                },
                {
                    'arg_type' => 'NONE',
                    'index'    => 43,
                    'length'   => 1,
                    'limit'    => 44,
                    'type'     => 'REPLACE_NUMBER',
                    'value'    => 0
                },
                {
                    'arg_type' => 'NONE',
                    'index'    => 51,
                    'length'   => 1,
                    'limit'    => 52,
                    'type'     => 'MSG_LIMIT',
                    'value'    => 1
                },
            ),

            {
                'arg_type' => 'PLURAL',
                'index'    => 52,
                'length'   => 1,
                'limit'    => 53,
                'type'     => 'ARG_LIMIT',
                'value'    => 3
            },
            {
                'arg_type' => 'NONE',
                'index'    => 54,
                'length'   => 0,
                'limit'    => 54,
                'type'     => 'MSG_LIMIT',
                'value'    => 0
            }

        ],
    },
);

my %part_type_name = reverse %Unicode::ICU::MessagePatternPart::PART_TYPE;
my %arg_type_name  = reverse %Unicode::ICU::MessagePatternPart::ARG_TYPE;

for my $t_hr (@parses) {
    my ( $str, $expect_ar ) = @{$t_hr}{ 'pattern', 'parse' };

    diag $str;

    my $parse = Unicode::ICU::MessagePattern->new($str);

    is(
        $parse,
        object {
            prop blessed => 'Unicode::ICU::MessagePattern';

            call count_parts => T();

            call [ get_part => 0 ] => object {
                prop blessed => 'Unicode::ICU::MessagePatternPart';
            };
        },
        'parse basics',
    );

    my @parts = map {
        my $part = $parse->get_part( $_ - 1 );

        {
            type     => $part_type_name{ $part->type() },
            arg_type => $arg_type_name{ $part->arg_type() },
            index    => $part->index(),
            length   => $part->length(),
            limit    => $part->limit(),
            value    => $part->value(),
        }
    } 1 .. $parse->count_parts();

    is( \@parts, $expect_ar, 'parse as expected', explain \@parts, );
}

#----------------------------------------------------------------------

my $parse = Unicode::ICU::MessagePattern->new("abc {0}");

my $err = dies { $parse->get_part(999) };
is(
    $err,
    check_set(
        match( qr<999> ),
        match( qr<4> ),
    ),
    'get_part() given excess',
);

done_testing;

1;
