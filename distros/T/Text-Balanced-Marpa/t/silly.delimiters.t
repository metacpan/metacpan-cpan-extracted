#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Text::Balanced::Marpa;

# -----------

my($count)  = 0;
my($parser) = Text::Balanced::Marpa -> new
(
	open  => ['vw'],
	close => ['xy'],
);
my(@text) =
(
	q|one vwtwoxy three|,
	q|one \vwtwo\xy three|,
	q|one \vwvw\vwtwo\xyxy\xy three|,
);

for my $text (@text)
{
	$count++;

	ok($parser -> parse(text => \$text) == 0, "Parsed: $text");

	#diag join("\n", @{$parser -> tree -> tree2string});
}

print "# Internal test count: $count\n";

done_testing($count);
