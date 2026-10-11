#!/usr/bin/env perl
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket qw(tcp_server);
use Scalar::Util qw(refaddr);
use Unblock::HTTP2::Server;

# ADAPTER CODE: the Handle subclass owns HTTP protocol state.
package Local::HTTPHandle;
use parent 'AnyEvent::Handle';
use Scalar::Util qw(refaddr);
our %active;

sub new {
    my ($class, %args) = @_;
    my $on_request = delete $args{on_request};
    my $self = $class->SUPER::new(
        %args,
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
    $self->{http2} = Unblock::HTTP2::Server->new(
        transport => $self, on_request => $on_request,
    );
    $active{refaddr($self)} = $self;
    return $self;
}

sub unblock_send {
    my ($self, $bytes) = @_;
    $self->push_write($bytes);
    return; # AnyEvent owns the complete queued buffer.
}

sub unblock_finish {
    my ($self) = @_;
    $self->on_drain(sub {
        my ($handle) = @_;
        delete $active{refaddr($handle)};
        $handle->destroy;
    });
    return;
}

sub unblock_abort {
    my ($self) = @_;
    delete $active{refaddr($self)};
    $self->destroy;
    return;
}

package main;

# APPLICATION CODE: no adapter operations here.
my $on_request = sub {
    my ($tx, $request) = @_;
    $tx->respond(
        status => 200,
        headers => [ [ 'Content-Type' => 'text/plain' ] ],
        body => "hello from AnyEvent\n",
    );
};

my $port = shift || 8080;
die "usage: $0 [PORT]\n"
    unless $port =~ /\A[0-9]+\z/ && $port >= 1 && $port <= 65535;

my $server = tcp_server undef, $port, sub {
    my ($socket) = @_;
    Local::HTTPHandle->new(fh => $socket, on_request => $on_request);
};

print "HTTP/2 prior-knowledge server listening on port $port\n";
AnyEvent->condvar->recv;
