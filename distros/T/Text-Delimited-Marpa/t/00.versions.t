#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Text::Delimited::Marpa; # For the version #.

use Test::More;

use Const::Exporter;
use Marpa::R2;
use Moo;
use strict;
use Tree;
use Try::Tiny;
use Types::Standard;
use utf8;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Const::Exporter
	Marpa::R2
	Moo
	strict
	Tree
	Try::Tiny
	Types::Standard
	utf8
	warnings
/;

diag "Testing Text::Delimited::Marpa V $Text::Delimited::Marpa::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
