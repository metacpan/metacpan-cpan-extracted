#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Text::Table::Manifold; # For the version #.

use Test::More;

use Const::Exporter;
use HTML::Entities::Interpolate;
use List::AllUtils;
use Module::Runtime;
use Moo;
use Scalar::Util;
use strict;
use String::TtyLength;
use Types::Standard;
use utf8;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Const::Exporter
	HTML::Entities::Interpolate
	List::AllUtils
	Module::Runtime
	Moo
	Scalar::Util
	strict
	String::TtyLength
	Types::Standard
	utf8
	warnings
/;

diag "Testing Text::Table::Manifold V $Text::Table::Manifold::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
