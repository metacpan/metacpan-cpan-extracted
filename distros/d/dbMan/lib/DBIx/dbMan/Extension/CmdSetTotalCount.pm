package DBIx::dbMan::Extension::CmdSetTotalCount;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.03';

1;

sub IDENTIFICATION { return "000001-000074-000003"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub menu {
	my $obj = shift;

	my $dir = 'on';  my $sel = ' ';
	$sel = '*' if $obj->{-mempool}->get('total_count');
	$dir = 'off' if $sel eq '*';

	return ( { label => 'Settings', submenu => [
			{ label => $sel.' '.'Show total count of lines and cols',
				action => { action => 'COMMAND',
					cmd => 'set total count '.$dir } }
		] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^set\s+total\s*count\s+(on|off)$/i) {
			my $want = lc $1;  my $owant = $want;
			$want = ($want eq 'off')?0:1;
			$obj->{-mempool}->set('total_count',$want);
			$action{action} = 'OUTPUT';
			$action{output} = "Total size info messages $owant.\n";
			$obj->{-interface}->rebuild_menu();
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SET TOTAL COUNT [ON|OFF]' => 'Set total count info messages on or off.'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/ON OFF/ if $line =~ /^\s*SET\s+TOTAL\s+COUNT\s+\S*$/i;
	return qw/COUNT/ if $line =~ /^\s*SET\s+TOTAL\s+\S*$/i;
	return qw/TOTAL/ if $line =~ /^\s*SET\s+\S*$/i;
	return qw/SET/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
