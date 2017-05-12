#!/usr/bin/perl

# Test the cPanel::TaskQueue module.
#
# This tests the code for handling long-running processes. Since it is, by
#  necessity, slower to execute than we probably want to run as a normal
#  test. This code is disabled, unless it is run with the environment
#  variable CPANEL_SLOW_TESTS set.


use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();

use Test::More tests => 34;
use cPanel::TaskQueue;

my $tmpdir = './tmp';
my $statedir = "$tmpdir/statedir";

{
    package SleepTask;
    use base 'cPanel::TaskQueue::ChildProcessor';

    sub _do_child_task {
        my ($self, $cmd, $logger, @args) = @_;

        my $secs = $args[0] || 10;
        system( "sleep $secs" );
    }
}

SKIP:
{
    skip 'Long running tests not enabled.', 34 unless $ENV{CPANEL_SLOW_TESTS};

    # In case the last test did not succeed.
    cleanup();
    File::Path::mkpath( $statedir );

    cPanel::TaskQueue->register_task_processor( 'sleep', SleepTask->new() );

    my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir, max_running => 5 } );
    isa_ok( $queue, 'cPanel::TaskQueue', 'Correct object built.' );

    foreach my $cnt ( 1 .. 8 ) {
        my $time = 10+$cnt;
        ok( $queue->queue_task( "sleep $time" ), "$cnt task queued" );
    }

    is( $queue->how_many_queued(), 8, 'correct number queued' );
    ok( $queue->has_work_to_do(), 'tasks outstanding' );

    ok( !$queue->process_next_task(), "child task $_" ) foreach 0 .. 4;
    is( $queue->how_many_in_process(), 5, 'correct number in process' );

    # Don't use normally, only for monitoring.
    my $queues = $queue->snapshot_task_lists();
    is( scalar( @{$queues->{waiting}} ), 3, 'Waiting list is correct size.' );
    is( scalar( @{$queues->{processing}} ), 5, 'Processing list is empty.' );
    foreach my $cnt ( 1 .. 5 ) {
        my $time = 10+$cnt;
        if ( defined $queues->{processing}->[$cnt-1] ) {
            is( $queues->{processing}->[$cnt-1]->full_command(), "sleep $time", "$cnt command is correct" );
        }
        else {
            fail( "$cnt processing task not found" )
        }
    }


    ok( !$queue->has_work_to_do(), 'can\'t work too many in process.' );

    ok( !$queue->process_next_task(), 'should wait to process' );
    is( $queue->how_many_queued(), 2, 'correct number remaining' );
    ok( !$queue->process_next_task(), "processing next to last task" );
    ok( !$queue->process_next_task(), "processing last task" );

    ok( !$queue->has_work_to_do(), 'still too many in process' );
    isnt( $queue->how_many_in_process(), 0, 'some are being processed' );
    is( $queue->how_many_queued(), 0, 'no more in queue' );
    $queue->finish_all_processing();
    ok( !$queue->has_work_to_do(), 'no outstanding tasks' );
    is( $queue->how_many_in_process(), 0, 'no more in process' );

    cleanup();
}


# Clean up after myself
sub cleanup {
    File::Path::rmtree( $tmpdir );
}
