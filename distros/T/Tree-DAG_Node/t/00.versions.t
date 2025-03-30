#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Tree::DAG_Node; # For the version #.

use Test::More;

use ExtUtils::MakeMaker;
use File::Slurper;
use strict;
use utf8;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	ExtUtils::MakeMaker
	File::Slurper
	strict
	utf8
	warnings
/;

diag "Testing Tree::DAG_Node V $Tree::DAG_Node::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
