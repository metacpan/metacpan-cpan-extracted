#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use YAML::Syck;
use Data::Dumper;

# Carrier returns after c-indicators aren't being handled properly.

my %tests = (
    # From the original bug report. Seems to have been fixed already.
    '42\\r' => "42\r",

    # These all produced bad YAML.
    '?\\r'  => "?\r",
    '-\\r\\r'  => "-\r\r",
    ',\\r\\r\\r'  => ",\r\r\r",
);

plan tests => scalar keys %tests;
while (my ($test, $value) = each (%tests))
{
    my $yaml = YAML::Syck::Dump($value);
    my $decoded = eval { YAML::Syck::Load($yaml); };
    is($decoded, $value, "Produces valid YAML: $test");
}

note 'Done!';

