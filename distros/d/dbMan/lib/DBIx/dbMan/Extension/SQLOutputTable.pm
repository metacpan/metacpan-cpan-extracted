package DBIx::dbMan::Extension::SQLOutputTable;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000026-000004"; }

sub preference { return -25; }

sub known_actions { return [ qw/SQL_OUTPUT/ ]; }

sub init {
	my $obj = shift;
	$obj->{-mempool}->register('output_format','table');
	$obj->{-mempool}->set('output_format','table') unless $obj->{-mempool}->get('output_format');
}

sub done {
	my $obj = shift;
	$obj->{-mempool}->deregister('output_format','table');
	if ($obj->{-mempool}->get('output_format') eq 'table') {
		my @all_formats = $obj->{-mempool}->get_register('output_format');
		$obj->{-mempool}->set('output_format',$all_formats[0]) if @all_formats;
	}
}
	
sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'SQL_OUTPUT') {	# table is standard fallback
		# $action{fieldtypes} - formatting ?
		my $table = new Text::FormatTable ('|'.( 'l|' x scalar @{$action{fieldnames}} ));
		$table->rule;
		$table->head(@{$action{fieldnames}});
		$table->rule;
		for (@{$action{result}}) {
			$table->row(@$_);
		}
		$table->rule;
		$action{action} = 'OUTPUT';
		$action{output} = $table->render($obj->{-interface}->render_size);
		delete $action{processed};
	}

	return %action;
}
