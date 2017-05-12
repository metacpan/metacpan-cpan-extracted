#!/usr/bin/perl

# Test the cPanel::TaskQueue module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();

use Test::More tests => 20;
use cPanel::TaskQueue;

my $tmpdir = './tmp';

# Make sure we are clean to start with.
File::Path::rmtree( $tmpdir );
my $statedir = $tmpdir;

eval {
    cPanel::TaskQueue->register_task_processor();
};
like( $@, qr/Missing command/, 'register with no command fails' );
eval {
    cPanel::TaskQueue->register_task_processor( '' );
};
like( $@, qr/Missing command/, 'register with empty command fails' );
eval {
    cPanel::TaskQueue->register_task_processor( 'doit' );
};
like( $@, qr/Missing task processor/, 'register with missing processor fails' );
eval {
    cPanel::TaskQueue->register_task_processor( 'noop', sub {} );
};
like( $@, qr/already has/, 're-register command fails' );
eval {
    cPanel::TaskQueue->register_task_processor( 'fail', {} );
};
like( $@, qr/Unrecognized task processor/, 'Failed to register non-task process' );

my $mock_processor = cPanel::TaskQueue::Processor->new();
ok( cPanel::TaskQueue->register_task_processor( 'mock', $mock_processor ),
    'new TaskProcessor command registered' );
ok( cPanel::TaskQueue->unregister_task_processor( 'mock' ), 'Remove mock processor.' );

my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );
isa_ok( $queue, 'cPanel::TaskQueue', 'Correct object built.' );

my $times_executed = 0;
ok( cPanel::TaskQueue->register_task_processor( 'doit', sub { ++$times_executed; } ),
    'new coderef command registered' );

ok( my $qid4 = $queue->queue_task( 'doit a b c' ), 'Added a task with new command.' );
ok( $queue->process_next_task(), 'Task processed immediately' );
ok( !$queue->is_task_queued( $qid4 ), 'Task is not queued.' );
ok( !$queue->is_task_processing( $qid4 ), 'Task is not processing.' );
is( $times_executed, 1, 'doit code actually executed.' );

{
    package MockTask;
    use base 'cPanel::TaskQueue::Processor';

    sub is_valid_args {
        my ($self, $task) = @_;

        return 2 == scalar( $task->args() );
    }
}

ok( cPanel::TaskQueue->register_task_processor( 'mock', MockTask->new() ),
    'new TaskProcessor command registered' );

ok( $queue->queue_task( 'mock 1 2' ), 'new processor supported' );

eval {
    $queue->queue_task( 'mock 1 2 3' );
};
like( $@, qr/invalid arguments/, 'Invalid arguments detected.' );

# Check some invalid unregister requests.
eval {
    cPanel::TaskQueue->unregister_task_processor();
};
like( $@, qr/Missing command/, 'Must supply a command to unregister.' );

eval {
    cPanel::TaskQueue->unregister_task_processor( '' );
};
like( $@, qr/Missing command/, 'Must supply a non-empty command to unregister.' );

eval {
    cPanel::TaskQueue->unregister_task_processor( 'xyzzy' );
};
like( $@, qr/not registered/, 'Command must have been registered.' );

cleanup();

# Clean up after myself
sub cleanup {
    File::Path::rmtree( $tmpdir );
}
