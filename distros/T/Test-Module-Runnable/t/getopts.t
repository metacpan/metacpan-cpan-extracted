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
#

package getoptsTester;
use Getopt::Std;
use Moose;
use POSIX qw(EXIT_FAILURE EXIT_SUCCESS);
use Readonly;
use Test::Module::Runnable;
use Test::More 0.96;

extends 'Test::Module::Runnable';

Readonly my $EXPECT_ARG => '6f499142-b11a-11e7-919e-a54e42df3661';

has __seenArgument => (isa => 'Str', is => 'rw');

sub setUpBeforeClass {
	my ($self) = @_;
	my %opts;

	if (getopts('n:', \%opts)) {
		$self->__seenArgument($opts{n});
		return EXIT_SUCCESS;
	}

	return EXIT_FAILURE;
}

sub testOnlyThisTest {
	my ($self) = @_;

	plan tests => 1;

	is($self->__seenArgument, $EXPECT_ARG, 'Expected argument seen in only test expected to run');

	return EXIT_SUCCESS;
}

package main;
use strict;
use warnings;

sub main {
	# In Test::Module::Runner 0.1.0, specifying non-test name arguments would cause no test to run
	local @ARGV = ('-n', $EXPECT_ARG);
	return getoptsTester->new->run();
}

exit(main());
