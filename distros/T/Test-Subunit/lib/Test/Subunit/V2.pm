# Perl module for parsing and generating the Subunit v2 binary protocol
# Copyright (C) 2026 Jelmer Vernooij <jelmer@samba.org>
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

package Test::Subunit::V2;

use strict;
use warnings;
use Carp;
use String::CRC32 qw(crc32);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    SIGNATURE
    FLAG_TESTID FLAG_ROUTE FLAG_TIMESTAMP FLAG_RUNNABLE
    FLAG_TAGS FLAG_FILECONTENT FLAG_MIME FLAG_EOF
    STATUS_UNDEFINED STATUS_EXISTS STATUS_INPROGRESS STATUS_SUCCESS
    STATUS_UXSUCCESS STATUS_SKIP STATUS_FAIL STATUS_XFAIL
    pack_packet write_packet parse_stream read_packet
    encode_varint decode_varint
);

use constant SIGNATURE        => 0xB3;
use constant VERSION2         => 0x2000;

use constant FLAG_TESTID      => 0x0800;
use constant FLAG_ROUTE       => 0x0400;
use constant FLAG_TIMESTAMP   => 0x0200;
use constant FLAG_RUNNABLE    => 0x0100;
use constant FLAG_TAGS        => 0x0080;
use constant FLAG_FILECONTENT => 0x0040;
use constant FLAG_MIME        => 0x0020;
use constant FLAG_EOF         => 0x0010;
use constant STATUS_MASK      => 0x0007;

use constant STATUS_UNDEFINED  => 0;
use constant STATUS_EXISTS     => 1;
use constant STATUS_INPROGRESS => 2;
use constant STATUS_SUCCESS    => 3;
use constant STATUS_UXSUCCESS  => 4;
use constant STATUS_SKIP       => 5;
use constant STATUS_FAIL       => 6;
use constant STATUS_XFAIL      => 7;

our %STATUS_NAME = (
    STATUS_UNDEFINED()  => undef,
    STATUS_EXISTS()     => 'exists',
    STATUS_INPROGRESS() => 'inprogress',
    STATUS_SUCCESS()    => 'success',
    STATUS_UXSUCCESS()  => 'uxsuccess',
    STATUS_SKIP()       => 'skip',
    STATUS_FAIL()       => 'fail',
    STATUS_XFAIL()      => 'xfail',
);

our %NAME_STATUS = (
    'exists'     => STATUS_EXISTS,
    'inprogress' => STATUS_INPROGRESS,
    'success'    => STATUS_SUCCESS,
    'successful' => STATUS_SUCCESS,
    'uxsuccess'  => STATUS_UXSUCCESS,
    'skip'       => STATUS_SKIP,
    'fail'       => STATUS_FAIL,
    'failure'    => STATUS_FAIL,
    'error'      => STATUS_FAIL,
    'xfail'      => STATUS_XFAIL,
    'knownfail'  => STATUS_XFAIL,
);

# Encode a non-negative integer using subunit v2's variable-length encoding.
# The top two bits of the first byte indicate total octet count (1..4); the
# remaining 6/14/22/30 bits hold the value in network byte order. Max value
# is 2**30 - 1 (1073741823).
sub encode_varint {
    my ($n) = @_;
    croak "encode_varint: negative value $n" if $n < 0;
    if ($n <= 0x3F) {
        return pack('C', $n);
    } elsif ($n <= 0x3FFF) {
        return pack('n', $n | 0x4000);
    } elsif ($n <= 0x3FFFFF) {
        return pack('C', 0x80 | (($n >> 16) & 0x3F))
             . pack('n', $n & 0xFFFF);
    } elsif ($n <= 0x3FFFFFFF) {
        return pack('N', $n | 0xC0000000);
    } else {
        croak "encode_varint: value $n exceeds 2**30 - 1";
    }
}

# Decode a varint from $$buf_ref starting at $$pos_ref; advances $$pos_ref.
# Returns the decoded integer, or dies if the buffer is too short.
sub decode_varint {
    my ($buf_ref, $pos_ref) = @_;
    my $len = length($$buf_ref);
    croak "decode_varint: truncated" if $$pos_ref >= $len;
    my $first = unpack('C', substr($$buf_ref, $$pos_ref, 1));
    my $octets = (($first & 0xC0) >> 6) + 1;
    croak "decode_varint: truncated (need $octets bytes)"
        if $$pos_ref + $octets > $len;
    my $value = $first & 0x3F;
    for my $i (1 .. $octets - 1) {
        $value = ($value << 8)
               | unpack('C', substr($$buf_ref, $$pos_ref + $i, 1));
    }
    $$pos_ref += $octets;
    return $value;
}

# Build a v2 packet body (everything after the 3-byte length field) given
# the flags and already-encoded optional sections. Used internally.
sub _pack_optionals {
    my (%opts) = @_;
    my $flags = 0;
    my $body  = '';

    if (defined $opts{timestamp}) {
        $flags |= FLAG_TIMESTAMP;
        my ($sec, $nsec) = @{$opts{timestamp}};
        $body .= pack('N', $sec) . encode_varint($nsec // 0);
    }
    if (defined $opts{testid}) {
        $flags |= FLAG_TESTID;
        my $octets = _utf8_octets($opts{testid});
        $body .= encode_varint(length $octets) . $octets;
    }
    if (defined $opts{tags}) {
        $flags |= FLAG_TAGS;
        my @tags = @{$opts{tags}};
        my $tag_body = encode_varint(scalar @tags);
        for my $t (@tags) {
            my $octets = _utf8_octets($t);
            $tag_body .= encode_varint(length $octets) . $octets;
        }
        $body .= $tag_body;
    }
    if (defined $opts{mime}) {
        $flags |= FLAG_MIME;
        my $octets = _utf8_octets($opts{mime});
        $body .= encode_varint(length $octets) . $octets;
    }
    if (defined $opts{file_name} || defined $opts{file_content}) {
        $flags |= FLAG_FILECONTENT;
        my $name = _utf8_octets(defined $opts{file_name} ? $opts{file_name} : '');
        my $content = defined $opts{file_content} ? $opts{file_content} : '';
        $body .= encode_varint(length $name) . $name
               . encode_varint(length $content) . $content;
    }
    if (defined $opts{route_code}) {
        $flags |= FLAG_ROUTE;
        my $octets = _utf8_octets($opts{route_code});
        $body .= encode_varint(length $octets) . $octets;
    }

    return ($flags, $body);
}

sub _utf8_octets {
    my ($s) = @_;
    utf8::encode($s) if utf8::is_utf8($s);
    croak "embedded NUL in UTF-8 string" if index($s, "\0") >= 0;
    return $s;
}

# Build a complete subunit v2 packet. Arguments are passed as a hash:
#   status      => one of STATUS_*  (required, 0..7)
#   runnable    => bool (default true)
#   eof         => bool
#   testid      => scalar (UTF-8 string)
#   tags        => arrayref of UTF-8 strings
#   timestamp   => [seconds, nanoseconds]
#   mime        => scalar
#   file_name   => scalar       (presence of either sets FLAG_FILECONTENT)
#   file_content=> scalar (bytes)
#   route_code  => scalar
# Returns the packet as a byte string.
sub pack_packet {
    my (%opts) = @_;
    my $status = defined $opts{status} ? $opts{status} : STATUS_UNDEFINED;
    croak "status out of range" if $status < 0 || $status > 7;

    my ($feature_flags, $optionals) = _pack_optionals(%opts);
    my $flags = VERSION2 | $feature_flags | ($status & STATUS_MASK);
    $flags |= FLAG_RUNNABLE if !exists $opts{runnable} || $opts{runnable};
    $flags |= FLAG_EOF      if $opts{eof};

    # Length field is itself variable-length. Compute the smallest encoding
    # that accommodates the final length (including its own bytes and the
    # trailing 4-byte CRC).
    my $fixed = 1 + 2 + length($optionals) + 4;  # sig + flags + body + crc
    my $length_size;
    for my $size (1, 2, 3, 4) {
        my $total = $fixed + $size;
        my $max = (1 << (6 + 8 * ($size - 1))) - 1;
        if ($total <= $max) { $length_size = $size; last; }
    }
    croak "packet too large" unless defined $length_size;
    my $total = $fixed + $length_size;
    croak "packet exceeds 4MiB limit" if $total > 4194303;

    my $length_bytes = _encode_varint_fixed($total, $length_size);

    my $prefix = pack('C', SIGNATURE) . pack('n', $flags) . $length_bytes . $optionals;
    my $crc = crc32($prefix);
    return $prefix . pack('N', $crc);
}

# Encode a value as a varint of an exact byte width (1..4). Used for the
# packet length field, which needs a predictable size for self-reference.
sub _encode_varint_fixed {
    my ($n, $size) = @_;
    my $max = (1 << (6 + 8 * ($size - 1))) - 1;
    croak "value $n doesn't fit in $size-byte varint" if $n > $max;
    my $prefix = ($size - 1) << 6;
    if ($size == 1) {
        return pack('C', $prefix | ($n & 0x3F));
    } elsif ($size == 2) {
        return pack('n', ($prefix << 8) | ($n & 0x3FFF));
    } elsif ($size == 3) {
        return pack('C', $prefix | (($n >> 16) & 0x3F))
             . pack('n', $n & 0xFFFF);
    } else {
        return pack('N', ($prefix << 24) | ($n & 0x3FFFFFFF));
    }
}

# Convenience: write a packet to a filehandle (defaults to STDOUT).
sub write_packet {
    my ($fh, %opts) = @_;
    $fh = \*STDOUT unless defined $fh;
    my $pkt = pack_packet(%opts);
    binmode $fh;
    print $fh $pkt or croak "write failed: $!";
}

# Parse a single packet from a byte buffer starting at $pos. Returns
# (\%packet, $new_pos) on success, or (undef, $pos) if more data is needed
# to decode a full packet starting at $pos. Dies on malformed packets.
sub read_packet {
    my ($buf_ref, $pos) = @_;
    my $len = length($$buf_ref);
    return (undef, $pos) if $pos + 7 > $len;  # sig + flags + min len + crc

    my $sig = unpack('C', substr($$buf_ref, $pos, 1));
    croak sprintf("expected 0xB3 signature at offset %d, got 0x%02x", $pos, $sig)
        if $sig != SIGNATURE;

    my $flags = unpack('n', substr($$buf_ref, $pos + 1, 2));
    my $version = ($flags >> 12) & 0xF;
    croak sprintf("unsupported v2 version 0x%x", $version) if $version != 0x2;

    my $length_pos = $pos + 3;
    my $save = $length_pos;
    my $packet_len;
    eval { $packet_len = decode_varint($buf_ref, \$save); 1 }
        or return (undef, $pos);
    return (undef, $pos) if $pos + $packet_len > $len;

    my $end = $pos + $packet_len;
    my $crc_got = unpack('N', substr($$buf_ref, $end - 4, 4));
    my $crc_exp = crc32(substr($$buf_ref, $pos, $packet_len - 4));
    croak sprintf("CRC mismatch: got 0x%08x, expected 0x%08x", $crc_got, $crc_exp)
        if $crc_got != $crc_exp;

    my %p = (
        flags    => $flags,
        status   => $flags & STATUS_MASK,
        runnable => ($flags & FLAG_RUNNABLE) ? 1 : 0,
        eof      => ($flags & FLAG_EOF) ? 1 : 0,
    );
    my $cur = $save;
    my $body_end = $end - 4;

    if ($flags & FLAG_TIMESTAMP) {
        croak "truncated timestamp" if $cur + 4 > $body_end;
        my $sec = unpack('N', substr($$buf_ref, $cur, 4));
        $cur += 4;
        my $nsec = decode_varint($buf_ref, \$cur);
        $p{timestamp} = [$sec, $nsec];
    }
    if ($flags & FLAG_TESTID) {
        $p{testid} = _read_utf8_string($buf_ref, \$cur, $body_end);
    }
    if ($flags & FLAG_TAGS) {
        my $count = decode_varint($buf_ref, \$cur);
        my @tags;
        push @tags, _read_utf8_string($buf_ref, \$cur, $body_end) for 1 .. $count;
        $p{tags} = \@tags;
    }
    if ($flags & FLAG_MIME) {
        $p{mime} = _read_utf8_string($buf_ref, \$cur, $body_end);
    }
    if ($flags & FLAG_FILECONTENT) {
        $p{file_name}    = _read_utf8_string($buf_ref, \$cur, $body_end);
        $p{file_content} = _read_bytes($buf_ref, \$cur, $body_end);
    }
    if ($flags & FLAG_ROUTE) {
        $p{route_code} = _read_utf8_string($buf_ref, \$cur, $body_end);
    }

    croak "packet body has $body_end-$cur trailing bytes" if $cur != $body_end;
    return (\%p, $end);
}

sub _read_utf8_string {
    my ($buf_ref, $pos_ref, $end) = @_;
    my $len = decode_varint($buf_ref, $pos_ref);
    croak "truncated string" if $$pos_ref + $len > $end;
    my $s = substr($$buf_ref, $$pos_ref, $len);
    $$pos_ref += $len;
    croak "embedded NUL in UTF-8 string" if index($s, "\0") >= 0;
    utf8::decode($s);
    return $s;
}

sub _read_bytes {
    my ($buf_ref, $pos_ref, $end) = @_;
    my $len = decode_varint($buf_ref, $pos_ref);
    croak "truncated bytes" if $$pos_ref + $len > $end;
    my $s = substr($$buf_ref, $$pos_ref, $len);
    $$pos_ref += $len;
    return $s;
}

# Parse a stream of v2 packets from a filehandle, dispatching to $msg_ops
# with methods: packet(\%packet). Any bytes between packets (i.e. not
# starting with 0xB3) are reported via output_msg() one byte at a time,
# buffered per run of non-signature bytes until a newline or the next
# packet. Updates $statistics as tests complete.
sub parse_stream {
    my ($msg_ops, $statistics, $fh) = @_;
    binmode $fh;
    my $buf = '';
    my $pos = 0;

    while (1) {
        # Consume any packets available at $pos.
        if ($pos < length($buf) && ord(substr($buf, $pos, 1)) == SIGNATURE) {
            my ($pkt, $new_pos) = read_packet(\$buf, $pos);
            if (!defined $pkt) {
                # Need more bytes; fall through to read.
            } else {
                _dispatch_packet($msg_ops, $statistics, $pkt);
                $pos = $new_pos;
                next;
            }
        } elsif ($pos < length($buf)) {
            # Scan forward to next signature byte or end, emit as output.
            my $next_sig = index($buf, chr(SIGNATURE), $pos);
            my $stop = $next_sig < 0 ? length($buf) : $next_sig;
            if ($stop > $pos) {
                my $chunk = substr($buf, $pos, $stop - $pos);
                $msg_ops->output_msg($chunk) if $msg_ops->can('output_msg');
                $pos = $stop;
                next if $pos < length($buf);
            }
        }

        # Compact consumed bytes then read more.
        if ($pos > 0) {
            substr($buf, 0, $pos) = '';
            $pos = 0;
        }
        my $chunk;
        my $n = read($fh, $chunk, 65536);
        last if !defined $n || $n == 0;
        $buf .= $chunk;
    }

    if (length($buf) > $pos) {
        my $tail = substr($buf, $pos);
        if (ord(substr($tail, 0, 1)) == SIGNATURE) {
            croak "truncated packet at end of stream";
        }
        $msg_ops->output_msg($tail) if $msg_ops->can('output_msg');
    }
    return 0;
}

sub _dispatch_packet {
    my ($msg_ops, $statistics, $pkt) = @_;
    $msg_ops->packet($pkt) if $msg_ops->can('packet');

    my $status = $pkt->{status};
    my $name   = $pkt->{testid};

    if ($status == STATUS_INPROGRESS && defined $name) {
        $msg_ops->start_test($name) if $msg_ops->can('start_test');
        return;
    }

    my $result = $STATUS_NAME{$status};
    return unless defined $result && defined $name;

    my $unexpected = 0;
    if ($status == STATUS_SUCCESS) {
        $statistics->{TESTS_EXPECTED_OK}++;
    } elsif ($status == STATUS_XFAIL) {
        $statistics->{TESTS_EXPECTED_FAIL}++;
    } elsif ($status == STATUS_FAIL) {
        $statistics->{TESTS_UNEXPECTED_FAIL}++;
        $unexpected = 1;
    } elsif ($status == STATUS_UXSUCCESS) {
        $statistics->{TESTS_UNEXPECTED_OK}++;
        $unexpected = 1;
    } elsif ($status == STATUS_SKIP) {
        $statistics->{TESTS_SKIP}++;
    }

    my $reason;
    if (defined $pkt->{file_content} && length $pkt->{file_content}) {
        $reason = $pkt->{file_content};
    }
    $msg_ops->end_test($name, $result, $unexpected, $reason)
        if $msg_ops->can('end_test');
}

1;

__END__

=head1 NAME

Test::Subunit::V2 - Subunit version 2 binary protocol support

=head1 SYNOPSIS

    use Test::Subunit::V2 qw(pack_packet write_packet parse_stream
                             STATUS_INPROGRESS STATUS_SUCCESS STATUS_FAIL);

    # Emit packets.
    write_packet(\*STDOUT,
                 status   => STATUS_INPROGRESS,
                 testid   => 'foo',
                 runnable => 1);
    write_packet(\*STDOUT,
                 status   => STATUS_SUCCESS,
                 testid   => 'foo',
                 runnable => 1);

    # Parse packets from a filehandle.
    Test::Subunit::V2::parse_stream($msg_ops, $statistics, $fh);

=head1 DESCRIPTION

Implements the subunit v2 binary protocol as described at
L<https://github.com/testing-cabal/subunit>.

=cut
