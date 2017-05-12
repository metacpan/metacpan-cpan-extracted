package Helm::Log;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints qw(enum);
use namespace::autoclean;

enum LOG_LEVEL => qw(debug info warn error);
has channels => (
    is      => 'ro',
    writer  => '_channels',
    isa     => 'ArrayRef[Helm::Log::Channel]',
    default => sub { [] },
);
has log_level => (
    is      => 'ro',
    writer  => '_log_level',
    isa     => 'LOG_LEVEL',
    default => 'info',
);

sub add_channel {
    my ($self, $channel) = @_;
    push(@{$self->channels}, $channel);
}

sub initialize {
    my ($self, $helm) = @_;
    $_->initialize($helm) foreach @{$self->channels};
}

sub finalize {
    my ($self, $helm) = @_;
    $_->finalize($helm) foreach @{$self->channels};
}

sub parallelize {
    my ($self, $helm) = @_;
    $_->parallelize($helm) foreach @{$self->channels};
}

sub start_server {
    my ($self, $server, $task) = @_;
    $_->start_server($server, $task) foreach @{$self->channels};
}

sub end_server {
    my ($self, $server, $task) = @_;
    $_->end_server($server, $task) foreach @{$self->channels};
}

sub forked {
    my ($self, $type) = @_;
    $_->forked($type) foreach @{$self->channels};
}

sub debug {
    my ($self, $msg) = @_;
    if( $self->log_level eq 'debug' ) {
        $_->debug($msg) foreach @{$self->channels};
    }
}

sub info {
    my ($self, $msg) = @_;
    if($self->log_level eq 'debug' || $self->log_level eq 'info') {
        $_->info($msg) foreach @{$self->channels};
    }
}

sub warn {
    my ($self, $msg) = @_;
    my @channels = @{$self->channels};
    if( @channels ) {
        $_->warn($msg) foreach @channels;
    } else {
        # make sure something happens even if we don't have any channels.
        warn("Warning: $msg");
    }
}

sub error {
    my ($self, $msg) = @_;
    my @channels = @{$self->channels};
    if( @channels ) {
        $_->error($msg) foreach @channels;
    } else {
        # make sure something happens even if we don't have any channels.
        die("Error: $msg");
    }
}

__PACKAGE__->meta->make_immutable;

1;
