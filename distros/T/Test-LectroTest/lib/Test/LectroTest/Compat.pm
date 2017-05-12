package Test::LectroTest::Compat;
{
  $Test::LectroTest::Compat::VERSION = '0.5001';
}

use warnings;
use strict;

use Filter::Util::Call;
use Test::Builder;
use Test::LectroTest::TestRunner;
require Test::LectroTest::Property;
require Test::LectroTest::Generator;

=head1 NAME

Test::LectroTest::Compat - Use LectroTest property checks in a Test::Simple world

=head1 VERSION

version 0.5001

=head1 SYNOPSIS

    #!/usr/bin/perl -w

    use MyModule;  # contains code we want to test
    use Test::More tests => 2;
    use Test::LectroTest::Compat;

    # property specs can now use Test::Builder-based
    # tests such as Test::More's cmp_ok()

    my $prop_nonnegative = Property {
        ##[ x <- Int, y <- Int ]##
        cmp_ok(MyModule::my_function( $x, $y ), '>=', 0);
    }, name => "my_function output is non-negative" ;

    # and we can now check whether properties hold
    # as a Test::Builder-style test that integrates
    # with other T::B tests

    holds( $prop_nonnegative );   # test whether prop holds
    cmp_ok( 0, '<', 1, "trivial 0<1 test" );  # a "normal" test

=head1 DESCRIPTION

This module lets you use mix LectroTest property checking with other
popular Test::* modules.  With it, you can use C<is()>- and
C<ok()>-style assertions from Test::* modules within your LectroTest
property specifications and you can check LectroTest properties as
part of a Test::Simple or Test::More test plan.  (You can actually
take advantage of any module based on Test::Builder, not just
Test::Simple and Test::More.)

The module exports a single function C<holds> which is described
below.

=head2 holds(I<property>, I<opts>...)

    holds( $prop_nonnegative );  # check prop_nonnegative

    holds( $prop_nonnegative, trials => 100 );

    holds(
        Property {
            ##[ x <- Int ]##
            my_function2($x) < 0;
        }, name => "my_function2 is non-positive"
    );

Checks whether the given property holds.

When called, this method creates a new
Test::LectroTest::TestRunner, asks the TestRunner to check the
property, and then reports the result to Test::Builder, which in
turn reports to you as part of a typical Test::Simple- or
Test::More-style test plan.  Any options you provide to C<holds> after
the property will be passed to the C<TestRunner> so you can change the
number of trials to run and so on.  (See the docs for C<new> in
L<Test::LectroTest::TestRunner> for the complete list of
options.)


=head1 TESTING FOR REGRESSIONS AND CORNER CASES

LectroTest can record failure-causing test cases to a file, and it can
play those test cases back as part of its normal testing strategy.
The easiest way to take advantage of this feature is to set the
I<regressions> parameter when you C<use> this module:

    use Test::LectroTest::Compat
        regressions => "regressions.txt";

This tells LectroTest to use the file "regressions.txt" for both
recording and playing back failures.  If you want to record and
play back from separate files, or want only to record I<or> play
back, use the I<record_failures> and/or
I<playback_failures> options:

    use Test::LectroTest::Compat
        playback_failures => "regression_suite_for_my_module.txt",
        record_failures   => "failures_in_the_field.txt";

See L<Test::LectroTest::RegressionTesting> for more.

B<NOTE:>  If you pass any of the recording or playback parameters
to Test::LectroTest::Compat, you must have version 0.3500 or
greater of LectroTest installed.  Module authors, update your
modules' build dependencies accordingly.


=cut

my $Test = Test::Builder->new();

sub import {
    my $self = shift;
    my $caller = caller;
    { no strict 'refs';  *{$caller.'::holds'} = \&holds; }
    $Test->exported_to($caller);
    $Test->plan(_filter_recorder_opts(@_));
    Test::LectroTest::Property->export_to_level(1, $self);
    Test::LectroTest::Generator->export_to_level(1, $self, ':all');
    filter_add(Test::LectroTest::Property->_make_code_filter);
}

sub holds {
    my ($diag_store, $results) = _check_property(@_);
    my $success = $results->success;
    (my $name = $results->summary) =~ s/^.*?- /property /;
    $Test->ok($success, $name);
    $Test->diag(@$diag_store) if @$diag_store;
    my $details = $results->details;
    $details =~ s/^.*?\n//;     # remove summary line
    $details =~ s/^\# /    /mg; # replace commenting w/ indent
    $Test->diag($details) if $details;
    return $success ? 1 : 0;    # same result policy as Test::Builder::ok
}

my ($playback_failures, $record_failures);

sub _check_property {
    no warnings 'redefine';
    my $diag_store = [];
    my $property = shift;
    local *Test::Builder::ok   = \&_disconnected_ok;
    local *Test::Builder::diag = sub { shift; push @$diag_store, @_; 0 };

    # for efficiency, we recycle any recorders that the TestRunner
    # may have created (the recorders cache test cases)

    my @opts = (
        $playback_failures ? (playback_failures => $playback_failures) : (),
        $record_failures ? (record_failures => $record_failures) : (),
        @_  # passed-in options go last to override defaults
    );
    my $runner = Test::LectroTest::TestRunner->new(@opts);
    my @results = ($diag_store, $runner->run($property));

    # the TestRunner may have converted file names into TestRecorder
    # objects, so we just "upgrade" to these objects if they exist
    # and we're still holding filenames

    $playback_failures = $runner->playback_failures
        if $playback_failures && !ref($playback_failures);
    $record_failures = $runner->record_failures
        if $record_failures && !ref($record_failures);

    return @results;
}

my @RECORDER_OPTS = (qw( record_failures playback_failures regressions ));

sub _filter_recorder_opts {
    my (@opts);
    while (@_) {
        unless (grep $_ eq $_[0], @RECORDER_OPTS) {
            push @opts, shift;
        }
        else {
            my ($ropt, $rval) = (shift, shift);
            if ($ropt eq "regressions") {
                $playback_failures = $record_failures = $rval;
            }
            elsif ($ropt eq "playback_failures") {
                $playback_failures = $rval;
            }
            else {
                $record_failures = $rval;
            }
        }
    }
    return @opts;
}

# the following sub replaces Test::Builder's
# ok() method when we want to disable T::B's
# test harness

sub _disconnected_ok { $_[1] ? 1 : 0 }


1;

=head1 BUGS

In order to integrate with the L<Test::Builder> testing harness (whose
underlying testing model is somewhat incompatible with the needs of
random trial-based testing) this module redefines two Test::Builder
functions (C<ok()> and C<diag()>) for the duration of each property
check.


=head1 SEE ALSO

For a gentle introduction to LectroTest, see
L<Test::LectroTest::Tutorial>.  Also, the slides from my LectroTest
talk for the Pittsburgh Perl Mongers make for a great introduction.
Download a copy from the LectroTest home (see below).

L<Test::LectroTest::RegressionTesting> explains how to test for
regressions and corner cases using LectroTest.

L<Test::LectroTest::Property> explains in detail what
you can put inside of your property specifications.

L<Test::LectroTest::Generator> describes the many generators and
generator combinators that you can use to define the test or
condition space that you want LectroTest to search for bugs.

L<Test::LectroTest::TestRunner> describes the objects that check your
properties and tells you how to turn their control knobs.  You'll want
to look here if you're interested in customizing the testing
procedure.

L<Test::Simple> and L<Test::More> explain how to do simple
case-based testing in Perl.

L<Test::Builder> is the test harness upon which this module
is built.


=head1 AUTHOR

Tom Moertel (tom@moertel.com)

=head1 INSPIRATION

The LectroTest project was inspired by Haskell's
QuickCheck module by Koen Claessen and John Hughes:
http://www.cs.chalmers.se/~rjmh/QuickCheck/.

=head1 COPYRIGHT and LICENSE

Copyright (c) 2004-13 by Thomas G Moertel.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
