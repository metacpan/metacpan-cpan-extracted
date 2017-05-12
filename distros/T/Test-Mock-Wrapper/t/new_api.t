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

describe "Test::Mock::Wrapper new mocking api" => sub {
    it "creates a default mock with null return with no arguments" => sub {
        my ($mocker) = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new);
        $mocker->addMock('foo');
        is($mocker->getObject->foo, undef);
    };
    it "creates an argument scoped mock if with called" => sub {
        my ($mocker) = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new);
        $mocker->addMock('foo')->with(supersetof('bat'));
        is($mocker->getObject->foo,        'bar');
        is($mocker->getObject->foo('bat'), undef);
    };
    it "adds the return value if called on the return of with" => sub {
        my ($mocker) = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new);
        $mocker->addMock('foo')->with(supersetof('bat'))->returns('foo');
        is($mocker->getObject->foo,        'bar');
        is($mocker->getObject->foo('bat'), 'foo');
    };
    it "executes sub routine for return value if given a sub ref" => sub {
        my ($mocker) = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new);
        $mocker->addMock('foo')->with(supersetof('bat'))->returns(sub { return 'fun' });
        is($mocker->getObject->foo('bat'), 'fun');
    };
    it "passes input arguments to sub routine" => sub {
        my ($mocker) = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new);
        $mocker->addMock('foo')->with(supersetof('bat'))->returns(sub { return $_[1] });
        is($mocker->getObject->foo('bat'), 'bat');
    };
    it "only uses default if no conditions match" => sub {
        my ($mocker) = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new);
        $mocker->addMock('foo')->with(supersetof('bat'))->returns(sub { return $_[1] });
        $mocker->addMock('foo')->returns('default');
        is($mocker->getObject->foo('bat'),  'bat');
        is($mocker->getObject->foo('ball'), 'default');
    };
    it "only uses default if no conditions match (regardless of order specified)" => sub {
        my ($mocker) = Test::Mock::Wrapper->new(UnderlyingObjectToTest->new);
        $mocker->addMock('foo')->returns('default');
        $mocker->addMock('foo')->with(supersetof('bat'))->returns(sub { return $_[1] });
        is($mocker->getObject->foo('bat'),  'bat');
        is($mocker->getObject->foo('ball'), 'default');
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
