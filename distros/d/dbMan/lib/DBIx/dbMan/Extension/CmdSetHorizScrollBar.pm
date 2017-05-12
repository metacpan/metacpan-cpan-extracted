package DBIx::dbMan::Extension::CmdSetHorizScrollBar;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000089-000001"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub load_ok {
	my $obj = shift;

	return $obj->{-interface}->can('horizontal_scrollbar');
}

sub menu {
	my $obj = shift;

	my $dir = 'on';  my $sel = ' ';
	$sel = '*' if $obj->{-interface}->horizontal_scrollbar();
	$dir = 'off' if $sel eq '*';

	return ( { label => 'Settings', submenu => [
			{ label => $sel.' '.'Horizontal scrollbar',
				action => { action => 'COMMAND',
					cmd => 'set horizontal scrollbar '.$dir } }
		] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^set\s+horiz(?:ontal)?(?:\s+scrollbars?)?\s+(on|off)$/i) {
			my $want = lc $1;  my $owant = $want;
			$want = ($want eq 'off')?0:1;
			$obj->{-interface}->horizontal_scrollbar($want);
			$action{action} = 'OUTPUT';
			$action{output} = "Set horizontal scrollbar to $owant now.\n";
			$obj->{-interface}->rebuild_menu();
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SET HORIZONTAL SCROLLBAR [ON|OFF]' => 'Select usage of horizontal scrollbar in output windows.'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/ON OFF/ if $line =~ /^\s*SET\s+HORIZ(ONTAL)?(\s+SCROLLBAR)?\s+\S*$/i;
	return qw/SCROLLBAR/ if $line =~ /^\s*SET\s+HORIZ(ONTAL)?\s+\S*$/i;
	return qw/HORIZONTAL/ if $line =~ /^\s*SET\s+\S*$/i;
	return qw/SET/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
