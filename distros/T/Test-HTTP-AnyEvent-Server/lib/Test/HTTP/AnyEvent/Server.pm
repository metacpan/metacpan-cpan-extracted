package Test::HTTP::AnyEvent::Server;
# ABSTRACT: the async counterpart to Test::HTTP::Server


use feature qw(state switch);
use strict;
use utf8;
use warnings qw(all);

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Log;
use AnyEvent::Socket;
use AnyEvent::Util;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Response;
use HTTP::Status;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use POSIX;

no if ($] >= 5.017010), warnings => q(experimental);

#$AnyEvent::Log::FILTER->level('debug');

our $VERSION = '0.013'; # VERSION

my %pool;


has address     => (is => 'ro', isa => Str, default => sub { '127.0.0.1' }, writer => 'set_address');


has port        => (is => 'ro', isa => Int, writer => 'set_port');


has maxconn     => (is => 'ro', isa => Int, default => sub { 10 });


has timeout     => (is => 'ro', isa => Int, default => sub { 60 });


has disable_proxy => (is => 'ro', isa => Bool, default => sub { 1 });


has https       => (is => 'ro', isa => HashRef);


has custom_handler => (is => 'ro', isa => CodeRef);


has forked      => (is => 'ro', isa => Bool, default => sub { 0 });


has forked_pid  => (is => 'ro', isa => Int, writer => 'set_forked_pid');


has server      => (is => 'ro', isa => Ref, writer => 'set_server');


sub BUILD {
    my ($self) = @_;

    ## no critic (RequireLocalizedPunctuationVars)
    @ENV{qw(no_proxy http_proxy https_proxy ftp_proxy all_proxy)} = (q(localhost,127.0.0.1), (q()) x 4)
        if $self->disable_proxy;

    unless ($self->forked) {
        $self->set_server(
            $self->start_server(sub {
                my (undef, $address, $port) = @_;
                $self->set_address($address);
                $self->set_port($port);
                AE::log info =>
                    'bound to ' . $self->uri;
            })
        );
    } else {
        my ($rh, $wh) = portable_pipe;

        given (fork) {
            when (undef) {
                AE::log fatal =>
                    "couldn't fork(): $!";
            } when (0) {
                # child
                close $rh;

                my $h = AnyEvent::Handle->new(
                    fh          => $wh,
                    on_error    => sub {
                        AE::log fatal =>
                            "couldn't syswrite() to pipe: $!";
                    },
                );

                $self->set_server(
                    $self->start_server(sub {
                        my (undef, $address, $port) = @_;
                        # have to postpone so the address/port gets actually bound
                        AE::postpone { $h->push_write(join("\t", $address, $port)) };
                    })
                );

                AE::cv->wait;
                POSIX::_exit(0);
                exit 1;
            } default {
                # parent
                my $pid = $_;
                close $wh;

                my $buf;
                my $len = sysread $rh, $buf, 65536;
                AE::log fatal =>
                    "couldn't sysread() from pipe: $!"
                        if not defined $len or not $len;

                my ($address, $port) = split m{\t}x, $buf;
                $self->set_address($address);
                $self->set_port($port);
                $self->set_forked_pid($pid);
                AE::log info =>
                    "forked as $pid and bound to " . $self->uri;
            }
        }
    }

    return;
}

sub DEMOLISH {
    my ($self) = @_;

    if ($self->forked) {
        my $pid = $self->forked_pid;
        kill 9 => $pid;
        AE::log info =>
            "killed $pid";
    }

    return;
}


sub uri {
    my ($self) = @_;
    return sprintf(
        '%s://%s:%d/',
        ($self->https ? 'https' : 'http'),
        $self->address,
        $self->port,
    );
}


sub start_server {
    my ($self, $cb) = @_;

    return tcp_server(
        $self->address => $self->port,
        sub {
            my ($fh, $host, $port) = @_;
            if (scalar keys %pool > $self->maxconn) {
                AE::log error =>
                    "deny connection from $host:$port (too many connections)\n";
                return;
            } else {
                AE::log warn =>
                    "new connection from $host:$port\n";
            }

            my $h = AnyEvent::Handle->new(
                fh          => $fh,
                on_eof      => \&_cleanup,
                on_error    => \&_cleanup,
                timeout     => $self->timeout,
                ($self->https ? (tls_ctx => $self->https) : ()),
            );

            $h->push_read(tls_autostart => 'accept') if $self->https;

            $pool{fileno($fh)} = $h;
            AE::log debug =>
                sprintf "%d connection(s) in pool\n", scalar keys %pool;

            $self->_start($h);
        } => $cb
    );
}


sub _start {
    my ($self, $my_handle) = @_;
    return $my_handle->push_read(regex => qr{(\015?\012){2}}x, sub {
        my ($h, $data) = @_;
        my ($req, $hdr) = split m{\015?\012}x, $data, 2;
        $req =~ s/\s+$//sx;
        AE::log debug => "request: [$req]\n";
        if ($hdr =~ m{\bContent-length:\s*(\d+)\b}isx) {
            AE::log debug => "expecting content\n";
            $h->push_read(chunk => int($1), sub {
                my ($_h, $_data) = @_;
                $self->_reply($_h, $req, $hdr, $_data);
            });
        } else {
            $self->_reply($h, $req, $hdr);
        }
    });
}


sub _cleanup {
    my ($h) = @_;
    AE::log debug => "closing connection\n";
    my $r = eval {
        ## no critic (ProhibitNoWarnings)
        no warnings;

        my $id = fileno($h->{fh});
        delete $pool{$id};
        shutdown $h->{fh}, 2;

        return 1;
    };
    AE::log warn => "shutdown() aborted\n"
        if not defined $r or $@;
    $h->destroy;
    return;
}


sub _reply {
    my ($self, $h, $req, $hdr, $content) = @_;
    state $timer = {};

    my $res = HTTP::Response->new(
        &HTTP::Status::RC_OK ,=> undef,
        HTTP::Headers->new(
            Connection      => 'close',
            Content_Type    => 'text/plain',
            Server          => __PACKAGE__ . "/@{[ $Test::HTTP::AnyEvent::Server::VERSION // 0 ]} AnyEvent/$AE::VERSION Perl/$] ($^O)",
        )
    );
    $res->date(time);
    $res->protocol('HTTP/1.0');

    if ($req =~ m{^(GET|POST)\s+(.+)\s+(HTTP/1\.[01])$}ix) {
        my ($method, $uri, $protocol) = ($1, $2, $3);
        AE::log debug => "sending response to $method ($protocol)\n";
        AE::log debug => "simulating connection to $1\n"
            if $uri =~ s{^(https?://[^/]+)}{}ix;
        for ($uri) {
            when (m{^/repeat/(\d+)/(.+)}x) {
                $res->content($2 x $1);
            } when (m{^/echo/head$}x) {
                $res->content(
                    join(
                        "\015\012",
                        qq($method $uri $protocol),
                        $hdr,
                    )
                );
            } when (m{^/echo/body$}x) {
                $res->content($content);
            } when (m{^/delay/(\d+)$}x) {
                $res->content(sprintf(qq(issued %s\n), scalar gmtime));
                $timer->{$h} = AE::timer $1, 0, sub {
                    delete $timer->{$h};
                    AE::log debug => "delayed response\n";
                    $h->push_write($res->as_string("\015\012"));
                    _cleanup($h);
                };
                return;
            } default {
                my $found;
                if ($self->custom_handler) {
                    $res->request(HTTP::Request->new(
                        $method,
                        $uri,
                        [
                            map {
                                m{^\s*([^:\s]+)\s*:\s*(.*)$}sx
                            } split m{\015?\012}x, $hdr
                        ],
                        $content,
                    ));
                    $found = eval { $self->custom_handler->($res) };
                    if ($@) {
                        AE::log error => "custom_handler died: $@";
                        $res->code(&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
                        $res->content($@);
                        $found = 1;
                    }
                }
                unless ($found) {
                    $res->code(&HTTP::Status::RC_NOT_FOUND);
                    $res->content('Not Found');
                }
            }
        }
    } elsif ($req =~ m{^CONNECT\s+([\w\.\-]+):(\d+)\s+(HTTP/1\.[01])$}ix) {
        my ($peer_host, $peer_port, $protocol) = ($1, $2, $3);
        AE::log debug => "simulating connection to $peer_host:$peer_port ($protocol)\n";
        $res->message('Connection established');
        $h->push_write($res->as_string("\015\012"));
        if ($self->https) {
            AE::log debug => 'attempting to use TLS';
            $h->push_read(tls_autostart => 'accept');
        }
        $self->_start($h);
        return;
    } else {
        AE::log error => "bad request\n";
        $res->code(&HTTP::Status::RC_BAD_REQUEST);
        $res->content('Bad Request');
    }

    $h->push_write($res->as_string("\015\012"));
    _cleanup($h);
    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::HTTP::AnyEvent::Server - the async counterpart to Test::HTTP::Server

=head1 VERSION

version 0.013

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use common::sense;

    use AnyEvent::HTTP;
    use Test::HTTP::AnyEvent::Server;

    my $server = Test::HTTP::AnyEvent::Server->new;
    my $cv = AE::cv;

    $cv->begin;
    http_request GET => $server->uri . q(echo/head), sub {
        my ($body, $hdr) = @_;
        say $body;
        $cv->end;
    };

    $cv->wait;

=head1 DESCRIPTION

This package provides a simple B<NON>-forking HTTP server which can be used for testing HTTP clients.

=head1 ATTRIBUTES

=head2 address

Address to bind the server.
Defaults to C<127.0.0.1>.

=head2 port

Port to bind the server.
Picks the first available by default.

=head2 maxconn

Limit the number of accepted connections to this.
Default: 10.

=head2 timeout

Timeout connection after this number of seconds.
Default: 60.

=head2 disable_proxy

Reset the proxy-controlling environment variables (C<no_proxy>/C<http_proxy>/C<ftp_proxy>/C<all_proxy>).
I guess you don't need a proxy to connect to yourself.
Default: true.

=head2 https

B<(experimental)> Accept both HTTP and HTTPS connections on the same port (depends on L<Net::SSLeay>).
This parameter follows the same rules as the C<tls_ctx> parameter to L<AnyEvent::Handle>.
Note: HTTPS server mandatorily need both certificate and key specified!

=head2 custom_handler

B<(experimental)> Callback for custom request processing.

    my $server = Test::HTTP::AnyEvent::Server->new(
        custom_handler => sub {
            # HTTP::Response instance
            my ($response) = @_;
            # also carries HTTP::Request!
            if ($response->request->uri eq '/hello') {
                $response->content('world');
                return 1;
            } else {
                # 404 - Not Found
                return 0;
            }
        },
    );

=head2 forked

B<(experimental)> Sometimes, you just need to test some blocking code.
Setting this flag to true will start L<Test::HTTP::AnyEvent::Server> in a forked process.

=head2 forked_pid

B<(internal)> Holds the PID of a child process if L</forked> flag was used.

=head2 server

B<(internal)> Holds the guard object whose lifetime it tied to the TCP server.

=head1 METHODS

=head2 uri

Return URI of a newly created server (with a trailing C</>).

=head2 start_server($prepare_cb)

B<(internal)> Wrapper for the C<tcp_server> from L<AnyEvent::Socket>.
C<$prepare_cb> is used to get the IP address and port of the local socket endpoint and populate respective attributes.

=head2 _start

B<(internal)> Start processing the request

=head2 _reply

B<(internal)> Issue HTTP reply.

=head1 FUNCTIONS

=head2 _cleanup

B<(internal)> Close descriptor and shutdown connection.

=head1 INTERFACE

Mostly borrowed from L<Test::HTTP::Server>.

=head2 GET /echo/head

Echoes back the issued HTTP request (except the content part):

    $ curl -v http://127.0.0.1:44721/echo/head
    * About to connect() to 127.0.0.1 port 44721 (#0)
    *   Trying 127.0.0.1...
    * connected
    * Connected to 127.0.0.1 (127.0.0.1) port 44721 (#0)
    > GET /echo/head HTTP/1.1
    > User-Agent: curl/7.27.0
    > Host: 127.0.0.1:44721
    > Accept: */*
    >
    * HTTP 1.0, assume close after body
    < HTTP/1.0 200 OK
    < Connection: close
    < Date: Mon, 15 Oct 2012 19:18:54 GMT
    < Server: Test::HTTP::AnyEvent::Server/0.003 AnyEvent/7.02 Perl/5.016001 (linux)
    < Content-Type: text/plain
    <
    GET /echo/head HTTP/1.1
    User-Agent: curl/7.27.0
    Host: 127.0.0.1:44721
    Accept: */*

    * Closing connection #0

=head2 GET /echo/body

Echoes back the content part of an issued HTTP POST request:

    $ curl -v -d param1=value1 -d param2=value2 http://127.0.0.1:44721/echo/body
    * About to connect() to 127.0.0.1 port 44721 (#0)
    *   Trying 127.0.0.1...
    * connected
    * Connected to 127.0.0.1 (127.0.0.1) port 44721 (#0)
    > POST /echo/body HTTP/1.1
    > User-Agent: curl/7.27.0
    > Host: 127.0.0.1:44721
    > Accept: */*
    > Content-Length: 27
    > Content-Type: application/x-www-form-urlencoded
    >
    * upload completely sent off: 27 out of 27 bytes
    * HTTP 1.0, assume close after body
    < HTTP/1.0 200 OK
    < Connection: close
    < Date: Mon, 15 Oct 2012 19:19:50 GMT
    < Server: Test::HTTP::AnyEvent::Server/0.003 AnyEvent/7.02 Perl/5.016001 (linux)
    < Content-Type: text/plain
    <
    * Closing connection #0
    param1=value1&param2=value2

=head2 GET /repeat/5/PADDING

Mindlessly repeat the specified pattern:

    $ curl -v http://127.0.0.1:44721/repeat/5/PADDING
    * About to connect() to 127.0.0.1 port 44721 (#0)
    *   Trying 127.0.0.1...
    * connected
    * Connected to 127.0.0.1 (127.0.0.1) port 44721 (#0)
    > GET /repeat/5/PADDING HTTP/1.1
    > User-Agent: curl/7.27.0
    > Host: 127.0.0.1:44721
    > Accept: */*
    >
    * HTTP 1.0, assume close after body
    < HTTP/1.0 200 OK
    < Connection: close
    < Date: Mon, 15 Oct 2012 19:21:12 GMT
    < Server: Test::HTTP::AnyEvent::Server/0.003 AnyEvent/7.02 Perl/5.016001 (linux)
    < Content-Type: text/plain
    <
    * Closing connection #0
    PADDINGPADDINGPADDINGPADDINGPADDING

=head2 GET /delay/5

Holds the response for a specified number of seconds.
Useful to test the timeout routines:

    $ curl -v http://127.0.0.1:44721/delay/5 && date
    * About to connect() to 127.0.0.1 port 44721 (#0)
    *   Trying 127.0.0.1...
    * connected
    * Connected to 127.0.0.1 (127.0.0.1) port 44721 (#0)
    > GET /delay/5 HTTP/1.1
    > User-Agent: curl/7.27.0
    > Host: 127.0.0.1:44721
    > Accept: */*
    >
    * HTTP 1.0, assume close after body
    < HTTP/1.0 200 OK
    < Connection: close
    < Date: Mon, 15 Oct 2012 19:24:05 GMT
    < Server: Test::HTTP::AnyEvent::Server/0.003 AnyEvent/7.02 Perl/5.016001 (linux)
    < Content-Type: text/plain
    <
    * Closing connection #0
    issued Mon Oct 15 19:24:05 2012
    Mon Oct 15 16:24:10 BRT 2012

B<P.S.> - not present in L<Test::HTTP::Server>.

B<P.P.S.> - setting the C<delay> value below the L</timeout> value is quite pointless.

=for Pod::Coverage BUILD
DEMOLISH

=head1 TODO

=over 4

=item *

Implement C<cookie>/C<index> routes from L<Test::HTTP::Server>;

=item *

Test edge cases for L</forked>.

=back

=head1 SEE ALSO

=over 4

=item *

L<Test::HTTP::Server>

=back

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTOR

Сергей Романов <sromanov-dev@yandex.ru>

=cut
