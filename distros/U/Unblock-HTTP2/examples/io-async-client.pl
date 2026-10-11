#!/usr/bin/env perl
use strict;
use warnings;

use IO::Async::Loop;
use Unblock::HTTP2::Client;

# --------------------------------------------------
# ADAPTER: an IO::Async::Stream with an HTTP client
# --------------------------------------------------

package My::HTTPClientStream;
use parent 'IO::Async::Stream';

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(
        %args,
        close_on_read_eof => 0,
    );

    $self->{http} = Unblock::HTTP2::Client->new(transport => $self);
    return $self;
}

sub on_read {
    my ($self, $buffer, $eof) = @_;

    if (length $$buffer) {
        my $bytes = $$buffer;
        $$buffer = '';
        $self->{http}->input($bytes);
    }

    if ($eof && !$self->{http}->is_closed) {
        $self->{http}->input_eof;
    }

    return 0;
}

sub on_read_error {
    my ($self, $error) = @_;
    $self->{http}->transport_error("read error: $error");
}

sub on_write_error {
    my ($self, $error) = @_;
    $self->{http}->transport_error("write error: $error");
}

sub unblock_send {
    my ($self, $bytes) = @_;
    $self->write($bytes);
    return;
}

sub unblock_finish { $_[0]->close_when_empty; return }
sub unblock_abort  { $_[0]->close_now; return }

package main;

# --------------------------------------------------
# APPLICATION: HTTP/2 prior-knowledge client
# --------------------------------------------------

my $port = shift || 8080;
die "usage: $0 [PORT]\n"
    unless $port =~ /\A[0-9]+\z/ && $port >= 1 && $port <= 65535;

my $loop = IO::Async::Loop->new;

my $on_response = sub {
    my ($tx, $response) = @_;
    print "HTTP status: ", $response->status, "\n";
};

my $on_body = sub {
    my ($tx, $response, $bytes) = @_;
    print $bytes;
};

$loop->connect(
    host => '127.0.0.1',
    service => $port,
    socktype => 'stream',
    on_connected => sub {
        my ($socket) = @_;

        my $stream = My::HTTPClientStream->new(handle => $socket);
        $loop->add($stream);

        $stream->{http}->request(
            method      => 'GET',
            target      => '/',
            authority   => '127.0.0.1:' . $port,
            scheme      => 'http',
            on_response => $on_response,
            on_body     => $on_body,
            on_complete => sub { $loop->stop },
            on_error    => sub { die "HTTP request failed: $_[1]\n" },
        );
    },
    on_connect_error => sub {
        my ($operation, $error) = @_;
        die "$operation failed: $error\n";
    },
    on_resolve_error => sub { die "resolve failed: $_[-1]\n" },
);

$loop->run;
