#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event::IO::Sock::Listener;
use Linux::Event::Loop;
use Unblock::HTTP::Server;

# APPLICATION CODE: one definition serves all incoming connections.
my $server = Unblock::HTTP::Server->new(
    http1 => {},
    http2 => {},
    on_request => sub ($tx, $request) {
        $tx->respond(
            status => 200,
            headers => [ [ 'Content-Type' => 'text/plain' ] ],
            body => "hello from Unblock::HTTP\n",
        );
    },
);

# ADAPTER CODE: supply the definition to each framework-owned stream.
package Example::HTTPStream;
use parent 'Linux::Event::IO::Sock::Stream';
use Scalar::Util qw(blessed);

# LOCAL EXAMPLE ADAPTER: this class is not installed or bundled as a module.
sub http { $_[0]{unblock_http} }
sub websocket { $_[0]{unblock_websocket} }

sub on_ready ($self) {
    my $server = $self->http_server;
    die "http_server() must return a shared Unblock::HTTP::Server definition\n"
        unless blessed($server) && $server->isa('Unblock::HTTP::Server');
    my $protocol = $self->http_protocol;
    my %select = defined($protocol)
        ? (protocol => $protocol)
        : (alpn => $self->selected_alpn);
    $self->{unblock_http} = $server->attach_stream(
        transport => $self, %select,
    );
    return;
}

sub unblock_upgrade ($self, $websocket) {
    die "unblock_upgrade(): WebSocket input consumer is required\n"
        unless blessed($websocket) && $websocket->can('input')
            && $websocket->can('input_eof') && $websocket->can('transport_error')
            && $websocket->can('resume_output');
    die "unblock_upgrade(): transport already upgraded\n"
        if $self->{unblock_websocket};
    $self->{unblock_websocket} = $websocket;
    return;
}

sub _consumer ($self) {
    return $self->{unblock_websocket} || $self->{unblock_http};
}

sub on_data ($self, $bytes) {
    $self->_consumer->input($bytes);
}

sub on_eof ($self) {
    my $consumer = $self->_consumer;
    $consumer->input_eof if $consumer && $consumer->want_read;
}

sub on_error ($self, $error) {
    my $consumer = $self->_consumer;
    $consumer->transport_error("$error") if $consumer;
}

sub on_drain ($self) {
    my $consumer = $self->_consumer;
    $consumer->resume_output if $consumer;
}

sub unblock_send ($self, $bytes) {
    my $ready = $self->write($bytes);
    die "Linux::Event stream closed during HTTP output\n" if $self->is_closed;
    return $ready;
}

sub unblock_finish ($self) { $self->end }
sub unblock_abort ($self, $reason) { $self->close }


sub http_server ($self) { $server }
sub http_protocol ($self) { $ENV{UNBLOCK_HTTP_PROTOCOL} }

package main;
my $port = shift // 8080;
die "usage: $0 [PORT]\n"
    unless $port =~ /\A[0-9]+\z/ && $port >= 1 && $port <= 65535;
my $loop = Linux::Event::Loop->new;
my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop, host => '127.0.0.1', port => $port,
    stream => { class => 'Example::HTTPStream' },
);

# This example uses cleartext. Set UNBLOCK_HTTP_PROTOCOL=h2 for H2 prior
# knowledge. For a TLS listener use the framework's ALPN configuration
# with the choices returned by $server->alpn_protocols.
print "HTTP listening on ", $listener->port, "\n";
$loop->run;
