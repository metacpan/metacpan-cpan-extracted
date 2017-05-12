package MockQueue;

use warnings;
use strict;

sub new {
    my ($class) = @_;
    return bless [], $class;
}

sub queue_task {
    my ($self, $task) = @_;

    push @{$self}, $task;
    return $task->uuid;
}

sub clear_tasks {
    my ($self) = @_;
    @{$self} = ();
    return;
}

sub get_tasks {
    my ($self) = @_;
    return @{$self};
}

1;

=head1 NAME

MockQueue - Mock the interface for a Queue object to allow Scheduler processing.

=head1 DESCRIPTION

This is a mocked queue object that basically supports the C<queue_task> method.
It also includes the ability to clear and retrieve the task objects.
