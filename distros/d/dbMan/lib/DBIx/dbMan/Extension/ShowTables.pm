package DBIx::dbMan::Extension::ShowTables;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000020-000005"; }

sub preference { return 0; }

sub known_actions { return [ qw/SHOW_TABLES/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'SHOW_TABLES') {
		$action{action} = 'NONE';
		unless ($obj->{-dbi}->current) {
			$obj->{-interface}->error("No current connection selected.");
			return %action;
		}	

		my $table = new Text::FormatTable '| l | l | l |';
		$table->rule;
		$table->head('SCHEMA','NAME','TYPE');
		$table->rule;

		my $sth = $obj->{-dbi}->table_info();
		my $ret = $sth->fetchall_arrayref();
		study $action{mask};
		if (defined $ret) {
			for (sort { 
				($a->[1] eq $b->[1]) 
				? ($a->[2] cmp $b->[2]) 
				: ($a->[1] cmp $b->[1]) } @$ret) {
				if (($action{type} eq 'object' or
				  $action{type} eq lc $_->[3]) and
				  $action{mask} and
				  $_->[1] =~ /$action{mask}/i) {
					$table->row($_->[1],$_->[2],$_->[3]);
				}
			}
		}
		$sth->finish;
		$table->rule;
		$action{action} = 'OUTPUT';
		$action{output} = $table->render($obj->{-interface}->render_size);
	}

	$action{processed} = 1;
	return %action;
}
