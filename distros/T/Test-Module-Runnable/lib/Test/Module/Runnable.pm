package Test::Module::Runnable;
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
	return $tester->run;

B<Deprecated> alternative:

	my $tester = new YourTestSuite;
	plan tests => $tester->testCount;
	foreach my $name ($tester->testMethods) {
		subtest $name => $tester->$name;
	}

=head1 DESCRIPTION

A test framework based on Moose introspection to automagically
call all methods matching a user-defined pattern.  Supports per-test
setup and tear-down routines and easy early L<Test::Builder/BAIL_OUT> using
L<Test::More>.

=cut

use Moose;

BEGIN {
	our $VERSION = '0.6.2';
}

extends 'Test::Module::Runnable::Base';

use Exporter qw(import);
use POSIX qw/EXIT_SUCCESS/;
use Test::Module::Runnable::Base;
use Test::More 0.96;

our @EXPORT_OK = qw(unique uniqueDomain uniqueStr uniqueStrCI uniqueLetters);

=head1 ATTRIBUTES

=over

=item C<sut>

System under test - a generic slot for an object you are testing, which
could be re-initialized under the C<setUp> routine, but this entry may be
ignored.

=item C<mocker>

This slot can be used during L</setUpBeforeClass> to set up a C<Test::MockModule>
for the L</sut> class being tested.  If set, C<< mocker->unmock_all() >> will be
called automagically, just after each test method is executed.
This will allow different methods to to be mocked, which are not directly relevant
to the test method being executed.

By default, this slot is C<undef>

=item C<pattern>

The pattern which defines which user-methods are considered tests.
Defaults to C<^test>.
Methods matching this pattern will be returned from L</methodNames>

=item C<logger>

A generic slot for a loggger, to be initialized with your logging framework,
or a mock logging system.

This slot is not touched by this package, but might be passed on to
your L</sut>, or you may wish to clear it between tests by sub-classing
this package.

=back

=head1 METHODS

=over

=item C<methodNames>

Returns a list of all names of test methods which should be called by C</subtest>,
ie. all method names beginning with 'test', or the user-defined L</pattern>.

If you use L</run>, this is handled automagically.

=item C<debug>

Call C<Test::Builder::diag> with a user-defined message,
if and only if the C<TEST_VERBOSE> environment variable is set.

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

Calls including arguments and return values are passed to the L</debug>
method.

=item unmock([class], [$method])

Clears all mock objects.

If no arguments are specified L<Test::Module::Runnable::Base/clearMocks> is called.

Is a class is specified, only that class is cleared.

If a method is specified too, only that method of that mocked class is cleared
(not methods by the same name under other classes).

It is not legal to unmock a method in many or unspecified classes,
doing so will invoke C<die()>.

The reference to the the tester is returned.

=item C<mockCalls($class, $method)>

Return a reference to an array of the calls made to the specified mocked function.  Each entry in the arrayref
is an arrayref of the arguments to that call, B<excluding> the object reference itself (i.e. C<$self>).

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

=item C<unique>

Returns a unique, integer ID, which is predictable.

An optional C<$domain> can be specified, which is a discrete sequence,
isolated from any other domain.  If not specified, a default domain is used.
The actual name for this domain is opaque.

A special domain; C<rand> can be used for random numbers which will not repeat.

=item C<methodCount>

Returns the number of tests to pass to C<plan>
If you use L</run>, this is handled automagically.

=item C<clearMocks>

Forcibly clear all mock objects, if required e.g. in C<tearDown>.

=back

=head1 PROTECTED METHODS

=over

=item C<_mockdump>

Helper method for dumping arguments and return values from C<mock> function.

=back

=head1 USER DEFINED METHODS

=over

=item C<setUpBeforeClass>

If you need to initialize your test suite before any tests run,
this hook is your opportunity.  If the setup fails, you should
return C<EXIT_FAILURE>.  you must return C<EXIT_SUCCESS> in order
for tests to proceed.

Don't write code here!  Override the method in your test class.

The default action is to do nothing.

=cut

sub setUpBeforeClass {
	return EXIT_SUCCESS;
}

=item C<tearDownAfterClass>

If you need to finalize any cleanup for your test suite, after all
tests have completed running, this hook is your opportunity.  If the
cleanup fails, you should return C<EXIT_FAILURE>.  If cleanup succeeds,
you should return C<EXIT_SUCCESS>.  You can also perform final sanity checking
here, because retuning C<EXIT_FAILURE> causes the suite to call
L<Test::Builder/BAIL_OUT>.

Don't write code here!  Override the method in your test class.

The default action is to do nothing.

=cut

sub tearDownAfterClass {
	return EXIT_SUCCESS;
}

=item C<setUp>

If you need to perform per-test setup, ie. before individual test methods
run, you should override this hook.  You must return C<EXIT_SUCCESS> from
the hook, otherwise the entire test suite will be aborted via L<Test::Builder/BAIL_OUT>.

Don't write code here!  Override the method in your test class.

The default action is to do nothing.

=cut

sub setUp {
	return EXIT_SUCCESS;
}

=item C<tearDown>

If you need to perform per-test cleanup, ie. after individual test methods
run, you should override this hook.  You must return C<EXIT_SUCCESS> from
the hook, otherwise the entire test suite will be aborted via L<Test::Builder/BAIL_OUT>.

Don't write code here!  Override the method in your test class.

The default action is to do nothing.

=cut

sub tearDown {
	return EXIT_SUCCESS;
}

sub unique {
	my (@args) = @_;
	return Test::Module::Runnable::Base::unique(@args);
}

=item C<uniqueStr([$length])>

Return a unique alphanumeric string which shall not be shorter than the specified C<$length>,
which is 1 by default.  The string is guaranteed to evaluate true in a boolean context.

The numerical value of each character is obtained from L</unique>.

Note that the strings returned from this function are B<only> guaranteed to
be in monotonically increasing lexicographical order if they are all of
the same length.  Therefore if this is a concern, specify a length which
will be long enough to include all the strings you wish to generate,
for example C<uniqueStr(4)> would produce C<62**4> (over 14 million)
strings in increasing order.

Can be called statically and exported in the same way as L</unique>.

=cut

sub uniqueStr {
	my (@args) = @_;
	return Test::Module::Runnable::Base::uniqueStr(@args);
}

=item C<uniqueStrCI($length)>

Works exactly the same as L</uniqueStr([$length])> except that the results are case
sensitively identical.  Note that the strings are not guaranteed to be
all lowercase or all uppercase, you may get "A" or "a", but you will
never get both.  No assumption should be made about the case.

=cut

sub uniqueStrCI {
	my (@args) = @_;
	return Test::Module::Runnable::Base::uniqueStrCI(@args);
}

=item C<uniqueDomain([$options])>

Returns a unique, fake domain-name.  No assumptions should be made about the domain
name or TLD returned, except that this domain cannot be registered via a domain registrar, is lower-case and is
unique per test suite run.

The optional C<$options>, if specified, must be a C<HASH> ref, and it may contain the following keys:

=over

=item C<length>

The length of the first part of the hostname.  This ensures correct lexicographic ordering.

=item C<lettersOnly>

Ensure that hostname parts only contain letters, not numbers.  This is also useful to
ensure correct lexicographic ordering.

=back

=cut

sub uniqueDomain {
	my (@args) = @_;
	return Test::Module::Runnable::Base::uniqueDomain(@args);
}

=item C<uniqueLetters($length)>

Return a unique string containing letters only, which shall not be shorter
than the specified C<$length>, which is 1 by default.  The string is guaranteed
to evaluate true in a boolean context.

Note that the strings returned from this function are B<only> guaranteed to
be in monotonically increasing lexicographical order if they are all of
the same length.  Therefore if this is a concern, specify a length which
will be long enough to include all the strings you wish to generate,
for example C<uniqueStr(4)> would produce C<62**4> (over 14 million)
strings in increasing order.

=cut

sub uniqueLetters {
	my (@args) = @_;
	return Test::Module::Runnable::Base::uniqueLetters(@args);
}

=item C<modeName>

If set, this routine will be called from the internal
L<Test::Module::Runnable::Base/__generateMethodName>
method, which is used to generate the method name displyed to the user.  This
name should represent the mode of testing currently in use, for example.
you may be re-running all the tests to test a different database driver.

If C<undef> or an empty string is returned, the result is ignored, as if you
had not defined this method.

SEE ALSO L</modeSwitch>

This is a dummy method which just returns C<undef>.
User test classes can override this.

=cut

sub modeName {
	return;
}

=item C<modeSwitch>

If set, this routine will be called between test runs.
This is typically used by setting an C<n> value of at least C<2>.
Every time the test suite finishes, this routine is called, and
you can replace a L</sut> or set a flag so that all tests can then
run with an underlying assumption shared between the tests inverted,
for example, with a different database driver.

The return value from your registered C<modeSwitch CODE> reference
should be zero to indicate success.  Your routine will be passed the
current C<n> iteration, starting with zero.

This is the default action for switching the mode of the test between
iterations is to report success but do nothing.
Testers which are subclasses may override this method.

=cut

sub modeSwitch {
	return EXIT_SUCCESS;
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

=back

=head1 AUTHOR

Duncan Ross Palmer, 2E0EOL L<mailto:palmer@overchat.org>

=head1 LICENCE

Daybo Logic Shared Library
Copyright (c) 2015-2024, Duncan Ross Palmer (2E0EOL), Daybo Logic
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

L<https://metacpan.org/release/Test-Module-Runnable>
L<https://git.sr.ht/~m6kvm/libtest-module-runnable-perl>
L<http://www.daybologic.co.uk/software.php?content=libtest-module-runnable-perl>

=head1 CAVEATS

None known.

=cut

1;
