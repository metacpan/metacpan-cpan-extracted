package Win32::IdentifyFile;

use 5.008000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::IdentifyFile ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(IdentifyFile CloseIdentifyFile
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Win32::IndentifyFile::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Win32::IdentifyFile', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is POD

=head1 NAME

Win32::IdentifyFile - Perl extension for to obtain an identity for an NTFS file

=head1 SYNOPSIS

  use Win32::IdentifyFile qw(:all);

  @info = IdentifyFile(filename);
  $info = IdentifyFile(filename);
  CloseIdentifyFile();

=head1 DESCRIPTION

This module returns three items which together uniquely identify a file
or directory on Microsoft Windows NTFS.  The identity fulfils a similar
role to an inode number on UNIX file systems.

The filename specified may be a file or directory, and may be in conventional
Windows, relative, or UNC (Universal Naming Convention), formats.

The information returned by IdentifyFile is as follows:
   Volume Serial Number, 
   File Index High,
   File Index Low.  
In list context these are returned as a list.  
In scalar context these are returned as a single string, joined by ':';

Just getting this information could result in a race condition.  The
file could be deleted, possibly by another process, between getting the information
and using it in a test.  Worse, another file might be created with the same
file index meanwhile.  To prevent this scenario, files (or directories) are
opened internally by IdentifyFile(), and kept open until CloseIdentifyFile() 
is called (files are not physically deleted until all open file handles are closed).

It is important to call CloseIdentifyFile() in order to avoid a resource leak.  
Only one call is required, regardless of the number of times IdentifyFile() is 
called.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Win32API::File

=head1 AUTHOR

Clive Darke, E<lt>clive.darke@talk21.comE<gt>
From a suggestion by 'grinder'

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Clive Darke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
