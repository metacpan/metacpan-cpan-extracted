package DBIx::dbMan::Extension::ClipboardInfo;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.02';

1;

sub IDENTIFICATION { return "000001-000066-000002"; }

sub preference { return -38; }

sub known_actions { return [ qw/OUTPUT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'OUTPUT' and $action{output_info}) {
		$action{output} .= $action{output_info};
	}

	return %action;
}
