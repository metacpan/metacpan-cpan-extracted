package DBIx::dbMan::Extension::LineComplete;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.03';

1;

sub IDENTIFICATION { return "000001-000048-000003"; }

sub preference { return 3999; }

sub known_actions { return [ qw/LINE_COMPLETE/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'LINE_COMPLETE') {
		$action{list} = [];
		my %maybe = ();
		for my $ext (@{$obj->{-core}->{extensions}}) {
			if ($ext->can('cmdcomplete')) {
				study "\Q$action{text}";
				for ($ext->cmdcomplete($action{text},$action{line},$action{start})) {
					++$maybe{$_} if /^\Q$action{text}/i;
				}
			}
		}
		$action{list} = [ sort keys %maybe ];
		$action{action} = 'NONE';
	}
	$action{processed} = 1;

	return %action;
}
