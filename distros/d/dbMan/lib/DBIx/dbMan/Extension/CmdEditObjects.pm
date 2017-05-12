package DBIx::dbMan::Extension::CmdEditObjects;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000042-000005"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub init {
	my $obj = shift;
	$obj->{-mempool}->set('edit_object_errors',1);
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^edit\s+(?:(.*)\s+)?(\S+)$/i) {
			$action{action} = 'EDIT_OBJECT';
			$action{type} = $1;
			$action{what} = $2;
		} elsif ($action{cmd} =~ /^set\s+edit\s+object\s+errors\s+(on|off)$/i) {
			my $want = lc $1;  my $owant = $want;
			$want = ($want eq 'off')?0:1;
			$obj->{-mempool}->set('edit_object_errors',$want);
			$action{action} = 'OUTPUT';
			$action{output} = "Edit object errors $owant.\n";
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'EDIT <objectname>' => 'Edit object with <objectname>',
		'SET EDIT OBJECT ERRORS [ON|OFF]' => 'Set edit object errors on or off.'
		];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/ON OFF/ if $line =~ /^\s*SET\s+EDIT\s+OBJECT\s+ERRORS\s+\S*$/i;
	return qw/ERRORS/ if $line =~ /^\s*SET\s+EDIT\s+OBJECT\s+\S*$/i;
	return qw/OBJECT/ if $line =~ /^\s*SET\s+EDIT\s+\S*$/i;
	return qw/EDIT/ if $line =~ /^\s*SET\s+\S*$/i;
	return qw/SET/ if $line =~ /^\s*[A-Z]*$/i and not $obj->{-dbi}->current;
	return qw/SET EDIT/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
