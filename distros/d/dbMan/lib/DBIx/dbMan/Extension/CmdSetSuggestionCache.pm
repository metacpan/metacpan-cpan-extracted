package DBIx::dbMan::Extension::CmdSetSuggestionCache;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000095-000001"; }

sub preference { return 1000; }

sub known_actions { return [ qw/COMMAND NOTIFY/ ]; }

sub init {
	my $obj = shift;

	$obj->{prompt_num} = $obj->{-interface}->register_prompt(800);
	$obj->{prompt_title} = $obj->{-config}->prompt_tabcache || '[tab-cache]';
}

sub done {
	my $obj = shift;

	$obj->{-interface}->deregister_prompt( $obj->{prompt_num} );
}

sub menu {
	my $obj = shift;

	my $local_mempool = $obj->{-dbi}->mempool();
	unless ( $local_mempool ) {
		$obj->{-interface}->prompt($obj->{prompt_num}, '');
		return ();
	}

	my $dir = 'on';  my $sel = ' ';
	$sel = '*' if $local_mempool->get('suggestion_cache');
	$dir = 'off' if $sel eq '*';

	return ( { label => 'Settings', submenu => [
			{ label => $sel.' '.'Suggestion cache',
				action => { action => 'COMMAND',
					cmd => 'set suggestion cache '.$dir } }
		] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		if ($action{cmd} =~ /^set\s+suggestion\s+cache\s+(on|off)$/i) {
			my $want = lc $1;  my $owant = $want;
			$want = '' if $want eq 'off';
			$action{action} = 'OUTPUT';

			my $local_mempool = $obj->{-dbi}->mempool();
			if ( $local_mempool ) {
				$local_mempool->set('suggestion_cache',$want);
				$action{output} = "Suggestion cache $owant.\n";
				if ( $local_mempool->get('suggestion_cache') ) {
					$obj->{-interface}->prompt($obj->{prompt_num}, $obj->{prompt_title});
				} else {
					$obj->{-interface}->prompt($obj->{prompt_num}, '');
				}
			} else {
				$action{output} = "There is no active connection where suggestion cache can be used.\n";
				$obj->{-interface}->prompt($obj->{prompt_num}, '');
			}
			$obj->{-interface}->rebuild_menu();
		}
	} elsif ( $action{action} eq 'NOTIFY' and $action{notify} eq 'connection_change' ) {
			my $local_mempool = $obj->{-dbi}->mempool();

			if ( $local_mempool and $local_mempool->get('suggestion_cache') ) {
				$obj->{-interface}->prompt($obj->{prompt_num}, $obj->{prompt_title});
			} else {
				$obj->{-interface}->prompt($obj->{prompt_num}, '');
			}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdhelp {
	return [
		'SET SUGGESTION CACHE [ON|OFF]' => 'Set suggestion cache on or off.'
	];
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
			
	my $local_mempool = $obj->{-dbi}->mempool();
	if ( $local_mempool ) {
		return qw/ON OFF/ if $line =~ /^\s*SET\s+SUGGESTION\s+CACHE\s+\S*$/i;
		return qw/CACHE/ if $line =~ /^\s*SET\s+SUGGESTION\s+\S*$/i;
		return qw/SUGGESTION/ if $line =~ /^\s*SET\s+\S*$/i;
		return qw/SET/ if $line =~ /^\s*[A-Z]*$/i;
	}
	return ();
}
