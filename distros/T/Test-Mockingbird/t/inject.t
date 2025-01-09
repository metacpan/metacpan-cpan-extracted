#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most tests => 3;

use lib 'lib';
use Test::Mockingbird;

is(MyClass::db_connect(), 'Original code', 'Check system behaves');

# Inject mock object
my $mock_db = sub { return 'Mock DB Connection' };
Test::Mockingbird::inject('MyClass', 'db_connect', $mock_db);
is(MyClass::db_connect()->(), 'Mock DB Connection', 'Dependency injected successfully');

Test::Mockingbird::restore_all();

is(MyClass::db_connect(), 'Original code', 'Check system restored');

1;

package MyClass;

sub db_connect
{
	return 'Original code';
}

1;
