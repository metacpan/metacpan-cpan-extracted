package DBIx::dbMan::Extension::CmdSQLHelp;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.03';

1;

sub IDENTIFICATION { return "000001-000058-000003"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^\\h(\s+(.+))?$/i) {
			if ($1) {
				$action{action} = 'HELP';
				$action{type} = 'sql';
				$action{what} = $2;
			} else {
				$action{action} = 'OUTPUT';
				$action{output} = "You must specify SQL command for getting help.\n";
			}
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'\h <sql>' => 'Show help for SQL command'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return ('\h') if $line =~ /^\s*$/i;
	return ('h') if $line =~ /^\s*\\[A-Z]*$/i;
	return ();
}
