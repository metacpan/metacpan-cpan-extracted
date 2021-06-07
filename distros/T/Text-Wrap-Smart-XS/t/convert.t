#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2 * 2;
use Text::Wrap::Smart::XS qw(exact_wrap fuzzy_wrap);

my $wrap_at  = 60;
my $expected = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';

foreach my $text (
    [ "Lorem ipsum\fdolor\nsit\ramet,\tconsectetur adipiscing elit.",    'whitespace substituted' ],
    [ 'Lorem  ipsum  dolor  sit  amet,  consectetur  adipiscing  elit.', 'spaces consolidated'    ],
) {
    my @strings = exact_wrap($text->[0], $wrap_at);
    is_deeply(\@strings, [$expected], "exact_wrap(): $text->[1]");

    @strings = fuzzy_wrap($text->[0], $wrap_at);
    is_deeply(\@strings, [$expected], "fuzzy_wrap(): $text->[1]");
}
