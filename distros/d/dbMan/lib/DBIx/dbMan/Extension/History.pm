package DBIx::dbMan::Extension::History;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;
use DBIx::dbMan::History;

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000035-000005"; }

sub preference { return 0; }

sub known_actions { return [ qw/HISTORY/ ]; }

sub menu {
	my $obj = shift;

	return ( { label => 'Input', submenu => [
			{ label => 'History', submenu => [
				{ label => 'Show', action => { action => 'HISTORY',
					operation => 'show' } },
				{ label => 'Clear', action => { action => 'HISTORY',
					operation => 'clear' } }
		] } ] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'HISTORY') {
		if ($action{operation} eq 'show') {
			my $table = new Text::FormatTable '| r l |';
			$table->rule;
			my $i = 1;
			my $history = new DBIx::dbMan::History -config => $obj->{-config};
			for ($history->load()) {	
				$table->row("$i.",$_);
				++$i;
			}
			$table->rule;
			$action{action} = 'OUTPUT';
			$action{output} = $table->render($obj->{-interface}->render_size);
		} elsif ($action{operation} eq 'clear') {
			$obj->{-interface}->history_clear();
			$action{action} = 'OUTPUT';
			$action{output} = "Commands history cleared.\n";
		}
	}

	$action{processed} = 1;
	return %action;
}
