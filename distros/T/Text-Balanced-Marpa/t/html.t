#!/usr/bin/env perl
#
# scripts/traverse.pl is another version of this program.

use strict;
use warnings;

use Test::More;

use Text::Balanced::Marpa;

# -----------

my($count)  = 0;
my($parser) = Text::Balanced::Marpa -> new
(
	open =>
	[
		'<html>',
		'<head>',
		'<title>',
		'<body>',
		'<h1>',
		'<table>',
		'<tr>',
		'<td>',
	],
	close =>
	[
		'</html>',
		'</head>',
		'</title>',
		'</body>',
		'</h1>',
		'</table>',
		'</tr>',
		'</td>',
	],
);
my(@text) =
(
	q|
<html>
	<head>
		<title>A Title</title>
	</head>
	<body>
		<h1>A H1 Heading</h1>
		<table>
			<tr>
				<td>A table cell</td>
			</tr>
		</table>
	</body>
</html>
|,
);

for my $text (@text)
{
	$count++;

	$parser -> text(\$text);

	ok($parser -> parse == 0, "Parsed: $text");

	#diag join("\n", @{$parser -> tree -> tree2string});
}

print "# Internal test count: $count\n";

done_testing($count);
