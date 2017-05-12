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

# Save the data, since render() may update it.

my(@data) = @{$table -> data};

$table -> empty(empty_as_text);
$table -> undef(undef_as_text);
$table -> format(format_internal_github);

print "Format: format_internal_github: \n";
print $table -> render_as_string, "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);

# Etc.
