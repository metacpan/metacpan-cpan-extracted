#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::Most tests => 3;

use lib 'lib';
use Test::Mockingbird;

# Test the original
is(MyClass::add(2, 3), 5, "Original works correctly");

# Mock it
my $add = sub { 42 };
Test::Mockingbird::mock('MyClass', 'add', $add);

# Test the mock
is(MyClass::add(2, 3), 42, "Mocked add returns 42");

# Restore mocks
Test::Mockingbird::restore_all();

# Test the restore
is(MyClass::add(2, 3), 5, "Original add restored correctly");

done_testing();

1;

package MyClass;

sub add
{
	return $_[0] + $_[1];
}

1;
