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

package mockNonExistentMethodTests;
use strict;
use Moose;
extends 'Test::Module::Runnable';

use English qw(-no_match_vars);
use Test::Module::Runnable;
use IO::Pipe;
use POSIX;
use Test::Exception;
use Test::More;
use Test::Output;

use lib 't/lib';
use Private::Test::Module::Runnable::Dummy;
use Private::Test::Module::Runnable::DummyWithAutoload;

sub setUp {
	my ($self) = @_;

	$self->sut(Test::Module::Runnable->new);

	return EXIT_SUCCESS;
}

sub tearDown {
	my ($self) = @_;

	$self->clearMocks();

	return EXIT_SUCCESS;
}

sub testClassWithoutAutoload {
	my ($self) = @_;
	plan tests => 2;

	my $pipe = IO::Pipe->new;
	BAIL_OUT("pipe: $ERRNO") unless $pipe;

	my $pid = fork;
	BAIL_OUT("fork: $ERRNO") unless defined $pid;

	# Easiest way to test BAIL_OUT is to fork a new process and execute it as
	# a new perl process.
	if ($pid == 0) {
		$pipe->writer();
		open STDOUT, '>&', $pipe;
		open STDERR, '>&', $pipe;

		my $code = <<EOF;
use Test::Module::Runnable;
use Private::Test::Module::Runnable::Dummy;
Test::Module::Runnable->new->mock('Private::Test::Module::Runnable::Dummy', 'noSuchMethod');
EOF

		exec('perl', (map { "-I$_" } @INC), '-e', $code);
		exit 127;
	}

	$pipe->reader();

	my $line = <$pipe>;
	is($line, "Bail out!  Cannot mock Private::Test::Module::Runnable::Dummy->noSuchMethod because it doesn't exist and Private::Test::Module::Runnable::Dummy has no AUTOLOAD\n",
		'bailed out as expected when mocking nonexistent method on class without AUTOLOAD');

	$pipe->close();
	wait;
	isnt($?, 0, 'process reported failure');

	return EXIT_SUCCESS;
}

sub testClassWithAutoload {
	my ($self) = @_;
	plan tests => 2;

	lives_ok { $self->mock('Private::Test::Module::Runnable::DummyWithAutoload', 'noSuchMethod') } 'can mock nonexistent method when class has AUTOLOAD';

	lives_ok { Private::Test::Module::Runnable::DummyWithAutoload->noSuchMethod } 'can call mocked method';

	return EXIT_SUCCESS;
}

package main;
use strict;
exit(mockNonExistentMethodTests->new->run);
