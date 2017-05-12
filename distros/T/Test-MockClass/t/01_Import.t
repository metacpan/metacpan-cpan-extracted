#!/usr/bin/perl
#
#		Test script for Test::MockClass
#		$Id: 01_Import.t,v 1.1 2005/02/18 21:16:20 phaedrus Exp $
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
	eval { use Test::MockClass qw{Test::MockClass::MyClass -1.1.1}; };
}
use Test::MockClass::MyClass;

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
												$mainObject = Test::MockClass->new('Test::MockClass::MyClass');
											});
 						 assertInstanceOf( 'Test::MockClass', $mainObject );
 						 assert($INC{'Test/MockClass/MyClass.pm'});
 						 assert($Test::MockClass::MyClass::VERSION eq '-1.1.1');
 						 my $maker = '';
 						 assertNoException( sub {
 												$maker = &Test::MockClass::MyClass::___getMaker();
 											});
 						 assertInstanceOf( 'Test::MockClass', $maker );
 					 },
 				 },

				 {
				     name => 'Mock Object Creation',
				     test => sub {
						 assertNot(Test::MockClass::MyClass->can('new'));
						 assertNot(Test::MockClass::MyClass->can('foo'));
						 assertNot(Test::MockClass::MyClass->can('bar'));
						 assertNot(Test::MockClass::MyClass->can('bas'));
						 assertNot(Test::MockClass::MyClass->can('baz'));
						 my $mockObject = '';
 						 assertNoException( sub {
 												$mainObject->defaultConstructor('foo' => 3, 'bar' => 2, 'bas' => 1, 'baz' => 0);
 												$mainObject->addMethod('foo', sub {shift->{foo};});
 												$mainObject->addMethod('bar', sub {shift->{foo};});
 												$mainObject->addMethod('bas', sub {shift->{foo};});
 												$mainObject->addMethod('baz', sub {shift->{foo};});
 												$mockObject = Test::MockClass::MyClass->new();
 											});
						 assertInstanceOf('Test::MockClass::MyClass', $mockObject );
 						 assert(Test::MockClass::MyClass->can('new'));
 						 assert(Test::MockClass::MyClass->can('foo'));
 						 assert(Test::MockClass::MyClass->can('bar'));
 						 assert(Test::MockClass::MyClass->can('bas'));
 						 assert(Test::MockClass::MyClass->can('baz'));

					 },
				 },
				 # test inheritFrom method.

				 {
				     name => 'inheritFrom method',
				     test => sub {
						 my $mockObject = '';
						 assertNoException( sub {
												$mainObject->inheritFrom('Test::MockClass');
												$mockObject = Test::MockClass::MyClass->new();
											});
						 assertKindOf('Test::MockClass', $mockObject);
						 assert(Test::MockClass::MyClass->can('inheritFrom'));
					 },
				 },

				 );
runTests(@testSuite);
