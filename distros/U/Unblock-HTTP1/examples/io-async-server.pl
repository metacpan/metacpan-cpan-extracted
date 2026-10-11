#!/usr/bin/env perl
use strict;
use warnings;

use IO::Async::Listener;
use IO::Async::Loop;
use Unblock::HTTP1::Server;

# --------------------------------------------------
# ADAPTER: an IO::Async::Stream with HTTP built in
# --------------------------------------------------

package My::HTTPStream;
use parent 'IO::Async::Stream';

sub new {
    my ($class, %args) = @_;

    my $on_request = delete $args{on_request}
        or die "on_request is required\n";

    my $self = $class->SUPER::new(
        %args,
        close_on_read_eof => 0,
    );

    $self->{http} = Unblock::HTTP1::Server->new(
        transport  => $self,
        on_request => $on_request,
    );

    return $self;
}

sub on_read {
    my ($self, $buffer, $eof) = @_;

    if (length $$buffer) {
        my $bytes = $$buffer;
        $$buffer = '';
        $self->{http}->input($bytes);
    }

    if ($eof && !$self->{http}->is_closed
             && !$self->{http}->is_switched) {
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
    return; # IO::Async owns the complete output queue.
}

sub unblock_finish { $_[0]->close_when_empty; return }
sub unblock_abort  { $_[0]->close_now; return }

package main;

# --------------------------------------------------
# APPLICATION: ordinary HTTP server
# --------------------------------------------------

my $on_request = sub {
    my ($tx, $request) = @_;

    $tx->respond(
        status => 200,
        body   => "hello from IO::Async\n",
    );
};

my $port = shift || 8080;
die "usage: $0 [PORT]\n"
    unless $port =~ /\A[0-9]+\z/ && $port >= 1 && $port <= 65535;

my $loop = IO::Async::Loop->new;

my $listener = IO::Async::Listener->new(
    on_accept => sub {
        my ($listener, $socket) = @_;

        my $stream = My::HTTPStream->new(
            handle     => $socket,
            on_request => $on_request,
        );

        $loop->add($stream);
    },
);

$loop->add($listener);
$listener->listen(service => $port, socktype => 'stream')->get;

print "listening on port $port\n";
$loop->run;
