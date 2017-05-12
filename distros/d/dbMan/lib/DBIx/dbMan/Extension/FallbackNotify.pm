package DBIx::dbMan::Extension::FallbackNotify;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000097-000001"; }

sub preference { return -99990; }

sub known_actions { return [ qw/NOTIFY/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;

	$action{action} = 'NONE' if $action{action} eq 'NOTIFY';

	return %action;
}
