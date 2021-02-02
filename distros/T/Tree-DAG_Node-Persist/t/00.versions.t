#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Tree::DAG_Node::Persist; # For the version #.

use Test::More;

use DBI;
use DBIx::Admin::CreateTable;
use File::Temp;
use Getopt::Long;
use Moo;
use Pod::Usage;
use Scalar::Util;
use strict;
use Tree::DAG_Node;
use Types::Standard;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	DBI
	DBIx::Admin::CreateTable
	File::Temp
	Getopt::Long
	Moo
	Pod::Usage
	Scalar::Util
	strict
	Tree::DAG_Node
	Types::Standard
	warnings
/;

diag "Testing Tree::DAG_Node::Persist V $Tree::DAG_Node::Persist::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
