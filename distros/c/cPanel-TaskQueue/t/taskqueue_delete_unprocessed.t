#!/usr/bin/perl

# Test the cPanel::TaskQueue module.
#

use Test::More tests => 6;

use strict;
use warnings;
use File::Temp;

use cPanel::TaskQueue;

my $tmpdir      = File::Temp->newdir();
my $statedir    = "$tmpdir/statedir";

# Create the real TaskQueue
my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );

ok( $queue->queue_task('noop 1 on'), 'queue noop (1)' );
ok( $queue->queue_task('noop 2 on'), 'queue noop (2)' );
ok( $queue->queue_task('noop 3 on'), 'queue noop (3)' );
is( $queue->how_many_queued(), 3, 'Correct number of noops queued.' );

is( $queue->delete_all_unprocessed_tasks(), 3, "Correct number of waiting tasks deleted" );
is( $queue->how_many_queued(), 0, 'All noops deleted' );
