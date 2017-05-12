package Ukigumo::Client::Logger;
use strict;
use warnings;
use utf8;
use Ukigumo::Logger;

use Mouse;

has logfh => (
    is       => 'ro',
    required => 1,
);

has branch => (
    is       => 'ro',
    required => 1,
);

has quiet => (
    is       => 'ro',
    required => 1,
);

has _logger => (
    is => 'ro',
    isa => 'Ukigumo::Logger',
    default => sub {
        my $self = shift;
        Ukigumo::Logger->new(prefix => ['[' . $self->branch . ']']);
    },
);

has _format => (
    is => 'ro',
    default => sub {
        return sub {
            my ($time, $type, $message) = @_;
            warn "$time [$type] $message\n";
        };
    },
);

no Mouse;

sub infof {
    my $self = shift;
    $self->_output_log_by('infof', @_);
}

sub warnf {
    my $self = shift;
    $self->_output_log_by('warnf', @_);
}

sub _output_log_by {
    my $self   = shift;
    my $method = shift;

    my $STDERR = *STDERR;

    open my $fh, '>', \my $log;
    local *STDERR = $fh;

    local $Log::Minimal::PRINT = $self->_format;
    $self->_logger->$method(@_);

    my $logfh = $self->logfh;
    print $logfh $log;

    unless ($self->quiet) {
        local *STDERR = $STDERR;
        warn $log;
    }
}

1;

