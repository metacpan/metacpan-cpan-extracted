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

$table -> footers(['One', 'Two', 'Three', 'Four']);
$table -> empty(empty_as_text);
$table -> escape(escape_html);
$table -> include(include_headers | include_data | include_footers);
$table -> pass_thru({new => {table => {align => 'center', border => 1} } });
$table -> undef(undef_as_text);

print "Format: as_internal_html: \n";
print $table -> render_as_string(format => format_internal_html, join => "\n"), "\n";
print "\n";

# Note: Restore the saved data.

$table -> data([@data]);

# Etc.
