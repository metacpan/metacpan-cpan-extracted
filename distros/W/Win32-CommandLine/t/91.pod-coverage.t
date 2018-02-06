#!perl -w  -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};

#my $haveTestPodCoverage = eval { require 'Test::Pod::Coverage 1.04'; 1; };		## TODO: add version support
use version qw();
my @modules = ( 'Test::Pod::Coverage 1.04' );	# @modules = ( '<MODULE> [[<MIN_VERSION>] <MAX_VERSION>]', ... )
my $haveRequired = 1;
foreach (@modules) {my ($module, $min_v, $max_v) = split(' '); my $v = eval "require $module; $module->VERSION();"; if ( !$v || ($min_v && ($v < version->new($min_v))) || ($max_v && ($v > version->new($max_v))) ) { $haveRequired = 0; my $out = $module . ($min_v?' [v'.$min_v.($max_v?" - $max_v":'+').']':''); diag("$out is not available"); }}	## no critic (ProhibitStringyEval)

plan skip_all => '[ '.join(', ',@modules).' ] required for testing' if !$haveRequired;

(undef) = eval { require Test::Pod::Coverage; 1; };	## REPEATED (as obvious code) for kwalitee testing

Test::Pod::Coverage::all_pod_coverage_ok();
