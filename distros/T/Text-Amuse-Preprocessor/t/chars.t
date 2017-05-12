#!perl

use strict;
use warnings;

use Text::Amuse::Preprocessor::TypographyFilters;

use Test::More tests => 8 * 14;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

my $chars = Text::Amuse::Preprocessor::TypographyFilters::characters();

foreach my $lang (keys %$chars) {
    foreach my $token (qw/ldouble rdouble lsingle rsingle apos emdash
                          dash endash/) {
        ok($chars->{$lang}->{$token},
           "Found $token for $lang: $chars->{$lang}->{$token}");
    }
}

