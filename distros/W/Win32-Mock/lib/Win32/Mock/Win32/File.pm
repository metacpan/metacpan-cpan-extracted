package # hide from PAUSE
        Win32::File;
use strict;
use warnings;
use Exporter ();

use constant {
    READONLY    => 0x00000001,  # FILE_ATTRIBUTE_READONLY
    HIDDEN      => 0x00000002,  # FILE_ATTRIBUTE_HIDDEN
   #LABEL       => 0x00000008,  # FILE_ATTRIBUTE_LABEL  /* Not in Windows API */
    SYSTEM      => 0x00000004,  # FILE_ATTRIBUTE_SYSTEM
    DIRECTORY   => 0x00000010,  # FILE_ATTRIBUTE_DIRECTORY
    ARCHIVE     => 0x00000020,  # FILE_ATTRIBUTE_ARCHIVE
    NORMAL      => 0x00000080,  # FILE_ATTRIBUTE_NORMAL
    TEMPORARY   => 0x00000100,  # FILE_ATTRIBUTE_TEMPORARY
    COMPRESSED  => 0x00000800,  # FILE_ATTRIBUTE_COMPRESSED
   #xxxxxxxxxx  => 0x00000200,  # FILE_ATTRIBUTE_ATOMIC_WRITE
   #xxxxxxxxxx  => 0x00000400,  # FILE_ATTRIBUTE_XACTION_WRITE
    OFFLINE     => 0x00001000,  # FILE_ATTRIBUTE_OFFLINE
};

{
    no strict;
    $VERSION = '0.01';
    @ISA     = qw(Exporter);
    @EXPORT  = qw(
        ARCHIVE COMPRESSED DIRECTORY HIDDEN LABEL  
        NORMAL  OFFLINE    READONLY  SYSTEM TEMPORARY
    );
    @EXPORT_OK = qw(
        GetAttributes  SetAttributes
    );
}

my %file_attrs = ();

sub GetAttributes {
    my ($file, $attr) = @_;
    $_[1] = $file_attrs{$file} ||= NORMAL;
    return 1
}

sub SetAttributes {
    my ($file, $attr) = @_;
    $file_attrs{$file} = $attr;
    return 1
}


1

__END__

=head1 NAME

Win32::File - Mocked Win32::File

=head1 SYNOPSIS

    use Win32::Mock;
    use Win32::File;

=head1 DESCRIPTION

This module is a mock/emulation of C<Win32::File>. 
See the documentation of the real module for more details. 

=head1 SEE ALSO

L<Win32::File>

L<Win32::Mock>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>sebastien@aperghis.netE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2008 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
