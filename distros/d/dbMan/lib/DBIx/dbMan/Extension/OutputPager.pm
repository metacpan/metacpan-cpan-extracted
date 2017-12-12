package DBIx::dbMan::Extension::OutputPager;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000037-000005"; }

sub preference { return -50; }

sub known_actions { return [ qw/OUTPUT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'OUTPUT' and $action{output_pager} and $obj->{-interface}->can_pager()) {
		open F,"|less";
        if ( $obj->{ -interface }->is_utf8 ) {
            binmode F, ':utf8';
        }
		print F $action{output};
		close F;
		$action{action} = 'NONE';
	}

	$action{processed} = 1;
	return %action;
}
