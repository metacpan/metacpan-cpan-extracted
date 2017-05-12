package DBIx::dbMan::Extension::CmdSetGUI;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000092-000001"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub init {
	my $obj = shift;

	my $cfg = 1;
	$cfg = $obj->{-config}->gui() if defined $obj->{-config}->gui();
	$obj->{-mempool}->set('gui',$cfg);
}

sub menu {
	my $obj = shift;

	my $dir = 'on';  my $sel = ' ';
	$sel = '*' if $obj->{-mempool}->get('gui');
	$dir = 'off' if $sel eq '*';

	return ( { label => 'Settings', preference => -1, submenu => [
			{ label => $sel.' '.'Use rather GUI version of commands',
				action => { action => 'COMMAND',
					cmd => 'set gui '.$dir } }
		] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^set\s+(?:gui)\s+(on|off)$/i) {
			my $want = lc $1;  my $owant = $want;
			$want = ($want eq 'off')?0:1;
			$obj->{-mempool}->set('gui',$want);
			$action{action} = 'OUTPUT';
			$action{output} = "Use GUI version of commands $owant.\n";
			$obj->{-interface}->rebuild_menu;
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SET GUI [ON|OFF]' => 'Set using of GUI version of commands on or off.'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/ON OFF/ if $line =~ /^\s*SET\s+GUI\s+\S*$/i;
	return qw/GUI/ if $line =~ /^\s*SET\s+\S*$/i;
	return qw/SET/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
