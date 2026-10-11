package Unblock::HTTP2;

use strict;
use warnings;

our $VERSION = '0.11';

use constant {
    NO_ERROR            => 0,
    PROTOCOL_ERROR      => 1,
    INTERNAL_ERROR      => 2,
    FLOW_CONTROL_ERROR  => 3,
    SETTINGS_TIMEOUT    => 4,
    STREAM_CLOSED       => 5,
    FRAME_SIZE_ERROR    => 6,
    REFUSED_STREAM      => 7,
    CANCEL              => 8,
    COMPRESSION_ERROR   => 9,
    CONNECT_ERROR       => 10,
    ENHANCE_YOUR_CALM   => 11,
    INADEQUATE_SECURITY => 12,
    HTTP_1_1_REQUIRED   => 13,
};

my @ERROR_NAME = qw(
    NO_ERROR
    PROTOCOL_ERROR
    INTERNAL_ERROR
    FLOW_CONTROL_ERROR
    SETTINGS_TIMEOUT
    STREAM_CLOSED
    FRAME_SIZE_ERROR
    REFUSED_STREAM
    CANCEL
    COMPRESSION_ERROR
    CONNECT_ERROR
    ENHANCE_YOUR_CALM
    INADEQUATE_SECURITY
    HTTP_1_1_REQUIRED
);

sub error_name {
    my ($class, $code) = @_;
    return unless defined($code) && !ref($code)
        && "$code" =~ /\A[0-9]+\z/;
    return $ERROR_NAME[0 + $code];
}

1;

__END__

=head1 NAME

Unblock::HTTP2 - non-blocking HTTP/2 protocol engine for Perl

=head1 SYNOPSIS

    use Unblock::HTTP2::Server;

    # $stream is an accepted connection owned by your event framework.
    my $server = Unblock::HTTP2::Server->new(
        transport  => $stream,
        on_request => sub {
            my ($tx, $request) = @_;
            $tx->respond(status => 200, body => "Hello World!\n");
        },
    );

    # In the framework's read callback:
    $server->input($received_http2_bytes);

    use Unblock::HTTP2::Client;

    # $client_stream is a separate connected framework stream.
    my $client = Unblock::HTTP2::Client->new(
        transport => $client_stream,
    );

    $client->request(
        method    => 'GET',
        target    => '/',
        scheme    => 'https',
        authority => 'example.test',
        on_response => sub {
            my ($tx, $response) = @_;
            print $response->status, "\n";
        },
        on_body => sub {
            my ($tx, $response, $bytes) = @_;
            print $bytes;
        },
    );

Both C<$stream> and C<$client_stream> are framework-owned transport objects.
Each implements C<unblock_send($bytes)>, C<unblock_finish()>, and
C<unblock_abort($reason)>. They feed received bytes with C<input()>.
Outgoing HTTP/2 bytes are sent automatically through C<unblock_send()>.
No C<output()> polling loop is needed in this mode.

For complete, runnable integration examples, see
L<Unblock::HTTP2::Integration> and the F<examples/> directory.

=head1 DESCRIPTION

Unblock::HTTP2 is an HTTP/2 protocol engine.

It handles HTTP/2 framing, HPACK, multiplexed streams, SETTINGS, flow control,
PING, GOAWAY, trailers, CONNECT, and RFC 9218 priority signaling.

It does not own sockets, TLS, ALPN, an event loop, connection pooling, or retry
policy.

HTTP messages are L<Uniform::HTTP::Request> and
L<Uniform::HTTP::Response> objects.

libnghttp2 is used through a small private XS binding contained in this
distribution.

=head1 MODULES

=over 4

=item L<Unblock::HTTP2::Integration>

How to attach an event-framework stream.

=item L<Unblock::HTTP2::Client>

One client HTTP/2 connection.

=item L<Unblock::HTTP2::Server>

One server HTTP/2 connection.

=item L<Unblock::HTTP2::Transaction>

One HTTP request/response transaction carried by an HTTP/2 stream.

=item L<Unblock::HTTP2::NativeABI>

Optional native transport ABI for XS-backed integrations.

=back

=head1 ERROR CODES

The standard HTTP/2 error codes are available as package constants, including
C<NO_ERROR>, C<PROTOCOL_ERROR>, C<REFUSED_STREAM>, and C<CANCEL>.

C<error_name($code)> returns the symbolic name for a known code.

=head1 TRANSPORT BOUNDARY

Create a Client or Server with C<transport =E<gt> $framework_stream>.
The framework provides C<unblock_send()>, C<unblock_finish()>, and
C<unblock_abort()>. Feed received bytes with C<input()>. The engine
automatically delivers outgoing HTTP/2 bytes to the framework.

The previous manual C<want_write()> and C<output()> interface remains
available without an attached transport.

XS-backed transports can instead use L<Unblock::HTTP2::NativeABI>
for borrowed input and native output sinks.

For a complete description of callbacks, backpressure, EOF, and shutdown,
see L<Unblock::HTTP2::Integration>.

=head1 SEE ALSO

L<Uniform::HTTP>, L<Alien::nghttp2>

=head1 LICENSE

MIT License.

=cut
