#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6 * 2;
use Text::Wrap::Smart::XS qw(exact_wrap fuzzy_wrap);

{
    my $text     = " \f\n\r\tLorem ipsum dolor sit amet, consectetur adipiscing elit. \f\n\r\t";
    my $expected = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
    my $wrap_at  = 60;

    my @strings = exact_wrap($text, $wrap_at);
    is_deeply(\@strings, [$expected], 'exact_wrap(): text trimmed');

    @strings = fuzzy_wrap($text, $wrap_at);
    is_deeply(\@strings, [$expected], 'fuzzy_wrap(): text trimmed');
}

{
    my $wrap_at = 10;

    foreach my $text (
        [' foo ', ['foo'], 'at begin/end' ],
        [' foo',  ['foo'], 'at begin'     ],
        ['foo ',  ['foo'], 'at end'       ],
        [' ',     [],      'only'         ],
        ['',      [],      undef          ],
    ) {
        my $message = defined $text->[2] ? "whitespace $text->[2]" : 'empty';

        my @strings = exact_wrap($text->[0], $wrap_at);
        is_deeply(\@strings, $text->[1], "exact_wrap(): $message");

        @strings = fuzzy_wrap($text->[0], $wrap_at);
        is_deeply(\@strings, $text->[1], "fuzzy_wrap(): $message");
    }
}
