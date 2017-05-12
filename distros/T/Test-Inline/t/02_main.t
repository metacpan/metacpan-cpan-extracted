#!/usr/bin/perl

# Tests for Test::Inline

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use File::Spec::Functions ':ALL';
use Test::More tests => 71;
use Test::Inline ();

# Prepare
my $example = File::Spec->catfile( 't', 'data', 'example' );
my $testfile = 'foo_bar.t';

my $PODCONTENT = <<'END_TEST';
# =begin testing SETUP 0
my $Foo = Foo::Bar->new();



# =begin testing bar 2
{
This is also a test
}



# =begin testing that after bar 4
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





#####################################################################
# Test::Inline::Extract

# Create a new object
my $Extract = Test::Inline::Extract->new( $example );
isa_ok( $Extract, 'Test::Inline::Extract' );

# Try to get the sections
my $elements = $Extract->elements;
isa_ok( $elements, 'ARRAY' );
ok( @$elements == 6, '->elements returns the correct number of file chunks' );
is( shift(@$elements), "package Foo::Bar;", 'First element is the package statement' );
foreach ( @$elements ) {
	ok( /^=begin test/, 'Sections appear to be correct' );
}





#####################################################################
# Test::Inline::Section

{
# Try to parse each of the sections
my $Setup = Test::Inline::Section->new( shift @$elements );
isa_ok( $Setup, 'Test::Inline::Section' );
ok(   $Setup->setup, '=begin testing SETUP: ->setup returns true' );
is(   $Setup->context, undef, '->context is false' );
ok( ! $Setup->name, '=begin testing SETUP: ->name returns false' );
ok( ! $Setup->anonymous, '=begin testing SETUP: ->anonymous returns false' );
is_deeply( [ $Setup->depends ], [], '=begin testing SETUP: ->depends returns null list' );
is_deeply( [ $Setup->after ], [ $Setup->depends ], '->after matches ->depends' );
is(   $Setup->content, "my \$Foo = Foo::Bar->new();\n", "=begin testing SETUP: ->content returns expected" );
ok( ! $Setup->tests, "=begin testing SETUP: ->tests returns false" );

my $Anonymous = Test::Inline::Section->new( shift @$elements );
isa_ok( $Anonymous, 'Test::Inline::Section' );
ok( ! $Anonymous->setup, '=begin testing: ->setup returns false' );
is(   $Anonymous->context, undef, '->context is false' );
ok( ! $Anonymous->name, '=begin testing: ->name returns false' );
ok(   $Anonymous->anonymous, '=begin testing: ->anonymous returns true' );
is_deeply( [ $Anonymous->depends ], [], '=begin testing: ->depends returns null list' );
is_deeply( [ $Anonymous->after ], [ $Anonymous->depends ], '->after matches ->depends' );
is(   $Anonymous->content, "This is a test\n", "=begin testing: ->content returns expected" );
is(   $Anonymous->tests, 1, "=begin testing: ->tests returns correct number" );

my $Named = Test::Inline::Section->new( shift(@$elements), 'Foo::Bar' );
isa_ok( $Named, 'Test::Inline::Section' );
ok( ! $Named->setup, '=begin testing bar: ->setup returns false' );
is(   $Named->context, 'Foo::Bar', 'Module provided as second argument to ->new becomes the ->context' );
ok(   $Named->name eq 'bar', '=begin testing bar: ->name returns true' );
ok( ! $Named->anonymous, '=begin testing bar: ->anonymous returns false' );
is_deeply( [ $Named->depends ], [], '=begin testing bar: ->depends returns null list' );
is_deeply( [ $Named->after ], [ $Named->depends ], '->after matches ->depends' );
is(   $Named->content, "This is also a test\n", "=begin testing bar: ->content returns expected" );
is(   $Named->tests, 2, "=begin testing bar: ->tests returns correct number" );

my $Depends = Test::Inline::Section->new( shift @$elements );
isa_ok( $Depends, 'Test::Inline::Section' );
ok( ! $Depends->setup, '=begin testing foo after bar that: ->setup returns false' );
is(   $Depends->context, undef, '->context is false' );
ok(   $Depends->name eq 'foo', '=begin testing foo after bar that: ->name returns true' );
ok( ! $Depends->anonymous, '=begin testing foo after bar that: ->anonymous returns false' );
ok(   scalar($Depends->depends) == 2, '=begin testing foo after bar that: ->depends returns null list' );
is(   $Depends->content, "This is another test\n", "=begin testing foo after bar that: ->content returns expected" );
is(   $Depends->tests, 3, "=begin testing foo after bar that: ->tests returns correct value" );
my @dep = sort $Depends->depends;
is(   $dep[0], 'bar', '->depends returns as expected' );
is(   $dep[1], 'that', '->depends returns as expected' );
is_deeply( [ $Depends->after ], [ $Depends->depends ], '->after matches ->depends' );

my $That = Test::Inline::Section->new( pop @$elements );
isa_ok( $That, 'Test::Inline::Section' );
ok( ! $That->setup, '=begin testing that after bar: ->setup returns false' );
is(   $That->context, undef, '->context is false' );
ok(   $That->name eq 'that', '=begin testing that after bar: ->name returns true' );
ok( ! $That->anonymous, '=begin testing that after bar: ->anonymous returns false' );
ok(   scalar($That->depends) == 1, '=begin testing that after bar: ->depends returns null list' );
is(   $That->content, "Final test\n", "=begin testing that after bar: ->content returns expected" );
is(   $That->tests, 4, "=begin testing that after bar: ->tests returns false" );
@dep = sort $That->depends;
is(   $dep[0], 'bar', '->depends returns as expected' );
is_deeply( [ $That->after ], [ $That->depends ], '->after matches ->depends' );
}




#####################################################################
# Test::Inline

# Do a basic run through a default Inline usage
{
	my $Inline = Test::Inline->new;
	isa_ok( $Inline, 'Test::Inline' );
	ok( $Inline->add( $example ), 'Adding example file' );
	is_deeply( [ $Inline->classes ], [ 'Foo::Bar' ], '->add added the correct class' );
	
	# Check the ::Script object created by the addition
	my $Class = $Inline->class('Foo::Bar');
	isa_ok( $Class, 'Test::Inline::Script' );
	is( $Class->filename, $testfile, '->filename returns correct file name' );
	is( $Class->merged_content, $PODCONTENT, '->merged_content matches expected value' );
	is( $Class->tests, 10, '->tests returns the correct number' );
	is( "$Class", $Class->filename, 'Stringification returns the same as for ->filename' );
	
	# Check some other basics
	is_deeply( $Inline->filenames, { 'Foo::Bar' => $testfile }, '->filenames returns correctly' );
}

# Check manifests create correctly
{
	my $Inline = Test::Inline->new( manifest => 'foo' );
	isa_ok( $Inline, 'Test::Inline' );
	ok( $Inline->add( $example ), 'Adding example file' );

	# Generate the manifest file
	is( $Inline->manifest, "$testfile\n", '->manifest generates correct content' );
}

# Regression test. Make sure that a class name in the =begin line can be retrieved
# correctly by ->classes
{
	my $pod = <<END_POD;
=begin testing this after that Foo::Bar 1

blah blah blah

=end testing
END_POD

	# Create the test section
	my $Section = Test::Inline::Section->new( $pod, 'Foo' );
	isa_ok( $Section, 'Test::Inline::Section' );

	# Does the ->classes function return the class dependency
	my @result = $Section->classes;
	is_deeply( \@result, [ 'Foo::Bar' ], '->classes returns correctly' );
}

exit();
