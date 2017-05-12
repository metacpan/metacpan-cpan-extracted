package DBIx::dbMan::Extension::Format;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.02';

1;

sub IDENTIFICATION { return "000001-000063-000002"; }

sub preference { return -75; }

sub handle_action {
	my ($obj,%action) = @_;

	if (exists $action{old_output_format}) {
		$obj->{-mempool}->set('output_format',$action{old_output_format});
	}

	$action{processed} = 1;
	return %action;
}
