package Unblock::HTTP::_Session;

use strict;
use warnings;
use Carp qw(croak);
use Unblock::HTTP::_EngineFactory;

my %ENGINE = (
    'http/1.1' => 'Unblock::HTTP1',
    'h2'       => 'Unblock::HTTP2',
    'h3'       => 'Unblock::HTTP3',
);

sub _new {
    my ($class, $role, %option) = @_;

    my $protocol = delete $option{protocol};
    my $alpn     = delete $option{alpn};

    croak 'new(): specify either protocol or alpn, not both'
        if defined($protocol) && defined($alpn);

    my $has_quic = defined $option{quic};
    my $has_transport = defined $option{transport};

    croak 'new(): cannot supply both quic and transport'
        if $has_quic && $has_transport;

    if (!defined $protocol) {
        $protocol = defined($alpn) && length($alpn)
            ? $alpn : $has_quic ? 'h3' : 'http/1.1';
    }

    croak 'new(): protocol must be a scalar' if ref $protocol;
    croak "new(): unsupported HTTP protocol '$protocol'"
        unless exists $ENGINE{$protocol};

    if ($protocol eq 'h3') {
        croak 'new(): HTTP/3 requires quic, not a byte transport'
            unless $has_quic && !$has_transport;
    } else {
        croak "new(): $protocol requires a byte transport, not quic"
            if $has_quic;
    }

    my $backend = Unblock::HTTP::_EngineFactory->create(
        $role, $protocol, %option,
    );

    return bless {
        protocol => $protocol,
        backend  => $backend,
    }, $class;
}

sub protocol { return $_[0]{protocol} }
sub backend  { return $_[0]{backend} }

sub _stream_backend {
    my ($self, $method) = @_;
    croak "$method(): HTTP/3 uses QUIC streams, not TCP byte input/output"
        if $self->{protocol} eq 'h3';
    return $self->{backend};
}

sub input {
    my ($self, @arg) = @_;
    return $self->_stream_backend('input')->input(@arg);
}

sub input_eof {
    my ($self, @arg) = @_;
    return $self->_stream_backend('input_eof')->input_eof(@arg);
}

sub transport_error {
    my ($self, @arg) = @_;
    return $self->_stream_backend('transport_error')->transport_error(@arg);
}

sub resume_output {
    my ($self, @arg) = @_;
    return $self->_stream_backend('resume_output')->resume_output(@arg);
}

sub want_read {
    my ($self, @arg) = @_;
    return $self->_stream_backend('want_read')->want_read(@arg);
}

sub want_write {
    my ($self, @arg) = @_;
    return $self->_stream_backend('want_write')->want_write(@arg);
}

sub output {
    my ($self, @arg) = @_;
    return $self->_stream_backend('output')->output(@arg);
}

sub close {
    my ($self, @arg) = @_;
    return $self->_stream_backend('close')->close(@arg);
}

sub start {
    my ($self) = @_;
    $self->{backend}->start if $self->{protocol} eq 'h3';
    return $self;
}

sub started {
    my ($self) = @_;
    return $self->{protocol} eq 'h3'
        ? $self->{backend}->started : 1;
}

1;
