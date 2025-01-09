#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most tests => 3;

use lib 'lib';
use Test::Mockingbird;

ok(!MyClass->can('greet'));

# Mock a method
Test::Mockingbird::mock('MyClass', 'greet', sub { return 'Hello, Mock!' });
ok(MyClass->can('greet'));
is(MyClass::greet(), 'Hello, Mock!', 'Method mocked successfully');

# Test::Mockingbird::restore_all();

Test::Mockingbird::unmock('MyClass', 'greet');
# ok(!MyClass->can('greet'));
# diag('>>>>', MyClass::greet());

1;

package MyClass;

1;
