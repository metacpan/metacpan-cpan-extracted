package DBIx::dbMan::Extension::TrimCmd;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000006-000004"; }

sub preference { return 5000; }

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND') {
		return %action if $action{cmd} =~ s/^\s+//;
		return %action if $action{cmd} =~ s/\s+$//;
	}

	$action{processed} = 1;
	return %action;
}
