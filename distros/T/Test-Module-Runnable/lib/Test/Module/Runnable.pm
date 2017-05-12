#!/usr/bin/perl
#
# Module test framework
# Copyright (c) 2015-2016, David Duncan Ross Palmer (2E0EOL) and others,
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

=head1 NAME

Test::Module::Runnable - A runnable framework on Moose for running tests

=head1 SYNOPSIS

package YourTestSuite;
use Moose;
use Test::More 0.96;
use strict;

extends 'Test::Module::Runnable';

sub helper { } # Not called
sub testExample { } # Automagically called due to 'test' prefix.

package main;

my $tester = new YourTestSuite;
plan tests => $tester->testCount;
foreach my $name ($tester->testMethods) {
	subtest $name => $tester->$name;
}

alternatively...

my $tester = new YourTestSuite;
return $tester->run;

=head1 DESCRIPTION

A test framework based on Moose introspection to automagically
call all methods matching a user-defined pattern.  Supports per-test
setup and tear-down routines and easy early C<BAIL_OUT> using
C<Test::More>.

=cut

package Test::Module::Runnable;

use Moose;
use Test::More 0.96;
use POSIX qw/EXIT_SUCCESS/;

use strict;
use warnings;

our $VERSION = '0.1.0';

=head2 ATTRIBUTES

=over

=item C<sut>

System under test - a generic slot for an object you are testing, which
could be re-initialized under the C<setUp> routine, but this entry may be
ignored.

=cut

has 'sut' => (is => 'rw', required => 0);

=item C<__unique_default_domain>

The internal default domain value.  This is used when C<unique>
is called without a domain, because a key cannot be C<undef> in Perl.

=cut

has '__unique_default_domain' => (
	isa => 'Str',
	is => 'ro',
	default => 'db3eb5cf-a597-4038-aea8-fd06faea6eed'
);

=item C<__unique>

Tracks the counter returned by C<unique>.
Always contains the previous value returned, or zero before any calls.

=back

=cut

has '__unique' => (
	is => 'ro',
	isa => 'HashRef[Int]',
	default => sub {
		{ }
	},
);

=head2 METHODS

=over

=item <unique>

Returns a unique ID, which is predictable.

=cut

sub unique {
	my ($self, $domain) = @_;
	$domain = (defined($domain) && length($domain)) ? ($domain) : ($self->__unique_default_domain);
	return ++($self->__unique->{$domain});
}

=item C<pattern>

The pattern which defines which user-methods are considered tests.
Defaults to ^test
Methods matching this pattern will be returned from C<methodNames>

=cut

has 'pattern' => (is => 'ro', isa => 'Regexp', default => sub { qr/^test/ });

=item C<logger>

A generic slot for a loggger, to be initialized with your logging framework,
or a mock logging system.

This slot is not touched by this package, but might be passed on to
your C<sut>, or you may wish to clear it between tests by sub-classing
this package.

=cut

has 'logger' => (is => 'rw', required => 0);

=item C<mocker>

This slot can be used during C<setUpBeforeClass> to set up a C<Test::MockModule>
for the C<sut> class being tested.  If set, C<mocker->unmock_all()> will be
called automagically, just after each test method is executed.
This will allow different methods to to be mocked, which are not directly relevant
to the test method being executed.

By default, this slot is C<undef>

=cut

has 'mocker' => (
	is => 'rw',
	isa => 'Maybe[Test::MockModule]',
	required => 0,
	default => undef,
);

=item C<methodNames>

Returns a list of all names of test methods which should be called by C<subtest>,
ie. all method names beginning with 'test', or the user-defined C<pattern>.

If you use C<run>, this is handled automagically.

=cut

sub methodNames {
        my @ret = ( );
        my $self = shift;
        my @methodList = $self->meta->get_all_methods();

        foreach my $method (@methodList) {
		$method = $method->name;
                next unless ($self->can($method)); # Skip stuff we cannot do
                next if ($method !~ $self->pattern); # Skip our own helpers
                push(@ret, $method);
        }

        return @ret;
}

=item C<methodCount>

Returns the number of tests to pass to C<plan>
If you use C<run>, this is handled automagically.

=cut

sub methodCount {
        my $self = shift;
        return scalar($self->methodNames());
}

sub __wrapFail {
	my ($self, $type, $method, $returnValue) = @_;
	return if (defined($returnValue) && $returnValue eq '0');
	if (!defined($method)) { # Not method-specific
		BAIL_OUT('Must specify type when evaluating result from method hooks')
			if ('setUpBeforeClass' ne $type && 'tearDownAfterClass' ne $type);

		$method = 'N/A';
	}
	BAIL_OUT($type . ' returned non-zero for ' . $method);
}

=item C<run>

Executes all of the tests, in a random order
An optional override may be passed with the tests parameter.

  * tests
    An ARRAY ref which contains the inclusive list of all tests
    to run.  If not passed, all tests are run. If an empty list
    is passed, no tests are run.  If a test does not exist, C<confess>
    is called.

  * n
    Number of times to iterate through the tests.
    Defaults to 1.  Setting to a higher level is useful if you want to
    prove that the random ordering of tests does not break, but you do
    not want to type 'make test' many times.

Returns:
    The return value is always C<EXIT_SUCCESS>, which you can pass straight
    to C<exit>

=cut

sub run {
	my ($self, %params) = @_;
	my ($fail, @tests) = (0);

	$params{n} = 1 unless ($params{n});

	if (ref($params{tests}) eq 'ARRAY') { # User specified
		@tests = @{ $params{tests} };
	} else {
		@tests = $self->methodNames();
		if (@ARGV) {
			my @userRunTests = ( );
			foreach my $testName (@tests) {
				foreach my $arg (@ARGV) {
					next if ($arg ne $testName);
					push(@userRunTests, $testName);
				}
			}
			@tests = @userRunTests;
		}
	}

	plan tests => scalar(@tests) * $params{n};

	$fail = $self->setUpBeforeClass() if ($self->can('setUpBeforeClass')); # Call any registered pre-suite routine
	$self->__wrapFail('setUpBeforeClass', undef, $fail);
	for (my $i = 0; $i < $params{n}; $i++) {
		foreach my $method (@tests) {
			$fail = 0;

			# Check if user specified just one test, and this isn't it
			confess(sprintf('Test \'%s\' does not exist', $method))
				unless $self->can($method);

			$fail = $self->setUp(method => $method) if ($self->can('setUp')); # Call any registered pre-test routine
			$self->__wrapFail('setUp', $method, $fail);
			subtest $method => sub { $fail = $self->$method(method => $method) }; # Correct test (or all)
			$self->__wrapFail('method', $method, $fail);
			$self->mocker->unmock_all() if ($self->mocker);
			$fail = 0;
			$fail = $self->tearDown(method => $method) if ($self->can('tearDown')); # Call any registered post-test routine
			$self->__wrapFail('tearDown', $method, $fail);
		}
	}
	$fail = $self->tearDownAfterClass() if ($self->can('tearDownAfterClass')); # Call any registered post-suite routine
	$self->__wrapFail('tearDownAfterClass', undef, $fail);

	return EXIT_SUCCESS;
}

=item C<debug>

Call C<Test::Builder::diag> with a user-defined message,
if and only if the C<TEST_VERBOSE> environment variable is set.

=cut

sub debug {
	my (undef, $format, @params) = @_;
	return unless ($ENV{'TEST_VERBOSE'});
	diag(sprintf($format, @params));
	return;
}

=back

=head1 AUTHOR

David Duncan Ross Palmer, 2E0EOL L<mailto:palmer@overchat.org>

=head1 LICENCE

Daybo Logic Shared Library
Copyright (c) 2015, David Duncan Ross Palmer (2E0EOL), Daybo Logic
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the Daybo Logic nor the names of its contributors
      may be used to endorse or promote products derived from this software
      without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

=head1 AVAILABILITY

https://bitbucket.org/2E0EOL/libtest-module-runnable-perl

=head1 CAVEATS

None known.

=cut

1;
