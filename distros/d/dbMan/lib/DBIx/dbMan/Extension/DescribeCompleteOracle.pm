package DBIx::dbMan::Extension::DescribeCompleteOracle;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000049-000004"; }

sub preference { return 1000; }

sub known_actions { return [ qw/DESCRIBE/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'DESCRIBE' and $action{oper} eq 'complete' and $obj->{-dbi}->driver eq 'Oracle') {
		$action{action} = 'CACHE';
		$action{cache_type} = 'describe_ora';

		unless ($obj->{-dbi}->current) {
			$obj->{-interface}->error("No current connection selected.");
			return %action;
		}	
		my $sth = $obj->{-dbi}->prepare(q!SELECT object_name FROM user_objects WHERE object_type IN ('TABLE','VIEW')!);
		$sth->execute();
		my $ret = $sth->fetchall_arrayref();
		my @all = ();
		@all = map { $_->[0] } @$ret if defined $ret;
		$sth->finish;
		$action{list} = \@all;
		$action{what} = 'list';
		$action{processed} = 1;
		return %action;
	}

	$action{processed} = 1;
	return %action;
}
