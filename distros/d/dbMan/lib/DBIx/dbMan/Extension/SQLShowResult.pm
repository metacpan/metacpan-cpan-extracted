package DBIx::dbMan::Extension::SQLShowResult;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000015-000005"; }

sub preference { return 0; }

sub known_actions { return [ qw/SQL_RESULT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'SQL_RESULT') {
		if ($action{type} eq 'select') {
			$action{action} = 'SQL_OUTPUT';
			unless ($obj->{-mempool}->get('output_format')) {
				my @all_formats = $obj->{-mempool}->get_register('output_format');
				$obj->{-mempool}->set('output_format',$all_formats[0]) if @all_formats;
			}
			delete $action{processed};
		} elsif ($action{type} eq 'do') {
			if ($action{result} > -1) {
				$action{action} = 'OUTPUT';
				if ($action{result} ne '0E0') {
					$action{output} = "Processed ".$action{result}." line".(($action{result} == 1)?'':'s').".\n" ;
				} else {
					$action{output} = "Command processed.\n" ;
				}
			} else {
				$action{action} = 'NONE';
			}
		}
	}

	return %action;
}
