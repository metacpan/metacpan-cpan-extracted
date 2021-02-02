#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Tree::Persist; # For the version #.

use Test::More;

use base;
use Module::Runtime;
use Scalar::Util;
use strict;
use warnings;
use XML::Parser;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	base
	Module::Runtime
	Scalar::Util
	strict
	warnings
	XML::Parser
/;

diag "Testing Tree::Persist V $Tree::Persist::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
