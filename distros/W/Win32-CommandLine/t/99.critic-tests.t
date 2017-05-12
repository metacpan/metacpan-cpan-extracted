#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};

my $haveTestPerlCritic = eval {	require Test::Perl::Critic;	1; };

plan skip_all => 'Test::Perl::Critic required to criticize code' if !$haveTestPerlCritic;

##-- config
my %config;
#$config{-top} = 10; 		# limit number of criricisms to top <N> criticisms
$config{-severity} = 3;		# [ 5 = gentle, 4 = stern, 3 = harsh, 2 = cruel, 1 = brutal ]
$config{-exclude} = [ qw( ProhibitExcessMainComplexity CodeLayout::ProhibitHardTabs RegularExpressions::RequireExtendedFormatting Subroutines::RequireArgUnpacking Miscellanea::RequireRcsKeywords ) ];
$config{-verbose} = '[%l:%c]: (%p; Severity: %s) %m. %e. ';
##

import Test::Perl::Critic ( %config );

my @files = glob('t/*.t');

plan tests => $#files+1;

for my $file (@files) { critic_ok( $file ); };

