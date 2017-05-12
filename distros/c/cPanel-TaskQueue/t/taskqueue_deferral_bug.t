#!/usr/bin/env perl

use Test::More 'no_plan'; #tests => 1;
use File::Temp;

use strict;
use warnings;
use FindBin;
use File::Path ();
use lib "$FindBin::Bin/mocks";

my $statedir = File::Temp->newdir();

use cPanel::TaskQueue ( -logger => 'cPanel::FakeLogger', -serializer => 'cPanel::TQSerializer::YAML' );

# I need a task that I can cause to wait and then trigger when I'm ready.
{
    package Triggerable;
    use base 'cPanel::TaskQueue::ChildProcessor';

    sub trigger {
        my ( $class, $arg ) = @_;
        my $file = "$statedir/$arg";
        open my $fh, '>>', $file or die;
        print {$fh} $arg;
        close $fh;

        # Wait for processor to handle
        select undef, undef, undef, 0.1 while -e $file;
        # Make certain that other process has exited
        select undef, undef, undef, 0.2;
    }

    sub _do_child_task {
        my ( $self, $task, $logger ) = @_;
        my $arg = $task->get_arg( 0 );
        my $file = "$statedir/$arg";
        # Wait for trigger.
        while( !-e $file ) {
            select undef, undef, undef, 0.1;
        }
        unlink $file;

        return;
    }

    sub is_valid_args {
        my ( $self, $task ) = @_;
        return defined $task->get_arg( 0 );
    }

    sub deferral_tags {
        my ( $self, $task ) = @_;
        return qw/wait/;
    }
}

cPanel::TaskQueue->register_task_processor( 'trigger', Triggerable->new() );

# Need two potential processes, otherwise I don't get control to trigger.
my $queue = cPanel::TaskQueue->new( {
        name => 'tasks',
        state_dir => $statedir,
        max_running => 2
    } );

# Queue two tasks, one of which will defer
$queue->queue_task( 'trigger hold' );
$queue->queue_task( 'trigger defer' );

# Attempt to process each task
$queue->process_next_task();
$queue->process_next_task();
is( $queue->how_many_in_process(), 1, 'One processing task' );
is( $queue->how_many_deferred(), 1, 'One deferred task' );

# Cause the first task to complete
Triggerable->trigger( 'hold' );
$queue->process_next_task();
is( $queue->how_many_in_process(), 1, 'Deferred task is now processing' );
is( $queue->how_many_deferred(), 0, 'No more deferred tasks' );

# Cause the second task to complete
Triggerable->trigger( 'defer' );
$queue->process_next_task();
is( $queue->how_many_in_process(), 0, 'All tasks cleared' );
