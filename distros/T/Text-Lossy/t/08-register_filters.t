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

Text::Lossy->register_filters();
is (scalar(keys %Text::Lossy::filtermap), 6, "No filters added");

# Note: we need a code reference, and 'all_digit' gives us one!
Text::Lossy->register_filters( all_zero => all_digit(0) );
is (scalar(keys %Text::Lossy::filtermap), 7, "One filter added");
$lossy = Text::Lossy->new->add('all_zero');

is($lossy->process('The 12345 test'), 'The 00000 test', "Filter works");

Text::Lossy->register_filters( lower => undef );
is (scalar(keys %Text::Lossy::filtermap), 6, "Removed a built-in filter");

throws_ok {
    $lossy = Text::Lossy->new->add('lower');
} qr{unknown filter}ims, "Built-in filter no longer known";

$lossy = Text::Lossy->new->add('all_zero');
Text::Lossy->register_filters( all_zero => all_digit(1) );
my $lossy_one = Text::Lossy->new->add('all_zero');
is($lossy->process('The 12345 test'), 'The 00000 test', "Filter works, even if overregistered");
is($lossy_one->process('The 12345 test'), 'The 11111 test', "The object created after register_filters has the new filter");

done_testing();
