package Win32::MBCS;

use 5.008;
use strict;
use warnings;
use base qw(Exporter);
use vars qw($VERSION @EXPORT @EXPORT_OK);
$VERSION = "0.07";
@EXPORT = qw();
@EXPORT_OK = qw(Utf8ToLocal LocalToUtf8);

require XSLoader;
XSLoader::load('Win32::MBCS', $VERSION);

1;
__END__

=head1 NAME

Win32::MBCS - Utf8 and win32 local multi-byte string conversion

=head1 SYNOPSIS

  use Win32::MBCS qw(Utf8ToLocal LocalToUtf8);
  $data = "abcd\x{4e2d}\x{6587}";
  Utf8ToLocal( $data );
  print $data;

  LocalToUtf8( $data );
  use Encode;
  print Encode::encode( "gbk", $data );

=head1 DESCRIPTION

Convert utf8 strings to or from win32 local multi-byte string.

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
L<http://bookbot.sourceforge.net/>
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-MBCS>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2004 Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
