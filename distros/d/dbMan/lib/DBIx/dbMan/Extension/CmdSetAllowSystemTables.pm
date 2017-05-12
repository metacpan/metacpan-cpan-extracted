package DBIx::dbMan::Extension::CmdSetAllowSystemTables;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.02';

1;

sub IDENTIFICATION { return "000001-000083-000002"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub menu {
	my $obj = shift;

	my $dir = 'on';  my $sel = ' ';
	$sel = '*' if $obj->{-mempool}->get('allow_system_tables');
	$dir = 'off' if $sel eq '*';

	return ( { label => 'Settings', submenu => [
			{ label => $sel.' '.'Include system tables to lists',
				action => { action => 'COMMAND',
					cmd => 'set alow system tables '.$dir } }
		] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^set\s+allow\s*system\s*tables\s+(on|off)$/i) {
			my $want = lc $1;  my $owant = $want;
			$want = ($want eq 'off')?0:1;
			$obj->{-mempool}->set('allow_system_tables',$want);
			$action{action} = 'OUTPUT';
			$action{output} = "Allow system tables in completation set to $owant now.\n";
			$obj->{-interface}->rebuild_menu();
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SET ALLOW SYSTEM TABLES [ON|OFF]' => 'Allow system tables in completation on or off.'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/ON OFF/ if $line =~ /^\s*SET\s+ALLOW\s+SYSTEM\s+TABLES\s+\S*$/i;
	return qw/TABLES/ if $line =~ /^\s*SET\s+ALLOW\s+SYSTEM\s+\S*$/i;
	return qw/SYSTEM/ if $line =~ /^\s*SET\s+ALLOW\s+\S*$/i;
	return qw/ALLOW/ if $line =~ /^\s*SET\s+\S*$/i;
	return qw/SET/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
