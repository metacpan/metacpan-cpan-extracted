package Win32::SearchPath;

use 5.008000;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our @EXPORT = qw( SearchPath );

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Win32::SearchPath', $VERSION);



1;
__END__

# Below is documentation for the module.

=head1 NAME

Win32::SearchPath - Perl extension for the Win32 API SearchPath.

=head1 SYNOPSIS

  use Win32::SearchPath;

  $FullPath = SearchPath ('perl');
  $FullPath = SearchPath ('perl', 'C:\\Bin;C:\\Perl\Bin;D:\\Bin');

=head1 DESCRIPTION

This module is specifically for use with Win32::Process::Create.  That interface
requires the full path name of the executable, which SearchPath provides.

   $FULL_PATH = SearchPath(FILENAME)

Search for the specified FILENAME.  By default the extension ".exe" is added to 
FILENAME, but this is ignored if it already has an extension.  The full path name of
the file is returned, or undef on error.  The path name may be in '8.3' format, which
can be converted using Win32::GetLongPathName if desired.

By default, the SearchPath API searches directories in the same order as code is loaded by 
the operating system (dll's and exe's), which is:

   1.  The directory from which the application was loaded.
   2.  The current directory.
   3.  The Windows system directory (SYSTEM32 on NT, 2000, XP, et al)
   4.  The 16-bit Windows system directory (named SYSTEM, largely obsolete).
   5.  The 'top level' Windows directory, in $ENV{SystemRoot}.
   6.  Finally it searches directories in the Path environment variable.

Alternatively a specific 'Path' list may be specified:

   $FULL_PATH = SearchPath(FILENAME,PATHLIST)

PATHLIST must be a list of directory names separated by semi-colons (';').  Only these 
directory names will be searched for FILENAME, sub-directories are not searched unless
they are specifically included in the list.  As with most Windows APIs, the directory
separator may be either 'slash' character (\ or /), but the returned path name will
contain back-slashes (\).

Although non-executable files can be searched for using this module, it is not really 
suitable for anything other than finding executables.

In the event of an error undef is returned, in which case $^E 
($EXTENDED_OS_ERROR) should be checked, not $! ($OS_ERROR).

=head2 EXPORT

SearchPath

=head1 SEE ALSO

Win32::Process
Win32::API provides a generic interface to APIs in kernel32.dll
File::Which is similar to the basic SearchPath API, but only searches %Path%.

SearchPath API in the MSDN

=head1 AUTHOR

Clive Darke, E<lt>clive.darke@talk21.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Clive Darke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
