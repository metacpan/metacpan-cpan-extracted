package WebService::TypeSafe::RetryPolicy;

use strict;
use warnings;
use Carp qw(croak);

sub new {
    my ($class, @args) = @_;
    my %args = @args == 1 && ref($args[0]) eq 'HASH' ? %{ $args[0] } : @args;
    my $self = {
        max_retries       => 2,
        backoff_initial   => 0.5,
        backoff_max       => 8,
        backoff_jitter    => 0.25,
        http_statuses     => { map { $_ => 1 } qw(408 409 429 500 502 503 504 529) },
        respect_retry_after => 1,
        connection_errors => 1,
        timeout           => undef,
        %args,
    };
    croak 'max_retries must be a nonnegative integer'
        unless $self->{max_retries} =~ /^\d+$/;
    for my $name (qw(backoff_initial backoff_max backoff_jitter)) {
        croak "$name must be a nonnegative number"
            unless defined($self->{$name}) && $self->{$name} =~ /^\d+(?:\.\d+)?$/;
    }
    croak 'backoff_jitter must be between 0 and 1' if $self->{backoff_jitter} > 1;
    if (ref($self->{http_statuses}) eq 'ARRAY') {
        $self->{http_statuses} = { map { $_ => 1 } @{ $self->{http_statuses} } };
    }
    croak 'http_statuses must be an array or hash reference'
        unless ref($self->{http_statuses}) eq 'HASH';
    return bless $self, $class;
}

sub should_retry_status { return !!$_[0]->{http_statuses}{ $_[1] } }
sub max_retries { $_[0]->{max_retries} }
sub timeout { $_[0]->{timeout} }

sub delay {
    my ($self, $retry_number, $headers) = @_;
    $headers ||= {};
    if ($self->{respect_retry_after}) {
        my $ms = $headers->{'retry-after-ms'};
        return $ms / 1000 if defined($ms) && $ms =~ /^\d+(?:\.\d+)?$/;
        my $seconds = $headers->{'retry-after'};
        return $seconds if defined($seconds) && $seconds =~ /^\d+(?:\.\d+)?$/;
    }
    my $delay = $self->{backoff_initial} * (2 ** ($retry_number - 1));
    $delay = $self->{backoff_max} if $delay > $self->{backoff_max};
    $delay *= 1 - rand($self->{backoff_jitter}) if $self->{backoff_jitter};
    return $delay;
}

1;
