#!/usr/bin/perl
#
# Module test framework
# Copyright (c) 2015-2019, Duncan Ross Palmer (2E0EOL) and others,
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

package ExampleTest;
use POSIX qw/EXIT_SUCCESS EXIT_FAILURE/;
use Moose;
use Test::Module::Runnable;
use Test::More 0.96;

extends 'Test::Module::Runnable';

has 'dummyRunCount' => (isa => 'Int', is => 'rw', default => 0);
has [qw(methodsSetUp methodsTornDown)] => (
	isa => 'HashRef', is => 'ro', default => sub {{}}
);

sub setUp {
	my ($self, %args) = @_;
	my $name = $args{method};

	return EXIT_FAILURE unless ($name);
	$self->methodsSetUp->{$name}++;

	return EXIT_SUCCESS;
}

sub tearDown {
	my ($self, %args) = @_;
	my $name = $args{method};

	return EXIT_FAILURE unless ($name);
	$self->methodsTornDown->{$name}++;

	return EXIT_SUCCESS;
}

sub increment {
	my $self = shift;
	$self->dummyRunCount(1 + $self->dummyRunCount);
}

sub funcNeverCalled {
	my $self = shift;
	plan tests => 1;

	$self->increment();
	cmp_ok($self->dummyRunCount, '>', 0, 'testFuncNeverCalled'); # Won't happen
	BAIL_OUT('Funcion never called, due to name');
}

sub testFuncIsCalled {
	my $self = shift;
	plan tests => 1;

	$self->increment();
	cmp_ok($self->dummyRunCount, '>', 0, 'funcIsCalled');

	return EXIT_SUCCESS;
}

sub testFuncAnotherIsCalled {
	my $self = shift;
	plan tests => 1;

	$self->increment();
	cmp_ok($self->dummyRunCount, '>', 0, 'testFuncAnotherIsCalled');

	return EXIT_SUCCESS;
}

package main;
use Test::More 0.96;
use POSIX qw/EXIT_SUCCESS/;
use Moose;
use List::MoreUtils qw/all/;

sub main {
	my $tester;
	my $ret;
	my @methodNames;
	my $n = 16;
	my %expectMethodNames = map { $_ => $n } qw/testFuncIsCalled testFuncAnotherIsCalled/;
	my $allResult;

	plan tests => 11;

	$tester = new_ok('ExampleTest');
	isa_ok($tester, 'Test::Module::Runnable');
	can_ok($tester, qw/run methodCount sut methodNames/);

	is($tester->dummyRunCount, 0, 'No tests yet run');
	subtest 'run' => sub { $ret = $tester->run(n => $n) };
	is($ret, EXIT_SUCCESS, 'Success returned');
	is($tester->dummyRunCount, 2 * $n, 'count methods run');

	@methodNames = $tester->methodNames;
	$allResult = all { $expectMethodNames{$_} } @methodNames;
	isnt($allResult, undef, 'methodNames contains all expected names');
	is($tester->methodCount, 2, 'Method count correct');
	is(scalar(@methodNames), $tester->methodCount, 'methodNames returns same as methodCount');

	subtest 'setUp and tearDown calls' => sub {
		my @types = (qw(methodsSetUp methodsTornDown));
		plan tests => scalar(@types);

		foreach my $type (@types) {
			is_deeply($tester->$type, \%expectMethodNames, $type);
		}
	};

	return $ret;
}

exit(main());
