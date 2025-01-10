#!/usr/bin/env perl

# Test object level methods

use strict;
use warnings;

use Data::Dumper;
use Test::Most tests => 3;

use lib 'lib';
use Test::Mockingbird;

# Test the original
my $obj = MyClass->new();

is($obj->add(2, 3), 5, 'Original works correctly');

# Mock it
my $add = sub { 42 };
Test::Mockingbird::mock('MyClass', 'add', $add);

# Test the mock
is($obj->add(2, 3), 42, 'Mocked add returns 42');

# Restore mocks
Test::Mockingbird::restore_all();

# Test the restore
is($obj->add(2, 3), 5, 'Original add restored correctly');

done_testing();

1;

package MyClass;

sub new
{
	my $class = shift;

	return bless {}, $class;
}

sub add
{
	shift;
	return $_[0] + $_[1];
}

1;
