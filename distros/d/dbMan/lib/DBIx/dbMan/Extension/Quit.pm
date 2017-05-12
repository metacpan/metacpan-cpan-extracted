package DBIx::dbMan::Extension::Quit;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.08';

1;

sub IDENTIFICATION { return "000001-000003-000008"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub menu {
    return ( { label => 'dbMan', preference => 10000, submenu => [
			{ label => 'Quit', preference => -1000, action => { action => 'QUIT' } },
			{ separator => 1, preference => -999 }
		] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND' 
		and $action{cmd} =~ /^(quit|exit|log ?out|\\q)$/i) {
			$action{action} = 'QUIT';
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		QUIT => 'Exit this program'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/q/ if $line =~ /^\s*\\[A-Z]*$/i;
	return qw/QUIT EXIT LOGOUT \q/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
