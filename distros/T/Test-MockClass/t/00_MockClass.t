#!/usr/bin/perl
#
#		Test script for Test::MockClass
#		$Id: 00_MockClass.t,v 1.3 2005/02/18 21:16:20 phaedrus Exp $
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
	eval { use Test::MockClass; };
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
						 $mainObject = Test::MockClass->new('FakeClass');
					 },
				 },

				 # the teardown function:
				 {
					 name => 'teardown',
					 func => sub {
#						 $mainObject->DESTROY;
						 $mainObject = undef;
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
						 assertInstanceOf( 'Test::MockClass', $mainObject );
						 assert($INC{'FakeClass.pm'});
						 assert($FakeClass::VERSION == -1);
						 my $maker = '';
						 assertNoException( sub {
												$maker = &FakeClass::___getMaker();
											});
						 assertInstanceOf( 'Test::MockClass', $maker );
					 },
				 },

				 {
					 name => 'noTracking method',
					 test => sub {
						 assertNoException( sub {
												$mainObject->noTracking;
											});
						 assert($mainObject->{'Test::MockClass::noConstructorCallTracking'});
						 assert($mainObject->{'Test::MockClass::noMethodCallTracking'});
						 assert($mainObject->{'Test::MockClass::noAttributeAccessTracking'});
					 },
				 },

				 {
					 name => 'tracking method',
					 test => sub {
						 assertNoException( sub {
												$mainObject->tracking;
											});
						 assertNot($mainObject->{'Test::MockClass::noConstructorCallTracking'});
						 assertNot($mainObject->{'Test::MockClass::noMethodCallTracking'});
						 assertNot($mainObject->{'Test::MockClass::noAttributeAccessTracking'});
					 },
				 },

				 {
					 name => 'constructor method',
					 test => sub {
						 assertNoException( sub {
												$mainObject->constructor('shazam');
											});
						 assert($mainObject->{'Test::MockClass::hasConstructor'} eq 'shazam');
						 my $mockObject = '';
						 assertNoException( sub {
												$mainObject->defaultConstructor;
												$mockObject = FakeClass->shazam();
											});
					 },
				 },

 				 {
 					 name => 'addMethod method',
 					 test => sub {
						 $mainObject->noTracking;
						 assertNoException( sub {
												$mainObject->addMethod( 'fooberries', sub {return 1;});
											});
						 assert(&UNIVERSAL::can('FakeClass', 'fooberries'));
 						 assertNoException( sub {
 												$result = &FakeClass::fooberries;
 											});
						 assert($result);
 					 },
 				 },

 				 {
 					 name => 'defaultConstructor method',
 					 test => sub {
						 $mainObject->noTracking;
						 my %args = (cat => 'rat', bat => 'hat');
						 assertNoException( sub {
												$mainObject->defaultConstructor(%args);
											});
						 assert(&UNIVERSAL::can('FakeClass', 'new'));
						 assert($mainObject->{'Test::MockClass::hasConstructor'} eq 'new');
						 assertNoException( sub {
												$result = &FakeClass::new('FakeClass', cat => 'hat');
											});
						 assertInstanceOf( 'FakeClass', $result );
						 assert($result->{bat} eq 'hat');
						 assert($result->{cat} eq 'hat');
 					 },
 				 },

 				 {
 					 name => 'setReturnValues method',
 					 test => sub {
						 $mainObject->noTracking;
						 assertNoException( sub {
												$mainObject->setReturnValues('truth', 'true');
											});
						 assert(&UNIVERSAL::can('FakeClass', 'truth'));
						 assertNoException( sub {
												$result = &FakeClass::truth();
											});
						 assert($result);

						 assertNoException( sub {
												$mainObject->setReturnValues('falseness', 'false');
											});
						 assert(&UNIVERSAL::can('FakeClass', 'falseness'));
						 assertNoException( sub {
												$result = &FakeClass::falseness();
											});
						 assertNot($result);

						 assertNoException( sub {
												$mainObject->setReturnValues('nothing', 'undef');
											});
						 assert(&UNIVERSAL::can('FakeClass', 'nothing'));
						 assertNoException( sub {
												$result = &FakeClass::nothing();
											});
						 assertNot(defined($result));

						 assertNoException( sub {
												$mainObject->setReturnValues('two', 'always', 2);
											});
						 assert(&UNIVERSAL::can('FakeClass', 'two'));
						 assertNoException( sub {
												$result = &FakeClass::two();
											});
						 assert($result == 2);

						 assertNoException( sub {
												$mainObject->setReturnValues('twoNtwo', 'always', 2, 2);
											});
						 assert(&UNIVERSAL::can('FakeClass', 'twoNtwo'));
						 assertNoException( sub {
												@results = &FakeClass::twoNtwo();
											});
						 assert($results[0] == 2);
						 assert($results[1] == 2);

						 assertNoException( sub {
												$mainObject->setReturnValues('twoNthree', 'always', 2, 3);
											});
						 assert(&UNIVERSAL::can('FakeClass', 'twoNthree'));
						 assertNoException( sub {
												$result = &FakeClass::twoNthree();
											});
						 assert($result->[0] == 2);
						 assert($result->[1] == 3);

						 assertNoException( sub {
												$mainObject->setReturnValues('fibonacci', 'series', 1, 1, 2, 3, 5);
											});
						 assert(&UNIVERSAL::can('FakeClass', 'fibonacci'));
						 assertNoException( sub {
												$result = &FakeClass::fibonacci();
											});
						 assert($result == 1);
						 assertNoException( sub {
												$result = &FakeClass::fibonacci();
											});
						 assert($result == 1);
						 assertNoException( sub {
												$result = &FakeClass::fibonacci();
											});
						 assert($result == 2);
						 assertNoException( sub {
												$result = &FakeClass::fibonacci();
											});
						 assert($result == 3);
						 assertNoException( sub {
												$result = &FakeClass::fibonacci();
											});
						 assert($result == 5);
						 assertNoException( sub {
												$mainObject->setReturnValues('flipflop', 'cycle', 1, 0);
											});
						 assert(&UNIVERSAL::can('FakeClass', 'flipflop'));
						 assertNoException( sub {
												$result = &FakeClass::flipflop();
											});
						 assert($result == 1);
						 assertNoException( sub {
												$result = &FakeClass::flipflop();
											});
						 assert($result == 0);
						 assertNoException( sub {
												$result = &FakeClass::flipflop();
											});
						 assert($result == 1);
						 assertNoException( sub {
												$result = &FakeClass::flipflop();
											});
						 assert($result == 0);
						 assertNoException( sub {
												$mainObject->setReturnValues('randomUser', 'random', (0..9));
											});
						 assertNoException( sub {
												$result = &FakeClass::randomUser();
											});
						 assert($result =~ m{\d});
						 assert($result >= 0);
						 assert($result < 10);
#						 print "result: $result\n";
 					 },
 				 },

 				 {
 					 name => 'create method',
 					 test => sub {
						 $mainObject->noTracking;
						 assertNoException(sub {
											   $mainObject->defaultConstructor('cat' => 'rat', 'bat'=> 'hat');
										   });
						 assertNoException(sub {
											   $result = $mainObject->create('cat' => 'hat');
										   });
						 assertInstanceOf('FakeClass', $result);
						 assert($result->{bat} eq 'hat');
						 assert($result->{cat} eq 'hat');
 					 },
 				 },


 				 {
 					 name => 'getNextObjectId method',
 					 test => sub {
						 assertNoException(sub {
											   $mainObject->defaultConstructor();
											   $results[0] = $mainObject->create();
											   $results[1] = $mainObject->create();
											   $results[2] = $mainObject->create();
										   });
						 my $objectId = '';
						 assertNoException(sub {
											   $objectId = $mainObject->getNextObjectId();
										   });
						 assert($objectId eq "$results[0]");
						 $objectId = '';
						 assertNoException(sub {
											   $objectId = $mainObject->getNextObjectId();
										   });
						 assert($objectId eq "$results[1]");
						 $objectId = '';
						 assertNoException(sub {
											   $objectId = $mainObject->getNextObjectId();
										   });
						 assert($objectId eq "$results[2]");
						 assertNoException(sub {
											   $objectId = $mainObject->getNextObjectId();
										   });
						 assert(not(defined($objectId)));
						 assertNoException(sub {
											   $objectId = $mainObject->getNextObjectId();
										   });
						 assert($objectId eq "$results[0]");
 					 },
 				 },

  				 {
  					 name => 'setCallOrder, getCallOrder, verifyCallOrder methods',
  					 test => sub {
 						 assertNoException( sub {
 												$mainObject->defaultConstructor();
 												$mainObject->setReturnValues('thingy', 'always', 'thingy');
 												$mainObject->setReturnValues('foosh', 'true');
 											});
 						 assertNoException( sub {
 												$mainObject->setCallOrder('new', 'thingy', 'foosh');
 											});
						 my @objects = ();
						 assertNoException( sub {
												$objects[0] = $mainObject->create();
												$objects[1] = $mainObject->create();
												$objects[2] = $mainObject->create();
												$objects[0]->thingy;
												$objects[1]->foosh;
												$objects[1]->thingy;
												$objects[2]->thingy;
												$objects[2]->foosh;
											});
						 assertNoException( sub {
												$results[0] = $mainObject->getCallOrder("$objects[0]");
												$results[1] = $mainObject->getCallOrder("$objects[1]");
												$results[2] = $mainObject->getCallOrder("$objects[2]");
											});
						 assert($results[0][0] eq 'new');
 						 assert($results[0][1] eq 'thingy');
						 assert($results[1][0] eq 'new');
 						 assert($results[1][1] eq 'foosh');
 						 assert($results[1][2] eq 'thingy');
						 assert($results[2][0] eq 'new');
 						 assert($results[2][1] eq 'thingy');
 						 assert($results[2][2] eq 'foosh');
						 assertNoException( sub {
												$result = $mainObject->verifyCallOrder("$objects[0]");
											});
						 assertNot($result);
						 my $breakpoint;
						 assertNoException( sub {
												$result = $mainObject->verifyCallOrder("$objects[1]");
											});
						 assertNot($result);
						 assertNoException( sub {
												$result = $mainObject->verifyCallOrder("$objects[2]");
											});
						 assert($result);
 					 },
 				 },

 				 {
 					 name => 'getArgumentList method',
 					 test => sub {
 						 assertNoException( sub {
 												$mainObject->defaultConstructor();
 												$mainObject->setReturnValues('thingy', 'always', 'thingy');
 												$mainObject->setReturnValues('foosh', 'true');
 											});
						 my @objects = ();
						 assertNoException( sub {
												$objects[0] = $mainObject->create();
												$objects[1] = $mainObject->create('foo');
												$objects[2] = $mainObject->create('foo', 'bar');
												$objects[0]->thingy();
												$objects[1]->foosh('cat');
												$objects[1]->thingy('bat');
												$objects[2]->thingy('cat', 'rat');
												$objects[2]->foosh('bat', 'hat');
											});
						 assertNoException( sub {
												$results[0] = $mainObject->getArgumentList("$objects[0]", 'new', 0);
												$results[1] = $mainObject->getArgumentList("$objects[1]", 'new', 0);
												$results[2] = $mainObject->getArgumentList("$objects[2]", 'new', 0);
											});
						 assertNot(scalar(@{$results[0]}));
						 assert(scalar(@{$results[1]}) == 1);
						 assert(scalar(@{$results[2]}) == 2);
						 assert($results[1][0] eq 'foo');
						 assert($results[2][0] eq 'foo');
						 assert($results[2][1] eq 'bar');
						 assertNoException( sub {
												$results[0] = $mainObject->getArgumentList("$objects[0]", 'thingy', 0);
												$results[1] = $mainObject->getArgumentList("$objects[1]", 'thingy', 0);
												$results[2] = $mainObject->getArgumentList("$objects[2]", 'thingy', 0);
											});
						 assert(scalar(@{$results[0]}) == 0);
						 assert(scalar(@{$results[1]}) == 1);
						 assert(scalar(@{$results[2]}) == 2);
 						 assert($results[1][0] eq 'bat');
 						 assert($results[2][0] eq 'cat');
 						 assert($results[2][1] eq 'rat');
 						 assertNoException( sub {
  												$objects[0]->thingy();
  												$objects[1]->foosh('fan');
  												$objects[1]->thingy('man');
  												$objects[2]->thingy('plan', 'ran');
  												$objects[2]->foosh('flan', 'stan');
  												$results[0] = $mainObject->getArgumentList("$objects[0]", 'thingy', 1);
  												$results[1] = $mainObject->getArgumentList("$objects[1]", 'thingy', 1);
  												$results[2] = $mainObject->getArgumentList("$objects[2]", 'thingy', 1);
  											});
  						 assert(scalar(@{$results[0]}) == 0);
  						 assert(scalar(@{$results[1]}) == 1);
  						 assert(scalar(@{$results[2]}) == 2);
  						 assert($results[1][0] eq 'man');
  						 assert($results[2][0] eq 'plan');
  						 assert($results[2][1] eq 'ran');
  					 },
 				 },

 				 {
 					 name => 'getAttributeAccess method',
 					 test => sub {
						 my @objects = ();
						 assertNoException( sub {
												$mainObject->defaultConstructor('cat' => 'rat');
												$objects[0] = $mainObject->create();
												$objects[1] = $mainObject->create();
											});
						 assertNoException( sub {
												$objects[0]->{cat} = 'hat';
												my $thingy = $objects[1]->{cat};
												$objects[1]->{cat} = 'fat';
												$objects[1]->{bat} = 'mat';
											});
						 assertNoException( sub {
												$results[0] = $mainObject->getAttributeAccess("$objects[0]");
												$results[1] = $mainObject->getAttributeAccess("$objects[1]");
											});
						 assert($results[0][0][0] eq 'store');
						 assert($results[0][0][1] eq 'cat');
						 assert($results[0][0][2] eq 'hat');
						 assert($results[1][0][0] eq 'fetch');
						 assert($results[1][0][1] eq 'cat');
						 assert($results[1][1][0] eq 'store');
						 assert($results[1][1][1] eq 'cat');
						 assert($results[1][1][2] eq 'fat');
						 assert($results[1][2][0] eq 'store');
						 assert($results[1][2][1] eq 'bat');
						 assert($results[1][2][2] eq 'mat');
 					 },
 				 },

				 );
runTests(@testSuite);
