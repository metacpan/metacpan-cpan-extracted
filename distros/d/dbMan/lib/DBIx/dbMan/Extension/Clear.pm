package DBIx::dbMan::Extension::Clear;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000057-000004"; }

sub preference { return 0; }

sub known_actions { return [ qw/SCREEN/ ]; }

sub menu {
	return ( { label => '_Output', submenu => [
			{ label => 'Clear output area',
				action => { action => 'SCREEN', operation => 'clear' } }
		] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'SCREEN') {
		if ($action{operation} eq 'clear') {
			$obj->{-interface}->clear_screen();
			$action{action} = 'NONE';
		}
	}

	$action{processed} = 1;
	return %action;
}
