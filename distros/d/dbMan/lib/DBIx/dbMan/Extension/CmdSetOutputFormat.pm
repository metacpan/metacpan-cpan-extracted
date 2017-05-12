package DBIx::dbMan::Extension::CmdSetOutputFormat;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.06';

1;

sub IDENTIFICATION { return "000001-000025-000006"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub menu {
	my $obj = shift;

	my $current = $obj->{-mempool}->get('output_format');

	my @menu = ();
	for ($obj->{-mempool}->get_register('output_format')) {
		my $sel = ' ';
		$sel = '*' if $_ eq $current;
		push @menu,{ label => $sel.' '.$_,
			action => { action => 'COMMAND', cmd => 'set output format to '.$_ } };
	}

	return ( { label => '_Output', submenu => [
			{ label => 'Output format', submenu => \@menu }
		] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^set\s+output\s+format\s*(=|to\s)?\s*(.*)$/i) {
			my $want = lc $2;
			my @fmts = $obj->{-mempool}->get_register('output_format');
			my %fmts = ();
			for (@fmts) { ++$fmts{$_}; }
			$action{action} = 'OUTPUT';
			if ($fmts{$want}) {
				$obj->{-mempool}->set('output_format',$want);
				$action{output} = "Output format $want selected.\n";
				$obj->{-interface}->rebuild_menu();
			} else {
				$action{output} = "Unknown output format.\n".
					"Registered formats: ".(join ',',sort @fmts)."\n";
			}
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SET OUTPUT FORMAT TO <format>' => 'Select another SQL output format'
	];
}

sub formatlist {
	my $obj = shift;
	return $obj->{-mempool}->get_register('output_format');
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return $obj->formatlist if $line =~ /^\s*SET\s+OUTPUT\s+FORMAT\s+TO\s+\S*$/i;
	return qw/TO/ if $line =~ /^\s*SET\s+OUTPUT\s+FORMAT\s+\S*$/i;
	return qw/FORMAT/ if $line =~ /^\s*SET\s+OUTPUT\s+\S*$/i;
	return qw/OUTPUT/ if $line =~ /^\s*SET\s+\S*$/i;
	return qw/SET/ if $line =~ /^\s*[A-Z]*$/i;
	return ();
}
