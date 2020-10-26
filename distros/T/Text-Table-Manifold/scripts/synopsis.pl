#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Text::Table::Manifold ':constants';

# -----------

# Set parameters with new().

my($table) = Text::Table::Manifold -> new
(
	alignment =>
	[
		align_left,
		align_center,
		align_right,
		align_center,
	]
);

$table -> headers(['Homepage', 'Country', 'Name', 'Metadata']);
$table -> data(
[
	['http://savage.net.au/',   'Australia', 'Ron Savage',    undef],
	['https://duckduckgo.com/', 'Earth',     'Mr. S. Engine', ''],
]);

# Note: Save the data, since render() may update it.

my(@data) = @{$table -> data};

# Set parameters with methods.

$table -> empty(empty_as_text);
$table -> format(format_internal_boxed);
$table -> undef(undef_as_text);

# Set parameters with render().

print "Format: format_internal_boxed: \n";
print join("\n", @{$table -> render(padding => 1)}), "\n";
print "\n";

$table -> headers(['One', 'Two', 'Three']);
$table -> data(
[
	['Reichwaldstraße', 'Böhme', 'ʎ ʏ ʐ ʑ ʒ ʓ ʙ ʚ'],
	['ΔΔΔΔΔΔΔΔΔΔ', 'Πηληϊάδεω Ἀχιλῆος', 'A snowman: ☃'],
	['Two ticks: ✔✔', undef, '<table><tr><td>TBA</td></tr></table>'],
]);

# Save the data, since render() may update it.

@data = @{$table -> data};

$table -> empty(empty_as_minus);
$table -> format(format_internal_boxed);
$table -> undef(undef_as_text);
$table -> padding(2);

print "Format: format_internal_boxed: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);

# Etc.
