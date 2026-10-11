# Connecting Unblock::HTTP2 to an event loop

Unblock::HTTP2 does not own sockets, TLS, ALPN, or event loops.

Start with the installed documentation:

    perldoc Unblock::HTTP2::Integration

For a runnable Linux::Event example, see examples/linux-event-server.pl.
That example separates ADAPTER CODE from APPLICATION CODE.

## Application side

No explicit Uniform::HTTP objects are necessary:

    $tx->respond(status => 200, body => "hello\n");

    $client->request(
        method    => 'GET',
        target    => '/',
        scheme    => 'https',
        authority => 'example.test',
        on_response => sub {
            my ($tx, $response) = @_;
            print $response->status, "\n";
        },
    );

Uniform::HTTP::Request and Uniform::HTTP::Response objects still work.

## Small framework interface

Your framework stream creates one Client or Server:

    $self->{http2} = Unblock::HTTP2::Server->new(
        transport  => $self,
        on_request => $on_request,
    );

It implements:

    unblock_send($bytes)      # accept ALL wire bytes into its queue
    unblock_finish()          # flush queued bytes, then close
    unblock_abort($reason)    # close immediately

It calls:

    $http->input($bytes);            # decrypted network input
    $http->input_eof;                # peer closed input
    $http->transport_error($error);  # fatal transport failure

Output is handed off automatically; no output polling is necessary.
A response written later by a timer also sends automatically.

unblock_send() must accept the entire buffer or throw. A defined false
return signals congestion AFTER acceptance. Call $http->resume_output
when the host can accept more output. Returning undef means the host
queues everything and provides no congestion signal.

The engine holds the host weakly. The framework owns the socket, TLS,
write queue and connection lifetime.

## HTTP/2 differences from HTTP/1

One attached Client or Server multiplexes many Transactions on one
connection. Cancelling a Transaction resets that stream, not the whole
transport. Server response timing does not depend on input reads.

HTTP/2 messages are never completed by TCP EOF. input_eof closes the
session and fails any unfinished Transactions. Use GOAWAY via drain()
or goaway() for HTTP/2 connection draining.

Flow control remains per-stream and per-connection. A false return
from Transaction->write() means the body bytes were accepted but
production must pause until on_drain.

## Manual output

The low-level API remains for callers that do not attach a host:

    $http->input($bytes);
    while ($http->want_write) {
        my $bytes = $http->output;
        last unless length $bytes;
        $framework->write($bytes);
    }

Do not call output() when a transport is attached.

## Native input and output

XS integrations may use Unblock::HTTP2::NativeABI version 1 instead of the
portable interface. Its borrowed-buffer ownership and sink pause rules
are unchanged by the attached-transport API. Never use both Perl attached
output and the native output sink on the same session.
