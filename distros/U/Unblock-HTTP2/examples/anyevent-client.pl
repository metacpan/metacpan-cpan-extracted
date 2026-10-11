#!/usr/bin/env perl
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket qw(tcp_connect);
use Unblock::HTTP2::Client;

# ADAPTER CODE: the Handle subclass contains an HTTP client engine.
package Local::HTTPClientHandle;
use parent 'AnyEvent::Handle';

sub new {
    my ($class, %arg) = @_;
    my $self = $class->SUPER::new(
        %arg,
        on_read => sub {
            my ($handle) = @_;
            my $bytes = $handle->rbuf;
            $handle->rbuf = '';
            $handle->{http2}->input($bytes)
                if length($bytes) && $handle->{http2};
        },
        on_eof => sub {
            my ($handle) = @_;
            $handle->{http2}->input_eof
                if $handle->{http2} && !$handle->{http2}->is_closed;
        },
        on_error => sub {
            my ($handle, $fatal, $error) = @_;
            $handle->{http2}->transport_error($error)
                if $handle->{http2};
        },
    );
    $self->{http2} = Unblock::HTTP2::Client->new(transport => $self);
    return $self;
}

sub unblock_send {
    my ($self, $bytes) = @_;
    $self->push_write($bytes);
    return;
}

sub unblock_finish {
    my ($self) = @_;
    $self->on_drain(sub { $_[0]->destroy });
    return;
}

sub unblock_abort { $_[0]->destroy; return }

package main;

my $port = shift || 8080;
die "usage: $0 [PORT]\n"
    unless $port =~ /\A[0-9]+\z/ && $port >= 1 && $port <= 65535;

my $done = AnyEvent->condvar;
my $active_handle; # Keep this Handle alive until the HTTP request completes.
my $connection = tcp_connect '127.0.0.1', $port, sub {
    my ($socket) = @_;
    die "could not connect: $!\n" unless $socket;
    $active_handle = Local::HTTPClientHandle->new(fh => $socket);

    # APPLICATION CODE: a request uses only HTTP names and callbacks.
    $active_handle->{http2}->request(
        method => 'GET',
        target => '/',
        authority => '127.0.0.1:' . $port,
        scheme => 'http',
        on_response => sub {
            my ($tx, $response) = @_;
            print "HTTP status: ", $response->status, "\n";
        },
        on_body => sub {
            my ($tx, $response, $bytes) = @_;
            print $bytes;
        },
        on_complete => sub { $done->send },
        on_error => sub { die "HTTP request failed: $_[1]\n" },
    );
};
$done->recv;
