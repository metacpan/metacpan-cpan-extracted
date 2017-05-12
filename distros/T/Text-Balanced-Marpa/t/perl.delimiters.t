#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Text::Balanced::Marpa;

# -----------

my($count)  = 0;
my($parser) = Text::Balanced::Marpa -> new
(
	open  => ['qw/', 'qr/', 'q|', 'qq|'],
	close => [  '/',   '/',  '|',   '|'],
);
my(@text) =
(
	q!qw/one two/!,
	q!qr/^(+.)$/!, # Must single-quote this because of the $.
	q!Literally: \q\r\/^(+.)$\/!, # Ditto.
	q!q|a|!,
	q!Literally: \q\|q|a|\|!,
	q!Literally: q|\q\|a\||!,
	q!qq|a|!,
	q!Literally: \q\q\|qq|a|\|!,
	q!Literally: qq|\q\q\|a\||!,
);

for my $text (@text)
{
	$count++;

	ok($parser -> parse(text => \$text) == 0, "Parsed: $text");

	#diag join("\n", @{$parser -> tree -> tree2string});
}

print "# Internal test count: $count\n";

done_testing($count);
