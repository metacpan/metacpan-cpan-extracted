#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Tree::Simple::VisitorFactory; # For the version #.

use Test::More;

use base;
use File::Spec;
use Scalar::Util;
use Tree::Simple;
use Tree::Simple::Visitor;
use strict;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	base
	File::Spec
	Scalar::Util
	Tree::Simple
	Tree::Simple::Visitor
	strict
	warnings
/;

diag "Testing Tree::Simple::VisitorFactory V $Tree::Simple::VisitorFactory::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
