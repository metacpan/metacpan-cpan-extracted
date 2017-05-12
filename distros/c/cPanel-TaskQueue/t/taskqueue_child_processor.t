#!/usr/bin/perl

use Test::More tests => 6;

use strict;
use warnings;
use cPanel::TaskQueue::ChildProcessor;

{
    package MockTask;
    sub new {
        return bless { retries => 5 };
    }
    sub retries_remaining { return $_[0]->{retries}; }
    sub decrement_retries {
        --( $_[0]->{retries} ) if $_[0]->{retries};
        return;
    }
    sub get_userdata {
        return;
    }
}

my $proc = cPanel::TaskQueue::ChildProcessor->new;
isa_ok( $proc, 'cPanel::TaskQueue::ChildProcessor', 'correct type' );

ok( !defined $proc->get_child_timeout, 'Default timeout is undef.' );
is( $proc->get_reschedule_delay, 900, 'Default reschedule delay is 15 minutes.' );
my $task = MockTask->new;
$proc->retry_task( $task );
is( $task->retries_remaining, 4, 'Number retries is decremented.' );

$proc->retry_task( $task, 1 );
is( $task->retries_remaining, 3, 'Number retries is decremented, again.' );

$task->decrement_retries() while $task->retries_remaining();
$proc->retry_task( $task );
is( $task->retries_remaining, 0, 'Scheduling with no retries is okay.' );

