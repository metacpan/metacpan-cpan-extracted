#!/usr/bin/perl

# Regression testing for rt.cpan.org

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use File::Spec::Functions ':ALL';
use Test::More tests => 7;
use Test::Inline ();





# Change to the correct directory
chdir catdir( 't', 'data', '09_regression' ) or die "Failed to change to test directory";





#####################################################################
# Regression tests for rt.cpan.org bug #557
# (Test::Inline doesn't catch improper nesting)

{
	# Create basic Test::Inline object
	my $Inline = My::Inline->new();
	isa_ok( $Inline, 'Test::Inline' );

	my @errors = '';

	# Add the files
	my $rv = $Inline->add( 'My/BadPodNesting.pm' );
	is( $rv, undef, 'Adding bad file returns undef' );
	is_deeply( \@errors, [ 
		'Failed to parse sections: Test::Inline::Section: POD statement \'=begin testing bar\' illegally nested inside of section \'=begin testing foo\''
		],
		'Bad nesting error is triggered as expected' );

	package My::Inline;
	
	use base 'Test::Inline';

	sub _error {
		shift;
		@errors = @_;
		undef;
	}

	1;
}




#####################################################################
# Regression tests for anonymous bug
# "=begin testing SETUP after DDS::Info 1" is not a setup section

{
	my $POD = <<'END_POD';
=begin testing SETUP after DDS::Info 1

# This is ok
ok( 1, 'This is true' );

=end testing
END_POD

	# Create the Section
	my $Section = Test::Inline::Section->new( $POD );
	isa_ok( $Section, 'Test::Inline::Section' );

	ok( $Section->setup, 'Is a setup section' );
	ok( ! $Section->example, 'Is not an example section' );
	is( $Section->name, '', 'Does not have a name' );
}
