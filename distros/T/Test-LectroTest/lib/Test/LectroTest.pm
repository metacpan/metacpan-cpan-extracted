package Test::LectroTest;
{
  $Test::LectroTest::VERSION = '0.5001';
}

use warnings;
use strict;

use Test::LectroTest::TestRunner;
use Filter::Util::Call;
require Test::LectroTest::Property;
require Test::LectroTest::Generator;

=head1 NAME

Test::LectroTest - Easy, automatic, specification-based tests

=head1 VERSION

version 0.5001

=head1 SYNOPSIS

    #!/usr/bin/perl -w

    use MyModule;  # contains code we want to test
    use Test::LectroTest;

    Property {
        ##[ x <- Int, y <- Int ]##
        MyModule::my_function( $x, $y ) >= 0;
    }, name => "my_function output is non-negative" ;

    Property { ... }, name => "yet another property" ;

    # more properties to check here

=head1 DESCRIPTION

This module provides a simple (yet full featured) interface to
LectroTest, an automated, specification-based testing system for Perl.
To use it, declare properties that specify the expected behavior
of your software.  LectroTest then checks your software to see whether
those properties hold.

Declare properties using the C<Property> function, which takes a
block of code and promotes it to a L<Test::LectroTest::Property>:

    Property {
        ##[ x <- Int, y <- Int ]##
        MyModule::my_function( $x, $y ) >= 0;
    }, name => "my_function output is non-negative" ;

The first part of the block must contain a generator-binding
declaration.  For example:

        ##[  x <- Int, y <- Int  ]##

(Note the special bracketing, which is required.)  This particular
binding says, "For all integers I<x> and I<y>."  (By the way, you
aren't limited to integers.  LectroTest also gives you booleans,
strings, lists, hashes, and more, and it lets you define your own
generator types.  See L<Test::LectroTest::Generator> for more.)

The second part of the block is simply a snippet of code that makes
use of the variables we bound earlier to test whether a property holds
for the piece of software we are testing:

        MyModule::my_function( $x, $y ) >= 0;

In this case, it asserts that C<MyModule::my_function($x,$y)> returns
a non-negative result.  (Yes, C<$x> and C<$y> refer to the same I<x>
and I<y> that we bound to the generators earlier.  LectroTest
automagically loads these lexically bound Perl variables with values
behind the scenes.)

B<Note:> If you want to use testing assertions like C<ok> from
L<Test::Simple> or C<is>, C<like>, or C<cmp_ok> from L<Test::More>
(and the related family of L<Test::Builder>-based testing modules),
see L<Test::LectroTest::Compat>, which lets you mix and match
LectroTest with these modules.

Finally, we give the whole Property a name, in this case "my_function
output is non-negative."  It's a good idea to use a meaningful name
because LectroTest refers to properties by name in its output.

Let's take a look at the finished property specification:

    Property {
        ##[ x <- Int, y <- Int ]##
        MyModule::my_function( $x, $y ) >= 0;
    }, name => "my_function output is non-negative" ;

It says, "For all integers I<x> and I<y>, we assert that my_function's
output is non-negative."

To check whether this property holds, simply put it in a Perl program
that uses the Test::LectroTest module.  (See the L</SYNOPSIS> for an
example.)  When you run the program, LectroTest will load the property
(and any others in the file) and check it by running random trials
against the software you're testing.

B<Note:> If you want to place LectroTest property checks into
a test plan managed by L<Test::Builder>-based modules such as
L<Test::Simple> or L<Test::More>, see L<Test::LectroTest::Compat>.

If LectroTest is able to "break" your software during the property
check, it will emit a counterexample to your property's assertions and
stop.  You can plug the counterexample back into your software to
debug the problem.  (You might also want to add the counterexample to
a list of regression tests.)

A successful LectroTest looks like this:

  1..1
  ok 1 - 'my_function output is non-negative' (1000 attempts)

On the other hand, if you're not so lucky:

  1..1
  not ok 1 - 'my_function output is non-negative' falsified \
      in 324 attempts
  # Counterexample:
  # $x = -34
  # $y = 0

=head1 EXIT CODE

The exit code returned by running a suite of property checks is the
number of failed checks.  The code is 0 if all properties passed their
checks or I<N> if I<N> properties failed. (If more than 254 properties
failed, the exit code will be 254.)


=head1 ADJUSTING THE TESTING PARAMETERS

There is one testing parameter (among others) that you might wish to
change from time to time: the number of trials to run for each
property checked.  By default it is 1,000.  If you want to try more or
fewer trials, pass the C<trials=E<gt>>I<N> flag:

  use Test::LectroTest trials => 10_000;


=head1 TESTING FOR REGRESSIONS AND CORNER CASES

LectroTest can record failure-causing test cases to a file, and it can
play those test cases back as part of its normal testing strategy.
The easiest way to take advantage of this feature is to set the
I<regressions> parameter when you C<use> this module:

    use Test::LectroTest
        regressions => "regressions.txt";

This tells LectroTest to use the file "regressions.txt" for both
recording and playing back failures.  If you want to record and
play back from separate files, or want only to record I<or> play
back, use the I<record_failures> and/or
I<playback_failures> options:

    use Test::LectroTest
        playback_failures => "regression_suite_for_my_module.txt",
        record_failures   => "failures_in_the_field.txt";

See L<Test::LectroTest::RegressionTesting> for more.


=head1 CAVEATS

When you use this module, it imports all of the generator-building
functions from L<Test::LectroTest::Generator> into the your code's
namespace.  This is almost always what you want, but I figured I ought
to say something about it here to reduce the possibility of surprise.

A Property specification must appear in the first column, i.e.,
without any indentation, in order for it to be automatically loaded
and checked.  If this poses a problem, let me know, and this
restriction can be lifted.

=cut

our $r;
our @props;
our @opts;

sub import {
    my $self = shift;
    Test::LectroTest::Property->export_to_level(1, $self);
    Test::LectroTest::Generator->export_to_level(1, $self, ':all');
    @opts = @_;
    $r = Test::LectroTest::TestRunner->new( @_ );
    my $lines = 0;
    my $subfilter = Test::LectroTest::Property::_make_code_filter();
    filter_add( sub {
        my $status = filter_read();
        s{^(?=Test|Property)\b}{push \@Test::LectroTest::props, };
        $subfilter->( $status );
    });
}

sub _run {
    return @props - $r->run_suite( @props, @opts );
}

END {
    if ($r) {
        my $failed = Test::LectroTest::_run();
        $? = $failed > 254 ? 254 : $failed;
    }
}

1;

__END__


=head1 SEE ALSO

For a gentle introduction to LectroTest, see
L<Test::LectroTest::Tutorial>.  Also, the slides from my LectroTest
talk for the Pittsburgh Perl Mongers make for a great introduction.
Download a copy from the LectroTest home (see below).

L<Test::LectroTest::RegressionTesting> explains how to test for
regressions and corner cases using LectroTest.

L<Test::LectroTest::Compat> lets you mix LectroTest with the
popular family of L<Test::Builder>-based modules such as
L<Test::Simple> and L<Test::More>.

L<Test::LectroTest::Property> explains in detail what
you can put inside of your property specifications.

L<Test::LectroTest::Generator> describes the many generators and
generator combinators that you can use to define the test or
condition space that you want LectroTest to search for bugs.

L<Test::LectroTest::TestRunner> describes the objects that check your
properties and tells you how to turn their control knobs.  You'll want
to look here if you're interested in customizing the testing
procedure.

=head1 LECTROTEST HOME

The LectroTest home is
http://community.moertel.com/LectroTest.
There you will find more documentation, presentations, mailing-list archives, a wiki,
and other helpful LectroTest-related resources.  It's also the
best place to ask questions.

=head1 AUTHOR

Tom Moertel (tom@moertel.com)

=head1 INSPIRATION

The LectroTest project was inspired by Haskell's
QuickCheck module by Koen Claessen and John Hughes:
http://www.cs.chalmers.se/~rjmh/QuickCheck/.

=head1 COPYRIGHT and LICENSE

Copyright (c) 2004-05 by Thomas G Moertel.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
