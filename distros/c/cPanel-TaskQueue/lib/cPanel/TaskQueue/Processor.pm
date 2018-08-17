package cPanel::TaskQueue::Processor;
$cPanel::TaskQueue::Processor::VERSION = '0.900';
use strict;

#use warnings;

{

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub get_timeout {
        my ($self) = @_;
        return;
    }

    sub is_dupe {
        my ( $self, $a, $b ) = @_;

        return unless $a->command() eq $b->command();
        my @a_args = $a->args();
        my @b_args = $b->args();
        return unless @a_args == @b_args;

        foreach my $i ( 0 .. $#a_args ) {
            return unless $a_args[$i] eq $b_args[$i];
        }

        return 1;
    }

    sub overrides {
        my ( $self, $new, $old ) = @_;

        return;
    }

    sub is_valid_args {
        my ( $self, $task ) = @_;

        return 1;
    }

    sub process_task {
        my ( $self, $task, $logger ) = @_;

        if ($logger) {
            $logger->throw("No processing has been specified for this task.\n");
        }
        else {
            die "No processing has been specified for this task.\n";
        }
    }

    sub deferral_tags {
        my ( $self, $task ) = @_;
        return;
    }

    sub is_task_deferred {
        my ( $self, $task, $defer_hash ) = @_;
        return unless $defer_hash && keys %{$defer_hash};

        foreach my $tag ( $self->deferral_tags($task) ) {
            return 1 if exists $defer_hash->{$tag};
        }

        return;
    }

    # Utility functions
    sub checked_system {
        my ( $self, $args ) = @_;
        die "Argument must be a hashref." unless ref $args eq 'HASH';
        die "Missing required 'logger' argument." unless $args->{'logger'};
        $args->{'logger'}->throw("Missing required 'cmd' argument.")
          unless defined $args->{'cmd'} && length $args->{'cmd'};
        $args->{'logger'}->throw("Missing required 'name' argument.")
          unless defined $args->{'name'} && length $args->{'name'};
        $args->{'args'} ||= [];

        my $rc = system $args->{'cmd'}, @{ $args->{'args'} };
        return 0 unless $rc;

        my $message;
        if ( $rc == -1 ) {
            $message = "Failed to run $args->{'name'}";
        }
        elsif ( $rc & 127 ) {
            $message = "$args->{'name'} dies with signal: " . ( $rc & 127 );
        }
        else {
            $message = "$args->{'name'} exited with value " . ( $rc >> 8 );
        }
        $args->{'logger'}->warn($message);

        return $rc;
    }
}

# To simplify use, here is a simple module that turns a code ref into a valid
# TaskQueue::Processor.
{

    package cPanel::TaskQueue::Processor::CodeRef;
$cPanel::TaskQueue::Processor::CodeRef::VERSION = '0.900';
use parent -norequire, 'cPanel::TaskQueue::Processor';

    {

        sub new {
            my ( $class, $args_ref ) = @_;
            die "Args must be a hash ref.\n" unless 'HASH' eq ref $args_ref;

            unless ( exists $args_ref->{code} and 'CODE' eq ref $args_ref->{code} ) {
                die "Missing required code parameter.\n";
            }
            return bless { proc => $args_ref->{code} }, $class;
        }

        # Override the default behavior to call the stored coderef with the
        # arguments supplied in the task. Return whatever the coderef returns.
        sub process_task {
            my ( $self, $task, $logger ) = @_;

            eval {
                $self->{proc}->( $task->args() );
                1;
            } or do {
                $logger->throw($@);
            };

            return 0;
        }
    }
}

1;

__END__

Copyright (c) 2010, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

