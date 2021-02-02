#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Tree::Simple::View; # For the version #.

use Test::More;

use Class::Throwable;
use constant;
use parent;
use Scalar::Util;
use strict;
use Tree::Simple;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Class::Throwable
	constant
	parent
	Scalar::Util
	strict
	Tree::Simple
	warnings
/;

diag "Testing Tree::Simple::View V $Tree::Simple::View::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
