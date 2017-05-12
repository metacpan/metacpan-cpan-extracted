package DBIx::dbMan::Extension::CmdSetTracing;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.03';

1;

sub IDENTIFICATION { return "000001-000061-000003"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub menu {
	my $obj = shift;

	my $dir = 'on';  my $sel = ' ';
	$sel = '*' if $obj->{-core}->{-trace};
	$dir = 'off' if $sel eq '*';

	return ( { label => 'dbMan', submenu => [
			{ label => 'Extensions', submenu => [
				{ separator => 1, preference => -1000 },
				{ label => $sel.' '.'Trace extensions calls',
					preference => -1200,
					action => { action => 'COMMAND',
						cmd => 'set tracing '.$dir } }
		] } ] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^set\s+tracing\s+(on|off)$/i) {
			my $want = lc $1;  my $owant = $want;
			$want = ($want eq 'off')?0:1;
			$obj->{-core}->{-trace} = $want;
			$action{action} = 'OUTPUT';
			$action{output} = "Tracing $owant.\n";
			$obj->{-interface}->rebuild_menu();
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SET TRACING [ON|OFF]' => 'Set tracing extensions on or off.'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return qw/ON OFF/ if $line =~ /^\s*SET\s+TRACING\s+\S*$/i;
	return qw/TRACING/ if $line =~ /^\s*SET\s+\S*$/i;
	return qw/SET/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
