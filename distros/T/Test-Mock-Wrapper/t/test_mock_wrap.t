#!/usr/local/bin/perl
use strict;
use warnings;
use Test::Spec;
use Test::More;
use Test::Deep;
use Test::Fatal qw(lives_ok);
use lib qw(..);
use Test::Mock::Wrapper;
use base qw(Test::Spec);
use Scalar::Util qw(weaken isweak);
use metaclass;
use Data::Dumper;

describe "Test::Mock::Wrapper" => sub {
    describe "basic functionality" => sub {
	my($mock);
	before sub {
	    $mock = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new());
	};
	it "uses mocked response for basic mocked method" => sub {
	    $mock->addMock('foo', returns=>'bam');
	    my($res) = $mock->getObject->foo();
	    is($res, 'bam');
	};
	it "returns a conditional return value if the with condition is met" => sub {
	    $mock->addMock('foo', with=>[ignore, 'man'], returns=>'choo');
	    $mock->addMock('foo', returns=>'bam');
	    is($mock->getObject->foo('man'), 'choo');
	};
	it "returns default return value if no with condition is met" => sub {
	    $mock->addMock('foo', with=>['man'], returns=>'choo');
	    $mock->addMock('foo', returns=>'bam');
	    is($mock->getObject->foo('who'), 'bam');
	};
	it "returns first provided return value if multiple conditions are met" => sub {
	    $mock->addMock('foo', with=>[supersetof('man')], returns=>'choo');
	    $mock->addMock('foo', with=>[supersetof('bat')], returns=>'foo');
	    is($mock->getObject->foo('man', 'bat'), 'choo');
	};
    };
    describe "type=wrap" => sub {
	my($mock);
	before sub {
	    $mock = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new());
	};
	it "calls the original object for non-mocked method" => sub {
	    is($mock->getObject->baz, 'bat');
	};
	it "dies when calling a method not available on original object" => sub {
	    eval {
		$mock->getObject->far;
		fail("should have thrown exception for non-existent method");
	    };
	    ok(defined $@);
	};
    };
    describe "type=stub" => sub {
	my($mock);
	before sub {
	    $mock = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new(), type=>'stub');
	};
	it "returns undef for non mocked method" => sub {
	    is($mock->getObject->baz, undef);
	};
	it "returns undef when calling a method not available on original object" => sub {
	    eval {
		$mock->getObject->far;
		ok("should have trapped unknow method call");
	    };
	    is($@, '', 'eval error should be null');
	};
    };
    describe "type=mock" => sub {
	my($mock);
	before sub {
	    $mock = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new(), type=>'mock');
	};
	it "returns undef for non mocked method" => sub {
	    is($mock->getObject->baz, undef);
	};
	it "dies when calling a method not available on original object" => sub {
	    eval {
		$mock->getObject->far;
		fail("should have thrown exception for non-existent method");
	    };
	    ok(defined $@);
	};
    };
    describe "Package Mocking" => sub {
	it "returns a mocked object from a call to new in the mocked package" => sub {
	    my $mocker = Test::Mock::Wrapper->new('UnderlyingObjectToTest');
	    my $test_object = UnderlyingObjectToTest->new(type=>'stub');
	    isa_ok($test_object, 'UnderlyingObjectToTest');
	    is($test_object->foo, undef);
	    $mocker->DESTROY();
	};
	it "restores underlying object after destroy" => sub {
	    my $test_object = UnderlyingObjectToTest->new();
	    isa_ok($test_object, 'UnderlyingObjectToTest');
	    is($test_object->foo, 'bar');
	};
	it "can handle 'immutable' packages" => sub {
	    lives_ok {
		Immutable::ExamplePackage->meta->make_immutable;
		my $immutableWrapper = Test::Mock::Wrapper->new('Immutable::ExamplePackage');
	    };
	};
	it "can use instance of an oject to limit scope of mocked response" => sub {
	    my $mocker = Test::Mock::Wrapper->new('UnderlyingObjectToTest');
	    my $obj1 = UnderlyingObjectToTest->new();
	    my $obj2 = UnderlyingObjectToTest->new();
	    $mocker->addMock('foo', with=>[supersetof($obj1)], returns=>'hi');
	    $mocker->addMock('foo', with=>[supersetof($obj2)], returns=>'bye');
	    is($obj1->foo, 'hi');
	    is($obj2->foo, 'bye');
	};
    };

    describe "Reset Mocks" => sub {
	my($mock);
	before sub {
	    $mock = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new(), type=>'mock');
	    $mock->addMock('foo', returns=>'bar');
	    $mock->addMock('baz', returns=>'bat');
	};
	it "clears all method mocks if called with no arguments" => sub {
	    is($mock->getObject->foo, 'bar');
	    is($mock->getObject->baz, 'bat');
	    $mock->resetMocks;
	    is($mock->getObject->baz, undef);
	    is($mock->getObject->foo, undef);
	};
	it "clears only specified method if provided" => sub {
	    is($mock->getObject->baz, 'bat');
	    is($mock->getObject->foo, 'bar');
	    $mock->resetMocks('foo');
	    is($mock->getObject->foo, undef);
	    is($mock->getObject->baz, 'bat');
	};
    };

    describe "Call verification" => sub {
	my($mock);
	before sub {
	    $mock = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new(), type=>'mock');
	};
	it "suppports exact call number verification" => sub {
	    $mock->addMock('foo');
	    $mock->getObject->foo;
	    $mock->verify('foo')->exactly(1);
	    $mock->addMock('baz');
	    $mock->getObject->baz;
	    $mock->getObject->baz;
	    $mock->getObject->baz;
	    $mock->verify('baz')->exactly(3);
	};
	it "suppports never" => sub {
	    $mock->addMock('foo');
	    $mock->verify('foo')->never;
	};
	it "suppports once" => sub {
	    $mock->addMock('foo');
	    $mock->getObject->foo;
	    $mock->verify('foo')->once;
	};
	it "suppports at least" => sub {
	    $mock->addMock('foo');
	    $mock->getObject->foo;
	    $mock->getObject->foo;
	    $mock->getObject->foo;
	    $mock->verify('foo')->at_least(1);
	};
	it "suppports at most" => sub {
	    $mock->addMock('foo');
	    $mock->getObject->foo;
	    $mock->getObject->foo;
	    $mock->getObject->foo;
	    $mock->verify('foo')->at_most(4);
	};
	it "is chainable" => sub {
	    $mock->addMock('foo');
	    $mock->getObject->foo;
	    $mock->verify('foo')->once->at_least(1)->at_most(1);
	};
	it "can be queried by 'with'" => sub {
	    $mock->addMock('foo');
	    $mock->getObject->foo({name=>'dave', status=>'cool'});
	    $mock->getObject->foo({name=>'dave', status=>'smart'});
	    $mock->getObject->foo({name=>'juli', status=>'cute'});
	    $mock->getObject->foo({name=>'tom', status=>'smart'});
	    $mock->getObject->foo({name=>'dan', status=>'lazy'});
	    $mock->verify('foo')->with(supersetof(superhashof({name=>'dave'})))->exactly(2);
	    $mock->verify('foo')->with(supersetof(superhashof({name=>'dave'})))->at_least(1)->with(supersetof(superhashof({status=>'cool'})))->once;
	};
	xit "retains call list at each distinct state" => sub {
	    $mock->addMock('foo');
	    $mock->getObject->foo({name=>'dave', status=>'cool'});
	    $mock->getObject->foo({name=>'dave', status=>'smart'});
	    $mock->getObject->foo({name=>'juli', status=>'cute'});
	    $mock->getObject->foo({name=>'tom', status=>'smart'});
	    $mock->getObject->foo({name=>'dan', status=>'lazy'});
	    my $verifier = $mock->verify('foo');
	    $verifier->with(supersetof({name=>'dave', status=>ignore()}))->exactly(2);
	    $verifier->with(supersetof({name=>'juli', status=>ignore()}))->once;
	};
	xdescribe "resetCalls" => sub {
	    before "each" => sub {
		$mock->addMock('foo');
		$mock->addMock('baz');
		$mock->getObject->foo('bar');
		$mock->getObject->baz('bat');
		$mock->verify('foo')->at_least(1);
		$mock->verify('baz')->at_least(1);
	    };
	    it "resets history for all calls if called without arguments" => sub {
		$mock->resetCalls;
		$mock->verify('foo')->never;
		$mock->verify('baz')->never;
	    };
	    it "resets history for only specified method if provided" => sub {
		$mock->resetCalls('foo');
		$mock->verify('foo')->never;
		$mock->verify('baz')->at_least(1);
	    };
	};
    };
};

runtests;

package UnderlyingObjectToTest;

sub new {
    return bless({}, __PACKAGE__);
}

sub foo {
    return 'bar';
}

sub baz {
    return 'bat';
}

package Immutable::ExamplePackage;
use metaclass;

sub ga {
    return 'farv';
}
