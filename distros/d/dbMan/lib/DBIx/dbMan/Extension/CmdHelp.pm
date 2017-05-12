package DBIx::dbMan::Extension::CmdHelp;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.08';

1;

sub IDENTIFICATION { return "000001-000009-000008"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^help(?:\s+(.+))?$/i) {
			$action{action} = 'HELP';
			$action{type} = 'commands';
			$action{what} = $1;
		} elsif ($action{cmd} =~ /^(show\s+)?versions?$/i) {
			$action{action} = 'HELP';
			$action{type} = 'version';
		} elsif ($action{cmd} =~ /^(show\s+)?licen[cs]e$/i) {
			$action{action} = 'HELP';
			$action{type} = 'license';
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'HELP' => 'Show this help',
		'SHOW VERSION' => 'Show dbMan'."'".'s version',
		'SHOW LICENSE' => 'Show dbMan'."'".'s license'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/VERSION LICENSE/ if $line =~ /^\s*SHOW\s+[A-Z]*$/i;
	return qw/HELP SHOW/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
