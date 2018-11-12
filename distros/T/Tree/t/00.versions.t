#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Tree; # For the version #.

use Test::More;

use base;
use constant;
use Data::Dumper;
use Exporter;
use lib;
use overload;
use Scalar::Util;
use strict;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	base
	constant
	Data::Dumper
	Exporter
	lib
	overload
	Scalar::Util
	strict
	warnings
/;

diag "Testing Tree V $Tree::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
