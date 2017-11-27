# Module test framework
# Copyright (c) 2015-2017, Duncan Ross Palmer (2E0EOL) and others,
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
setup and tear-down routines and easy early L<Test::Builder/BAIL_OUT> using
L<Test::More>.

=cut

package Test::Module::Runnable::Base;
use Moose;

use Data::Dumper;
use POSIX qw/EXIT_SUCCESS/;
use Test::MockModule;
use Test::More 0.96;

BEGIN {
	our $VERSION = '0.3.0';
}

=head1 ATTRIBUTES

=over

=item C<sut>

System under test - a generic slot for an object you are testing, which
could be re-initialized under the C<setUp> routine, but this entry may be
ignored.

=back

=cut

has 'sut' => (is => 'rw', required => 0);

=head1 PRIVATE ATTRIBUTES

=over

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
A hash is used to support multiple domains.

=cut

has '__unique' => (
	is => 'ro',
	isa => 'HashRef[Int]',
	default => sub {
		{ }
	},
);

=item C<__random>

Hash of random numbers already given out.

=back

=cut

has '__random' => (
	is => 'ro',
	isa => 'HashRef[Int]',
	default => sub {
		{ }
	},
);

=head1 METHODS

=over

=item C<setUpBeforeClass>

Placeholder method called before any test method is called, in order
for you to initialize your tests.

=item C<unique>

Returns a unique, integer ID, which is predictable.

An optional C<$domain> can be specified, which is a discrete sequence,
isolated from anhy other domain.  If not specified, a default domain is used.
The actual name for this domain is opaque, and is specified by
L</__unique_default_domain>.

A special domain; C<rand> can be used for random numbers which will not repeat.

=cut

sub unique {
	my ($self, $domain) = @_;
	my $useRandomDomain = 0;
	my $result;

	if (defined($domain) && length($domain)) {
		$useRandomDomain++ if ('rand' eq $domain);
	} else {
		$domain = $self->__unique_default_domain;
	}

	if ($useRandomDomain) {
		do {
			$result = int(rand(999_999_999));
		} while ($self->__random->{$result});
		$self->__random->{$result}++;
	} else {
		$result = ++($self->__unique->{$domain});
	}

	return $result;
}

=item C<pattern>

The pattern which defines which user-methods are considered tests.
Defaults to ^test
Methods matching this pattern will be returned from L</methodNames>

=cut

has 'pattern' => (is => 'ro', isa => 'Regexp', default => sub { qr/^test/ });

=item C<logger>

A generic slot for a loggger, to be initialized with your logging framework,
or a mock logging system.

This slot is not touched by this package, but might be passed on to
your L</sut>, or you may wish to clear it between tests by sub-classing
this package.

=cut

has 'logger' => (is => 'rw', required => 0);

=item C<mocker>

This slot can be used during L</setUpBeforeClass> to set up a C<Test::MockModule>
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

			if (scalar(@userRunTests) > 0) {
				@tests = @userRunTests;
			}
		}
	}

	plan tests => scalar(@tests) * $params{n};

	$fail = $self->setUpBeforeClass(); # Call any registered pre-suite routine
	$self->__wrapFail('setUpBeforeClass', undef, $fail);
	for (my $i = 0; $i < $params{n}; $i++) {
		foreach my $method (@tests) {
			$fail = 0;

			# Check if user specified just one test, and this isn't it
			confess(sprintf('Test \'%s\' does not exist', $method))
				unless $self->can($method);

			$fail = $self->setUp(method => $method); # Call any registered pre-test routine
			$self->__wrapFail('setUp', $method, $fail);
			subtest $method => sub { $fail = $self->$method(method => $method) }; # Correct test (or all)
			$self->__wrapFail('method', $method, $fail);
			$self->mocker->unmock_all() if ($self->mocker);
			$fail = 0;
			$fail = $self->tearDown(method => $method); # Call any registered post-test routine
			$self->__wrapFail('tearDown', $method, $fail);
		}
	}
	$fail = $self->tearDownAfterClass(); # Call any registered post-suite routine
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

=item C<mock($class, $method, $return)>

This mocks the given method on the specified class, with the specified
return value, described below.  Additionally, stores internally a log of all
method calls, and their arguments.  Note that the first argument is not
saved, i.e. the object on which the method was called, as this is rarely useful
in a unit test comparison.

The return value, C<$return>, may be specified in one of two ways:

=over

=item A C<CODE> reference

In which case the code reference is simply called
each time, with all arguments as passed to the mocked function, and the
return value passed as-is to the caller.  Note that care is taken that
if the mocked method is called in array context, the code reference is
called in array context, and likewise for scalar context.

=item An C<ARRAY> reference

In which case, a value is shifted from the front
of the array.  If the value removed is itself a C<CODE> ref the code
reference is called, and its return value returned, as described above,
otherwise the value is returned as-is.

Note that you cannot return a list by adding it to an array, so if you need to
use the array form, and also return a list, you will need to add a C<CODE> reference into the array:

   $self->mock($class, $method, [
     1,                       # first call returns scalar '1'
     [2,3,4],                 # second call returns array reference
     sub { return (5,6,7) },  # third call returns a list
  ]);

=back

If no value is specified, or if the specified array is exhaused, then either
C<undef> or an empty array is returned, depending on context.

Calls including arguments and return values are passed to the C<debug()>
method.

=cut

sub mock {
	my ($self, $class, $method, $return) = @_;

	unless ($class->can($method) || $class->can('AUTOLOAD')) {
		BAIL_OUT("Cannot mock $class->$method because it doesn't exist and $class has no AUTOLOAD")
	}

	die('$return must be CODE or ARRAY ref') if defined($return) && ref($return) ne 'CODE' && ref($return) ne 'ARRAY';

	unless ($self->{mock_module}->{$class}) {
		$self->{mock_module}->{$class} = Test::MockModule->new($class);
	}

	$self->{mock_module}->{$class}->mock($method, sub {
		my @ret;
		my @args = @_;

		push @{$self->{mock_args}->{$class}->{$method}}, [@args];

		if ($return) {
			my ($val, $empty);
			if (ref($return) eq 'ARRAY') {
				# $return is an array ref, so shift the next value
				if (@$return) {
					$val = shift @$return;
				} else {
					$empty = 1;
				}
			} else {
				# here $return must be a CODE ref, so just set $val
				# and carry on.
				$val = $return;
			}

			if (ref($val) eq 'CODE') {
				if (wantarray) {
					@ret = $val->(@_);
				} else {
					$ret[0] = scalar $val->(@_);
				}
			} else {
				# just return this value, unless we're in the case
				# where we exhausted the array, in which case we
				# don't set this - it would make us return (undef)
				# rather than empty list in list context.
				$ret[0] = $val unless $empty;
			}
		}

		# TODO: When running the CODE ref above, we should catch any fatal error,
		# log them here, and then re-throw the error.
		shift @args;
		$self->debug(sprintf('%s::%s(%s) returning (%s)',
				$class, $method, _mockdump(\@args), _mockdump(\@ret)));
		return (wantarray ? @ret : $ret[0]);
	});

	return;
}

=item unmock([class], [$method])

Clears all mock objects.

If no arguments are specified clearMocks is called.

Is a class is specified, only that class is cleared.

If a method is specified too, only that method of that mocked class is cleared
(not methods by the same name under other classes).

It is not legal to unmock a method in many or unspecified classes,
doing so will invoke C<die()>.

The reference to the the tester is returned.

=cut

sub unmock {
	my ($self, $class, $method) = @_;

	if (!$class) {
		die('It is not legal to unmock a method in many or unspecified classes') if ($method);
		$self->clearMocks;
	} elsif (!$method) {
		delete($self->{mock_module}->{$class});
		delete($self->{mock_args}->{$class});
	} else {
		if ($self->{mock_module}->{$class}) {
			$self->{mock_module}->{$class}->unmock($method);
		}
		delete($self->{mock_args}->{$class}->{$method});
	}

	return $self;
}

=item C<_mockdump>

Helper method for dumping arguments and return values from C<mock> function.

=cut

sub _mockdump {
	my $arg = shift;
	my $dumper = Data::Dumper->new([$arg], ['arg']);
	$dumper->Indent(1);
	$dumper->Maxdepth(1);
	my $str = $dumper->Dump();
	$str =~ s/\n\s*/ /g;
	$str =~ s/^\$arg = \[\s*//;
	$str =~ s/\s*\];\s*$//s;
	return $str;
}

=item C<mockCalls($class, $method)>

Return a reference to an array of the calls made to the specified mocked function.  Each entry in the arrayref
is an arrayref of the arguments to that call, B<excluding> the object reference itself (i.e. C<$self>).

=cut

sub mockCalls {
	my ($self, $class, $method) = @_;
	return $self->__mockCalls($class, $method);
}

=item C<mockCallsWithObject($class, $method)>

Return a reference to an array of the calls made to the specified mocked function.  Each entry in the arrayref
is an arrayref of the arguments to that call, B<including> the object reference itself (i.e. C<$self>).

This method is strongly encouraged in preference to L</mockCalls($class,
$method)> if your test constructs multiple instances of the same class,
so that you know that the right method calls were actually made on the
right object.

Normal usage:

  cmp_deeply($self->mockCallsWithObject($class, $method), [
    [ shallow($instance1), $arg1, $arg2 ],
    [ shallow($instance2), $otherArg1, $otherArg2 ],
    ...
  ], 'correct method calls');

=cut

sub mockCallsWithObject {
	my ($self, $class, $method) = @_;
	return $self->__mockCalls($class, $method, withObject => 1);
}

=item C<clearMocks>

Forcibly clear all mock objects, if required e.g. in C<tearDown>.

=cut

sub clearMocks {
	my ($self) = @_;

	$self->{mock_module} = {};
	$self->{mock_args} = {};
	return;
}

=item C<__mockCalls>

Helper method used by L</mockCalls($class, $method)> and L</mockCallsWithObject($class, $method)>.

=cut

sub __mockCalls {
	my ($self, $class, $method, %args) = @_;

	my $calls = $self->{mock_args}->{$class}->{$method} || [];
	unless ($args{withObject}) {
		# This ugly code takes $calls, which is a an arrayref
		# of arrayrefs, and maps it into a new arrayref, where
		# each inner arrayref is a copy of the original, with the
		# first element removed (i.e. the object reference).
		#
		# i.e. given $calls = [
		#    [ $obj, $arg1, $arg2 ],
		#    [ $obj, $arg3, $arg4 ],
		# ]
		# this will set $calls = [
		#    [ $arg1, $arg2 ],
		#    [ $arg3, $arg4 ],
		# ]
		$calls = [ map { [ @{$_}[1..$#$_] ] } @$calls ];
	}

	return $calls;
}

=back

=head1 AUTHOR

Duncan Ross Palmer, 2E0EOL L<mailto:palmer@overchat.org>

=head1 LICENCE

Daybo Logic Shared Library
Copyright (c) 2015-2017, Duncan Ross Palmer (2E0EOL), Daybo Logic
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

L<https://bitbucket.org/2E0EOL/libtest-module-runnable-perl>

=head1 CAVEATS

None known.

=cut

1;
