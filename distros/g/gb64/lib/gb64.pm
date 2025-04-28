package gb64;

use strict;
use warnings;
use Exporter qw(import);

our $VERSION = '1.0.0';
our @EXPORT_OK = qw(enc_b64 dec_b64);

sub new {
    my ($class) = @_;
    my $self = bless { buffer => '' }, $class;
    return $self;
}

sub add {
    my ($self, $data) = @_;
    die "Input must be defined" unless defined $data;
    $self->{buffer} .= $data;
    return $self;
}

sub encode {
    my ($self) = @_;
    my $data = $self->{buffer};
    $self->{buffer} = '';
    return enc_b64($data);
}

sub decode {
    my ($self) = @_;
    my $data = $self->{buffer};
    $self->{buffer} = '';
    return dec_b64($data);
}

# Lookup-tabel voor encoderen (ASCII-waarden voor A-Z, a-z, 0-9, +, /)
my @b64_table = (65..90, 97..122, 48..57, 43, 47);

# Lookup-tabel voor decoderen (array in plaats van hash)
my @b64_decode_array = (undef) x 128;
@b64_decode_array[65..90] = 0..25;   # A-Z
@b64_decode_array[97..122] = 26..51;  # a-z
@b64_decode_array[48..57] = 52..61;   # 0-9
$b64_decode_array[43] = 62;           # +
$b64_decode_array[47] = 63;           # /

sub enc_b64 {
    my ($data) = @_;
    my $len = length($data) || 0;
    my $pos = 0;
    my @bytes;

    # Verwerk groepen van 3 bytes
    while ($pos + 2 < $len) {
        my ($b1, $b2, $b3) = unpack("C3", substr($data, $pos, 3));
        push @bytes,
            ($b1 >> 2) & 0x3F,
            (($b1 & 0x3) << 4) | (($b2 >> 4) & 0xF),
            (($b2 & 0xF) << 2) | (($b3 >> 6) & 0x3),
            $b3 & 0x3F;
        $pos += 3;
    }

    # Behandel restanten
    if ($pos < $len) {
        my $rest = substr($data, $pos);
        if (length($rest) == 1) {
            my $b1 = ord($rest);
            push @bytes,
                ($b1 >> 2) & 0x3F,
                ($b1 & 0x3) << 4;
            return pack("C*", map { $b64_table[$_] } @bytes) . "==";
        }
        elsif (length($rest) == 2) {
            my ($b1, $b2) = unpack("C2", $rest);
            push @bytes,
                ($b1 >> 2) & 0x3F,
                (($b1 & 0x3) << 4) | (($b2 >> 4) & 0xF),
                ($b2 & 0xF) << 2;
            return pack("C*", map { $b64_table[$_] } @bytes) . "=";
        }
    }

    return pack("C*", map { $b64_table[$_] } @bytes);
}

sub dec_b64 {
    my ($data) = @_;
    my $len = length($data) || 0;
    die "Invalid Base64 length" unless $len == 0 || $len % 4 == 0;
    my $pos = 0;
    my @bytes;

    # Verwerk groepen van 4 karakters
    while ($pos + 3 < $len) {
        my ($c1, $c2, $c3, $c4) = unpack("C4", substr($data, $pos, 4));
        if ($c4 == ord("=")) {
            if ($c3 == ord("=")) {
                my $v1 = $b64_decode_array[$c1] // die "Invalid Base64 character at position $pos";
                my $v2 = $b64_decode_array[$c2] // die "Invalid Base64 character at position " . ($pos + 1);
                push @bytes, ($v1 << 2) | (($v2 >> 4) & 0x3);
            }
            else {
                my $v1 = $b64_decode_array[$c1] // die "Invalid Base64 character at position $pos";
                my $v2 = $b64_decode_array[$c2] // die "Invalid Base64 character at position " . ($pos + 1);
                my $v3 = $b64_decode_array[$c3] // die "Invalid Base64 character at position " . ($pos + 2);
                push @bytes,
                    ($v1 << 2) | (($v2 >> 4) & 0x3),
                    (($v2 & 0xF) << 4) | (($v3 >> 2) & 0xF);
            }
            last;
        }
        my $v1 = $b64_decode_array[$c1] // die "Invalid Base64 character at position $pos";
        my $v2 = $b64_decode_array[$c2] // die "Invalid Base64 character at position " . ($pos + 1);
        my $v3 = $b64_decode_array[$c3] // die "Invalid Base64 character at position " . ($pos + 2);
        my $v4 = $b64_decode_array[$c4] // die "Invalid Base64 character at position " . ($pos + 3);
        push @bytes,
            ($v1 << 2) | (($v2 >> 4) & 0x3),
            (($v2 & 0xF) << 4) | (($v3 >> 2) & 0xF),
            (($v3 & 0x3) << 6) | $v4;
        $pos += 4;
    }

    return pack("C*", @bytes);
}

1; # EOF gb64.pm (C) 2025 OnEhIppY, Domero