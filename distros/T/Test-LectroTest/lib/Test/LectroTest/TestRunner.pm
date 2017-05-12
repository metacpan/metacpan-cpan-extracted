package Test::LectroTest::TestRunner;
{
  $Test::LectroTest::TestRunner::VERSION = '0.5001';
}

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Scalar::Util qw(blessed);

use Test::LectroTest::Property qw( NO_FILTER );
use Test::LectroTest::FailureRecorder;
use Test::LectroTest::Generator qw( Unit );

=head1 NAME

Test::LectroTest::TestRunner - Configurable TAP-compatible engine for running LectroTest property checks

=head1 VERSION

version 0.5001

=head1 SYNOPSIS

 use Test::LectroTest::TestRunner;

 my @args = trials => 1_000, retries => 20_000;
 my $runner = Test::LectroTest::TestRunner->new( @args );

 # test a single property and print details upon failure
 my $result = $runner->run( $a_single_lectrotest_property );
 print $result->details unless $result->success;

 # test a suite of properties, w/ Test::Harness::TAP output
 my $num_successful = $runner->run_suite( @properties );
 print "# All passed!" if $num_successful == @properties;

=head1 DESCRIPTION

B<STOP!> If you just want to write and run simple tests, see
L<Test::LectroTest>.  If you really want to learn about the
property-checking apparatus or turn its control knobs, read on.

This module provides Test::LectroTest::TestRunner, a class of objects
that tests properties by running repeated random trials.  Create a
TestRunner, configure it, and then call its C<run> or C<run_suite>
methods to test properties individually or in groups.

=head1 METHODS

The following methods are available.

=cut

our %defaults = (
    trials            =>  1_000,
    retries           => 20_000,
    scalefn           => sub { $_[0] / 2 + 1 },
    number            => 1,
    verbose           => 1,
    record_failures   => undef,
    playback_failures => undef,
);

# build field accessors

for my $field (keys %defaults) {
    no strict 'refs';
    *{$field} = sub {
        my $self = shift;
        $self->{$field} = $_[0] if @_;
        $self->{$field}
    };
}

sub regressions {
    my ($self, $value) = @_;
    $self->record_failures($value);
    $self->playback_failures($value);
}

=pod

=head2 new(I<named-params>)

  my $runner = new Test::LectroTest::TestRunner(
    trials      => 1_000,
    retries     => 20_000,
    scalefn     => sub { $_[0] / 2 + 1 },
    verbose     => 1,
    regressions => "/path/to/regression_suite.txt",
  );

Creates a new Test::LectroTest::TestRunner and configures it with the
given named parameters, if any.  Typically, you need only provide the
C<trials> parameter because the other values are reasonable for almost
all situations.  Here is what each parameter means:

=over 4

=item trials

The number of trials to run against each property checked.
The default is 1_000.

=item retries

The number of times to allow a property to retry trials (via
C<$tcon-E<gt>retry>) during the entire property check before aborting
the check.  This is used to prevent infinite looping, should
the property retry every attempt.

=item scalefn

A subroutine that scales the sizing guidance given to input
generators.

The TestRunner starts with an initial guidance of 1 at the beginning
of a property check.  For each trial (or retry) of the property, the
guidance value is incremented.  This causes successive trials to be
tried using successively more complex inputs.  The C<scalefn>
subroutine gets to adjust this guidance on the way to the input
generators.  Typically, you would change the C<scalefn> subroutine if
you wanted to change the rate and which inputs grow during the course
of the trials.

=item verbose

If this paramter is set to true (the default) the TestRunner will use
verbose output that includes things like label frequencies and
counterexamples.  Otherwise, only one-line summaries will be output.
Unless you have a good reason to do otherwise, leave this parameter
alone because verbose output is almost always what you want.

=item record_failures

If this parameter is set to a file's pathname (or a FailureRecorder
object), the TestRunner will record property-check failures to the
file (or recorder).  (This is an easy way to build a
regression-testing suite.)  If the file cannot be created or
written to, this parameter will be ignored.  Set this parameter to
C<undef> (the default) to turn off recording.

=item playback_failures

If this parameter is set to a file's pathname (or a FailureRecorder
object), the TestRunner will load previously recorded failures from
the file (or recorder) and use them as I<additional> test cases when
checking properties.  If the file cannot be read, this option will be
ignored.  Set this parameter to C<undef> (the default) to turn off
recording.

=item regressions

If this parameter is set to a file's pathname (or a FailureRecorder
object), the TestRunner will load failures from and record failures to
the file (or recorder).  Setting this parameter is a shortcut for, and
exactly equivalent to, setting I<record_failures> and
<playback_failures> to the same value, which is typically what you
want when managing a persistent suite of regression tests.

This is a write-only accessor.

=back

You can also set and get the values of the configuration properties
using accessors of the same name.  For example:

  $runner->trials( 10_000 );

=cut

sub new {
    my $class = shift;
    my $self = bless { %defaults, @_ }, $class;
    if (defined(my $val = delete $self->{regressions})) {
        $self->regressions($val);
    }
    return $self;
}

=pod

=head2 run(I<property>)

  $results = $runner->run( $a_property );
  print $results->summary, "\n";
  if ($results->success) {
      # celebrate!
  }

Checks whether the given property holds by running repeated random
trials.  The result is a Test::LectroTest::TestRunner::results object,
which you can query for fined-grained information about the outcome of
the check.

The C<run> method takes an optional second argument which gives
the test number.  If it is not provided (usually the case), the
next number available from the TestRunner's internal counter is
used.

  $results = $runner->run( $third_property, 3 );

Additionally, if the TestRunner's I<playback_failures> parameter is
defined, this method will play back any relevant failure cases from
the given playback file (or FailureRecorder).

Additionally, if the TestRunner's I<record_failures> parameter is
defined, this method will record any new failures to the given file
(or FailureRecorder).

=cut

sub run {
    my ($self, $prop, $number) = @_;

    # if a test number wasn't provided, take the next from our counter

    unless (defined $number) {
        $number = $self->number;
        $self->number( $number + 1);
    }

    # create a new results object to hold our results; run trials

    my ($inputs_list, $testfn, $name) = @$prop{qw/inputs test name/};
    my $results = Test::LectroTest::TestRunner::results->new(
        name => $name, number => $number
    );

    # create an empty label store and start at attempts = 0

    my %labels;
    my $attempts = 0;
    my $in_regressions = 1;

    # for each set of input-generators, run a series of trials

    for my $gen_specs (@{$self->_regression_generators($name)},
                       undef,  # separator
                       @$inputs_list) {

        # an undef value separates the regression-test generators (if
        # any) from the property's own generators; we use it to turn
        # on failure recording after the regression-test generators
        # have all been used.  (we don't record failures during
        # regression testing because they have already been recorded)

        if (!defined($gen_specs)) {
            $in_regressions = 0;
            next;
        }

        my $retries = 0;
        my $base_size = 0;
        my @vars = sort keys %$gen_specs;
        my $scalefn = $self->scalefn;

        for (1 .. ($in_regressions ? 1 : $self->trials)) {

            # run a trial

            $base_size++;
            my $controller=Test::LectroTest::TestRunner::testcontroller->new;
            my $size = $scalefn->($base_size);
            my $inputs = { "WARNING" => "EXCEPTION FROM WITHIN GENERATOR" };
            my $success = eval {
                $inputs = { map {($_, $gen_specs->{$_}->generate($size))}
                            @vars };
                $testfn->($controller, @$inputs{@vars});
            };

            # did the trial bail out because of an exception?

            $results->exception( do { my $ex=$@; chomp $ex; $ex } ) if $@;

            # was it retried?

            if ($controller->retried) {
                $retries++;
                if ($retries >= $self->retries) {
                    $results->incomplete("$retries retries exceeded");
                    $results->attempts( $attempts );
                    return $results;
                }
                redo;  # re-run the trial w/ new inputs
            }

            # the trial ran to completion, so count the attempt

            $attempts++;

            # and count the trial toward the bin with matching labels

            if ($controller->labels) {
                local $" = " & ";
                my @cl = sort @{$controller->labels};
                $labels{"@cl"}++ if @cl;
            }

            # if the trial outcome was failure, return a counterexample

            unless ( $success ) {
                $results->counterexample_( $inputs );
                $results->notes_( $controller->notes );
                $results->attempts( $attempts );
                $self->_record_regression( $name, $inputs )
                    unless $in_regressions;
                return $results;
            }

            # otherwise, loop up to the next trial
        }
    }

    $results->success(1);
    $results->attempts( $attempts );
    $results->labels( \%labels );
    return $results;
}

sub _recorder_for_writes {
    shift->_get_recorder('record_failures');
}

sub _recorder_for_reads {
    shift->_get_recorder('playback_failures');
}

sub _get_recorder {
    my ($self, $attr) = @_;
    my $val = $self->{$attr};
    if ($val && ! ref $val) {
        $val = $self->{$attr} = Test::LectroTest::FailureRecorder->new($val);
    }
    return $val;
}

sub _regression_generators {

    my ($self, $prop_name) = @_;

    # if we get an error reading failures from the recorder, ignore it
    # because if we're building a new regression suite, there may not
    # even be a failure-recording file yet

    my $failures = eval {
        $self->_recorder_for_reads->get_failures_for_property($prop_name);
    } || [];

    my @gens;

    for my $inputs (@$failures) {

        # convert the failure case's inputs into a set of generator
        # bindings that will generate the failure case

        my %gen_bindings;
        $gen_bindings{$_} = Unit($inputs->{$_}) for keys %$inputs;
        push @gens, \%gen_bindings;
    }

    return \@gens;
}

sub _record_regression {
    my ($self, $name, $inputs) = @_;
    eval {
        $self->_recorder_for_writes # may be undef
             ->record_failure_for_property($name, $inputs);
    };
}


=pod

=head2 run_suite(I<properties>...)

  my $num_successful = $runner->run_suite( @properties );
  if ($num_successful == @properties) {
      # celebrate most jubilantly!
  }

Checks a suite of properties, sending the results of each
property checked to C<STDOUT> in a form that is compatible with
L<Test::Harness::TAP>.  For example:

  1..5
  ok 1 - Property->new disallows use of 'tcon' in bindings
  ok 2 - magic Property syntax disallows use of 'tcon' in bindings
  ok 3 - exceptions are caught and reported as failures
  ok 4 - pre-flight check catches new w/ no args
  ok 5 - pre-flight check catches unbalanced arguments list

By default, labeling statistics and counterexamples (if any) are
included in the output if the TestRunner's C<verbose> property is
true.  You may override the default by passing the C<verbose> named
parameter after all of the properties in the argument list:

  my $num_successes = $runner->run_suite( @properties,
                                          verbose => 1 );
  my $num_failed = @properties - $num_successes;

=cut

sub _prop($) { blessed $_[0] && $_[0]->isa("Test::LectroTest::Property") }

sub run_suite {
    local $| = 1;
    my $self = shift;
    my @tests;
    my @opts;
    while (@_) {
        if (_prop $_[0]) {  push @tests, shift;       }
        else             {  push @opts, shift, shift; }
    }
    my %opts = (verbose => $self->verbose, @opts);
    my $verbose = $opts{verbose};
    $self->number(1);    # reset test-number count
    my $successful = 0;  # reset success count
    print "1..", scalar @tests, "\n";
    for (@tests) {
        my $results = $self->run($_);
        print $verbose ? $results->details : $results->summary ."\n";
        $successful += $results->success ? 1 : 0;
    }
    return $successful;
}

=pod

=head1 HELPER OBJECTS

There are two kinds of objects that TestRunner uses as helpers.
Neither is meant to be created by you.  Rather, a TestRunner
will create them on your behalf when they are needed.

The objects are described in the following subsections.


=head2 Test::LectroTest::TestRunner::results

  my $results = $runner->run( $a_property );
  print "Property name: ", $results->name, ": ";
  print $results->success ? "Winner!" : "Loser!";

This is the object that you get back from C<run>.  It contains all of
the information available about the outcome of a property check
and provides the following methods:

=over 4

=item success

Boolean value:  True if the property checked out successfully;
false otherwise.

=item summary

Returns a one line summary of the property-check outcome.  It does not
end with a newline.  Example:

  ok 1 - Property->new disallows use of 'tcon' in bindings

=item details

Returns all relevant information about the property-check outcome as a
series of lines.  The last line is terminated with a newline.  The
details are identical to the summary (except for the terminating
newline) unless label frequencies are present or a counterexample is
present, in which case the details will have these extras (the
summary does not).  Example:

  1..1
  not ok 1 - 'my_sqrt meets defn of sqrt' falsified in 1 attempts
  # Counterexample:
  # $x = '0.546384454460178';

=item name

Returns the name of the property to which the results pertain.

=item number

The number assigned to the property that was checked.

=item counterexample

Returns the counterexample that "broke" the code being tested, if
there is one.  Otherwise, returns an empty string.  If any notes
have been attached to the failing trial, they will be included.

=item labels

Label counts.  If any labels were applied to trials during the
property check, this value will be a reference to a hash mapping each
combination of labels to the count of trials that had that particular
combination.  Otherwise, it will be undefined.

Note that each trial is counted only once -- for the I<most-specific>
combination of labels that was applied to it.  For example, consider
the following labeling logic:

  Property {
    ##[ x <- Int ]##
    $tcon->label("negative") if $x < 0;
    $tcon->label("odd")      if $x % 2;
    1;
  }, name => "negative/odd labeling example";

For a particular trial, if I<x> was 2 (positive and even), the trial
would receive no labels.  If I<x> was 3 (positive and odd), the trial
would be labeled "odd".  If I<x> was -2 (negative and even), the trial
would be labeled "negative".  If I<x> was -3 (negative and odd), the
trial would be labeled "negative & odd".

=item label_frequencies

Returns a string containing a line-by-line accounting of labels
applied during the series of trials:

  print $results->label_frequencies;

The corresponding output looks like this:

  25% negative
  25% negative & odd
  25% odd

If no labels were applied, an empty string is returned.

=item exception

Returns the text of the exception or error that caused the series of
trials to be aborted, if the trials were aborted because an exception
or error was intercepted by LectroTest.  Otherwise, returns an empty
string.

=item attempts

Returns the count of trials performed.

=item incomplete

In the event that the series of trials was halted before it was
completed (such as when the retry count was exhausted), this method will
return the reason.  Otherwise, it returns an empty string.

Note that a series of trials I<is> complete if a counterexample was
found.

=back

=cut

package Test::LectroTest::TestRunner::results;
{
  $Test::LectroTest::TestRunner::results::VERSION = '0.5001';
}
use Class::Struct;
import Data::Dumper;

struct( name            => '$',
        success         => '$',
        labels          => '$',
        counterexample_ => '$',
        notes_          => '$',
        exception       => '$',
        attempts        => '$',
        incomplete      => '$',
        number          => '$',
);

sub summary {
    my $self = shift;
    my ($name, $attempts) = ($self->name, $self->attempts);
    my $incomplete = $self->incomplete;
    my $number = $self->number;
    local $" = " / ";
    return $self->success
        ? "ok $number - '$name' ($attempts attempts)"
        : $incomplete
            ? "not ok $number - '$name' incomplete ($incomplete)"
            : "not ok $number - '$name' falsified in $attempts attempts";
}

sub details {
    my $self = shift;
    my $summary = $self->summary . "\n";
    my $details .= $self->label_frequencies;
    my $cx = $self->counterexample;
    if ( $cx ) {
        $details .= "Counterexample:\n$cx";
    }
    my $ex = $self->exception;
    if ( $ex ) {
        local $Data::Dumper::Terse = 1;
        $details .= "Caught exception: " . Dumper($ex);
    }
    $details =~ s/^/\# /mg if $details;  # mark as TAP comments
    return "$summary$details";
}

sub label_frequencies {
    my $self = shift;
    my $l = $self->labels;
    my $total = $self->attempts;
    my @keys = sort { $l->{$b} <=> $l->{$a} } keys %$l;
    join( "\n",
          (map {sprintf "% 3d%% %s", (200*$l->{$_}+1)/(2*$total), $_} @keys),
          ""
    );
}

sub counterexample {
    my $self = shift;
    my $vars = $self->counterexample_;
    return "" unless $vars;  # no counterexample
    my $sorted_keys = [ sort keys %$vars ];
    no warnings 'once';
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Useqq    = 1;
    return Data::Dumper->new([@$vars{@$sorted_keys}], $sorted_keys)->Dump .
           $self->notes;
}

sub notes {
    my $self = shift;
    my $notes = $self->notes_;
    return $notes ? join("\n", "Notes:", @$notes, "") : "";
}

=pod

=head2 Test::LectroTest::TestRunner::testcontroller

During a live property-check trial, the variable C<$tcon> is
available to your Properties.  It lets you label the current
trial or request that it be re-tried with new inputs.

The following methods are available.

=cut

package Test::LectroTest::TestRunner::testcontroller;
{
  $Test::LectroTest::TestRunner::testcontroller::VERSION = '0.5001';
}
import Class::Struct;

struct ( labels => '$', retried => '$', notes => '$' );

=pod

=over 4

=item retry

    Property {
      ##[ x <- Int ]##
      return $tcon->retry if $x == 0;
    }, ... ;


Stops the current trial and tells the TestRunner to re-try it
with new inputs.  Typically used to reject a particular case
of inputs that doesn't make for a good or valid test.  While
not required, you will probably want to call C<$tcon-E<gt>retry>
as part of a C<return> statement to prevent further execution
of your property's logic, the results of which will be thrown
out should it run to completion.

The return value of C<$tcon-E<gt>retry> is itself meaningless; it is
the side-effect of calling it that causes the current trial to be
thrown out and re-tried.

=cut

sub retry {
    shift->retried(1);
}


=pod

=item label(I<string>)

    Property {
      ##[ x <- Int ]##
      $tcon->label("negative") if $x < 0;
      $tcon->label("odd")      if $x % 2;
    }, ... ;

Applies a label to the current trial.  At the end of the trial, all of
the labels are gathered together, and the trial is dropped into a
bucket bearing the combined label.  See the discussion of
L</labels> for more.

=cut


sub label {
    my $self = shift;
    my $labels = $self->labels;
    push @$labels, @_;
    $self->labels( $labels );
}

=pod

=item trivial

    Property {
      ##[ x <- Int ]##
      $tcon->trivial if $x == 0;
    }, ... ;

Applies the label "trivial" to the current trial.  It is identical to
calling C<label> with "trivial" as the argument.

=cut

sub trivial {
    shift->label("trivial");
}


=pod

=item note(I<string>...)

    Property {
      ##[ s <- String( charset=>"A-Za-z0-9" ) ]##
      my $s_enc     = encode($s);
      my $s_enc_dec = decode($s_enc);
      $tcon->note("s_enc     = $s_enc",
                  "s_enc_dec = $s_enc_dec");
      $s eq $s_enc_dec;
    }, name => "decode is encode's inverse" ;

Adds a note (or notes) to the current trial.  In the event that the
trial fails, these notes will be emitted as part of the
counterexample.  For example:

    1..1
    not ok 1 - property 'decode is encode's inverse' \
        falsified in 68 attempts
    #     Counterexample:
    #     $s = "0";
    #     Notes:
    #     $s_enc     = "";
    #     $s_enc_dec = "";

Notes can help you debug your code when something goes wrong.  Use
them as debugging hints to yourself.  For example, you can use notes
to record the output of each stage of a multi-stage test.  That way,
if the test fails, you can see what happened in each stage without
having to plug the counterexample into your code under a debugger.

If you want to include complicated values or data structures in your
notes, see the C<dump> method, next, which may be more appropriate.


=cut

sub note {
    my $self = shift;
    my $notes = $self->notes;
    push @$notes, @_;
    $self->notes( $notes );
}

=pod

=item dump(I<value>, I<name>)

    Property {
      ##[ s <- String ]##
      my $s_enc     = encode($s);
      my $s_enc_dec = decode($s_enc);
      $tcon->dump($s_enc, "s_enc");
      $tcon->dump($s_enc_dec, "s_enc_dec");
      $s eq $s_enc_dec;
    }, name => "decode is encode's inverse" ;

Adds a note to the current trial in which the given I<value> is
dumped.  The value will be dumped via L<Data::Dumper> and thus may
be complex and contain weird control characters and so on.  If you
supply a I<name>, it will be used to name the dumped value.  Returns
I<value> as its result.

In the event that the trial fails, the note (and any others) will be
emitted as part of the counterexample.


See C<note> above for more.

=cut

sub dump {
    my $self = shift;
    my ($val, $name) = @_;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Useqq    = 1;
    local $Data::Dumper::Indent   = 0;
    my @names = $name ? ([$name]) : ();
    $self->note( Data::Dumper->new( [$val], @names )->Dump );
    return $val;
}


=pod

=back

=cut



package Test::LectroTest::TestRunner;

1;


=head1 SEE ALSO

L<Test::LectroTest::Property> explains in detail what
you can put inside of your property specifications.

L<Test::LectroTest::RegressionTesting> explains how to test for
regressions and corner cases using LectroTest.

L<Test::Harness:TAP> documents the Test Anything Protocol,
Perl's simple text-based interface between testing modules such
as L<Test::LectroTest> and the test harness L<Test::Harness>.


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
