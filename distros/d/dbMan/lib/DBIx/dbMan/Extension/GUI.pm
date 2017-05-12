package DBIx::dbMan::Extension::GUI;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000093-000001"; }

sub preference { return 5000; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND' and not $action{gui_tested}
			and $obj->{-mempool}->get('gui')) {
		++$action{gui};
		delete $action{processed};
	} else {
		$action{processed} = 1;
	}

	++$action{gui_tested};

	return %action;
}
