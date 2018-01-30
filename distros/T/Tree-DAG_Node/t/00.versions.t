#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Tree::DAG_Node; # For the version #.

use Test::More;

use File::Slurp::Tiny;
use strict;
use utf8;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	File::Slurp::Tiny
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
