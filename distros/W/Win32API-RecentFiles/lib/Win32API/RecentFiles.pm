package Win32API::RecentFiles 0.04;
use 5.020;
use experimental 'signatures';
use Exporter 'import';
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw(SHAddToRecentDocsA SHAddToRecentDocsU SHAddToRecentDocsW);

our $VERSION = '0.04';

bootstrap Win32API::RecentFiles;
1;

=encoding utf8

=head1 NAME

Win32API::RecentFiles - recently accessed file API functions on Windows

=head1 SYNOPSIS

  use Win32API::RecentFiles qw(SHAddToRecentDocsA SHAddToRecentDocsW SHAddToRecentDocsU);
  use Win32;
  use Encode 'encode';
  SHAddToRecentDocsA('C:\\Full\\Path\\To\\Makefile.PL');
  SHAddToRecentDocsW(encode('UTF-16LE', 'C:\\Full\\Path\\To\\Motörhead.mp3'));

  use utf8;
  SHAddToRecentDocsU('C:\\Full\\Path\\To\\fünf.txt');
  my $recent_dir = Win32::GetFolderPath(Win32::CSIDL_RECENT());
  # $recent_dir\\fünf.txt.lnk exists

=head1 DESCRIPTION

This module exports the C<SHAddToRecentDocsA>
C<SHAddToRecentDocsU> and C<SHAddToRecentDocsW> functions.

=head1 FUNCTIONS

=head2 C<SHAddToRecentDocsA>

  SHAddToRecentDocsA('C:\\Full\\Path\\To\\Makefile.PL');
  
Adds the filename to the list of recently accessed documents.
C<$filename> must be an ANSI string encoded in the local code page.
Relative paths will be evaluated against the current directory.

=head2 C<SHAddToRecentDocsU>

  SHAddToRecentDocsU('C:\\Full\\Path\\To\\Makefile.PL');

C<$filename> must be a Unicode string encoded as UTF-8.

=head2 C<SHAddToRecentDocsW>

  SHAddToRecentDocsW('C\0:\0\\\0...');

C<$filename> must be a sequence of bytes encoded as UTF-16.

=head1 CYGWIN

Programs under Cygwin need to take care to pass native Windows
filenames and paths with Backslashes (!) tto the API.

=head1 SEE ALSO

Microsoft documentation at L<https://learn.microsoft.com/de-de/windows/win32/api/shlobj_core/nf-shlobj_core-shaddtorecentdocs>

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Win32API-RecentFiles>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/Win32API-RecentFiles/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2024- by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the Artistic License 2.0.

=cut

