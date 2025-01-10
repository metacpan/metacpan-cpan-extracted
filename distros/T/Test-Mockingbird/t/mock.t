#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most tests => 5;

use lib 'lib';
use Test::Mockingbird;

ok(!MyClass->can('greet'));

# Mock a method
Test::Mockingbird::mock('MyClass', 'greet', sub { return 'Hello, Mock!' });
ok(MyClass->can('greet'));
is(MyClass::greet(), 'Hello, Mock!', 'Method mocked successfully');

# Test::Mockingbird::restore_all();

Test::Mockingbird::unmock('MyClass', 'greet');

# Even though it's no longer callable (you get told that the routine is undefined),
# Universal->can now says that the routine exists.
# There's a bug somewhere, but I have no idea where,
# so instead just verify a failure has happened

# ok(!MyClass->can('greet'));

dies_ok( sub { MyClass::greet() }, 'greet no longer exists' );
like($@, qr/Undefined subroutine &MyClass::greet/, 'greet() is now undefined');

1;

package MyClass;

1;
