#!/usr/bin/env perl

use strict;
use warnings;

use Text::Delimited::Marpa ':constants';

# -----------

my(%count)  = (fail => 0, success => 0, total => 0);
my($parser) = Text::Delimited::Marpa -> new
(
	open    => '<:',
	close   => ':>',
	options => print_errors | print_warnings | mismatch_is_fatal,
);
my(@prefix) =
(
	'',
	'Skip me ->',
	"I've already parsed up to here ->",
);
my(@text) =
(
	q|<:a:> <:b:>|,
	q|a <:b <:c:> d:> e <:f <: g <:h:> i:> j:> k|,
	q|one <: two <: three <: four :> five :> six :> seven|,
);

my($result);
my($text);

for my $i (0 .. $#text)
{
	$count{total}++;

	$text = $prefix[$i] . $text[$i];

	$parser -> pos(length $prefix[$i]);
	$parser -> length(length($text) - $parser -> pos);

	print sprintf('(# %3d) | ', $count{total});
	printf '%10d', $_ for (1 .. 9);
	print "\n";
	print '        |';
	print '0123456789' for (0 .. 8);
	print "0\n";
	print "Parsing |$text|. pos: ", $parser -> pos, '. length: ', $parser -> length, "\n";

	$result = $parser -> parse(text => \$text);

	print "Parse result: $result (0 is success)\n";

	if ($result == 0)
	{
		$count{success}++;

		print join("\n", @{$parser -> tree -> tree2string}), "\n";
	}
}

$count{fail} = $count{total} - $count{success};

print "\n";
print 'Statistics: ', join(', ', map{"$_ => $count{$_}"} sort keys %count), ". \n";
