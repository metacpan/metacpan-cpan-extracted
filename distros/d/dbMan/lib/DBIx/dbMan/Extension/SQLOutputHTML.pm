package DBIx::dbMan::Extension::SQLOutputHTML;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000028-000004"; }

sub preference { return 0; }

sub init {
	my $obj = shift;
	$obj->{-mempool}->register('output_format','html');
}

sub done {
	my $obj = shift;
	$obj->{-mempool}->deregister('output_format','html');
	if ($obj->{-mempool}->get('output_format') eq 'html') {
		my @all_formats = $obj->{-mempool}->get_register('output_format');
		$obj->{-mempool}->set('output_format',$all_formats[0]) if @all_formats;
	}
}
	
sub known_actions { return [ qw/SQL_OUTPUT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'SQL_OUTPUT') {
		if ($obj->{-mempool}->get('output_format') eq 'html') {
			my $output = "<TABLE>\n<TR>";
			$output .= join '',map { "<TH>$_</TH>" } @{$action{fieldnames}};
			$output .= "</TR>\n";
			for (@{$action{result}}) {
				$output .= "<TR>".(join '',map { "<TD>$_</TD>" } @$_);
				$output .= "</TR>\n";
			}
			$output .= "</TABLE>\n";
			$action{action} = 'OUTPUT';
			$action{output} = $output;
			delete $action{processed};
		}
	}

	return %action;
}
