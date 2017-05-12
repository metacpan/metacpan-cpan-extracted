package Win32::UrlCache::FileTime;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT = qw( filetime );

use Win32::API;

# BOOL FileTimeToSystemTime(
#   CONST FILETIME *lpFileTime,
#   LPSYSTEMTIME    lpSystemTime,
# )

my $FileTimeToSystemTime = Win32::API->new(
  kernel32 => FileTimeToSystemTime => 'PP', 'I'
);

sub filetime {
  my $filetime = shift;

# FILETIME
#   DWORD dwLowDateTime;
#   DWORD dwHighDateTime;

  if ( substr( $filetime, 0, 2 ) eq '0x' && length( $filetime ) == 18 ) {
    my $low   = substr $filetime, 2, 8;
    my $high  = substr $filetime, 10;
    $filetime = pack 'H8H8', $low, $high;
  }

# SYSTEMTIME
#   WORD wYear;
#   WORD wMonth;
#   WORD wDayOfWeek;
#   WORD wDay;
#   WORD wHour;
#   WORD wMinute;
#   WORD wSecond;
#   WORD wMilliseconds;

  my $systemtime = pack( 'S8', (0) x 8 );

  $FileTimeToSystemTime->Call( $filetime, $systemtime );

  my @systimes = unpack( 'S8', $systemtime );

  splice @systimes, 2, 1;  # remove wDayOfWeek

  return sprintf "%04d-%02d-%02d %02d:%02d:%02d", @systimes;
}

1;

__END__

=head1 NAME

Win32::UrlCache::FileTime - convert Windows FileTime

=head1 SYNOPSIS

  use Win32::UrlCache::FileTime;
  filetime( '0x809F9D637B90C701' ); # 2007-05-07 07:43:23

=head1 DESCRIPTION

This is used internally to convert a Windows FileTime data to a system time string through a Windows API.

=head1 FUNCTION

=head2 filetime

receives a FileTime binary structure or an equivalent hex string (which should start with '0x') and returns a system time string. This function is exported by default.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
