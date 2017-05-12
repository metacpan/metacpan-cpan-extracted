#!perl -w

use strict;
use Test::More tests => 1;

use File::Spec;
use FindBin qw($Bin);
use lib File::Spec->join($Bin, 'tlib');

use XSLoader; # preload

use Test::Warn;

use warnings::unused -global;

sub make_pat{
	my $n = shift;

	(qr/^Unused variable my [\$\@\%][a-z]_unused/) x $n;
}

warnings_like
	{ require Foo }
	[ make_pat(7)],
	'-global';


