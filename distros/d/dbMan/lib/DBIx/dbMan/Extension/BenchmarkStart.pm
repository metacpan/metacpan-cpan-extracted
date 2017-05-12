package DBIx::dbMan::Extension::BenchmarkStart;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000051-000004"; }

sub preference { return 99999; }

sub init {
	my $obj = shift;

	$obj->{hires} = 0;
	eval q{
		use Time::HiRes qw/gettimeofday/;
	};
	++$obj->{hires} unless $@;
}

sub known_actions { return [ qw/COMMAND/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'COMMAND' and 
	  $obj->{-mempool}->get('benchmark') and
	  not $action{benchmark_starttime}) {
		if ($obj->{hires}) {
			eval q{
				$action{benchmark_starttime} = [ gettimeofday ];
			};
		} else {
			$action{benchmark_starttime} = time;
		}
	}

	$action{processed} = 1;
	return %action;
}
