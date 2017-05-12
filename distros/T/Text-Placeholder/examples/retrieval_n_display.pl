#!/usr/bin/perl -W -T

use strict;
use Data::Dumper;
use Text::Placeholder::Appliance::SQL::Retrieval_n_Display;

my %values = (
	'cond_some_value' => '99'
);

my $rnd = Text::Placeholder::Appliance::SQL::Retrieval_n_Display->new;
$rnd->html_parameter(
	'<td>[=fld_some_name=]</td>
	<td>[=fld_other_name=]</td>');
my ($statement, $value_names) = $rnd->sql_parameter(
	'SELECT [=field_list=]
	FROM some_table
	WHERE some_field = [=cond_some_value=]');
my @values = map($values{$_}, @{$value_names});
#my $rows = $dbh->selectall_arrayref($statement, {}, @values);
my $rows = [[4..6], [qw(A B C)]];
$rnd->format($rows);

print Dumper($statement, \@values, $rows);

exit(0);

__END__
$VAR1 = \'SELECT some_name, other_name
        FROM some_table
        WHERE some_field = ?';
$VAR2 = [
          '99'
        ];
$VAR3 = [
          '<td>4</td>
        <td>5</td>',
          '<td>A</td>
        <td>B</td>'
        ];

