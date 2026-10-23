package Unblock::WebSocket::_Engine;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed weaken);

use Unblock::WebSocket ();
use Unblock::WebSocket::_Deflate ();
use Unblock::WebSocket::_Frame ();
use Unblock::WebSocket::_Random ();
use Unblock::WebSocket::_UTF8 ();

my %VALID_CLOSE = map { $_ => 1 } (
    1000, 1001, 1002, 1003,
    1007, 1008, 1009, 1010, 1011, 1012, 1013, 1014,
);


sub _checked_deflate_config {
    my ($value) = @_;
    return unless defined $value;
    croak 'new(): permessage_deflate must be a hash reference'
        unless ref($value) eq 'HASH';

    my %copy = %$value;
    my %out;

    for my $name (qw(
        client_no_context_takeover
        server_no_context_takeover
    )) {
        next unless exists $copy{$name};
        my $flag = delete $copy{$name};
        croak "new(): permessage_deflate $name must be zero or one"
            if ref($flag) || "$flag" !~ /\A[01]\z/;
        $out{$name} = $flag ? 1 : 0;
    }

    for my $name (qw(
        client_max_window_bits
        server_max_window_bits
    )) {
        next unless exists $copy{$name};
        my $bits = delete $copy{$name};
        croak "new(): permessage_deflate $name must be an integer from 8 through 15"
            unless defined($bits) && !ref($bits)
                && "$bits" =~ /\A[0-9]+\z/
                && $bits >= 8 && $bits <= 15;
        $out{$name} = 0 + $bits;
    }

    croak 'new(): unknown permessage_deflate option(s): '
        . join(', ', sort keys %copy)
        if %copy;

    return \%out;
}

sub _compressed_wire_limit {
    my ($max_message_size) = @_;
    return $max_message_size + int($max_message_size / 100) + 1024;
}

sub _new {
    my ($class, %option) = @_;
    my $role = delete $option{role};
    croak 'new(): role must be client or server'
        unless defined($role) && ($role eq 'client' || $role eq 'server');

    my $transport = delete $option{transport};
    if (defined $transport) {
        croak 'new(): transport must be an object' unless blessed($transport);
        for my $method (qw(unblock_send unblock_finish unblock_abort)) {
            croak "new(): transport must implement $method()"
                unless $transport->can($method);
        }
    }

    my $max_message_size = exists($option{max_message_size})
        ? delete($option{max_message_size}) : 16 * 1024 * 1024;
    croak 'new(): max_message_size must be a positive integer'
        unless defined($max_message_size) && !ref($max_message_size)
            && $max_message_size =~ /\A[0-9]+\z/ && $max_message_size > 0;

    my $high_water = exists($option{high_water})
        ? delete($option{high_water}) : 64 * 1024;
    my $low_water = exists($option{low_water})
        ? delete($option{low_water}) : 32 * 1024;
    for my $pair ([high_water => $high_water], [low_water => $low_water]) {
        croak "new(): $pair->[0] must be a non-negative integer"
            unless defined($pair->[1]) && !ref($pair->[1])
                && $pair->[1] =~ /\A[0-9]+\z/;
    }
    croak 'new(): low_water must not exceed high_water'
        if $low_water > $high_water;

    my $random_bytes = delete $option{random_bytes};
    croak 'new(): random_bytes must be a code reference'
        if defined($random_bytes) && ref($random_bytes) ne 'CODE';

    my $deflate_config =
        _checked_deflate_config(delete $option{permessage_deflate});

    my $backend = delete $option{backend};
    if (!defined $backend) {
        $backend = defined($random_bytes)
            ? 'perl'
            : (Unblock::WebSocket->native_available ? 'native' : 'perl');
    }
    croak 'new(): backend must be native or perl'
        unless !ref($backend) && ($backend eq 'native' || $backend eq 'perl');
    croak 'new(): native backend is not available'
        if $backend eq 'native' && !Unblock::WebSocket->native_available;
    croak 'new(): random_bytes is only supported by the perl backend'
        if $backend eq 'native' && defined $random_bytes;

    my $native;
    if ($backend eq 'native') {
        require Unblock::WebSocket::_Native;
        my $wire_limit = $deflate_config
            ? _compressed_wire_limit($max_message_size)
            : $max_message_size;
        $native = Unblock::WebSocket::_Native->new(
            $role,
            $wire_limit,
            $deflate_config ? 1 : 0,
        );
    }

    my %callback;
    for my $name (qw(on_message on_ping on_pong on_close on_error on_drain)) {
        next unless exists $option{$name};
        my $cb = delete $option{$name};
        croak "new(): $name must be a code reference"
            if defined($cb) && ref($cb) ne 'CODE';
        $callback{$name} = $cb if $cb;
    }

    croak 'new(): unknown option(s): ' . join(', ', sort keys %option)
        if %option;

    my $self = bless {
        role             => $role,
        backend          => $backend,
        native           => $native,
        parser           => $backend eq 'perl'
            ? Unblock::WebSocket::_Frame->new_parser(
                expect_masked  => $role eq 'server' ? 1 : 0,
                max_frame_size => $deflate_config
                    ? _compressed_wire_limit($max_message_size)
                    : ($max_message_size < 125 ? 125 : $max_message_size),
                allow_rsv1     => $deflate_config ? 1 : 0,
            )
            : undef,
        deflate          => $deflate_config
            ? Unblock::WebSocket::_Deflate->new(
                role             => $role,
                config           => $deflate_config,
                max_message_size => $max_message_size,
            )
            : undef,
        deflate_config   => $deflate_config,
        max_message_size => 0 + $max_message_size,
        high_water       => 0 + $high_water,
        low_water        => 0 + $low_water,
        output           => '',
        output_blocked   => 0,
        callbacks        => \%callback,
        random_bytes      => $random_bytes,
        fragment_opcode     => undef,
        fragment_payload    => '',
        fragment_compressed => 0,
        sent_close       => 0,
        received_close   => 0,
        closed           => 0,
        failed           => 0,
        driving          => 0,
        transport          => $transport,
        transport_attached => defined($transport) ? 1 : 0,
        transport_blocked  => 0,
        transport_syncing  => 0,
        transport_in_send  => 0,
        transport_finished => 0,
        transport_aborted  => 0,
        transport_producer_blocked => 0,
    }, $class;
    weaken($self->{transport}) if defined $transport;
    return $self;
}

sub role       { $_[0]{role} }
sub backend    { $_[0]{backend} }
sub permessage_deflate {
    my ($self) = @_;
    return unless $self->{deflate_config};
    return { %{ $self->{deflate_config} } };
}
sub is_open    { !$_[0]{closed} && !$_[0]{sent_close} && !$_[0]{received_close} ? 1 : 0 }
sub is_closing { !$_[0]{closed} && ($_[0]{sent_close} || $_[0]{received_close}) ? 1 : 0 }
sub is_closed  { $_[0]{closed} ? 1 : 0 }
sub want_read  { !$_[0]{closed} ? 1 : 0 }
sub want_write { length($_[0]{output}) ? 1 : 0 }
sub output_size { length($_[0]{output}) }
sub close_sent { $_[0]{sent_close} ? 1 : 0 }
sub close_received { $_[0]{received_close} ? 1 : 0 }
sub close_complete { $_[0]{sent_close} && $_[0]{received_close} ? 1 : 0 }
sub want_end {
    my ($self) = @_;
    return 0 if $self->{closed} || length($self->{output});
    return 1 if $self->{failed};
    return $self->{received_close} ? 1 : 0;
}

sub _invoke {
    my ($self, $name, @args) = @_;
    my $cb = $self->{callbacks}{$name} or return 1;
    my $ok = eval { $cb->($self, @args); 1 };
    return 1 if $ok;
    my $error = $@ || "$name callback failed";
    $self->_fail($error, 1011) unless $name eq 'on_error';
    return;
}

sub _notify_drain {
    my ($self) = @_;
    return if $self->{closed} || $self->{transport_blocked};
    return if length($self->{output}) > $self->{low_water};
    return unless $self->{output_blocked}
        || $self->{transport_producer_blocked};
    $self->{output_blocked} = 0;
    $self->{transport_producer_blocked} = 0;
    $self->_invoke('on_drain');
    return;
}

# All bytes passed to unblock_send() are accepted or the host must throw.
# A false return signals congestion after acceptance, never a partial write.
sub _transport_sync {
    my ($self) = @_;
    return unless $self->{transport_attached};
    return if $self->{driving} || $self->{transport_syncing};
    return if $self->{transport_aborted} || $self->{transport_finished};
    return if $self->{transport_blocked};

    my $host = $self->{transport};
    return $self->_transport_abort('WebSocket transport was destroyed')
        unless $host;

    {
        local $self->{transport_syncing} = 1;
        while (!$self->{transport_blocked} && !$self->{transport_aborted}) {
            if (length($self->{output})) {
                my $bytes = $self->{output};
                $self->{output} = '';
                my $ready;
                my $ok = eval {
                    local $self->{transport_in_send} = 1;
                    $ready = $host->unblock_send($bytes);
                    1;
                };
                unless ($ok) {
                    $self->_transport_abort("$@" || 'unblock_send() failed');
                    last;
                }
                $self->{transport_blocked} = 1
                    if defined($ready) && !$ready;
            }
            $self->_notify_drain unless $self->{transport_blocked};
            last unless length($self->{output});
        }
    }

    # finish() must preserve the host's already accepted write queue.
    # Sending our Close frame alone is not completion of the handshake.
    if (!$self->{transport_aborted} && !$self->{transport_finished}
        && !$self->{transport_blocked} && !length($self->{output})
        && ($self->{received_close} || $self->{failed})) {
        $self->{transport_finished} = 1;
        my $ok = eval { $host->unblock_finish(); 1 };
        $self->_transport_abort("$@" || 'unblock_finish() failed')
            unless $ok;
    }
    return;
}

sub resume_output {
    my ($self) = @_;
    croak 'resume_output(): no attached transport'
        unless $self->{transport_attached};
    croak 'resume_output(): cannot be called recursively from a callback'
        if $self->{driving} || $self->{transport_syncing};
    return $self if $self->{transport_aborted} || $self->{transport_finished};
    $self->{transport_blocked} = 0;
    $self->_transport_sync;
    return $self;
}

sub _transport_abort {
    my ($self, $reason) = @_;
    return if $self->{transport_aborted};
    $reason = 'transport error' unless defined($reason) && length($reason);
    $reason = "$reason";
    $self->{transport_aborted} = 1;
    $self->{closed} = 1;
    $self->{failed} = 1;
    $self->{output} = '';
    $self->_invoke('on_error', $reason);
    $self->_invoke('on_close', undef, $reason) unless $self->{received_close};
    if (my $host = $self->{transport}) {
        eval { $host->unblock_abort($reason) };
    }
    return;
}

sub transport_error {
    my ($self, $reason) = @_;
    return $self if $self->{transport_aborted} || $self->{closed};
    $self->_transport_abort($reason);
    return $self;
}

sub _queue_wire {
    my ($self, $bytes) = @_;
    croak 'WebSocket output cannot be generated from unblock_send()'
        if $self->{transport_in_send};
    return 1 if !defined($bytes) || !length($bytes);
    $self->{output} .= $bytes;
    $self->_transport_sync if $self->{transport_attached};
    my $ready = length($self->{output}) < $self->{high_water}
        && !$self->{transport_blocked}
        && !$self->{transport_aborted};
    unless ($ready) {
        $self->{output_blocked} = 1
            if length($self->{output}) >= $self->{high_water};
        $self->{transport_producer_blocked} = 1
            if $self->{transport_blocked};
    }
    return $ready ? 1 : 0;
}

sub _sync_native_output {
    my ($self) = @_;
    return 1 unless $self->{backend} eq 'native';
    my $wire = $self->{native}->flush;
    return $self->_queue_wire($wire);
}

sub _queue_portable_frame {
    my ($self, $opcode, $payload, %option) = @_;
    my %mask;
    if ($self->{role} eq 'client') {
        my $key = $self->{random_bytes}
            ? $self->{random_bytes}->(4)
            : Unblock::WebSocket::_Random->bytes(4);
        croak 'random byte provider must return exactly four bytes for a mask key'
            if !defined($key) || ref($key) || length($key) != 4;
        %mask = (mask_key => $key);
    }
    my $wire = Unblock::WebSocket::_Frame->encode(
        opcode  => $opcode,
        payload => $payload,
        masked  => $self->{role} eq 'client' ? 1 : 0,
        %mask,
        %option,
    );
    return $self->_queue_wire($wire);
}

sub _queue_frame {
    my ($self, $opcode, $payload, %option) = @_;

    if ($self->{deflate} && ($opcode == 1 || $opcode == 2)) {
        $payload = $self->{deflate}->compress($payload);
        $option{rsv1} = 1;
    }

    if ($self->{backend} eq 'native') {
        my $compressed = delete($option{rsv1}) ? 1 : 0;
        croak 'native frame options are internal-only' if %option;

        # A native input batch can contain a complete valid message followed by
        # a malformed frame. bq has already entered error/closing state by the
        # time Perl receives the earlier valid event, so its normal send API
        # refuses the application response. Preserve wire ordering by encoding
        # only responses generated while delivering those retained pre-error
        # events through the portable framer. This is an exceptional error
        # path; ordinary native traffic remains fully native.
        if ($self->{native_pre_error_event}
            && $self->{native}->_error_code) {
            return $self->_queue_portable_frame(
                $opcode,
                $payload,
                ($compressed ? (rsv1 => 1) : ()),
            );
        }

        $self->{native}->queue_message(
            $opcode,
            $payload,
            $compressed,
        );
        return $self->_sync_native_output;
    }

    return $self->_queue_portable_frame($opcode, $payload, %option);
}

sub send_text {
    my ($self, $text) = @_;
    croak 'send_text(): WebSocket is closing or closed' unless $self->is_open;
    croak 'send_text(): text must be a defined scalar'
        if !defined($text) || ref($text);
    my $bytes;
    if (utf8::is_utf8($text)) {
        $bytes = Unblock::WebSocket::_UTF8->encode($text);
    }
    else {
        $bytes = "$text";
        croak 'send_text(): payload contains invalid UTF-8'
            unless Unblock::WebSocket::_UTF8->valid_bytes($bytes);
    }
    return $self->_queue_frame(1, $bytes);
}

sub send_binary {
    my ($self, $bytes) = @_;
    croak 'send_binary(): WebSocket is closing or closed' unless $self->is_open;
    croak 'send_binary(): payload must be a defined scalar'
        if !defined($bytes) || ref($bytes);
    my $copy = "$bytes";
    croak 'send_binary(): payload must be a byte string'
        unless utf8::downgrade($copy, 1);
    return $self->_queue_frame(2, $copy);
}

sub ping {
    my ($self, $bytes) = @_;
    $bytes = '' unless defined $bytes;
    croak 'ping(): WebSocket is closing or closed' unless $self->is_open;
    croak 'ping(): payload must be a scalar' if ref($bytes);
    my $copy = "$bytes";
    croak 'ping(): payload must be a byte string'
        unless utf8::downgrade($copy, 1);
    croak 'ping(): payload exceeds 125 bytes' if length($copy) > 125;
    return $self->_queue_frame(9, $copy);
}

sub _valid_close_code {
    my ($code) = @_;
    return 1 if $VALID_CLOSE{$code};
    return 1 if $code >= 3000 && $code <= 4999;
    return 0;
}

sub _close_payload {
    my ($code, $reason) = @_;
    return '' unless defined $code;
    croak 'close(): code must be an integer from 1000 through 4999'
        unless !ref($code) && $code =~ /\A[0-9]+\z/ && _valid_close_code($code);
    $reason = '' unless defined $reason;
    croak 'close(): reason must be a scalar' if ref($reason);
    my $bytes = utf8::is_utf8($reason)
        ? Unblock::WebSocket::_UTF8->encode($reason)
        : "$reason";
    croak 'close(): reason contains invalid UTF-8'
        unless Unblock::WebSocket::_UTF8->valid_bytes($bytes);
    croak 'close(): reason exceeds 123 bytes' if length($bytes) > 123;
    return pack('n', $code) . $bytes;
}

sub close {
    my ($self, %option) = @_;
    croak 'close(): cannot be called from unblock_send()'
        if $self->{transport_in_send};
    return $self if $self->{closed} || $self->{sent_close};
    my $code = exists($option{code}) ? delete($option{code}) : 1000;
    my $reason = delete $option{reason};
    croak 'close(): unknown option(s): ' . join(', ', sort keys %option)
        if %option;
    my $payload = _close_payload($code, $reason);
    if ($self->{backend} eq 'native') {
        $reason = '' unless defined $reason;
        $self->{native}->queue_close($code, $reason);
        $self->_sync_native_output;
    }
    else {
        $self->_queue_frame(8, $payload);
    }
    $self->{sent_close} = 1;
    return $self;
}

sub abort {
    my ($self) = @_;
    if ($self->{transport_attached}) {
        $self->_transport_abort('WebSocket aborted');
    }
    else {
        $self->{closed} = 1;
        $self->{output} = '';
    }
    return $self;
}

sub input_eof {
    my ($self) = @_;
    return $self if $self->{closed};
    croak 'input_eof(): cannot be called recursively from a callback'
        if $self->{driving} || $self->{transport_syncing};
    if ($self->{transport_attached} && !$self->{received_close}) {
        $self->_transport_abort('transport EOF without WebSocket Close');
        return $self;
    }
    $self->{closed} = 1;
    $self->_invoke('on_close', undef, 'transport EOF')
        unless $self->{received_close};
    $self->_transport_sync if $self->{transport_attached};
    return $self;
}

sub output {
    my ($self, $max) = @_;
    croak 'output(): manual output is unavailable with an attached transport'
        if $self->{transport_attached};
    croak 'output(): cannot be called recursively from a callback'
        if $self->{driving};
    return '' unless length $self->{output};

    my $take = length($self->{output});
    if (defined $max) {
        croak 'output(): maximum must be a positive integer'
            unless !ref($max) && $max =~ /\A[0-9]+\z/ && $max > 0;
        $take = $max if $max < $take;
    }

    my $bytes = substr($self->{output}, 0, $take, '');
    $self->_notify_drain;
    return $bytes;
}

sub input {
    my ($self, $bytes) = @_;
    croak 'input(): WebSocket is closed' if $self->{closed};
    croak 'input(): cannot be called recursively from a callback'
        if $self->{driving} || $self->{transport_syncing};

    if ($self->{backend} eq 'native') {
        croak 'input(): bytes must be a scalar' if ref($bytes);
        $bytes = '' unless defined $bytes;
        my $copy = "$bytes";
        croak 'input(): bytes must be a byte string'
            unless utf8::downgrade($copy, 1);

        my $events = $self->{native}->feed($copy);
        my $error_code = $self->{native}->_error_code;
        {
            local $self->{driving} = 1;
            local $self->{native_pre_error_event} = $error_code ? 1 : 0;
            $self->_handle_native_events($events);
        }

        if ($error_code && !$self->{failed}) {
            my $error = $self->{native}->_error_string;
            my %message = (
                LIMIT_MAX_RECV_MSG_SIZE => 'WebSocket message exceeds configured limit',
                BAD_UTF8                => 'WebSocket text contains invalid UTF-8',
                RESERVED_BIT            => 'WebSocket frame uses reserved RSV bits',
                BAD_CLOSE               => 'invalid WebSocket Close payload',
            );
            $error = $message{$error} || "native WebSocket error: $error";
            $self->{failed} = 1;
            $self->{sent_close} = 1;
            $self->_invoke('on_error', $error);
        }
        $self->_sync_native_output;
        $self->_transport_sync if $self->{transport_attached};
        return length($copy);
    }

    my $count = $self->{parser}->input($bytes);
    {
        local $self->{driving} = 1;
        while (!$self->{closed}) {
            my $frame;
            my $ok = eval { $frame = $self->{parser}->next_frame; 1 };
            if (!$ok) {
                my $error = $@ || 'WebSocket frame parse failure';
                my $code = $error =~ /exceeds configured limit/ ? 1009 : 1002;
                $self->_fail($error, $code);
                last;
            }
            last unless $frame;
            $self->_handle_frame($frame);
        }
    }
    $self->_transport_sync if $self->{transport_attached};
    return $count;
}

sub _handle_native_events {
    my ($self, $events) = @_;
    for my $event (@$events) {
        last if $self->{closed} || $self->{failed};
        my ($opcode, $payload, $flags) = @$event;
        $flags ||= 0;

        if ($opcode == 1 || $opcode == 2) {
            my $compressed = ($flags & 0x01) ? 1 : 0;
            $self->_deliver_message($opcode, $payload, $compressed);
        }
        elsif ($opcode == 8) {
            $self->_handle_native_close($payload);
        }
        elsif ($opcode == 9) {
            $self->_invoke('on_ping', $payload);
        }
        elsif ($opcode == 10) {
            $self->_invoke('on_pong', $payload);
        }
        else {
            $self->_fail('native WebSocket engine returned unsupported event', 1002);
        }
    }
    return;
}

sub _handle_native_close {
    my ($self, $payload) = @_;
    return if $self->{received_close};

    my ($code, $reason);
    my $ok = eval { ($code, $reason) = _parse_close($payload); 1 };
    return $self->_fail($@ || 'invalid WebSocket Close payload', 1002)
        unless $ok;

    $self->{received_close} = 1;
    $self->{sent_close} = 1 unless $self->{sent_close};
    $self->_invoke('on_close', $code, $reason);
    return;
}

sub _handle_frame {
    my ($self, $frame) = @_;
    my $opcode = $frame->{opcode};

    if ($opcode == 0) {
        return $self->_fail(
            'WebSocket continuation frame outside fragmented message', 1002
        ) unless defined $self->{fragment_opcode};

        $self->{fragment_payload} .= $frame->{payload};
        my $limit = $self->{fragment_compressed}
            ? _compressed_wire_limit($self->{max_message_size})
            : $self->{max_message_size};
        return $self->_fail('WebSocket message exceeds configured limit', 1009)
            if length($self->{fragment_payload}) > $limit;

        if ($frame->{fin}) {
            my $type_opcode = delete $self->{fragment_opcode};
            my $payload = $self->{fragment_payload};
            my $compressed = $self->{fragment_compressed} ? 1 : 0;
            $self->{fragment_payload} = '';
            $self->{fragment_compressed} = 0;
            $self->_deliver_message($type_opcode, $payload, $compressed);
        }
        return;
    }

    if ($opcode == 1 || $opcode == 2) {
        return $self->_fail(
            'WebSocket data frame while fragmented message is unfinished', 1002
        ) if defined $self->{fragment_opcode};

        my $compressed = $frame->{rsv1} ? 1 : 0;
        if (!$frame->{fin}) {
            $self->{fragment_opcode} = $opcode;
            $self->{fragment_payload} = $frame->{payload};
            $self->{fragment_compressed} = $compressed;

            my $limit = $compressed
                ? _compressed_wire_limit($self->{max_message_size})
                : $self->{max_message_size};
            return $self->_fail('WebSocket message exceeds configured limit', 1009)
                if length($self->{fragment_payload}) > $limit;
            return;
        }
        return $self->_deliver_message(
            $opcode,
            $frame->{payload},
            $compressed,
        );
    }

    if ($opcode == 8) {
        return $self->_handle_close($frame->{payload});
    }

    if ($opcode == 9) {
        $self->_invoke('on_ping', $frame->{payload});
        $self->_queue_frame(10, $frame->{payload})
            unless $self->{closed} || $self->{failed};
        return;
    }

    if ($opcode == 10) {
        $self->_invoke('on_pong', $frame->{payload});
        return;
    }

    return $self->_fail('WebSocket frame has unsupported opcode', 1002);
}

sub _deliver_message {
    my ($self, $opcode, $payload, $compressed) = @_;

    if ($compressed) {
        my $ok = eval {
            $payload = $self->{deflate}->decompress($payload);
            1;
        };
        if (!$ok) {
            my $error = $@ || 'permessage-deflate decompression failed';
            my $code = $error =~ /exceeds configured limit/ ? 1009 : 1002;
            return $self->_fail($error, $code);
        }
    }

    return $self->_fail('WebSocket message exceeds configured limit', 1009)
        if length($payload) > $self->{max_message_size};

    if ($opcode == 1) {
        my $text = eval { Unblock::WebSocket::_UTF8->decode($payload) };
        return $self->_fail('WebSocket text contains invalid UTF-8', 1007)
            if $@;
        $self->_invoke('on_message', $text, 'text');
    }
    else {
        $self->_invoke('on_message', $payload, 'binary');
    }
    return;
}

sub _parse_close {
    my ($payload) = @_;
    return (undef, '') if length($payload) == 0;
    croak 'WebSocket Close payload has invalid one-byte length'
        if length($payload) == 1;

    my $code = unpack('n', substr($payload, 0, 2));
    croak "WebSocket Close uses invalid status code $code"
        unless _valid_close_code($code);
    my $reason_bytes = substr($payload, 2);
    my $reason = '';
    if (length $reason_bytes) {
        $reason = Unblock::WebSocket::_UTF8->decode($reason_bytes);
    }
    return ($code, $reason);
}

sub _handle_close {
    my ($self, $payload) = @_;
    return if $self->{received_close};

    my ($code, $reason);
    my $ok = eval { ($code, $reason) = _parse_close($payload); 1 };
    if (!$ok) {
        my $error = $@ || 'invalid WebSocket Close payload';
        my $close_code = $error =~ /UTF-8|Unicode scalar/i ? 1007 : 1002;
        return $self->_fail($error, $close_code);
    }

    $self->{received_close} = 1;
    if (!$self->{sent_close}) {
        $self->_queue_frame(8, $payload);
        $self->{sent_close} = 1;
    }
    $self->_invoke('on_close', $code, $reason);
    return;
}

sub _fail {
    my ($self, $error, $close_code) = @_;
    return if $self->{failed}++;
    $error = "$error";
    $error =~ s/\s+\z//;
    $self->_invoke('on_error', $error);
    if (!$self->{sent_close} && !$self->{closed}) {
        if ($self->{backend} eq 'native') {
            my $ok = eval { $self->{native}->queue_close($close_code, ''); 1 };
            $self->_sync_native_output if $ok;
        }
        else {
            my $payload = eval { _close_payload($close_code, '') };
            $self->_queue_frame(8, $payload) if defined $payload;
        }
        $self->{sent_close} = 1;
    }
    return;
}

1;
