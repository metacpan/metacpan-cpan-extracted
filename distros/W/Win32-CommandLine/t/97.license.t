#!perl -w  -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

# check for LICENSE file
# ? check for correspondance between LICENSE file and license property
# ? need Software::License module

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars ProhibitPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More;		# included with perl v5.6.2+

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless ($ENV{TEST_AUTHOR} or $ENV{AUTHOR_TESTING}) or ($ENV{TEST_RELEASE} or $ENV{RELEASE_TESTING}) or $ENV{TEST_ALL};

plan tests => 2;

my $filename = 'LICENSE';

ok (-f $filename, "Found the $filename file");
ok (-s $filename, "Found non-empty $filename file");
