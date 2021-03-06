#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Text::Delimited::Marpa ':constants';

# -----------

my($count)  = 0;
my($parser) = Text::Delimited::Marpa -> new
(
	open    => '<:',
	close   => ':>',
	options => mismatch_is_fatal,
);
my(@text) =
(
	q||,
	q|a|,
	q|<: a :>|,
	q|a {b <: c :> d} e|,
	q|a <: b <: c :> d :> e <:>|,
);

my($result);

for my $text (@text)
{
	$count++;

	$result = $parser -> parse(text => \$text);

	if ($count == 5)
	{
		ok($result == 1, "Deliberate error. Failed to parse: $text");
	}
	else
	{
		ok($result == 0, "Parsed: $text");
	}

	#diag join("\n", @{$parser -> tree -> tree2string});
}

print "# Internal test count: $count\n";

done_testing($count);
