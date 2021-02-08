#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Text::CSV_PP::Iterator; # For the version #.

use Test::More;

use Exception::Class;
use Iterator;
use Iterator::IO;
use Test::More;
use Test::Pod;
use Text::CSV_PP;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Exception::Class
	Iterator
	Iterator::IO
	Test::More
	Test::Pod
	Text::CSV_PP
/;

diag "Testing Text::CSV_PP::Iterator V $Text::CSV_PP::Iterator::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
