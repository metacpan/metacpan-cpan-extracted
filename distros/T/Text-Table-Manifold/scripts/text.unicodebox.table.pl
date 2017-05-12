#!/usr/bin/env perl

use strict;
use warnings;

use Text::Table::Manifold ':constants';

# -----------

my($table) = Text::Table::Manifold -> new
(
	alignment =>
	[
		align_left,
		align_right,
		align_left,
		align_right,
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

$table -> empty(empty_as_text);
$table -> pass_thru({new => {style => 'light'} });
$table -> undef(undef_as_text);

print "Format: format_text_unicodebox_table, with border style 'light': \n";
print join("\n", @{$table -> render(format => format_text_unicodebox_table)});
print "\n";

# Note: Restore the saved data.

$table -> data([@data]);
$table -> pass_thru({new => {style => 'horizontal_double'} });

print "Format: format_text_unicodebox_table, with border style 'horizontal_double': \n";
print $table -> render_as_string(join => "\n");
print "\n";

# Note: Restore the saved data.

$table -> data([@data]);

# Etc.
