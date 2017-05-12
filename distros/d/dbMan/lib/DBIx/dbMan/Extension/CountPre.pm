package DBIx::dbMan::Extension::CountPre;

use strict;
use base 'DBIx::dbMan::Extension';
use DBI ':sql_types';

our $VERSION = '0.02';

1;

sub IDENTIFICATION { return "000001-000079-000002"; }

sub preference { return 300; }

sub known_actions { return [ qw/COUNT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'COUNT' and $obj->{-dbi}->current) {
		if ($action{count_re}) {
			my $sth = $obj->{-dbi}->table_info();
			my $ret = $sth->fetchall_arrayref();
			study $action{count_re};
			my @tab = ();
			if (defined $ret) {
				for (@$ret) {
					push @tab,$_->[2] if lc $_->[3] eq 'table' and 
						$_->[2] =~ /$action{count_re}/i;
                                }
                        }
			$action{count_tables} = \@tab;
			delete $action{count_re};
		} 

		unless (@{$action{count_tables}}) {
			$action{output_info} = $action{error_output};
			$action{action} = 'SQL_RESULT';
			$action{result} = [];
			for my $table (sort keys %{$action{count_result}}) {
				push @{$action{result}}, [ $table,
					$action{count_result}->{$table}{rows},
					$action{count_result}->{$table}{cols} ];
			}
			$action{fieldnames} = [ 'TABLE', 'LINES', 'FIELDS' ];
			$action{fieldtypes} = [ SQL_VARCHAR, SQL_INTEGER, SQL_INTEGER ];
			$action{output} = '';
			unless (@{$action{result}}) {
				$action{action} = 'OUTPUT';
				$action{fieldnames} = [];
				$action{fieldtypes} = [];
				$action{sql} = '';
				$action{type} = '';
			}
		} else {
			my $table = shift @{$action{count_tables}};
			$action{action} = 'SQL';
			$action{count_process} = 1;
			$action{sql} = 'SELECT COUNT(*) pocet FROM '.$table;
			$action{type} = 'select';
			delete $action{processed};
		}
	}

	return %action;
}
