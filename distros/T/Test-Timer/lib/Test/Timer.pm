package Test::Timer;

use warnings;
use strict;

use vars qw($VERSION @ISA @EXPORT);
use Benchmark; # timestr
use Carp qw(croak);
use Error qw(:try);
use Test::Builder;
use base 'Test::Builder::Module';

use constant TRUE => 1;
use constant FALSE => 0;

#own
use Test::Timer::TimeoutException;

@EXPORT = qw(time_ok time_nok time_atleast time_atmost time_between);

$VERSION = '2.09';

my $test  = Test::Builder->new;
my $timeout = 0;

our $alarm = 2; #default alarm

# syntactic sugar for time_atmost
sub time_ok {
    return time_atmost(@_);
}

# inverse test of time_ok
sub time_nok {
    my ( $code, $upperthreshold, $name ) = @_;

    # timing from zero to upper threshold
    my ($within, $time) = _runtest( $code, 0, $upperthreshold );

    # are we within the specified threshold
    if ($within == TRUE) {

        # we inverse the result, since we are the inverse of time_ok
        $within = FALSE;
        $test->ok( $within, $name ); # no, we fail
        $test->diag( "Test ran $time seconds and did not exceed specified threshold of $upperthreshold seconds" );
    } else {

        # we inverse the result, since we are the inverse of time_ok
        $within = TRUE;
        $test->ok( $within, $name ); # yes, we do not fail
    }

    return $within;
}

# test to make sure we are below a specified threshold
sub time_atmost {
    my ( $code, $upperthreshold, $name ) = @_;

    # timing from zero to upper threshold
    my ($within, $time) = _runtest( $code, 0, $upperthreshold );

    # are we within the specified threshold
    if ($within == TRUE) {
        $test->ok( $within, $name ); # yes, we do not fail
    } else {
        $test->ok( $within, $name ); # no, we fail
        $test->diag( "Test ran $time seconds and exceeded specified threshold of $upperthreshold seconds" );
    }

    return $within;
}

# test to make sure we are above a specified threshold
sub time_atleast {
    my ( $code, $lowerthreshold, $name ) = @_;

    # timing from lowerthreshold to nothing
    my ($above, $time) = _runtest( $code, $lowerthreshold, undef );

    # are we above the specified threshold
    if ($above == TRUE) {
        $test->ok( $above, $name ); # yes, we do not fail

    } else {
        $test->ok( $above, $name ); # no, we fail
        $test->diag( "Test ran $time seconds and did not exceed specified threshold of $lowerthreshold seconds" );
    }

    return $above;
}

# test to make sure we are witin a specified threshold time frame
sub time_between {
    my ( $code, $lowerthreshold, $upperthreshold, $name ) = @_;

    # timing from lower to upper threshold
    my ($within, $time) = _runtest( $code, $lowerthreshold, $upperthreshold );

    # are we within the specified threshold
    if ($within == TRUE) {
        $test->ok( $within, $name ); # yes, we do not fail
    } else {
        $test->ok( $within, $name ); # no, we fail
        if ($timeout) {
            $test->diag( "Execution ran $timeout seconds and did not execute within specified interval $lowerthreshold - $upperthreshold seconds and timed out");
        } else {
            $test->diag( "Test ran $time seconds and did not execute within specified interval $lowerthreshold - $upperthreshold seconds" );
        }
    }

    return $within;
}

# helper routine to make initiate timing and make initial interpretation of results
# test mehtods do the final interpretation
sub _runtest {
    my ( $code, $lowerthreshold, $upperthreshold ) = @_;

    my $ok = FALSE;
    my $time = 0;

    try {

        # we have both a lower and upper threshold (time_between, time_most, time_ok)
        if ( defined $lowerthreshold and defined $upperthreshold ) {

            $time = _benchmark( $code, $upperthreshold );

            if ( $time >= $lowerthreshold and $time <= $upperthreshold ) {
                $ok = TRUE;
            } else {
                $ok = FALSE;
            }

        # we just have a lower threshold (time_atleast)
        } elsif ( defined $lowerthreshold ) {

            $time = _benchmark( $code );

            if ( $time >= $lowerthreshold ) {
                $ok = TRUE;
            } else {
                $ok = FALSE;
            }
        }
    }
    # catching a timeout so we do not run forever
    catch Test::Timer::TimeoutException with {
        my $E = shift;

        $timeout = $E->{-text};

        return (undef, $time); # we return undef as result
    };

    return ($ok, $time);
}

# actual timing using benchmark
sub _benchmark {
    my ( $code, $threshold ) = @_;

    my $time = 0;

    # We default to no alarm
    my $local_alarm = 0;

    # We only define an alarm if we have an upper threshold
    # alarm is based on upper threshold + default alarm
    # default alarm can be extended, see the docs
    if (defined $threshold) {
        $local_alarm = $threshold + $alarm;
    }

    # setting first benchmark
    my $t0 = new Benchmark;

    # defining alarm signal handler
    # the handler takes care of terminating the
    # benchmarking
    local $SIG{ALRM} = sub {

        my $t1 = new Benchmark;

        my $timestring = timestr( timediff( $t1, $t0 ) );
        my $time = _timestring2time($timestring);

        throw Test::Timer::TimeoutException($time);
    };

    # setting alarm
    alarm( $local_alarm );

    # running code
    &{$code};

    # clear alarm
    alarm( 0 );

    # setting second benchmark
    my $t1 = new Benchmark;

    # parsing benchmark output
    my $timestring = timestr( timediff( $t1, $t0 ) );
    $time = _timestring2time($timestring);

    return $time;
}

# helper method to change benchmmark's timestr to an integer
sub _timestring2time {
    my $timestring = shift;

    # $timestring:
    # 2 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)
    my ($time) = $timestring =~ m/(\d+) /;

    return $time;
}

1;

__END__

=pod

=begin markdown

# Test::Timer

[![CPAN version](https://badge.fury.io/pl/Test-Timer.svg)](http://badge.fury.io/pl/Test-Timer)
![stability-stable](https://img.shields.io/badge/stability-stable-green.svg)
[![Build Status](https://travis-ci.org/jonasbn/perl-test-timer.svg?branch=master)](https://travis-ci.org/jonasbn/perl-test-timer)
[![Coverage Status](https://coveralls.io/repos/github/jonasbn/perl-test-timer/badge.svg?branch=master)](https://coveralls.io/github/jonasbn/perl-test-timer?branch=master)
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

<!-- MarkdownTOC autoanchor=false -->


<!-- /MarkdownTOC -->

=end markdown

=head1 NAME

Test::Timer - test module to test/assert response times

=head1 VERSION

The documentation describes version 2.09 of Test::Timer

=head1 FEATURES

=over

=item * Test subroutines to implement unit-tests to time that your code executes before a specified threshold

=item * Test subroutines to implement unit-tests to time that your code execution exceeds a specified threshold

=item * Test subroutine to implement unit-tests to time that your code executes within a specified time frame

=item * Supports measurements in seconds

=item * Implements configurable alarm signal handler to make sure that your tests do not execute forever

=back

=head1 SYNOPSIS

    use Test::Timer;

    time_ok( sub { doYourStuffButBeQuickAboutIt(); }, 1, 'threshold of one second');

    time_atmost( sub { doYourStuffYouHave10Seconds(); }, 10, 'threshold of 10 seconds');

    time_between( sub { doYourStuffYouHave5-10Seconds(); }, 5, 10,
        'lower threshold of 5 seconds and upper threshold of 10 seconds');

    # Will succeed
    time_nok( sub { sleep(2); }, 1, 'threshold of one second');

    time_atleast( sub { sleep(2); }, 2, 'threshold of one second');

    # Will fail after 5 (threshold) + 2 seconds (default alarm)
    time_ok( sub { while(1) { sleep(1); } }, 5, 'threshold of one second');

    $test::Timer::alarm = 6 #default 2 seconds

    # Will fail after 5 (threshold) + 6 seconds (specified alarm)
    time_ok( sub { while(1) { sleep(1); } }, 5, 'threshold of one second');

=head1 DESCRIPTION

Test::Timer implements a set of test primitives to test and assert test times
from bodies of code.

The key features are subroutines to assert or test the following:

=over

=item * that a given piece of code does not exceed a specified time limit

=item * that a given piece of code takes longer than a specified time limit
and does not exceed another

=back

=head1 EXPORT

Test::Timer exports:

=over

=item * L<time_ok|/time_ok>

=item * L<time_nok|/time_nok>

=item * L<time_atleast|/time_atleast>

=item * L<time_atmost|/time_atmost>

=item * L<time_between|/time_between>

=back

=head1 SUBROUTINES/METHODS

=head2 time_ok

Takes the following parameters:

=over

=item * a reference to a block of code (anonymous sub)

=item * a threshold specified as a integer indicating a number of seconds

=item * a string specifying a test name

=back

    time_nok( sub { sleep(2); }, 1, 'threshold of one second');

If the execution of the code exceeds the threshold specified the test fail with the following diagnostic message

    Test ran 2 seconds and exceeded specified threshold of 1 seconds

=head2 time_nok

The is the inverted variant of L<time_ok|/time_ok>, it passes if the threshold is
exceeded and fails if the benchmark of the code is within the specified
timing threshold.

The API is the same as for L<time_ok|/time_ok>.

    time_nok( sub { sleep(1); }, 2, 'threshold of two seconds');

If the execution of the code executes below the threshold specified the test fail with the following diagnostic message

    Test ran 1 seconds and did not exceed specified threshold of 2 seconds

=head2 time_atmost

This is I<syntactic sugar> for L<time_ok|/time_ok>

    time_atmost( sub { doYourStuffButBeQuickAboutIt(); }, 1, 'threshold of one second');

If the execution of the code exceeds the threshold specified the test fail with the following diagnostic message

    Test ran N seconds and exceeded specified threshold of 1 seconds

N will be the actual measured execution time of the specified code

=for HTML <img src='https://jonasbn.github.io/perl-test-timer/assets/images/time_atmost.png' alt='time_atmost visualisation' /></a>

=for markdown ![time_atmost visualisation](https://jonasbn.github.io/perl-test-timer/assets/images/time_atmost.png)

=begin text

Graphical visualisation of the above example.

    +------------------+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    | Time in seconds: | 0| 1| 2| 3| 4| 5| 6| 7| 8| 9|10|11|12|13|14|
    +------------------+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    | Test outcome:    | S| S| F| F| F| F| F| F| F| F| F| F| F| F| F|
    +------------------+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

    F = failure
    S = Success

=end text

=head2 time_atleast

    time_atleast( sub { doYourStuffAndTakeYourTimeAboutIt(); }, 1, 'threshold of 1 second');

The test succeeds if the code takes at least the number of seconds specified by
the timing threshold.

If the code executes faster, the test fails with the following diagnosic message

    Test ran 1 seconds and did not exceed specified threshold of 2 seconds

Please be aware that Test::Timer, breaks the execution with an alarm specified
to trigger after the specified threshold + 2 seconds (default), so if you expect your
execution to run longer, set the alarm accordingly.

    $Test::Timer::alarm = $my_alarm_in_seconds;

See also L<diagnostics|/DIAGNOSTICS>.

=for HTML <img src='https://jonasbn.github.io/perl-test-timer/assets/images/time_atleast.png' alt='time_atleast visualisation' /></a>

=for markdown ![time_atleast visualisation](https://jonasbn.github.io/perl-test-timer/assets/images/time_atleast.png)

=begin text

Graphical visualisation of the above example.

    +------------------+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    | Time in seconds: | 0| 1| 2| 3| 4| 5| 6| 7| 8| 9|10|11|12|13|14|
    +------------------+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    | Test outcome:    | F| F| S| S| S| S| S| S| S| S| S| S| S| S| S|
    +------------------+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

    F = failure
    S = Success

=end text

=head2 time_between

This method is a more extensive variant of L<time_atmost|/time_atmost> and L<time_ok|/time_ok>, you
can specify a lower and upper threshold, the code has to execute within this
interval in order for the test to succeed

    time_between( sub { sleep(2); }, 5, 10,
        'lower threshold of 5 seconds and upper threshold of 10 seconds');

If the code executes faster than the lower threshold or exceeds the upper threshold, the test fails with the following diagnosic message

    Test ran 2 seconds and did not execute within specified interval 5 - 10 seconds

Or

    Test ran 12 seconds and did not execute within specified interval 5 - 10 seconds

=for HTML <img src='https://jonasbn.github.io/perl-test-timer/assets/images/time_between.png' alt='time_between visualisation' /></a>

=for markdown ![time_between visualisation](https://jonasbn.github.io/perl-test-timer/assets/images/time_between.png)

=begin text

Graphical visualisation of the above example.

    +------------------+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    | Time in seconds: | 0| 1| 2| 3| 4| 5| 6| 7| 8| 9|10|11|12|13|14|
    +------------------+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    | Test outcome:    | F| F| F| F| F| S| S| S| S| S| S| F| F| F| F|
    +------------------+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

    F = failure
    S = Success

=end text

=head1 PRIVATE FUNCTIONS

=head2 _runtest

This is a method to handle the result from L<_benchmark|/_benchmark> is initiates the
benchmark calling benchmark and based on whether it is within the provided
interval true (1) is returned and if not false (0).

=head2 _benchmark

This is the method doing the actual benchmark, if a better method is located
this is the place to do the handy work.

Currently L<Benchmark> is used. An alternative could be L<Devel::Timer>, but I
do not know this module very well and L<Benchmark> is core, so this is used for
now.

The method takes two parameters:

=over

=item * a code block via a code reference

=item * a threshold (the upper threshold, since this is added to the default
alarm.

=back

=head2 _timestring2time

This is the method extracts the seconds from benchmarks timestring and returns
it as an integer.

It takes the timestring from L<_benchmark|/_benchmark> (L<Benchmark>) and returns the seconds
part.

=head2 import

Test::Builder required import to do some import I<hokus-pokus> for the test methods
exported from Test::Timer. Please refer to the documentation in L<Test::Builder>

=head1 DIAGNOSTICS

All tests either fail or succeed, but a few exceptions are implemented, these
are listed below.

=over

=item * Test did not exceed specified threshold, this message is diagnosis for
L<time_atleast|/time_atleast> and L<time_nok|/time_nok> tests, which do not exceed their specified
threshold.

=item * Test exceeded specified threshold, this message is a diagnostic for
L<time_atmost|/time_atmost> and L<time_ok|/time_ok>, if the specified threshold is surpassed.

This is the key point of the module, either your code is too slow and you should
address this or your threshold is too low, in which case you can set it a bit
higher and run the test again.

=item * Test did not execute within specified interval, this is the diagnostic
from L<time_between|/time_between>, it is the diagnosis if the execution of the code is
not between the specified lower and upper thresholds.

=item * Insufficient parameters, this is the message if a specified test is not
provided with the sufficient number of parameters, consult this documentation
and correct accordingly.

=item * Execution exceeded threshold and timed out, the exception is thrown if
the execution of tested code exceeds even the alarm, which is default 2 seconds,
but can be set by the user or is equal to the upperthreshold + 2 seconds.

The exception results in a diagnostic for the failing test. This is a failsafe
to avoid that code runs forever. If you get this diagnose either your code is
too slow and you should address this or it might be error prone. If this is not
the case adjust the alarm setting to suit your situation.

=back

=head1 CONFIGURATION AND ENVIRONMENT

This module requires no special configuration or environment.

Tests are sensitive and be configured using environment and configuration files, please
see the section on L<test and quality|/TEST AND QUALITY>.

=head1 DEPENDENCIES

=over

=item * L<Carp>

=item * L<Benchmark>

=item * L<Error>

=item * L<Test::Builder>

=item * L<Test::Builder::Module>

=back

=head1 INCOMPATIBILITIES

This module holds no known incompatibilities.

=head1 BUGS AND LIMITATIONS

This module holds no known bugs.

The current implementations only use seconds and resolutions should be higher,
so the current implementation is limited to seconds as the highest resolution.

On occassion failing tests with CPAN-testers have been observed. This seem to be related to the test-suite
being not taking into account that some smoke-testers do not prioritize resources for the test run and that
additional processes/jobs are running. The test-suite have been adjusted to accommodate this but these issues
might reoccur.

=head1 TEST AND QUALITY

=for HTML <a href='https://coveralls.io/github/jonasbn/perl-test-timer'><img src='https://coveralls.io/repos/github/jonasbn/perl-test-timer/badge.svg' alt='Coverage Status' /></a>

=for markdown [![Coverage Status](https://coveralls.io/repos/github/jonasbn/perl-test-timer/badge.svg?branch=master)](https://coveralls.io/github/jonasbn/perl-test-timer?branch=master)

Coverage report for the release described in this documentation (see L<VERSION|/VERSION>).

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/Test/Timer.pm        100.0   95.0   66.6  100.0  100.0   99.9   98.0
    ...Timer/TimeoutException.pm  100.0    n/a    n/a  100.0  100.0    0.0  100.0
    Total                         100.0   95.0   66.6  100.0  100.0  100.0   98.4
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

The L<Test::Perl::Critic> test runs with severity 5 (gentle) for now, please
refer to F<t/critic.t> and F<t/perlcriticrc>.

Set TEST_POD to enable L<Test::Pod> test in F<t/pod.t> and L<Test::Pod::Coverage>
test in F<t/pod-coverage.t>.

Set TEST_CRITIC to enable L<Test::Perl::Critic> test in F<t/critic.t>

=head2 CONTINUOUS INTEGRATION

This distribution uses Travis for continuous integration testing, the
Travis reports are public available.

=for HTML <a href="https://travis-ci.org/jonasbn/perl-test-timer"><img src="https://travis-ci.org/jonasbn/perl-test-timer.png?branch=master"></a>

=for markdown [![Build Status](https://travis-ci.org/jonasbn/perl-test-timer.svg?branch=master)](https://travis-ci.org/jonasbn/perl-test-timer)

=head1 SEE ALSO

=over

=item * L<Test::Benchmark>

=back

=head1 ISSUE REPORTING

Please report any bugs or feature requests using Github

=over

=item * L<Github Issues|https://github.com/jonasbn/perl-test-timer/issues>

=back

=head1 SUPPORT

You can find (this) documentation for this module with the C<perldoc> command.

    perldoc Test::Timer

You can also look for information at:

=over

=item * L<Homepage|https://jonasbn.github.io/perl-test-timer/>

=item * L<MetaCPAN|https://metacpan.org/pod/Test-Timer>

=item * L<AnnoCPAN: Annotated CPAN documentation|http://annocpan.org/dist/Test-Timer>

=item * L<CPAN Ratings|http://cpanratings.perl.org/d/Test-Timer>

=back

=head1 DEVELOPMENT

=over

=item * L<Github Repository|https://github.com/jonasbn/perl-test-timer>, please see L<the guidelines for contributing|https://github.com/jonasbn/perl-test-timer/blob/master/CONTRIBUTING.md>.

=back

=head1 AUTHOR

=over

=item * Jonas B. Nielsen (jonasbn) C<< <jonasbn at cpan.org> >>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item * Erik Johansen, suggestion for clearing alarm

=item * Gregor Herrmann, PR #16 fixes to spelling mistakes

=item * Nigel Horne, issue #15 suggestion for better assertion in L<time_atleast|/time_atleast>

=item * Nigel Horne, issue #10/#12 suggestion for improvement to diagnostics

=item * p-alik, PR #4 eliminating warnings during test

=item * Kent Fredric, PR #7 addressing file permissions

=item * Nick Morrott, PR #5 corrections to POD

=item * Bartosz Jakubski, reporting issue #3

=item * Gabor Szabo (GZABO), suggestion for specification of interval thresholds
even though this was obsoleted by the later introduced time_between

=item * Paul Leonerd Evans (PEVANS), suggestions for time_atleast and time_atmost
and the handling of $SIG{ALRM}. Also bug report for addressing issue with Debian
packaging resulting in release 0.10

=item * brian d foy (BDFOY), for patch to L<_run_test|/_run_test>

=back

=head1 LICENSE AND COPYRIGHT

Test::Timer and related modules are (C) by Jonas B. Nielsen,
(jonasbn) 2007-2017

Test::Timer and related modules are released under the Artistic
License 2.0

Used distributions are under copyright of there respective authors and designated licenses

Image used on L<website|https://jonasbn.github.io/perl-test-timer/> is under copyright by L<Veri Ivanova|https://unsplash.com/@veri_ivanova?photo=p3Pj7jOYvnM>

=cut
