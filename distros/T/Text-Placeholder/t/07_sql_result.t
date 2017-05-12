#!/usr/bin/perl -W -T

use strict;
use Test::Simple tests => 2;

use Text::Placeholder;

my $placeholder = Text::Placeholder->new(
	my $sql_result = '::SQL::Result');
$sql_result->placeholder_re('^fld_(\w+)$');
$placeholder->compile('<td>[=fld_some_name=]</td>');

my $statement = "SELECT ". join(', ', @{$sql_result->fields}). " FROM some_table";
ok($statement eq 'SELECT some_name FROM some_table', 'T001: statement');
my $row = [7, 8, 9];
$sql_result->subject($row);

my $output = ${$placeholder->execute()};
ok($output eq '<td>7</td>', 'T002: output');

exit(0);
