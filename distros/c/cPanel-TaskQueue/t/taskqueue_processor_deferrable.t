#!/usr/bin/perl

use Test::More tests => 14;

use strict;
use warnings;
use cPanel::TaskQueue::Task;
use cPanel::TaskQueue::Processor;

{
    package MockTaskProcessor;
    use base 'cPanel::TaskQueue::Processor';

    sub process_task {
        my ($self, $task) = @_;
        return 1;
    }

    sub deferral_tags {
        my ($self, $task) = @_;

        return $task->args();
    }
}

my $task = cPanel::TaskQueue::Task->new( {
    cmd  => 'test tag1 tag2 tag3',
    nsid => 'TaskQueueTest',
    id   => 1,
} );

{
    my $proc = MockTaskProcessor->new();

    is_deeply( [ $proc->deferral_tags( $task ) ], [ qw(tag1 tag2 tag3) ], 'Deferral tags' );

    ok( !$proc->is_task_deferred( $task, {} ),            'Not deferred: empty deferral object' );
    ok( !$proc->is_task_deferred( $task, { fred => 1 } ), 'Not deferred: non-matching tag' );

    ok(  $proc->is_task_deferred( $task, { tag1 => 1 } ), 'Deferred: with first tag' );
    ok(  $proc->is_task_deferred( $task, { tag2 => 1 } ), 'Deferred: with second tag' );
    ok(  $proc->is_task_deferred( $task, { tag3 => 1 } ), 'Deferred: with third tag' );

    ok(  $proc->is_task_deferred( $task, { tag1 => 1, tag2 => 1 } ), 'Deferred: with multiple tag' );
}

{
    my $proc = cPanel::TaskQueue::Processor->new();

    is_deeply( [ $proc->deferral_tags( $task ) ], [ ], 'Deferral tags: none' );

    ok( !$proc->is_task_deferred( $task, {} ),            'Not deferred: empty deferral object' );
    ok( !$proc->is_task_deferred( $task, { fred => 1 } ), 'Not deferred: non-matching tag' );

    ok( !$proc->is_task_deferred( $task, { tag1 => 1 } ), 'Not Deferred: with first tag' );
    ok( !$proc->is_task_deferred( $task, { tag2 => 1 } ), 'Not Deferred: with second tag' );
    ok( !$proc->is_task_deferred( $task, { tag3 => 1 } ), 'Not Deferred: with third tag' );

    ok( !$proc->is_task_deferred( $task, { tag1 => 1, tag2 => 1 } ), 'Not Deferred: with multiple tag' );
}
