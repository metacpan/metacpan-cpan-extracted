package Unblock::HTTP2::_Connection;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed weaken);
use utf8 ();

our $VERSION = '0.11';

my @SETTING_NAMES = qw(
    header_table_size
    enable_push
    max_concurrent_streams
    initial_window_size
    max_frame_size
    max_header_list_size
    enable_connect_protocol
    no_rfc7540_priorities
);

my %SETTING_ID = (
    header_table_size       => 1,
    enable_push             => 2,
    max_concurrent_streams  => 3,
    initial_window_size     => 4,
    max_frame_size          => 5,
    max_header_list_size    => 6,
    enable_connect_protocol => 8,
    no_rfc7540_priorities    => 9,
);

my %SETTING_NAME = reverse %SETTING_ID;


sub _initialize_connection {
    my ($self, $session, %option) = @_;

    croak 'HTTP/2 session must be an object'
        unless blessed($session);

    my $transport = delete $option{transport};
    if (defined $transport) {
        croak 'new(): transport must be an object' unless blessed($transport);
        for my $method (qw(unblock_send unblock_finish unblock_abort)) {
            croak "new(): transport must implement $method()"
                unless $transport->can($method);
        }
    }
    my $role = delete $option{role};
    my $callbacks = delete($option{callbacks}) || {};

    croak 'HTTP/2 connection role must be client or server'
        unless defined($role) && ($role eq 'client' || $role eq 'server');
    croak 'HTTP/2 connection callbacks must be a hash reference'
        unless ref($callbacks) eq 'HASH';
    croak 'unknown HTTP/2 connection options: ' . join(', ', sort keys %option)
        if %option;

    $self->{transport}          = $transport;
    weaken($self->{transport}) if defined $transport;
    $self->{transport_attached} = defined($transport) ? 1 : 0;
    $self->{transport_blocked}  = 0;
    $self->{transport_syncing}  = 0;
    $self->{transport_finished} = 0;
    $self->{transport_aborted}  = 0;
    $self->{transport_graceful} = 0;
    $self->{transport_pending}  = '';
    $self->{input_eof}          = 0;
    $self->{session}          = $session;
    $self->{role}             = $role;
    $self->{callbacks}        = $callbacks;
    $self->{transactions}          = {};
    $self->{closed}           = 0;
    $self->{close_reason}      = undef;
    $self->{in_session_call}  = 0;
    $self->{close_pending}    = undef;
    $self->{pending_drain}    = {};
    $self->{local_settings}   = {};
    $self->{peer_settings}    = {};
    $self->{settings_pending} = [];
    $self->{local_goaway}      = undef;

    $self->_refresh_peer_settings;
    return $self;
}

sub is_closed {
    return $_[0]{closed} ? 1 : 0;
}

sub close_reason {
    return $_[0]{close_reason};
}

sub transaction_count {
    return scalar keys %{ $_[0]{transactions} };
}

sub transaction_for_stream_id {
    my ($self, $stream_id) = @_;
    return $self->{transactions}{$stream_id};
}

sub want_read {
    my ($self) = @_;
    return 0 if $self->{closed} || !$self->{session} || $self->{input_eof};
    return $self->{session}->want_read ? 1 : 0;
}

sub want_write {
    my ($self) = @_;
    return 0 if $self->{closed} || !$self->{session};
    return $self->{session}->want_write ? 1 : 0;
}

sub input {
    my ($self, $bytes) = @_;

    croak 'input(): connection is closed' if $self->{closed};
    croak 'input(): read side is already at EOF' if $self->{input_eof};
    croak 'input(): cannot be called from unblock_send()'
        if $self->{transport_syncing};
    croak 'input(): bytes must be a scalar' if ref($bytes);
    return 0 unless defined($bytes) && length($bytes);
    croak 'input(): cannot be called from an HTTP/2 session callback'
        if $self->{in_session_call};

    my $consumed;
    my $ok = eval {
        local $self->{in_session_call} = 1;
        $consumed = $self->{session}->mem_recv($bytes);
        1;
    };

    if (!$ok) {
        my $error = length($@) ? "$@" : 'input(): nghttp2 receive failed';
        $self->_finish_close($error) unless $self->{closed};
        die $error;
    }

    if (!defined($consumed) || $consumed != length($bytes)) {
        my $error = 'input(): nghttp2 did not consume complete input';
        $self->_finish_close($error);
        croak $error;
    }

    if (defined $self->{close_pending}) {
        $self->_finish_close(delete $self->{close_pending});
        return $consumed;
    }

    $self->_after_session_call;
    $self->_transport_sync if $self->{transport_attached};
    return $consumed;
}

sub output {
    my ($self) = @_;
    croak 'output(): manual output is unavailable with an attached transport'
        if $self->{transport_attached};
    return $self->_output_raw;
}

sub _output_raw {
    my ($self) = @_;

    croak 'output(): connection is closed' if $self->{closed};
    croak 'output(): cannot be called from an HTTP/2 session callback'
        if $self->{in_session_call};

    return '' unless $self->{session}->want_write;

    my $bytes;
    my $ok = eval {
        local $self->{in_session_call} = 1;
        $bytes = $self->{session}->mem_send;
        1;
    };

    if (!$ok) {
        my $error = length($@) ? "$@" : 'output(): nghttp2 send failed';
        $self->_finish_close($error) unless $self->{closed};
        die $error;
    }

    if (defined $self->{close_pending}) {
        $self->_finish_close(delete $self->{close_pending});
        return defined($bytes) ? $bytes : '';
    }

    $bytes = '' unless defined $bytes;

    $self->_after_session_call;
    return $bytes;
}


# nghttp2 generates wire buffers on demand. An attached transport accepts
# each complete buffer into its own output queue before reporting congestion.
sub _transport_sync {
    my ($self) = @_;
    return unless $self->{transport_attached};
    return if $self->{transport_syncing} || $self->{in_session_call};
    return if $self->{transport_aborted} || $self->{transport_finished};
    return if $self->{transport_blocked};

    my $host = $self->{transport};
    return $self->_transport_abort('HTTP/2 transport was destroyed')
        unless $host;

    {
        local $self->{transport_syncing} = 1;
        while (!$self->{transport_blocked}) {
            my $bytes;
            if (length $self->{transport_pending}) {
                $bytes = $self->{transport_pending};
                $self->{transport_pending} = '';
            }
            elsif (!$self->{closed} && $self->{session}
                    && $self->{session}->want_write) {
                my $ok = eval { $bytes = $self->_output_raw; 1 };
                unless ($ok) {
                    $self->_transport_abort("$@" || 'HTTP/2 output failed');
                    return;
                }
            }
            else {
                last;
            }
            last unless defined($bytes) && length($bytes);

            my $ready;
            my $ok = eval { $ready = $host->unblock_send($bytes); 1 };
            unless ($ok) {
                $self->_transport_abort("$@" || 'unblock_send() failed');
                return;
            }
            $self->{transport_blocked} = 1 if defined($ready) && !$ready;
        }
    }

    if ($self->{closed} && $self->{transport_graceful}
            && !length($self->{transport_pending})
            && !$self->{transport_blocked}
            && !$self->{transport_finished}
            && !$self->{transport_aborted}) {
        $self->{transport_finished} = 1;
        my $ok = eval { $host->unblock_finish(); 1 };
        $self->_transport_abort("$@" || 'unblock_finish() failed') unless $ok;
    }
    return;
}

sub resume_output {
    my ($self) = @_;
    croak 'resume_output(): no attached transport'
        unless $self->{transport_attached};
    croak 'resume_output(): cannot be called from unblock_send()'
        if $self->{transport_syncing};
    return $self if $self->{transport_finished} || $self->{transport_aborted};
    $self->{transport_blocked} = 0;
    $self->_transport_sync;
    if (!$self->{transport_blocked} && !$self->{closed}) {
        # Producers can have paused because the host, rather than their own
        # stream queue, was congested. Wake only those below low water.
        for my $id (keys %{ $self->{providers} || {} }) {
            my $provider = $self->{providers}{$id};
            next unless $provider->{blocked};
            next unless length($provider->{queue}) < 32_768;
            $provider->{blocked} = 0;
            $self->_queue_drain($id);
        }
        $self->_after_session_call;
        $self->_transport_sync;
    }
    return $self;
}

sub _transport_abort {
    my ($self, $reason) = @_;
    return if $self->{transport_aborted};
    $self->{transport_aborted} = 1;
    $self->{transport_pending} = '';
    $self->{transport_graceful} = 0;
    $self->_finish_close($reason) unless $self->{closed};
    if (my $host = $self->{transport}) {
        eval { $host->unblock_abort($reason) };
    }
    return;
}

sub transport_error {
    my ($self, $reason) = @_;
    $reason = 'transport error' unless defined($reason) && length($reason);
    $self->_transport_abort("$reason");
    return $self;
}

sub input_eof {
    my ($self) = @_;
    return $self if $self->{input_eof} || $self->{closed};
    croak 'input_eof(): cannot be called during HTTP/2 input or host send'
        if $self->{in_session_call} || $self->{transport_syncing};
    $self->{input_eof} = 1;
    # Unlike HTTP/1, EOF never completes an HTTP/2 response body.
    $self->close('HTTP/2 transport reached EOF');
    return $self;
}

# Retain unsent wire output across explicit close, even while a host is paused.
sub _stage_final_output {
    my ($self) = @_;
    return unless $self->{transport_attached} && $self->{session};
    return if $self->{staging_final_output};
    local $self->{staging_final_output} = 1;
    while ($self->{session} && $self->{session}->want_write) {
        my $bytes = $self->_output_raw;
        last unless defined($bytes) && length($bytes);
        $self->{transport_pending} .= $bytes;
    }
    return;
}

sub _register_transaction {
    my ($self, $transaction) = @_;
    $self->{transactions}{ $transaction->stream_id } = $transaction;
    return $transaction;
}

sub _remove_transaction {
    my ($self, $stream_id) = @_;
    delete $self->{pending_drain}{$stream_id};
    return delete $self->{transactions}{$stream_id};
}

sub _queue_drain {
    my ($self, $stream_id) = @_;
    $self->{pending_drain}{$stream_id} = 1;
    return;
}

sub _reset_stream {
    my ($self, $transaction, $error_code) = @_;

    croak 'reset(): connection is closed'
        if $self->{closed} || !$self->{session};
    croak 'reset(): error code must be an unsigned 32-bit integer'
        unless defined($error_code) && !ref($error_code)
            && "$error_code" =~ /\A[0-9]+\z/
            && $error_code <= 4_294_967_295;

    $self->{session}->submit_rst_stream($transaction->stream_id, 0 + $error_code);
    $transaction->_mark_cancelled(0 + $error_code, 0);
    $self->_transport_sync if $self->{transport_attached};
    return;
}

sub _consume_stream_body {
    my ($self, $transaction, $bytes) = @_;

    croak 'consume(): connection is closed'
        if $self->{closed} || !$self->{session};
    return unless $bytes;

    $self->{session}->consume_stream($transaction->stream_id, $bytes);
    $self->_transport_sync if $self->{transport_attached};
    return;
}

sub local_goaway {
    my ($self) = @_;
    return unless $self->{local_goaway};
    return { %{ $self->{local_goaway} } };
}

sub goaway {
    my ($self, %option) = @_;

    croak 'goaway(): connection is closed'
        if $self->{closed} || !$self->{session};

    my $error_code = exists($option{error_code})
        ? delete($option{error_code})
        : 0;
    croak 'goaway(): error code must be an unsigned 32-bit integer'
        unless defined($error_code) && !ref($error_code)
            && "$error_code" =~ /\A[0-9]+\z/
            && $error_code <= 4_294_967_295;

    my $last_stream_id = exists($option{last_stream_id})
        ? delete($option{last_stream_id})
        : $self->{role} eq 'server'
            ? 0 + ($self->{last_peer_stream_id} || 0)
            : 0;

    croak 'goaway(): last_stream_id must be in the HTTP/2 31-bit range'
        unless defined($last_stream_id) && !ref($last_stream_id)
            && "$last_stream_id" =~ /\A[0-9]+\z/
            && $last_stream_id <= 2_147_483_647;

    my $debug_data = exists($option{debug_data})
        ? delete($option{debug_data})
        : '';
    $debug_data = $self->_body_bytes('goaway()', $debug_data);

    croak 'goaway(): unknown options: ' . join(', ', sort keys %option)
        if %option;

    if ($self->{local_goaway}
        && $last_stream_id > $self->{local_goaway}{last_stream_id}) {
        croak 'goaway(): last_stream_id cannot increase across GOAWAY frames';
    }

    $self->{session}->submit_goaway(
        last_stream_id => 0 + $last_stream_id,
        error_code     => 0 + $error_code,
        debug_data     => $debug_data,
    );

    $self->{local_goaway} = {
        last_stream_id => 0 + $last_stream_id,
        error_code     => 0 + $error_code,
        debug_data     => $debug_data,
    };
    $self->{draining} = 1 if exists $self->{draining};
    $self->_transport_sync if $self->{transport_attached};

    return $self;
}

sub ping {
    my ($self, $opaque) = @_;

    croak 'ping(): connection is closed'
        if $self->{closed} || !$self->{session};
    croak 'ping(): opaque data is required'
        unless defined $opaque;

    my $bytes = $self->_body_bytes('ping()', $opaque);
    croak 'ping(): opaque data must be exactly 8 bytes'
        unless length($bytes) == 8;

    $self->{session}->submit_ping($bytes);
    $self->_transport_sync if $self->{transport_attached};
    return $self;
}

sub _handle_ping_frame {
    my ($self, $frame) = @_;
    return 0 unless (($frame->{type} // -1) == 6);

    my $opaque = defined($frame->{opaque_data})
        ? "$frame->{opaque_data}"
        : '';

    my $callback = (($frame->{flags} || 0) & 0x1)
        ? 'on_ping_ack'
        : 'on_ping';

    $self->_invoke_control_callback($callback, $opaque);
    return 1;
}

sub _update_stream_priority {
    my ($self, $transaction, $field_value) = @_;

    croak 'update_priority(): connection is closed'
        if $self->{closed} || !$self->{session};
    croak 'update_priority(): only clients can send PRIORITY_UPDATE'
        unless $self->{role} eq 'client';

    my $bytes = $self->_body_bytes('update_priority()', $field_value);
    croak 'update_priority(): field value exceeds HTTP/2 PRIORITY_UPDATE limit'
        if length($bytes) > 16_380;

    my $enabled = $self->peer_setting('no_rfc7540_priorities');
    croak 'update_priority(): peer has not enabled RFC 9218 priorities'
        unless $enabled == 1;

    $self->{session}->submit_priority_update($transaction->stream_id, $bytes);
    $self->_transport_sync if $self->{transport_attached};
    return;
}

sub _handle_priority_update_frame {
    my ($self, $frame) = @_;
    return 0 unless (($frame->{type} // -1) == 0x10);

    my $stream_id = 0 + ($frame->{prioritized_stream_id} || 0);
    my $field_value = defined($frame->{priority_field_value})
        ? "$frame->{priority_field_value}"
        : '';

    $self->_invoke_control_callback(
        'on_priority',
        $stream_id,
        $field_value,
    );
    return 1;
}

sub local_settings {
    my ($self) = @_;
    return { %{ $self->{local_settings} || {} } };
}

sub local_setting {
    my ($self, $name) = @_;
    croak 'local_setting(): setting name is required'
        unless defined($name) && !ref($name) && length($name);
    croak "local_setting(): unknown setting '$name'"
        unless exists $SETTING_ID{$name};
    return $self->{local_settings}{$name};
}

sub peer_settings {
    my ($self) = @_;
    $self->_refresh_peer_settings
        if !$self->{closed} && $self->{session};
    return { %{ $self->{peer_settings} || {} } };
}

sub peer_setting {
    my ($self, $name) = @_;
    croak 'peer_setting(): setting name is required'
        unless defined($name) && !ref($name) && length($name);
    croak "peer_setting(): unknown setting '$name'"
        unless exists $SETTING_ID{$name};

    $self->_refresh_peer_settings
        if !$self->{closed} && $self->{session};
    return $self->{peer_settings}{$name};
}

sub settings_pending {
    my ($self) = @_;
    return scalar @{ $self->{settings_pending} || [] };
}

sub update_settings {
    my ($self, @settings) = @_;

    croak 'update_settings(): connection is closed'
        if $self->{closed} || !$self->{session};

    my $input;
    if (@settings == 1 && ref($settings[0]) eq 'HASH') {
        $input = $settings[0];
    }
    elsif (@settings && @settings % 2 == 0) {
        $input = { @settings };
    }
    else {
        croak 'update_settings(): expected a hash reference or key/value pairs';
    }

    $self->_submit_settings('update_settings()', $input);
    $self->_transport_sync if $self->{transport_attached};
    return $self;
}

sub _submit_settings {
    my ($self, $operation, $input) = @_;
    my $settings = $self->_validate_settings($operation, $input);

    $self->{session}->submit_settings($settings);

    my %submitted = %$settings;
    push @{ $self->{settings_pending} }, \%submitted;
    @{$self->{local_settings}}{keys %submitted} = values %submitted;

    if (exists $submitted{max_header_list_size}) {
        $self->{max_header_list_size} = $submitted{max_header_list_size};
    }
    if ($self->{role} eq 'server') {
        if (exists $submitted{max_concurrent_streams}) {
            $self->{max_concurrent_streams} = $submitted{max_concurrent_streams};
        }
        if (exists $submitted{enable_connect_protocol}) {
            $self->{enable_connect_protocol}
                = $submitted{enable_connect_protocol};
        }
    }

    return $self;
}

sub _validate_settings {
    my ($self, $operation, $input) = @_;

    croak "$operation settings must be a hash reference"
        unless ref($input) eq 'HASH';
    croak "$operation requires at least one setting"
        unless keys %$input;

    my %settings;
    for my $name (keys %$input) {
        croak "$operation unknown setting '$name'"
            unless exists $SETTING_ID{$name};

        my $value = $input->{$name};
        croak "$operation $name must be an unsigned integer"
            unless defined($value) && !ref($value)
                && "$value" =~ /\A[0-9]+\z/;

        $value = 0 + $value;

        if ($name eq 'enable_push'
            || $name eq 'enable_connect_protocol'
            || $name eq 'no_rfc7540_priorities') {
            croak "$operation $name must be zero or one"
                unless $value == 0 || $value == 1;
        }
        elsif ($name eq 'initial_window_size') {
            croak "$operation initial_window_size exceeds HTTP/2 maximum"
                if $value > 2_147_483_647;
        }
        elsif ($name eq 'max_frame_size') {
            croak "$operation max_frame_size must be between 16384 and 16777215"
                if $value < 16_384 || $value > 16_777_215;
        }
        else {
            croak "$operation $name exceeds HTTP/2 maximum"
                if $value > 4_294_967_295;
        }

        $settings{$name} = $value;
    }

    if (exists $settings{enable_connect_protocol}
        && ($self->{local_settings}{enable_connect_protocol} || 0) == 1
        && $settings{enable_connect_protocol} == 0) {
        croak "$operation enable_connect_protocol cannot return to zero after one";
    }

    if (exists $settings{no_rfc7540_priorities}
        && exists $self->{local_settings}{no_rfc7540_priorities}
        && $settings{no_rfc7540_priorities}
            != $self->{local_settings}{no_rfc7540_priorities}) {
        croak "$operation no_rfc7540_priorities cannot change after the first SETTINGS frame";
    }

    if ($self->{role} eq 'client') {
        croak "$operation enable_push=1 is unsupported because server push is disabled"
            if ($settings{enable_push} || 0) == 1;
    }
    elsif (exists $settings{enable_push}) {
        croak "$operation a server must not send enable_push";
    }

    return \%settings;
}

sub _refresh_peer_settings {
    my ($self) = @_;
    return $self->{peer_settings}
        unless $self->{session};

    my %settings;
    for my $name (@SETTING_NAMES) {
        $settings{$name}
            = 0 + $self->{session}->remote_setting($SETTING_ID{$name});
    }

    # ENABLE_PUSH is a client-to-server setting.  It has no server-advertised
    # peer value for a client, and Unblock does not support server push.
    $settings{enable_push} = 0 if $self->{role} eq 'client';

    $self->{peer_settings} = \%settings;
    return $self->{peer_settings};
}

sub _handle_settings_frame {
    my ($self, $frame) = @_;
    return 0 unless (($frame->{type} // -1) == 4);

    if (($frame->{flags} || 0) & 0x1) {
        my $acked = shift @{ $self->{settings_pending} };
        $acked ||= {};
        $self->_invoke_control_callback(
            'on_settings_ack',
            { %$acked },
        );
        return 1;
    }

    my %changed;
    for my $pair (@{ $frame->{settings} || [] }) {
        next unless ref($pair) eq 'ARRAY' && @$pair >= 2;
        my ($id, $value) = @$pair;
        my $name = $SETTING_NAME{$id};
        next unless defined $name;
        $changed{$name} = 0 + $value;
    }

    my $peer = $self->_refresh_peer_settings;
    $self->_invoke_control_callback(
        'on_settings',
        { %$peer },
        \%changed,
    );

    return 1;
}

sub _invoke_control_callback {
    my ($self, $name, @args) = @_;
    my $callback = $self->{callbacks}{$name} or return 1;

    my $ok = eval {
        $callback->($self, @args);
        1;
    };

    return 1 if $ok;

    my $error = "$name callback failed";
    $error .= ": $@" if length $@;
    # An application control callback exception is fatal, not an explicit
    # graceful close. Defer teardown until libnghttp2 has returned when the
    # callback runs from inside a native receive/send call.
    if ($self->{in_session_call}) {
        $self->{close_pending} = $error;
    }
    else {
        $self->_finish_close($error);
    }
    return 0;
}

sub _after_session_call {
    my ($self) = @_;

    my @ids = keys %{ $self->{pending_drain} };
    $self->{pending_drain} = {};

    for my $stream_id (@ids) {
        my $transaction = $self->{transactions}{$stream_id} or next;
        next if $transaction->is_terminal;

        my $result = $transaction->_drain;
        next if $result && $result eq '1';

        if ($result && $result ne '1') {
            $self->_stream_failure($stream_id, "$result");
        }
    }

    return;
}

sub _body_bytes {
    my ($self, $operation, $bytes) = @_;

    croak "$operation: body must be a scalar" if ref($bytes);
    $bytes = '' unless defined $bytes;

    my $copy = "$bytes";
    if (utf8::is_utf8($copy)) {
        croak "$operation: body must be a byte string"
            unless utf8::downgrade($copy, 1);
    }

    return $copy;
}

sub close {
    my ($self, $error) = @_;
    return $self if $self->{closed};

    $error = 'HTTP/2 connection closed'
        unless defined($error) && length($error);

    $self->{transport_graceful} = 1 if $self->{transport_attached};
    if ($self->{in_session_call}) {
        $self->{close_pending} = "$error";
        return $self;
    }

    return $self->_finish_close($error);
}

sub _finish_close {
    my ($self, $error) = @_;
    return $self if $self->{closed};

    if ($self->{transport_graceful} && !$self->{transport_aborted}) {
        my $ok = eval { $self->_stage_final_output; 1 };
        $self->{transport_graceful} = 0 unless $ok;
    }
    $self->{closed} = 1;
    $self->{close_reason} = "$error";

    for my $transaction (values %{ $self->{transactions} }) {
        next if $transaction->is_terminal;
        $transaction->_fail($error);
        $self->_invoke_stream_error($transaction, $error);
    }

    $self->{transactions} = {};
    $self->{pending_drain} = {};
    $self->{session} = undef;
    if ($self->{transport_attached}) {
        if ($self->{transport_graceful}) {
            $self->_transport_sync;
        }
        elsif (!$self->{transport_aborted}) {
            $self->_transport_abort($error);
        }
    }
    return $self;
}

sub _invoke_stream_error {
    my ($self, $transaction, $error, $error_code) = @_;
    my $result = $transaction->_invoke('on_error', $error, $error_code);
    return $result;
}

1;
