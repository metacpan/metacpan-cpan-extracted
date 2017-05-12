#############################################################################
## Name:        Wx::Perl::FSHandler::UNC
## Purpose:     UNC FileSystemHandler
## Author:      Simon Flack
## Modified by: $Author: mattheww $ on $Date: 2006/05/18 11:13:03 $
## Created:     14/11/2002
## RCS-ID:      $Id: UNC.pm,v 1.8 2006/05/18 11:13:03 mattheww Exp $
#############################################################################

package  Wx::Perl::FSHandler::UNC;
use strict;
use vars qw( @ISA $VERSION );

@ISA = qw( Wx::PlFileSystemHandler );
$VERSION = sprintf'%d.%03d', q$Revision: 1.8 $ =~ /: (\d+)\.(\d+)/;

use IO::File;
use Wx::FS;

sub CanOpen {
    my ($self, $location) = @_;
    (my $unc = $location) =~ s|/|\\|g;

    return 1 if $unc =~ /^\\\\/;
}

sub OpenFile {
    my ($self, $fs, $location) = @_;
    (my $unc = $location) =~ s|/|\\|g;

    return unless -e $unc && -r _;

    my $mimetype = 'text/plain';
    my $anchor = '';

    my $fh = new IO::File( $unc, 'r' );
    return unless defined $fh;

    my $FSfile = new Wx::FSFile( $fh, $unc, $mimetype, $anchor );
    return $FSfile;
}


1;

=pod

=head1 NAME

Wx::Perl::FSHandler::UNC - A filesystem handler for UNC filepaths

=head1 SYNOPSIS

  use Wx::Perl::FSHandler::UNC;
  Wx::FileSystemHandler::AddHandler( new  Wx::Perl::FSHandler::UNC );

=head1 DESCRIPTION

Wx::Perl::FSHandler::UNC is a wxFileSystemHandler. The default file system
handlers don't appear to support UNC file paths since the slashes are
un-microsoft'd by default.

=head1 WX SPECIFICS

See L</SYNOPSIS> for usage.

IO::File is used to open files given a UNC file path.

This module overrides two methods of wxFileSystemHandler: CanOpen() and
OpenFile().

=head1 LIMITATIONS

This handler opens files only in read-only mode.

FindFirst() and FindNext() are not implemented. They will need to be if
wildcards are being used.

=head1 AUTHOR

	Simon Flack <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 SEE ALSO

wxWidgets: wxFileSystem, wxFSFile, wxFileSystemHandler, wxFileSystem Overview

wxPerl L<http://wxperl.sourceforge.net>

L<Win32::NetName>

L<Wx::Perl::FSHandler::LWP>

L<IO::File>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
