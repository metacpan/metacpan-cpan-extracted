package Unblock::WebSocket::_Frame;

use strict;
use warnings;
use Carp qw(croak);
use Config ();

use Unblock::WebSocket::_Random ();

my %TYPE_TO_OPCODE = (
    continuation => 0x0,
    text         => 0x1,
    binary       => 0x2,
    close        => 0x8,
    ping         => 0x9,
    pong         => 0xA,
);

my %OPCODE_TO_TYPE = reverse %TYPE_TO_OPCODE;

sub opcode {
    my ($class, $type) = @_;
    return $TYPE_TO_OPCODE{$type};
}

sub type {
    my ($class, $opcode) = @_;
    return $OPCODE_TO_TYPE{$opcode};
}

sub _byte_string {
    my ($where, $value) = @_;
    croak "$where requires a defined scalar"
        if !defined($value) || ref($value);
    my $bytes = "$value";
    croak "$where requires a byte string"
        unless utf8::downgrade($bytes, 1);
    return $bytes;
}

sub mask {
    my ($class, $payload, $key, $offset) = @_;
    $payload = _byte_string('mask()', $payload);
    $key = _byte_string('mask()', $key);
    $offset ||= 0;
    croak 'mask(): key must contain exactly four bytes'
        unless length($key) == 4;

    my $out = $payload;
    for my $i (0 .. length($out) - 1) {
        substr($out, $i, 1) = chr(
            ord(substr($out, $i, 1))
            ^ ord(substr($key, ($offset + $i) & 3, 1))
        );
    }
    return $out;
}

sub encode {
    my ($class, %option) = @_;
    my $opcode = delete $option{opcode};
    my $payload = exists($option{payload}) ? delete($option{payload}) : '';
    my $fin = exists($option{fin}) ? delete($option{fin}) : 1;
    my $masked = delete($option{masked}) ? 1 : 0;
    my $mask_key = delete $option{mask_key};
    my $rsv1 = delete($option{rsv1}) ? 1 : 0;
    my $rsv2 = delete($option{rsv2}) ? 1 : 0;
    my $rsv3 = delete($option{rsv3}) ? 1 : 0;

    croak 'encode(): unknown option(s): ' . join(', ', sort keys %option)
        if %option;
    croak 'encode(): opcode must be an integer between 0 and 15'
        unless defined($opcode) && !ref($opcode)
            && $opcode =~ /\A[0-9]+\z/ && $opcode <= 15;
    croak 'encode(): fin must be zero or one' unless "$fin" =~ /\A[01]\z/;

    $payload = _byte_string('encode(): payload', $payload);
    my $length = length($payload);

    if ($opcode >= 8) {
        croak 'encode(): control frames must not be fragmented' unless $fin;
        croak 'encode(): control frame payload exceeds 125 bytes'
            if $length > 125;
    }

    my $first = ($fin ? 0x80 : 0)
        | ($rsv1 ? 0x40 : 0)
        | ($rsv2 ? 0x20 : 0)
        | ($rsv3 ? 0x10 : 0)
        | $opcode;
    my $mask_bit = $masked ? 0x80 : 0;
    my $header;

    if ($length < 126) {
        $header = pack('CC', $first, $mask_bit | $length);
    }
    elsif ($length <= 0xffff) {
        $header = pack('CCn', $first, $mask_bit | 126, $length);
    }
    else {
        my $high = int($length / 4_294_967_296);
        my $low = $length % 4_294_967_296;
        croak 'encode(): payload length exceeds RFC 6455 63-bit limit'
            if $high >= 0x80000000;
        $header = pack('CCNN', $first, $mask_bit | 127, $high, $low);
    }

    return $header . $payload unless $masked;

    $mask_key = Unblock::WebSocket::_Random->mask_key
        unless defined $mask_key;
    $mask_key = _byte_string('encode(): mask_key', $mask_key);
    croak 'encode(): mask_key must contain exactly four bytes'
        unless length($mask_key) == 4;

    return $header . $mask_key . $class->mask($payload, $mask_key);
}

sub new_parser {
    my ($class, %option) = @_;
    my $expect_masked = delete $option{expect_masked};
    my $max_frame_size = exists($option{max_frame_size})
        ? delete($option{max_frame_size}) : 16 * 1024 * 1024;
    my $allow_rsv1 = delete($option{allow_rsv1}) ? 1 : 0;
    croak 'new_parser(): expect_masked must be zero or one'
        unless defined($expect_masked) && !ref($expect_masked)
            && "$expect_masked" =~ /\A[01]\z/;
    croak 'new_parser(): max_frame_size must be a positive integer'
        unless defined($max_frame_size) && !ref($max_frame_size)
            && $max_frame_size =~ /\A[0-9]+\z/ && $max_frame_size > 0;
    croak 'new_parser(): unknown option(s): ' . join(', ', sort keys %option)
        if %option;

    return bless {
        expect_masked  => $expect_masked ? 1 : 0,
        max_frame_size => 0 + $max_frame_size,
        allow_rsv1     => $allow_rsv1,
        buffer         => '',
    }, 'Unblock::WebSocket::_Frame::Parser';
}

package Unblock::WebSocket::_Frame::Parser;

use strict;
use warnings;
use Carp qw(croak);

sub buffered_bytes { length($_[0]{buffer}) }

sub input {
    my ($self, $bytes) = @_;
    croak 'input(): bytes must be a scalar' if ref($bytes);
    $bytes = '' unless defined $bytes;
    my $copy = "$bytes";
    croak 'input(): bytes must be a byte string'
        unless utf8::downgrade($copy, 1);
    $self->{buffer} .= $copy;
    return length($copy);
}

sub next_frame {
    my ($self) = @_;
    my $buffer = $self->{buffer};
    return unless length($buffer) >= 2;

    my ($first, $second) = unpack('CC', substr($buffer, 0, 2));
    my $fin = ($first & 0x80) ? 1 : 0;
    my $rsv1 = ($first & 0x40) ? 1 : 0;
    my $rsv2 = ($first & 0x20) ? 1 : 0;
    my $rsv3 = ($first & 0x10) ? 1 : 0;
    my $opcode = $first & 0x0f;
    my $masked = ($second & 0x80) ? 1 : 0;
    my $length7 = $second & 0x7f;

    croak 'WebSocket frame uses reserved RSV bits'
        if $rsv2 || $rsv3;
    croak 'WebSocket frame uses reserved RSV bits (RSV1 not negotiated)'
        if $rsv1 && !$self->{allow_rsv1};
    croak 'WebSocket frame has reserved opcode'
        unless exists $OPCODE_TO_TYPE{$opcode};
    croak 'WebSocket continuation frame must not set RSV1'
        if $rsv1 && $opcode == 0;
    croak 'WebSocket control frame must not set RSV1'
        if $rsv1 && $opcode >= 8;
    croak 'WebSocket peer used incorrect masking direction'
        if $masked != $self->{expect_masked};

    my $offset = 2;
    my $length;
    if ($length7 < 126) {
        $length = $length7;
    }
    elsif ($length7 == 126) {
        return unless length($buffer) >= $offset + 2;
        $length = unpack('n', substr($buffer, $offset, 2));
        $offset += 2;
        croak 'WebSocket frame uses non-minimal 16-bit length'
            if $length < 126;
    }
    else {
        return unless length($buffer) >= $offset + 8;
        my ($high, $low) = unpack('NN', substr($buffer, $offset, 8));
        croak 'WebSocket frame length has reserved high bit set'
            if $high & 0x80000000;
        croak 'WebSocket frame length is too large for this Perl build'
            if $high && ($Config::Config{uvsize} || 4) < 8;
        $length = $high * 4_294_967_296 + $low;
        $offset += 8;
        croak 'WebSocket frame uses non-minimal 64-bit length'
            if $length <= 0xffff;
    }

    if ($opcode >= 8) {
        croak 'WebSocket control frame is fragmented' unless $fin;
        croak 'WebSocket control frame payload exceeds 125 bytes'
            if $length > 125;
    }

    croak 'WebSocket frame exceeds configured limit'
        if $length > $self->{max_frame_size};

    my $mask_key;
    if ($masked) {
        return unless length($buffer) >= $offset + 4;
        $mask_key = substr($buffer, $offset, 4);
        $offset += 4;
    }

    return unless length($buffer) >= $offset + $length;
    my $payload = substr($buffer, $offset, $length);
    if ($masked) {
        $payload = Unblock::WebSocket::_Frame->mask($payload, $mask_key);
    }

    substr($self->{buffer}, 0, $offset + $length, '');

    return {
        fin     => $fin,
        rsv1    => $rsv1,
        rsv2    => $rsv2,
        rsv3    => $rsv3,
        opcode  => $opcode,
        type    => $OPCODE_TO_TYPE{$opcode},
        masked  => $masked,
        payload => $payload,
    };
}

1;
