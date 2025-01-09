#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::Most tests => 3;

use lib 'lib';
use Test::Mockingbird;

# Spy on a method
my $spy = Test::Mockingbird::spy('MyClass', 'do_something');
MyClass::do_something("arg1");
MyClass::do_something("arg2", "arg3");

my @calls = $spy->();
diag(Data::Dumper->new([\@calls])->Dump()) if($ENV{'TEST_VERBOSE'});
is(scalar(@calls), 2, "Captured two calls");
is_deeply($calls[0], ["arg1"], "Captured first call arguments");
is_deeply($calls[1], ["arg2", "arg3"], "Captured second call arguments");

Test::Mockingbird::restore_all();

1;

package MyClass;

sub do_something
{
	# ::diag($_[0]);
}

1;
