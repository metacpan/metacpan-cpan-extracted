#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Tree::Cladogram; # For the version #.

use Test::More;

use File::Slurper;
use Getopt::Long;
use Imager;
use Imager::Fill;
use Moo;
use parent;
use Pod::Usage;
use strict;
use Tree::DAG_Node;
use Types::Standard;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	File::Slurper
	Getopt::Long
	Imager
	Imager::Fill
	Moo
	parent
	Pod::Usage
	strict
	Tree::DAG_Node
	Types::Standard
	warnings
/;

diag "Testing Tree::Cladogram V $Tree::Cladogram::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
