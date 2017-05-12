#!/usr/bin/perl

# Test the cPanel::TaskQueue module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();

use Test::More tests => 20;
use cPanel::TaskQueue;

my $tmpdir   = './tmp';
my $statedir = "$tmpdir/statedir";

# In case the last test did not succeed.
cleanup();
File::Path::mkpath($tmpdir) or die "Unable to create tmpdir: $!";

{

    package SleepTask;
    use base 'cPanel::TaskQueue::ChildProcessor';

    sub _do_child_task {
        my ( $self, $cmd, $logger, @args ) = @_;

        my $secs = $args[0] || 10;
        system("sleep $secs");
    }
}
cPanel::TaskQueue->register_task_processor( 'sleep', SleepTask->new() );

# Create the real TaskQueue
my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );
isa_ok( $queue, 'cPanel::TaskQueue', 'Correct object built.' );

my @qids;

foreach my $cmd ( 'sleep 2', 'noop 1', 'noop 2', 'noop 3' ) {
    push @qids, $queue->queue_task($cmd);
}

is( scalar( grep { defined $_ } @qids ), 4, 'All tasks queued successfully.' );

foreach my $id (@qids) {
    ok( $queue->is_task_queued($id), "$id: is queued" );
    my $task = $queue->find_task($id);
    if ( defined $task ) {
        is( $task->uuid(), $id, "$id: task found." );
    }
    else {
        fail("$id: task not found.");
    }
}

my $ftask = $queue->find_command('sleep');
ok( $ftask, 'Found the sleep task.' );
is( $qids[0], $ftask->uuid(), 'It is the correct task' );
$ftask = $queue->find_command('noop');
ok( $ftask, 'Found a noop task.' );
is( $qids[1], $ftask->uuid(), 'It is the correct noop task' );

ok( !$queue->find_command('xyzzy'), 'Did not find non-existant command.' );

SKIP:
{
    skip 'Long running tests not enabled.', 4 unless $ENV{CPANEL_SLOW_TESTS};

    ok( !$queue->process_next_task(),        'Start background task.' );
    ok( !$queue->is_task_queued( $qids[0] ), 'Not in queue.' );
    my $task = $queue->find_task( $qids[0] );
    if ( defined $task ) {
        is( $task->uuid(), $qids[0], 'Task found in processing' );
    }
    else {
        fail("Processing task not found.");
    }
    ok( $queue->is_task_processing( $qids[0] ), 'Is in processing.' );
    $queue->finish_all_processing();
}

{
    my $tid = $queue->queue_task('noop 1234');
    $queue->unqueue_task($tid);
    ok( !$queue->find_task($tid), 'Can not find task that is not isn queue.' );
}

cleanup();

# Clean up after myself
sub cleanup {
    File::Path::rmtree($tmpdir) if -d $tmpdir;
}

