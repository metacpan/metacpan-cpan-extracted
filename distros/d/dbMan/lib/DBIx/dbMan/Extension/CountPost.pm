package DBIx::dbMan::Extension::CountPost;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.02';

1;

sub IDENTIFICATION { return "000001-000080-000002"; }

sub preference { return 90; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{count_process} eq '1') {
		delete $action{processed};
		delete $action{count_process};
		my $oldaction = $action{action};
		$action{action} = 'COUNT';
		$action{sql} = uc $action{sql};
		$action{sql} =~ s/SELECT COUNT\(\*\) POCET FROM //i;
		$action{error_output} .= "Table $action{sql} does not exists.\n" if $oldaction eq 'OUTPUT';
		return %action if $oldaction ne 'SQL_RESULT';

		my $result = $action{result};
		$action{count_rows} = $result->[0][0];
		$action{action} = 'SQL';
		$action{sql} = 'SELECT * FROM '.$action{sql}.' WHERE 0 = 1';
		$action{count_process} = '2';
	} elsif ($action{count_process} eq '2') {
		delete $action{processed};
		delete $action{count_process};
		my $oldaction = $action{action};
		$action{action} = 'COUNT';
		$action{sql} = uc $action{sql};
		$action{sql} =~ s/SELECT \* FROM //i;
		$action{sql} =~ s/ WHERE 0 = 1//i;
		return %action if $oldaction ne 'SQL_RESULT';

		my $result = $action{result};
		$action{count_result}->{$action{sql}}{rows} = $action{count_rows};
		$action{count_result}->{$action{sql}}{cols} = scalar @{$action{fieldnames}};
	}

	return %action;
}
