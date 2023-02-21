package DBIx::dbMan::Extension::SQLOutputMarkdown;

use strict;
use base 'DBIx::dbMan::Extension';
use utf8;
use Text::FormatTable;
use Term::ANSIColor;

our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000100-000001"; }

sub preference { return 0; }

sub known_actions { return [ qw/SQL_OUTPUT/ ]; }

sub init {
	my $obj = shift;
	$obj->{-mempool}->register('output_format','markdown');
}

sub done {
	my $obj = shift;
	$obj->{-mempool}->deregister('output_format','markdown');
	if ($obj->{-mempool}->get('output_format') eq 'markdown') {
		my @all_formats = $obj->{-mempool}->get_register('output_format');
		$obj->{-mempool}->set('output_format', @all_formats ? $all_formats[0] : '');
	}
}
	
sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'SQL_OUTPUT') {	# table is standard fallback
		if ($obj->{-mempool}->get('output_format') eq 'markdown') {
			my $output = '';
			$output .= '| ' . ( join ' | ', @{ $action{ fieldnames } } ) . ' |' . "\n";
			$output .= '| ' . ( join ' | ', map { '---' } @{ $action{ fieldnames } } ) . ' |' . "\n";

			for ( @{ $action{ result } } ) {
				$output .= '| ' . ( join ' | ', @$_ ) . ' |' . "\n";
			}

			$action{action} = 'OUTPUT';
			$action{output} = $output;
			delete $action{processed};
		}
	}

	return %action;
}
