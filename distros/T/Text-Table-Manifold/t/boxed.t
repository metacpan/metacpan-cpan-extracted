#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Text::Table::Manifold ':constants';

# -----------------------------------------------

sub run_test
{
	my($table, $format, $first_char, $last_char) = @_;

	$table -> format($format);

	my(@table)      = @{$table -> render};
	my(@first_line) = split(//, $table[0]);
	my(@last_line)  = split(//, $table[$#table]);

	ok($first_line[0] eq $first_char, "First line starts with $first_char");
	ok($last_line[$#last_line] eq $last_char, "Last line ends with $last_char");

} # End of run_test.

# -----------------------------------------------

my($table) = Text::Table::Manifold -> new;

$table -> headers(['Name', 'Type', 'Null', 'Key', 'Auto increment']);
$table -> data(
[
	['id', 'int(11)', 'not null', 'primary key', 'auto_increment'],
	['description', 'varchar(255)', 'not null', '', ''],
	['name', 'varchar(255)', 'not null', '', ''],
	['upper_name', 'varchar(255)', 'not null', '', ''],
]);

run_test($table, format_internal_boxed, '+', '+');
run_test($table, format_internal_github, 'N', '|');
run_test($table, format_internal_html, '<', '>');

done_testing;
