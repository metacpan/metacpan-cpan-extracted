#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Text::Prefix::XS;
use utf8;

my $byte_prefix = "\x254\x237";
my @prefixes = (
    $byte_prefix,
    "שלום",
    "ascii",
);

my $search = prefix_search_create(@prefixes);
is(prefix_search($search, "שלום ולהתראות"), "שלום", "Non-ASCII matching");

my $bytes = "\x254\x237\x69\x42\x50";

is(prefix_search($search, $bytes), $byte_prefix, "Got random byte prefix");
is(prefix_search($search, "ascii_string"), 'ascii', "Got ASCII");

my $mixed = "ascii_שלום";
is(prefix_search($search, $mixed), 'ascii', "Mixed-encoding string with valid prefix");

done_testing();