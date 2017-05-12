#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Time::ETA;
use Time::HiRes qw(
    gettimeofday
    tv_interval
    usleep
);
use Test::More;

use Time::ETA::MockTime;

# global vars
my $true = 1;
my $false = '';

my $precision = 0.1;
my $microseconds = 1_000_000;

my $tests = [
    {
        count => 6,
        sleep_time => $microseconds,
    },
    {
        count => 5,
        sleep_time => 0.75 * $microseconds,
    },
];

# methods that don't change data - they does not change the internals of the
# object

my @precise_immutable_methods = qw(
    get_completed_percent
    is_completed
    can_calculate_eta
    is_paused
);

my @inprecise_immutable_methods = qw(
    get_elapsed_seconds
    get_remaining_seconds
);


# subs
sub compare_objects {
    my (%params) = @_;

    croak "Expected to get 'original'" unless defined $params{original};
    croak "Expected to get 'respawned'" unless defined $params{respawned};
    croak "Expected to get 'passed_milestones'"
        unless defined $params{passed_milestones};

    foreach my $method (@precise_immutable_methods) {
        is(
            $params{original}->$method(),
            $params{respawned}->$method(),
            "After $params{passed_milestones} milestones "
                . "method $method returns equal values for "
                . "the original and respawned objects."
        );
    }

    foreach my $method (@inprecise_immutable_methods) {
        if($method eq "get_remaining_seconds") {
            next if $params{passed_milestones} == 0;
        }

        my $diff = $params{original}->$method()
            - $params{respawned}->$method();

        ok(
            abs($diff) < $precision,
            "After $params{passed_milestones} milestones "
                . "method $method returns equal values for "
                . "the original and respawned objects."
        );
    }

    return $false;
}

sub check_fresh_object {
    my (%params) = @_;

    croak "Expected to get 'original'" unless defined $params{original};
    croak "Expected to get 'start_time'" unless defined $params{start_time};

    my $original_eta = $params{original};

    my $data = $original_eta->serialize();
    ok(Time::ETA->can_spawn($data), 'can_spawn() return true');
    my $respawned_eta = Time::ETA->spawn($data);

    foreach my $name ("original", "respawned") {
        my $eta;

        if ($name eq "original") {
            $eta = $original_eta;
        } elsif ($name eq "respawned") {
            $eta = $respawned_eta;
        } else {
            croak "Internal error. Stopped";
        }

        # Untill pass_milestone() is run for the first time we know that the
        # percent of completion is 0.
        is(
            $eta->get_completed_percent(),
            0,
            "In $name fresh object we know the percent of completion is 0",
        );

        # At this point we can't calculate ETA
        ok(
            not($eta->can_calculate_eta()),
            "In $name fresh object we can't calculate ETA",
        );

        # And if we try we will get error
        eval {
            my $value = $eta->get_remaining_seconds();
        };

        like(
            $@,
            qr/There is not enough data to calculate estimated time of accomplishment/,
            "In $name fresh object we die if we try to use get_completed_percent()"
        );

        # The other thing that can be checked here is that
        # get_elapsed_seconds() returns the correct number of seconds
        ok(
            abs(
                tv_interval($params{start_time}, [gettimeofday])
                    - $eta->get_elapsed_seconds()
            ) < $precision,
            "In $name fresh object elapsed seconds are very small"
        );
    }

    return $false;
}

sub check_object_in_progress {
    my (%params) = @_;

    croak "Expected to get 'original'" unless defined $params{original};
    croak "Expected to get 'start_time'" unless defined $params{start_time};
    croak "Expected to get 'done'" unless defined $params{done};
    croak "Expected to get 'milestones'" unless defined $params{milestones};

    my $original_eta = $params{original};
    my $respawned_eta = Time::ETA->spawn($original_eta->serialize());

    foreach my $name ("original", "respawned") {
        my $eta;

        if ($name eq "original") {
            $eta = $original_eta;
        } elsif ($name eq "respawned") {
            $eta = $respawned_eta;
        } else {
            croak "Internal error. Stopped";
        }

        ok(
            not($eta->is_completed()),
            "In $name object after $params{done} milestones is_completed() return false",
        );

        my $percent = $eta->get_completed_percent();
        ok(
            abs($percent - ((100 * $params{done} / $params{milestones})) ) < $precision,
            "In $name object after $params{done} milestones got correct percent $percent",
        );

        ok(
            $eta->can_calculate_eta(),
            "In $name object after $params{done} milestones can_calculate_eta() return true",
        );

        my $remaining_seconds = $eta->get_remaining_seconds();
        my $number_of_tasks_left = $params{milestones} - $params{done};
        my $current_time = [gettimeofday()];
        my $estimated_time = $number_of_tasks_left
            * ( tv_interval($params{start_time}, $current_time) / $params{done});
        ok(
            abs($remaining_seconds - $estimated_time) < $precision,
            "In $name object after $params{done} milestones got correct remainig time $remaining_seconds"
        );

        my $elapsed_seconds = $eta->get_elapsed_seconds();
        my $elapsed_addition = 0;

        is(
            tv_interval($params{start_time}, $current_time),
            $elapsed_seconds,
            "In $name object after $params{done} milestones got correct elapsed seconds $elapsed_seconds"
        );

    }

}

sub check_completed_object {
    my (%params) = @_;

    croak "Expected to get 'original'" unless defined $params{original};
    croak "Expected to get 'start_time'" unless defined $params{start_time};
    croak "Expected to get 'end_time'" unless defined $params{end_time};

    my $original_eta = $params{original};
    my $respawned_eta = Time::ETA->spawn($original_eta->serialize());

    foreach my $name ("original", "respawned") {
        my $eta;

        if ($name eq "original") {
            $eta = $original_eta;
        } elsif ($name eq "respawned") {
            $eta = $respawned_eta;
        } else {
            croak "Internal error. Stopped";
        }

        ok(
            $eta->is_completed(),
            "In $name completed object is_completed() return true",
        );

        is(
            $eta->get_completed_percent(),
            100,
            "In $name completed object get_completed_percent() return 100",
        );

        ok(
            $eta->can_calculate_eta(),
            "In $name completed object can_calculate_eta() return true (but ETA should be 0)",
        );

        is(
            $eta->get_remaining_seconds(),
            0,
            "In $name completed object get_remaining_seconds() return 0",
        );

        is(
            $eta->get_remaining_time(),
            "0:00:00",
            "In $name completed object get_remaining_time() return '0:00:00'",
        );

# TODO bes
        my $elapsed_seconds = $eta->get_elapsed_seconds();
        is(
            tv_interval($params{start_time}, $params{end_time}),
            $elapsed_seconds,
            "In $name completed object got correct elapsed seconds $elapsed_seconds"
        );

        eval {
            $eta->pass_milestone();
        };
        like(
            $@,
            qr/You have already completed all milestones/,
            "In $name completed object pass_milestone() throws exception",
        );

    }
}

# main
sub main {
    ok($true, "Loaded ok");

    foreach my $test (@{$tests}) {

        my $original_eta = Time::ETA->new(
            milestones => $test->{count},
        );

        my $start_time = [gettimeofday()];

        compare_objects(
            original => $original_eta,
            respawned  => Time::ETA->spawn($original_eta->serialize()),
            passed_milestones => 0,
        );

        check_fresh_object(
            original => $original_eta,
            start_time => $start_time,
        );

        foreach my $i (1..$test->{count}) {

            usleep $test->{sleep_time};
            $original_eta->pass_milestone();

            compare_objects(
                original => $original_eta,
                respawned  => Time::ETA->spawn($original_eta->serialize()),
                passed_milestones => $i,
            );

            if ($i != $test->{count}) {
                # The compled part will be checked in check_completed_object()
                check_object_in_progress(
                    original => $original_eta,
                    start_time => $start_time,
                    done => $i,
                    milestones => $test->{count},
                );
            }
        }

        my $end_time = [gettimeofday()];

        check_completed_object(
            original => $original_eta,
            start_time => $start_time,
            end_time => $end_time,
        );

        sleep 1;

        check_completed_object(
            original => $original_eta,
            start_time => $start_time,
            end_time => $end_time,
        );

        compare_objects(
            original => $original_eta,
            respawned  => Time::ETA->spawn($original_eta->serialize()),
            passed_milestones => $test->{count},
        );

    }

    done_testing();
}
main();
__END__
