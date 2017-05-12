package t::lib::Display;
use strict;
use warnings FATAL => 'all';

our $VERSION = '1.07';

use Test::More;
use Test::NeedsDisplay ':skip_all';

sub xeyes {
	my $xeyes = '/usr/bin/xeyes';

	plan skip_all => "No $xeyes" if not -e $xeyes;
	
	plan tests => 2;
	$SIG{ALRM} = sub { die "TIMEOUT\n" };
	alarm(1);
	my $pid = open(my $ph, "|$xeyes");
	eval {
		if (ok($pid, 'running xeyes')) {
			diag "PID $pid";
			sleep 3;
		}
	};
	alarm(0);
	ok($@ and $@ eq "TIMEOUT\n");
	if ($pid) {
		kill 9, $pid;
	}
}


1;


