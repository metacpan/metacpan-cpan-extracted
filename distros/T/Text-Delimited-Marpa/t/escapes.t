#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

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
	q|Escaped opening delimiters\: \<.|,
	q|Escaped closing delimiters\: \:.|,
	q|a|,
	q|Escaping permits nested but non-fatal delimiters\: <: $string \<\: $string \:\> :>|,
	q|I said "I sang 'Δ Lady'" [\"Contains UTF8\"]|,
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
