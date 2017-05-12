#!/usr/local/bin/perl
use strict;
use warnings;
use Test::Spec;
use Test::More;
use Test::Deep;
use Test::Fatal qw(lives_ok);

use Test::Mock::Wrapper qw(NestedNamespace);
use NestedNamespace;

describe "cool stuff" => sub {
    it "is cool" => sub {
	is(&nestedFunction, undef);
    };
    it "is really cool" => sub {
	is(&nestedFunction, undef);
	my $wrapped = Test::Mock::Wrapper->new('NestedNamespace');
	$wrapped->verify('nestedFunction')->at_least(1);
    };
    it "still reverts to unmocked method after destroy" => sub {
	my $wrapped = Test::Mock::Wrapper->new('NestedNamespace');
	$wrapped->DESTROY;
	is(&nestedFunction, 'nested');
    };
};

runtests;