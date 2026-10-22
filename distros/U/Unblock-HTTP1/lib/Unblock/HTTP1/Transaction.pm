package Unblock::HTTP1::Transaction;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(weaken blessed);
use Uniform::HTTP::Response;

our $VERSION = '0.12';

sub _new {
    my ($class, $owner, $request, %args) = @_;
    my $self = bless {
        owner       => $owner,
        request     => $request,
        response    => undef,
        state       => 'active',
        error       => undef,
        callbacks   => $args{callbacks} || {},
        local_done  => $args{local_done} ? 1 : 0,
        remote_done => $args{remote_done} ? 1 : 0,
        send_plan   => $args{send_plan},
        blocked     => 0,
    }, $class;
    $self->{receive_body} = $owner->{receive_body};
    $self->{max_buffered_body_bytes} = $owner->{max_buffered_body_bytes};
    my $on_data = delete $self->{callbacks}{on_data};
    $self->on_data($on_data) if $on_data;
    croak 'buffered reception cannot be combined with on_body'
        if $self->{receive_body} eq 'buffered' && $self->{callbacks}{on_body};
    weaken($self->{owner});
    return $self;
}

sub request { $_[0]{request} }
sub response { $_[0]{response} }
sub state { $_[0]{state} }
sub error { $_[0]{error} }
sub is_complete { $_[0]{state} eq 'complete' ? 1 : 0 }
sub is_cancelled { $_[0]{state} eq 'cancelled' ? 1 : 0 }
sub is_error { $_[0]{state} eq 'error' ? 1 : 0 }
sub is_terminal { $_[0]{state} ne 'active' ? 1 : 0 }

sub on_data {
    my ($self, $cb) = @_;
    croak 'on_data(): callback must be a coderef' unless ref($cb) eq 'CODE';
    croak 'on_data(): receive body has already started or finished'
        if $self->{receive_started} || $self->{receive_done} || $self->is_terminal;
    my $owner = $self->{owner};
    croak 'on_data(): cannot be combined with on_body'
        if $self->{callbacks}{on_body} || ($owner && $owner->{callbacks}{on_body});
    croak 'on_data(): callback is already registered' if $self->{callbacks}{on_data};
    $self->{callbacks}{on_data} = $cb;
    $self->{receive_body} = 'stream';
    return $self;
}

sub on_finish {
    my ($self, $cb) = @_;
    croak 'on_finish(): callback must be a coderef' unless ref($cb) eq 'CODE';
    croak 'on_finish(): Transaction is terminal' if $self->is_terminal;
    croak 'on_finish(): callback is already registered' if $self->{callbacks}{on_finish};
    $self->{callbacks}{on_finish} = $cb;
    return $self;
}

sub _receive_data {
    my ($self, $message, $bytes) = @_;
    return 1 if $self->is_terminal;
    $self->{receive_started} = 1;
    if ($self->{receive_body} eq 'buffered') {
        my $size = ($self->{received_bytes} || 0) + length($bytes);
        if ($size > $self->{max_buffered_body_bytes}) {
            delete $self->{receive_chunks};
            delete $self->{received_bytes};
            return 'received body exceeds max_buffered_body_bytes';
        }
        push @{ $self->{receive_chunks} }, $bytes;
        $self->{received_bytes} = $size;
        return 1;
    }
    return $self->_invoke('on_data', $bytes) if $self->{callbacks}{on_data};
    my $owner = $self->{owner};
    return $owner->_invoke_server('on_body', $self, $message, $bytes)
        if $owner && $owner->can('_invoke_server');
    return $self->_invoke('on_body', $message, $bytes);
}

sub _finish_receive {
    my ($self, $message) = @_;
    $self->{receive_done} = 1;
    if ($self->{receive_body} eq 'buffered' && $message->body_is_mutable) {
        $message->body(join '', @{ delete($self->{receive_chunks}) || [] });
    }
    delete $self->{receive_chunks};
    delete $self->{received_bytes};
    return;
}

sub _notify_finish {
    my ($self) = @_;
    return unless $self->is_terminal && !$self->{finish_called};
    $self->{finish_pending} = 1;
    return if $self->{callback_depth};
    $self->{finish_called} = 1;
    delete $self->{finish_pending};
    # Terminal observers cannot undo cleanup or recursively report an error.
    $self->_invoke('on_finish');
    return;
}

sub write {
    my ($self, $bytes) = @_;
    croak 'write(): Transaction is terminal' if $self->is_terminal;
    my $owner = $self->{owner} or croak 'write(): HTTP/1 connection is gone';
    return $owner->_transaction_write($self, $bytes, 0);
}

sub end {
    my ($self, $bytes) = @_;
    croak 'end(): Transaction is terminal' if $self->is_terminal;
    my $owner = $self->{owner} or croak 'end(): HTTP/1 connection is gone';
    return $owner->_transaction_write($self, defined($bytes) ? $bytes : '', 1);
}

sub respond {
    my ($self, @arg) = @_;
    croak 'respond(): Transaction is terminal' if $self->is_terminal;
    my $owner = $self->{owner} or croak 'respond(): HTTP/1 connection is gone';

    my ($response, %option);
    if (@arg && ref($arg[0])) {
        $response = shift @arg;
        croak 'respond(): requires a Uniform HTTP response object'
            unless blessed($response) && $response->can('status')
                && $response->can('header_count');
        croak 'respond(): options must be key/value pairs' if @arg % 2;
        %option = @arg;
    } else {
        croak 'respond(): response fields must be key/value pairs' if @arg % 2;
        my %field = @arg;
        for my $name (qw(stream_body on_drain)) {
            $option{$name} = delete $field{$name} if exists $field{$name};
        }
        $response = Uniform::HTTP::Response->new(%field);
    }

    return $owner->_transaction_respond($self, $response, %option);
}

sub send_informational {
    my ($self, @arg) = @_;
    croak 'send_informational(): Transaction is terminal' if $self->is_terminal;
    my $owner = $self->{owner} or croak 'send_informational(): HTTP/1 connection is gone';

    my $response;
    if (@arg && ref($arg[0])) {
        croak 'send_informational(): response object does not take options'
            unless @arg == 1;
        $response = $arg[0];
        croak 'send_informational(): requires a Uniform HTTP response object'
            unless blessed($response) && $response->can('status')
                && $response->can('header_count');
    } else {
        croak 'send_informational(): response fields must be key/value pairs'
            if @arg % 2;
        $response = Uniform::HTTP::Response->new(@arg);
    }

    return $owner->_transaction_informational($self, $response);
}

sub cancel {
    my ($self) = @_;
    return $self if $self->is_terminal;
    my $owner = $self->{owner};
    if ($owner) {
        $owner->_transaction_cancel($self);
    } else {
        $self->_mark_cancelled;
        $self->_notify_finish;
    }
    return $self;
}

sub _set_response { $_[0]{response} = $_[1]; return $_[0] }
sub _mark_local_done { $_[0]{local_done} = 1; return }
sub _mark_remote_done { $_[0]{remote_done} = 1; return }
sub _mark_complete { $_[0]{state} = 'complete'; return }
sub _mark_cancelled { $_[0]->_discard_receive; $_[0]{state} = 'cancelled'; return }
sub _fail { $_[0]->_discard_receive; $_[0]{state} = 'error'; $_[0]{error} = $_[1]; return }

sub _discard_receive {
    delete $_[0]{receive_chunks};
    delete $_[0]{received_bytes};
    return;
}

sub _invoke {
    my ($self, $name, @args) = @_;
    my $cb = $self->{callbacks}{$name} or return 1;
    $self->{callback_depth}++;
    my $ok = eval { $cb->($self, @args); 1 };
    my $error = "$@";
    $self->{callback_depth}--;
    $self->_notify_finish if $self->{finish_pending};
    return $ok ? 1 : $error;
}

1;

__END__

=head1 NAME

Unblock::HTTP1::Transaction - One HTTP/1 request/response exchange

=head1 SYNOPSIS

Server side:

    on_request => sub {
        my ($tx, $request) = @_;

        $tx->respond(
            status => 200,
            body   => "hello\n",
        );
    };

Client side:

    my $tx = $client->request(
        method => 'GET',
        target => '/',
        on_complete => sub {
            my ($tx) = @_;
            print $tx->response->status, "\n";
        },
    );

=head1 RECEIVE AND FINISH CALLBACKS

    $tx->on_data(sub {
        my ($tx, $bytes) = @_;
        consume_chunk($bytes);
    });

Register during the incoming-header callback (server C<on_request> or client
C<on_response>). This selects streaming for this transaction. Only decoded
HTTP body bytes are passed; content encodings such as gzip are not decoded.
No full body is accumulated. Registering after body delivery starts or ends,
registering twice, or combining this callback with C<on_body> is an error.
Client C<request()> also accepts C<on_data> before the request is dispatched.

    $tx->on_finish(sub {
        my ($tx) = @_;
        record_outcome($tx->state, $tx->error);
    });

Runs once after the applicable completion or error callbacks for a terminal
C<complete>, C<cancelled>, or C<error> transaction. The state is committed
before the callback. Cancellation alone does not call C<on_error>.
A completed incoming request can still have an unfinished response; it is
not terminal until both sides required by the engine have finished.

Client C<request()> also accepts C<on_finish>. Register it before the
transaction becomes terminal. Duplicate and late registration are errors.
An exception from this terminal observer is ignored so cleanup and other
transactions can continue. Earlier callbacks keep the engine's exception
policy, but cannot suppress this notification.

=head1 DESCRIPTION

A Transaction represents one HTTP/1 request and its response.

Applications do not construct Transaction objects directly. A client gets one
from C<$client-E<gt>request()>. A server receives one in C<on_request>.

The same class is used on both sides:

=over 4

=item Client Transaction

Owns one outgoing request and the incoming response.

For a streaming request body, C<write()> and C<end()> send request body bytes.

=item Server Transaction

Owns one incoming request and the outgoing response.

C<respond()> starts the final response. For a streaming response body,
C<write()> and C<end()> send response body bytes.

=back

A Transaction does not own the socket or event loop. It delegates wire work to
its owning Client or Server connection.

=head1 MESSAGE ACCESSORS

=head2 request

    my $request = $tx->request;

Returns the canonical L<Uniform::HTTP::Request> for this exchange.

On the client this is the request supplied to, or constructed by,
C<Client-E<gt>request()>.

On the server this is the parsed request delivered by C<on_request>.

=head2 response

    my $response = $tx->response;

Returns the canonical L<Uniform::HTTP::Response> once a final response exists.

Before that point it returns undef.

On a client, the response becomes available when the final response head is
received.

On a server, it becomes available after C<respond()> starts the final response.

Informational responses do not replace the final C<response()> value.

=head1 SERVER RESPONSE METHODS

These methods are meaningful on a server Transaction.

=head2 respond

Concise form:

    $tx->respond(
        status  => 200,
        headers => [
            [ 'Content-Type' => 'text/plain' ],
        ],
        body => "hello\n",
    );

Existing-object form:

    $tx->respond($response);

Starts the final response and returns the Transaction.

The concise form constructs a canonical L<Uniform::HTTP::Response> internally.

C<respond()> may be called before the complete request body has arrived. This
is useful for early rejection or any response which does not depend on the full
request body.

A Transaction can have only one final response.

Informational status codes other than 101 must use
C<send_informational()> instead.

For a streaming response:

    $tx->respond(
        status      => 200,
        stream_body => 1,
        on_drain    => sub {
            produce_more();
        },
    );

The response head is sent immediately and body data is supplied later with
C<write()> and C<end()>.

C<on_drain> is valid only with C<stream_body =E<gt> 1>.

Calling C<respond()> on a client Transaction is an error.

=head2 send_informational

Concise form:

    $tx->send_informational(
        status  => 103,
        headers => [
            [ Link => '</style.css>; rel=preload' ],
        ],
    );

Existing-object form:

    $tx->send_informational($response);

Sends one informational response and returns the Transaction.

The status must be from 100 through 199, except 101. A 101 response is a final
protocol-switch response and uses C<respond()>.

More than one informational response may be sent before the final response.

HTTP/1.0 clients cannot receive informational responses through this method.

Calling C<send_informational()> on a client Transaction is an error.

=head1 STREAMING BODY METHODS

=head2 write

    my $ok = $tx->write($bytes);

Adds one chunk of a streaming body.

On a client Transaction, this writes an outgoing request body.

On a server Transaction, this writes an outgoing response body after
C<respond(stream_body =E<gt> 1)>.

The supplied bytes are accepted even when the return value is false.

A true return means the output path remains writable.

A false return means backpressure is active. The producer should stop creating
more body data and resume from its C<on_drain> callback.

C<write()> is valid only for a transaction created or started with
C<stream_body =E<gt> 1>.

The engine applies HTTP transfer framing. Applications provide body bytes, not
chunk framing.

When Content-Length is explicitly declared, writing more than that length is an
error.

=head2 end

    my $ok = $tx->end;
    my $ok = $tx->end($last_bytes);

Finishes a streaming body.

C<$last_bytes>, when supplied, are accepted as the final body bytes before the
stream is ended.

On a client this finishes the request body.

On a server this finishes the response body.

For chunked HTTP/1.1 output, C<end()> writes the final chunk and any configured
trailers.

For an explicit Content-Length, ending before exactly that many bytes have
been written is an error.

After C<end()> the local streaming body is complete and additional
C<write()> or C<end()> calls are invalid.

The boolean return has the same backpressure meaning as C<write()>.

=head1 CANCELLATION

=head2 cancel

    $tx->cancel;

Cancels the Transaction and returns it.

HTTP/1 transactions share connection ordering and framing state, so
cancellation closes the HTTP/1 connection rather than attempting to skip an
arbitrary exchange in place.

On a client, queued requests which depended on that connection are failed.

Calling C<cancel()> again after the Transaction is terminal is harmless.

Cancellation is distinct from an error. A cancelled Transaction has state
C<cancelled> and C<error()> remains undef.

=head1 STATE

=head2 state

    my $state = $tx->state;

Returns one of:

    active
    complete
    cancelled
    error

C<active> means the exchange is still in progress.

C<complete> means both sides required by the exchange have finished.

C<cancelled> means C<cancel()> terminated the exchange.

C<error> means the exchange failed.

=head2 error

    my $error = $tx->error;

Returns the transaction error string when C<state()> is C<error>.

Returns undef for active, complete, and cancelled Transactions.

=head2 is_complete

    if ($tx->is_complete) { ... }

True only when C<state()> is C<complete>.

=head2 is_cancelled

    if ($tx->is_cancelled) { ... }

True only when C<state()> is C<cancelled>.

=head2 is_error

    if ($tx->is_error) { ... }

True only when C<state()> is C<error>.

=head2 is_terminal

    if ($tx->is_terminal) { ... }

True for C<complete>, C<cancelled>, or C<error>.

False only while the Transaction is C<active>.

=head1 CLIENT LIFECYCLE

For a normal buffered client request:

=over 4

=item 1.

C<$client-E<gt>request()> creates the Transaction and queues or sends the
request.

=item 2.

C<on_informational> may run zero or more times.

=item 3.

C<on_response> runs when the final response head arrives.

=item 4.

C<on_body> runs zero or more times.

=item 5.

The response completes, and C<on_complete> runs once the local request side is
also complete.

=back

For C<stream_body =E<gt> 1>, the local side remains incomplete until
C<end()> or until an early final response makes further request-body output
impossible.

=head1 SERVER LIFECYCLE

For a normal server request:

=over 4

=item 1.

The Transaction is created and passed to C<on_request>.

=item 2.

C<on_body> may run zero or more times as request body bytes arrive.

=item 3.

C<on_request_end> runs when the full request and trailers are complete.

=item 4.

The application starts the final response with C<respond()>.

=item 5.

If the response streams, C<write()> and C<end()> finish the local response
side.

=item 6.

The Transaction becomes complete when both the request and response sides are
done.

=back

The response may begin before steps 2 and 3 finish.

=head1 BACKPRESSURE

Backpressure is advisory to the producer, not rejection of the bytes passed to
C<write()> or C<end()>.

When either the HTTP queue or an attached transport becomes congested:

    my $ok = $tx->write($bytes);

returns false.

The producer should stop until C<on_drain> runs.

With a manual integration, draining C<Client-E<gt>output()> or
C<Server-E<gt>output()> below the low-water mark can cause C<on_drain>.

With an attached transport, the adapter calls C<$http-E<gt>resume_output()> when the
transport becomes writable again.

=head1 PROTOCOL SWITCH

A server Transaction can cause a switch by sending a valid 101 response or a
successful CONNECT response.

A client Transaction can receive the corresponding switch response.

The Transaction completes its HTTP lifecycle before the connection reports
C<is_switched()>. With an attached transport, a server's C<on_switch> is
delayed until the complete outgoing handshake has been accepted by the host.

Bytes after the HTTP boundary belong to the next protocol and are obtained from
the owning Client or Server with C<take_remainder()>.

=head1 SEE ALSO

L<Unblock::HTTP1::Integration>,
L<Unblock::HTTP1>,
L<Unblock::HTTP1::Client>,
L<Unblock::HTTP1::Server>,
L<Uniform::HTTP::Request>,
L<Uniform::HTTP::Response>

=cut
