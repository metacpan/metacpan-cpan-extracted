#!/usr/bin/env perl
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

package modeSwitchTester;
use Moose;

extends 'Test::Module::Runnable';

use POSIX qw(EXIT_SUCCESS);
use Test::More 0.96;

has [qw(modeTracker mode)] => (isa => 'Int', is => 'rw', default => 0);

sub modeSwitch {
	my ($self, $n) = @_;

	$self->debug(sprintf('mode is %d, iteration %d, setting mode %d',
	    $self->mode, $n, 1 + $n));

	$self->mode(1 + $n);

	return EXIT_SUCCESS;
}

sub modeName {
	my ($self) = @_;
	if ($self->mode % 2 == 0) {
		return 'second';
	}

	return 'first'
}

sub testBlah {
	my ($self) = @_;
	plan tests => 1;

	is($self->mode, $self->modeTracker, sprintf('Mode is %u', $self->modeTracker));
	$self->modeTracker(1 + $self->modeTracker);

	return EXIT_SUCCESS;
}

package main;
use strict;
use warnings;

exit(modeSwitchTester->new->run(n => 3));
