#!/usr/bin/perl
#
#		Test script for Test::MockClass::MyClass
#		$Id: 00_MyClass.t,v 1.1 2005/02/18 21:16:20 phaedrus Exp $
#
#		Before `make install' is performed this script should be runnable with
#		`make test'. After `make install' it should work as `perl test.pl'
#
#		Please do not commit any changes you make to the module without a
#		successful 'make test'!
#

# always use these:
use strict;
use warnings qw{all};

use Test::SimpleUnit qw{:functions};

Test::SimpleUnit::AutoskipFailedSetup(1);

# this is actually the very first test, the one to see if the package compile-checks:
{
	no warnings;			# for some reason I get:
	# Use of uninitialized value in eval "string"
	eval { use Test::MockClass::MyClass; };
}
my $evalError = $@;

# create all objects and variables that will be set up later:
my $mainObject = undef;
my $result = '';
my @results = ();

my @testSuite = (
				 # the setup function:
				 {
					 name => 'setup',
					 func => sub {
					 },
				 },

				 # the teardown function:
				 {
					 name => 'teardown',
					 func => sub {
					 },
				 },

				 {
					 name => 'File Loading',
					 test => sub {
						 assertNot( $evalError );
					 },
				 },

				 {
					 name => 'Object Creation',
					 test => sub {
						 # do assertions knowing that stuff has been set up
						 assertNoException( sub {
												$mainObject = Test::MockClass::MyClass->new;
											});
						 assertInstanceOf( 'Test::MockClass::MyClass', $mainObject );
						 assert($mainObject->can( 'foo' ) );
						 assert($mainObject->can( 'bar' ) );
						 assert($mainObject->can( 'bas' ) );
						 assertNot($mainObject->can( 'baz' ) );
					 },
				 },


				 );
runTests(@testSuite);
