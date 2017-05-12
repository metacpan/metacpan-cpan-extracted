package Win32::UrlCache::FileTimePP;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT = qw( filetime );

use Math::BigInt try => 'GMP';
use DateTime;
use DateTime::Duration;

sub filetime {
  my $filetime = shift;

  my @bytes;
  if ( length( $filetime ) == 18 && substr( $filetime, 0, 2 ) eq '0x' ) {
     @bytes = map { chr(hex($_)) }
              substr( $filetime, 2 ) =~ /(..)/g;
  }
  else {
    @bytes = split //, $filetime;
  }

  my $hundred_nanoseconds = (
    ord( $bytes[7] ) * ( 256 ** 7 ) +
    ord( $bytes[6] ) * ( 256 ** 6 ) +
    ord( $bytes[5] ) * ( 256 ** 5 ) +
    ord( $bytes[4] ) * ( 256 ** 4 ) +
    ord( $bytes[3] ) * ( 256 ** 3 ) +
    ord( $bytes[2] ) * ( 256 ** 2 ) +
    ord( $bytes[1] ) * ( 256 ** 1 ) +
    ord( $bytes[0] ) * ( 256 ** 0 )
  );

  my $seconds = $hundred_nanoseconds / 10000000;
  my $minutes = $seconds / 60;
  my $hours   = $minutes / 60;
  my $days    = $hours   / 24;

  my $start = DateTime->new(
    year      => 1601,
    month     => 1,
    day       => 1,
    hour      => 0,
    minute    => 0,
    second    => 0,
    time_zone => 'GMT',
  );

  # explicitly stringify to unbless
  my $duration = DateTime::Duration->new(
    days    => "$days",
    hours   => "".($hours   % 24),
    minutes => "".($minutes % 60),
    seconds => "".($seconds % 60),
  );

  my $date = $start + $duration;
}

1;

__END__

=head1 NAME

Win32::UrlCache::FileTimePP - convert Windows FileTime to DateTime object

=head1 SYNOPSIS

  use Win32::UrlCache::FileTimePP;
  filetime( '0x809F9D637B90C701' ); # 2007-05-07T07:43:23

=head1 DESCRIPTION

This is used internally to convert a Windows FileTime data to a (Perl's) DateTime object. According to MSDN, Windows FileTime is a structure of "a 64-bit value representing the number of 100-nanosecond intervals since January 1, 1601."

=head1 FUNCTION

=head2 filetime

receives a FileTime binary structure or an equivalent hex string (which should start with '0x') and returns a DateTime object. This function is exported by default.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
