#!/usr/bin/perl

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();

use Test::More tests => 15;
use cPanel::TaskQueue;

my $tmpdir = './tmp';
my $statedir = "$tmpdir/state_test";

# In case the last test did not succeed.
cleanup();
File::Path::mkpath( $tmpdir ) or die "Unable to create tmpdir: $!";

# Create the real TaskQueue
my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );

ok( !$queue->is_paused, 'TaskQueue is created unpaused.' );

$queue->pause_processing;
ok( $queue->is_paused, 'TaskQueue is paused.' );
my $qid = $queue->queue_task( 'noop 1 2 3' );
ok( $qid, 'Task queued.' );
ok( $queue->is_task_queued( $qid ), 'id found in queue' );
ok( !$queue->has_work_to_do(), 'A paused queue has no work to do.' );
ok( $queue->process_next_task(), 'A paused queue does no work' );
ok( $queue->is_task_queued( $qid ), 'id still found in queue' );

$queue->resume_processing;
ok( !$queue->is_paused, 'TaskQueue is unpaused.' );
ok( $queue->has_work_to_do(), 'Unpaused queue ow has work to do' );
ok( $queue->process_next_task(), 'Unpaused queue processes tasks' );
ok( !$queue->is_task_queued( $qid ), 'no longer found in queue' );

{
    my $label = "Resume in other copy";
    $queue->pause_processing;
    ok( $queue->is_paused, "$label: TaskQueue is paused." );
    my $queue2 = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );
    ok( $queue2->is_paused, "$label: TaskQueue2 is paused." );
    $queue2->resume_processing;
    ok( !$queue2->is_paused, "$label: TaskQueue2 is unpaused." );
    ok( !$queue->is_paused, "$label: TaskQueue is unpaused." );
}

cleanup();

# Clean up after myself
sub cleanup {
    File::Path::rmtree( $tmpdir );
}
