package cPanel::TaskQueue::ChildProcessor;
$cPanel::TaskQueue::ChildProcessor::VERSION = '0.900';
use strict;

#use warnings;
use base 'cPanel::TaskQueue::Processor';
use cPanel::TaskQueue::Scheduler ();

{

    sub get_child_timeout {
        my ($self) = @_;
        return;
    }

    sub get_reschedule_delay {
        my ( $self, $task ) = @_;

        return 15 * 60;
    }

    sub retry_task {
        my ( $self, $task, $delay ) = @_;
        $delay ||= $self->get_reschedule_delay($task);

        $task->decrement_retries();
        if ( $task->retries_remaining() and $task->get_userdata('sched') ) {
            my $s = cPanel::TaskQueue::Scheduler->new( { token => $task->get_userdata('sched') } );

            # This will either succeed or exception.
            $s->schedule_task( $task, { delay_seconds => $delay } );
        }

        return;
    }

    sub process_task {
        my ( $self, $task, $logger ) = @_;
        my $pid = fork();

        $logger->throw( q{Unable to start a child process to handle the '} . $task->command() . "' task\n" )
          unless defined $pid;

        # Parent returns
        return $pid if $pid;

        my $timeout = $self->get_child_timeout() || $task->child_timeout();
        my $oldalarm;
        eval {
            local $SIG{'CHLD'} = 'DEFAULT';
            local $SIG{'ALRM'} = sub { die "timeout detected\n"; };
            $oldalarm = alarm $timeout;
            $self->_do_child_task( $task, $logger );
            alarm $oldalarm;
            1;
        } or do {
            my $ex = $@;
            alarm $oldalarm;
            if ( $ex eq "timeout detected\n" ) {
                eval {

                    # TODO: consider adding another timeout in case this handling
                    # locks up.
                    $self->_do_timeout($task);

                    # Handle retries
                    $self->retry_task($task);
                };

                # Don't throw, we want to exit instead.
                if ($@) {
                    $logger->warn($@);
                    exit 1;
                }
            }
            else {

                # Don't throw, we want to exit instead.
                $logger->warn($ex);
                exit 1;
            }
        };
        exit 0;
    }

    sub _do_timeout {
        my ( $self, $task ) = @_;

        return;
    }

    sub _do_child_task {
        my ( $self, $task, $logger ) = @_;

        $logger->throw("No child task defined.\n");
    }
}

1;

__END__

Copyright (c) 2010, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

