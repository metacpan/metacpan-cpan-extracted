#!/usr/bin/env perl
# Test that we can record milestones, including the magic START milestone.

package TestsFor::Timer::Milestones::Milestones;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Scalar::Util;
use Test::Fatal;
# Prototype disagreement between Test::More and Test2::Tools::Compare, so
# explicitly use the Test2::Tools::Compare versions.
use Test::More import => [qw(!is !like)];
use Test2::Tools::Compare qw(is like array item end);

use Timer::Milestones qw(:all);

# We're not testing reports here, so silence them.
no warnings 'redefine';
local *Timer::Milestones::_default_notify_report = sub { return sub {} };
use warnings 'redefine';

local $Data::Dumper::Indent   = 1;
local $Data::Dumper::Terse    = 1;
local $Data::Dumper::Sortkeys = 1;

my $re_timestamp = qr/^ [0-9]+ ( [.] \d+ )? $/x;

test_simple_start_stop();
test_add_milestones();
test_default_milestone_name();
test_ending_timing_thwarts_add_milestone();
test_exported_functions();

done_testing();

# Calling start_timing and stop_timing creates and updates the START milestone
# respectively.

sub test_simple_start_stop {
    # Create a new Timer object. It starts off with a milestone called START
    # and a time.
    my $timer = Timer::Milestones->new;
    is(ref($timer), 'Timer::Milestones', 'We have a valid-looking object');
    my %expected_guts
        = (milestones => [{ name => 'START', started => $re_timestamp }]);
    like($timer, \%expected_guts,
        'Our object contains a milestone called START, with a start time')
        or diag(Dumper($timer));

    # Because the constructor called start_timing for us, calling it again
    # has no effect.
    my @milestones = @{ $timer->{milestones} };
    ok($timer->start_timing, 'We can call start_timing again...');
    is($timer->{milestones}, \@milestones, '...but that has no obvious effect')
        or diag(Dumper($timer->{milestones}));

    # Ending timing updates that milestone.
    $timer->stop_timing;
    like(
        $timer,
        {
            milestones => array {
                item {
                    name    => 'START',
                    started => $re_timestamp,
                    ended   => $re_timestamp
                };
                end();
            },
            timing_stopped => $re_timestamp
        },
        'Stop_timing updates the START timestamp, and marks timing as stopped'
    ) or diag(Dumper($timer));
}

# Calling add_milestone inserts new milestones. We use timestamps from our
# test mocker.
### TODO: what if the milestone name matches the current one? The previous one?
### A milestone we've seen before?

sub test_add_milestones {
    # Set up trivial time mocking; make sure that the numbers are arbitrary
    # so we're not just returning an incremented count or something.
    my @times = qw(123 405 789 880);
    my $get_time
        = sub { my $time = shift @times or croak 'Ran out of times!'; $time };
    my $timer = Timer::Milestones->new(get_time => $get_time);
    $timer->add_milestone('Part-way through');
    $timer->add_milestone('Almost there');
    $timer->stop_timing;
    like(
        $timer,
        {
            milestones => array {
                item {
                    name    => 'START',
                    started => 123,
                    ended   => 405
                };
                item {
                    name    => 'Part-way through',
                    started => 405,
                    ended   => 789
                };
                item {
                    name    => 'Almost there',
                    started => 789,
                    ended   => 880,
                };
                end();
            },
            timing_stopped => 880,
        },
        'Adding a milestone updates the previous one; end updates the last one',
    ) or diag(Dumper($timer));
    is(scalar @times, 0, 'We used all our mock times');

    # If we call stop_timing again, this does nothing. To be absolutely sure,
    # fiddle in the guts of our object.
    $timer->{milestones}[-1]{ended} = 1234;
    $timer->{timing_stopped} = 1314;
    $timer->stop_timing;
    is($timer->{milestones}[-1]{ended},
        1234,
        'End of last milestone unaffected by another call to stop_timing');
    is($timer->{timing_stopped}, 1314,
        'As was the time that timing stopped as a whole');
}

# If you don't specify a name, one is worked out for you.
sub test_default_milestone_name {
    my $timer = Timer::Milestones->new;
    my $expect_line = __LINE__ + 1;
    $timer->add_milestone;
    like(
        $timer,
        {
            milestones => array {
                item {
                    name    => 'START',
                    started => $re_timestamp,
                    ended   => $re_timestamp
                };
                item {
                    name => qr{
                        ^
                        TestsFor::Timer::Milestones::Milestones
                        ::test_default_milestone_name
                        \s
                        [(]
                             line \s $expect_line \s of \s
                             .* t/milestones[.]t
                        [)]
                        $
                    }xsm,
                    started => $re_timestamp
                };
                end();
            },
        },
        'A milestone name is generated from package, subroutine and line number'
    );
}

# If you stop timing, you can't add any more milestones.

sub test_ending_timing_thwarts_add_milestone {
    my $timer = Timer::Milestones->new;
    $timer->add_milestone('I can add this milestone');
    $timer->stop_timing;
    ok(
        exception {
            $timer->add_milestone(q{No more milestones, we've stopped})
        },
        q{Cannot add milestones after we've stopped milestones}
    );
}

# All of this works using exported functions.

sub test_exported_functions {
    # We'll test that ending testing spits out stuff to STDERR elsewhere,
    # but for the moment just make it shut up.
    # This is probably not Windows-safe.
    local *STDERR;
    open(STDERR, '>', '/dev/null');

    # Right, call our exported functions very simply.
    start_timing();
    add_milestone('This is really simple');
    stop_timing();

    # That updated our singleton.
    my ($singleton) = Timer::Milestones::_object_and_arguments;
    like(
        $singleton,
        {
            milestones => array {
                item {
                    name    => 'START',
                    started => $re_timestamp,
                    ended   => $re_timestamp
                };
                item {
                    name    => 'This is really simple',
                    started => $re_timestamp,
                    ended   => $re_timestamp
                };
                end();
            },
            timing_stopped => $re_timestamp,
        },
        'These methods also apply to a singleton in non-OO mode',
    ) or diag(Dumper($singleton));
}

1;
