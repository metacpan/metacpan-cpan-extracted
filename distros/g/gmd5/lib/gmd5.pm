package gmd5;

use strict;
use warnings;
use feature 'state';
use Exporter qw(import);

our $VERSION = '2.4.1'; # Incremented to reflect fixes

our @EXPORT_OK = qw(md5 md5_hex);

sub new {
    my ($class) = @_;
    state @h_init = (0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476);
    my $self = bless {
        h => [@h_init],
        buffer => '',
        length => 0,
        pos => 0,
        w => [(0) x 16],
        final_digest => undef,
    }, $class;
    return $self;
}

sub reset {
    my ($self) = @_;
    state @h_init = (0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476);
    $self->{h} = [@h_init];
    $self->{buffer} = '';
    $self->{length} = 0;
    $self->{pos} = 0;
    $self->{final_digest} = undef;
    return $self;
}

sub add {
    my ($self, $data) = @_;
    _validate_input($data);
    return $self unless length($data);
    $self->{final_digest} = undef;
    _append_data($self, $data);
    _process_buffer($self) while _has_enough_data($self);
    return $self;
}

sub digest {
    my ($self) = @_;
    if (defined $self->{final_digest}) {
        return $self->{final_digest};
    }
    my $digest = _compute_digest($self);
    $self->{final_digest} = $digest;
    state @h_init = (0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476);
    $self->{h} = [@h_init];
    return $digest;
}

sub hexdigest {
    my ($self) = @_;
    my $digest = $self->digest;
    return _format_hex($digest);
}

sub md5 {
    my ($data) = @_;
    _validate_input($data);
    my $md5 = gmd5->new;
    $md5->add($data);
    return $md5->digest;
}

sub md5_hex {
    my ($data) = @_;
    _validate_input($data);
    my $md5 = gmd5->new;
    $md5->add($data);
    return $md5->hexdigest;
}

sub _validate_input {
    my ($data) = @_;
    die "Input must be defined" unless defined $data;
}

sub _append_data {
    my ($self, $data) = @_;
    $self->{buffer} .= $data;
    $self->{length} += length($data);
}

sub _has_enough_data {
    my ($self) = @_;
    my $buffer_length = length($self->{buffer});
    my $position = $self->{pos};
    return $buffer_length - $position >= 64;
}

sub _process_buffer {
    my ($self) = @_;
    my $buf_ref = \$self->{buffer};
    my $pos = $self->{pos};
    my $len = length($$buf_ref);
    my $block_num = 0;

    while (_can_process_block($pos, $len)) {
        my $w = [(0) x 16];
        my $block = _extract_block($buf_ref, $pos);
        _unpack_words($w, $block, $block_num);
        _process_block($self, $self->{h}, $w);
        $pos = _increment_position($pos);
        $block_num++;
    }

    _update_buffer($self, $buf_ref, $pos);
}

sub _can_process_block {
    my ($pos, $len) = @_;
    return $pos + 64 <= $len;
}

sub _extract_block {
    my ($buf_ref, $pos) = @_;
    return substr($$buf_ref, $pos, 64);
}

sub _unpack_words {
    my ($w, $block, $block_num) = @_;
    @$w = unpack("V16", $block);
}

sub _increment_position {
    my ($pos) = @_;
    return $pos + 64;
}

sub _update_buffer {
    my ($self, $buf_ref, $pos) = @_;
    $$buf_ref = $pos ? substr($$buf_ref, $pos) : '';
    $self->{pos} = 0;
}

sub _compute_digest {
    my ($self) = @_;
    my $len = _compute_bit_length($self);
    my $original_buffer = $self->{buffer};
    _append_padding($self);
    my $pad_len = length($self->{buffer}) - length($original_buffer) - 1;
    _append_length($self, $len);
    _validate_buffer_length($self);
    _process_buffer($self);
    my $digest = _construct_digest($self);
    $self->{final_digest} = $digest;
    $self->{buffer} = $original_buffer;
    return $digest;
}

sub _compute_bit_length {
    my ($self) = @_;
    my $len = $self->{length} * 8;
    die "Invalid length" if $len < 0;
    return $len;
}

sub _append_padding {
    my ($self) = @_;
    _append_one_bit($self);
    _append_zero_padding($self);
}

sub _append_one_bit {
    my ($self) = @_;
    $self->{buffer} .= "\x80";
}

sub _append_zero_padding {
    my ($self) = @_;
    my $current_len = length($self->{buffer});
    my $pad_len = (56 - $current_len % 64) % 64;
    $self->{buffer} .= "\x00" x $pad_len;
}

sub _append_length {
    my ($self, $len) = @_;
    my $length_bytes = _pack_length($len);
    $self->{buffer} .= $length_bytes;
}

sub _pack_length {
    my ($len) = @_;
    return pack("V2", $len & 0xffffffff, $len >> 32);
}

sub _validate_buffer_length {
    my ($self) = @_;
    die "Invalid buffer length" unless length($self->{buffer}) % 64 == 0;
}

sub _construct_digest {
    my ($self) = @_;
    my $h = $self->{h};
    return pack("V4", @$h);
}

sub _format_hex {
    my ($digest) = @_;
    return unpack("H*", $digest);
}

sub _rotate_left {
    my ($value, $shift) = @_;
    my $left_shift = ($value << $shift) & 0xffffffff;
    my $right_shift = ($value >> (32 - $shift)) & 0xffffffff;
    return ($left_shift | $right_shift) & 0xffffffff;
}

sub _process_block {
    my ($self, $h, $w) = @_;
    state @t = map { $_ & 0xffffffff } (
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
        0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
        0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
        0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
        0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
    );
    state @s = (
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
    );
    state @g = (
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
        1, 6, 11, 0, 5, 10, 15, 4, 9, 14, 3, 8, 13, 2, 7, 12,
        5, 8, 11, 14, 1, 4, 7, 10, 13, 0, 3, 6, 9, 12, 15, 2,
        0, 7, 14, 5, 12, 3, 10, 1, 8, 15, 6, 13, 4, 11, 2, 9
    );

    my $start_time = time() if $ENV{GMD5_PROFILE};
    my @initial_h = @$h;
    my ($a, $b, $c, $d) = @initial_h;
    for my $i (0 .. 63) {
        ($a, $b, $c, $d) = _compute_round($self, $i, $a, $b, $c, $d, \@t, \@s, $w, \@g);
    }
    _update_hash_values($h, $a, $b, $c, $d, \@initial_h);
}

sub _compute_round {
    my ($self, $i, $a, $b, $c, $d, $t, $s, $w, $g) = @_;
    $a &= 0xffffffff;
    $b &= 0xffffffff;
    $c &= 0xffffffff;
    $d &= 0xffffffff;
    my $f;
    if ($i < 16) {
        $f = _compute_f($b, $c, $d);
    } elsif ($i < 32) {
        $f = _compute_g($b, $c, $d);
    } elsif ($i < 48) {
        $f = _compute_h($b, $c, $d);
    } else {
        $f = _compute_i($b, $c, $d);
    }
    $f &= 0xffffffff;
    my $word = $w->[$g->[$i]] & 0xffffffff;
    my $table_value = $t->[$i] & 0xffffffff;
    my $sum = ($a + $f) & 0xffffffff;
    $sum = ($sum + $word) & 0xffffffff;
    $sum = ($sum + $table_value) & 0xffffffff;
    my $temp = _rotate_left($sum, $s->[$i]) & 0xffffffff;
    $temp = ($b + $temp) & 0xffffffff;
    return ($d, $temp, $b, $c);
}

sub _compute_f {
    my ($b, $c, $d) = @_;
    $b &= 0xffffffff;
    $c &= 0xffffffff;
    $d &= 0xffffffff;
    my $f = (($b & $c) | (~$b & $d)) & 0xffffffff;
    return $f;
}

sub _compute_g {
    my ($b, $c, $d) = @_;
    $b &= 0xffffffff;
    $c &= 0xffffffff;
    $d &= 0xffffffff;
    my $bd = $b & $d;
    my $not_d = (~$d) & 0xffffffff;
    my $c_not_d = $c & $not_d;
    my $f = ($bd | $c_not_d) & 0xffffffff;
    return $f;
}

sub _compute_h {
    my ($b, $c, $d) = @_;
    $b &= 0xffffffff;
    $c &= 0xffffffff;
    $d &= 0xffffffff;
    my $bc = $b ^ $c;
    my $f = ($bc ^ $d) & 0xffffffff;
    return $f;
}

sub _compute_i {
    my ($b, $c, $d) = @_;
    $b &= 0xffffffff;
    $c &= 0xffffffff;
    $d &= 0xffffffff;
    my $not_d = (~$d) & 0xffffffff;
    my $b_not_d = $b | $not_d;
    my $f = ($c ^ $b_not_d) & 0xffffffff;
    return $f;
}

sub _update_hash_values {
    my ($h, $a, $b, $c, $d, $initial_h) = @_;
    $h->[0] = ($initial_h->[0] + $a) & 0xffffffff;
    $h->[1] = ($initial_h->[1] + $b) & 0xffffffff;
    $h->[2] = ($initial_h->[2] + $c) & 0xffffffff;
    $h->[3] = ($initial_h->[3] + $d) & 0xffffffff;
}

1;