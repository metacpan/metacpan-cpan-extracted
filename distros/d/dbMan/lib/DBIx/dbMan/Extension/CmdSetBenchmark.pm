package DBIx::dbMan::Extension::CmdSetBenchmark;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000050-000004"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub menu {
	my $obj = shift;

	my $dir = 'on';  my $sel = ' ';
	$sel = '*' if $obj->{-mempool}->get('benchmark');
	$dir = 'off' if $sel eq '*';

	return ( { label => 'Settings', submenu => [
			{ label => $sel.' '.'Benchmarking',
				action => { action => 'COMMAND',
					cmd => 'set benchmark '.$dir } }
		] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^set\s+benchmark\s+(on|off)$/i) {
			my $want = lc $1;  my $owant = $want;
			$want = '' if $want eq 'off';
			$action{action} = 'OUTPUT';
			$obj->{-mempool}->set('benchmark',$want);
			$action{output} = "Benchmarking $owant.\n";
			$obj->{-interface}->rebuild_menu();
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SET BENCHMARK [ON|OFF]' => 'Set benchmarking on or off.'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/ON OFF/ if $line =~ /^\s*SET\s+BENCHMARK\s+\S*$/i;
	return qw/BENCHMARK/ if $line =~ /^\s*SET\s+\S*$/i;
	return qw/SET/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
