package ULID::Tiny;

use strict;
use warnings;
use v5.16;

use Crypt::SysRandom qw(random_bytes);
use Time::HiRes qw(time);
use Fcntl qw(O_RDONLY);

use Exporter 'import';

our $VERSION = '1.0.0';

our @EXPORT    = qw(ulid ulid_date);
our @EXPORT_OK = qw(ulid ulid_date);

my @CROCKFORD_CHARS = split //, '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

###############################################################################
# Public API
###############################################################################

sub ulid {
	my (%opts) = @_;

	my $ts;
	if (defined($opts{time})) {
		$ts = _encode_timestamp($opts{time});
	} else {
		$ts = _unixtime_ms_48bit();
	}

	my $rand = random_bytes(10);
	my $ret  = '';

	state $prev_ts   = 0;
	state $prev_ulid = "";

	if (!$opts{unique} && $prev_ts && ($ts eq $prev_ts)) {
		$ret = _crockford_increment($prev_ulid);
	} else {
		# 48 bits of timestamp + 80 bits of randomness
		my $raw = $ts . $rand;

		$ret = _crockford_encode($raw);
	}

	if (!$opts{unique}) {
		$prev_ts   = $ts;
		$prev_ulid = $ret;
	}

	if ($opts{binary}) {
		my $bits = _crockford_decode_bits($ret);
		$bits = substr($bits, 0, 128);
		return pack("B*", $bits);
	}

	return $ret;
}

# Extract the millisecond epoch timestamp from a ULID string
sub ulid_date {
	my ($ulid_str) = @_;

	if (!defined $ulid_str || length($ulid_str) != 26) {
		die "Invalid ULID: must be exactly 26 characters";
	}

	# The first 10 characters of a ULID encode the 48-bit timestamp.
	# 10 Crockford chars = 50 bits, but only the top 48 are the timestamp
	# (the encoder right-pads 2 zero bits to reach a multiple of 5).
	my $time_part = substr($ulid_str, 0, 10);
	my $raw       = _crockford_decode_int($time_part);
	my $ms        = $raw >> 2; # discard the 2 padding bits

	return $ms;
}

###############################################################################
# Internal functions
###############################################################################

sub _crockford_increment {
    my ($str) = @_;

    state %val;

	# Build the reverse mapping table (once)
	if (!scalar(%val)) {
		@val{@CROCKFORD_CHARS} = (0..$#CROCKFORD_CHARS);
	}

    my @out   = reverse split //, uc($str);
    my $carry = 1;

    for my $i (0 .. $#out) {
        last unless $carry;

        my $v  = $val{$out[$i]};
        $v    += $carry;

        if ($v >= 32) {
            $out[$i] = $CROCKFORD_CHARS[0];
            $carry   = 1;
        } else {
            $out[$i] = $CROCKFORD_CHARS[$v];
            $carry   = 0;
        }
    }

	if ($carry) {
		push(@out, '1');
	}

    return join('', reverse @out);
}

sub _crockford_encode {
    my ($bytes) = @_;
    my $bits    = unpack("B*", $bytes);
    my $result  = '';

    # Pad bits to multiple of 5
    my $pad = (5 - (length($bits) % 5)) % 5;
    $bits .= '0' x $pad;

    for (my $i = 0; $i < length($bits); $i += 5) {
        my $chunk = substr($bits, $i, 5);
        my $index = 0;
        for my $bit (split //, $chunk) {
            $index = ($index << 1) | $bit;
        }

        $result .= $CROCKFORD_CHARS[$index];
    }

    return $result;
}

# Decode a Crockford Base32 string to a decimal integer (for timestamps)
sub _crockford_decode_int {
    my ($str) = @_;

    state %val;
	if (!scalar(%val)) {
		@val{@CROCKFORD_CHARS} = (0..$#CROCKFORD_CHARS);
	}

    my $n = 0;
    for my $ch (split //, uc($str)) {
        $n = $n * 32 + ($val{$ch} // die "Invalid Crockford character: $ch");
    }

    return $n;
}

# Decode a Crockford Base32 string to a binary bit string
sub _crockford_decode_bits {
    my ($str) = @_;

    state %val;
	if (!scalar(%val)) {
		@val{@CROCKFORD_CHARS} = (0..$#CROCKFORD_CHARS);
	}

    my $bits = '';
    for my $ch (split //, uc($str)) {
        my $v = $val{$ch} // die "Invalid Crockford character: $ch";
        $bits .= sprintf("%05b", $v);
    }

    return $bits;
}

sub _unixtime_ms_48bit {
    my $ms = int(time() * 1000);

    return pack("H*", sprintf("%012X", $ms));
}

sub _encode_timestamp {
    my ($epoch_ms) = @_;

    return pack("H*", sprintf("%012X", int($epoch_ms)));
}

1;

__END__

=head1 NAME

ULID::Tiny - A lightweight ULID (Universally Unique Lexicographically Sortable
Identifier) generator

=head1 SYNOPSIS

    use ULID::Tiny qw(ulid ulid_date);

    # Generate a new ULID
    my $id = ulid(); # e.g. "01ARZ3NDEKTSV4RRFFQ69G5FAV"

    # Generate a ULID with a specific timestamp (milliseconds since epoch)
    my $id = ulid(time => 1234567890000);

    # Extract the timestamp from a ULID (returns milliseconds since epoch)
    my $ms = ulid_date($id);

    # Generate a ULID in raw 16-byte binary form
    my $bytes = ulid(binary => 1);

=head1 DESCRIPTION

ULID::Tiny is a minimal, pure Perl, dependency-light module for generating
ULIDs.

https://github.com/ulid/spec

A ULID is a 128-bit identifier consisting of:

=over 4

=item * 48-bit millisecond timestamp (first 10 characters)

=item * 80-bit cryptographic randomness (last 16 characters)

=back

Key properties:

=over 4

=item * Lexicographically sortable

=item * Canonically encoded as a 26 character string

=item * Monotonically increasing within the same millisecond

=back

=head1 METHODS

=over 4

=item B<ulid(%opts)>

Generate a new ULID string. Options:

=over 4

=item * C<time> - Specify timestamp in milliseconds. Defaults to current time.

=item * C<binary> - Returns the raw 16-byte binary ULID instead of an
alpha-numeric string.

=back

=item B<ulid_date($ulid_string)>

Extract the timestamp from a ULID string. Returns the number of milliseconds
since the Unix epoch.

=back

=head1 RANDOMNESS

The module uses C<Crypt::SysRandom> to get the best source of cryptographic
entropy

=head1 VERSION

1.0.0

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4
