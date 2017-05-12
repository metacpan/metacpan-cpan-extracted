#!/usr/bin/perl

# Tests for Test::Inline's check_count functionality

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use File::Spec::Functions ':ALL';
use Test::More tests => 36;
use Test::Inline ();

# Prepare
my $example  = File::Spec->catfile( 't', 'data', 'example' );
my $testfile = 'foo_bar.t';

sub is_string {
	my ($left, $right, $message) = @_;
	$left  = [ split /\n/, $left  ];
	$right = [ split /\n/, $right ];
	is_deeply( $left, $right, $message );
}





#####################################################################
# Test param initialisation

my $basic = Test::Inline->new();
isa_ok( $basic, 'Test::Inline' );
is( $basic->{check_count}, 1, '->new() initialises correctly' );
$basic = Test::Inline->new( check_count => 0 );
isa_ok( $basic, 'Test::Inline' );
is( $basic->{check_count}, 0, '->new( check_count => 0 ) initialises correctly' );
$basic = Test::Inline->new( check_count => 1 );
isa_ok( $basic, 'Test::Inline' );
is( $basic->{check_count}, 1, '->new( check_count => 1 ) initialises correctly' );
$basic = Test::Inline->new( check_count => 2 );
isa_ok( $basic, 'Test::Inline' );
is( $basic->{check_count}, 2, '->new( check_count => 2 ) initialises correctly' );





#####################################################################
# Force Testing when all sections have test counts

# Do a basic run through a default Inline usage, but this time with
# full count checking enabled.
{
	my $PODCONTENT = <<'END_TEST';
# =begin testing SETUP 0
$::__tc = Test::Builder->new->current_test;
my $Foo = Foo::Bar->new();
is( Test::Builder->new->current_test - $::__tc, 0,
	'0 tests were run in the section' );



# =begin testing bar 2
$::__tc = Test::Builder->new->current_test;
{
This is also a test
}
is( Test::Builder->new->current_test - $::__tc, 2,
	'2 tests were run in the section' );



# =begin testing that after bar 4
$::__tc = Test::Builder->new->current_test;
{
Final test
}
is( Test::Builder->new->current_test - $::__tc, 4,
	'4 tests were run in the section' );



# =begin testing foo after bar that 3
$::__tc = Test::Builder->new->current_test;
{
This is another test
}
is( Test::Builder->new->current_test - $::__tc, 3,
	'3 tests were run in the section' );



# =begin testing 1
$::__tc = Test::Builder->new->current_test;
{
This is a test
}
is( Test::Builder->new->current_test - $::__tc, 1,
	'1 test was run in the section' );
END_TEST

	my $Inline = Test::Inline->new( check_count => 2 );
	isa_ok( $Inline, 'Test::Inline' );
	ok( $Inline->add( $example ), 'Adding example file' );
	is_deeply( [ $Inline->classes ], [ 'Foo::Bar' ], '->add added the correct class' );
	
	# Check the ::Script object created by the addition
	my $Class = $Inline->class('Foo::Bar');
	isa_ok( $Class, 'Test::Inline::Script' );
	is( $Class->filename, $testfile, '->filename returns correct file name' );
	is_string( $Class->merged_content, $PODCONTENT, '->merged_content matches expected value' );
	is( $Class->tests, 15, '->tests returns the correct number' );
}





$example  = File::Spec->catfile( 't', 'data', 'check_count' );





#####################################################################
# Force Testing when some sections have test counts

# Do a basic run through a default Inline usage, this time for a file
# that doesn't all have test counts
{
	my $PODCONTENT = <<'END_TEST';
# =begin testing SETUP 0
$::__tc = Test::Builder->new->current_test;
my $Foo = Foo::Bar->new();
is( Test::Builder->new->current_test - $::__tc, 0,
	'0 tests were run in the section' );



# =begin testing bar
{
This is also a test
}



# =begin testing that after bar
{
Final test
}



# =begin testing foo after bar that 3
$::__tc = Test::Builder->new->current_test;
{
This is another test
}
is( Test::Builder->new->current_test - $::__tc, 3,
	'3 tests were run in the section' );



# =begin testing 1
$::__tc = Test::Builder->new->current_test;
{
This is a test
}
is( Test::Builder->new->current_test - $::__tc, 1,
	'1 test was run in the section' );
END_TEST

	my $Inline = Test::Inline->new( check_count => 2 );
	isa_ok( $Inline, 'Test::Inline' );
	ok( $Inline->add( $example ), 'Adding example file' );
	is_deeply( [ $Inline->classes ], [ 'Foo::Bar' ], '->add added the correct class' );
	
	# Check the ::Script object created by the addition
	my $Class = $Inline->class('Foo::Bar');
	isa_ok( $Class, 'Test::Inline::Script' );
	is( $Class->filename, $testfile, '->filename returns correct file name' );
	is_string( $Class->merged_content, $PODCONTENT, '->merged_content matches expected value' );
	is( $Class->tests, undef, '->tests returns the correct number' );
}





#####################################################################
# Smart Testing when some sections have test counts

# And again, with the default test behaviour
{
	my $PODCONTENT = <<'END_TEST';
# =begin testing SETUP 0
$::__tc = Test::Builder->new->current_test;
my $Foo = Foo::Bar->new();
is( Test::Builder->new->current_test - $::__tc, 0,
	'0 tests were run in the section' );



# =begin testing bar
{
This is also a test
}



# =begin testing that after bar
{
Final test
}



# =begin testing foo after bar that 3
$::__tc = Test::Builder->new->current_test;
{
This is another test
}
is( Test::Builder->new->current_test - $::__tc, 3,
	'3 tests were run in the section' );



# =begin testing 1
$::__tc = Test::Builder->new->current_test;
{
This is a test
}
is( Test::Builder->new->current_test - $::__tc, 1,
	'1 test was run in the section' );
END_TEST

	my $Inline = Test::Inline->new( check_count => 1 );
	isa_ok( $Inline, 'Test::Inline' );
	ok( $Inline->add( $example ), 'Adding example file' );
	is_deeply( [ $Inline->classes ], [ 'Foo::Bar' ], '->add added the correct class' );
	
	# Check the ::Script object created by the addition
	my $Class = $Inline->class('Foo::Bar');
	isa_ok( $Class, 'Test::Inline::Script' );
	is( $Class->filename, $testfile, '->filename returns correct file name' );
	is_string( $Class->merged_content, $PODCONTENT, '->merged_content matches expected value' );
	is( $Class->tests, undef, '->tests returns the correct number' );
}





#####################################################################
# No Testing when some sections have test counts

# And again, but with test count checking disabled
{
	my $PODCONTENT = <<'END_TEST';
# =begin testing SETUP 0
my $Foo = Foo::Bar->new();



# =begin testing bar
{
This is also a test
}



# =begin testing that after bar
{
Final test
}



# =begin testing foo after bar that 3
{
This is another test
}



# =begin testing 1
{
This is a test
}
END_TEST

	my $Inline = Test::Inline->new( check_count => 0 );
	isa_ok( $Inline, 'Test::Inline' );
	ok( $Inline->add( $example ), 'Adding example file' );
	is_deeply( [ $Inline->classes ], [ 'Foo::Bar' ], '->add added the correct class' );
	
	# Check the ::Script object created by the addition
	my $Class = $Inline->class('Foo::Bar');
	isa_ok( $Class, 'Test::Inline::Script' );
	is( $Class->filename, $testfile, '->filename returns correct file name' );
	is_string( $Class->merged_content, $PODCONTENT, '->merged_content matches expected value' );
	is( $Class->tests, undef, '->tests returns the correct number' );
}

exit();
