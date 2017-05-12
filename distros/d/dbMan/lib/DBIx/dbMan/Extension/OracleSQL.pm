package DBIx::dbMan::Extension::OracleSQL;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.10';

1;

sub IDENTIFICATION { return "000001-000038-000010"; }

sub preference { return 3999; }

sub known_actions { return [ qw/COMMAND SQL/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND' and $obj->{-dbi}->driver eq 'Oracle') {
		$action{processed} = 1;
		$obj->{-dbi}->set('LongTruncOk',1);
		if ($obj->{-mempool}->get('dbms_output')) {
			$obj->{-dbi}->func(1000000,'dbms_output_enable');
			$action{oracle_dbms} = 1;
		}
		if ($action{cmd} !~ /end;$/i) {
			return %action if $action{cmd} =~ s/[;\/]$//;
		}
	}
	if ($action{action} eq 'SQL' and $action{oper} eq 'complete' and $obj->{-dbi}->driver eq 'Oracle') {
		$action{action} = 'CACHE';
		my @all = ();
		if ($action{context} =~ /\./) {
			$action{cache_type} = 'sql_oracle_' . $action{type} . '___' . $action{context};
			my $tab = $action{context};  $tab =~ s/\.[^.]*$//;
			my $sth = $obj->{-dbi}->prepare(q!SELECT * FROM !.$tab.q! WHERE 0 = 1!);
			if (defined $sth and not @all) {
				if ($sth->execute) {
					@all = map { ($action{type} eq 'FIELDS') ? $_ : $tab.'.'.$_ } @{$sth->{NAME}};
					$sth->finish;
				} elsif (lc $action{type} eq 'seq') {  # don't work ??? why ???
					if ($tab !~ /\./) { @all = map { $tab.'.'.$_ } qw/next_val curr_val/; }
				} 
			} else {
				my $d = $obj->{-dbi}->selectall_arrayref(q!
					SELECT object_name
					FROM all_objects
					WHERE owner = ? AND object_type !.(lc $action{type} ne 'object'?((lc $action{type} eq 'context')?q! IN ('TABLE','VIEW','FUNCTION','PACKAGE')!:((lc $action{type} eq 'seq')?q! = 'SEQUENCE'!:q! = '!.uc($action{type}).q!'!)):q!IN ('PROCEDURE','FUNCTION','TRIGGER','VIEW','PACKAGE','PACKAGE BODY')!),{},uc $tab);
				@all = map { uc($tab).'.'.$_->[0] } @$d if defined $d;
			}
		} else {
			$action{cache_type} = 'sql_oracle_' . $action{type};
			my $d = $obj->{-dbi}->selectall_arrayref(q!
				SELECT object_name
				FROM user_objects
				WHERE object_type !.(lc $action{type} ne 'object'?((lc $action{type} eq 'context')?q! IN ('TABLE','VIEW','FUNCTION','PACKAGE')!:((lc $action{type} eq 'seq')?q! = 'SEQUENCE'!:q! = '!.uc($action{type}).q!'!)):q!IN ('PROCEDURE','FUNCTION','TRIGGER','VIEW','PACKAGE','PACKAGE BODY')!));
			@all = map { $_->[0] } @$d if defined $d;
			push @all,'DUAL';
			push @all,'SYSDATE';
		}
		$action{list} = \@all;
	}
	$action{processed} = 1;
	return %action;
}
