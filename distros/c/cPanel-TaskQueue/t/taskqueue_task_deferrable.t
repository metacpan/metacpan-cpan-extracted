#!/usr/bin/perl

use Test::More tests => 34;

use strict;
use warnings;

use cPanel::TaskQueue;
use File::Path ();

my $tmpdir = './tmp';
my $state_dir = "$tmpdir/queue";

File::Path::rmtree( $tmpdir );

sub make_process_wait {
    open my $fh, '>>', "$state_dir/flag" or die "Unable to create flag file: $!\n";
    close( $fh );
}

sub clear_process_wait { unlink "$state_dir/flag"; }

{
    package MockTaskProcessor;
    use base 'cPanel::TaskQueue::ChildProcessor';

    sub _do_child_task {
        do {
            select( undef, undef, undef, 0.25 );  # 1/4 second sleep
        } while( -e "$state_dir/flag" );
        return;
    }

    sub deferral_tags {
        my ($self, $task) = @_;
        return $task->args();
    }

    cPanel::TaskQueue->register_task_processor( 'test', MockTaskProcessor->new() );
}

{
    my $label = 'No deferral overlap';

    File::Path::mkpath( $state_dir );
    my $queue = cPanel::TaskQueue->new( {
        state_dir => $state_dir,
        name      => 'test',
    } );

    make_process_wait();
    my @tasks = (
        $queue->queue_task( 'test' ),
        $queue->queue_task( 'test a' ),
        $queue->queue_task( 'test b' ),
        $queue->queue_task( 'test c' ),
    );

    is( $queue->how_many_queued(),     4, "$label: queue count starts correctly" );
    is( $queue->how_many_deferred(),   0, "$label: deferred count starts correctly" );
    is( $queue->how_many_in_process(), 0, "$label: process count starts correctly" );

    # moves the first task into processing
    $queue->process_next_task();

    is( $queue->how_many_queued(),     3, "$label (1 step): queue count starts correctly" );
    is( $queue->how_many_deferred(),   0, "$label (1 step): deferred count starts correctly" );
    is( $queue->how_many_in_process(), 1, "$label (1 step): process count starts correctly" );

    # looking for a new item to process with move all of the deferables to the queue
    $queue->process_next_task();
    ok( !$queue->has_work_to_do(),        "$label: no work to do" );

    is( $queue->how_many_queued(),     2, "$label (2 step): queue count is correct" );
    is( $queue->how_many_deferred(),   0, "$label (2 step): deferred count is correct" );
    is( $queue->how_many_in_process(), 2, "$label (2 step): process count is correct" );

    clear_process_wait();
    File::Path::rmtree( $state_dir );
}

{
    my $label = 'Full deferral overlap';

    File::Path::mkpath( $state_dir );
    my $queue = cPanel::TaskQueue->new( {
        state_dir => $state_dir,
        name      => 'test',
    } );

    make_process_wait();
    my @tasks = (
        $queue->queue_task( 'test a' ),
        $queue->queue_task( 'test a d' ),
        $queue->queue_task( 'test b a' ),
        $queue->queue_task( 'test c a' ),
    );

    is( $queue->how_many_queued(),     4, "$label: queue count starts correctly" );
    is( $queue->how_many_deferred(),   0, "$label: deferred count starts correctly" );
    is( $queue->how_many_in_process(), 0, "$label: process count starts correctly" );

    # moves the first task into processing
    $queue->process_next_task();

    is( $queue->how_many_queued(),     3, "$label (1 step): queue count starts correctly" );
    is( $queue->how_many_deferred(),   0, "$label (1 step): deferred count starts correctly" );
    is( $queue->how_many_in_process(), 1, "$label (1 step): process count starts correctly" );

    # looking for a new item to process with move all of the deferables to the queue
    $queue->process_next_task();

    my $snap = $queue->snapshot_task_lists();
    is_deeply(
        [ map { $_->uuid() } @{ $snap->{'deferred'} } ],
        [ @tasks[3,2,1] ],
        "$label: Deferred tasks found in correct order."
    );

    is( $queue->how_many_queued(),     0, "$label (2 step): queue count is correct" );
    is( $queue->how_many_deferred(),   3, "$label (2 step): deferred count is correct" );
    is( $queue->how_many_in_process(), 1, "$label (2 step): process count is correct" );

    clear_process_wait();
    sleep( 1 ); # Clear the processing task
    make_process_wait();
    $queue->process_next_task();

    # Deferred tasks are moved to waiting queue, and a new task begins processing
    is( $queue->how_many_queued(),     2, "$label (3 step): queue count is correct" );
    is( $queue->how_many_deferred(),   0, "$label (3 step): deferred count is correct" );
    is( $queue->how_many_in_process(), 1, "$label (3 step): process count is correct" );

    # Next attempt moves queued items to deferred queue if not ready.
    $queue->process_next_task();

    $snap = $queue->snapshot_task_lists();
    is_deeply(
        [ map { $_->uuid() } @{ $snap->{'deferred'} } ],
        [ @tasks[3,2] ],
        "$label: Deferred tasks found in correct order."
    );

    is( $queue->how_many_queued(),     0, "$label (3 step): queue count is correct" );
    is( $queue->how_many_deferred(),   2, "$label (3 step): deferred count is correct" );
    is( $queue->how_many_in_process(), 1, "$label (3 step): process count is correct" );

    clear_process_wait();
    File::Path::rmtree( $state_dir );
}

{
    my $label = 'Partial deferral overlap';

    File::Path::mkpath( $state_dir );
    my $queue = cPanel::TaskQueue->new( {
        state_dir => $state_dir,
        name      => 'test',
    } );

    make_process_wait();
    my @tasks = (
        $queue->queue_task( 'test a' ),
        $queue->queue_task( 'test a d' ),
        $queue->queue_task( 'test b a' ),
        $queue->queue_task( 'test c d' ),
    );

    is( $queue->how_many_queued(),     4, "$label: queue count starts correctly" );
    is( $queue->how_many_deferred(),   0, "$label: deferred count starts correctly" );
    is( $queue->how_many_in_process(), 0, "$label: process count starts correctly" );

    # moves the first task into processing
    $queue->process_next_task();
    $queue->process_next_task();  # Works through deferred items until one to process.

    my $snap = $queue->snapshot_task_lists();
    is_deeply(
        [ map { $_->uuid() } @{ $snap->{'deferred'} } ],
        [ @tasks[2,1] ],
        "$label: Deferred tasks found in correct order."
    );

    is( $queue->how_many_queued(),     0, "$label (2 step): queue count is correct" );
    is( $queue->how_many_deferred(),   2, "$label (2 step): deferred count is correct" );
    is( $queue->how_many_in_process(), 2, "$label (2 step): process count is correct" );

    clear_process_wait();
    File::Path::rmtree( $state_dir );
}

File::Path::rmtree( $tmpdir );
