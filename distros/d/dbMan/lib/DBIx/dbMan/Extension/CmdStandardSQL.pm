package DBIx::dbMan::Extension::CmdStandardSQL;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.12';

1;

sub IDENTIFICATION { return "000001-000013-000012"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^(?:\/\*.*?\*\/\s*)?(select|with|explain)\s+/i) {
			$action{action} = 'SQL';
			$action{type} = 'select';
			$action{sql} = $action{cmd};
			$action{explain} = 1 if $action{cmd} =~ /^explain\s+/i and $obj->{-dbi}->driver eq 'Oracle';
		} elsif ($action{cmd} =~ /^(?:\/\*.*?\*\/\s*)?((delete|insert|update|create|drop|begin|alter|truncate|grant|revoke|analyze)\s+.*|vacuum)(?:\s*\/\*.*?\*\/)?$/i) {
			$action{action} = 'SQL';
			$action{type} = 'do';
			$action{sql} = $action{cmd};
		} elsif ($action{cmd} =~ /^(?:\/\*.*?\*\/\s*)?execute\s+(.*)$/i and $obj->{-dbi}->driver eq 'Oracle') {
			$action{action} = 'SQL';
			$action{type} = 'do';
			my $cmd = $1;  $cmd =~ s/;+$//;
			$action{sql} = "begin $1; end;";
		}
	}

	$action{processed} = 1;
	return %action;
}

sub objectlist {
	my ($obj,$type,$text) = @_;
	my %action = (action => 'SQL', oper => 'complete', what => 'list', type => $type, context => $text);
	do {
		%action = $obj->{-core}->handle_action(%action);
	} until ($action{processed});
	return @{$action{list}} if ref $action{list} eq 'ARRAY';
	return ();
}

sub oracle_objectlist {
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

	if ($obj->{-dbi}->driver eq 'Oracle') {
		return $obj->oracle_objectlist('PACKAGE BODY') if $line =~ /^\s*(ALTER|DROP)\s+PACKAGE\s+BODY\s+\S*$/i;
		return ('BODY',$obj->oracle_objectlist('PACKAGE')) if $line =~ /^\s*(ALTER|DROP)\s+PACKAGE\s+\S*$/i;
		return $obj->oracle_objectlist($1) if $line =~ /^\s*(?:ALTER|DROP)\s+(PROCEDURE|FUNCTION|TRIGGER|VIEW|PACKAGE)\s+\S*$/i;
	}

	return ('(',qw/VALUES SELECT/) if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?INSERT\s+INTO\s+(\S+)\s+$/i;
	return qw/VALUES SELECT/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?INSERT\s+INTO\s+(\S+)\s+(\([^)]+\))?\s*[A-Z]*$/i;
	return ('(') if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?INSERT\s+INTO\s+(\S+)\s+(\([^)]+\)\s*)?VALUES\s*$/i;
	return ($obj->objectlist('PROCEDURE',$text),$obj->objectlist('PACKAGE',$text)) if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?(EXECUTE|BEGIN)\s+/i;
	return ($obj->objectlist('FUNCTION',$text),$obj->objectlist('SEQ',$text)) if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?INSERT\s+INTO\s+(\S+)\s+(\([^)]+\))?\s*VALUES/i;
	return ($obj->objectlist('CONTEXT',$text),$obj->objectlist('SEQ',$text)) if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?INSERT\s+INTO\s+(\S+)\s+(\([^)]+\))?\s*SELECT/i;
	return ($obj->objectlist('FIELDS',$1.'.')) if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?INSERT\s+INTO\s+(\S+)\s+/i;
	return qw/SELECT/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?EXPLAIN\s+PLAN\s+FOR\s+\S*$/i;
	return qw/FOR/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?EXPLAIN\s+PLAN\s+\S*$/i;
	return qw/PLAN/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?EXPLAIN\s+\S*$/i;
	return $obj->objectlist($1) if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?DROP\s+(PACKAGE\s+BODY|\S+)\s+\S*$/i;
	return qw/WHERE/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?DELETE\s+FROM\s+\S+\s+\S*$/i;
	return qw/STATISTICS/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?ANALYZE\s+TABLE\s+\S+\s+(COMPUTE|ESTIMATE|DELETE)\s+\S*$/i;
	return ('COMPUTE STATISTICS','ESTIMATE STATISTICS','DELETE STATISTICS') if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?ANALYZE\s+TABLE\s+\S+\s+\S*$/i;
	return qw/SET/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?UPDATE\s+\S+\s+\S*$/i;
	return $obj->objectlist('TABLE') if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?(TRUNCATE\s+TABLE|DELETE\s+FROM|INSERT\s+INTO|UPDATE|ALTER\s+TABLE|ANALYZE\s+TABLE)\s+\S*$/i;
	return qw/TABLE/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?TRUNCATE\s+\S*$/i;
	return qw/FROM/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?DELETE\s+\S*$/i;
	return qw/INTO/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?INSERT\s+\S*$/i;
	return qw/TABLE INDEX CLUSTER/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?ANALYZE\s+\S*$/i;
	return qw/TABLE SEQUENCE VIEW FUNCTION PACKAGE PROCEDURE TRIGGER/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?(DROP|CREATE|ALTER)\s+\S*$/i;
	return qw/SELECT EXPLAIN DELETE INSERT UPDATE CREATE DROP BEGIN ALTER TRUNCATE GRANT REVOKE ANALYZE EXECUTE/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?[A-Z]*$/i && $obj->{-dbi}->driver eq 'Oracle';
	return qw/SELECT EXPLAIN DELETE INSERT UPDATE CREATE DROP BEGIN ALTER TRUNCATE GRANT REVOKE ANALYZE/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?[A-Z]*$/i;
	return ($obj->objectlist('CONTEXT',$text),$obj->objectlist('SEQ',$text)) if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?(DELETE|UPDATE)\s+/i;
	return map { $1.$_ } ($obj->objectlist('CONTEXT',$text),$obj->objectlist('SEQ',$text)) if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?(?:SELECT|EXPLAIN\s+PLAN\s+FOR\s+SELECT)\s+(?:.*,\s+|.*?(\S*,)\S*$)?/i;
}

sub cmdhelp {
	my $obj = shift;

	my $helps = ['EXPLAIN PLAN FOR <select>' => 'Explain (Oracle) plan for executing query <select>'];
	push @$helps,('EXECUTE <plsql>' => 'Execute PL/SQL code') if $obj->{-dbi}->driver eq 'Oracle';
	return $helps;
}
