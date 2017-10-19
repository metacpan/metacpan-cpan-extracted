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

package Test::Module::Runnable;
use Moose;
use Test::More 0.96;
use POSIX qw/EXIT_SUCCESS/;

BEGIN {
	our $VERSION = '0.2.3';
}

extends 'Test::Module::Runnable::Base';

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

=back

=cut

1;
