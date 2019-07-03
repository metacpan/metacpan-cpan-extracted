package WorkerManager::Gearman;
use strict;
use warnings;
use Module::Load ();
use Gearman::Worker;

our $VERSION = '0.1000';

use Class::Accessor::Lite (
    rw => [qw(
        job_servers
        prefix
        worker_classes
        workers
    )],
);

sub new {
    my ($class, $worker_classes, $options) = @_;
    $options ||= {};

    my $prefix = delete $options->{prefix} || '';
    my $job_servers;
    if ($job_servers = delete $options->{job_servers}) {
        $job_servers = [$job_servers] if ref $job_servers ne 'ARRAY';
    }
    else {
        $job_servers = [qw(127.0.0.1)];
    }

    my $self = $class->SUPER::new({
        job_servers    => $job_servers,
        prefix         => $prefix,
        worker_classes => $worker_classes || [],
        terminate      => undef,
        workers        => [],
    });
    $self->init;
    $self;
}

sub init {
    my $self = shift;
    for my $worker_class (@{$self->worker_classes}) {
        Module::Load::load($worker_class);
        push @{$self->workers}, $worker_class->new({
            job_servers => $self->job_servers,
            prefix      => $self->prefix,
        });
    }
}

sub work {
    my $self  = shift;
    my $max   = shift || 100;
    my $delay = shift || 5;
    my $count = 0;
    while ($count < $max && !$self->{terminate}) {
        if (getppid == 1) {
            die "my dad may be killed.";
            exit(1);
        }
        for my $worker (@{$self->workers}) {
            $worker->worker->work(
                on_start => sub {
                    my $job = shift;
                    $WorkerManager::LOGGER->('Gearman', sprintf('started: %s', ref $worker));
                },
                on_complete => sub {
                    $WorkerManager::LOGGER->('Gearman', sprintf('job completed: %s', ref $worker));
                },
                on_fail => sub {
                    $WorkerManager::LOGGER->('Gearman', sprintf('job failed: %s', ref $worker));
                },
            );
        }
        $count++;
        sleep $delay;
    }
}

sub terminate {
    my $self = shift;
    $self->{terminate} = 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

WorkerManager::Gearman - Gearman backend for WorkerManager

=head1 LICENSE

Copyright (C) Hatena Co., Ltd..

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

Original implementation written by stanaka.

=cut
