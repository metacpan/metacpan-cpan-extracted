package Unblock::HTTP3::Transaction;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed weaken);

use Uniform::HTTP::Request 0.06 ();
use Uniform::HTTP::Response 0.06 ();

use Unblock::HTTP3 ();
use Unblock::HTTP3::_Native ();

our $VERSION = '0.13';

my %TERMINAL = map { $_ => 1 } qw(complete cancelled error);
my $BUFFERED_BODY_RETAIN_BYTES = 16_384;

sub _priority_from_args {
    my ($current, @args) = @_;
    croak 'priority() requires named arguments' if @args % 2;

    my %priority = (
        urgency     => 3,
        incremental => 0,
        %{ $current || {} },
    );

    while (@args) {
        my $name = shift @args;
        my $value = shift @args;

        croak "unknown priority option: $name"
            if $name ne 'urgency' && $name ne 'incremental';

        if ($name eq 'urgency') {
            croak 'priority urgency must be an integer from 0 through 7'
                if !defined($value)
                    || ref($value)
                    || "$value" !~ /\A[0-7]\z/;
            $priority{urgency} = 0 + $value;
            next;
        }

        croak 'priority incremental must be 0 or 1'
            if !defined($value)
                || ref($value)
                || "$value" !~ /\A[01]\z/;
        $priority{incremental} = $value ? 1 : 0;
    }

    return \%priority;
}

sub _priority_field {
    my ($priority) = @_;
    my $value = 'u=' . $priority->{urgency};
    $value .= ', i' if $priority->{incremental};
    return $value;
}

sub _parse_priority_field {
    my ($value) = @_;

    return {
        urgency     => 3,
        incremental => 0,
    } unless defined $value;

    my $parsed = eval {
        Unblock::HTTP3::_Native->parse_priority($value);
    };

    return {
        urgency     => 3,
        incremental => 0,
    } unless defined $parsed;

    return {
        urgency     => 0 + $parsed->[0],
        incremental => $parsed->[1] ? 1 : 0,
    };
}

sub _request_contract {
    my ($request) = @_;
    return unless blessed($request);

    for my $method (qw(
        method target scheme authority protocol version
        header_count header_name header_value
        trailer_count trailer_name trailer_value
        has_buffered_body body
    )) {
        return unless $request->can($method);
    }

    return 1;
}

sub _response_contract {
    my ($response) = @_;
    return unless blessed($response);

    for my $method (qw(
        status version
        header_count header_name header_value
        trailer_count trailer_name trailer_value
        has_buffered_body body
    )) {
        return unless $response->can($method);
    }

    return 1;
}

sub _new {
    my ($class, %args) = @_;

    my $connection = delete $args{connection};
    my $stream_id  = delete $args{stream_id};
    my $request    = delete $args{request};
    my $response   = delete $args{response};
    my $callbacks  = delete($args{callbacks}) || {};
    my $request_streaming = delete $args{request_streaming} ? 1 : 0;
    my $early_data = delete $args{early_data} ? 1 : 0;

    croak 'Transaction requires a Unblock::HTTP3::Connection'
        unless blessed($connection)
            && $connection->isa('Unblock::HTTP3::Connection');
    croak 'Transaction requires a non-negative stream ID'
        unless defined($stream_id)
            && !ref($stream_id)
            && $stream_id =~ /\A[0-9]+\z/;
    croak 'Transaction requires the Uniform HTTP request contract'
        unless _request_contract($request);
    croak 'Transaction response must implement the Uniform HTTP response contract'
        if defined($response)
            && !_response_contract($response);
    croak 'Transaction callbacks must be a hash reference'
        unless ref($callbacks) eq 'HASH';
    croak 'unknown Transaction option: ' . join(', ', sort keys %args)
        if %args;

    my $self = bless {
        connection => $connection,
        stream_id  => 0 + $stream_id,
        request    => $request,
        response                => $response,
        callbacks               => { %$callbacks },
        informational           => [],
        request_body            => undef,
        response_body            => undef,
        request_receive_mode     => 'buffered',
        response_receive_mode    => 'buffered',
        request_receive_options  => {},
        response_receive_options => {},
        request_end_callback_called => 0,
        request_streaming         => $request_streaming,
        early_data                => $early_data,
        response_streaming        => 0,
        request_buffered_body     => '',
        request_buffered_chunks   => [],
        request_buffered_bytes    => 0,
        request_buffered_seen     => 0,
        response_buffered_body    => '',
        response_buffered_chunks  => [],
        response_buffered_bytes   => 0,
        response_buffered_seen    => 0,
        response_output_started  => 0,
        capsule_stream           => undef,
        datagrams_enabled        => 0,
        datagram_queue           => [],
        datagram_callback        => undef,
        priority                 => _parse_priority_field(
            $request->header('priority'),
        ),
        local_reset_code          => undef,
        remote_reset_code         => undef,
        local_stop_sending_code   => undef,
        remote_stop_sending_code  => undef,
        state                    => 'active',
        error                   => undef,
    }, $class;

    weaken($self->{connection});

    return $self;
}

sub early_data {
    my ($self, @args) = @_;
    croak 'early_data() does not accept arguments' if @args;
    return $self->{early_data} ? 1 : 0;
}

sub stream_id {
    my ($self, @args) = @_;
    croak 'stream_id() does not accept arguments' if @args;
    return $self->{stream_id};
}

sub request {
    my ($self, @args) = @_;
    croak 'request() does not accept arguments' if @args;
    return $self->{request};
}

sub protocol {
    my ($self, @args) = @_;
    croak 'protocol() does not accept arguments' if @args;
    return $self->{request}->protocol;
}

sub is_extended_connect {
    my ($self, @args) = @_;
    croak 'is_extended_connect() does not accept arguments' if @args;
    return defined($self->{request}->protocol) ? 1 : 0;
}

sub response {
    my ($self, @args) = @_;
    croak 'response() does not accept arguments' if @args;
    return $self->{response};
}

sub local_reset_code {
    my ($self, @args) = @_;
    croak 'local_reset_code() does not accept arguments' if @args;
    return $self->{local_reset_code};
}

sub remote_reset_code {
    my ($self, @args) = @_;
    croak 'remote_reset_code() does not accept arguments' if @args;
    return $self->{remote_reset_code};
}

sub local_stop_sending_code {
    my ($self, @args) = @_;
    croak 'local_stop_sending_code() does not accept arguments' if @args;
    return $self->{local_stop_sending_code};
}

sub remote_stop_sending_code {
    my ($self, @args) = @_;
    croak 'remote_stop_sending_code() does not accept arguments' if @args;
    return $self->{remote_stop_sending_code};
}

sub is_aborted {
    my ($self, @args) = @_;
    croak 'is_aborted() does not accept arguments' if @args;

    return defined($self->{local_reset_code})
        || defined($self->{remote_reset_code})
        || defined($self->{local_stop_sending_code})
        || defined($self->{remote_stop_sending_code})
        ? 1
        : 0;
}

sub _mark_local_reset {
    my ($self, $code) = @_;
    $self->{local_reset_code} = 0 + $code;
    return $self;
}

sub _mark_remote_reset {
    my ($self, $code) = @_;
    $self->{remote_reset_code} = 0 + $code;
    return $self;
}

sub _mark_local_stop_sending {
    my ($self, $code) = @_;
    $self->{local_stop_sending_code} = 0 + $code;
    return $self;
}

sub _mark_remote_stop_sending {
    my ($self, $code) = @_;
    $self->{remote_stop_sending_code} = 0 + $code;
    return $self;
}

sub priority {
    my ($self, @args) = @_;

    my $connection = $self->{connection};

    if (!@args) {
        return { %{ $self->{priority} } }
            if $self->is_terminal || !defined($connection);

        my $priority = $connection->_transaction_priority($self);
        $self->{priority} = { %$priority };

        return { %$priority };
    }

    croak 'priority() cannot change a terminal Transaction'
        if $self->is_terminal;

    $connection
        or croak 'priority(): Transaction no longer has a connection';

    my $current = $connection->_transaction_priority($self);
    my $priority = _priority_from_args(
        $current,
        @args,
    );

    $connection->_set_transaction_priority(
        $self,
        $priority,
    );

    $self->{priority} = { %$priority };
    return $self;
}

sub capsules {
    my ($self, @args) = @_;

    if (my $stream = $self->{capsule_stream}) {
        croak 'capsules() options can only be supplied when the stream is created'
            if @args;
        return $stream;
    }

    croak 'capsules() options must be key/value pairs'
        if @args % 2;
    croak 'capsules() cannot be used on a terminal Transaction'
        if $self->is_terminal;
    croak 'capsules() requires Extended CONNECT'
        unless $self->is_extended_connect;

    require Unblock::HTTP3::Capsule::Stream;

    my $stream = Unblock::HTTP3::Capsule::Stream->_new(
        $self,
        @args,
    );

    $self->{capsule_stream} = $stream;
    return $stream;
}

sub _enable_datagrams {
    my ($self) = @_;
    $self->{datagrams_enabled} = 1;
    return $self;
}

sub datagrams_enabled {
    my ($self, @args) = @_;
    croak 'datagrams_enabled() does not accept arguments' if @args;
    return $self->{datagrams_enabled} ? 1 : 0;
}

sub send_datagram {
    my ($self, $bytes) = @_;

    croak 'send_datagram(): Transaction is already terminal'
        if $self->is_terminal;
    croak 'send_datagram(): HTTP Datagrams are not enabled for this Transaction'
        unless $self->{datagrams_enabled};

    my $connection = $self->{connection}
        or croak 'send_datagram(): Transaction no longer has a connection';

    return $connection->_send_transaction_datagram($self, $bytes);
}

sub max_datagram_payload_size {
    my ($self, @args) = @_;
    croak 'max_datagram_payload_size() does not accept arguments' if @args;
    return 0 unless $self->{datagrams_enabled};
    return 0 if $self->is_terminal;

    my $connection = $self->{connection};
    return 0 unless defined $connection;

    return $connection->_transaction_datagram_payload_size($self);
}

sub next_datagram {
    my ($self, @args) = @_;
    croak 'next_datagram() does not accept arguments' if @args;

    my $bytes = shift @{ $self->{datagram_queue} };
    return unless defined $bytes;

    my $connection = $self->{connection};
    $connection->_datagram_dequeued(length($bytes))
        if defined $connection;

    return $bytes;
}

sub on_datagram {
    my ($self, $callback) = @_;

    croak 'on_datagram() callback must be a code reference or undef'
        if defined($callback) && ref($callback) ne 'CODE';

    $self->{datagram_callback} = $callback;

    if (defined $callback) {
        while (defined(my $bytes = $self->next_datagram)) {
            $callback->($self, $bytes);
        }
    }

    return $self;
}

sub _enqueue_datagram {
    my ($self, $bytes) = @_;
    push @{ $self->{datagram_queue} }, $bytes;
    return;
}

sub _receive_datagram {
    my ($self, $bytes) = @_;

    my $callback = $self->{datagram_callback};
    if (defined $callback) {
        $callback->($self, $bytes);
        return;
    }

    my $connection = $self->{connection};
    return unless defined $connection;

    $connection->_buffer_transaction_datagram($self, $bytes);
    return;
}

sub _discard_datagrams {
    my ($self) = @_;

    my $connection = $self->{connection};

    if (defined $connection) {
        for my $bytes (@{ $self->{datagram_queue} }) {
            $connection->_datagram_dequeued(length($bytes));
        }
    }

    $self->{datagram_queue} = [];
    $self->{datagram_callback} = undef;
    return;
}

sub state {
    my ($self, @args) = @_;
    croak 'state() does not accept arguments' if @args;
    return $self->{state};
}

sub error {
    my ($self, @args) = @_;
    croak 'error() does not accept arguments' if @args;
    return $self->{error};
}

sub is_complete {
    my ($self, @args) = @_;
    croak 'is_complete() does not accept arguments' if @args;
    return $self->{state} eq 'complete' ? 1 : 0;
}

sub is_cancelled {
    my ($self, @args) = @_;
    croak 'is_cancelled() does not accept arguments' if @args;
    return $self->{state} eq 'cancelled' ? 1 : 0;
}

sub is_error {
    my ($self, @args) = @_;
    croak 'is_error() does not accept arguments' if @args;
    return $self->{state} eq 'error' ? 1 : 0;
}

sub is_terminal {
    my ($self, @args) = @_;
    croak 'is_terminal() does not accept arguments' if @args;
    return $TERMINAL{ $self->{state} } ? 1 : 0;
}

sub _set_callback {
    my ($self, $name, $callback) = @_;

    croak "_set_callback(): callback must be a code reference or undef"
        if defined($callback) && ref($callback) ne 'CODE';

    if (defined $callback) {
        $self->{callbacks}{$name} = $callback;
    } else {
        delete $self->{callbacks}{$name};
    }

    return $self;
}

sub on_data {
    my ($self, $cb) = @_;
    croak 'on_data(): callback must be a coderef' unless ref($cb) eq 'CODE';
    croak 'on_data(): receive body has already started or finished'
        if $self->{receive_started} || $self->{receive_done} || $self->is_terminal;
    croak 'on_data(): cannot be combined with on_body'
        if $self->{callbacks}{on_body};
    croak 'on_data(): callback is already registered' if $self->{callbacks}{on_data};
    my $connection = $self->{connection}
        or croak 'on_data(): HTTP/3 connection is gone';
    my $kind = $connection->role eq 'server' ? 'request' : 'response';
    my $reader = $self->{ $kind . '_body' };
    croak 'on_data(): body reader already has an on_data callback'
        if ($reader && $reader->{on_data})
            || $self->{ $kind . '_receive_options' }{on_data};
    my $weak = $self;
    weaken($weak);
    my $deliver = sub {
        my ($reader, $bytes) = @_;
        my $tx = $weak or return;
        my $result = $tx->_invoke('on_data', $bytes);
        die $result unless $result eq '1';
    };
    $self->{callbacks}{on_data} = $cb;
    $self->{ $kind . '_receive_mode' } = 'stream';
    if ($reader) {
        $reader->_configure(on_data => $deliver);
    } else {
        $self->{ $kind . '_receive_options' }{on_data} = $deliver;
    }
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

sub _invoke {
    my ($self, $name, @args) = @_;

    my $callback = $self->{callbacks}{$name} or return 1;

    $self->{callback_depth}++;
    my $ok = eval {
        $callback->($self, @args);
        1;
    };

    my $error = "$@";
    $self->{callback_depth}--;
    if (!$ok && !$self->is_terminal
        && $name =~ /\Aon_(?:request|response|data|body|request_end|informational)\z/) {
        my $connection = $self->{connection};
        $connection->_reject_message_stream($self->stream_id, $error)
            if $connection;
        eval { $self->_mark_error($error) };
    }
    $self->_notify_finish if $self->{finish_pending};
    return $ok ? 1 : $error;
}

sub next_informational {
    my ($self, @args) = @_;

    croak 'next_informational() does not accept arguments' if @args;
    return shift @{ $self->{informational} };
}

sub send_informational {
    my ($self, @arg) = @_;

    my $response;
    if (@arg && ref($arg[0])) {
        croak 'send_informational(): response object does not take options'
            unless @arg == 1;
        $response = $arg[0];
    } else {
        croak 'send_informational(): fields must be key/value pairs'
            if @arg % 2;
        $response = Uniform::HTTP::Response->new(@arg);
    }

    croak 'send_informational(): Transaction is already terminal'
        if $self->is_terminal;
    my $connection = $self->{connection}
        or croak 'send_informational(): Transaction no longer has a connection';

    $connection->_assert_response_contract(
        $response,
        'send_informational()',
    );
    croak 'send_informational(): status must be 100 through 199, excluding 101'
        unless $response->status >= 100
            && $response->status <= 199
            && $response->status != 101;
    croak 'send_informational(): informational responses cannot have a body'
        if $response->has_buffered_body;
    croak 'send_informational(): informational responses cannot have trailers'
        if $response->has_trailers;

    $connection->_send_informational_response(
        $self,
        $response,
    );

    return $self;
}

sub is_response_started {
    my ($self, @args) = @_;
    croak 'is_response_started() does not accept arguments' if @args;
    return $self->{response_output_started} ? 1 : 0;
}

sub request_body {
    my ($self, @args) = @_;

    if (my $body = $self->{request_body}) {
        if (@args) {
            croak 'request_body options must be key/value pairs'
                if @args % 2;

            if ($body->can('_configure')) {
                $body->_configure(@args);
            } else {
                croak 'request_body options may only be supplied when the producer is created';
            }
        }

        return $body;
    }

    croak 'request_body(): Transaction is already terminal'
        if $self->is_terminal;

    my $connection = $self->{connection}
        or croak 'request_body(): Transaction no longer has a connection';

    if ($connection->role eq 'server') {
        croak 'request_body(): request receive mode is buffered'
            unless $self->{request_receive_mode} eq 'stream';
        croak 'request_body options must be key/value pairs'
            if @args % 2;

        require Unblock::HTTP3::Body::Reader;

        my %option = (
            %{ $self->{request_receive_options} || {} },
            @args,
        );

        my $body = Unblock::HTTP3::Body::Reader->_new(
            $self,
            'request',
            %option,
        );

        $self->{request_body} = $body;
        return $body;
    }

    croak 'request_body(): Request is not configured for incremental body production'
        unless $self->{request_streaming};
    croak 'request_body options must be key/value pairs'
        if @args % 2;

    require Unblock::HTTP3::Body::Stream;

    my $body = Unblock::HTTP3::Body::Stream->_new(
        $self,
        'request',
        @args,
    );

    $self->{request_body} = $body;
    return $body;
}

sub response_body {
    my ($self, @args) = @_;

    if (my $body = $self->{response_body}) {
        if (@args) {
            croak 'response_body options must be key/value pairs'
                if @args % 2;

            if ($body->can('_configure')) {
                $body->_configure(@args);
            } else {
                croak 'response_body options may only be supplied when the producer is created';
            }
        }

        return $body;
    }

    croak 'response_body(): Transaction is already terminal'
        if $self->is_terminal;

    my $connection = $self->{connection}
        or croak 'response_body(): Transaction no longer has a connection';

    if ($connection->role eq 'client') {
        croak 'response_body(): response receive mode is buffered'
            unless $self->{response_receive_mode} eq 'stream';
        croak 'response_body options must be key/value pairs'
            if @args % 2;

        require Unblock::HTTP3::Body::Reader;

        my %option = (
            %{ $self->{response_receive_options} || {} },
            @args,
        );

        my $body = Unblock::HTTP3::Body::Reader->_new(
            $self,
            'response',
            %option,
        );

        $self->{response_body} = $body;
        return $body;
    }

    croak 'response_body(): response output has already started'
        if $self->{response_output_started};
    croak 'response_body options must be key/value pairs'
        if @args % 2;

    my $response = $self->{response}
        or croak 'response_body(): Transaction has no Response';

    $connection->_assert_response_body_allowed(
        $self,
        $response,
        'response_body()',
    );

    $self->{response_streaming} = 1;
    $response->mark_incomplete if $response->can('mark_incomplete');

    require Unblock::HTTP3::Body::Stream;

    my $body = Unblock::HTTP3::Body::Stream->_new(
        $self,
        'response',
        @args,
    );

    $self->{response_body} = $body;
    return $body;
}

sub respond {
    my ($self, @arg) = @_;

    my ($response, %option);
    if (@arg && ref($arg[0])) {
        $response = shift @arg;
        croak 'respond(): options must be key/value pairs' if @arg % 2;
        %option = @arg;
    } else {
        croak 'respond(): fields must be key/value pairs' if @arg % 2;
        my %field = @arg;
        for my $name (qw(stream_body on_drain on_error)) {
            $option{$name} = delete $field{$name} if exists $field{$name};
        }
        $response = Uniform::HTTP::Response->new(%field);
    }

    croak 'respond(): Transaction is already terminal'
        if $self->is_terminal;

    my $connection = $self->{connection}
        or croak 'respond(): HTTP/3 connection is no longer available';

    $connection->_respond_transaction(
        $self,
        $response,
        %option,
    );

    return $self;
}

sub write {
    my ($self, $bytes) = @_;

    croak 'write(): Transaction is already terminal'
        if $self->is_terminal;

    my $connection = $self->{connection}
        or croak 'write(): HTTP/3 connection is no longer available';

    return $connection->_write_stream_body(
        $self,
        $bytes,
        0,
        'write',
    );
}

sub end {
    my ($self, @args) = @_;

    croak 'end(): accepts at most one final byte string'
        if @args > 1;
    croak 'end(): Transaction is already terminal'
        if $self->is_terminal;

    my $connection = $self->{connection}
        or croak 'end(): HTTP/3 connection is no longer available';

    my $bytes = @args ? $args[0] : '';
    $connection->_write_stream_body(
        $self,
        $bytes,
        1,
        'end',
    );

    return $self;
}

sub cancel {
    my ($self) = @_;

    return $self if $self->is_terminal;

    my $connection = $self->{connection};
    if (defined $connection) {
        $connection->_cancel_transaction($self);
    }

    return $self if $self->is_terminal;
    return $self->_mark_cancelled;
}

sub _configure_receive_body {
    my ($self, $kind, $mode, $options) = @_;

    croak "unsupported HTTP body receive kind '$kind'"
        if $kind ne 'request' && $kind ne 'response';
    croak 'receive body mode must be buffered or stream'
        if $mode ne 'buffered' && $mode ne 'stream';
    croak 'receive body options must be a hash reference'
        unless ref($options) eq 'HASH';

    $self->{ $kind . '_receive_mode' } = $mode;
    $self->{ $kind . '_receive_options' } = { %$options };

    return $self;
}

sub _ensure_receive_reader {
    my ($self, $kind) = @_;

    return unless $self->{ $kind . '_receive_mode' } eq 'stream';

    return $kind eq 'request'
        ? $self->request_body
        : $self->response_body;
}

sub _incoming_body_reader {
    my ($self, $kind) = @_;

    return unless $self->{ $kind . '_receive_mode' } eq 'stream';

    return $self->_ensure_receive_reader($kind);
}

sub _consume_received_body {
    my ($self, $kind, $amount) = @_;

    my $connection = $self->{connection}
        or croak 'received body lost its HTTP/3 connection';

    $connection->_consume_received_body(
        $self,
        $kind,
        $amount,
    );

    return;
}

sub _received_body_complete {
    my ($self, $kind) = @_;

    $self->{receive_done} = 1;
    $self->_invoke_request_end
        if $kind eq 'request'
            && $self->{request_receive_mode} eq 'stream';

    return if $self->{callback_depth};
    my $connection = $self->{connection};
    $connection->_maybe_complete_transaction($self->{stream_id})
        if defined $connection;

    return;
}

sub _capsule_protocol_error {
    my ($self, $error) = @_;

    return if $self->is_terminal;

    my $connection = $self->{connection};
    if (defined $connection) {
        $connection->_capsule_protocol_error(
            $self,
            $error,
        );
    } else {
        $self->_mark_error($error);
    }

    return;
}

sub _write_body {
    my ($self, $kind, $bytes, $final, $operation) = @_;

    croak "$operation(): Transaction is already terminal"
        if $self->is_terminal;
    croak "$operation(): unsupported HTTP body producer '$kind'"
        if $kind ne 'request' && $kind ne 'response';

    my $message = $kind eq 'request'
        ? $self->{request}
        : ($self->{response}
            or croak "$operation(): Transaction has no Response");

    my $connection = $self->{connection}
        or croak "$operation(): Transaction no longer has a connection";

    my ($can_continue, $ok, $error);

    {
        local $@;
        $ok = eval {
            $can_continue = $connection->_write_transaction_body(
                $self,
                $kind,
                $bytes,
                $final,
                $operation,
            );
            1;
        };
        $error = $@;
    }

    die $error unless $ok;

    $message->mark_complete
        if $final && $message->can('mark_complete');
    return $can_continue;
}

sub _request_is_streaming {
    my ($self) = @_;
    return $self->{request_streaming} ? 1 : 0;
}

sub _response_is_streaming {
    my ($self) = @_;
    return $self->{response_streaming} ? 1 : 0;
}

sub _enable_response_streaming {
    my ($self) = @_;
    $self->{response_streaming} = 1;
    $self->{response}->mark_incomplete if defined $self->{response};
    return $self;
}

sub _buffered_body_bytes {
    my ($self, $kind) = @_;
    croak "unsupported buffered body kind '$kind'"
        if $kind ne 'request' && $kind ne 'response';

    return 0 unless $self->{ $kind . '_buffered_seen' };

    return $self->{ $kind . '_buffered_bytes' }
        + length($self->{ $kind . '_buffered_body' });
}

sub _append_buffered_body {
    my ($self, $kind, $bytes) = @_;
    croak "unsupported buffered body kind '$kind'"
        if $kind ne 'request' && $kind ne 'response';

    $self->{ $kind . '_buffered_seen' } = 1;

    my $length = length($bytes);

    if ($length < $BUFFERED_BODY_RETAIN_BYTES) {
        $self->{ $kind . '_buffered_body' } .= $bytes;
        return;
    }

    my $body_name = $kind . '_buffered_body';
    my $chunks = $self->{ $kind . '_buffered_chunks' };
    my $bytes_name = $kind . '_buffered_bytes';

    if (length($self->{$body_name})) {
        my $tail = $self->{$body_name};

        push @$chunks, $tail;
        $self->{$bytes_name} += length($tail);
        $self->{$body_name} = '';
    }

    push @$chunks, $bytes;
    $self->{$bytes_name} += $length;
    return;
}

sub _finish_received_message {
    my ($self, $kind) = @_;
    croak "unsupported received message kind '$kind'"
        if $kind ne 'request' && $kind ne 'response';

    my $message = $kind eq 'request'
        ? $self->{request}
        : $self->{response};

    return unless defined $message;

    if (
        $self->{ $kind . '_receive_mode' } eq 'buffered'
    ) {
        my $body_name = $kind . '_buffered_body';
        my $chunks = $self->{ $kind . '_buffered_chunks' };
        my $body;

        if (@$chunks) {
            push @$chunks, $self->{$body_name}
                if length($self->{$body_name});

            $body = @$chunks == 1
                ? $chunks->[0]
                : join('', @$chunks);
        } else {
            $body = $self->{$body_name};
        }

        $self->{$body_name} = '';
        $self->{ $kind . '_buffered_chunks' } = [];
        $self->{ $kind . '_buffered_bytes' } = 0;
        $self->{ $kind . '_buffered_seen' } = 0;

        $message->body($body) if $message->body_is_mutable;
    } else {
        $self->{ $kind . '_buffered_body' } = '';
        $self->{ $kind . '_buffered_chunks' } = [];
        $self->{ $kind . '_buffered_bytes' } = 0;
        $self->{ $kind . '_buffered_seen' } = 0;
    }

    $message->freeze_trailers;
    $message->freeze;
    $message->mark_complete;

    $self->{receive_done} = 1;
    $self->_invoke_request_end
        if $kind eq 'request'
            && $self->{request_receive_mode} eq 'buffered';

    return;
}

sub _invoke_request_end {
    my ($self) = @_;

    return if $self->is_terminal || $self->{request_end_callback_called};
    $self->{request_end_callback_called} = 1;

    my $result = $self->_invoke(
        'on_request_end',
        $self->{request},
    );
    die $result unless $result eq '1';

    return;
}

sub _discard_received_body_buffers {
    my ($self) = @_;

    for my $kind (qw(request response)) {
        $self->{ $kind . '_buffered_body' } = '';
        $self->{ $kind . '_buffered_chunks' } = [];
        $self->{ $kind . '_buffered_bytes' } = 0;
        $self->{ $kind . '_buffered_seen' } = 0;
    }

    return;
}

sub _request_body_object {
    my ($self) = @_;
    return $self->{request_body};
}

sub _response_body_object {
    my ($self) = @_;
    return $self->{response_body};
}

sub _mark_response_started {
    my ($self) = @_;
    $self->{response_output_started} = 1;
    return $self;
}

sub _push_informational {
    my ($self, $response) = @_;

    croak 'informational response must implement the Uniform HTTP response contract'
        unless _response_contract($response);

    push @{ $self->{informational} }, $response;
    return $response;
}

sub _set_response {
    my ($self, $response) = @_;

    croak 'cannot attach a response to a terminal Transaction'
        if $self->is_terminal;
    croak 'Transaction already has a response'
        if defined $self->{response};
    croak 'Transaction response must implement the Uniform HTTP response contract'
        unless _response_contract($response);

    $self->{response} = $response;
    return $response;
}

# Commit the terminal state before body cancellation callbacks can re-enter.
# Always release both bodies and notify observers even when a callback throws.
sub _terminal_cleanup {
    my ($self) = @_;
    my $error = '';
    for my $body ($self->{request_body}, $self->{response_body}) {
        next unless $body && !$body->is_complete;
        eval { $body->_cancel; 1 } or $error ||= "$@";
    }
    $self->_discard_datagrams;
    $self->_discard_received_body_buffers;
    return $error;
}

sub _mark_complete {
    my ($self) = @_;
    return $self if $self->is_terminal;
    $self->{state} = 'complete';
    my $error = $self->_terminal_cleanup;
    my $result = $self->_invoke('on_complete');
    $self->_notify_finish;
    die $error if length $error;
    die $result unless $result eq '1';
    return $self;
}

sub _mark_cancelled {
    my ($self) = @_;
    return $self if $self->is_terminal;
    $self->{state} = 'cancelled';
    my $error = $self->_terminal_cleanup;
    $self->_notify_finish;
    die $error if length $error;
    return $self;
}

sub _mark_error {
    my ($self, $error, $error_code) = @_;
    return $self if $self->is_terminal;
    $self->{state} = 'error';
    $self->{error} = defined($error) ? "$error" : 'HTTP/3 transaction failed';
    my $cleanup_error = $self->_terminal_cleanup;
    my $result = $self->_invoke('on_error', $self->{error}, $error_code);
    $self->_notify_finish;
    die $cleanup_error if length $cleanup_error;
    die $result unless $result eq '1';
    return $self;
}

1;

__END__

=head1 NAME

Unblock::HTTP3::Transaction - one HTTP/3 request and response transaction

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

A Transaction represents one HTTP request/response exchange carried by one
HTTP/3 request stream.

C<request()> returns the Uniform request. C<response()> returns the final
Uniform response when one is available.

=head1 COMMON API

The application-facing API intentionally matches the other Unblock HTTP
engines:

    respond
    write
    end
    send_informational

A server sends a final response with named fields:

    $transaction->respond(status => 200, body => "hello\n");

An existing Uniform-compatible Response object is also accepted:

    $transaction->respond($response);

For a streaming response:

    $transaction->respond(
        $response,
        stream_body => 1,
    );

    $transaction->write($chunk);
    $transaction->end($last_chunk);

A client request opened with C<stream_body =E<gt> 1> uses the same C<write()>
and C<end()> methods.

C<send_informational(status =E<gt> 103)> sends a server-side 1xx response
before the final response. It also accepts a Uniform-compatible Response
object. HTTP/3 does not use status 101.

=head1 ADVANCED BODY API

C<request_body()> and C<response_body()> expose
L<Unblock::HTTP3::Body::Stream> or L<Unblock::HTTP3::Body::Reader> when explicit
HTTP/3 body control is needed.

The common Transaction methods are a convenience layer over those body
objects, not a replacement for them.

=head1 STATE

Useful lifecycle methods are:

    state
    error
    is_complete
    is_cancelled
    is_error
    is_terminal

C<state()> returns C<active>, C<complete>, C<cancelled>, or C<error>.

=head1 HTTP/3 STATE

C<stream_id()> returns the HTTP/3 request stream ID.

C<priority()> gets or changes RFC 9218 priority state.

C<local_reset_code()>, C<remote_reset_code()>,
C<local_stop_sending_code()>, and C<remote_stop_sending_code()> preserve
HTTP/3 stream diagnostics.

C<is_aborted()> is true when any RESET_STREAM or STOP_SENDING condition has
been recorded.

C<protocol()> and C<is_extended_connect()> expose Extended CONNECT state.

C<early_data()> reports whether the request used QUIC 0-RTT.

=head1 INFORMATIONAL RESPONSES

C<next_informational()> returns the next queued informational Response for
users of the pull interface.

=head1 CAPSULES AND DATAGRAMS

C<capsules()> returns the generic RFC 9297 Capsule stream for an Extended
CONNECT Transaction.

HTTP Datagram methods include:

    datagrams_enabled
    send_datagram
    next_datagram
    on_datagram
    max_datagram_payload_size

=head1 CANCELLATION

C<cancel()> cancels the HTTP/3 request stream with H3_REQUEST_CANCELLED.

=head1 SEE ALSO

L<Unblock::HTTP3>, L<Unblock::HTTP3::Client>, L<Unblock::HTTP3::Server>,
L<Unblock::HTTP3::Body::Stream>, L<Unblock::HTTP3::Body::Reader>

=head1 LICENSE

MIT License.

=cut
