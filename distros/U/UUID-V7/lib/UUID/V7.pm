package UUID::V7;
$UUID::V7::VERSION = '0.001';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/generate_uuid_v7/;

use Crypt::SysRandom 'random_bytes';
use POSIX::RT::Clock;

my $clock = POSIX::RT::Clock->new('realtime');
my $nano_to_milli = 1_000_000;

sub generate_uuid_v7 {
	use integer;
	my $time = $clock->get_time;
	my $nanoseconds = $time->nsec;
	my $primary = $time->sec * 1000 + $nanoseconds / $nano_to_milli;
	my $secondary = $nanoseconds % $nano_to_milli / 245; # 0..4081 is almost 12 bits

	my $result = pack "Q>A8", $primary << 16, random_bytes(8);
	vec($result, 3, 16) = $secondary;
	vec($result, 35, 2) = 2; # RFC 9562 variant
	vec($result, 13, 4) = 7; # UUIDv7

	return join '-', unpack 'A8A4A4A4A12', unpack 'H*', $result;
}

1;

# ABSTRACT: A precise UUIDv7 implementation

__END__

=pod

=encoding UTF-8

=head1 NAME

UUID::V7 - A precise UUIDv7 implementation

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use UUID::V7 'generate_uuid_v7';

 my $uuid = generate_uuid_v7();

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 generate_uuid_v7

This will generate a new UUIDv7 identifier. This will use 62 bits of timing information (±250 nanoseconds) for monotonicity with high-frequency UUID generation.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
