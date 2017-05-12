#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Text::Delimited::Marpa ':constants';

# -----------

my($count)  = 0;
my($parser) = Text::Delimited::Marpa -> new
(
	open    => '{',
	close   => '}',
	options => mismatch_is_fatal,
);
my(@prefix) =
(
	'Skip me ->',
	"I've already parsed up to here ->",
);
my(@text) =
(
	q|a {b} c|,
	q|a {b {c} d} e|,
);

my($text);

for my $i (0 .. $#text)
{
	$count++;

	$text = $prefix[$i] . $text[$i];

	$parser -> pos(length $prefix[$i]);
	$parser -> length(length($text) - $parser -> pos);

	ok($parser -> parse(text => \$text) == 0, "Parsed: $text");

	#diag join("\n", @{$parser -> tree -> tree2string});
}

print "# Internal test count: $count\n";

done_testing($count);
