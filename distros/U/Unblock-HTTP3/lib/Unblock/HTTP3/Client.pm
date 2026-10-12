package Unblock::HTTP3::Client;

use strict;
use warnings;
use Carp qw(croak);
use Uniform::HTTP::Request 0.06 ();

use parent 'Unblock::HTTP3::Connection';

our $VERSION = '0.12';

sub new {
    my ($class, %option) = @_;
    return $class->_new('client', %option);
}

sub request {
    my ($self, @arg) = @_;

    my ($request, %option);
    if (@arg && ref($arg[0])) {
        $request = shift @arg;
        croak 'request(): options must be key/value pairs' if @arg % 2;
        %option = @arg;
    } else {
        croak 'request(): fields must be key/value pairs' if @arg % 2;
        my %field = @arg;
        for my $name (qw(
            stream_body receive_body datagrams early_data
            on_informational on_response on_body on_complete on_error on_drain
        )) {
            $option{$name} = delete $field{$name} if exists $field{$name};
        }
        $request = Uniform::HTTP::Request->new(%field);
    }

    return $self->SUPER::request($request, %option);
}

1;

__END__

=head1 NAME

Unblock::HTTP3::Client - one non-blocking HTTP/3 client connection

=head1 SYNOPSIS

    use Unblock::HTTP3::Client;

    # $quic is a ready Net::QUIC::Connection.
    my $client = Unblock::HTTP3::Client->new(quic => $quic);
    $client->start;

    my $tx = $client->request(
        method    => 'GET',
        target    => '/',
        scheme    => 'https',
        authority => 'localhost',
        on_response => sub {
            my ($tx, $response) = @_;
            print $response->status, "\n";
        },
        on_body => sub {
            my ($tx, $response, $bytes) = @_;
            print $bytes;
        },
        on_complete => sub {
            my ($tx) = @_;
            print "complete\n";
        },
        on_error => sub {
            my ($tx, $error, $code) = @_;
            warn "HTTP/3 request failed: $error\n";
        },
    );

=head1 DESCRIPTION

One Client owns HTTP/3 protocol state on one existing Net::QUIC connection.
Several Transactions can run at once on the same connection.

This class does not open UDP sockets, perform TLS handshakes, choose timers,
or run an event loop. Use L<Unblock::HTTP3::Integration> to connect an event
framework through Net::QUIC::Driver.

HTTP/3 response messages are canonical Uniform::HTTP::Response objects.

=head1 CONSTRUCTOR

=head2 new

    my $client = Unblock::HTTP3::Client->new(
        quic => $quic,
    );

C<quic> is required and must be a L<Net::QUIC::Connection>.

Useful optional constructor settings include C<receive_body>,
C<send_buffer_limit>, C<max_field_section_size>,
C<max_buffered_body_bytes>, C<max_streaming_body_bytes>,
C<qpack_max_table_capacity>, C<qpack_blocked_streams>,
C<enable_http_datagrams>, and C<remembered_peer_settings>.

The connection can be created before QUIC is ready, but for ordinary 1-RTT
operation call C<start()> only after C<$quic-E<gt>ready> is true.

=head1 REQUESTS

=head2 request

    my $tx = $client->request(
        method    => 'GET',
        target    => '/resource',
        scheme    => 'https',
        authority => 'example.com',
        on_response => sub { ... },
    );

Returns an L<Unblock::HTTP3::Transaction>. Request fields are used to
construct a canonical Uniform::HTTP::Request. The existing object form is
also accepted:

    my $tx = $client->request(
        $uniform_request,
        on_response => sub { ... },
    );

Object identity is retained for the object form. HTTP/3 validates request
semantics, pseudo-headers and any explicit protocol version.

The following keys are request options, not Uniform message fields:

    stream_body
    receive_body
    datagrams
    early_data
    on_informational
    on_response
    on_body
    on_complete
    on_error
    on_drain

C<stream_body =E<gt> 1> starts an outbound streaming request body. Do not
combine it with an already-buffered request body.

    my $tx = $client->request(
        method => 'POST', target => '/upload', scheme => 'https',
        authority => 'example.com', stream_body => 1,
    );

    $tx->write("first chunk");
    $tx->end("final chunk");

An C<on_body> callback automatically selects streaming response delivery.
Without it, received response bodies are buffered on the Uniform message,
unless C<receive_body> explicitly selects streaming mode. The advanced
C<receive_body> hash form configures a Body::Reader.

=head1 REQUEST CALLBACKS

=over 4

=item C<on_informational($tx, $response)>

Called for 1xx response headers before a final response. HTTP/3 does not
use status 101.

=item C<on_response($tx, $response)>

Called when final response headers arrive. The response body may still be
incomplete at that point.

=item C<on_body($tx, $response, $bytes)>

Called for incoming response body chunks in streaming mode.

=item C<on_complete($tx)>

Called when the HTTP/3 Transaction has completed.

=item C<on_error($tx, $error, $error_code)>

Called when a Transaction fails. The numeric code is an HTTP/3 or stream
diagnostic when one is available.

=item C<on_drain($tx)>

Used with C<stream_body =E<gt> 1>. Called when outbound body production can
resume after backpressure.

=back

An application may also use the advanced pull and Body::Reader interfaces
instead of the common callback style.

=head1 CONNECTION METHODS

=head2 start

Starts HTTP/3 control streams and installs the QUIC stream-activity handlers.
For ordinary requests, the Net::QUIC connection must be ready first.

=head2 next_transaction

Pulls the next Transaction available from the engine. The callback API does
not require polling.

=head2 next_informational

Pulls the next informational-response notification when using the low-level
polling interface.

=head2 quic

Returns the underlying Net::QUIC::Connection.

=head2 started

True once HTTP/3 has started.

=head2 failed

True if the HTTP/3 connection has failed.

=head2 error

Returns the HTTP/3 connection failure message, if any.

=head2 error_code

Returns the associated failure code, if any.

=head1 HTTP/3 FEATURES

HTTP Datagrams, Capsules, Extended CONNECT, priorities, and 0-RTT are
supported through the connection or Transaction objects. Request 0-RTT
requires an explicit C<early_data =E<gt> 1> and compatible remembered settings.
Early requests can be replayed; retries are not automatic.

See L<Unblock::HTTP3::Connection> for settings, shutdown, ORIGIN and extension
controls. See L<Unblock::HTTP3::Transaction> for request-stream state.

=head1 SEE ALSO

L<Unblock::HTTP3::Integration>, L<Unblock::HTTP3::Server>,
L<Unblock::HTTP3::Transaction>, L<Uniform::HTTP::Request>,
L<Net::QUIC::Driver>

=head1 LICENSE

MIT License.

=cut
