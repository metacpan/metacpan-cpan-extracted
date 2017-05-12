package DBIx::dbMan::Extension::OutputQuiet;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.02';

1;

sub IDENTIFICATION { return "000001-000081-000002"; }

sub preference { return -45; }

sub known_actions { return [ qw/OUTPUT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	$action{action} = 'NONE' if $action{action} eq 'OUTPUT' && $action{output_quiet};

	return %action;
}
