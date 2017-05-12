package DBIx::dbMan::Extension::CmdShowErrors;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000046-000005"; }

sub preference { return 2000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub menu {
	my $obj = shift;

	if ($obj->{-dbi}->current and $obj->{-dbi}->driver eq 'Oracle') {
		return ( { label => 'Connection', submenu => [
				{ label => 'Show errors', preference => -800,
					action => { action => 'COMMAND', cmd => 'show errors' } },
				{ separator => 1, preference => -500 }
			] } );
	} else {
		return ();
	}
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND' and $obj->{-dbi}->current and $obj->{-dbi}->driver eq 'Oracle') {
		if ($action{cmd} =~ /^show\s+errors?$/i) {
			$action{action} = 'SQL';
			$action{type} = 'select';
			$action{sql} = 'SELECT name,type,line,position,text FROM user_errors ORDER BY name,type,sequence';
			return %action;
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SHOW ERRORS' => 'Show errors in Oracle objects (only for Oracle)'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return unless $obj->{-dbi}->current;
	return unless $obj->{-dbi}->driver eq 'Oracle';
	return qw/ERRORS/ if $line =~ /^\s*SHOW\s+\S*$/i;
	return qw/SHOW/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
