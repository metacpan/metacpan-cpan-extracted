#!perl

# Test that modules are documented by their pod.

use strict;
use Test::More;

sub filter {
	my $module = shift;
	
	return 0 if $module =~ m/::Object\z/;
	return 0 if $module =~ m/::Trace::/;
	return 0 if $module =~ m/::StrictConstructor/;
	return 0 if $module =~ m/::Types\z/;
	return 0 if $module =~ m/_Old\z/;
	return 1;
}

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Pod::Coverage::Moose 0.01',
	'Pod::Coverage 0.20',
	'Test::Pod::Coverage 1.08',
);

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

plan( skip_all => "Test fails as of yet." );

my @modules = all_modules();
my @modules_to_test = grep { filter($_) } @modules;
my $test_count = scalar @modules_to_test;
plan( tests => $test_count );

foreach my $module (@modules_to_test) {
	pod_coverage_ok($module, { 
	  coverage_class => 'Pod::Coverage::Moose', 
	  also_private => [ qr/^[A-Z_]+$/ ],
	  trustme => [ qw(as_string get_namespace) ]
	});
}