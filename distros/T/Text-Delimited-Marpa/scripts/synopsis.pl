#!/usr/bin/env perl

use strict;
use warnings;

use Text::Delimited::Marpa ':constants';

# -----------

my(%count)  = (fail => 0, success => 0, total => 0);
my($parser) = Text::Delimited::Marpa -> new
(
	open    => '/*',
	close   => '*/',
	options => print_errors | print_warnings | mismatch_is_fatal,
);
my(@text) =
(
	q|Start /* One /* Two /* Three */ Four */ Five */ Finish|,
);

my($result);
my($text);

for my $i (0 .. $#text)
{
	$count{total}++;

	$text = $text[$i];

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
