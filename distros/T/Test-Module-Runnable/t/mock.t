#!/usr/bin/perl
#
# Module test framework
# Copyright (c) 2015-2024, Duncan Ross Palmer (2E0EOL) and others,
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#     * Neither the name of the Daybo Logic nor the names of its contributors
#       may be used to endorse or promote products derived from this software
#       without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

package mockTests;
use strict;
use lib 't/lib';
use Moose;

extends 'Test::Module::Runnable';

use POSIX qw(EXIT_SUCCESS);
use Private::Test::Module::Runnable::Appender;
use Private::Test::Module::Runnable::Dummy;
use Test::Deep qw(cmp_deeply shallow);
use Test::Exception;
use Test::Module::Runnable;
use Test::More;

sub setUp {
	my ($self, %params) = @_;

	$self->sut(Test::Module::Runnable->new);

	return $self->SUPER::setUp(%params);
}

sub tearDown {
	my ($self, %params) = @_;
	$self->sut->clearMocks();
	return $self->SUPER::setUp(%params);
}

sub testVerbose {
	my ($self) = @_;

	my $v = $ENV{TEST_VERBOSE};
	$ENV{TEST_VERBOSE} = 1;

	$self->_testVerbose([], [], 'Private::Test::Module::Runnable::Dummy::realMethod() returning ()');
	$self->_testVerbose([1], [2], 'Private::Test::Module::Runnable::Dummy::realMethod(1) returning (2)');
	$self->_testVerbose([1, 2], ['a', 'b'], "Private::Test::Module::Runnable::Dummy::realMethod(1, 2) returning ('a', 'b')");

	$self->_testVerbose([{}, []], [Private::Test::Module::Runnable::Dummy->new], qr/^
		Private::Test::Module::Runnable::Dummy::realMethod
		\(
		'HASH\(\w+\)', \s 'ARRAY\(\w+\)'
		\)
		\s returning \s
		\(
		'Private::Test::Module::Runnable::Dummy=HASH\(\w+\)'
		\)$/x);

	$ENV{TEST_VERBOSE} = $v;

	return EXIT_SUCCESS;
}

sub _testVerbose {
	my ($self, $in, $out, $expectedMessage) = @_;

	$self->sut->mock('Private::Test::Module::Runnable::Dummy', 'realMethod', sub { return @$out });

	my $lastdiag;
	my $mock = Test::MockModule->new('Test::Builder');
	$mock->mock('diag', sub { $lastdiag = $_[1] });

	my $obj = Private::Test::Module::Runnable::Dummy->new;
	(undef) = $obj->realMethod(@$in);

	$mock = undef;

	if (ref $expectedMessage) {
		like($lastdiag, $expectedMessage);
	} else {
		is($lastdiag, $expectedMessage);
	}

	return;
}

sub test {
	my ($self) = @_;
	my @list;

	my $appender = Private::Test::Module::Runnable::Appender->new(appendTo => \@list);

	$appender->append("one");

	$self->sut->mock('Private::Test::Module::Runnable::Appender', 'append');

	$appender->append("two");
	$appender->append();

	# 'two' and <no-args> mocked
	is_deeply($self->sut->mockCalls('Private::Test::Module::Runnable::Appender', 'append'), [
		['two'],
		[],
	], 'correct mocked logger calls');

	$self->sut->clearMocks();

	is_deeply($self->sut->mockCalls('Private::Test::Module::Runnable::Appender', 'append'), [], 'mock calls cleared');

	$appender->append("four");

	# we should have 'one' and 'four' appended for real
	is_deeply(\@list, [
		['one'],
		['four'],
	], 'correct appended entries (real)');

	return EXIT_SUCCESS;
}

sub testCode {
	my ($self) = @_;

	my $counter = 0;
	my $dummy = Private::Test::Module::Runnable::Dummy->new();

	$self->sut->mock('Private::Test::Module::Runnable::Dummy', 'realMethod', sub { $counter++ });
	$dummy->realMethod("first");
	$dummy->realMethod("second");

	is($counter, 2, 'mocked code block was called');

	return EXIT_SUCCESS;
}

sub testDie {
	my ($self) = @_;
	plan tests => 4;

	$self->sut->mock(ref($self->sut), 'unique', [
		"first",
		sub { die "dies second time" },
		"third",
	]);

	is($self->sut->unique('first'), 'first', 'first return value correct');
	throws_ok { $self->sut->unique('second') } qr/^dies second time/, 'dies second time correctly';
	is($self->sut->unique('third'), 'third', 'third return value correct');

	is_deeply($self->sut->mockCalls(ref($self->sut), 'unique'), [
		['first'],
		['second'],
		['third'],
	], 'correct calls recorded');

	return EXIT_SUCCESS;
}

sub testArray {
	my ($self) = @_;

	$self->sut->mock('Private::Test::Module::Runnable::Dummy', 'realMethod', [1,2,3]);

	my $dummy = Private::Test::Module::Runnable::Dummy->new();

	is($dummy->realMethod, 1);
	is($dummy->realMethod, 2);
	is($dummy->realMethod, 3);
	is($dummy->realMethod, undef, 'undef (list exhausted)');
	is($dummy->realMethod, undef, 'undef again (just checking)');

	is_deeply([$dummy->realMethod], [], 'empty array in list context');

	return EXIT_SUCCESS;
}

sub testArrayMixed {
	my ($self) = @_;

	$self->sut->mock('Private::Test::Module::Runnable::Dummy', 'realMethod', [
		'first call',
		['second', 'call'],
		{ third => 'call' },
		undef,
		sub { return ('fifth', 'call') },
	]);

	my $dummy = Private::Test::Module::Runnable::Dummy->new;
	is($dummy->realMethod, 'first call');
	is_deeply($dummy->realMethod, ['second', 'call']);
	is_deeply($dummy->realMethod, { third => 'call' });
	is($dummy->realMethod, undef, 'fourth call undef');
	is_deeply([$dummy->realMethod], ['fifth', 'call']); # note [] on left, so realMethod() returns list, not array ref
	is($dummy->realMethod, undef);

	return EXIT_SUCCESS;
}

sub testBadReturn {
	my ($self) = @_;

	throws_ok { $self->sut->mock('Test::Module::Runnable', 'unique', 1) } qr/^\$return must be CODE or ARRAY ref /;

	return EXIT_SUCCESS;
}

sub testCodeReturn {
	my ($self) = @_;

	my $dummy = Private::Test::Module::Runnable::Dummy->new;

	$self->sut->mock('Private::Test::Module::Runnable::Dummy', 'realMethod', sub { return 'business' });
	is($dummy->realMethod(), 'business');

	$self->sut->mock('Private::Test::Module::Runnable::Dummy', 'realMethod', sub { return ('list', 'of', 'things') });
	is_deeply([$dummy->realMethod()], ['list', 'of', 'things']);

	return EXIT_SUCCESS;
}

sub testMultipleFunctions {
	my ($self) = @_;

	my $dummy = Private::Test::Module::Runnable::Dummy->new;

	$self->sut->mock('Private::Test::Module::Runnable::Dummy', 'realMethod');
	$self->sut->mock('Private::Test::Module::Runnable::Dummy', 'realMethod2');

	$dummy->realMethod("this is a realMethod");
	$dummy->realMethod2("this is a realMethod2");

	is_deeply($self->sut->mockCalls('Private::Test::Module::Runnable::Dummy', 'realMethod'), [
		['this is a realMethod'],
	]);
	is_deeply($self->sut->mockCalls('Private::Test::Module::Runnable::Dummy', 'realMethod2'), [
		['this is a realMethod2'],
	]);

	return EXIT_SUCCESS;
}

sub testMockCallsWithObject {
	my ($self) = @_;
	plan tests => 1;

	my $dummy1 = Private::Test::Module::Runnable::Dummy->new;
	my $dummy2 = Private::Test::Module::Runnable::Dummy->new;

	$self->sut->mock('Private::Test::Module::Runnable::Dummy', 'realMethod');

	my $msg = $self->uniqueStr();

	$dummy1->realMethod();
	$dummy2->realMethod($msg);

	cmp_deeply($self->sut->mockCallsWithObject('Private::Test::Module::Runnable::Dummy', 'realMethod'), [
		[ shallow($dummy1) ],
		[ shallow($dummy2), $msg ],
	], 'correct calls with object refs');

	return EXIT_SUCCESS;
}

package main;
use strict;
exit(mockTests->new->run) unless caller;
