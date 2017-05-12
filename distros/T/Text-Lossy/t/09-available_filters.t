#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;

use Text::Lossy;

my $lossy;

# A factory for our new filters
sub all_digit {
    my ($digit) = @_;
    return sub {
        my ($text) = @_;
        $text =~ s{\d}{$digit}xmsg;
        return $text;
    }
}

is (scalar(keys %Text::Lossy::filtermap), 6, "Start with six filters");
is (join(', ',Text::Lossy->available_filters()), 'alphabetize, lower, punctuation, punctuation_sp, whitespace, whitespace_nl', "All four filters listed");

# Note: we need a code reference, and 'all_digit' gives us one!
Text::Lossy->register_filters( all_zero => all_digit(0) );
is (join(', ',Text::Lossy->available_filters()), 'all_zero, alphabetize, lower, punctuation, punctuation_sp, whitespace, whitespace_nl', "New filter listed");

Text::Lossy->register_filters( lower => undef );
is (join(', ',Text::Lossy->available_filters()), 'all_zero, alphabetize, punctuation, punctuation_sp, whitespace, whitespace_nl', "Removed filter not listed");

Text::Lossy->register_filters( all_zero => undef, alphabetize => undef, punctuation => undef, punctuation_sp => undef, whitespace => undef, whitespace_nl => undef );
is (join(', ',Text::Lossy->available_filters()), '', "Removed all filters, list is empty");

done_testing();
