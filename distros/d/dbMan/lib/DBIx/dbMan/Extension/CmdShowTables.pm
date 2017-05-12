package DBIx::dbMan::Extension::CmdShowTables;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.06';

1;

sub IDENTIFICATION { return "000001-000019-000006"; }

sub preference { return 2000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^(?:show\s+(object|table|view|sequence)s?|\\dt)(?:\s+(\S+))?$/i) {
			$action{action} = 'SHOW_TABLES';
			$action{type} = lc $1;
			$action{type} = 'table' unless $action{type};
			$action{mask} = uc $2;
			$action{mask} = '^' if $action{mask} eq '';
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SHOW [OBJECTS|TABLES|VIEWS|SEQUENCES] [<RE-filter>]' => 'Show tables/views/sequences/all objects in current connection'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return () unless $obj->{-dbi}->current;
	return qw/OBJECTS TABLES VIEWS SEQUENCES/ if $line =~ /^\s*SHOW\s+\S*$/i;
	return ('SHOW','\dt') if $line =~ /^\s*$/;
	return ('dt') if $line =~ /^\s*\\[A-Z]*$/i;
	return qw/SHOW/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
