package DBIx::dbMan::Extension::SQLOracleOutput;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000060-000004"; }

sub preference { return -35; }

sub known_actions { return [ qw/OUTPUT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'OUTPUT' and $obj->{-dbi}->driver eq 'Oracle' and $action{oracle_dbms}) {
		my $dbms = join "\n",$obj->{-dbi}->func('dbms_output_get');
		$dbms = "DBMS output:\n$dbms\n" if $dbms;
		$action{output} .= $dbms;
	}

	return %action;
}
