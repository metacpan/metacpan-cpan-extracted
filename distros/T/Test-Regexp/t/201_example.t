#!/usr/bin/perl

use strict;
use warnings;

use Test::Regexp tests => 'no_plan';

my $checker = Test::Regexp -> new -> init (
    keep_pattern => qr /(\w+)\s+\g{-1}/,
    name         => "Double word matcher",
);

$checker -> match    ("foo foo", ["foo"]);
$checker -> no_match ("foo bar");


__END__
