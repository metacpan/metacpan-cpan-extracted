#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Test::More;

use Text::Balanced::Marpa;

# -----------

my($count)  = 0;
my($parser) = Text::Balanced::Marpa -> new
(
	open        => ['{'],
	close       => ['}'],
	escape_char => '%',
);
my(@text) =
(
	q|{%{a%}} \{\b\} {} %%|,
	q|a {b} c %{%} {\d}|,
);

my($result);

for my $text (@text)
{
	$count++;

	$result = $parser -> parse(text => \$text);

	ok($result == 0, "Parsed: $text");

	#diag join("\n", @{$parser -> tree -> tree2string});
}

print "# Internal test count: $count\n";

done_testing($count);
