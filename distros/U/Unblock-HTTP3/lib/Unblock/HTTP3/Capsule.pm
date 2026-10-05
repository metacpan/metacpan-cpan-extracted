package Unblock::HTTP3::Capsule;

use strict;
use warnings;

use Carp qw(croak);

use Unblock::HTTP3 ();
use Unblock::HTTP3::_Bytes ();

our $VERSION = '0.03';

my $MAX_VARINT = '4611686018427387903';

sub _normalize_varint {
    my ($value, $name) = @_;

    $name ||= 'capsule integer';

    croak "$name must be a non-negative integer"
        if !defined($value)
            || ref($value)
            || "$value" !~ /\A[0-9]+\z/;

    my $text = "$value";
    $text =~ s/\A0+(?=[0-9])//;

    croak "$name exceeds the HTTP/3 varint maximum"
        if length($text) > length($MAX_VARINT)
            || (
                length($text) == length($MAX_VARINT)
                && $text gt $MAX_VARINT
            );

    return $text;
}

sub _encode_varint {
    my ($value) = @_;

    $value = _normalize_varint($value, 'capsule integer');
    my $number = 0 + $value;

    return pack('C', $number)
        if $number <= 63;
    return pack('n', $number | 0x4000)
        if $number <= 16_383;
    return pack('N', $number | 0x80000000)
        if $number <= 1_073_741_823;

    my $high = (($number >> 32) & 0x3fffffff) | 0xc0000000;
    my $low = $number & 0xffffffff;

    return pack('NN', $high, $low);
}

sub _decode_varint {
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

sub new {
    my ($class, %args) = @_;

    my $type = delete $args{type};
    my $value = exists($args{value}) ? delete($args{value}) : '';

    croak 'Capsule type is required'
        unless defined $type;
    croak 'unknown Capsule option: ' . join(', ', sort keys %args)
        if %args;

    $type = _normalize_varint($type, 'Capsule type');
    $value = Unblock::HTTP3::_Bytes::byte_string('Capsule value', $value);

    return bless {
        type  => $type,
        value => $value,
    }, $class;
}

sub type {
    my ($self, @args) = @_;
    croak 'type() does not accept arguments' if @args;
    return $self->{type};
}

sub value {
    my ($self, @args) = @_;
    croak 'value() does not accept arguments' if @args;
    return $self->{value};
}

sub length {
    my ($self, @args) = @_;
    croak 'length() does not accept arguments' if @args;
    return CORE::length($self->{value});
}

sub encode {
    my ($self, @args) = @_;
    croak 'encode() does not accept arguments' if @args;

    return _encode_varint($self->{type})
        . _encode_varint(CORE::length($self->{value}))
        . $self->{value};
}

1;

__END__

=head1 NAME

Unblock::HTTP3::Capsule - one RFC 9297 Capsule

=head1 SYNOPSIS

    my $capsule = Unblock::HTTP3::Capsule->new(
        type  => 42,
        value => $bytes,
    );

    my $wire = $capsule->encode;

=head1 DESCRIPTION

A Capsule is a numeric type and an opaque byte value as defined by RFC 9297.

Unblock::HTTP3 does not assign application meaning to Capsule Types. Higher-level
protocols decide which types they use.

=head1 CONSTRUCTOR

=head2 new

    my $capsule = Unblock::HTTP3::Capsule->new(
        type  => $type,
        value => $bytes,
    );

Creates one Capsule.

=head1 METHODS

=head2 type

Returns the numeric Capsule Type.

=head2 value

Returns the opaque Capsule Value bytes.

=head2 length

Returns the Capsule Value length in bytes.

=head2 encode

Returns the complete wire encoding for an HTTP data stream.

=head1 SEE ALSO

L<Unblock::HTTP3::Capsule::Parser>,
L<Unblock::HTTP3::Capsule::Stream>,
L<Unblock::HTTP3::Transaction>

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

This software is available under the MIT License.

=cut
