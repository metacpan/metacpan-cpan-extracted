package DBIx::dbMan::Extension::CmdKeyBindings;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000088-000001"; }

sub preference { return 2000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^show\s+keys?$/i) {
			$action{action} = 'KEYS';
			$action{operation} = 'show';
		} elsif ($action{cmd} =~ /^(?:clear|erase)\s+keys?(\s+permanent(?:ly)?)?$/i) {
			$action{action} = 'KEYS';
			$action{operation} = 'clear';
			$action{permanent} = $1?1:0;
		} elsif ($action{cmd} =~ /^(re)?load\s+keys?$/i) {
			$action{action} = 'KEYS';
			$action{operation} = 'reload';
		} elsif ($action{cmd} =~ /^def(?:ine)?\s+key(?:\s+for)?\s+(.+)$/i) {
			$action{action} = 'KEYS';
			$action{operation} = 'define';
			$action{text} = $1;
		} elsif ($action{cmd} =~ /^undef(?:ine)?\s+key\s*$/i) {
			$action{action} = 'KEYS';
			$action{operation} = 'undefine';
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SHOW KEYS' => 'Show key bindings',
		'CLEAR KEYS [PERMAMENT]' => 'Clear key bindings - permanent or temporary',
		'RELOAD KEYS' => 'Reload key bindings from file',
		'DEFINE KEY FOR <macro>' => 'Define key for macro text',
		'UNDEFINE KEY' => 'Undefine key (pressed)'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/PERMANENT/ if $line =~ /^\s*(CLEAR|ERASE)\s+KEYS\s+\S*$/i;
	return qw/FOR/ if $line =~ /^\s*DEFINE\s+KEY\s+\S*$/i;
	return qw/KEYS/ if $line =~ /^\s*(SHOW|CLEAR|ERASE|RELOAD)\s+\S*$/i;
	return qw/KEY/ if $line =~ /^\s*(UN)?DEFINE\s+\S*$/i;
	return qw/SHOW CLEAR RELOAD DEFINE UNDEFINE/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
