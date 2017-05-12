#!/usr/bin/perl

# Test the retry logic for the cPanel::TaskQueue module.
#
# This tests the code for tasks scheduled for some time in the future. Since these
#  tasks are, by necessity, slower to execute than we probably don't want to run
#  as a normal test. This code is disabled, unless it is run with the environment
#  variable CPANEL_SLOW_TESTS set.


use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();

use Test::More tests => 17;
use cPanel::TaskQueue::Scheduler;
use cPanel::TaskQueue;
use cPanel::TaskQueue::Task;

my $tmpdir = './tmp';
my $statedir = $tmpdir;

# Processor designed to test retry logic.
{
    package MockTimeoutProcessor;
    use base 'cPanel::TaskQueue::ChildProcessor';

    sub get_child_timeout {
        my $self = shift;

        return 1;
    }

    sub get_reschedule_delay {
        my $self = shift;
        my $task = shift;
        return 5;
    }

    sub _do_child_task {
        my ($self, $task) = @_;

        sleep 3;
        return;
    }
}

cPanel::TaskQueue->register_task_processor( 'task', MockTimeoutProcessor->new() );

# In case the last test did not succeed.
cleanup();
File::Path::mkpath( $tmpdir ) or die "Unable to create tmpdir: $!";

my $sched = cPanel::TaskQueue::Scheduler->new(
    { name => 'tasks', state_dir => $statedir }
);
isa_ok( $sched, 'cPanel::TaskQueue::Scheduler', 'Scheduler object built.' );
my $queue = cPanel::TaskQueue->new(
    { name => 'tasks', state_dir => $statedir }
);
isa_ok( $queue, 'cPanel::TaskQueue', 'Queue object built.' );

# Set up initial retryable task
ok( $sched->schedule_task( 'task', {delay_seconds=>1, attempts=>4} ), 'scheduled task' );
is( $sched->peek_next_task()->retries_remaining(), 4, 'Retry count starts correctly.' );
SKIP:
{
    skip 'Long running tests not enabled.', 12 unless $ENV{CPANEL_SLOW_TESTS};

    my $wait;
    sleep $wait if $wait = $sched->seconds_until_next_task();
    is( $sched->process_ready_tasks( $queue ), 1, 'Task queued' );
    is( $sched->how_many_scheduled(), 0, 'Task has been queued' );
    ok( !$queue->process_next_task(), 'Child process launched.' );

# Timeout and retry
    sleep 3;
    is( $sched->how_many_scheduled(), 1, 'Task has been rescheduled' );
    is( $sched->peek_next_task()->retries_remaining(), 3, 'Retry count has been reduced.' );
    is( $sched->seconds_until_next_task(), 3, 'Delayed appropriately' );

    sleep $wait if $wait = $sched->seconds_until_next_task();
    is( $sched->process_ready_tasks( $queue ), 1, 'Task queued' );
    is( $sched->how_many_scheduled(), 0, 'Task has been queued' );
    ok( !$queue->process_next_task(), 'Child process launched.' );

# Timeout and retry
    sleep 3;
    is( $sched->how_many_scheduled(), 1, 'Task has been rescheduled' );
    is( $sched->peek_next_task()->retries_remaining(), 2, 'Retry count has been reduced.' );
    is( $sched->seconds_until_next_task(), 3, 'Delayed appropriately' );
}

ok( !$sched->schedule_task( 'task', {delay_seconds=>1, attempts=>0} ), 'do not schedule with no attempts' );

cleanup();

# Clean up after myself
sub cleanup {
    File::Path::rmtree( $tmpdir ) if -d $tmpdir;
}
