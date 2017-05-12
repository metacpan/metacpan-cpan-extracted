#!/usr/bin/perl

# Test the cPanel::TaskQueue module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();

use Test::More tests => 42;
use cPanel::TaskQueue;

my $tmpdir = './tmp';
my $statedir = "$tmpdir/state_test";

# In case the last test did not succeed.
cleanup();
File::Path::mkpath( $tmpdir ) or die "Unable to create tmpdir: $!";

# Create the real TaskQueue
my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );
isa_ok( $queue, 'cPanel::TaskQueue', 'Correct object built.' );
is( $queue->get_name, 'tasks', 'Queue is named correctly.' );

# Internal method, just verifying it's correct.
is( $queue->_state_file, "$statedir/tasks_queue.stor", 'State file is expected.' );

# Queue a simple item
my $qid = $queue->queue_task( 'noop 1 2 3' );
ok( $qid, 'Task queued.' );
ok( $queue->is_task_queued( $qid ), 'id found in queue' );
ok( $queue->has_work_to_do(), 'could do work.' );

my $qid2 = $queue->queue_task( 'noop a  b  c' );
ok( $qid2, 'Second task queued.' );
is( $queue->how_many_queued(), 2, 'Correct number in queue' );
isnt( $qid, $qid2, 'Queue Ids are unique.' );

ok( $queue->is_task_queued( $qid2 ), 'second id found' );
ok( $queue->is_task_queued( $qid ), 'first id still there' );

# Don't use normally, only for monitoring.
my $queues = $queue->snapshot_task_lists();
is( scalar( @{$queues->{waiting}} ), 2, 'Waiting list is correct size.' );
is( scalar( @{$queues->{processing}} ), 0, 'Processing list is empty.' );
is( $queues->{waiting}->[0]->full_command(), 'noop 1 2 3', 'First command is correct' );
is( $queues->{waiting}->[1]->full_command(), 'noop a  b  c', 'Second command is correct' );

ok( $queue->unqueue_task( $qid ), 'unqueue task succeeds' );
ok( !$queue->is_task_queued( $qid ), 'is truly unqueued' );
is( $queue->how_many_queued(), 1, 'Only one now.' );
ok( $queue->is_task_queued( $qid2 ), 'second is still queued' );

# Fail to insert duplicate command.
ok( !$queue->queue_task( "noop a b c" ), 'cannot queue a duplicate command' );

# Look at first task
my $task = $queue->peek_next_task();
isa_ok( $task, 'cPanel::TaskQueue::Task', 'We have a task' );
is( $task->command(), 'noop', 'Correct command in the queue.' );
is( join( ' ', $task->args() ), 'a b c', 'Correct command arguments.' );
is( $task->argstring(), 'a  b  c', 'Correct command argument string.' );
is( $task->uuid(), $qid2, 'Correct Task id.' );

# Test a second TaskQueue on same file.
my $q2 = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );
ok( $q2->is_task_queued( $qid2 ), 'Has read the previous queue' );
my $qid3 = $q2->queue_task( 'noop g w j' );
ok( $qid3, 'Have a queue id for new task' );
$task = $queue->peek_next_task();
isa_ok( $task, 'cPanel::TaskQueue::Task', 'We have a task' );
is( $task->uuid(), $qid2, 'Still previous task at front.' );

ok( $queue->is_task_queued( $qid3 ), 'Original queue sees the new task.' );

ok( $queue->unqueue_task( $qid2 ), 'Remove first' );
ok( $queue->unqueue_task( $qid3 ), 'Remove last' );
is( $queue->how_many_queued(), 0, 'Queue is empty.' );

eval {
    $queue->queue_task( 'xyzzy 1 2 3' );
};
like( $@, qr/No known processor/, 'Unrecognized command.' );

eval {
    $queue->queue_task( '' );
};
like( $@, qr/empty command/, 'Cannot queue an empty command.' );

eval {
    $queue->queue_task( '    ' );
};
like( $@, qr/empty command/, 'Cannot queue a command that is all space.' );

eval {
    $queue->unqueue_task();
};
like( $@, qr/No Task uuid/, 'Can not unqueue without a uuid' );

eval {
    $queue->unqueue_task( 1111111 );
};
like( $@, qr/No Task uuid/, 'Can not unqueue with an invalid uuid' );

eval {
    $queue->is_task_queued();
};
like( $@, qr/No Task uuid/, 'Can not check queued task without a uuid' );

eval {
    $queue->is_task_queued( 1111111 );
};
like( $@, qr/No Task uuid/, 'Can not check queued task with an invalid uuid' );

eval {
    $queue->is_task_processing();
};
like( $@, qr/No Task uuid/, 'Can not check processing task without a uuid' );

eval {
    $queue->is_task_processing( 1111111 );
};
like( $@, qr/No Task uuid/, 'Can not check processing task with an invalid uuid' );

cleanup();

# Clean up after myself
sub cleanup {
    File::Path::rmtree( $tmpdir );
}
