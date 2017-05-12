#!/usr/bin/perl -w
##############################################################################

=head1 NAME

    Test::MockClass - A module to provide mock classes and mock objects for testing

=head1 SYNOPSIS

    # Pass in the class name and version that you want to mock
    use Test::MockClass qw{ClassToMock 1.1};

    # create a MockClass object to handle a specific class
    my $mockClass = Test::MockClass->new('ClassToMock');

    # specify to inherit from a real class, or a mocked class:
    $mockClass->inheritFrom('IO::Socket');

    # make a constructor for the class, can also use 'addMethod' for more control
    $mockClass->defaultConstructor(%classWideDefaults);

    # add a method:
    $mockClass->addMethod('methodname', $coderef);

    # add a simpler method, and specify return values that it will return automatically
    $mockClass->setReturnValues('methodname2', 'always', 3);

    # create an instance of the mocked class:
    my $mockObject = $mockClass->create(%instanceData);

    # set the desired call order for the methods:
    $mockClass->setCallOrder('methodname2', 'methodname', 'methodname');

    # run tests using the mock Class elsewhere:
    #:in the class to test:
    sub objectFactory {
        return ClassToMock->new;
    }
    #:in your test code:
	assert($testObj->objectFactory->isa("ClassToMock"));

    # get the object Id for the rest of the methods:
    my $objectId = "$mockObject";
    #or
    $objectId = $mockClass->getNextObjectId();

    # verify that the methods were called in the correct order:
    if($mockClass->verifyCallOrder($objectId)) {
        # do something
    }

    # get the order that the methods were called:
    my @calls = $mockClass->getCallOrder($objectId);

    # get the list of arguments passed per call:
    my @argList = $mockClass->getArgumentList($objectId, 'methodname', $callPosition);

    # get the list of accesses made to a particular attribute (hashkey in $mockObject)
    my @accesses = $mockClass->getAttributeAccess($objectId, 'attribute');

=head1 EXPORTS

Nothing by default.

=head1 REQUIRES

The Hook::WrapSub manpage, the Tie::Watch manpage, the Scalar::Util manpage.

=head1 DESCRIPTION

This module provides a simple interface for creating mock classes and mock objects with mock methods for mock purposes, I mean testing purposes.  It also provides a simple mechanism for tracking the interactions to the mocked objects.  I originally wrote this class to help me test object factory methods, since then, I've added some more features.  This module is hopefully going to be the Date::Manip of mock class/object creation, so email me with lots of ideas, everything but the kitchen sink will go in!

=head1 METHODS

=head2 import

This method is called when you use the class.  It optionally takes a list of classes to mock:

  use Test::MockClass qw{IO::Socket File::Finder DBI};

You can also specify the version numbers for the classes:

  use Test::MockClass qw{DBD::mysql 1.1 Apache::Cookie 1.2.1}

This use fools perl into thinking that the class/module is already loaded, so it will override any use statement within the code that you're trying to test.

=head2 new

The Test::MockClass constructor.  It has one required argument which is the name of the class to mock.  It also optionally takes a version number as a second argument (this version will override any passed to the use statement).  It returns a Test::MockClass object, which is the interface for all of the method making and tracking for mock objects created later.

    my $mockClass = Test::MockClass->new('ClassToMock', '1.1');

If no version is specified in either the use statement or the call to new, it defaults to -1.

=head2 addMethod

A mocked class needs methods, and this is the most flexible way to create them.  It has two required arguments, the first one is the name of the method to mock.   The second argument is a coderef to use as the contents of the mocked method.  It returns nothing of value.  What it does that is valuable is install the method into the symbol table of the mocked class.

    $mockClass->addMethod('new', sub { my $proto = shift; my $class = ref($proto) || $proto; my $self = {}; bless($self, $class); });

    $mockClass->addMethod('foo', sub {return 'foo';});

=head2 defaultConstructor

I'm often too lazy, or, er, busy to write my own mocked constructor, especially when the constructor is a simple standard one.  For those times I use the defaultConstructor method.  This method takes a hashy list as the optional arguments, which it passes to the constructor as class-wide default attributes/values.  It installs the constructor in the mocked class as 'new' or whatever was set with $mockClass->constructor() (see that method description later in this document).

    $mockClass->defaultConstructor('cat' => 'hat', 'grinch' => 'x-mas');

Of course, this assumes that your objects are based on hashes.

=head2 setReturnValues

My laziness often extends beyond the simple constructor to the methods of the mocked class themselves.  Often I don't feel like writing a whole method when all I need for testing is to have the mocked method return a specific value.  For times like this I'm glad I wrote the setReturnValues method.  This method takes a variable number of arguments, but the first two are required.  The first argument is the name of the method to mock.  The second argument specifies what the mocked method will return.  Any additional arguments may be used as return values depending on the type of the second argument.  The possible values for the second argument are as follows:

=over 4

=item true

This specifies that the method should always return true (1).

  $mockClass->setReturnValues('trueMethod', 'true');
  if($mockObject->trueMethod) {}

=item false

This specifies that the method should always return false (0).

  $mockClass->setReturnValues('falseMethod', 'false');
  unless($mockObject->falseMethod) {}

=item undef

This specifies that the method should always return undef.

  $mockClass->setReturnValues('undefMethod', 'undef');
  if(defined $mockObject->undefMethod) {}

=item always

This specifies that the method should always return all of the rest of the arguments to setReturnValues.

  $mockClass->setReturnValues('alwaysFoo', 'always', 'foo');
  $mockClass->setReturnValues('alwaysFooNBar', 'always', 'foo', 'bar');

=item series

This specifies that the method should return 1 each of the rest of the arguments per method invocation until the arguments have all been used, then it returns undef.

  $mockClass->setReturnValues('aFewGoodMen', 'series', 'Abraham', 'Martin', 'John');

=item cycle

This specifies that the method should return 1 each of the rest of the arguments per method invocation, once all have been used it starts over at the beginning.

  $mockClass->setReturnValues('boybands', 'cycle', 'BackAlley-Bros', 'OutOfSync', 'OldKidsOverThere');

=item random

This specifies that the method should return a random value from the list.  Well, as random as perl's srand/rand can get it anyway.

  $mockClass->setReturnValues('userInput', 'random', (0..9));

=back

=head2 setCallOrder

Sometimes it's important to impose some guidelines for behavior on your mocked objects.  This method allows you to set the desired call order for your mocked methods, the order that you want them to be called.  It takes a variable length list which is the names of the methods in the proper order.  This list is then used in comparison with the actual call order made on individual mocked objects.

    $mockClass->setCallOrder('new', 'foo', 'bas', 'bar', 'foo');

=head2 getCallOrder

Objects often do bizzare and unnatural things when you aren't looking, so I wrote this method to track what they did behind the scenes.  This method returns the actual method call order for a given object.  It takes one required argument which is the object Id for the object you want the call order of.  One way to get an object's Id is to simply pass it in stringified:

    my @callOrder = $mockClass->getCallOrder("$mockObject");

This method returns an array in list context and an arrayref under scalar context.  It returns nothing under void context.

=head2 verifyCallOrder

Now we could compare, by hand, the differences between the call order we wanted and the call order we got, but that would be all boring and we've got better things to do.  I say we just use the verifyCallOrder method and be done with it.  This method takes one required argument which is the object Id of the object we want to verify.  It returns true or false depending on whether the methods were called in the correct order or not, respectively.

    if($mockClass->verifyCallOrder("$mockObject")) {
       # do something
    }

=head2 create

Sometimes you might want to use the Test::MockClass object to actually return mocked objects itself, I'm not sure why, but maybe someone would want it, so for them there is the create method.  This method takes a variable sized hashy list which will be used as instance attributes/values.  These attributes will ovverride any class-wide defaults set by the defaultConstructor method.  The method returns a mock object of the appropriate mocked class.  The only caveat with this method is that in order for the attribute/values defaulting-ovveride stuff to work you have to use the defaultConstructor to set up your constructor.

    $mockClass->defaultConstructor('spider-man' => 'ben reilly');
    my $mockObject = $mockClass->create('batman' => 'bruce wayne', 'spider-man' => 'peter parker');

=head2 getArgumentList

I've found that I often want to know exactly how a method was called on a mock object, when I do I use getArgumentList.  This method takes three arguments, two are required and the third is often needed.  The first argument is the object Id for the object you want the tracking for, the second argument is the name of the method that you want the arguments from, and the third argument corresponds to the order of call for this method (not to be confused with the call order for all the methods).  The method returns an array which is a list of the arguments that were passed into the method.  In scalar context it returns a reference to an array.  The following example gets the arguments from the second time 'fooMethod' was called.

    my @arguments = $mockClass->getArgumentList("$mockObject", 'fooMethod', 1);

If the third argument is not supplied, it returns an array of all of the argument lists.

=head2 getNextObjectId

Sometimes your mock objects are destroyed before you can get their object id.  Well in those cases you can get the cached object Id from the Test::MockClass object.  This method requires no arguments and returns object Ids suitable for use in any of the other Test::MockClass methods.  The method begins with the object id for the first object created, and returns subsequent ones until it runs out, in which case it returns undef, and then starts over.

    my $firstObjectId = $mockClass->getNextObjectId();

=head2 getAttributeAccess

Sometimes you need to track how the object's attributes are accessed.  Maybe someone's breaking your encapsulation, shame on them, or maybe the access is okay.  For whatever reason if you want a list of accesses for an object's underlying data structure just use getAttributeAccess method.  This method takes a single required argument which is the object id of the object you want the tracking for.  It returns a multi dimensional array, the first dimension corresponds to the order of accesses.  The second dimension contains the actual tracking information.  The first position [0] in this array describes the type of access, either 'store' or 'fetch'.  The second position [1] in this array corresponds to the attribute that was accessed, the key of the hash, the index of the array, or nothing for a scalar.  The third position in this array is only used when the access was of type 'store', and it contains the new value.  In scalar context it returns an array ref.

    my @accesses = $mockClass->getAttributeAccess("$mockObject");
    print "breaky\n" if(grep {$_[0] eq 'store'} @accesses);

A second argument can be supplied which corresponds to the order that the access took place.

=head2 noTracking

Maybe my mock objects are too slow for you, what with all the tracking of interactions and such.  Maybe all you need is a mock object and you don't care how it was interated with.  Maybe you have to make millions of mock objects and you just don't have the memory to support tracking.  Well fret not my friend, for the noTracking method is here to help you.  Just call this method (no arguments required) and all the tracking will be disabled for any subsequent mock objects created.  I personally like tracking, so I switch it on by default.

    $mockClass->noTracking(); # no more tracking of methodcalls, constructor-calls, attribute-accesses

=head2 tracking

So you want to track some calls but not others?  Fine, use the tracking method to turn tracking back on for any subsequently created mock objects.

    $mockClass->tracking(); # now tracking is back on.

=head2 constructor

You want to use defaultConstructor or create, but you don't want to use 'new' as the name of your constructor?  That's fine, just pass in the name of the constructor you want to use/create to the constructor method.  Ugh, that's kinda confusing, an example will be simpler.

    $mockClass->constructor('create'); # change from 'new'.
    $mockClass->defaultConstructor(); # installs 'create'.
    my $mockObject = MockClass->create(); # calls 'create' on mocked class.

=head2 inheritFrom

This method allows your mock class to inherit from other mock classes or real classes.  Since it basically just uses perl's inheritence, it's pretty transparent.  And yes, it does support multiple inheritence, though you don't have to use it if you don't wanna.

=head1 TODO

Figure out how to add simple export/import mechanisms for mocked classes.  Make Test::MockClass less hash-centric. Stop breaking Tie::Watch's encapsulation. Provide mock objects with an interface to their own tracking. Make tracking and noTracking more fine-grained. Maybe find a safe way to clean up namespaces after the maker object goes out of scope. Write tests for arrayref and scalarref based objects. Write tests for unusual objects (regular expression, typeglob, filehandle, etc.)

=head1 SEE ALSO

=item Alternatives: L<Test::MockObject>, L<Test::MockMethod>

=item Testing systems: L<Test::Simple>, L<Test::More>, L<Test::Builder>, L<Test::Harness>

=item xUnit testing: L<Test::SimpleUnit>, L<Test::Unit>, L<Test::Class>

=head1 AUTHOR

Jeremiah Jordan E<lt>jjordan@perlreason.comE<gt>

Inspired by Test::MockObject by chromatic, and by Test::Unit::Mockup (ruby) by Michael Granger.
Both of whom were probably inspired by other people (J-unit, Xunit types maybe?) which all goes back to that sUnit guy.  Thanks to Stevan Little for the constructive criticism.

Copyright (c) 2002, 2003, 2004, 2005 perl Reason, LLC. All Rights Reserved.

This module is free software. It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html) or under the GPL.

=cut

##############################################################################
package Test::MockClass;

use strict;
use warnings qw{all};

###############################################################################
###	 I N I T I A L I Z A T I O N 
###############################################################################
BEGIN {

	### Versioning stuff and custom includes
	use vars qw{$VERSION $RCSID};
  
	$VERSION	= do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
	$RCSID		= q$Id: MockClass.pm,v 1.5 2005/02/18 21:16:20 phaedrus Exp $;
	use Carp;
	use Hook::WrapSub qw{wrap_subs unwrap_subs};
	use Tie::Watch;
	use Scalar::Util qw{blessed reftype weaken};
	### Inheritance
	use base qw{ };
}


###############################################################################
###	 C O N F I G U R A T I O N	 ( G L O B A L S )
###############################################################################
use vars qw{};
our %classesToMock = ();

# the sole purpose of this import is to make perl believe that the classes passed in are already loaded.
sub import {
	my $class = shift;
	return unless(scalar(@_));

	# two ways to call,
	# hash way with ClassName => version number
	# or ClassName, ClassName, ClassName

	if(scalar(@_) % 2) { # odd
		foreach my $ctom (@_) {
			$classesToMock{$ctom} = -1; #set the version.
		}
	} else { # even
		# even could still be classes
		if($_[1] =~ m{^[0-9\.-]+$}) { # second arg looks like a version number
			%classesToMock = @_;
		} else {
			foreach my $ctom (@_) {
				$classesToMock{$ctom} = -1; #set the version.
			}
		}
	}
	no strict 'refs';

	foreach my $classToMock (keys %classesToMock) {
		my $filename = $classToMock;
		$filename =~ s{::}{/}g;

		# fool %INC into thinking it loaded it already:
		$INC{"$filename.pm"} = 1;

		# make a fake version:
		my $version = $classesToMock{$classToMock};
		# I'm not sure if this does anything:
#		${$filename . '::' }{VERSION} = $version;
		${$classToMock . '::' . 'VERSION'} = $version;
		# it's probably silly to explicitly add universal, but...
		push(@{$classToMock . '::' . 'ISA'}, 'UNIVERSAL');
	}
}


###############################################################################
###	 P U B L I C   M E T H O D S 
###############################################################################

### METHOD (OBJECT CONSTRUCTOR): new('classname')
### Creates a new reference blessed into the Test::MockClass class
###	(a Test::MockClass object).
sub new {
	my $proto = shift;
	my $classToMock = shift;
	my $version = shift;
	my $class = ref $proto || $proto;

	my $self = {
				# Public attributes:
				'Test::MockClass::hasConstructor'				=> '',
				'Test::MockClass::tolerant'					=> 1,
				'Test::MockClass::quiet'                      => 0,
				'Test::MockClass::noConstructorCallTracking'	=> 0,
				'Test::MockClass::noMethodCallTracking'		=> 0,
				'Test::MockClass::noAttributeAccessTracking'	=> 0,
				# Private attributes:
				'Test::MockClass::__mockClass'								=> $classToMock,
				'Test::MockClass::__desiredCallOrder'							=> [],
				'Test::MockClass::__CallOrderByObjectId'						=> {},
				'Test::MockClass::__argumentsByObjectIdMethodnameOrder'		=> {},
				'Test::MockClass::__attributeAccessByObjectId'				=> {},
				'Test::MockClass::__wrapperByMethodname'						=> {},
				'Test::MockClass::__returnAlgorythmByMethodname'				=> {},
				'Test::MockClass::__returnValuesByMethodname'					=> {},
				'Test::MockClass::__objectIds'								=> [],
				'Test::MockClass::__currentObjectIdIndex'						=> 0,
			   };
	bless($self, $class);

	# don't do all this stuff if we already loaded this class:
	unless(exists($classesToMock{$classToMock})) {
		my $filename = $classToMock;
		$filename =~ s{::}{/}g;

		# fool %INC into thinking it loaded it already:
		$INC{"$filename.pm"} = 1;

		# make a fake version:
		$version ||= -1;
		$classesToMock{$classToMock} = $version;
		{
			no strict 'refs';
			no warnings 'redefine';
			# I'm not sure if this does anything:
			${$filename . '::' }{VERSION} = $version;
			${$classToMock . '::' . 'VERSION'} = $version;
			# it's probably silly to explicitly add universal, but...
			push(@{$classToMock . '::' . 'ISA'}, 'UNIVERSAL');
		}
	}

	{
		no strict 'refs';
		no warnings 'redefine';
		# we have to create a special method that will return the self to any mocked objects (so that the wrappers can have access to it:
		my $weakSelf = $self;
		weaken($weakSelf);
		my $returnMaker = sub { return $weakSelf; };

		*{$classToMock . '::' . '___getMaker'} = $returnMaker;
#		*{'Test::MockClass::___getMaker' . $classToMock} = $returnMaker;
	}
	return $self;
}

sub inheritFrom {
	my $self = shift;
	my $className = shift;
	my $classToMock = $self->{'Test::MockClass::__mockClass'};
	no strict 'refs';
	push(@{"${classToMock}::ISA"}, $className, @_);
}

### METHOD: defaultConstructor(%classWideDefaults)
### Creates a standard two argument constructor
###	and installs it into the mocked class
sub defaultConstructor {
	my $self = shift;
	my $classToMock = $self->{'Test::MockClass::__mockClass'};

	$self->{'Test::MockClass::hasConstructor'} = 'new' unless($self->{'Test::MockClass::hasConstructor'});
	my $constructorName = $self->{'Test::MockClass::hasConstructor'};
	# get the class wide defaults:
	my %classWideDefaults = @_;

	# create an average constructor code ref:
	my $constructor = sub {
		my $proto = shift;
		my %args = (%classWideDefaults, @_);
		my $class = ref($proto) || $proto;
		my $self = {};
		foreach my $key (keys %args) { $self->{$key} = $args{$key}; }
		return bless($self, $class);
	};

	$self->addMethod( $constructorName, $constructor );
}

### METHOD: addMethod(methodname, codeRef)
### Installs the supplied code reference into the symbol table under
###	the supplied method name.
sub addMethod {
	my $self = shift;
	my $methodname = shift;
	my $code = shift;
	my $constructorName = '';
	my $classToMock = $self->{'Test::MockClass::__mockClass'};
	# perl mojo:
	{
		no strict 'refs';
		no warnings 'redefine';
		# what if we already have a method of that type?
		my $method = $classToMock . '::' . $methodname;
		if(&UNIVERSAL::can($classToMock, $methodname)) {
			# remove the old wrapper (if it exists).
			unwrap_subs($method);
		}

		# install the method into the symbol table:
		*{$method} = $code;
		# only install wrappers if we aren't under 'noTracking' mode?
		
		# catch their custom 'new' constructor and add stuff around it:
		$constructorName = $self->{'Test::MockClass::hasConstructor'};
		if($methodname eq $constructorName) {
			unless($self->{'Test::MockClass::noConstructorCallTracking'}) {
				# it's wrapping everything:
				wrap_subs($method, \&__postConstructor);
			}
		} else {
			unless($self->{'Test::MockClass::noMethodCallTracking'}) {
				wrap_subs(\&__preMethod, $method);
				# __preMethod tracks what arguments are passed to the method.
			}
		}
	}
}

### METHOD: setReturnValues(methodname, type, values...)
### Creates a dummy method which will always return the specified values
sub setReturnValues {
	my $self = shift;
	my $methodname = shift;
	my $type = shift;
	my @values = @_;

	my %defaultMethods = (
						  true =>  sub { return 1; },
						  false => sub { return 0;},
						  undef => sub { return undef },
						  always => sub { (scalar(@values) == 1) ? return $values[0] : return wantarray ? @values : \@values; },
						  series => sub { return shift(@values); },
						  cycle => sub { my $val = shift(@values); push(@values, $val); return $val; },
						  random => sub { srand; return($values[int(rand(scalar(@values)))]); },
						 );
	my $code = $defaultMethods{$type};
	$self->tattle("Invalid algorythm type!\n") unless(ref($code) eq 'CODE');
	$self->addMethod($methodname, $code);
}

### METHOD: setCallOrder(callOrder...)
### Specifies the desired order for the methods to be called in.
sub setCallOrder {
	my $self = shift;
	# clean up user values.
	my @callOrder = @_;
	$self->{'Test::MockClass::__desiredCallOrder'} = \@callOrder;
}

### METHOD: create(%instanceArgs)
### Creates a mock object of the class so mocked using 'new' or the supplied constructor
###	given by $self->{hasConstructor}, returns undef otherwise.
sub create {
	my $self = shift;
	my $classToMock = $self->{'Test::MockClass::__mockClass'};
	unless($self->{'Test::MockClass::hasConstructor'}) {
		$self->tattle("There's no constructor specified!  See Test::MockClass documentation.\n");
		return undef;
	}
	my $constructor = $self->{'Test::MockClass::hasConstructor'};
	{
		no strict 'refs';
		no warnings 'redefine';
		return &{$classToMock . '::' . $constructor}( $classToMock, @_ );
	}
}

### METHOD: verifyCallOrder(objectId)
### Returns 1 (true) if the desired call order matches this specific object's actual call order,
###	Returns 0 (false) otherwise.
sub verifyCallOrder {
	my $self = shift;
	my $objectId = 0;
	$objectId ||= shift;
	my $desiredCallOrderString = join('', @{$self->{'Test::MockClass::__desiredCallOrder'}});
	my $actualCallOrderString =  join('', @{$self->{'Test::MockClass::__CallOrderByObjectId'}{$objectId}});
	return $desiredCallOrderString eq $actualCallOrderString;
}

### METHOD: getCallOrder(objectId)
### Returns the actual call order of the methods in an array (list) form.
sub getCallOrder {
	my $self = shift;
	my $objectId = 0;
	$objectId ||= shift;
	return wantarray ? @{$self->{'Test::MockClass::__CallOrderByObjectId'}{$objectId}} : $self->{'Test::MockClass::__CallOrderByObjectId'}{$objectId};
}

### METHOD: getArgumentList(objectId, methodname, order)
### Returns the actual call order of the methods in an array (list) form.
sub getArgumentList {
	my $self = shift;
	my ($objectId, $methodname, $order) = @_;
	if(defined($order)) { # we return 1 argument list for that method
		$order = 0 unless($order);
		return wantarray ? @{$self->{'Test::MockClass::__argumentsByObjectIdMethodnameOrder'}{$objectId}{$methodname}[$order]} : $self->{'Test::MockClass::__argumentsByObjectIdMethodnameOrder'}{$objectId}{$methodname}[$order];
	} else { # we return all argument lists for that method
		return wantarray ? @{$self->{'Test::MockClass::__argumentsByObjectIdMethodnameOrder'}{$objectId}{$methodname}} : $self->{'Test::MockClass::__argumentsByObjectIdMethodnameOrder'}{$objectId}{$methodname};
	}
}

sub getAttributeAccess {
	my $self = shift;
	# change this to act like getArgumentList
	my $objectId = shift;
	my $order = shift;
	if(defined($order)) {
		return wantarray ? @{$self->{'Test::MockClass::__attributeAccessByObjectId'}{$objectId}[$order]} : $self->{'Test::MockClass::__attributeAccessByObjectId'}{$objectId}[$order];
	} else {
		return wantarray ? @{$self->{'Test::MockClass::__attributeAccessByObjectId'}{$objectId}} : $self->{'Test::MockClass::__attributeAccessByObjectId'}{$objectId};
	}
}

sub getNextObjectId {
	my $self = shift;
	my $tot = scalar(@{$self->{'Test::MockClass::__objectIds'}});
	my $num = $self->{'Test::MockClass::__currentObjectIdIndex'};
	if(not(defined($num))) {
		$self->{'Test::MockClass::__currentObjectIdIndex'} = 0;
		return undef;
	}
	my $objectId = $self->{'Test::MockClass::__objectIds'}[$num];
	$num++;
	$num = undef if($num == $tot);
	$self->{'Test::MockClass::__currentObjectIdIndex'} = $num;
	return $objectId;
}

sub tattle {
	my $self = shift;
	my $error = join('', @_);
	if($self->{'Test::MockClass::tolerant'}) {
		carp $error unless($self->{'Test::MockClass::quiet'});
	} else {
		croak $error;
	}
}

sub noTracking {
	my $self = shift;
	# turn off all tracking for speed and memory reduction:
	$self->{'Test::MockClass::noConstructorCallTracking'} = 1;
	$self->{'Test::MockClass::noMethodCallTracking'}      = 1;
	$self->{'Test::MockClass::noAttributeAccessTracking'} = 1;
}

sub tracking {
	my $self = shift;
	# turn off all tracking for speed and memory reduction:
	$self->{'Test::MockClass::noConstructorCallTracking'} = 0;
	$self->{'Test::MockClass::noMethodCallTracking'}      = 0;
	$self->{'Test::MockClass::noAttributeAccessTracking'} = 0;
}

sub constructor {
	my $self = shift;
	my $constructorName = shift;
	$self->{'Test::MockClass::hasConstructor'} = $constructorName;
}

###############################################################################
###	 P R I V A T E	 M E T H O D S 
###############################################################################


# this method is called after the constructor of the mock object.
sub __postConstructor {
	# I have to check the value of wantarray before I do anything else, otherwise I will segfault.
#	my $truth = wantarray;
	# should I still track the call?
#	return undef unless(defined($truth)); # the constructor was called in a void context!
	my $object = $Hook::WrapSub::result[0];

	my $classToMock = ref($object);
	# this will be thread-safe (hopefully) because it's a readonly method, 
	# and the contents will never change for any mock object created by the $maker object referred to.
	my $self = '';
	{
		no strict 'refs';
		no warnings 'redefine';
#		if(&UNIVERSAL::can($classToMock, '___getMaker')
		$self = $classToMock->___getMaker();
#		my $method = $classToMock . '::' . '___getMaker';
#		$self = &{$method};
	}
	# if the two aren't the same, we are in a subclass.
	return $object unless($classToMock eq $self->{'Test::MockClass::__mockClass'});
	# this new object will be used if we can support access tracking of attributes.
	my $newObject = '';
	# tracking only works for those datatypes supported by Tie::Watch,
	# ie Hash, Array, & Scalar.
	unless($self->{'Test::MockClass::noAttributeAccessTracking'}) {
		if(reftype($object) eq 'HASH') { # copy the hash and tie it.
			my %hashToTie = %$object;
			my $watch = Tie::Watch->new(
										-variable => \%hashToTie,
										-fetch    => \&__watchFetch,
										-store    => \&__watchStore,
									   );
			$newObject = bless(\%hashToTie, $classToMock);
			###::DANGER:: This breaks encapsulation:
			$watch->{'Test::MockClass::___mockArgs'} = [$self, $newObject];
			# still it was the only way I could get the right arguments passed.
			$Hook::WrapSub::result[0] = $newObject;
		} elsif(reftype($object eq 'ARRAY')) { # copy the array and tie it.
			my @arrayToTie = @$object;
			my $watch = Tie::Watch->new(
										-variable => \@arrayToTie,
										-fetch    => \&__watchFetch,
										-store    => \&__watchStore,
									   );
			$newObject = bless(\@arrayToTie, $classToMock);
			###::DANGER:: This breaks encapsulation:
			$watch->{'Test::MockClass::___mockArgs'} = [$self, $newObject];
			$Hook::WrapSub::result[0] = $newObject;
		} elsif(reftype($object eq 'SCALAR')) { # copy the scalar and tie it.
			my $scalarToTie = $$object;
			my $watch = Tie::Watch->new(
										-variable => \$scalarToTie,
										-fetch    => \&__watchFetch,
										-store    => \&__watchStore,
									   );
			$newObject = bless(\$scalarToTie, $classToMock);
			###::DANGER:: This breaks encapsulation:
			$watch->{'Test::MockClass::___mockArgs'} = [$self, $newObject];
			$Hook::WrapSub::result[0] = $newObject;
		}
	}
	my $objectId = '';
	if(ref($newObject)) {
		$objectId = "$newObject";
	} else {
		$objectId = "$object";
	}
	push(@{$self->{'Test::MockClass::__objectIds'}}, $objectId);

	### ::TODO:: I should put in more Carping, or safety checks:
	my $constructorName = $self->{'Test::MockClass::hasConstructor'};
	# add the call to the call order list.
	push(@{$self->{'Test::MockClass::__CallOrderByObjectId'}{$objectId}}, $constructorName);

	# add the arguments to the arg list:
	my @args = @_;
	push(@{$self->{'Test::MockClass::__argumentsByObjectIdMethodnameOrder'}{$objectId}{$constructorName}}, \@args);
}

# this method is called before a mocked method, it is used to track the call order and arguments.
sub __preMethod {
	my $object = $_[0]; # the first call to a method is always the object!
	my $classToMock = ref($object) || $object;
	my $objectId = "$object";
	# this will be thread-safe (hopefully) because it's a readonly method, 
	# and the contents will never change for any mock object created by the $maker object referred to.
	my $self = '';
	{
		no strict 'refs';
		no warnings 'redefine';
		$self = $classToMock->___getMaker();
#		my $method = $classToMock . '::' . '___getMaker';
#		$self = &{$method};
	}
	# get the methodname from caller:
	my $methodname = $Hook::WrapSub::name;
	$methodname =~ s/^.*:://g; # strip off the package part at the front.
	# add the call to the call order list.
	push(@{$self->{'Test::MockClass::__CallOrderByObjectId'}{$objectId}}, $methodname);

	# add the arguments to the arg list:
	my @args = @_;
	shift(@args); # take off the object, so that the args match constructor args
	push(@{$self->{'Test::MockClass::__argumentsByObjectIdMethodnameOrder'}{$objectId}{$methodname}}, \@args);
}

# who's watching the store?  Jerry Lewis?
sub __watchStore {
	my $watch = shift;
	my $key = shift;
	my $value = shift;
	my ($self, $object) = @{$watch->{'Test::MockClass::___mockArgs'}};
	push(@{$self->{'Test::MockClass::__attributeAccessByObjectId'}{"$object"}}, ['store', $key, $value]);
	$watch->Store($key, $value);
	return $value;
}

# good ole' fetch
sub __watchFetch {
	my $watch = shift;
	my $key = shift;
	my ($self, $object) = @{$watch->{'Test::MockClass::___mockArgs'}};
	push(@{$self->{'Test::MockClass::__attributeAccessByObjectId'}{"$object"}}, ['fetch', $key]);
	return $watch->Fetch($key);
}

###############################################################################
###	 P U B L I C   F U N C T I O N S 
###############################################################################



###############################################################################
###	 P R I V A T E	 F U N C T I O N S 
###############################################################################



###############################################################################
###	 P A C K A G E	 A N D	 O B J E C T   D E S T R U C T O R S 
###############################################################################
sub DESTROY {
# 	my $self = shift;
# 	# remove everything from the fake symbol table:
# 	my $classToMock = $self->{'Test::MockClass::__mockClass'};

#  	{
#  		no strict 'refs';
#  		foreach my $key (keys %{$classToMock . '::'}) {
#  			delete(${$classToMock . '::'}{$key});
#  		}
#  	}
# 	# get the filename:
#     my $filename = $classToMock;
# 	$filename =~ s{::}{/}g;
# 	$INC{"$filename.pm"} = 0;

}
sub END {}


### The package return value (required)
1;
