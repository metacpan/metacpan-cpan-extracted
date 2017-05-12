#!/usr/bin/env perl

use strict;
use warnings;

use Text::Balanced::Marpa ':constants';

# -----------

my($count)    = 0;
my($maxlevel) = shift || 'debug'; # Try 'info' (without the quotes).
my($parser)   = Text::Balanced::Marpa -> new
(
	open     => ['<', '{', '[', '(', '<:', '[%', '"'],
	close    => ['>', '}', ']', ')', ':>', '%]', '"'],
	maxlevel => $maxlevel,
	options  => overlap_is_fatal | print_warnings, # Diff output after using nothing_is_fatal.
);
my(@text) =
(
	q||,
	q|a|,
	q|{a}|,
	q|[a]|,
	q|a {b} c|,
	q|a [b] c|,
	q|a {b {c} d} e|,
	q|a [b [c] d] e|,
	q|a {b [c] d} e|,
	q|a <b {c [d (e "f") g] h} i> j|,
	q|<html><head><title>A Title</title></head><body><h1>A Heading</h1></body></html>|,
	q|{a nested { and } are okay as are () and <> pairs and escaped \}\'s };|,
	q|{a nested\n{ and } are okay as are\n() and <> pairs and escaped \}\'s };|,
	q|a "b" c|,
	q|a 'b' c|,
	q|a "b" c "d" e|,
	q|a "b" c 'd' e|,
	q|<: $a :> < b >|,
	q|<: $a <: $b :> :>|,
	q|[% $a %]|,
	q|{Bold [Italic}]|,           # This one is affected by overlap_is_fatal. Check the output.
	q|<i><b>Bold Italic</b></i>|, # This one is not, since '<' is the delim, not '<b>' :-).
	q|<i><b>Bold Italic</i></b>|,
);

my($result);

for my $text (@text)
{
	$count++;

	if ($maxlevel ne 'notice')
	{
		print '-' x 50, "\n";
		print "Start test  $count. Input |$text|\n";
	}

	$result = $parser -> parse(text => \$text);

	print join("\n", @{$parser -> tree -> tree2string}), "\n";
	print "Parse result: $result (0 is success)\n";

	if ($maxlevel ne 'notice')
	{
		print "Finish test $count. Input |$text|\n";
	}
}
