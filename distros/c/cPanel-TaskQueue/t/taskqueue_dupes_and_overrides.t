#!/usr/bin/perl

# Test the cPanel::TaskQueue module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();

use Test::More tests => 39;
use cPanel::TaskQueue;
use cPanel::TaskQueue::Processor;

my $tmpdir      = './tmp';
my $statedir    = "$tmpdir/statedir";
my $missing_dir = "$tmpdir/task_queue_test";

{

    package MockProcessor;
    use cPanel::TaskQueue::Processor;
    use base 'cPanel::TaskQueue::Processor';

    sub overrides {
        my $self = shift;
        my ( $new, $old ) = @_;

        return unless 'mock' eq $old->command();

        return 1 if 'all' eq $new->get_arg(0);

        return $new->get_arg(0) eq $old->get_arg(0);
    }

    sub process_task {
        my $self = shift;
        my $task = shift;

        return;
    }
}

cPanel::TaskQueue->register_task_processor( 'mock', MockProcessor->new() );

# In case the last test did not succeed.
cleanup();
File::Path::mkpath($tmpdir) or die "Unable to create tmpdir: $!";

# Create the real TaskQueue
my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );
isa_ok( $queue, 'cPanel::TaskQueue', 'Correct object built.' );
is( $queue->get_name, 'tasks', 'Queue is named correctly.' );

# Duplicate testing
ok( $queue->queue_task('noop 1 2 3'), 'queue item' );
is( $queue->how_many_queued(), 1, 'Only one item' );

ok( !$queue->queue_task('noop 1 2 3'), 'can not queue duplicate' );
ok( $queue->queue_task('noop a b c'),  'can queue with different args (1)' );
ok( $queue->queue_task('noop 1 b c'),  'can queue with different args (2)' );
ok( $queue->queue_task('noop a 2 c'),  'can queue with different args (3)' );
ok( $queue->queue_task('noop a b 3'),  'can queue with different args (4)' );

ok( !$queue->queue_task('noop 1 b c'),      'duplicate not added even if not first' );
ok( !$queue->queue_task('noop  a   2   c'), 'duplicate test ignores spacing' );
ok( !$queue->queue_task('noop  a \'2\' c'), 'duplicate test ignores single quoting' );
ok( !$queue->queue_task('noop  a "2" c'),   'duplicate test ignores double quoting' );
is( $queue->how_many_queued(), 5, 'Correct number is queued.' );

# Empty the queue
foreach my $i ( 0 .. 4 ) {
    $queue->unqueue_task( $queue->peek_next_task()->uuid() );
}

# Override testing
ok( $queue->queue_task('mock 1 on'), 'queue mock (1)' );
ok( $queue->queue_task('mock 2 on'), 'queue mock (2)' );
ok( $queue->queue_task('mock 3 on'), 'queue mock (3)' );
is( $queue->how_many_queued(), 3, 'Correct number of mocks queued.' );

ok( $queue->queue_task('mock all off'), 'queue override request' );
is( $queue->how_many_queued(),            1,     'only one task exists' );
is( $queue->peek_next_task()->get_arg(0), 'all', 'it is the override' );

# add after override
ok( $queue->queue_task('mock 1 on'), 'queue mock (1)' );
ok( $queue->queue_task('mock 2 on'), 'queue mock (2)' );
ok( $queue->queue_task('mock 3 on'), 'queue mock (3)' );
is( $queue->how_many_queued(), 4, 'Correct number of mocks queued.' );

ok( $queue->queue_task('mock 2 off'), 'single override' );
is( $queue->how_many_queued(), 4, 'Number of mocks queued not changed.' );

remove_and_check_tasks(
    $queue, 'single override',
    'all off',
    '1 on',
    '3 on',
    '2 off',
);

# override, not dupe
ok( $queue->queue_task('mock all off'), 'queue override request' );
ok( $queue->queue_task('mock 1 on'),    'queue mock (1)' );
ok( $queue->queue_task('mock 2 on'),    'queue mock (2)' );
ok( $queue->queue_task('mock 3 on'),    'queue mock (3)' );
ok( $queue->queue_task('mock all off'), 'queue override request' );
is( $queue->how_many_queued(),            1,     'only one task exists' );
is( $queue->peek_next_task()->get_arg(0), 'all', 'it is the override' );

# perform cleanup.

cleanup();

sub remove_and_check_tasks {
    my $q     = shift;
    my $label = shift;

    is( scalar(@_), $q->how_many_queued(), "$label: correct number queued" );
    my $i = 0;
    while ( my $first = $q->peek_next_task() ) {
        is( $first->argstring(), $_[$i], "$label [$i]: correct task." );
        $q->unqueue_task( $first->uuid() );
        ++$i;
    }
}

# Clean up after myself
sub cleanup {
    File::Path::rmtree($tmpdir) if -d $tmpdir;
}
