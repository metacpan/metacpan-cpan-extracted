package DBIx::dbMan::Extension::CmdInputFile;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000023-000005"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^(?:\\i\s+|\@)(.*)$/i) {
			$action{action} = 'INPUT_FILE';
			$action{file} = $1;
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'\i <file>' => 'Input commands from <file>'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return $obj->{-interface}->filenames_complete($text,$line,$start) if $line =~ /^\s*(\\i\s+|@)/;
	return ('\i','@') if $line =~ /^\s*$/i;
	return ('i') if $line =~ /^\s*\\[A-Z]*$/i;
	return ();
}
