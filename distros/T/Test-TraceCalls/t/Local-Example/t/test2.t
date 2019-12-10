use strict;
use warnings;
use Test::More (
	$ENV{PERL_TRACE_CALLS_SUITE}
		? (tests => 3)
		: (skip_all => 'please run via 01basic.t')
);

use File::Spec;
use FindBin qw($Bin);
use lib File::Spec->catdir($Bin, '..', 'lib');
use lib File::Spec->catdir($Bin, '..', '..', '..', 'lib');

use Local::Example;

is(
	Local::Example::Module2::foo(),
	'Local::Example::Module2->foo',
);

is(
	Local::Example::Module2::bar(),
	'Local::Example::Module1->bar',
);

Local::Example::quux();

is(
	Local::Example::quux(),
	'Local::Example->quux',
);
