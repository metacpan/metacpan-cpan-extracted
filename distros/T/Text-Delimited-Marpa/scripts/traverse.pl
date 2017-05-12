#!/usr/bin/env perl

use strict;
use warnings;

use Text::Delimited::Marpa ':constants';

# -----------

my($parser) = Text::Delimited::Marpa -> new
(
	open    => '<:',
	close   => ':>',
	options => print_errors | print_warnings | mismatch_is_fatal,
);
my($text) = q|a <:b <:c:> d:> e <:f <: g <:h:> i:> j:> k|;
my($span) = 0;

my($result);

print '        | ';
printf '%10d', $_ for (1 .. 9);
print "\n";
print '        |';
print '0123456789' for (0 .. 8);
print "0\n";
print "Parsing |$text|. \n";
print "Span  Start  End  Length  Text\n";

if ($parser -> parse(text => \$text) == 0)
{
	my($attributes);
	my($indent);
	my($text);

	for my $node ($parser -> tree -> traverse)
	{
		next if ($node -> is_root);

		$span++;

		$attributes = $node -> meta;
		$text       = $$attributes{text};
		$indent     = $node -> depth - 1;

		print sprintf("%4d  %5d  %3d  %6d  %-s\n", $span, $$attributes{start}, $$attributes{end}, $$attributes{length}, '  ' x $indent . "|$text|") if (length($text) );
	}
}
