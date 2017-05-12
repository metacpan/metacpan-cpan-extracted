package DBIx::dbMan::Extension::CmdCount;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.02';

1;

sub IDENTIFICATION { return "000001-000078-000002"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND' and $obj->{-dbi}->current) {
		if ($action{cmd} =~ /^(?:\/\*.*?\*\/\s*)?count\s+(.*)(?:\s*\/\*.*?\*\/)?$/i) {
			$action{action} = 'COUNT';
			$action{count_tables} = [ split /,/,$1 ];
		} elsif ($action{cmd} =~ /^(?:\/\*.*?\*\/\s*)?countre\s+(.*)(?:\s*\/\*.*?\*\/)?$/i) {
			$action{action} = 'COUNT';
			$action{count_re} = $1 || '^';
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

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return () unless $obj->{-dbi}->current;
	return map { $1.$_ } $obj->objectlist('TABLE',$2) if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?COUNT\s+(?:.*,\s+|.*?(\S*,))?(\S*)$/i;
	return qw/COUNT COUNTRE/ if $line =~ /^\s*(?:\/\*.*?\*\/\s*)?[A-Z]*$/i;
}

sub cmdhelp {
	my $obj = shift;

	return [ 'COUNT <table>,...' => 'Select base statistics of tables',
		 'COUNTRE <re>' => 'COUNT on table name fit to RE' ] if $obj->{-dbi}->current;
	return [];
}
