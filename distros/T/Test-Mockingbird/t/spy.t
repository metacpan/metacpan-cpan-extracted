#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::Most tests => 7;

use lib 'lib';
use Test::Mockingbird;

cmp_ok(MyClass::do_something('arg0'), 'eq', 'done something', 'routine is called before being spied on');

# Spy on a method
my $spy = Test::Mockingbird::spy('MyClass', 'do_something');
MyClass::do_something('arg1');
cmp_ok(MyClass::do_something('arg2', 'arg3'), 'eq', 'done something', 'routine is called when being spied on');

my @calls = $spy->();
diag(Data::Dumper->new([\@calls])->Dump()) if($ENV{'TEST_VERBOSE'});
is(scalar(@calls), 2, 'Captured two calls');
is_deeply($calls[0], ['arg1'], 'Captured first call arguments');
is_deeply($calls[1], ['arg2', 'arg3'], 'Captured second call arguments');

Test::Mockingbird::restore_all();

cmp_ok(MyClass::do_something('arg4'), 'eq', 'done something', 'routine is called before after spied on');
is(scalar(@calls), 2, 'No longer capturing calls');

1;

package MyClass;

sub do_something
{
	# ::diag($_[0]);
	return 'done something';
}

1;
