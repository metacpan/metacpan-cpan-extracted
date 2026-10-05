package Unblock::HTTP3::Connection;

use strict;
use warnings;
use Carp qw(croak);
use Uniform::HTTP::Request 0.06 ();
use Uniform::HTTP::Response 0.06 ();
use Scalar::Util qw(blessed weaken);
use Time::HiRes ();

use Unblock::HTTP3 ();
use Unblock::HTTP3::_Native ();
use Unblock::HTTP3::Transaction ();
use Net::QUIC::Connection ();

our $VERSION = '0.03';

my $H3_DATAGRAM_ERROR = 0x33;
my $H3_CLOSED_CRITICAL_STREAM = 0x0104;
my $H3_EXCESSIVE_LOAD = 0x0107;
my $H3_ID_ERROR = 0x0108;
my $H3_SETTINGS_ERROR = 0x0109;
my $QPACK_DECODER_STREAM_ERROR = 0x0202;
my $H3_REQUEST_CANCELLED = 0x010c;
my $H3_MESSAGE_ERROR = 0x010e;
my $HTTP3_MAX_VARINT = '4611686018427387903';
my $HTTP3_MAX_QUARTER_STREAM_ID = '1152921504606846975';
my $SETTINGS_STATE_MAGIC = "UH3S";
my $SETTINGS_STATE_VERSION = 1;

my %SETTING_DEFAULT = (
    1  => '0',
    6  => $HTTP3_MAX_VARINT,
    7  => '0',
    8  => '0',
    51 => '0',
);

my %CORE_SETTING_ID = map { $_ => 1 } qw(1 6 7 8 51);
my %RESERVED_SETTING_ID = map { $_ => 1 } qw(0 2 3 4 5);
my %CORE_STREAM_TYPE = map { $_ => 1 } qw(0 1 2 3);
my %CONNECTION_SPECIFIC_FIELD = map { $_ => 1 } qw(
    connection
    keep-alive
    proxy-connection
    transfer-encoding
    upgrade
);

sub _decimal_mod {
    my ($value, $divisor) = @_;

    my $remainder = 0;

    for my $digit (split //, "$value") {
        $remainder = ($remainder * 10 + ord($digit) - 48) % $divisor;
    }

    return $remainder;
}

sub _is_grease_setting_id {
    my ($id) = @_;

    return 0 if length($id) < 2;
    return 0 if length($id) == 2 && $id lt '33';

    return _decimal_mod($id, 31) == 2 ? 1 : 0;
}

sub _assert_extension_setting_id {
    my ($id) = @_;

    croak "HTTP/3 setting $id is reserved for dedicated Unblock::HTTP3 support"
        if $CORE_SETTING_ID{$id};
    croak "HTTP/3 setting $id is reserved"
        if $RESERVED_SETTING_ID{$id};
    croak "HTTP/3 setting $id is reserved for greasing"
        if _is_grease_setting_id($id);

    return;
}

sub _is_peer_extension_setting_id {
    my ($id) = @_;

    return 0 if $CORE_SETTING_ID{$id};
    return 0 if $RESERVED_SETTING_ID{$id};
    return 0 if _is_grease_setting_id($id);

    return 1;
}

sub _is_grease_stream_type {
    my ($type) = @_;

    return 0 if length($type) < 2;
    return 0 if length($type) == 2 && $type lt '33';

    return _decimal_mod($type, 31) == 2 ? 1 : 0;
}

sub _assert_extension_stream_type {
    my ($type) = @_;

    croak "HTTP/3 stream type $type is managed by Unblock::HTTP3"
        if $CORE_STREAM_TYPE{$type};
    croak "HTTP/3 stream type $type is reserved for greasing"
        if _is_grease_stream_type($type);

    return;
}

sub _normalize_extension_stream_handlers {
    my ($handlers) = @_;

    return {} unless defined $handlers;

    croak 'extension_stream_handlers must be a hash reference'
        unless ref($handlers) eq 'HASH';

    my %normalized;

    for my $raw_type (keys %$handlers) {
        my $type = _normalize_http3_varint(
            $raw_type,
            'extension stream type',
        );

        _assert_extension_stream_type($type);

        my $callback = $handlers->{$raw_type};

        croak "extension stream handler for type $type must be a code reference"
            unless ref($callback) eq 'CODE';
        croak "duplicate extension stream type $type"
            if exists $normalized{$type};

        $normalized{$type} = $callback;
    }

    return \%normalized;
}

sub _exceeds_http3_varint {
    my ($value) = @_;

    my $text = "$value";
    $text =~ s/\A0+//;
    $text = '0' if $text eq '';

    return 1 if length($text) > length($HTTP3_MAX_VARINT);
    return 0 if length($text) < length($HTTP3_MAX_VARINT);

    return $text gt $HTTP3_MAX_VARINT ? 1 : 0;
}

sub _normalize_http3_varint {
    my ($value, $name) = @_;

    $name ||= 'HTTP/3 varint';

    croak "$name must be a non-negative integer"
        if !defined($value)
            || ref($value)
            || "$value" !~ /\A[0-9]+\z/;

    my $text = "$value";
    $text =~ s/\A0+(?=[0-9])//;

    croak "$name exceeds the HTTP/3 varint maximum"
        if _exceeds_http3_varint($text);

    return $text;
}

sub _encode_http3_varint {
    my ($value) = @_;
    $value = 0 + $value;

    return pack('C', $value)
        if $value <= 63;
    return pack('n', $value | 0x4000)
        if $value <= 16_383;
    return pack('N', $value | 0x80000000)
        if $value <= 1_073_741_823;

    my $high = (($value >> 32) & 0x3fffffff) | 0xc0000000;
    my $low = $value & 0xffffffff;

    return pack('NN', $high, $low);
}

sub _decode_http3_varint {
    my ($bytes, $offset) = @_;
    $offset ||= 0;

    return if $offset >= length($bytes);

    my $first = ord(substr($bytes, $offset, 1));
    my $length = (1, 2, 4, 8)[ $first >> 6 ];

    return if length($bytes) - $offset < $length;

    my $value;

    if ($length == 1) {
        $value = $first & 0x3f;
    } elsif ($length == 2) {
        $value = unpack('n', substr($bytes, $offset, 2)) & 0x3fff;
    } elsif ($length == 4) {
        $value = unpack('N', substr($bytes, $offset, 4)) & 0x3fffffff;
    } else {
        my ($high, $low) = unpack('NN', substr($bytes, $offset, 8));
        $high &= 0x3fffffff;
        $value = ($high << 32) | $low;
    }

    return ("$value", $length);
}

sub _encode_settings_state {
    my ($settings) = @_;

    croak 'HTTP/3 settings state requires a hash reference'
        unless ref($settings) eq 'HASH';

    my @ids = sort {
        length($a) <=> length($b)
            || $a cmp $b
    } keys %$settings;

    my $out = $SETTINGS_STATE_MAGIC
        . pack('C', $SETTINGS_STATE_VERSION)
        . _encode_http3_varint(scalar @ids);

    for my $id (@ids) {
        my $normalized_id = _normalize_http3_varint(
            $id,
            'settings state identifier',
        );
        my $value = _normalize_http3_varint(
            $settings->{$id},
            "settings state value for $normalized_id",
        );

        $out .= _encode_http3_varint($normalized_id);
        $out .= _encode_http3_varint($value);
    }

    return $out;
}

sub _decode_settings_state {
    my ($state, $name) = @_;
    $name ||= 'HTTP/3 settings state';

    croak "$name must be an opaque byte string returned by Unblock::HTTP3"
        if !defined($state) || ref($state);

    my $header_length = length($SETTINGS_STATE_MAGIC) + 1;
    croak "invalid $name"
        if length($state) < $header_length
            || substr($state, 0, length($SETTINGS_STATE_MAGIC))
                ne $SETTINGS_STATE_MAGIC
            || ord(substr($state, length($SETTINGS_STATE_MAGIC), 1))
                != $SETTINGS_STATE_VERSION;

    my $offset = $header_length;
    my ($count, $count_length) = _decode_http3_varint($state, $offset);
    croak "invalid $name" unless defined $count;
    $offset += $count_length;

    my %settings;

    for (1 .. 0 + $count) {
        my ($id, $id_length) = _decode_http3_varint($state, $offset);
        croak "invalid $name" unless defined $id;
        $offset += $id_length;

        my ($value, $value_length) = _decode_http3_varint($state, $offset);
        croak "invalid $name" unless defined $value;
        $offset += $value_length;

        croak "invalid $name: duplicate setting $id"
            if exists $settings{$id};

        $settings{$id} = $value;
    }

    croak "invalid $name: trailing bytes"
        if $offset != length($state);

    return \%settings;
}

sub _effective_setting {
    my ($settings, $id) = @_;

    return $settings->{$id}
        if exists $settings->{$id};

    return $SETTING_DEFAULT{$id}
        if exists $SETTING_DEFAULT{$id};

    return;
}

sub _settings_compatibility_error {
    my ($remembered, $current) = @_;

    my $old_qpack_capacity = _effective_setting($remembered, 1);
    my $new_qpack_capacity = _effective_setting($current, 1);

    if ($old_qpack_capacity ne '0') {
        if (
            !exists($current->{1})
            || $new_qpack_capacity ne $old_qpack_capacity
        ) {
            my $message =
                "SETTINGS_QPACK_MAX_TABLE_CAPACITY changed from "
                . "$old_qpack_capacity to $new_qpack_capacity";

            return wantarray
                ? ($QPACK_DECODER_STREAM_ERROR, $message)
                : $message;
        }
    }

    for my $id (qw(6 7 8 51)) {
        my $old = _effective_setting($remembered, $id);
        my $new = _effective_setting($current, $id);

        if (_decimal_less_than($new, $old)) {
            my $message = $id == 6
                ? "SETTINGS_MAX_FIELD_SECTION_SIZE decreased from $old to $new"
                : "HTTP/3 setting $id decreased from $old to $new";

            return wantarray
                ? ($H3_SETTINGS_ERROR, $message)
                : $message;
        }

        if (
            exists($remembered->{$id})
            && $remembered->{$id} ne $SETTING_DEFAULT{$id}
            && !exists($current->{$id})
        ) {
            my $message =
                "HTTP/3 setting $id was previously non-default but is now omitted";

            return wantarray
                ? ($H3_SETTINGS_ERROR, $message)
                : $message;
        }
    }

    for my $id (
        grep {
            _is_peer_extension_setting_id($_)
        } keys %$remembered
    ) {
        if (
            !exists($current->{$id})
            || $remembered->{$id} ne $current->{$id}
        ) {
            my $message = "extension setting $id changed across 0-RTT";

            return wantarray
                ? ($H3_SETTINGS_ERROR, $message)
                : $message;
        }
    }

    return wantarray ? () : undef;
}

sub _normalize_extension_settings {
    my ($settings) = @_;

    return {} unless defined $settings;

    croak 'extension_settings must be a hash reference'
        unless ref($settings) eq 'HASH';

    my %normalized;

    for my $raw_id (keys %$settings) {
        my $id = _normalize_http3_varint(
            $raw_id,
            'extension setting identifier',
        );

        _assert_extension_setting_id($id);

        my $value = _normalize_http3_varint(
            $settings->{$raw_id},
            "extension setting $id value",
        );

        croak "duplicate extension setting identifier $id"
            if exists $normalized{$id};

        $normalized{$id} = $value;
    }

    return \%normalized;
}

sub _rewrite_control_settings {
    my ($bytes, $extension_settings) = @_;

    my ($stream_type, $stream_type_length) =
        _decode_http3_varint($bytes, 0);

    croak 'libnghttp3 split the initial HTTP/3 control stream type'
        unless defined $stream_type;
    croak 'libnghttp3 produced an unexpected initial control stream type'
        unless $stream_type eq '0';

    my $frame_type_offset = $stream_type_length;
    my ($frame_type, $frame_type_length) =
        _decode_http3_varint($bytes, $frame_type_offset);

    croak 'libnghttp3 split the initial HTTP/3 SETTINGS frame type'
        unless defined $frame_type;
    croak 'libnghttp3 did not emit SETTINGS first on the control stream'
        unless $frame_type eq '4';

    my $frame_length_offset = $frame_type_offset + $frame_type_length;
    my ($frame_length, $frame_length_length) =
        _decode_http3_varint($bytes, $frame_length_offset);

    croak 'libnghttp3 split the initial HTTP/3 SETTINGS frame length'
        unless defined $frame_length;

    my $payload_offset = $frame_length_offset + $frame_length_length;
    my $payload_length = 0 + $frame_length;

    croak 'libnghttp3 split the initial HTTP/3 SETTINGS frame payload'
        if length($bytes) - $payload_offset < $payload_length;

    my $payload = substr($bytes, $payload_offset, $payload_length);
    my %existing;
    my $offset = 0;

    while ($offset < length($payload)) {
        my ($id, $id_length) = _decode_http3_varint($payload, $offset);
        croak 'libnghttp3 produced a malformed SETTINGS identifier'
            unless defined $id;
        $offset += $id_length;

        my ($value, $value_length) =
            _decode_http3_varint($payload, $offset);
        croak 'libnghttp3 produced a malformed SETTINGS value'
            unless defined $value;
        $offset += $value_length;

        croak "libnghttp3 produced duplicate SETTINGS identifier $id"
            if exists $existing{$id};

        $existing{$id} = $value;
    }

    my $extra = '';

    for my $id (
        sort {
            length($a) <=> length($b)
                || $a cmp $b
        } keys %$extension_settings
    ) {
        my $value = $extension_settings->{$id};

        if (exists $existing{$id}) {
            croak "extension setting $id conflicts with libnghttp3"
                if $existing{$id} ne $value;
            next;
        }

        $extra .= _encode_http3_varint($id);
        $extra .= _encode_http3_varint($value);
    }

    my $new_payload = $payload . $extra;
    my $payload_end = $payload_offset + $payload_length;

    my $rewritten =
        substr($bytes, 0, $frame_length_offset)
        . _encode_http3_varint(length($new_payload))
        . $new_payload
        . substr($bytes, $payload_end);

    return ($rewritten, length($bytes), length($rewritten) - length($bytes));
}

sub _inspect_peer_settings_bytes {
    my ($self, $id, $bytes) = @_;

    return unless ($id & 0x2) == 0x2;

    my $state = $self->{peer_settings_parser}{$id};

    if (!defined $state) {
        $state = {
            stage     => 'stream_type',
            buffer    => '',
            remaining => undef,
            settings  => {},
        };
        $self->{peer_settings_parser}{$id} = $state;
    }

    return if $state->{stage} eq 'ignore'
        || $state->{stage} eq 'done';

    $state->{buffer} .= $bytes;

    while (1) {
        if ($state->{stage} eq 'stream_type') {
            my ($value, $length) =
                _decode_http3_varint($state->{buffer}, 0);
            return unless defined $value;

            substr($state->{buffer}, 0, $length, '');

            if ($value ne '0') {
                $state->{stage} = 'ignore';
                $state->{buffer} = '';
                return;
            }

            $state->{stage} = 'frame_type';
            next;
        }

        if ($state->{stage} eq 'frame_type') {
            my ($value, $length) =
                _decode_http3_varint($state->{buffer}, 0);
            return unless defined $value;

            substr($state->{buffer}, 0, $length, '');

            if ($value ne '4') {
                $state->{stage} = 'ignore';
                $state->{buffer} = '';
                return;
            }

            $state->{stage} = 'frame_length';
            next;
        }

        if ($state->{stage} eq 'frame_length') {
            my ($value, $length) =
                _decode_http3_varint($state->{buffer}, 0);
            return unless defined $value;

            substr($state->{buffer}, 0, $length, '');
            $state->{remaining} = 0 + $value;
            $state->{stage} = 'setting_id';
            next;
        }

        if ($state->{stage} eq 'setting_id') {
            if ($state->{remaining} == 0) {
                my %extension = map {
                    $_ => $state->{settings}{$_}
                } grep {
                    _is_peer_extension_setting_id($_)
                } keys %{ $state->{settings} };

                $self->{pending_peer_settings} = {
                    %{ $state->{settings} },
                };
                $self->{pending_peer_extension_settings} = \%extension;
                $state->{stage} = 'done';
                $state->{buffer} = '';
                return;
            }

            my ($value, $length) =
                _decode_http3_varint($state->{buffer}, 0);
            return unless defined $value;

            if ($length > $state->{remaining}) {
                $state->{stage} = 'ignore';
                $state->{buffer} = '';
                return;
            }

            substr($state->{buffer}, 0, $length, '');
            $state->{remaining} -= $length;
            $state->{setting_id} = $value;
            $state->{stage} = 'setting_value';
            next;
        }

        if ($state->{stage} eq 'setting_value') {
            my ($value, $length) =
                _decode_http3_varint($state->{buffer}, 0);
            return unless defined $value;

            if ($length > $state->{remaining}) {
                $state->{stage} = 'ignore';
                $state->{buffer} = '';
                return;
            }

            substr($state->{buffer}, 0, $length, '');
            $state->{remaining} -= $length;

            my $setting_id = delete $state->{setting_id};

            if (exists $state->{settings}{$setting_id}) {
                $state->{stage} = 'ignore';
                $state->{buffer} = '';

                $self->_fail_connection(
                    $H3_SETTINGS_ERROR,
                    "peer sent duplicate HTTP/3 setting $setting_id",
                );
                return;
            }

            if (
                ($setting_id eq '8' || $setting_id eq '51')
                && $value ne '0'
                && $value ne '1'
            ) {
                $state->{stage} = 'ignore';
                $state->{buffer} = '';

                $self->_fail_connection(
                    $H3_SETTINGS_ERROR,
                    "peer HTTP/3 setting $setting_id must be 0 or 1",
                );
                return;
            }

            $state->{settings}{$setting_id} = $value;
            $state->{stage} = 'setting_id';
            next;
        }

        croak "unknown peer SETTINGS parser state '$state->{stage}'";
    }
}

sub _accept_peer_extension_settings {
    my ($self) = @_;

    my $all_settings = delete $self->{pending_peer_settings};
    $all_settings = {} unless defined $all_settings;

    if (
        defined($self->{remembered_peer_settings})
        && $self->{quic}->early_data_status eq 'accepted'
    ) {
        my ($compatibility_code, $compatibility_error) =
            _settings_compatibility_error(
                $self->{remembered_peer_settings},
                $all_settings,
            );

        if (defined $compatibility_error) {
            $self->_fail_connection(
                $compatibility_code,
                "peer SETTINGS are incompatible with accepted 0-RTT: "
                    . $compatibility_error,
            );
            return;
        }
    }

    my $settings = delete $self->{pending_peer_extension_settings};
    $settings = {} unless defined $settings;

    $self->{peer_settings_wire} = { %$all_settings };
    $self->{peer_extension_settings} = { %$settings };
    $self->{peer_settings_received} = 1;
    $self->{peer_settings_initialized} = 1;

    my $callback = $self->{on_extension_settings};
    return 1 unless defined $callback;

    my $ok = eval {
        $callback->($self, { %$settings });
        1;
    };

    return 1 if $ok;

    my $error = $@;
    $error = 'extension SETTINGS validation failed'
        unless defined($error) && length($error);
    $error =~ s/\s+\z//;

    $self->_fail_connection(
        $H3_SETTINGS_ERROR,
        "peer extension SETTINGS rejected: $error",
    );

    return;
}

sub _ascii_lc {
    my ($value) = @_;
    my $copy = "$value";
    $copy =~ tr/A-Z/a-z/;
    return $copy;
}

sub _authority_equal {
    my ($left, $right) = @_;
    return _ascii_lc($left) eq _ascii_lc($right) ? 1 : 0;
}

sub _connect_authority_error {
    my ($authority) = @_;

    return 'CONNECT authority must not contain userinfo'
        if $authority =~ /@/;

    my $port;

    if ($authority =~ /\A\[[^\]]+\]:([0-9]+)\z/) {
        $port = $1;
    } elsif ($authority =~ /\A[^:]+:([0-9]+)\z/) {
        $port = $1;
    } else {
        return 'CONNECT authority must contain a host and explicit port';
    }

    $port =~ s/\A0+(?=[0-9])//;

    return 'CONNECT authority port must be between 1 and 65535'
        if $port eq '0'
            || length($port) > 5
            || (length($port) == 5 && $port gt '65535');

    return;
}

sub _request_semantic_error {
    my (%args) = @_;

    my $method = $args{method};
    my $scheme = $args{scheme};
    my $authority = $args{authority};
    my $target = $args{target};
    my $protocol = $args{protocol};
    my $host_values = $args{host_values} || [];

    return 'multiple Host fields are not allowed'
        if @$host_values > 1;

    my $host = @$host_values ? $host_values->[0] : undef;

    if (defined($authority) && defined($host)) {
        return 'Host field must match :authority'
            unless _authority_equal($authority, $host);
    }

    if (defined($protocol) && $method ne 'CONNECT') {
        return ':protocol is only valid with CONNECT';
    }

    if ($method eq 'CONNECT') {
        if (defined $protocol) {
            return 'Extended CONNECT :protocol must be an HTTP token'
                unless $protocol =~ /\A[!\#\$%&'*+\-.\^_\x60|~0-9A-Za-z]+\z/;
            return 'Extended CONNECT requires :scheme'
                unless defined $scheme;
            return 'Extended CONNECT requires :path'
                unless defined $target && length $target;
        } else {
            return 'CONNECT requires :authority'
                unless defined $authority;

            my $error = _connect_authority_error($authority);
            return $error if defined $error;

            return 'CONNECT target must match :authority'
                if defined($target) && !_authority_equal($target, $authority);

            return;
        }
    }

    if (defined($scheme) && _ascii_lc($scheme) =~ /\Ahttps?\z/) {
        my $effective_authority = defined($authority)
            ? $authority
            : $host;

        return 'http and https requests require authority'
            unless defined $effective_authority && length $effective_authority;

        return 'http and https authority must not contain userinfo'
            if $effective_authority =~ /@/;

        return 'http and https :path must not contain a fragment'
            if $target =~ /#/;

        return
            if $target =~ m{\A/}
                || ($method eq 'OPTIONS' && $target eq '*');

        return 'http and https :path must start with /, except OPTIONS *';
    }

    return;
}

sub _request_host_values {
    my ($headers) = @_;

    return [
        map { $_->[1] }
        grep { _ascii_lc($_->[0]) eq 'host' }
        @$headers
    ];
}

sub _assert_request_semantics {
    my ($self, $request, $operation) = @_;

    my $error = _request_semantic_error(
        method      => $request->method,
        scheme      => $request->scheme,
        authority   => $request->authority,
        target      => $request->target,
        protocol    => $request->protocol,
        host_values => $request->header_values('host'),
    );

    croak "$operation: $error"
        if defined $error;

    return;
}

sub _valid_origin_serialization {
    my ($value) = @_;

    return 0 unless defined($value) && !ref($value);
    return 0 if $value =~ /[^\x00-\x7f]/;
    return 0 if $value =~ /[\x00-\x20\x7f]/;
    return 0 if length($value) > 65_535;
    return 1 if $value eq 'null';

    my $scheme = qr/[A-Za-z][A-Za-z0-9+.-]*/;
    my $reg_name =
        qr/(?:[A-Za-z0-9._~-]|%[0-9A-Fa-f]{2}|[!\$&'()*+,;=])+/;
    my $ip_literal =
        qr/\[(?:[0-9A-Fa-f:.]+|[vV][0-9A-Fa-f]+\.[A-Za-z0-9._~!\$&'()*+,;=:-]+)\]/;

    return $value =~ m{\A$scheme://(?:$ip_literal|$reg_name)(?::[0-9]+)?\z}
        ? 1
        : 0;
}

sub _normalize_origins {
    my ($origins) = @_;

    return undef unless defined $origins;

    croak 'origins must be an array reference'
        unless ref($origins) eq 'ARRAY';

    my @normalized;

    for my $origin (@$origins) {
        croak 'each origin must be a defined scalar'
            if !defined($origin) || ref($origin);

        my $value = "$origin";

        croak 'origin exceeds the RFC 9412 16-bit length limit'
            if length($value) > 65_535;
        croak 'origin must be an RFC 6454 ASCII serialization'
            unless _valid_origin_serialization($value);

        push @normalized, $value;
    }

    return \@normalized;
}

sub _serialize_origins {
    my ($origins) = @_;

    return undef unless defined $origins;

    my $payload = '';

    for my $origin (@$origins) {
        $payload .= pack('n', length($origin));
        $payload .= $origin;
    }

    return $payload;
}

sub client {
    my ($class, %args) = @_;
    return $class->_new('client', %args);
}

sub server {
    my ($class, %args) = @_;
    return $class->_new('server', %args);
}

sub _new {
    my ($class, $role, %args) = @_;

    my $quic = delete $args{quic};
    my $send_buffer_limit = exists $args{send_buffer_limit}
        ? delete $args{send_buffer_limit}
        : 4 * 1024 * 1024;
    my $max_field_section_size = exists $args{max_field_section_size}
        ? delete $args{max_field_section_size}
        : 65_536;
    my $max_buffered_body_bytes = exists $args{max_buffered_body_bytes}
        ? delete $args{max_buffered_body_bytes}
        : 64 * 1024 * 1024;
    my $max_streaming_body_bytes = exists $args{max_streaming_body_bytes}
        ? delete $args{max_streaming_body_bytes}
        : 4 * 1024 * 1024;
    my $qpack_max_table_capacity = exists $args{qpack_max_table_capacity}
        ? delete $args{qpack_max_table_capacity}
        : 4_096;
    my $qpack_blocked_streams = exists $args{qpack_blocked_streams}
        ? delete $args{qpack_blocked_streams}
        : 100;
    my $receive_body = exists $args{receive_body}
        ? delete $args{receive_body}
        : 'buffered';
    my $enable_extended_connect = exists $args{enable_extended_connect}
        ? delete $args{enable_extended_connect}
        : 0;
    my $enable_http_datagrams = exists $args{enable_http_datagrams}
        ? delete $args{enable_http_datagrams}
        : 0;
    my $origins = _normalize_origins(delete $args{origins});
    my $datagram_request = delete $args{datagram_request};
    my $max_buffered_datagram_bytes =
        exists $args{max_buffered_datagram_bytes}
            ? delete $args{max_buffered_datagram_bytes}
            : 1024 * 1024;
    my $max_buffered_datagrams =
        exists $args{max_buffered_datagrams}
            ? delete $args{max_buffered_datagrams}
            : 1024;
    my $has_quic_max_bidi_streams = exists $args{quic_max_bidi_streams};
    my $quic_max_bidi_streams = $has_quic_max_bidi_streams
        ? delete $args{quic_max_bidi_streams}
        : 100;
    my $extension_settings = _normalize_extension_settings(
        delete $args{extension_settings},
    );
    my $remembered_peer_settings_state =
        delete $args{remembered_peer_settings};
    my $remembered_local_settings_state =
        delete $args{remembered_local_settings};
    my $remembered_peer_settings = defined($remembered_peer_settings_state)
        ? _decode_settings_state(
            $remembered_peer_settings_state,
            'remembered_peer_settings',
        )
        : undef;
    my $remembered_local_settings = defined($remembered_local_settings_state)
        ? _decode_settings_state(
            $remembered_local_settings_state,
            'remembered_local_settings',
        )
        : undef;
    my $on_extension_settings = delete $args{on_extension_settings};
    my $extension_stream_handlers =
        _normalize_extension_stream_handlers(
            delete $args{extension_stream_handlers},
        );

    croak 'remembered_peer_settings is only valid for a client connection'
        if $role ne 'client' && defined $remembered_peer_settings;
    croak 'remembered_local_settings is only valid for a server connection'
        if $role ne 'server' && defined $remembered_local_settings;

    croak 'on_extension_settings must be a code reference'
        if defined($on_extension_settings)
            && ref($on_extension_settings) ne 'CODE';

    croak 'enable_extended_connect must be 0 or 1'
        if !defined($enable_extended_connect)
            || ref($enable_extended_connect)
            || "$enable_extended_connect" !~ /\A[01]\z/;
    croak 'enable_extended_connect is only valid for a server connection'
        if $role ne 'server' && $enable_extended_connect;

    croak 'enable_http_datagrams must be 0 or 1'
        if !defined($enable_http_datagrams)
            || ref($enable_http_datagrams)
            || "$enable_http_datagrams" !~ /\A[01]\z/;
    croak 'datagram_request must be a code reference'
        if defined($datagram_request) && ref($datagram_request) ne 'CODE';
    croak 'datagram_request is only valid for a server connection'
        if $role ne 'server' && defined($datagram_request);
    croak 'origins is only valid for a server connection'
        if $role ne 'server' && defined($origins);

    croak 'quic_max_bidi_streams must be a non-negative integer'
        if !defined($quic_max_bidi_streams)
            || ref($quic_max_bidi_streams)
            || "$quic_max_bidi_streams" !~ /\A[0-9]+\z/;
    croak 'quic_max_bidi_streams is only valid for server connections'
        if $role ne 'server' && $has_quic_max_bidi_streams;

    croak 'quic is required'
        unless defined $quic;
    croak 'quic must be a Net::QUIC::Connection object'
        unless blessed($quic) && $quic->isa('Net::QUIC::Connection');
    croak 'enable_http_datagrams requires QUIC DATAGRAM receive support'
        if $enable_http_datagrams && !$quic->can_receive_datagram;

    croak 'send_buffer_limit must be a positive integer'
        unless defined($send_buffer_limit)
            && !ref($send_buffer_limit)
            && $send_buffer_limit =~ /\A[0-9]+\z/
            && $send_buffer_limit > 0;
    croak 'max_buffered_datagram_bytes must be a positive integer'
        unless defined($max_buffered_datagram_bytes)
            && !ref($max_buffered_datagram_bytes)
            && $max_buffered_datagram_bytes =~ /\A[0-9]+\z/
            && $max_buffered_datagram_bytes > 0;
    croak 'max_buffered_datagrams must be a positive integer'
        unless defined($max_buffered_datagrams)
            && !ref($max_buffered_datagrams)
            && $max_buffered_datagrams =~ /\A[0-9]+\z/
            && $max_buffered_datagrams > 0;

    for my $limit (
        [ max_field_section_size   => $max_field_section_size ],
        [ max_buffered_body_bytes  => $max_buffered_body_bytes ],
        [ max_streaming_body_bytes => $max_streaming_body_bytes ],
    ) {
        croak "$limit->[0] must be a positive integer"
            unless defined($limit->[1])
                && !ref($limit->[1])
                && $limit->[1] =~ /\A[0-9]+\z/
                && $limit->[1] > 0;
    }

    for my $setting (
        [ qpack_max_table_capacity => $qpack_max_table_capacity ],
        [ qpack_blocked_streams    => $qpack_blocked_streams ],
    ) {
        croak "$setting->[0] must be a non-negative integer"
            unless defined($setting->[1])
                && !ref($setting->[1])
                && $setting->[1] =~ /\A[0-9]+\z/;
    }

    croak 'max_field_section_size exceeds the HTTP/3 varint maximum'
        if _exceeds_http3_varint($max_field_section_size);
    croak 'qpack_max_table_capacity exceeds the HTTP/3 varint maximum'
        if _exceeds_http3_varint($qpack_max_table_capacity);
    croak 'qpack_blocked_streams exceeds the HTTP/3 varint maximum'
        if _exceeds_http3_varint($qpack_blocked_streams);

    croak 'receive_body must be buffered or stream'
        if !defined($receive_body)
            || ref($receive_body)
            || ($receive_body ne 'buffered' && $receive_body ne 'stream');

    croak 'unknown connection option: ' . join(', ', sort keys %args)
        if %args;

    my %local_settings = (
        1 => "$qpack_max_table_capacity",
        6 => "$max_field_section_size",
        7 => "$qpack_blocked_streams",
    );
    $local_settings{8} = '1' if $enable_extended_connect;
    $local_settings{51} = '1' if $enable_http_datagrams;
    @local_settings{keys %$extension_settings}
        = values %$extension_settings;

    my $origin_list = _serialize_origins($origins);

    if (defined $remembered_local_settings) {
        my $compatibility_error = _settings_compatibility_error(
            $remembered_local_settings,
            \%local_settings,
        );

        croak "remembered_local_settings is incompatible with current HTTP/3 settings: "
            . $compatibility_error
            if defined $compatibility_error;
    }

    my $native = $role eq 'server'
        ? Unblock::HTTP3::_Native->server(
            $max_field_section_size,
            $qpack_max_table_capacity,
            $qpack_blocked_streams,
            $enable_extended_connect,
            $enable_http_datagrams,
            $origin_list,
        )
        : Unblock::HTTP3::_Native->client(
            $max_field_section_size,
            $qpack_max_table_capacity,
            $qpack_blocked_streams,
            0,
            $enable_http_datagrams,
        );

    $native->set_max_client_streams_bidi($quic_max_bidi_streams)
        if $role eq 'server';

    return bless {
        role              => $role,
        quic              => $quic,
        native            => $native,
        send_buffer_limit       => 0 + $send_buffer_limit,
        max_field_section_size   => 0 + $max_field_section_size,
        max_buffered_body_bytes  => 0 + $max_buffered_body_bytes,
        max_streaming_body_bytes => 0 + $max_streaming_body_bytes,
        qpack_max_table_capacity  => 0 + $qpack_max_table_capacity,
        qpack_blocked_streams     => 0 + $qpack_blocked_streams,
        quic_max_bidi_streams       => 0 + $quic_max_bidi_streams,
        native_max_client_streams_bidi => 0 + $quic_max_bidi_streams,
        local_settings               => \%local_settings,
        remembered_peer_settings      => $remembered_peer_settings,
        remembered_local_settings     => $remembered_local_settings,
        peer_settings_wire            => {},
        peer_max_field_section_size => defined($remembered_peer_settings)
            ? _effective_setting($remembered_peer_settings, 6)
            : $HTTP3_MAX_VARINT,
        receive_body_mode         => $receive_body,
        enable_extended_connect    => $enable_extended_connect ? 1 : 0,
        peer_enable_connect_protocol => defined($remembered_peer_settings)
            && _effective_setting($remembered_peer_settings, 8) eq '1'
            ? 1 : 0,
        enable_http_datagrams       => $enable_http_datagrams ? 1 : 0,
        origins                     => $origins,
        peer_origins                => undef,
        peer_origin_pending         => [],
        peer_h3_datagram            => defined($remembered_peer_settings)
            && _effective_setting($remembered_peer_settings, 51) eq '1'
            ? 1 : 0,
        datagram_request            => $datagram_request,
        max_buffered_datagram_bytes => 0 + $max_buffered_datagram_bytes,
        max_buffered_datagrams      => 0 + $max_buffered_datagrams,
        datagram_buffered_bytes     => 0,
        datagram_buffered_count     => 0,
        datagram_receive_drops      => 0,
        extension_settings        => $extension_settings,
        peer_extension_settings   => defined($remembered_peer_settings)
            ? {
                map {
                    $_ => $remembered_peer_settings->{$_}
                } grep {
                    _is_peer_extension_setting_id($_)
                } keys %$remembered_peer_settings
            }
            : {},
        peer_settings_received     => 0,
        peer_settings_initialized  => defined($remembered_peer_settings) ? 1 : 0,
        peer_settings_parser       => {},
        on_extension_settings      => $on_extension_settings,
        control_settings_rewritten => 0,
        control_settings_delta     => 0,
        control_settings_pending   => undef,
        extension_stream_handlers  => $extension_stream_handlers,
        extension_stream_objects   => {},
        peer_uni_probe             => {},
        core_uni_streams           => {},
        ignored_uni_streams        => {},
        started                  => 0,
        early_data_started       => 0,
        early_data_status        => $quic->early_data_status,
        early_data_rollback_done => 0,
        failed                  => 0,
        error                   => undef,
        error_code              => undef,
        shutdown_notice_sent     => 0,
        shutdown_started         => 0,
        remote_shutdown_id       => undef,
        servicing         => 0,
        service_again     => 0,
        streams           => {},
        messages          => {},
        outgoing          => {},
        stream_lifecycle  => {},
        building          => {},
        transactions      => {},
        ready_transactions => [],
        pending_early_transactions => [],
        pending_early_datagrams    => {},
        ready_informational => [],
        output_finished   => {},
        response_sent     => {},
    }, $class;
}

sub role {
    my ($self, @args) = @_;
    croak 'role() does not accept arguments' if @args;
    return $self->{role};
}

sub quic {
    my ($self, @args) = @_;
    croak 'quic() does not accept arguments' if @args;
    return $self->{quic};
}

sub nghttp3_version {
    my ($self, @args) = @_;
    croak 'nghttp3_version() does not accept arguments' if @args;
    return Unblock::HTTP3::_Native::nghttp3_version();
}

sub early_data_status {
    my ($self, @args) = @_;
    croak 'early_data_status() does not accept arguments' if @args;
    $self->_sync_early_data_status if $self->{started};
    return $self->{quic}->early_data_status;
}

sub started {
    my ($self, @args) = @_;
    croak 'started() does not accept arguments' if @args;
    return $self->{started} ? 1 : 0;
}

sub failed {
    my ($self, @args) = @_;
    croak 'failed() does not accept arguments' if @args;
    return $self->{failed} ? 1 : 0;
}

sub error {
    my ($self, @args) = @_;
    croak 'error() does not accept arguments' if @args;
    return $self->{error};
}

sub error_code {
    my ($self, @args) = @_;
    croak 'error_code() does not accept arguments' if @args;
    return $self->{error_code};
}

sub max_field_section_size {
    my ($self, @args) = @_;
    croak 'max_field_section_size() does not accept arguments' if @args;
    return $self->{max_field_section_size};
}

sub max_buffered_body_bytes {
    my ($self, @args) = @_;
    croak 'max_buffered_body_bytes() does not accept arguments' if @args;
    return $self->{max_buffered_body_bytes};
}

sub max_streaming_body_bytes {
    my ($self, @args) = @_;
    croak 'max_streaming_body_bytes() does not accept arguments' if @args;
    return $self->{max_streaming_body_bytes};
}

sub qpack_max_table_capacity {
    my ($self, @args) = @_;
    croak 'qpack_max_table_capacity() does not accept arguments' if @args;
    return $self->{qpack_max_table_capacity};
}

sub qpack_blocked_streams {
    my ($self, @args) = @_;
    croak 'qpack_blocked_streams() does not accept arguments' if @args;
    return $self->{qpack_blocked_streams};
}

sub local_settings_state {
    my ($self, @args) = @_;
    croak 'local_settings_state() does not accept arguments' if @args;
    return _encode_settings_state($self->{local_settings});
}

sub peer_settings_state {
    my ($self, @args) = @_;
    croak 'peer_settings_state() does not accept arguments' if @args;
    return unless $self->{peer_settings_received};
    return _encode_settings_state($self->{peer_settings_wire});
}

sub using_remembered_peer_settings {
    my ($self, @args) = @_;
    croak 'using_remembered_peer_settings() does not accept arguments'
        if @args;

    return defined($self->{remembered_peer_settings})
        && !$self->{peer_settings_received}
        ? 1
        : 0;
}

sub extension_settings {
    my ($self, @args) = @_;
    croak 'extension_settings() does not accept arguments' if @args;
    return { %{ $self->{extension_settings} } };
}

sub extension_setting {
    my ($self, $id, @args) = @_;

    $id = _normalize_http3_varint(
        $id,
        'extension setting identifier',
    );

    _assert_extension_setting_id($id);

    return $self->{extension_settings}{$id}
        unless @args;

    croak 'extension_setting() accepts at most one value'
        unless @args == 1;
    croak 'extension SETTINGS cannot change after start()'
        if $self->{started};

    my $value = _normalize_http3_varint(
        $args[0],
        "extension setting $id value",
    );

    $self->{extension_settings}{$id} = $value;
    return $self;
}

sub peer_extension_settings {
    my ($self, @args) = @_;
    croak 'peer_extension_settings() does not accept arguments' if @args;
    return { %{ $self->{peer_extension_settings} } };
}

sub peer_extension_setting {
    my ($self, $id, @args) = @_;
    croak 'peer_extension_setting() accepts one setting identifier'
        if @args;

    $id = _normalize_http3_varint(
        $id,
        'peer extension setting identifier',
    );

    return $self->{peer_extension_settings}{$id};
}

sub peer_settings_received {
    my ($self, @args) = @_;
    croak 'peer_settings_received() does not accept arguments' if @args;
    return $self->{peer_settings_received} ? 1 : 0;
}

sub peer_origins {
    my ($self, @args) = @_;
    croak 'peer_origins() does not accept arguments' if @args;

    return undef unless defined $self->{peer_origins};
    return [ @{ $self->{peer_origins} } ];
}

sub extended_connect_enabled {
    my ($self, @args) = @_;
    croak 'extended_connect_enabled() does not accept arguments' if @args;
    return $self->{enable_extended_connect} ? 1 : 0;
}

sub peer_extended_connect_enabled {
    my ($self, @args) = @_;
    croak 'peer_extended_connect_enabled() does not accept arguments'
        if @args;
    return $self->{peer_enable_connect_protocol} ? 1 : 0;
}

sub http_datagrams_enabled {
    my ($self, @args) = @_;
    croak 'http_datagrams_enabled() does not accept arguments' if @args;
    return $self->{enable_http_datagrams} ? 1 : 0;
}

sub peer_http_datagrams_enabled {
    my ($self, @args) = @_;
    croak 'peer_http_datagrams_enabled() does not accept arguments' if @args;
    return $self->{peer_h3_datagram} ? 1 : 0;
}

sub can_send_http_datagrams {
    my ($self, @args) = @_;
    croak 'can_send_http_datagrams() does not accept arguments' if @args;

    return 0 unless $self->{enable_http_datagrams};
    return 0 unless $self->{peer_settings_initialized};
    return 0 unless $self->{peer_h3_datagram};

    return $self->{quic}->can_send_datagram ? 1 : 0;
}

sub can_receive_http_datagrams {
    my ($self, @args) = @_;
    croak 'can_receive_http_datagrams() does not accept arguments' if @args;

    return 0 unless $self->{enable_http_datagrams};
    return 0 unless $self->{peer_settings_initialized};
    return 0 unless $self->{peer_h3_datagram};

    return $self->{quic}->can_receive_datagram ? 1 : 0;
}

sub datagram_receive_drops {
    my ($self, @args) = @_;
    croak 'datagram_receive_drops() does not accept arguments' if @args;
    return 0 + $self->{datagram_receive_drops};
}

sub extension_stream_handler {
    my ($self, $type, @args) = @_;

    $type = _normalize_http3_varint(
        $type,
        'extension stream type',
    );

    _assert_extension_stream_type($type);

    return $self->{extension_stream_handlers}{$type}
        unless @args;

    croak 'extension_stream_handler() accepts at most one callback'
        unless @args == 1;
    croak 'extension stream handlers cannot change after start()'
        if $self->{started};
    croak 'extension stream handler must be a code reference'
        unless ref($args[0]) eq 'CODE';

    $self->{extension_stream_handlers}{$type} = $args[0];
    return $self;
}

sub open_extension_stream {
    my ($self, $type) = @_;

    croak 'HTTP/3 connection has not been started'
        unless $self->{started};
    croak 'HTTP/3 connection has failed'
        if $self->{failed};

    $type = _normalize_http3_varint(
        $type,
        'extension stream type',
    );

    _assert_extension_stream_type($type);

    my $stream = $self->{quic}->open_uni_stream;
    return unless defined $stream;

    my $header = _encode_http3_varint($type);
    $stream->send($header);

    require Unblock::HTTP3::Extension::Stream;

    my $extension = Unblock::HTTP3::Extension::Stream->_new(
        connection    => $self,
        stream        => $stream,
        type          => $type,
        header_length => length($header),
        incoming      => 0,
    );

    my $id = $stream->id;
    $self->{streams}{$id} = $stream;
    $self->{extension_stream_objects}{$id} = $extension;

    return $extension;
}

sub receive_body_mode {
    my ($self, @args) = @_;
    return $self->{receive_body_mode} unless @args;

    croak 'receive_body_mode() accepts at most one value'
        unless @args == 1;
    croak 'receive_body_mode must be buffered or stream'
        if !defined($args[0])
            || ref($args[0])
            || ($args[0] ne 'buffered' && $args[0] ne 'stream');

    $self->{receive_body_mode} = $args[0];
    return $self;
}

sub _fail_connection {
    my ($self, $code, $message) = @_;

    return if $self->{failed};

    $self->{failed} = 1;
    $self->{error_code} = 0 + $code;
    $self->{error} = "$message";

    for my $transaction (values %{ $self->{transactions} }) {
        next if $transaction->is_terminal;
        $transaction->_mark_error($message);
    }

    $self->{quic}->close($code);
    return;
}

sub request {
    my ($self, $request, %option) = @_;

    $self->_sync_early_data_status if $self->{started};

    croak 'request() is only available on a client HTTP/3 connection'
        unless $self->{role} eq 'client';
    croak 'request() requires a canonical Uniform::HTTP::Request'
        unless ref($request) eq 'Uniform::HTTP::Request';

    _assert_http3_version($request, 'request()');

    my $is_connect = $request->method eq 'CONNECT' ? 1 : 0;
    my $is_extended_connect =
        $is_connect && defined($request->protocol) ? 1 : 0;
    my $stream_body;
    my $receive_body = $self->{receive_body_mode};
    my $receive_options = {};
    my $datagrams = exists $option{datagrams}
        ? delete $option{datagrams}
        : 0;
    my $early_data = exists $option{early_data}
        ? delete $option{early_data}
        : 0;

    croak 'request(): early_data must be 0 or 1'
        if !defined($early_data)
            || ref($early_data)
            || "$early_data" !~ /\A[01]\z/;
    croak 'request(): datagrams must be 0 or 1'
        if !defined($datagrams)
            || ref($datagrams)
            || "$datagrams" !~ /\A[01]\z/;

    if ($is_connect) {
        if ($is_extended_connect) {
            croak 'request(): peer did not enable Extended CONNECT'
                unless $self->{peer_enable_connect_protocol};
            croak 'request(): Extended CONNECT requires scheme'
                unless defined $request->scheme;
            croak 'request(): Extended CONNECT requires authority'
                unless defined $request->authority;
        } else {
            croak 'request(): CONNECT requires authority'
                unless defined $request->authority;
            croak 'request(): CONNECT target must match authority'
                unless _authority_equal(
                    $request->target,
                    $request->authority,
                );
            croak 'request(): CONNECT must not have scheme'
                if defined $request->scheme;
        }

        croak 'request(): CONNECT cannot use a buffered request body'
            if $request->has_buffered_body;
        croak 'request(): CONNECT cannot use request trailers'
            if $request->has_trailers;

        $receive_body = 'stream';
        $stream_body = {};
    }

    if (exists $option{stream_body}) {
        my $configured = delete $option{stream_body};

        croak 'request(): stream_body must be a hash reference'
            unless ref($configured) eq 'HASH';

        $stream_body = { %$configured };

        croak 'request(): stream_body cannot be combined with a scalar Request body'
            if $request->has_buffered_body;

    }

    if (exists $option{receive_body}) {
        my $value = delete $option{receive_body};

        if (ref($value) eq 'HASH') {
            $receive_body = 'stream';
            $receive_options = { %$value };
        } else {
            croak 'request(): receive_body must be buffered, stream, or a hash reference'
                if !defined($value)
                    || ref($value)
                    || ($value ne 'buffered' && $value ne 'stream');
            $receive_body = $value;
        }
    }

    croak 'request(): CONNECT response body must use streaming receive mode'
        if $is_connect && $receive_body ne 'stream';

    croak 'request(): unknown options: ' . join(', ', sort keys %option)
        if %option;

    $self->_assert_request_semantics(
        $request,
        'request()',
    );
    my $request_streaming = defined($stream_body) ? 1 : 0;

    $self->_assert_request_content_length(
        $request,
        'request()',
        $request_streaming,
    );

    my $sending_early = !$self->{quic}->ready ? 1 : 0;

    if ($sending_early) {
        croak 'request(): early_data => 1 is required before QUIC handshake completion'
            unless $early_data;
        croak 'request(): HTTP/3 was not started for 0-RTT'
            unless $self->{early_data_started};
        croak 'request(): QUIC 0-RTT is not pending'
            unless $self->{quic}->early_data_status eq 'pending';
        croak 'request(): remembered peer HTTP/3 settings are required for 0-RTT'
            unless $self->{peer_settings_initialized};
    }

    my $stream_id = $self->_submit_request(
        $request,
        $request_streaming,
    );
    return unless defined $stream_id;

    $request->mark_incomplete if $request_streaming;

    my $transaction = Unblock::HTTP3::Transaction->_new(
        connection        => $self,
        stream_id         => $stream_id,
        request           => $request,
        request_streaming => $request_streaming,
        early_data        => $sending_early,
    );

    $transaction->_enable_datagrams if $datagrams;

    $transaction->_configure_receive_body(
        'response',
        $receive_body,
        $receive_options,
    );

    $self->{transactions}{$stream_id} = $transaction;

    if (defined $stream_body) {
        $transaction->request_body(%$stream_body);
    }

    $self->_maybe_complete_transaction($stream_id);

    return $transaction;
}

sub next_transaction {
    my ($self, @args) = @_;

    croak 'next_transaction() does not accept arguments' if @args;
    $self->_service if $self->{started} && !$self->{failed};
    return shift @{ $self->{ready_transactions} };
}

sub next_informational {
    my ($self, @args) = @_;

    croak 'next_informational() does not accept arguments' if @args;
    $self->_service if $self->{started} && !$self->{failed};
    return shift @{ $self->{ready_informational} };
}

sub _assert_http3_version {
    my ($message, $operation) = @_;

    my $version = $message->version;
    return unless defined $version;

    croak "$operation: explicit message version must be 3 for HTTP/3"
        unless "$version" eq '3';

    return;
}

sub _declared_content_length {
    my ($message, $operation) = @_;

    my $values = $message->header_values('content-length');
    return unless @$values;

    croak "$operation: multiple Content-Length fields are not allowed"
        unless @$values == 1;

    my $value = $values->[0];

    croak "$operation: Content-Length must be a decimal non-negative integer"
        unless $value =~ /\A[0-9]+\z/;

    $value =~ s/\A0+(?=[0-9])//;

    return $value;
}

sub _content_length_matches {
    my ($declared, $actual) = @_;
    return $declared eq "$actual" ? 1 : 0;
}

sub _content_length_is_less_than {
    my ($declared, $actual) = @_;

    my $actual_text = "$actual";

    return 1 if length($declared) < length($actual_text);
    return 0 if length($declared) > length($actual_text);

    return $declared lt $actual_text ? 1 : 0;
}

sub _assert_request_content_length {
    my ($self, $request, $operation, $streaming) = @_;

    my $declared = _declared_content_length($request, $operation);
    return unless defined $declared;

    if ($request->method eq 'CONNECT') {
        croak "$operation: CONNECT request Content-Length must be 0"
            unless $declared eq '0';
        return $declared;
    }

    return $declared if $streaming;

    my $actual = $request->has_buffered_body
        ? length($request->body)
        : 0;

    croak "$operation: Content-Length $declared does not match $actual body bytes"
        unless _content_length_matches($declared, $actual);

    return $declared;
}

sub _assert_response_content_length {
    my ($self, $transaction, $response, $operation) = @_;

    my $declared = _declared_content_length($response, $operation);
    return unless defined $declared;

    my $method = $transaction->request->method;
    my $status = $response->status;

    croak "$operation: Content-Length is not allowed on informational responses"
        if $status >= 100 && $status < 200;
    croak "$operation: Content-Length is not allowed on a 204 response"
        if $status == 204;
    croak "$operation: Content-Length is not allowed on a successful CONNECT response"
        if $method eq 'CONNECT' && $status >= 200 && $status < 300;

    return $declared
        if $method eq 'HEAD' || $status == 304;

    if ($status == 205) {
        croak "$operation: Content-Length on a 205 response must be 0"
            unless $declared eq '0';
        return $declared;
    }

    return $declared if $transaction->_response_is_streaming;

    my $actual = $response->has_buffered_body
        ? length($response->body)
        : 0;

    croak "$operation: Content-Length $declared does not match $actual body bytes"
        unless _content_length_matches($declared, $actual);

    return $declared;
}

sub _assert_incremental_content_length {
    my ($self, $transaction, $kind, $message, $bytes, $final, $operation) = @_;

    my $declared;

    if ($kind eq 'request') {
        $declared = $self->_assert_request_content_length(
            $message,
            $operation,
        );

        return if $message->method eq 'CONNECT';
    } else {
        $declared = $self->_assert_response_content_length(
            $transaction,
            $message,
            $operation,
        );

        my $status = $message->status;
        return
            if $transaction->request->method eq 'HEAD'
                || $status == 304
                || ($transaction->request->method eq 'CONNECT'
                    && $status >= 200 && $status < 300);
    }

    return unless defined $declared;

    my $id = $transaction->stream_id;
    my $sent = $self->{body_bytes_sent}{$id}{$kind} // 0;
    my $next = $sent + length($bytes);

    croak "$operation: body exceeds Content-Length $declared"
        if _content_length_is_less_than($declared, $next);

    if ($final) {
        croak "$operation: Content-Length $declared does not match $next body bytes"
            unless _content_length_matches($declared, $next);
    }

    $self->{body_bytes_sent}{$id}{$kind} = $next;
    return;
}

sub _send_informational_response {
    my ($self, $transaction, $response) = @_;

    croak 'informational responses require a server HTTP/3 connection'
        unless $self->{role} eq 'server';
    croak 'Transaction does not belong to this HTTP/3 connection'
        unless blessed($transaction)
            && $transaction->isa('Unblock::HTTP3::Transaction')
            && defined($self->{transactions}{ $transaction->stream_id })
            && $self->{transactions}{ $transaction->stream_id } == $transaction;
    croak 'final response has already started'
        if $self->{response_sent}{ $transaction->stream_id };
    _assert_http3_version($response, 'send_informational()');

    croak 'informational response status must be 100 through 199, excluding 101'
        unless $response->status >= 100
            && $response->status <= 199
            && $response->status != 101;

    $self->_assert_response_content_length(
        $transaction,
        $response,
        'send_informational()',
    );
    _assert_capsule_protocol_response(
        $response,
        'send_informational()',
    );

    $self->_assert_peer_field_section_size_value(
        $self->{native}->uniform_response_field_section_size($response),
        'send_informational()',
    );

    $self->{native}->submit_uniform_info(
        $transaction->stream_id,
        $response,
    );

    $response->freeze;

    $self->_drain_output;
    return $response;
}

sub _capsule_protocol_response_error {
    my ($status, $headers) = @_;

    my $present = 0;

    for my $field (@$headers) {
        my $name = lc($field->[0]);
        if ($name eq 'capsule-protocol') {
            $present = 1;
            last;
        }
    }

    return unless $present;
    return if $status >= 200 && $status < 300;

    return 'Capsule-Protocol is only valid on a successful HTTP/3 response';
}

sub _assert_capsule_protocol_response {
    my ($response, $operation) = @_;

    my $values = $response->header_values('capsule-protocol');
    return unless @$values;
    return if $response->status >= 200 && $response->status < 300;

    croak "$operation: Capsule-Protocol is only valid on a successful HTTP/3 response";
}

sub _response_content_forbidden_reason {
    my ($self, $transaction, $response) = @_;

    my $method = $transaction->request->method;
    my $status = $response->status;

    return 'response to HEAD must not contain content'
        if $method eq 'HEAD';
    return '204 response must not contain content'
        if $status == 204;
    return '205 response must not contain content'
        if $status == 205;
    return '304 response must not contain content'
        if $status == 304;

    return;
}

sub _assert_response_body_allowed {
    my ($self, $transaction, $response, $operation) = @_;

    my $reason = $self->_response_content_forbidden_reason(
        $transaction,
        $response,
    );

    croak "$operation: $reason"
        if defined $reason;

    return;
}

sub _assert_response_message_allowed {
    my ($self, $transaction, $response, $operation) = @_;

    my $reason = $self->_response_content_forbidden_reason(
        $transaction,
        $response,
    );

    return unless defined $reason;

    croak "$operation: $reason"
        if $response->has_buffered_body
            || $transaction->_response_is_streaming
            || $response->has_trailers;

    return;
}

sub _send_transaction_response {
    my ($self, $transaction) = @_;

    croak 'send_response() requires a server HTTP/3 connection'
        unless $self->{role} eq 'server';
    croak 'Transaction does not belong to this HTTP/3 connection'
        unless blessed($transaction)
            && $transaction->isa('Unblock::HTTP3::Transaction')
            && defined($self->{transactions}{ $transaction->stream_id })
            && $self->{transactions}{ $transaction->stream_id } == $transaction;
    croak 'response has already been sent for this Transaction'
        if $self->{response_sent}{ $transaction->stream_id };

    my $response = $transaction->response
        or croak 'Transaction has no response';

    _assert_http3_version($response, 'send_response()');

    $self->_assert_response_message_allowed(
        $transaction,
        $response,
        'send_response()',
    );
    $self->_assert_response_content_length(
        $transaction,
        $response,
        'send_response()',
    );
    _assert_capsule_protocol_response(
        $response,
        'send_response()',
    );

    croak 'final response status must be 200 through 599'
        if $response->status < 200;

    $self->{response_sent}{ $transaction->stream_id } = 1;

    my $ok = eval {
        $self->_submit_response(
            $transaction->stream_id,
            $response,
        );
        1;
    };

    if (!$ok) {
        delete $self->{response_sent}{ $transaction->stream_id };
        die $@;
    }

    $transaction->_mark_response_started;
    $self->_maybe_complete_transaction($transaction->stream_id);
    return $response;
}

sub _write_transaction_body {
    my ($self, $transaction, $kind, $bytes, $final, $operation) = @_;

    croak "$operation(): Transaction does not belong to this HTTP/3 connection"
        unless blessed($transaction)
            && $transaction->isa('Unblock::HTTP3::Transaction')
            && defined($self->{transactions}{ $transaction->stream_id })
            && $self->{transactions}{ $transaction->stream_id } == $transaction;

    my $id = $transaction->stream_id;
    my $message;

    if ($kind eq 'request') {
        croak "$operation(): request body production requires a client connection"
            unless $self->{role} eq 'client';

        $message = $transaction->request;

        croak "$operation(): Request is not configured for incremental body production"
            unless $transaction->_request_is_streaming;
    } elsif ($kind eq 'response') {
        croak "$operation(): response body production requires a server connection"
            unless $self->{role} eq 'server';

        $message = $transaction->response
            or croak "$operation(): Transaction has no Response";

        $self->_assert_response_body_allowed(
            $transaction,
            $message,
            $operation,
        );

        croak "$operation(): Response is not configured for incremental body production"
            unless $transaction->_response_is_streaming;

        if (!$self->{response_sent}{$id}) {
            $self->{response_sent}{$id} = 1;

            my $ok = eval {
                $self->_submit_response($id, $message);
                1;
            };

            if (!$ok) {
                delete $self->{response_sent}{$id};
                delete $self->{body_bytes_sent}{$id};
                die $@;
            }

            $transaction->_mark_response_started;
        }
    } else {
        croak "$operation(): unsupported HTTP body producer '$kind'";
    }

    $self->_assert_incremental_content_length(
        $transaction,
        $kind,
        $message,
        $bytes,
        $final ? 1 : 0,
        $operation,
    );

    $self->{native}->append_body(
        $id,
        $bytes,
        $final ? 1 : 0,
    );

    $self->_drain_output;
    $self->_maybe_complete_transaction($id);

    return $self->{native}->streaming_retained_bytes
        < $self->{send_buffer_limit}
        ? 1
        : 0;
}

sub _drain_body_producers {
    my ($self) = @_;

    return
        if $self->{native}->streaming_retained_bytes
            >= $self->{send_buffer_limit};

    for my $transaction (values %{ $self->{transactions} }) {
        next if $transaction->is_terminal;

        if (my $body = $transaction->_request_body_object) {
            $body->_drain;
        }

        if (my $body = $transaction->_response_body_object) {
            $body->_drain;
        }
    }

    return;
}

sub _consume_received_body {
    my ($self, $transaction, $kind, $amount) = @_;

    croak 'received body Transaction does not belong to this HTTP/3 connection'
        unless blessed($transaction)
            && $transaction->isa('Unblock::HTTP3::Transaction')
            && defined($self->{transactions}{ $transaction->stream_id })
            && $self->{transactions}{ $transaction->stream_id } == $transaction;

    croak 'received body consume amount must be a non-negative integer'
        unless defined($amount)
            && !ref($amount)
            && $amount =~ /\A[0-9]+\z/;

    return if $amount == 0;

    croak 'request receive bodies exist only on server connections'
        if $kind eq 'request' && $self->{role} ne 'server';
    croak 'response receive bodies exist only on client connections'
        if $kind eq 'response' && $self->{role} ne 'client';
    croak "unsupported received body kind '$kind'"
        if $kind ne 'request' && $kind ne 'response';

    my $stream = $self->{streams}{ $transaction->stream_id }
        or croak 'received body stream is no longer available';

    $stream->consume(0 + $amount);
    return;
}

sub _cancel_transaction {
    my ($self, $transaction) = @_;

    croak 'Transaction does not belong to this HTTP/3 connection'
        unless blessed($transaction)
            && $transaction->isa('Unblock::HTTP3::Transaction')
            && defined($self->{transactions}{ $transaction->stream_id })
            && $self->{transactions}{ $transaction->stream_id } == $transaction;

    return $transaction if $transaction->is_terminal;

    my $id = $transaction->stream_id;
    my $stream = $self->{streams}{$id};

    if (defined $stream) {
        if ($stream->can_receive && !$stream->remote_finished) {
            $self->{native}->shutdown_stream_read($id);
            $stream->stop_sending($H3_REQUEST_CANCELLED);
            $transaction->_mark_local_stop_sending($H3_REQUEST_CANCELLED);
        }

        if ($stream->can_send && !defined($stream->local_reset_code)) {
            $self->{native}->shutdown_stream_write($id);
            $stream->reset($H3_REQUEST_CANCELLED);
            $transaction->_mark_local_reset($H3_REQUEST_CANCELLED);
        }
    }

    $self->{native}->discard_body($id);

    $transaction->_mark_cancelled;
    return $transaction;
}

sub _transaction_priority {
    my ($self, $transaction) = @_;

    croak 'priority Transaction does not belong to this connection'
        unless blessed($transaction)
            && $transaction->isa('Unblock::HTTP3::Transaction')
            && defined($self->{transactions}{ $transaction->stream_id })
            && $self->{transactions}{ $transaction->stream_id } == $transaction;

    if (
        $self->{role} eq 'server'
        && !$transaction->is_terminal
    ) {
        my $priority = $self->{native}->get_server_stream_priority(
            $transaction->stream_id,
        );

        return {
            urgency     => 0 + $priority->[0],
            incremental => $priority->[1] ? 1 : 0,
        };
    }

    return { %{ $transaction->{priority} } };
}

sub _set_transaction_priority {
    my ($self, $transaction, $priority) = @_;

    croak 'priority Transaction does not belong to this connection'
        unless blessed($transaction)
            && $transaction->isa('Unblock::HTTP3::Transaction')
            && defined($self->{transactions}{ $transaction->stream_id })
            && $self->{transactions}{ $transaction->stream_id } == $transaction;
    croak 'priority must be a hash reference'
        unless ref($priority) eq 'HASH';

    my $stream_id = $transaction->stream_id;

    if ($self->{role} eq 'client') {
        my $field = Unblock::HTTP3::Transaction::_priority_field(
            $priority,
        );

        $self->{native}->set_client_stream_priority(
            $stream_id,
            $field,
        );
    } else {
        $self->{native}->set_server_stream_priority(
            $stream_id,
            $priority->{urgency},
            $priority->{incremental} ? 1 : 0,
        );
    }

    $transaction->{priority} = { %$priority };
    $self->_service;

    return;
}

sub _send_transaction_datagram {
    my ($self, $transaction, $bytes) = @_;

    croak 'HTTP Datagram Transaction does not belong to this connection'
        unless blessed($transaction)
            && $transaction->isa('Unblock::HTTP3::Transaction')
            && defined($self->{transactions}{ $transaction->stream_id })
            && $self->{transactions}{ $transaction->stream_id } == $transaction;
    croak 'HTTP Datagrams are not enabled for this Transaction'
        unless $transaction->datagrams_enabled;
    croak 'HTTP Datagram payload is required'
        unless defined $bytes;
    croak 'HTTP Datagram payload must be bytes, not a reference'
        if ref($bytes);
    croak 'HTTP/3 DATAGRAM is not negotiated with the peer'
        unless $self->can_send_http_datagrams;

    my $id = $transaction->stream_id;
    croak 'HTTP Datagram request stream send side is closed'
        if $self->{output_finished}{$id};

    my $stream = $self->{streams}{$id};
    croak 'HTTP Datagram request stream is no longer available'
        unless defined $stream;
    croak 'HTTP Datagram request stream send side is reset'
        if defined $stream->local_reset_code;

    my $quarter = $id >> 2;
    my $prefix = _encode_http3_varint($quarter);
    my $max = $self->_transaction_datagram_payload_size($transaction);

    croak "HTTP Datagram payload exceeds current path capacity $max"
        if length($bytes) > $max;

    return $self->{quic}->send_datagram($prefix . $bytes) ? 1 : 0;
}

sub _transaction_datagram_payload_size {
    my ($self, $transaction) = @_;

    croak 'HTTP Datagram Transaction does not belong to this connection'
        unless blessed($transaction)
            && $transaction->isa('Unblock::HTTP3::Transaction')
            && defined($self->{transactions}{ $transaction->stream_id })
            && $self->{transactions}{ $transaction->stream_id } == $transaction;

    return 0 unless $transaction->datagrams_enabled;
    return 0 unless $self->can_send_http_datagrams;

    my $capacity = $self->{quic}->max_datagram_payload_size;
    return 0 unless defined($capacity) && $capacity > 0;

    my $prefix = _encode_http3_varint($transaction->stream_id >> 2);
    my $available = $capacity - length($prefix);

    return $available > 0 ? $available : 0;
}

sub _buffer_transaction_datagram {
    my ($self, $transaction, $bytes) = @_;

    my $length = length($bytes);

    if (
        $self->{datagram_buffered_count} >= $self->{max_buffered_datagrams}
        || $self->{datagram_buffered_bytes} + $length
            > $self->{max_buffered_datagram_bytes}
    ) {
        ++$self->{datagram_receive_drops};
        return;
    }

    ++$self->{datagram_buffered_count};
    $self->{datagram_buffered_bytes} += $length;
    $transaction->_enqueue_datagram($bytes);
    return 1;
}

sub _datagram_dequeued {
    my ($self, $length) = @_;

    --$self->{datagram_buffered_count}
        if $self->{datagram_buffered_count} > 0;
    $self->{datagram_buffered_bytes} -= $length;
    $self->{datagram_buffered_bytes} = 0
        if $self->{datagram_buffered_bytes} < 0;

    return;
}

sub _reject_datagram_stream {
    my ($self, $transaction, $reason) = @_;

    my $id = $transaction->stream_id;
    my $stream = $self->{streams}{$id};

    if (defined $stream) {
        if ($stream->can_receive && !$stream->remote_finished) {
            $self->{native}->shutdown_stream_read($id);
            $stream->stop_sending($H3_DATAGRAM_ERROR);
            $transaction->_mark_local_stop_sending($H3_DATAGRAM_ERROR);
        }

        if ($stream->can_send && !$self->{output_finished}{$id}) {
            $self->{native}->shutdown_stream_write($id);
            $stream->reset($H3_DATAGRAM_ERROR);
            $transaction->_mark_local_reset($H3_DATAGRAM_ERROR);
        }
    }

    $self->{native}->discard_body($id);
    $transaction->_mark_error($reason);
    return;
}

sub _receive_quic_datagram {
    my ($self, $bytes, $early_data) = @_;

    return if $self->{failed};

    if ($early_data) {
        return if $self->{role} ne 'server';

        if (!defined($self->{remembered_local_settings})) {
            $self->_fail_connection(
                $H3_SETTINGS_ERROR,
                'received HTTP/3 0-RTT DATAGRAM without remembered_local_settings',
            );
            return;
        }

        # An unreliable DATAGRAM can race ahead of the client's 0-RTT
        # SETTINGS control stream. Drop it until current peer SETTINGS have
        # actually arrived; there is no safe request association yet.
        return unless $self->{peer_settings_received};
    }

    if (!$self->{enable_http_datagrams}) {
        $self->_fail_connection(
            $H3_DATAGRAM_ERROR,
            'received QUIC DATAGRAM without local SETTINGS_H3_DATAGRAM',
        );
        return;
    }

    # A peer may send after it has sent its SETTINGS while the control-stream
    # bytes are still racing this unreliable DATAGRAM. Dropping is safer than
    # assigning semantics before the peer SETTINGS have been processed.
    return unless $self->{peer_settings_received};

    if (!$self->{peer_h3_datagram}) {
        $self->_fail_connection(
            $H3_DATAGRAM_ERROR,
            'received QUIC DATAGRAM without peer SETTINGS_H3_DATAGRAM',
        );
        return;
    }

    my ($quarter, $prefix_length) = _decode_http3_varint($bytes, 0);

    if (!defined $quarter) {
        $self->_fail_connection(
            $H3_DATAGRAM_ERROR,
            'HTTP Datagram is missing a complete Quarter Stream ID',
        );
        return;
    }

    if (_decimal_less_than($HTTP3_MAX_QUARTER_STREAM_ID, $quarter)) {
        $self->_fail_connection(
            $H3_DATAGRAM_ERROR,
            'HTTP Datagram Quarter Stream ID exceeds the RFC 9297 maximum',
        );
        return;
    }

    my $id = (0 + $quarter) << 2;
    my $transaction = $self->{transactions}{$id};

    # RFC 9297 permits silently dropping a DATAGRAM that races ahead of the
    # request stream. The same treatment is appropriate after transaction
    # cleanup, where the receive side is already gone.
    return unless defined $transaction;

    my $stream = $self->{streams}{$id};
    return unless defined $stream;
    return if $stream->remote_finished;
    return if defined $stream->remote_reset_code;

    if (
        $transaction->early_data
        && $self->{role} eq 'server'
        && !$self->{quic}->ready
    ) {
        my $payload = substr($bytes, $prefix_length);
        my $length = length($payload);

        if (
            $self->{datagram_buffered_count}
                >= $self->{max_buffered_datagrams}
            || $self->{datagram_buffered_bytes} + $length
                > $self->{max_buffered_datagram_bytes}
        ) {
            ++$self->{datagram_receive_drops};
            return;
        }

        ++$self->{datagram_buffered_count};
        $self->{datagram_buffered_bytes} += $length;
        push @{ $self->{pending_early_datagrams}{$id} }, $payload;
        return;
    }

    if (!$transaction->datagrams_enabled) {
        $self->_reject_datagram_stream(
            $transaction,
            'received HTTP Datagram for a request without datagram semantics',
        );
        return;
    }

    my $payload = substr($bytes, $prefix_length);
    $transaction->_receive_datagram($payload);
    return;
}

sub _capsule_protocol_error {
    my ($self, $transaction, $error) = @_;

    croak 'Capsule Protocol Transaction does not belong to this connection'
        unless blessed($transaction)
            && $transaction->isa('Unblock::HTTP3::Transaction')
            && defined($self->{transactions}{ $transaction->stream_id })
            && $self->{transactions}{ $transaction->stream_id } == $transaction;

    my $message = defined($error) && length("$error")
        ? "$error"
        : 'malformed Capsule Protocol stream';
    $message =~ s/\s+\z//;

    $self->_reject_message_stream(
        $transaction->stream_id,
        "Capsule Protocol error: $message",
    );

    $transaction->_mark_error(
        "Capsule Protocol error: $message",
    );

    return;
}

sub _reject_message_stream {
    my ($self, $id, $reason) = @_;

    $self->{rejected_streams}{$id} = "$reason";

    my $stream = $self->{streams}{$id};
    my $transaction = $self->{transactions}{$id};

    if (defined $stream) {
        if ($stream->can_receive && !$stream->remote_finished) {
            $self->{native}->shutdown_stream_read($id);
            $stream->stop_sending($H3_MESSAGE_ERROR);
            $transaction->_mark_local_stop_sending($H3_MESSAGE_ERROR)
                if defined $transaction;
        }

        if ($stream->can_send && !defined($stream->local_reset_code)) {
            $self->{native}->shutdown_stream_write($id);
            $stream->reset($H3_MESSAGE_ERROR);
            $transaction->_mark_local_reset($H3_MESSAGE_ERROR)
                if defined $transaction;
        }
    }

    $self->{native}->discard_body($id);
    $self->{native}->discard_header_block($id);
    return;
}

sub _release_peer_bidi_stream_credit {
    my ($self, $id, $stream) = @_;

    return unless $self->{role} eq 'server';
    return unless defined $stream;
    return if $stream->local_initiated;
    return unless $stream->bidirectional;

    my $lifecycle = $self->{stream_lifecycle}{$id} ||= {};
    return if $lifecycle->{peer_bidi_credit_released};

    $lifecycle->{peer_bidi_credit_released} = 1;
    ++$self->{native_max_client_streams_bidi};

    $self->{native}->set_max_client_streams_bidi(
        $self->{native_max_client_streams_bidi},
    );

    return;
}

sub _cleanup_stream_if_done {
    my ($self, $id) = @_;

    my $lifecycle = $self->{stream_lifecycle}{$id};
    return unless defined($lifecycle) && $lifecycle->{closed_seen};

    my $transaction = $self->{transactions}{$id};
    return if defined($transaction) && !$transaction->is_terminal;

    delete $self->{streams}{$id};
    delete $self->{messages}{$id};
    delete $self->{outgoing}{$id};
    delete $self->{stream_lifecycle}{$id};
    delete $self->{trailer_field_section_size}{$id};
    delete $self->{output_finished}{$id};
    delete $self->{response_sent}{$id};
    delete $self->{body_bytes_sent}{$id};
    delete $self->{rejected_streams}{$id};
    delete $self->{peer_uni_probe}{$id};
    delete $self->{core_uni_streams}{$id};
    delete $self->{ignored_uni_streams}{$id};
    delete $self->{extension_stream_objects}{$id};
    delete $self->{transactions}{$id};

    return;
}

sub _maybe_complete_transaction {
    my ($self, $id) = @_;

    my $transaction = $self->{transactions}{$id};
    return unless defined $transaction;
    return if $transaction->is_terminal;

    if ($self->{role} eq 'client') {
        my $response = $transaction->response;
        return unless defined $response;
        return unless $response->is_complete;

        my $reader = $transaction->_incoming_body_reader('response');
        return if defined($reader) && !$reader->is_complete;

        if ($transaction->request->method eq 'CONNECT') {
            my $writer = $transaction->_request_body_object;
            return unless defined($writer) && $writer->is_complete;
        }

        $transaction->_mark_complete;
        $self->_cleanup_stream_if_done($id);
        return;
    }

    my $request = $transaction->request;
    return unless $request->is_complete;

    my $reader = $transaction->_incoming_body_reader('request');
    return if defined($reader) && !$reader->is_complete;

    return unless $self->{output_finished}{$id};

    $transaction->_mark_complete;
    $self->_cleanup_stream_if_done($id);
    return;
}

sub shutdown_notice_sent {
    my ($self, @args) = @_;
    croak 'shutdown_notice_sent() does not accept arguments' if @args;
    return $self->{shutdown_notice_sent} ? 1 : 0;
}

sub shutdown_started {
    my ($self, @args) = @_;
    croak 'shutdown_started() does not accept arguments' if @args;
    return $self->{shutdown_started} ? 1 : 0;
}

sub remote_shutdown_id {
    my ($self, @args) = @_;
    croak 'remote_shutdown_id() does not accept arguments' if @args;
    return $self->{remote_shutdown_id};
}

sub shutdown_notice {
    my ($self) = @_;

    croak 'HTTP/3 connection has not been started'
        unless $self->{started};
    croak 'HTTP/3 connection has failed'
        if $self->{failed};

    return $self if $self->{shutdown_notice_sent};

    $self->{native}->submit_shutdown_notice;
    $self->{shutdown_notice_sent} = 1;
    $self->_drain_output;

    return $self;
}

sub shutdown {
    my ($self) = @_;

    croak 'HTTP/3 connection has not been started'
        unless $self->{started};
    croak 'HTTP/3 connection has failed'
        if $self->{failed};

    return $self if $self->{shutdown_started};

    $self->{native}->begin_shutdown;
    $self->{shutdown_started} = 1;
    $self->_drain_output;

    return $self;
}

sub drained {
    my ($self, @args) = @_;

    croak 'drained() does not accept arguments' if @args;
    croak 'drained() is only meaningful for a server HTTP/3 connection'
        unless $self->{role} eq 'server';

    return $self->{native}->is_drained ? 1 : 0;
}

sub _bind_local_streams {
    my ($self) = @_;

    return 1 if defined $self->{control_stream_id};

    my $control = $self->{quic}->open_uni_stream;
    my $qenc = $self->{quic}->open_uni_stream;
    my $qdec = $self->{quic}->open_uni_stream;

    croak 'peer did not permit the three required HTTP/3 unidirectional streams'
        unless defined($control) && defined($qenc) && defined($qdec);

    for my $stream ($control, $qenc, $qdec) {
        $self->{streams}{ $stream->id } = $stream;
    }

    $self->{native}->bind_streams(
        $control->id,
        $qenc->id,
        $qdec->id,
    );

    $self->{control_stream_id} = $control->id;
    $self->{qpack_encoder_stream_id} = $qenc->id;
    $self->{qpack_decoder_stream_id} = $qdec->id;
    return 1;
}

sub start {
    my ($self) = @_;

    if ($self->{started}) {
        $self->_sync_early_data_status;
        return $self;
    }

    my $ready = $self->{quic}->ready ? 1 : 0;
    my $early_status = $self->{quic}->early_data_status;

    if (!$ready) {
        if ($self->{role} eq 'client') {
            croak 'cannot start HTTP/3 0-RTT without remembered_peer_settings'
                unless defined $self->{remembered_peer_settings};
            croak "cannot start HTTP/3 before QUIC is ready unless 0-RTT is pending"
                unless $early_status eq 'pending';
        } else {
            croak 'cannot start HTTP/3 server before QUIC is ready without remembered_local_settings'
                unless defined $self->{remembered_local_settings};
        }

        $self->{early_data_started} = 1;
    } elsif (
        $self->{role} eq 'server'
        && $early_status eq 'accepted'
        && !defined($self->{remembered_local_settings})
    ) {
        croak 'accepted QUIC 0-RTT requires remembered_local_settings for HTTP/3';
    }

    if (!defined $self->{quic}->send_buffer_limit) {
        $self->{quic}->send_buffer_limit($self->{send_buffer_limit});
    }

    # A client sending 0-RTT must send its control and QPACK streams in early
    # data. A server can receive and parse early request/control streams before
    # handshake completion, but its own HTTP/3 streams use 1-RTT and are bound
    # once the QUIC connection becomes ready.
    if ($ready || $self->{role} eq 'client') {
        $self->_bind_local_streams;
    }

    $self->{started} = 1;

    my $weak = $self;
    weaken($weak);

    $self->{quic}->on_stream_activity(sub {
        return unless defined $weak;
        $weak->_service;
    });

    $self->{quic}->on_stream_available(sub {
        return unless defined $weak;
        $weak->_service;
    });

    if ($self->{quic}->can_receive_datagram) {
        $self->{quic}->on_datagram(sub {
            my ($quic, $bytes, $early_data) = @_;
            return unless defined $weak;
            $weak->_receive_quic_datagram($bytes, $early_data);
        });
    }

    $self->_service;

    return $self;
}

sub _reset_peer_settings_to_defaults {
    my ($self) = @_;

    $self->{peer_max_field_section_size} = $HTTP3_MAX_VARINT;
    $self->{peer_enable_connect_protocol} = 0;
    $self->{peer_h3_datagram} = 0;
    $self->{peer_extension_settings} = {};
    $self->{peer_settings_wire} = {};
    $self->{peer_settings_received} = 0;
    $self->{peer_settings_initialized} = 0;
    $self->{pending_peer_settings} = undef;
    $self->{pending_peer_extension_settings} = undef;
    $self->{peer_settings_parser} = {};
    return;
}

sub _rollback_rejected_early_data {
    my ($self) = @_;

    return if $self->{early_data_rollback_done};
    return unless $self->{role} eq 'client';
    return unless $self->{early_data_started};
    return unless $self->{quic}->early_data_status eq 'rejected';
    return unless $self->{quic}->ready;

    for my $transaction (values %{ $self->{transactions} }) {
        next if $transaction->is_terminal;
        $transaction->_mark_error(
            'QUIC 0-RTT was rejected; retry the request only if it is replay-safe',
        );
    }

    $self->{transactions} = {};
    $self->{ready_transactions} = [];
    $self->{pending_early_transactions} = [];
    $self->{pending_early_datagrams} = {};
    $self->{ready_informational} = [];
    $self->{streams} = {};
    $self->{messages} = {};
    $self->{outgoing} = {};
    $self->{stream_lifecycle} = {};
    $self->{trailer_field_section_size} = {};
    $self->{output_finished} = {};
    $self->{response_sent} = {};
    $self->{body_bytes_sent} = {};
    $self->{rejected_streams} = {};
    $self->{peer_uni_probe} = {};
    $self->{core_uni_streams} = {};
    $self->{ignored_uni_streams} = {};
    $self->{extension_stream_objects} = {};
    $self->{control_settings_rewritten} = 0;
    $self->{control_settings_delta} = 0;
    $self->{control_settings_pending} = undef;
    delete $self->{control_stream_id};
    delete $self->{qpack_encoder_stream_id};
    delete $self->{qpack_decoder_stream_id};

    $self->{native} = Unblock::HTTP3::_Native->client(
        $self->{max_field_section_size},
        $self->{qpack_max_table_capacity},
        $self->{qpack_blocked_streams},
        0,
        $self->{enable_http_datagrams},
    );

    $self->_reset_peer_settings_to_defaults;

    $self->{started} = 0;
    $self->{early_data_started} = 0;
    $self->{early_data_rollback_done} = 1;
    $self->{early_data_status} = 'rejected';

    $self->start;
    return 1;
}

sub _discard_pending_early_datagrams {
    my ($self, $id) = @_;

    my $pending = delete $self->{pending_early_datagrams}{$id};
    return unless defined $pending;

    for my $bytes (@$pending) {
        $self->_datagram_dequeued(length($bytes));
    }

    return;
}

sub _promote_accepted_early_transactions {
    my ($self) = @_;

    return unless $self->{role} eq 'server';
    return unless $self->{quic}->ready;
    return if $self->{quic}->early_data_status eq 'rejected';
    return unless @{ $self->{pending_early_transactions} };

    my @pending =
        splice @{ $self->{pending_early_transactions} };

    for my $transaction (@pending) {
        next if $transaction->is_terminal;

        my $datagrams = 0;
        if (defined $self->{datagram_request}) {
            $datagrams =
                $self->{datagram_request}->(
                    $self,
                    $transaction->request,
                ) ? 1 : 0;
        }

        $transaction->_enable_datagrams if $datagrams;

        my $id = $transaction->stream_id;
        my $queued = delete $self->{pending_early_datagrams}{$id};

        if (defined $queued && @$queued) {
            if (!$datagrams) {
                for my $bytes (@$queued) {
                    $self->_datagram_dequeued(length($bytes));
                }

                $self->_reject_datagram_stream(
                    $transaction,
                    'received HTTP Datagram for a request without datagram semantics',
                );
                next;
            }

            for my $bytes (@$queued) {
                $self->_datagram_dequeued(length($bytes));
                $transaction->_receive_datagram($bytes);
            }
        }

        push @{ $self->{ready_transactions} }, $transaction;
    }

    return 1;
}

sub _reject_pending_early_transactions {
    my ($self) = @_;

    return unless $self->{role} eq 'server';
    return unless @{ $self->{pending_early_transactions} };

    my @pending =
        splice @{ $self->{pending_early_transactions} };

    for my $transaction (@pending) {
        my $id = $transaction->stream_id;
        $self->_discard_pending_early_datagrams($id);

        $transaction->_mark_error(
            'QUIC rejected 0-RTT before HTTP request processing',
        ) unless $transaction->is_terminal;
    }

    return 1;
}

sub _sync_early_data_status {
    my ($self) = @_;

    my $status = $self->{quic}->early_data_status;
    my $previous = $self->{early_data_status};
    $self->{early_data_status} = $status;

    if (
        $self->{role} eq 'client'
        && $self->{early_data_started}
        && $status eq 'rejected'
    ) {
        return $self->_rollback_rejected_early_data;
    }

    if ($self->{role} eq 'server') {
        if ($status eq 'rejected') {
            $self->_reject_pending_early_transactions;
        } elsif ($self->{quic}->ready) {
            $self->_promote_accepted_early_transactions;
        }
    }

    return 0;
}

sub _now_ns {
    return int(
        Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC())
            * 1_000_000_000
    );
}

sub _service {
    my ($self) = @_;

    return unless $self->{started};
    return if $self->{failed};

    my $restarted = $self->_sync_early_data_status;
    return if !$self->{quic}->ready
        && $self->{quic}->early_data_status eq 'rejected';
    return if $restarted;

    if (
        $self->{role} eq 'server'
        && $self->{quic}->ready
        && !defined($self->{control_stream_id})
    ) {
        $self->_bind_local_streams;
    }

    if ($self->{servicing}) {
        $self->{service_again} = 1;
        return;
    }

    $self->{servicing} = 1;

    my $ok = eval {
        do {
            $self->{service_again} = 0;

            my @new_ids;

            while (my $stream = $self->{quic}->next_stream) {
                $self->{streams}{ $stream->id } = $stream;
                push @new_ids, $stream->id;
            }

            for my $id (@new_ids) {
                last if $self->{failed};
                $self->_service_stream($id);
            }

            while (
                !$self->{failed}
                && defined(my $id = $self->{quic}->next_active_stream_id)
            ) {
                $self->_service_stream($id);
            }

            if (!$self->{failed}) {
                $self->_drain_events;
                $self->_drain_output
                    if defined $self->{control_stream_id};
            }
        } while ($self->{service_again} && !$self->{failed});

        1;
    };

    my $error = $@;
    $self->{servicing} = 0;

    die $error unless $ok;
    return;
}

sub _service_ignored_uni_stream {
    my ($self, $id, $stream) = @_;

    if ($stream->can_receive) {
        while (my $chunk = $stream->next_data_chunk) {
            my ($bytes) = @$chunk;
            $stream->consume(length($bytes))
                if length($bytes);
        }
    }

    if ($stream->closed) {
        delete $self->{streams}{$id};
        delete $self->{ignored_uni_streams}{$id};
        delete $self->{peer_uni_probe}{$id};
    }

    return;
}

sub _service_extension_stream {
    my ($self, $id, $stream, $extension) = @_;

    if ($stream->can_receive) {
        $extension->_drain_receive;
    }

    if ($stream->can_send) {
        $extension->_drain_send;
    }

    my $remote_reset = $stream->remote_reset_code;
    $extension->_mark_reset($remote_reset)
        if defined $remote_reset;

    my $remote_stop = $stream->remote_stop_sending_code;
    $extension->_mark_stop($remote_stop)
        if defined $remote_stop;

    if ($stream->closed) {
        delete $self->{streams}{$id};
        delete $self->{extension_stream_objects}{$id};
        delete $self->{peer_uni_probe}{$id};
    }

    return;
}

sub _classify_peer_uni_stream {
    my ($self, $id, $stream) = @_;

    my $state = $self->{peer_uni_probe}{$id} ||= {
        buffer => '',
        fin    => 0,
    };

    while (1) {
        my ($type, $type_length) =
            _decode_http3_varint($state->{buffer}, 0);

        if (defined $type) {
            if ($self->{role} eq 'client' && $type eq '1') {
                $stream->consume(length($state->{buffer}))
                    if length($state->{buffer});

                delete $self->{peer_uni_probe}{$id};

                $self->_fail_connection(
                    $H3_ID_ERROR,
                    'peer opened a push stream without advertised push capacity',
                );

                return 'failed';
            }

            if ($CORE_STREAM_TYPE{$type}) {
                my $bytes = $state->{buffer};
                my $fin = $state->{fin};

                delete $self->{peer_uni_probe}{$id};
                $self->{core_uni_streams}{$id} = 1;

                $self->_inspect_peer_settings_bytes($id, $bytes);
                return 'failed' if $self->{failed};

                my $result = $self->{native}->read_stream(
                    $id,
                    $bytes,
                    $fin ? 1 : 0,
                    _now_ns(),
                );

                if (@$result > 1) {
                    my ($unused, $lib_error, $app_error, $detail) = @$result;

                    $self->_fail_connection(
                        $app_error,
                        "libnghttp3 read error: $detail ($lib_error)",
                    );

                    return 'failed';
                }

                my $consumed = $result->[0];
                $stream->consume($consumed) if $consumed;
                $self->_drain_events;

                return 'core';
            }

            if (_is_grease_stream_type($type)) {
                $stream->consume(length($state->{buffer}))
                    if length($state->{buffer});

                delete $self->{peer_uni_probe}{$id};
                $self->{ignored_uni_streams}{$id} = 1;

                return 'ignored';
            }

            my $handler = $self->{extension_stream_handlers}{$type};

            if (!defined $handler) {
                $stream->consume(length($state->{buffer}))
                    if length($state->{buffer});

                delete $self->{peer_uni_probe}{$id};
                $self->{ignored_uni_streams}{$id} = 1;

                return 'ignored';
            }

            my $payload = substr(
                $state->{buffer},
                $type_length,
            );

            $stream->consume($type_length);

            require Unblock::HTTP3::Extension::Stream;

            my $extension = Unblock::HTTP3::Extension::Stream->_new(
                connection    => $self,
                stream        => $stream,
                type          => $type,
                header_length => $type_length,
                incoming      => 1,
                initial       => $payload,
                initial_fin   => $state->{fin},
            );

            delete $self->{peer_uni_probe}{$id};
            $self->{extension_stream_objects}{$id} = $extension;

            $handler->($self, $extension);
            $extension->_drain_receive;

            return 'extension';
        }

        my $chunk = $stream->next_data_chunk;

        if (!defined $chunk) {
            if ($stream->remote_finished) {
                $stream->consume(length($state->{buffer}))
                    if length($state->{buffer});

                delete $self->{peer_uni_probe}{$id};
                $self->{ignored_uni_streams}{$id} = 1;

                return 'ignored';
            }

            return 'pending';
        }

        my ($bytes, $fin) = @$chunk;
        $state->{buffer} .= $bytes;
        $state->{fin} ||= $fin ? 1 : 0;

        if ($fin && !length($state->{buffer})) {
            delete $self->{peer_uni_probe}{$id};
            $self->{ignored_uni_streams}{$id} = 1;
            return 'ignored';
        }
    }
}

sub _is_local_critical_stream {
    my ($self, $id) = @_;

    return 1
        if defined($self->{control_stream_id})
            && $id == $self->{control_stream_id};
    return 1
        if defined($self->{qpack_encoder_stream_id})
            && $id == $self->{qpack_encoder_stream_id};
    return 1
        if defined($self->{qpack_decoder_stream_id})
            && $id == $self->{qpack_decoder_stream_id};

    return 0;
}

sub _service_stream {
    my ($self, $id) = @_;

    my $stream = $self->{streams}{$id};
    return unless defined $stream;

    if (my $extension = $self->{extension_stream_objects}{$id}) {
        $self->_service_extension_stream(
            $id,
            $stream,
            $extension,
        );
        return;
    }

    if ($self->{ignored_uni_streams}{$id}) {
        $self->_service_ignored_uni_stream($id, $stream);
        return;
    }

    if (
        !$stream->bidirectional
        && !$stream->local_initiated
        && !$self->{core_uni_streams}{$id}
        && !exists($self->{peer_uni_probe}{$id})
    ) {
        $self->{peer_uni_probe}{$id} = {
            buffer => '',
            fin    => 0,
        };
    }

    if (exists $self->{peer_uni_probe}{$id}) {
        my $kind = $self->_classify_peer_uni_stream(
            $id,
            $stream,
        );

        if ($kind eq 'extension') {
            my $extension = $self->{extension_stream_objects}{$id};
            $self->_service_extension_stream(
                $id,
                $stream,
                $extension,
            ) if defined $extension;
            return;
        }

        if ($kind eq 'ignored') {
            $self->_service_ignored_uni_stream($id, $stream);
            return;
        }

        return if $kind ne 'core';
        return if $self->{failed};
    }

    if ($self->{rejected_streams}{$id}) {
        if ($stream->can_receive) {
            while (my $chunk = $stream->next_data_chunk) {
                my ($bytes) = @$chunk;
                $stream->consume(length($bytes))
                    if length($bytes);
            }
        }

        if ($stream->closed) {
            $self->_release_peer_bidi_stream_credit(
                $id,
                $stream,
            );
            $self->{native}->discard_body($id);
            delete $self->{streams}{$id};
            delete $self->{stream_lifecycle}{$id};
                    delete $self->{rejected_streams}{$id};
        }

        return;
    }

    if ($stream->can_receive) {
        while (1) {
            my $chunk = $stream->next_data_chunk;
            last unless defined $chunk;

            my ($bytes, $fin) = @$chunk;

            $self->_inspect_peer_settings_bytes($id, $bytes);
            return if $self->{failed};

            my $result = $self->{native}->read_stream(
                $id,
                $bytes,
                $fin ? 1 : 0,
                _now_ns(),
            );

            if (@$result > 1) {
                my ($unused, $lib_error, $app_error, $detail) = @$result;

                $self->_fail_connection(
                    $app_error,
                    "libnghttp3 read error: $detail ($lib_error)",
                );
                return;
            }

            my $consumed = $result->[0];
            $stream->consume($consumed) if $consumed;
            $self->_drain_events;
            return if $self->{failed};
        }
    }

    if ($stream->can_send) {
        my $acked_offset = $stream->acked_offset;

        if (
            defined($self->{control_stream_id})
            && $id == $self->{control_stream_id}
        ) {
            if (defined $self->{control_settings_pending}) {
                $acked_offset = 0;
            } elsif ($self->{control_settings_delta}) {
                my $delta = $self->{control_settings_delta};
                $acked_offset = $acked_offset > $delta
                    ? $acked_offset - $delta
                    : 0;
            }
        }

        $self->{native}->update_ack_offset(
            $id,
            $acked_offset,
        );
        $self->_drain_events;
        return if $self->{failed};
        $self->_drain_body_producers;
    }

    my $lifecycle = $self->{stream_lifecycle}{$id} ||= {};

    my $remote_reset = $stream->remote_reset_code;
    if (defined($remote_reset) && !$lifecycle->{remote_reset_seen}) {
        $lifecycle->{remote_reset_seen} = 1;
        $lifecycle->{remote_reset_code} = 0 + $remote_reset;

        if ($self->{core_uni_streams}{$id}) {
            $self->_fail_connection(
                $H3_CLOSED_CRITICAL_STREAM,
                'peer reset a critical HTTP/3 stream',
            );
            return;
        }

        $self->{native}->shutdown_stream_read($id);

        my $transaction = $self->{transactions}{$id};
        if (defined $transaction) {
            $transaction->_mark_remote_reset($remote_reset);
            $transaction->_mark_cancelled
                unless $transaction->is_terminal;
        }
    }

    my $remote_stop = $stream->remote_stop_sending_code;
    if (defined($remote_stop) && !$lifecycle->{remote_stop_seen}) {
        $lifecycle->{remote_stop_seen} = 1;
        $lifecycle->{remote_stop_sending_code} = 0 + $remote_stop;

        if ($self->_is_local_critical_stream($id)) {
            $self->_fail_connection(
                $H3_CLOSED_CRITICAL_STREAM,
                'peer requested closure of a critical HTTP/3 stream',
            );
            return;
        }

        $self->{native}->shutdown_stream_write($id);
        $self->{native}->discard_body($id);

        my $transaction = $self->{transactions}{$id};
        if (defined $transaction) {
            $transaction->_mark_remote_stop_sending($remote_stop);
            $transaction->_mark_cancelled
                unless $transaction->is_terminal;
        }
    }

    if ($stream->closed && !$lifecycle->{closed_seen}) {
        $lifecycle->{closed_seen} = 1;

        if ($self->{core_uni_streams}{$id}) {
            $self->_fail_connection(
                $H3_CLOSED_CRITICAL_STREAM,
                'peer closed a critical HTTP/3 stream',
            );
            return;
        }

        $self->_release_peer_bidi_stream_credit(
            $id,
            $stream,
        );

        $self->{native}->close_stream(
            $id,
            $remote_reset,
            $stream->local_reset_code,
        );

        $self->_cleanup_stream_if_done($id);
    }

    return;
}

sub _drain_events {
    my ($self) = @_;

    while (!$self->{failed} && (my $event = $self->{native}->next_event)) {
        my ($type, $id, @args) = @$event;

        if ($type eq 'settings') {
            $self->{peer_max_field_section_size} = "$args[0]";
            $self->{peer_enable_connect_protocol} = $args[1] ? 1 : 0;
            $self->{peer_h3_datagram} = $args[2] ? 1 : 0;
            $self->_accept_peer_extension_settings;
            next;
        }

        if ($type eq 'origin') {
            push @{ $self->{peer_origin_pending} }, $args[0]
                if _valid_origin_serialization($args[0]);
            next;
        }

        if ($type eq 'end_origin') {
            $self->{peer_origins} = []
                unless defined $self->{peer_origins};

            push @{ $self->{peer_origins} },
                @{ $self->{peer_origin_pending} };

            $self->{peer_origin_pending} = [];
            next;
        }

        if ($self->{rejected_streams}{$id}) {
            if ($type eq 'data') {
                my $stream = $self->{streams}{$id};
                $stream->consume(length($args[0]))
                    if defined($stream) && length($args[0]);
            } elsif ($type eq 'deferred_consume') {
                my $stream = $self->{streams}{$id};
                $stream->consume($args[0])
                    if defined($stream) && $args[0];
            }
            next;
        }

        if ($type eq 'headers') {
            my ($field_section_size, $fin) = @args;

            if (
                $field_section_size
                > $self->{max_field_section_size}
            ) {
                $self->_fail_connection(
                    $H3_EXCESSIVE_LOAD,
                    'HTTP/3 field section exceeds configured limit',
                );
                next;
            }

            $self->_finish_headers(
                $id,
                $fin ? 1 : 0,
            );
            next;
        }

        if ($type eq 'data') {
            my $bytes = $args[0];
            my $message = $self->{messages}{$id};

            croak "received HTTP/3 DATA before message headers"
                unless defined $message;

            my $transaction = $self->{transactions}{$id}
                or croak "received HTTP/3 DATA for unknown Transaction";
            my $kind = $self->{role} eq 'server'
                ? 'request'
                : 'response';
            my $reader = $transaction->_incoming_body_reader($kind);

            if (defined $reader) {
                if (
                    $reader->pending_bytes + length($bytes)
                    > $self->{max_streaming_body_bytes}
                ) {
                    $self->_fail_connection(
                        $H3_EXCESSIVE_LOAD,
                        'HTTP/3 streaming body queue exceeds configured limit',
                    );
                    next;
                }

                $reader->_push_owned($bytes);
                next;
            }

            my $current = $transaction->_buffered_body_bytes($kind);

            if (
                $current + length($bytes)
                > $self->{max_buffered_body_bytes}
            ) {
                $self->_fail_connection(
                    $H3_EXCESSIVE_LOAD,
                    'HTTP/3 buffered body exceeds configured limit',
                );
                next;
            }

            $transaction->_append_buffered_body($kind, $bytes);

            my $stream = $self->{streams}{$id};
            $stream->consume(length($bytes))
                if defined($stream) && length($bytes);

            next;
        }

        if ($type eq 'deferred_consume') {
            my $stream = $self->{streams}{$id};
            $stream->consume($args[0])
                if defined($stream) && $args[0];
            next;
        }

        if ($type eq 'end_stream') {
            my $transaction = $self->{transactions}{$id};
            if (defined $transaction) {
                my $kind = $self->{role} eq 'server'
                    ? 'request'
                    : 'response';
                my $reader = $transaction->_incoming_body_reader($kind);

                if (defined $reader) {
                    $reader->_mark_end;

                    my $message = $self->{messages}{$id};
                    if (defined $message) {
                        $message->freeze_trailers;
                        $message->freeze;
                        $message->mark_complete;
                    }
                } else {
                    $transaction->_finish_received_message($kind);
                }
            }

            $self->_maybe_complete_transaction($id);
            next;
        }

        if ($type eq 'stop_sending') {
            my $stream = $self->{streams}{$id};
            if (defined($stream) && $stream->can_receive) {
                $stream->stop_sending($args[0]);
                my $transaction = $self->{transactions}{$id};
                $transaction->_mark_local_stop_sending($args[0])
                    if defined $transaction;
            }
            next;
        }

        if ($type eq 'reset_stream') {
            my $transaction = $self->{transactions}{$id};
            $transaction->_mark_local_reset($args[0])
                if defined $transaction;

            my $stream = $self->{streams}{$id};
            $stream->reset($args[0])
                if defined($stream) && $stream->can_send;
            next;
        }

        if ($type eq 'begin_trailers') {
            $self->{trailer_field_section_size}{$id} = 0;
            next;
        }

        if ($type eq 'trailer') {
            my $message = $self->{messages}{$id};

            croak "received HTTP/3 trailer before message headers"
                unless defined $message;

            $self->{trailer_field_section_size}{$id}
                = ($self->{trailer_field_section_size}{$id} // 0)
                + length($args[0]) + length($args[1]) + 32;

            if (
                $self->{trailer_field_section_size}{$id}
                > $self->{max_field_section_size}
            ) {
                $self->_fail_connection(
                    $H3_EXCESSIVE_LOAD,
                    'HTTP/3 trailer field section exceeds configured limit',
                );
                next;
            }

            $message->add_trailer(
                $args[0],
                $args[1],
            );
            next;
        }

        if ($type eq 'end_trailers') {
            delete $self->{trailer_field_section_size}{$id};
            my $message = $self->{messages}{$id};

            if (defined $message) {
                _coalesce_trailer_cookie_fields($message);
                $message->freeze_trailers;
            }

            next;
        }

        if ($type eq 'shutdown') {
            $self->{remote_shutdown_id} = 0 + $id;
            next;
        }

        if ($type eq 'stream_close') {
            next;
        }

        croak "unknown native HTTP/3 event '$type'";
    }

    return;
}

sub _coalesce_trailer_cookie_fields {
    my ($message) = @_;

    my $values = $message->trailer_values('cookie');
    return unless @$values > 1;

    $message->trailer(
        'cookie',
        join('; ', @$values),
    );

    return 1;
}

sub _finish_headers {
    my ($self, $id, $fin) = @_;

    my $message;

    if ($self->{role} eq 'server') {
        my $method = $self->{native}->header_pseudo($id, ':method');

        croak 'HTTP/3 request is missing :method'
            unless defined $method;

        my $scheme = $self->{native}->header_pseudo($id, ':scheme');
        my $authority = $self->{native}->header_pseudo($id, ':authority');
        my $path = $self->{native}->header_pseudo($id, ':path');
        my $protocol = $self->{native}->header_pseudo($id, ':protocol');
        my $is_connect = $method eq 'CONNECT' ? 1 : 0;
        my $is_extended_connect =
            $is_connect && defined($protocol) ? 1 : 0;
        my $target;
        my $host_values = $self->{native}->header_values($id, 'host');

        if ($is_connect && !$is_extended_connect) {
            croak 'HTTP/3 CONNECT request is missing :authority'
                unless defined $authority;
            croak 'HTTP/3 CONNECT request must not contain :scheme'
                if defined $scheme;
            croak 'HTTP/3 CONNECT request must not contain :path'
                if defined $path;

            $target = $authority;

            my $semantic_error = _request_semantic_error(
                method      => 'CONNECT',
                scheme      => undef,
                authority   => $authority,
                target      => $target,
                protocol    => undef,
                host_values => $host_values,
            );

            if (defined $semantic_error) {
                $self->_reject_message_stream($id, $semantic_error);
                return;
            }
        } else {
            if ($is_extended_connect && !$self->{enable_extended_connect}) {
                $self->_reject_message_stream(
                    $id,
                    'Extended CONNECT was not enabled by this server',
                );
                return;
            }

            if ($is_extended_connect && !defined $path) {
                $self->_reject_message_stream(
                    $id,
                    'Extended CONNECT requires :path',
                );
                return;
            }

            croak 'HTTP/3 request is missing :path'
                unless defined $path;

            $target = $path;

            my $semantic_error = _request_semantic_error(
                method      => $method,
                scheme      => $scheme,
                authority   => $authority,
                target      => $target,
                protocol    => $protocol,
                host_values => $host_values,
            );

            if (defined $semantic_error) {
                $self->_reject_message_stream($id, $semantic_error);
                return;
            }

            if (!defined($authority) && @$host_values == 1) {
                $authority = $host_values->[0];
            }
        }

        $message = $self->{native}->receive_uniform_request(
            $id,
            $method,
            $target,
            $scheme,
            $authority,
            $protocol,
            $fin,
        );

        my $response = Uniform::HTTP::Response->new(
            status  => 200,
            version => '3',
        );

        my $stream = $self->{streams}{$id};
        my $stream_is_early = defined($stream) && $stream->early_data ? 1 : 0;

        if ($stream_is_early && !defined($self->{remembered_local_settings})) {
            $self->_fail_connection(
                $H3_SETTINGS_ERROR,
                'received HTTP/3 0-RTT request without remembered_local_settings',
            );
            return;
        }

        my $transaction = Unblock::HTTP3::Transaction->_new(
            connection => $self,
            stream_id  => $id,
            request    => $message,
            response   => $response,
            early_data => $stream_is_early,
        );

        my $request_receive_mode = $is_connect
            ? 'stream'
            : $self->{receive_body_mode};

        $transaction->_configure_receive_body(
            'request',
            $request_receive_mode,
            {},
        );
        $transaction->_ensure_receive_reader('request')
            if $request_receive_mode eq 'stream';

        $self->{transactions}{$id} = $transaction;

        if (
            $stream_is_early
            && !$self->{quic}->ready
        ) {
            push @{ $self->{pending_early_transactions} }, $transaction;
        } else {
            my $datagrams = 0;
            if (defined $self->{datagram_request}) {
                $datagrams =
                    $self->{datagram_request}->($self, $message) ? 1 : 0;
            }

            $transaction->_enable_datagrams if $datagrams;
            push @{ $self->{ready_transactions} }, $transaction;
        }
    } else {
        my $status = $self->{native}->header_pseudo($id, ':status');

        croak 'HTTP/3 response is missing :status'
            unless defined $status;

        if (
            $self->{native}->has_header($id, 'capsule-protocol')
            && !(0 + $status >= 200 && 0 + $status < 300)
        ) {
            $self->_reject_message_stream(
                $id,
                'Capsule-Protocol is only valid on a successful HTTP/3 response',
            );
            return;
        }

        $message = $self->{native}->receive_uniform_response(
            $id,
            0 + $status,
            $fin,
        );

        my $transaction = $self->{transactions}{$id}
            or croak "received HTTP/3 response for unknown Transaction";

        if ($message->status < 200) {
            $message->mark_complete;
            $message->freeze;

            croak 'HTTP/3 does not use 101 Switching Protocols'
                if $message->status == 101;
            croak 'informational HTTP/3 response cannot end the stream'
                if $fin;

            $transaction->_push_informational($message);
            push @{ $self->{ready_informational} }, $transaction;
            return;
        }

        $transaction->_set_response($message);
        $transaction->_ensure_receive_reader('response');

        if (
            $transaction->request->method eq 'CONNECT'
            && ($message->status < 200 || $message->status >= 300)
        ) {
            my $writer = $transaction->_request_body_object;
            $writer->complete
                if defined($writer) && !$writer->is_complete;
        }

        push @{ $self->{ready_transactions} }, $transaction;
    }

    my $lifecycle = $self->{stream_lifecycle}{$id};

    my $transaction = $self->{transactions}{$id};

    if (defined($lifecycle) && defined($transaction)) {
        if (defined $lifecycle->{remote_reset_code}) {
            $transaction->_mark_remote_reset(
                $lifecycle->{remote_reset_code},
            );
            $transaction->_mark_cancelled
                unless $transaction->is_terminal;
        }

        if (defined $lifecycle->{remote_stop_sending_code}) {
            $transaction->_mark_remote_stop_sending(
                $lifecycle->{remote_stop_sending_code},
            );
            $transaction->_mark_cancelled
                unless $transaction->is_terminal;
        }
    }

    $self->{messages}{$id} = $message;
    return;
}

sub _validate_wire_field {
    my ($context, $name, $value) = @_;

    croak "HTTP/3 does not allow connection-specific field '$name'"
        if $CONNECTION_SPECIFIC_FIELD{$name};

    if ($name eq 'te') {
        croak "HTTP/3 TE is only allowed in request headers"
            unless $context eq 'request';

        my $normalized = $value;
        $normalized =~ s/\A[ \t]+//;
        $normalized =~ s/[ \t]+\z//;

        croak "HTTP/3 TE field may contain only 'trailers'"
            unless lc($normalized) eq 'trailers';
    }

    return;
}

sub _decimal_less_than {
    my ($left, $right) = @_;

    $left = "$left";
    $right = "$right";

    $left =~ s/\A0+//;
    $right =~ s/\A0+//;
    $left = '0' if $left eq '';
    $right = '0' if $right eq '';

    return 1 if length($left) < length($right);
    return 0 if length($left) > length($right);

    return $left lt $right ? 1 : 0;
}

sub _field_section_size {
    my ($fields) = @_;

    my $size = 0;

    for my $field (@$fields) {
        $size += length($field->[0]) + length($field->[1]) + 32;
    }

    return $size;
}

sub _assert_peer_field_section_size_value {
    my ($self, $size, $operation) = @_;

    my $limit = $self->{peer_max_field_section_size};

    croak "$operation: field section size $size exceeds peer "
        . "SETTINGS_MAX_FIELD_SECTION_SIZE $limit"
        if _decimal_less_than($limit, $size);

    return $size;
}

sub _assert_peer_field_section_size {
    my ($self, $fields, $operation) = @_;

    return _assert_peer_field_section_size_value(
        $self,
        _field_section_size($fields),
        $operation,
    );
}

sub _wire_headers {
    my ($source, $context) = @_;

    croak 'internal HTTP/3 header context must be request or response'
        if $context ne 'request' && $context ne 'response';

    my @headers;

    for my $field (@$source) {
        my $name = $field->[0];
        my $value = $field->[1];

        $name =~ tr/A-Z/a-z/;

        _validate_wire_field($context, $name, $value);
        push @headers, [ $name, $value ];
    }

    return \@headers;
}

sub _wire_trailers {
    my ($source) = @_;

    my @trailers;

    for my $field (@$source) {
        my $name = $field->[0];
        my $value = $field->[1];

        $name =~ tr/A-Z/a-z/;

        _validate_wire_field('trailer', $name, $value);

        croak "HTTP/3 TE is not allowed in trailers"
            if $name eq 'te';
        croak "HTTP/3 Content-Length is not allowed in trailers"
            if $name eq 'content-length';
        croak "HTTP/3 Host is not allowed in trailers"
            if $name eq 'host';

        push @trailers, [ $name, $value ];
    }

    return \@trailers;
}

sub _submit_request {
    my ($self, $request, $streaming) = @_;

    croak 'request submission requires a client HTTP/3 connection'
        unless $self->{role} eq 'client';
    croak 'HTTP/3 connection has not been started'
        unless $self->{started};
    croak 'request must be a canonical Uniform::HTTP::Request'
        unless ref($request) eq 'Uniform::HTTP::Request';
    croak 'HTTP/3 peer has begun graceful shutdown'
        if defined $self->{remote_shutdown_id};
    croak 'HTTP/3 connection is shutting down'
        if $self->{shutdown_notice_sent} || $self->{shutdown_started};

    $self->_assert_peer_field_section_size_value(
        $self->{native}->uniform_request_field_section_size($request),
        'request()',
    );

    my $trailer_size =
        $self->{native}->uniform_trailer_field_section_size($request);

    $self->_assert_peer_field_section_size_value(
        $trailer_size,
        'request trailers',
    ) if $trailer_size;

    my $stream = $self->{quic}->open_bidi_stream;
    return unless defined $stream;

    my $id = $stream->id;
    $self->{streams}{$id} = $stream;

    $streaming = $streaming ? 1 : 0;

    $self->{native}->submit_uniform_request(
        $id,
        $request,
        $streaming,
    );

    $request->freeze;
    $self->{outgoing}{$id} = $request;

    $self->_drain_output;

    return $id;
}

sub _submit_response {
    my ($self, $stream_id, $response) = @_;

    croak 'response submission requires a server HTTP/3 connection'
        unless $self->{role} eq 'server';
    croak 'HTTP/3 connection has not been started'
        unless $self->{started};
    croak 'response must be a canonical Uniform::HTTP::Response'
        unless ref($response) eq 'Uniform::HTTP::Response';
    croak 'unknown HTTP/3 request stream'
        unless defined $self->{streams}{$stream_id};

    $self->_assert_peer_field_section_size_value(
        $self->{native}->uniform_response_field_section_size($response),
        'send_response()',
    );

    my $trailer_size =
        $self->{native}->uniform_trailer_field_section_size($response);

    $self->_assert_peer_field_section_size_value(
        $trailer_size,
        'response trailers',
    ) if $trailer_size;

    my $transaction = $self->{transactions}{$stream_id};
    my $streaming = defined($transaction)
        && $transaction->_response_is_streaming
        ? 1
        : 0;

    $self->{native}->submit_uniform_response(
        $stream_id,
        $response,
        $streaming,
    );

    $response->freeze;

    $self->_drain_output;
    return $response;
}

sub _drain_output {
    my ($self) = @_;

    while (1) {
        if (my $pending = $self->{control_settings_pending}) {
            my $id = $pending->{id};
            my $stream = $self->{streams}{$id}
                or croak "missing HTTP/3 control stream $id";

            my $remaining = substr(
                $pending->{bytes},
                $pending->{offset},
            );
            my $length = length($remaining);
            my $accepted = $length
                ? $stream->send_some($remaining)
                : 0;

            $pending->{offset} += $accepted;

            last if $pending->{offset} < length($pending->{bytes});

            $self->{native}->add_write_offset(
                $id,
                $pending->{native_length},
            );

            $self->{control_settings_delta} = $pending->{delta};
            delete $self->{control_settings_pending};
            next;
        }

        my $out = $self->{native}->next_write;
        last unless defined $out;

        my ($id, $bytes, $fin) = @$out;
        my $stream = $self->{streams}{$id}
            or croak "libnghttp3 selected unknown QUIC stream $id";

        if (
            !$self->{control_settings_rewritten}
            && defined($self->{control_stream_id})
            && $id == $self->{control_stream_id}
            && keys %{ $self->{extension_settings} }
        ) {
            croak 'HTTP/3 control stream unexpectedly ended with SETTINGS'
                if $fin;

            my ($rewritten, $native_length, $delta) =
                _rewrite_control_settings(
                    $bytes,
                    $self->{extension_settings},
                );

            $self->{control_settings_rewritten} = 1;
            $self->{control_settings_pending} = {
                id            => $id,
                bytes         => $rewritten,
                offset        => 0,
                native_length => $native_length,
                delta         => $delta,
            };
            next;
        }

        $self->{control_settings_rewritten} = 1
            if defined($self->{control_stream_id})
                && $id == $self->{control_stream_id};

        my $length = length($bytes);
        my $accepted = 0;

        if ($length) {
            $accepted = $stream->send_some($bytes);
        }

        $self->{native}->add_write_offset($id, $accepted);

        if ($fin && $accepted == $length) {
            $stream->finish;
            $self->{output_finished}{$id} = 1;
            $self->_maybe_complete_transaction($id);
        }

        last if $accepted < $length;
        last if !$length && !$fin;
    }

    return;
}

1;

__END__

=head1 NAME

Unblock::HTTP3::Connection - one HTTP/3 connection over Net::QUIC

=head1 SYNOPSIS

    use Unblock::HTTP3::Connection;
    use Uniform::HTTP::Request;

    my $h3 = Unblock::HTTP3::Connection->client(
        quic => $quic,
    );

    $h3->start;

    my $tx = $h3->request(
        Uniform::HTTP::Request->new(
            method    => 'GET',
            target    => '/',
            scheme    => 'https',
            authority => 'example.com',
        ),
    );

=head1 DESCRIPTION

One C<Unblock::HTTP3::Connection> wraps one L<Net::QUIC::Connection>.

Unblock::HTTP3 owns HTTP/3 connection state, control streams, QPACK integration,
request streams, HTTP/3 errors, and HTTP/3 extensions. Net::QUIC owns QUIC and
TLS. The event-loop adapter owns the UDP socket and timer.

L<Uniform::HTTP> supplies common request and response semantics.

=head1 CONSTRUCTORS

=head2 client

    my $h3 = Unblock::HTTP3::Connection->client(
        quic => $quic,
    );

Creates client-side HTTP/3 state.

=head2 server

    my $h3 = Unblock::HTTP3::Connection->server(
        quic => $quic,
    );

Creates server-side HTTP/3 state.

=head1 OPTIONS

C<quic> is required and must be a L<Net::QUIC::Connection>.

Common options are:

=over 4

=item C<send_buffer_limit>

Maximum buffered HTTP/3 output bytes. The default is 4 MiB.

=item C<max_field_section_size>

Maximum decoded header or trailer field-section size. The default is 65536
bytes.

=item C<max_buffered_body_bytes>

Maximum body size retained in a buffered Request or Response. The default is
64 MiB.

=item C<max_streaming_body_bytes>

Maximum queued incoming streaming body bytes. The default is 4 MiB.

=item C<receive_body>

C<buffered> by default. Use C<stream> to receive bodies through
L<Unblock::HTTP3::Body::Reader>.

=item C<qpack_max_table_capacity>

Local QPACK dynamic-table capacity. The default is 4096.

=item C<qpack_blocked_streams>

Local QPACK blocked-stream limit. The default is 100.

=item C<enable_extended_connect>

Server only. Advertises Extended CONNECT support.

=item C<enable_http_datagrams>

Advertises RFC 9297 HTTP Datagram support. The Net::QUIC connection must also
have QUIC DATAGRAM receive support.

=item C<origins>

Server only. Array reference of RFC 6454 ASCII origin serializations to send in
the RFC 9412 ORIGIN frame. An empty array sends an explicit empty ORIGIN frame.
Omit the option to send no ORIGIN frame.

=item C<datagram_request>

Server-only callback used to decide whether an incoming request uses HTTP
Datagrams. It receives the Connection and Request.

=item C<max_buffered_datagram_bytes>

Maximum total bytes retained in Transaction Datagram queues. The default is
1 MiB.

=item C<max_buffered_datagrams>

Maximum number of retained HTTP Datagrams. The default is 1024.

=item C<quic_max_bidi_streams>

Server-only synchronization value for libnghttp3 request stream validation.
The default is 100, matching Net::QUIC 0.04. If the QUIC server uses a
different C<transport-E<gt>{max_bidi_streams}> value, pass the same value here.

=item C<extension_settings>

Hash reference of additional HTTP/3 SETTINGS identifiers and values.

=item C<on_extension_settings>

Callback run after peer extension SETTINGS are accepted. It receives the
Connection and a hash reference of peer extension SETTINGS. Dying from the
callback rejects the settings with C<H3_SETTINGS_ERROR>.

=item C<extension_stream_handlers>

Hash reference mapping extension unidirectional stream types to callbacks.

=item C<remembered_peer_settings>

Client-only opaque value previously returned by C<peer_settings_state>. Used
for HTTP/3 0-RTT.

=item C<remembered_local_settings>

Server-only opaque value previously returned by C<local_settings_state>. Used
to validate HTTP/3 settings when accepting 0-RTT.

=back

=head1 METHODS

=head2 start

Starts HTTP/3 processing and creates the required control and QPACK streams.

Normally QUIC is already ready. A returning client with remembered peer
SETTINGS may start while QUIC early data is pending. A server with remembered
local SETTINGS may start early and parse 0-RTT request bytes internally.

Server 0-RTT Transactions are not returned by C<next_transaction> and the
C<datagram_request> application callback is not run until the QUIC handshake
has completed and the early data has not been rejected.

Returns the Connection.

=head2 request

    my $tx = $h3->request($request);

Client only. Submits a canonical L<Uniform::HTTP::Request> and returns a
L<Unblock::HTTP3::Transaction>.

Useful per-request options are:

    stream_body
    receive_body
    datagrams
    early_data

C<stream_body> configures an outgoing streaming request body.

C<receive_body> configures streaming response receipt.

C<datagrams =E<gt> 1> marks the request as using HTTP Datagram semantics.

C<early_data =E<gt> 1> explicitly permits submission before the QUIC handshake
finishes. 0-RTT is replayable. Unblock::HTTP3 does not retry an early request
automatically if QUIC rejects it.

=head2 next_transaction

Returns the next ready Transaction, or undef when none is queued.

On a server this is a newly received request. A request received in 0-RTT is
withheld until the QUIC handshake completes and the early data has not been
rejected.

On a client this is an existing Transaction whose final response headers have
arrived.

=head2 next_informational

Client only. Returns a Transaction which has received a new 1xx response.
Retrieve the response with C<< $tx->next_informational >>.

=head2 role

Returns C<client> or C<server>.

=head2 quic

Returns the wrapped L<Net::QUIC::Connection>.

=head2 nghttp3_version

Returns the runtime libnghttp3 version string.

=head2 started

True after C<start> succeeds.

=head2 failed

True after a fatal local HTTP/3 error.

=head2 error

Returns the saved error text after C<failed> becomes true.

=head2 error_code

Returns the HTTP/3 application error code associated with C<error>, or undef
when no fatal HTTP/3 error has been recorded.

=head2 receive_body_mode

    my $mode = $h3->receive_body_mode;
    $h3->receive_body_mode('stream');

Gets or changes the default receive mode for future Transactions. Valid values
are C<buffered> and C<stream>.

=head2 max_field_section_size

Returns the configured field-section limit.

=head2 max_buffered_body_bytes

Returns the configured buffered-body limit.

=head2 max_streaming_body_bytes

Returns the configured queued streaming-body limit.

=head2 qpack_max_table_capacity

Returns the configured QPACK table capacity.

=head2 qpack_blocked_streams

Returns the configured QPACK blocked-stream limit.

=head2 extended_connect_enabled

True when this server advertises Extended CONNECT support.

=head2 peer_extended_connect_enabled

True when the peer advertised Extended CONNECT support.

=head2 http_datagrams_enabled

True when this endpoint advertises SETTINGS_H3_DATAGRAM.

=head2 peer_http_datagrams_enabled

True when the peer advertised SETTINGS_H3_DATAGRAM.

=head2 can_send_http_datagrams

True when HTTP Datagrams are negotiated and Net::QUIC currently permits QUIC
DATAGRAM transmission.

=head2 can_receive_http_datagrams

True when HTTP Datagrams are negotiated and local QUIC DATAGRAM receive support
is active.

=head2 datagram_receive_drops

Returns the number of incoming HTTP Datagram payloads dropped because bounded
Transaction receive queues were full.

=head2 local_settings_state

Returns an opaque byte string representing this endpoint's advertised HTTP/3
SETTINGS. Store it without modifying it.

=head2 peer_settings_state

Returns an opaque byte string representing the current peer HTTP/3 SETTINGS
after C<peer_settings_received> becomes true. Before that it returns undef.

A client should save this with Net::QUIC's early-data state from the same
connection when it intends to attempt 0-RTT later.

=head2 using_remembered_peer_settings

True while a returning client is still using remembered server SETTINGS before
the new server SETTINGS frame arrives.

=head2 peer_settings_received

True after the peer SETTINGS frame has been accepted.

=head2 peer_origins

Returns undef until a complete RFC 9412 ORIGIN frame has been received.

After that, returns a copy of the cumulative valid origin entries advertised by
the server. An explicit empty ORIGIN frame therefore returns an empty array
reference rather than undef. Invalid origin entries are ignored as required by
RFC 8336.

=head2 early_data_status

Returns Net::QUIC's early-data status:

    none
    pending
    accepted
    rejected

Calling this method also applies any required HTTP/3 rollback after QUIC rejects
early data.

=head2 extension_settings

Returns a copy of the local extension SETTINGS.

=head2 extension_setting

    my $value = $h3->extension_setting($id);
    $h3->extension_setting($id, $value);

Gets or sets one extension SETTING. Values may only be changed before
C<start>.

Core, HTTP/3-reserved, and GREASE setting identifiers cannot be assigned
extension semantics.

=head2 peer_extension_settings

Returns a copy of peer extension SETTINGS.

=head2 peer_extension_setting

    my $value = $h3->peer_extension_setting($id);

Returns one peer extension SETTING, or undef if it was not advertised.

=head2 extension_stream_handler

    $h3->extension_stream_handler(
        $type,
        sub {
            my ($connection, $stream) = @_;
            ...
        },
    );

Registers one incoming extension unidirectional stream handler before
C<start>.

=head2 open_extension_stream

    my $stream = $h3->open_extension_stream($type);

Opens an outgoing HTTP/3 extension unidirectional stream.

Returns L<Unblock::HTTP3::Extension::Stream>, or undef when QUIC
unidirectional stream credit is exhausted.

=head2 shutdown_notice

Sends the first graceful HTTP/3 shutdown notice. Returns the Connection.

=head2 shutdown

Begins final graceful HTTP/3 shutdown. Returns the Connection.

The application or event-loop adapter decides how long to allow between
C<shutdown_notice> and C<shutdown>.

=head2 shutdown_notice_sent

True after the first graceful shutdown notice has been submitted.

=head2 shutdown_started

True after final graceful shutdown has started.

=head2 remote_shutdown_id

Returns the most recent shutdown identifier received from the peer, or undef
before the peer begins graceful shutdown.

=head2 drained

Server only. True when graceful shutdown has no request streams left to
process.

=head1 NOTES

Unblock::HTTP3 does not own the event loop. Network and timer activity continue
to be driven through Net::QUIC.

HTTP/3 Server Push is not exposed because the libnghttp3 version used by this
release does not implement it.

=head1 SEE ALSO

L<Unblock::HTTP3>, L<Unblock::HTTP3::Transaction>,
L<Uniform::HTTP::Request>, L<Uniform::HTTP::Response>, L<Net::QUIC>,
L<Uniform::HTTP>

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

This software is available under the MIT License.

=cut
