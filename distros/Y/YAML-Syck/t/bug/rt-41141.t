#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use YAML::Syck;

# RT #41141: \r must be quoted, not emitted as a raw carriage return.

my %roundtrip_tests = (
    '42\\r'        => "42\r",
    '?\\r'         => "?\r",
    '-\\r\\r'      => "-\r\r",
    ',\\r\\r\\r'   => ",\r\r\r",
    'hello\\r\\n'  => "hello\r\n",
    'just \\r'     => "just \r",
    '\\t tab'      => "\t tab",
);

# Verify roundtrip AND that no raw \r or \t appears in the YAML output.
plan tests => scalar(keys %roundtrip_tests) * 2;

while (my ($test, $value) = each (%roundtrip_tests))
{
    my $yaml = YAML::Syck::Dump($value);
    my $decoded = eval { YAML::Syck::Load($yaml); };
    is($decoded, $value, "Roundtrip: $test");

    # The YAML output must not contain raw \r or \t — they should be escaped.
    my $has_raw_cr = ($yaml =~ /\r/);
    my $has_raw_tab = ($yaml =~ /\t/);
    ok(!$has_raw_cr && !$has_raw_tab,
       "No raw control chars in output: $test");
}

note 'Done!';

