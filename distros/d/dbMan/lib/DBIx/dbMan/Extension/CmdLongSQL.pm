package DBIx::dbMan::Extension::CmdLongSQL;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.07';

1;

sub IDENTIFICATION { return "000001-000055-000007"; }

sub preference { return 4000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub init {
	my $obj = shift;
	$obj->{prompt_num} = $obj->{-interface}->register_prompt(2000);
}

sub done {
	my $obj = shift;
	$obj->{-interface}->deregister_prompt($obj->{-prompt_num});
}

sub menu {
	my $obj = shift;

	if ($obj->{-mempool}->get('long_active')) {
		return ( { label => 'Input', submenu => [
				{ label => 'Execute long stored SQL now',
					action => { action => 'COMMAND',
						cmd => '\\g' } }
			] } );
	} else {
		return ();
	}
}

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'COMMAND') {
		if ($obj->{-mempool}->get('long_active')) {
			if ($action{cmd} =~ /^\\g$/i) {
				my $current = $obj->{-mempool}->get('long_buffer');
				$obj->{-mempool}->set('long_active',0);
				$action{cmd} = $current;
				$obj->{-interface}->prompt($obj->{prompt_num},'');
				$obj->{-mempool}->set('long_buffer','');

				my $history = new DBIx::dbMan::History -config => $obj->{-config};
				my @buffer = $history->load();
				pop @buffer while @buffer and $buffer[$#buffer] !~ /^\s*\\l/i;
				pop @buffer if @buffer;
				$obj->{-interface}->history_clear();
				for (@buffer) {
					$obj->{-interface}->history_add($_);
				}
				$obj->{-interface}->history_add($current);
				$obj->{-interface}->rebuild_menu();
			} else {
				my $current = $obj->{-mempool}->get('long_buffer');
				$current .= ' ' if $current;
				$current .= $action{cmd};
				$obj->{-mempool}->set('long_buffer',$current);
				$action{action} = 'NONE';
				$obj->{-interface}->prompt($obj->{prompt_num},'LONG');
				$obj->{-interface}->rebuild_menu();
			}
			delete $action{processed};
		} else {
			if ($action{cmd} =~ s/^\\l\s+//i) {
				my $current = $obj->{-mempool}->get('long_buffer');
				$current .= ' ' if $current;
				$current .= $action{cmd};
				$obj->{-mempool}->set('long_buffer',$current);
				$obj->{-mempool}->set('long_active',1);
				delete $action{processed};
				$action{action} = 'NONE';
				$obj->{-interface}->prompt($obj->{prompt_num},'LONG');
				$obj->{-interface}->rebuild_menu();
			}
		}
	}

	return %action;
}

sub cmdhelp {
	my $obj = shift;

	if ($obj->{-mempool}->get('long_active')) {
		return [
			'\g' => 'Execute long SQL (multiline command)',
		];
	} else {
		return [
			'\l <command>' => 'Long SQL (multiline command)',
		];
	}
}

sub restart_complete {
	my ($obj,$text,$line,$start) = @_;
	my %action = (action => 'LINE_COMPLETE', text => $text, line => $line,
		start => $start);
	do {
		%action = $obj->{-core}->handle_action(%action);
	} until ($action{processed});
	return @{$action{list}} if ref $action{list} eq 'ARRAY';
	return $action{list} if $action{list};
	return ();
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return () if $obj->{-mempool}->get('long_active_complete');
	if ($obj->{-mempool}->get('long_active')) {
		my @base = ();  my @res = ();
		@base = ('g') if $line =~ /^\s*\\[A-Z]*$/i;
		unless (@base) {
			@base = ('\g') if $line =~ /^\s*$/i;
			my $current = $obj->{-mempool}->get('long_buffer');
			$current .= ' ' if $current;
			$start += length($current);
			$current .= $line;
			$obj->{-mempool}->set('long_active_complete',1);
			@res = $obj->restart_complete($text,$current,$start);
			$obj->{-mempool}->set('long_active_complete',0);
		}
		return (@base,@res);
	}
	return $obj->restart_complete($text,$1,$start-(length($line)-length($1))) if $line =~ /^\s*\\l\s+(.*)$/i;
	return ('\l') if $line =~ /^\s*$/i;
	return ('l') if $line =~ /^\s*\\[A-Z]*$/i;
	return ();
}
