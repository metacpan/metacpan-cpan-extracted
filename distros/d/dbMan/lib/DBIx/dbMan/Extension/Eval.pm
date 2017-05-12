package DBIx::dbMan::Extension::Eval;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.02';

1;

sub IDENTIFICATION { return "000001-000072-000002"; }

sub preference { return 0; }

sub known_actions { return [ qw/EVAL/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'EVAL') {
		if ($action{type} eq 'perl') {
			my $code = $action{what};
			eval $code;
			$action{action} = 'OUTPUT';
			$action{output} = $@ || '';
		} elsif ($action{type} eq 'system') {
			my $code = $action{what};
			$action{action} = 'OUTPUT';
			$action{output} = `$code`;
		} else {
			return %action;
		}
	}

	$action{processed} = 1;
	return %action;
}
