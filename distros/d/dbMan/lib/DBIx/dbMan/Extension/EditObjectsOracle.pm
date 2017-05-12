package DBIx::dbMan::Extension::EditObjectsOracle;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000045-000005"; }

sub preference { return 50; }

sub known_actions { return [ qw/EDIT_OBJECT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'EDIT_OBJECT' and $obj->{-dbi}->driver eq 'Oracle') {
		unless ($obj->{-dbi}->current) {
			$action{action} = 'NONE';
			$obj->{-interface}->error("No current connection selected.");
			return %action;
		}
		my $lastwhat = $action{what};
		my $schema = '';
		$schema = uc $1 if $action{what} =~ s/^([^.]+)\.//;
		my $schema_add = '';
		my @schema = ();
		if ($schema) {
			$schema_add = ' AND owner = ?';
			push @schema,$schema;
		}
		my $basetable = $schema?'all':'user';

		my $d = $obj->{-dbi}->selectall_arrayref(q!
			SELECT object_name, object_type
			FROM !.$basetable.q!_objects
			WHERE UPPER(object_name) LIKE ? AND object_type !.($action{type}?(q! = '!.uc($action{type}).q!'!):q!IN ('PROCEDURE','FUNCTION','TRIGGER','VIEW','PACKAGE','PACKAGE BODY')!).$schema_add,
			{},uc($action{what}),@schema);
		$action{what} = $lastwhat;
		if (defined $d) {
			$action{action} = 'NONE';
			if (@$d) {
				if (@$d == 1) {
					$action{action} = 'EDIT';
					$action{what} = $d->[0][0];
					$action{what} = "$schema.".$action{what} if $schema;
					$action{type} = $d->[0][1];
					delete $action{processed};
					return %action;
				} else {
					$action{action} = 'OUTPUT';
					$action{output} = "You must explicit say which object you want edit:\n";
					my $tab = new Text::FormatTable '| l | l |';
					$tab->rule;
					my @schema = ();
					push @schema,'SCHEMA' if $schema;
					$tab->head(@schema,'NAME','TYPE');
					$tab->rule;
					for (@$d) {
						my @item = ();
						push @item,$schema if $schema;
						$tab->row(@item,@$_);
					}
					$tab->rule;
					$action{output} .= $tab->render($obj->{-interface}->render_size);
				}
			} else {
				$obj->{-interface}->error("Object ".$action{what}." not found.");
				return %action;
			}
		} else {
			print DBI::errstr()."\n";
		}
	}

	return %action;
}

sub objectlist {
	my ($obj,$type) = @_;
	my $d = $obj->{-dbi}->selectall_arrayref(q!
		SELECT object_name
		FROM user_objects
		WHERE object_type !.
			($type?(q! = '!.$type.q!'!):q!IN ('PROCEDURE','FUNCTION','TRIGGER','VIEW','PACKAGE','PACKAGE BODY')!));
	return map { $_->[0] } @$d;
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return () unless $obj->{-dbi}->current;
	return $obj->objectlist('PACKAGE BODY') if $line =~ /^\s*EDIT\s+PACKAGE\s+BODY\s+\S*$/i;
	return ('BODY',$obj->objectlist('PACKAGE')) if $line =~ /^\s*EDIT\s+PACKAGE\s+\S*$/i;
	return $obj->objectlist($1) if $line =~ /^\s*EDIT\s+(PROCEDURE|FUNCTION|TRIGGER|VIEW|PACKAGE)\s+\S*$/i;
	return qw/PROCEDURE FUNCTION TRIGGER VIEW PACKAGE/ if $line =~ /^\s*EDIT\s+\S*$/i;
	return ();
}
