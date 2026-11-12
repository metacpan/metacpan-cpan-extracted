package UUID::V7;
$UUID::V7::VERSION = '0.004';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/generate_uuid_v7 extract_uuid_v7_time uuid_string_to_binary uuid_binary_to_string is_uuid_v7/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use Carp;
use Crypt::SysRandom 'random_bytes';
use POSIX::RT::Clock 0.024;

use constant HAS_NANO => POSIX::RT::Clock->new('realtime')->get_resolution->nsec < 1000;

my $clock = POSIX::RT::Clock->new('realtime');
my $nano_per_milli = 1_000_000;
my $format = 'H8H4H4H4H12';
my $submilli_modulus = 1 << 12;
my $uuid_v7_marker = 0x7000;

sub generate_uuid_v7 {
	use integer;
	my $time = $clock->get_time;
	my $nanoseconds = $time->nsec;
	my $milliseconds = $time->sec * 1000 + $nanoseconds / $nano_per_milli;
	my $sub_milliseconds = $nanoseconds % $nano_per_milli * $submilli_modulus / $nano_per_milli;

	my $high = ($milliseconds << 16) + $sub_milliseconds | $uuid_v7_marker;
	my $result = pack 'Q>A8', $high, random_bytes(8);
	vec($result, 28, 2) = vec($result, 35, 2) if not HAS_NANO; # lowest two bits of timestamp set to unused randomness.
	vec($result, 35, 2) = 2; # RFC 9562 variant

	return join '-', unpack $format, $result;
}

sub extract_uuid_v7_time {
	my ($uuid) = @_;
	my $binary = uuid_string_to_binary($uuid);
	croak 'UUID is not version 7' if vec($binary, 13, 4) != 7;

	my $high = unpack 'Q>', $binary;
	my $time = $high >> 16;
	$time += ($high & 0x0FFF) / $submilli_modulus;
	return $time / 1000;
}

sub uuid_string_to_binary {
	my ($uuid) = @_;
	croak 'UUID has incorrect length' if length $uuid != 36;
	return pack $format, split /-/, $uuid;
}

sub uuid_binary_to_string {
	my ($input) = @_;
	croak 'UUID binary has incorrect length' if length $input != 16;
	return join '-', unpack $format, $input;
}

sub is_uuid_v7 {
	my ($uuid) = @_;
	my $binary = uuid_string_to_binary($uuid);
	return vec($binary, 13, 4) == 7;
}

1;

# ABSTRACT: A precise UUIDv7 implementation

__END__

=pod

=encoding UTF-8

=head1 NAME

UUID::V7 - A precise UUIDv7 implementation

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use UUID::V7 ':all';

 my $uuid = generate_uuid_v7();
 my $time = extract_uuid_v7_time($uuid);

 my $binary = uuid_string_to_binary($uuid);
 my $uuid = uuid_binary_to_string($binary);
 croak "Not UUIDv7" unless is_uuid_v7($uuid);

=head1 DESCRIPTION

UUID version 7 are monotonically ascending and creation-time ordered unique identifiers, making them particularly suitable for database indices.

B<NOTE:> this module requires a perl with 64-bit integers; if you want to use it on a 32-bit system you need to compile your perl with the C<use64bitint> option.

=head1 FUNCTIONS

=head2 generate_uuid_v7

 my $uuid = generate_uuid_v7();

This will generate a new UUIDv7 identifier. This will use 60 bits of timing information (±250 nanoseconds) for monotonicity with high-frequency UUID generation if available on your platform. It will contain 62 bits of cryptographically strong randomness.

=head2 extract_uuid_v7_time

 my $time = extract_uuid_v7_time($uuid);

This will extract the time out of a UUIDv7.

=head2 uuid_string_to_binary

 my $binary = uuid_string_to_binary($uuid);

This will convert a UUID string to its equivalent 16-byte big-endian binary value.

=head2 uuid_binary_to_string

 my $uuid = uuid_binary_to_string($binary);

This will convert a 16-byte big-endian binary value to its equivalent UUID string.

=head2 is_uuid_v7

 my $is_7 = is_uuid_v7($uuid);

This returns true if the UUID is version 7

=head1 SEE ALSO

For UUIDv4, L<Crypt::SysRandom|Crypt::SysRandom> provides a C<random_uuid> function.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
