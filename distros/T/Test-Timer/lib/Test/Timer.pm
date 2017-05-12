package Test::Timer;

use warnings;
use strict;

use vars qw($VERSION @ISA @EXPORT);
use Benchmark;
use Carp qw(croak);
use Error qw(:try);
use Test::Builder;
use base 'Test::Builder::Module';

#own
use Test::Timer::TimeoutException;

@EXPORT = qw(time_ok time_nok time_atleast time_atmost time_between);

$VERSION = '0.18';

my $test  = Test::Builder->new;
our $alarm = 2; #default alarm

sub time_ok {
    return time_atmost(@_);
}

sub time_nok {
    my ( $code, $upperthreshold, $name ) = @_;

    my $ok = _runtest( $code, 0, $upperthreshold, $name );

    if ($ok == 1) {
        $ok = 0;
        $test->ok( $ok, $name );
        $test->diag( 'Test did not exceed specified threshold' );
    } else {
        $ok = 1;
        $test->ok( $ok, $name );
    }

    return $ok;
}

sub time_atmost {
    my ( $code, $upperthreshold, $name ) = @_;

    my $ok = _runtest( $code, 0, $upperthreshold, $name );

    if ($ok == 1) {
        $test->ok( $ok, $name );
    } else {
        $test->ok( $ok, $name );
        $test->diag( 'Test exceeded specified threshold' );
    }

    return $ok;
}

sub time_atleast {
    my ( $code, $lowerthreshold, $name ) = @_;

    my $ok = _runtest_atleast( $code, $lowerthreshold, undef, $name );

    if ($ok == 0) {
        $test->ok( $ok, $name );
        $test->diag( 'Test did not exceed specified threshold' );
    } else {
        $test->ok( $ok, $name );
    }

    return $ok;
}

sub time_between {
    my ( $code, $lowerthreshold, $upperthreshold, $name ) = @_;

    my $ok = _runtest( $code, $lowerthreshold, $upperthreshold, $name );

    if ($ok == 1) {
        $test->ok( $ok, $name );
    } else {
        $ok = 0;
        $test->ok( $ok, $name );
        $test->diag( 'Test did not execute within specified interval' );
    }

    return $ok;
}

sub _runtest {
    my ( $code, $lowerthreshold, $upperthreshold, $name ) = @_;

    my $within = 0;

    try {

        my $timestring = _benchmark( $code, $upperthreshold );
        my $time = _timestring2time($timestring);

        if ( defined $lowerthreshold && defined $upperthreshold ) {

            if ( $time >= $lowerthreshold && $time <= $upperthreshold ) {
                $within = 1;
            } else {
                $within = 0;
            }

        } else {
            croak 'Insufficient number of parameters';
        }
    }
    catch Test::Timer::TimeoutException with {
        my $E = shift;

        $test->ok( 0, $name );
        $test->diag( $E->{-text} );
    }
    otherwise {
        my $E = shift;
        croak( $E->{-text} );
    };

    return $within;
}

sub _runtest_atleast {
    my ( $code, $lowerthreshold, $upperthreshold, $name ) = @_;

    my $exceed = 0;

    try {

        if ( defined $lowerthreshold ) {

            my $timestring = _benchmark( $code, $lowerthreshold );
            my $time = _timestring2time($timestring);

            if ( $time > $lowerthreshold ) {
                $exceed = 1;
            } else {
                $exceed = 0;
            }

        } else {
            croak 'Insufficient number of parameters';
        }
    }
    catch Test::Timer::TimeoutException with {
        my $E = shift;

        $test->ok( 0, $name );
        $test->diag( $E->{-text} );
    }
    otherwise {
        my $E = shift;
        croak( $E->{-text} );
    };

    return $exceed;
}

sub _benchmark {
    my ( $code, $threshold ) = @_;

    my $timestring;
    my $alarm = $alarm + ($threshold || 0);

    try {
        local $SIG{ALRM} = sub {
            throw Test::Timer::TimeoutException(
                'Execution exceeded threshold and timed out');
        };

        alarm( $alarm );

        my $t0 = new Benchmark;
        &{$code};
        my $t1 = new Benchmark;

        $timestring = timestr( timediff( $t1, $t0 ) );
    }
    otherwise {
        my $E = shift;
        croak( $E->{-text} );
    };

    return $timestring;
}

sub _timestring2time {
    my $timestring = shift;

    my ($time) = $timestring =~ m/(\d+) /;

    return $time;
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Test-Timer.svg)](http://badge.fury.io/pl/Test-Timer)
[![Build Status](https://travis-ci.org/jonasbn/testt.svg?branch=master)](https://travis-ci.org/jonasbn/testt)
[![Coverage Status](https://coveralls.io/repos/jonasbn/testt/badge.png)](https://coveralls.io/r/jonasbn/testt)

=end markdown

=head1 NAME

Test::Timer - test module to test/assert response times

=head1 VERSION

The documentation in this module describes version 0.18 of Test::Timer

=head1 SYNOPSIS

    use Test::Timer;

    time_ok( sub { doYourStuffButBeQuickAboutIt(); }, 1, 'threshold of one second');

    time_atmost( sub { doYourStuffYouHave10Seconds(); }, 10, 'threshold of 10 seconds');

    time_between( sub { doYourStuffYouHave5-10Seconds(); }, 5, 10,
        'lower threshold of 5 seconds and upper threshold of 10 seconds');

    #Will succeed
    time_nok( sub { sleep(2); }, 1, 'threshold of one second');

    time_atleast( sub { sleep(2); }, 2, 'threshold of one second');

    #Will fail after 5 (threshold) + 2 seconds (default alarm)
    time_ok( sub { while(1) { sleep(1); } }, 5, 'threshold of one second');

    $test::Timer::alarm = 6 #default 2 seconds

    #Will fail after 5 (threshold) + 6 seconds (specified alarm)
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

    time_ok( sub { doYourStuffButBeQuickAboutIt(); }, 1, 'threshold of one second');

If the execution of the code exceeds the threshold the test fails

=head2 time_nok

The is the inverted variant of L<time_ok|/time_ok>, it passes if the threshold is
exceeded and fails if the benchmark of the code is within the specified
timing threshold.

The API is the same as for L<time_ok|/time_ok>.

    time_nok( sub { sleep(2); }, 1, 'threshold of one second');

=head2 time_atmost

This is I<syntactic sugar> for L<time_ok|/time_ok>

    time_atmost( sub { doYourStuffButBeQuickAboutIt(); }, 1, 'threshold of one second');

=head2 time_atleast

    time_atleast( sub { sleep(2); }, 1, 'threshold of one second');

The test succeeds if the code takes at least the number of seconds specified by
the timing threshold.

Please be aware that Test::Timer, breaks the execution with an alarm specified
to trigger after the specified threshold + 2 seconds, so if you expect your
execution to run longer, set the alarm accordingly.

    $Test::Timer::alarm = $my_alarm_in_seconds;

See also L<diagnostics|/DIAGNOSTICS>.

=head2 time_between

This method is a more extensive variant of L<time_atmost|/time_atmost> and L<time_ok|/time_ok>, you
can specify a lower and upper threshold, the code has to execute within this
interval in order for the test to succeed

    time_between( sub { sleep(2); }, 5, 10,
        'lower threshold of 5 seconds and upper threshold of 10 seconds');

=head1 PRIVATE FUNCTIONS

=head2 _runtest

This is a method to handle the result from L<_benchmark|/_benchmark> is initiates the
benchmark calling benchmark and based on whether it is within the provided
interval true (1) is returned and if not false (0).

=head2 _runtest_atleast

This is a simpler variant of the method above, it is the author's hope that is
can be refactored out at some point, due to the similarity with L<_runtest|/_runtest>.

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
but can be set by the user or is equal to the uppertreshold + 2 seconds.

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

As listed on the TODO, the current implementations only use seconds and
resolutions should be higher, so the current implementation is limited to
seconds as the highest resolution.

=head1 TEST AND QUALITY

Coverage report for the release described in this documentation (see L<VERSION|/VERSION>).

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/Test/Timer.pm         91.7   93.8   66.7   88.5  100.0   99.9   90.7
    ...Timer/TimeoutException.pm  100.0    n/a    n/a  100.0  100.0    0.1  100.0
    Total                          93.1   93.8   66.7   90.6  100.0  100.0   92.1
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

The L<Test::Perl::Critic> test runs with severity 5 (gentle) for now, please
refer to F<t/critic.t> and F<t/perlcriticrc>.

Set TEST_POD to enable L<Test::Pod> test in F<t/pod.t> and L<Test::Pod::Coverage>
test in F<t/pod-coverage.t>.

Set TEST_CRITIC to enable L<Test::Perl::Critic> test in F<t/critic.t>

=head2 CONTINUOUS INTEGRATION

This distribution uses Travis for continuous integration testing, the
Travis reports are public available.

=for HTML <a href="https://travis-ci.org/jonasbn/testt"><img src="https://travis-ci.org/jonasbn/testt.png?branch=master"></a>

=for markdown [![Build Status](https://travis-ci.org/jonasbn/testt.png?branch=master)](https://travis-ci.org/jonasbn/testt)

=head1 TODO

=over

=item * Implement higher resolution for thresholds

=item * Factor out L<_runtest_atleast|/_runtest_atleast>

=item * Add more tests to get a better feeling for the use and border cases
requiring alarm etc.

=item * Rewrite POD to emphasize L<time_atleast|/time_atleast> over L<time_ok|/time_ok>

=back

=head1 SEE ALSO

=over

=item * L<Test::Benchmark>

=back

=head1 BUGS

Please report any bugs or feature requests either using rt.cpan.org or Github

I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=over

=item * Github: L<https://github.com/jonasbn/testt/issues>

=back

=head1 SUPPORT

You can find (this) documentation for this module with the C<perldoc> command.

    perldoc Test::Timer

You can also look for information at:

=over

=item * L<AnnoCPAN: Annotated CPAN documentation|http://annocpan.org/dist/Test-Timer>

=item * L<CPAN Ratings|http://cpanratings.perl.org/d/Test-Timer>

=item * L<MetaCPAN|https://metacpan.org/pod/Test-Timer>

=back

=head1 DEVELOPMENT

=over

=item * L<Github Repository|https://github.com/jonasbn/testt>

=back

=head1 AUTHOR

=over

=item * Jonas B. Nielsen (jonasbn) C<< <jonasbn at cpan.org> >>

=back

=head1 ACKNOWLEDGEMENTS

=over

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
(jonasbn) 2007-2016

Test::Timer and related modules are released under the Artistic
License 2.0

=cut
