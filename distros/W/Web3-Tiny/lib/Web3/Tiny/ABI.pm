package Web3::Tiny::ABI;

use strict;
use warnings;
use Exporter 'import';
use Math::BigInt;

use Web3::Tiny::Keccak256 qw(keccak256);

our $VERSION   = '0.01';
our @EXPORT_OK = qw(
    selector encode_call encode_types decode_result decode_types
);

=head1 NAME

Web3::Tiny::ABI - Solidity ABI encoding/decoding

=head1 DESCRIPTION

Supports the common scalar types (C<uintN>, C<intN>, C<address>, C<bool>,
C<bytesN>, dynamic C<bytes>/C<string>) plus C<T[]> and C<T[k]> arrays of
them. Does B<not> support tuples/structs or arrays-of-arrays -- if you
need those, this is intentionally the "tiny" subset.

Integers are accepted as plain Perl numbers, numeric strings, or
L<Math::BigInt> objects, and are returned from C<decode_result> as
Math::BigInt objects (uint256 routinely exceeds native int range).
C<address> values are accepted/returned as C<"0x...">-prefixed 40-hex-char
strings. C<bytesN>/C<bytes> values are accepted/returned as raw byte
strings unless given as a C<"0x...">-prefixed hex string, in which case
that convention is preserved on decode too... actually bytes/bytesN are
always *returned* as raw bytes; only C<address> round-trips as hex text.

=cut

# ------------------------------------------------------------------
# type introspection
# ------------------------------------------------------------------

sub _is_dynamic_type {
    my ($type) = @_;
    return 1 if $type eq 'bytes' || $type eq 'string';
    if ($type =~ /^(.+)\[(\d*)\]$/) {
        my ($elem, $size) = ($1, $2);
        return 1 if $size eq '';
        return _is_dynamic_type($elem);
    }
    return 0;
}

sub _static_size {
    my ($type) = @_;
    if ($type =~ /^(.+)\[(\d+)\]$/) {
        return _static_size($1) * $2;
    }
    return 32;
}

# ------------------------------------------------------------------
# scalar codecs
# ------------------------------------------------------------------

sub _to_bigint {
    my ($n) = @_;
    return $n->copy if ref($n) && $n->isa('Math::BigInt');
    return Math::BigInt->new("$n");
}

sub _encode_uint_word {
    my ($n) = @_;
    my $bi = _to_bigint($n);
    die "Web3::Tiny::ABI: negative value not valid for unsigned type\n" if $bi->is_neg;
    my $hex = $bi->as_hex;
    $hex =~ s/^0x//;
    die "Web3::Tiny::ABI: integer too large for uint256\n" if length($hex) > 64;
    $hex = ('0' x (64 - length($hex))) . $hex;
    return pack('H*', $hex);
}

sub _decode_uint_word {
    my ($word) = @_;
    return Math::BigInt->from_hex('0x' . unpack('H*', $word));
}

sub _encode_int_word {
    my ($n) = @_;
    my $bi = _to_bigint($n);
    if ($bi->is_neg) {
        my $two_256 = Math::BigInt->new(2)->bpow(256);
        $bi = $two_256->badd($bi);
    }
    return _encode_uint_word($bi);
}

sub _decode_int_word {
    my ($word) = @_;
    my $v = _decode_uint_word($word);
    my $two_255 = Math::BigInt->new(2)->bpow(255);
    if ($v->bcmp($two_255) >= 0) {
        my $two_256 = Math::BigInt->new(2)->bpow(256);
        $v = $v->bsub($two_256);
    }
    return $v;
}

sub _hexish_to_bytes {
    my ($val) = @_;
    return '' unless defined $val;
    if ($val =~ /^0x([0-9a-fA-F]*)$/) {
        my $hex = $1;
        $hex = '0' . $hex if length($hex) % 2;
        return pack('H*', $hex);
    }
    return $val;
}

sub _encode_address {
    my ($addr) = @_;
    my $bytes = _hexish_to_bytes($addr);
    die "Web3::Tiny::ABI: address must be 20 bytes\n" unless length($bytes) == 20;
    return ("\x00" x 12) . $bytes;
}

sub _decode_address {
    my ($word) = @_;
    return '0x' . unpack('H*', substr($word, 12, 20));
}

sub _encode_bytesN {
    my ($val, $n) = @_;
    my $bytes = _hexish_to_bytes($val);
    die "Web3::Tiny::ABI: bytes$n value must be exactly $n bytes\n" unless length($bytes) == $n;
    return $bytes . ("\x00" x (32 - $n));
}

sub _encode_bytes_dynamic {
    my ($bytes) = @_;
    my $len = length($bytes);
    my $pad = (32 - ($len % 32)) % 32;
    return _encode_uint_word($len) . $bytes . ("\x00" x $pad);
}

# ------------------------------------------------------------------
# generic tuple (and by extension: array) encode/decode
#
# Offsets for dynamic values are always relative to the start of the
# *current* tuple's own data window -- whether that's the top-level
# call arguments, or an array's element region right after its length
# word. This keeps encode/decode of nested dynamic arrays consistent.
# ------------------------------------------------------------------

sub _slot_sizes {
    my ($types) = @_;
    return [map { _is_dynamic_type($_) ? 32 : _static_size($_) } @$types];
}

sub encode_types {
    my ($types, $values) = @_;
    die "Web3::Tiny::ABI: types/values count mismatch\n" unless @$types == @$values;

    my $slot_sizes = _slot_sizes($types);
    my $head_size  = 0;
    $head_size += $_ for @$slot_sizes;

    my @head_parts;
    my @tail_parts;
    for my $i (0 .. $#$types) {
        my $type = $types->[$i];
        my $val  = $values->[$i];
        if (_is_dynamic_type($type)) {
            push @head_parts, { dyn => 1, idx => scalar(@tail_parts) };
            push @tail_parts, _encode_value($type, $val);
        }
        else {
            push @head_parts, { raw => _encode_value($type, $val) };
        }
    }

    my @tail_offsets;
    my $running = 0;
    for my $tp (@tail_parts) {
        push @tail_offsets, $running;
        $running += length($tp);
    }

    my $head_str = '';
    for my $hp (@head_parts) {
        if ($hp->{raw}) {
            $head_str .= $hp->{raw};
        }
        else {
            $head_str .= _encode_uint_word($head_size + $tail_offsets[$hp->{idx}]);
        }
    }

    return $head_str . join('', @tail_parts);
}

sub _encode_value {
    my ($type, $value) = @_;

    if ($type =~ /^(.+)\[(\d*)\]$/) {
        my ($elem, $size) = ($1, $2);
        my @vals = ref($value) eq 'ARRAY' ? @$value : ($value);
        if ($size eq '') {
            return _encode_uint_word(scalar @vals)
                 . encode_types([($elem) x scalar(@vals)], \@vals);
        }
        die "Web3::Tiny::ABI: expected $size elements for $type, got " . scalar(@vals) . "\n"
            unless scalar(@vals) == $size;
        return encode_types([($elem) x $size], \@vals);
    }

    return _encode_bytes_dynamic($value)                    if $type eq 'bytes';
    return _encode_bytes_dynamic(_utf8_bytes($value))        if $type eq 'string';
    return _encode_address($value)                           if $type eq 'address';
    return _encode_uint_word($value ? 1 : 0)                 if $type eq 'bool';
    return _encode_uint_word($value)                         if $type =~ /^uint\d*$/;
    return _encode_int_word($value)                          if $type =~ /^int\d*$/;
    return _encode_bytesN($value, $1)                        if $type =~ /^bytes(\d+)$/;
    die "Web3::Tiny::ABI: unsupported type '$type'\n";
}

sub _utf8_bytes {
    my ($str) = @_;
    return '' unless defined $str;
    return $str unless utf8::is_utf8($str);
    require Encode;
    return Encode::encode('UTF-8', $str);
}

sub decode_types {
    my ($types, $data) = @_;
    my $slot_sizes = _slot_sizes($types);
    my @slot_offsets;
    my $running = 0;
    for my $sz (@$slot_sizes) {
        push @slot_offsets, $running;
        $running += $sz;
    }

    my @out;
    for my $i (0 .. $#$types) {
        push @out, _decode_value($types->[$i], $data, $slot_offsets[$i]);
    }
    return @out;
}

sub _decode_value {
    my ($type, $data, $head_offset) = @_;

    if (_is_dynamic_type($type)) {
        my $rel = _decode_uint_word(substr($data, $head_offset, 32))->numify;
        return _decode_dynamic($type, substr($data, $rel));
    }

    my $word = substr($data, $head_offset, 32);
    return _decode_static($type, $word, $data, $head_offset);
}

# static value living inline in the head (word already sliced out, but
# fixed-size arrays of static elements need the wider window too)
sub _decode_static {
    my ($type, $word, $data, $head_offset) = @_;

    if ($type =~ /^(.+)\[(\d+)\]$/) {
        my ($elem, $size) = ($1, $2);
        my $window = substr($data, $head_offset, 32 * $size);
        return [decode_types([($elem) x $size], $window)];
    }

    return $word eq "\x00" x 32 ? 0 : 1                     if $type eq 'bool';
    return _decode_address($word)                            if $type eq 'address';
    return _decode_uint_word($word)                           if $type =~ /^uint\d*$/;
    return _decode_int_word($word)                            if $type =~ /^int\d*$/;
    return substr($word, 0, $1)                               if $type =~ /^bytes(\d+)$/;
    die "Web3::Tiny::ABI: unsupported type '$type'\n";
}

# dynamic value: $data here is already windowed to start at the value's
# own offset (i.e. $data =~ /^length . content/ for bytes/string/array)
sub _decode_dynamic {
    my ($type, $data) = @_;

    if ($type =~ /^(.+)\[\]$/) {
        my $elem  = $1;
        my $count = _decode_uint_word(substr($data, 0, 32))->numify;
        return [decode_types([($elem) x $count], substr($data, 32))];
    }

    my $len = _decode_uint_word(substr($data, 0, 32))->numify;
    return substr($data, 32, $len);
}

# ------------------------------------------------------------------
# function-call level helpers
# ------------------------------------------------------------------

sub _parse_signature {
    my ($sig) = @_;
    die "Web3::Tiny::ABI: bad signature '$sig'\n"
        unless $sig =~ /^\s*(\w+)\s*\(\s*(.*?)\s*\)\s*$/;
    my ($name, $arglist) = ($1, $2);
    my @types = length($arglist) ? split(/\s*,\s*/, $arglist) : ();
    return ($name, \@types);
}

# selector($sig) -> 4 raw bytes
sub selector {
    my ($sig) = @_;
    return substr(keccak256($sig), 0, 4);
}

# encode_call($sig, @args) -> raw call data (selector . encoded args)
sub encode_call {
    my ($sig, @args) = @_;
    my (undef, $types) = _parse_signature($sig);
    die "Web3::Tiny::ABI: '$sig' expects " . scalar(@$types) . " args, got " . scalar(@args) . "\n"
        unless scalar(@$types) == scalar(@args);
    return selector($sig) . encode_types($types, \@args);
}

# decode_result(\@types, $raw_bytes) -> list of decoded values
sub decode_result {
    my ($types, $data) = @_;
    return decode_types($types, $data);
}

1;
