package Unblock::HTTP3::Server;

use strict;
use warnings;

use parent 'Unblock::HTTP3::Connection';

our $VERSION = '0.14';

sub new {
    my ($class, %option) = @_;
    return $class->_new('server', %option);
}

1;

__END__

=head1 NAME

Unblock::HTTP3::Server - one non-blocking HTTP/3 server connection

=head1 SYNOPSIS

    use Unblock::HTTP3::Server;

    # $quic is one accepted, ready Net::QUIC::Connection.
    my $server = Unblock::HTTP3::Server->new(
        quic => $quic,
        on_request => sub {
            my ($tx, $request) = @_;
            $tx->respond(status => 200, body => "hello\n");
        },
    );

    $server->start;

=head1 DESCRIPTION

One Server manages one HTTP/3 connection over an existing Net::QUIC
connection. A single server UDP socket may serve multiple QUIC connections,
each with its own Unblock::HTTP3::Server instance.

The event loop owns the UDP socket and timer. Net::QUIC::Driver owns the
QUIC transport. This class owns HTTP/3 state, including QPACK and request
stream handling.

The application sees canonical Uniform::HTTP::Request objects. It does not
need to build Uniform response objects manually for common replies.

=head1 RECEIVE BODY OPTIONS

C<receive_body> accepts C<buffered> or C<stream>. Buffering remains the default.
C<max_buffered_body_bytes> is a positive byte limit, defaulting to 64 MiB.
Zero does not mean unlimited. Buffered reception installs the body on the
same Uniform message before freezing it and invoking the body-completion
callback. Empty completed bodies have an empty string representation.
The engine releases retained chunks on failure or cancellation.

Select streaming per transaction with C<$tx-E<gt>on_data(...)> during the
header callback. Legacy C<on_body> still selects streaming automatically.
Do not combine C<on_data> and C<on_body>. See
L<Unblock::HTTP3::Transaction/RECEIVE AND FINISH CALLBACKS>.

A buffer limit failure resets only the affected stream.
It does not call successful body completion.

=head1 CONSTRUCTOR

=head2 new

    my $server = Unblock::HTTP3::Server->new(
        quic       => $quic,
        on_request => sub { ... },
    );

C<quic> must be a L<Net::QUIC::Connection>. The callback-style application
normally supplies C<on_request>. Users of the pull API may omit it.

Connection options include C<receive_body>, C<send_buffer_limit>,
C<max_field_section_size>, C<max_buffered_body_bytes>,
C<max_streaming_body_bytes>, C<qpack_max_table_capacity>,
C<qpack_blocked_streams>, C<quic_max_bidi_streams>,
C<enable_extended_connect>, C<enable_http_datagrams>, C<origins>,
C<remembered_local_settings>, and extension options.

=head1 REQUEST CALLBACKS

=over 4

=item C<on_request($tx, $request)>

Called when request headers arrive. The request body may still be arriving.

=item C<on_body($tx, $request, $bytes)>

Called for incoming request body chunks. Supplying C<on_body> selects
streaming request-body reception automatically.

=item C<on_request_end($tx, $request)>

Called when the request body and trailers have completed. This callback
does not independently force streamed or buffered body reception.

=item C<on_error($tx, $error, $error_code)>

Called when a Transaction fails, with the available HTTP/3 or stream code.

=back

C<receive_body> selects the default body ownership model. Without an
C<on_body> callback and with the default buffered mode, the Uniform
request body becomes available as a complete buffer at message end.

=head1 RESPONDING

=head2 respond

Inside an C<on_request> callback, call:

    $tx->respond(status => 200, body => "hello\n");

Or pass an existing Uniform-compatible Response object:

    $tx->respond($uniform_response);

The named form constructs a canonical Uniform::HTTP::Response for you.
C<respond()> sends a final response. It can only be called once for a
Transaction.

=head2 send_informational

    $tx->send_informational(status => 103);

Sends a 1xx response before the final response. Status 101 is not valid
in HTTP/3. A Uniform Response object is also accepted.

=head1 STREAMING RESPONSES

Start an outgoing response body with C<stream_body =E<gt> 1>:

    $tx->respond(
        status      => 200,
        stream_body => 1,
        on_drain    => sub {
            my ($tx) = @_;
            # Resume sending once output pressure has eased.
        },
    );

    $tx->write("first part");
    $tx->end("last part");

C<write()> adds outbound body data. C<end()> sends the last data and finishes
the sending side. Consult L<Unblock::HTTP3::Transaction> for advanced body
readers/writers, cancellation and reset information.

=head1 CONNECTION METHODS

=head2 start

Starts HTTP/3 processing and installs the QUIC stream callbacks. For ordinary
1-RTT operation, call after C<$quic-E<gt>ready> is true.

=head2 next_transaction

Returns the next newly received request Transaction for pull-style users.
Pull-only requests remain strongly queued until retrieved. When C<on_request>
also delivers the Transaction, its queue notification is weak. A mixed
callback/pull consumer may retrieve the live Transaction, but should keep
the callback's Transaction reference if it needs it after the request
becomes terminal and the native stream closes. Callback-only servers do
not retain all completed request bodies through this optional pull queue.

=head2 quic

Returns the underlying Net::QUIC::Connection.

=head2 started

True if HTTP/3 has started.

=head2 failed

True if HTTP/3 has encountered a fatal connection error.

=head2 error

The HTTP/3 connection error message, if any.

=head2 error_code

The corresponding HTTP/3 error code, if any.

=head1 SHUTDOWN AND ADVANCED FEATURES

The Server inherits HTTP/3 graceful shutdown, extension streams, settings,
priority, Capsules, Extended CONNECT, and HTTP Datagrams from
L<Unblock::HTTP3::Connection>. QUIC itself is managed by Net::QUIC.

Each accepted QUIC connection needs its own Server object. Keep it alive until
that QUIC connection closes. See L<Unblock::HTTP3::Integration> and the
complete Linux::Event server example for this lifecycle.

=head1 SEE ALSO

L<Unblock::HTTP3::Integration>, L<Unblock::HTTP3::Client>,
L<Unblock::HTTP3::Transaction>, L<Uniform::HTTP::Response>,
L<Net::QUIC::Driver>

=head1 LICENSE

MIT License.

=cut
