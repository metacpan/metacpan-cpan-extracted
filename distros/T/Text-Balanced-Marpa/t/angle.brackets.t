#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Text::Balanced::Marpa ':constants';

# -----------

my($count)  = 0;
my($parser) = Text::Balanced::Marpa -> new
(
	open    => ['<'],
	close   => ['>'],
	options => overlap_is_fatal, # No-op, because '<' matches '>'! The 'b' and '/i' are irrelevant.
);
my(@text) =
(
	q||,
	q|a|,
	q|<a>|,
	q|a <b {c [d (e "f") g] h} i> j|,
	q|<html><head><title>A Title</title></head><body><h1>A Heading</h1></body></html>|,
	q|<i><b>Bold Italic</b></i>|,
	q|<i><b>Bold Italic</i></b>|,
);

for my $text (@text)
{
	$count++;

	ok($parser -> parse(text => \$text) == 0, "Parsed: $text");

	#diag join("\n", @{$parser -> tree -> tree2string});
}

print "# Internal test count: $count\n";

done_testing($count);
