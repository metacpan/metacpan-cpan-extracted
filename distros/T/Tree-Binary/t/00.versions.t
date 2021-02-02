#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Tree::Binary; # For the version #.

use Test::More;

use constant;
use Scalar::Util;
use strict;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	constant
	Scalar::Util
	strict
	warnings
/;

diag "Testing Tree::Binary V $Tree::Binary::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
