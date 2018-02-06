#!perl -w  -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More;     # included with perl v5.6.2+

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{AUTOMATED_TESTING} or $ENV{TEST_AUTHOR} or $ENV{TEST_RELEASE} or $ENV{TEST_ALL};

use version qw();
my @modules = ( 'Test::CPAN::Meta 0.12', 'Test::CPAN::Meta::JSON' );	# @modules = ( '<MODULE> [<MIN_VERSION> [<MAX_VERSION>]]', ... )
my $haveRequired = 1;
foreach (@modules) {my ($module, $min_v, $max_v) = /\S+/gmsx; my $v = eval "require $module; $module->VERSION();"; if ( !$v || ($min_v && ($v < version->new($min_v))) || ($max_v && ($v > version->new($max_v))) ) { $haveRequired = 0; my $out = $module . ($min_v?' [v'.$min_v.($max_v?" - $max_v":'+').']':q//); diag("$out is not available"); }}	## no critic (ProhibitStringyEval)

plan skip_all => '[ '.join(', ',@modules).' ] required for testing' if not $haveRequired;

plan tests => 4;

Test::CPAN::Meta::JSON::meta_spec_ok();     # 2 tests
Test::CPAN::Meta::meta_spec_ok();           # 2 tests

#FROM Test-SubCalls-1.08
#!/usr/bin/perl
#
## Test that our META.yml file matches the current specification.
#
#use strict;
#BEGIN {
#	$|  = 1;
#	$^W = 1;
#}
#
#my $MODULE = 'Test::CPAN::Meta 0.12';
#
## Don't run tests for installs
#use Test::More;
#unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
#	plan( skip_all => "Author tests not required for installation" );
#}
#
## Load the testing module
#eval "use $MODULE";
#if ( $@ ) {
#	$ENV{RELEASE_TESTING}
#	? die( "Failed to load required release-testing module $MODULE" )
#	: plan( skip_all => "$MODULE not available for testing" );
#}
#
#meta_yaml_ok();
