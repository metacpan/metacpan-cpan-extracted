package DBIx::dbMan::Extension::CmdHistory;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000034-000004"; }

sub preference { return 2000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^show(\s+commands?)?\s+history$/i) {
			$action{action} = 'HISTORY';
			$action{operation} = 'show';
		} elsif ($action{cmd} =~ /^(clear|erase)(\s+commands?)?\s+history$/i) {
			$action{action} = 'HISTORY';
			$action{operation} = 'clear';
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SHOW HISTORY' => 'Show commands history',
		'CLEAR HISTORY' => 'Clear commands history'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/HISTORY/ if $line =~ /^\s*(SHOW|CLEAR)\s+\S*$/i;
	return qw/SHOW CLEAR/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
