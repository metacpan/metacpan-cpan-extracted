package Unblock::HTTP1;

use strict;
use warnings;

our $VERSION = '0.12';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;


__END__

=head1 NAME

Unblock::HTTP1 - Portable non-blocking HTTP/1.0 and HTTP/1.1 engine

=head1 SYNOPSIS

Server application:

    use Unblock::HTTP1::Server;

    my $server = Unblock::HTTP1::Server->new(
        transport => $stream,
        on_request => sub {
            my ($tx, $request) = @_;
            $tx->respond(status => 200, body => "hello\n");
        },
    );

Client application:

    use Unblock::HTTP1::Client;

    my $client = Unblock::HTTP1::Client->new(transport => $stream);
    $client->request(
        method => 'GET', target => '/', authority => 'example.test',
        on_response => sub {
            my ($tx, $response) = @_;
            print $response->status, "\n";
        },
    );

The C<$stream> shown above is an integration-owned framework connection
object implementing three small output methods. For complete, copyable
IO::Async and AnyEvent examples, start with
L<Unblock::HTTP1::Integration>.

=head1 DESCRIPTION

Unblock::HTTP1 parses and serializes HTTP/1.0 and HTTP/1.1. It supports
persistent connections, request and response streaming, trailers,
informational responses, Upgrade, and CONNECT.

The engine does not create sockets, handle DNS, negotiate TLS, choose an
event loop, or manage connection pools.

Each L<Unblock::HTTP1::Server> or L<Unblock::HTTP1::Client> owns HTTP
protocol state for one connection. A L<Unblock::HTTP1::Transaction>
represents one request and its response.

Canonical messages are L<Uniform::HTTP::Request> and
L<Uniform::HTTP::Response>. Normal application code may pass named
request or response fields instead of constructing Uniform objects
explicitly. Existing Uniform objects continue to work.

=head1 HOW TO CONNECT IT

The normal integration style attaches an object from the event framework
that implements:

    unblock_send($bytes)
    unblock_finish()
    unblock_abort($reason)

Incoming bytes go to C<input()>, EOF goes to C<input_eof()>, and a
transport failure goes to C<transport_error()>.

The engine automatically hands off output through C<unblock_send()>,
including output generated later by an asynchronous application callback.

Advanced integrations can omit C<transport> and use the original
C<want_write()> and C<output()> methods. Native transports can use the
borrowed-input C ABI through L<Unblock::HTTP1::NativeABI>.

For the precise host contract, backpressure, shutdown, switching and
working framework subclasses, see L<Unblock::HTTP1::Integration>.

=head1 PUBLIC CLASSES

=over 4

=item L<Unblock::HTTP1::Server>

HTTP/1 server connection, callbacks, response handling and pipelining.

=item L<Unblock::HTTP1::Client>

HTTP/1 client connection, requests, response callbacks and serial
request queueing.

=item L<Unblock::HTTP1::Transaction>

One exchange, body writing, completion, errors and cancellation.

=item L<Unblock::HTTP1::Integration>

Start-here guide for applications and framework integration authors.

=item L<Unblock::HTTP1::NativeABI>

Optional native borrowed-buffer input interface.

=back

=head1 LICENSE

MIT License.

=cut
