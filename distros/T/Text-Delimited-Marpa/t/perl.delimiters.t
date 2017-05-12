#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Text::Delimited::Marpa ':constants';

# -----------

my($count)  = 0;
my($parser) = Text::Delimited::Marpa -> new
(
	open    => 'qq|',
	close   =>   '|',
	options => mismatch_is_fatal,
);
my(@text) =
(
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
