package Win32::StreamNames;

use 5.008000;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# I only have one function name, so may as well export it 
our @EXPORT = qw( StreamNames);

our $VERSION = '1.04';

require XSLoader;
XSLoader::load('Win32::StreamNames', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

# Below is documentation for the module

=head1 NAME

Win32::StreamNames - Perl extension for reading Windows ADS names

=head1 SYNOPSIS

  use Win32::StreamNames;
  @streams = StreamNames( $file );
  
  if (@streams)
  {
     ...
  }
  else
  {
     # No Additional Data Stream names
     ...
  }

=head1 DESCRIPTION

Data Streams have always been a feature of Windows, but support 
for them was reinforced with NTFS 5 on Windows 2000.
With an additional data stream, a simple file can be 'extended' to 
include other data, and Windows Explorer does just that 
with its Summary Information (from the file Properties dialog).
The stream itself is seen by Perl as a separate file for I/O
purposes, but is invisible when scanning a directory using glob
or readdir.

To get at the stream names associated with a file requires calls
to the BackupRead Win32 API (and a few other bits and pieces), 
This module provides a simple wrapper to the API calls.

The only external function, StreamNames, takes a file or directory 
name as an argument, and returns a list of stream names.  These may
be appended to the original filename to get a fully qualified name,
which may be opened using the usual Perl functions.  

If the specified file or directory cannot be opened then $^E 
($EXTENDED_OS_ERROR) is set and an empty list is returned.  Note 
that an empty list is not necessarily an error, since a file need 
not have any additional streams.

For example:

   for $file ( glob("*.txt") ) 
   {
      @list = StreamNames($file);
   
      if (!@list && $^E)
      {
         print STDERR "Unable to open $file: $^E\n";
         next
      }
   
      for $stream (@list)
      {
         open (HANDLE, $file.$stream) || 
               die "Unable to open $file$stream: $!";
            
         binmode HANDLE;
         while (<HANDLE>)
         {
            # Do some stuff

         }

         close HANDLE;
      }
   
   }

=head2 NOTES 

The SummaryInformation stream names used by Windows Explorer 
contain a non-ASCII character (0x05).  Perl can happily open a
file with such a name but it might surprise you (it is displayed
as a playing card 'spade' symbol).

Microsoft Office applications such as Word do no use additional
data streams, but store their summary information in internal
fields.

The module now supports directory names, as well as files.

=head2 EXPORT

StreamNames



=head1 SEE ALSO

Win32::API provides a generic interface to APIs in kernel32.dll

=head1 BUGS

Versions prior to 1.03 had a bug where empty ADS files were not listed.
Versions prior to 1.04 had a bug where empty ADS files terminated the list.
Thanks to Frederic Medico for reporting these.

=head1 AUTHOR

Clive Darke, E<lt>clive.darke @ talk21.comE<gt>
With thanks to Geert VAN ACKER for the directory suggestion

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2007, 2008, 2009 by Clive Darke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
