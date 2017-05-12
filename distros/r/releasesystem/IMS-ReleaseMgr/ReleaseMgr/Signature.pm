###############################################################################
#
#         May be distributed under the terms of the artistic license
#
#                  Copyright @ 1998, Hewlett-Packard, Inc.,
#                            All Rights Reserved
#
###############################################################################
#
#   @(#)$Id: Signature.pm,v 1.3 1999/02/23 23:44:56 randyr Exp $
#
#   Description:    Provide encapsulated signature-generation routines for
#                   use by various release manager and related tools.
#
#   Functions:      crc_signature
#                   md5_signature
#
#   Libraries:      IO::File
#                   MD5
#
#   Global Consts:  $VERSION            Version information for this module
#                   $revision           Copy of the RCS revision string
#
#   Environment:    None.
#
###############################################################################
package IMS::ReleaseMgr::Signature;

use 5.002;
use strict;
use vars qw($VERSION $revision @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use AutoLoader 'AUTOLOAD';
use Carp;
require Exporter;

$VERSION = do {my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d"x$#r,@r};
$revision = q$Id: Signature.pm,v 1.3 1999/02/23 23:44:56 randyr Exp $;

@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(crc_signature md5_signature);
%EXPORT_TAGS = ();

1;

__END__

###############################################################################
#
#   Sub Name:       crc_signature
#
#   Description:    Implement the CRC-based checksum used by the release
#                   manager at www.hp.com.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $file     in      scalar    Name of the file to be 
#                                                 checksum'd
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    string (multiple lines are joined by "\n")
#                   Failure:    undef
#
###############################################################################
sub crc_signature
{
    my $file = shift;

    require IO::File;

    my $fh = new IO::File "< $file";
    if (! defined $fh)
    {
        carp "Error opening $file for reading: $!, ";
        return undef;
    }

    my $crc = 0;
    my $buffer = '';
    while (sysread($fh, $buffer, 16384))
    {
        $crc += unpack("%32C*", $buffer);
    }
    $crc %= 32767; # ??? this is a 15-bit mask, not even 16, let alone 32?
    $fh->close;

    "CRC: $crc";
}

###############################################################################
#
#   Sub Name:       md5_signature
#
#   Description:    Generate a checksum using the MD5 algorithm (via the MD5
#                   extension).
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $file     in      scalar    Name of the file to be 
#                                                 checksum'd
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    string (multiple lines are joined by "\n")
#                   Failure:    undef
#
###############################################################################
sub md5_signature
{
    my $file = shift;

    require Digest::MD5;

    my $fh = new IO::File "< $file";
    if (! defined $fh)
    {
        carp "Error: could not open $file for reading: $!, ";
        return undef;
    }
    my $md5 = new Digest::MD5;
    $md5->addfile($fh);
    my $sum = $md5->hexdigest;
    $fh->close;

    $sum;
}

=head1 NAME

IMS::ReleaseMgr::Signature - Generate checksums (signatures)

=head1 SYNOPSIS

    use IMS::ReleaseMgr::Signature qw(crc_signature md5_signature);

    $signature = md5_signature $file;

=head1 DESCRIPTION

This package provides ordinary, simple checksum-generation routines for 
applications that area a part of (or related to) the Release Manager System.
Signatures are used to verify intact transfer of the data prior to deployment
into web areas. The goal of this package is to provide an abstracted means of
generating these signatures, in order to maintain consistency across the
various applications.

=head1 FUNCTIONS

All functions return a single string, or the special value B<undef> in case of
error. Error messages are sent as warnings, and can be trapped with a handler
attached to the special Perl B<__WARN__> pseudo-signal. If a signature style
results in multiple lines, those lines are joined together with newline
characters.

The following signature implementations are provided:

=over

=item crc_signature($file)

This is the fairly basic CRC-style checksum used by the release manager on
www.hp.com, but not currently in use on IMSS-supported servers. This is not
recommended for use unless bundling a package for deployment to the main
corporate server.

=item md5_signature($file)

Returns the standard RSA MD5 hash of the file contents as a 16-byte value,
expressed as a 32-digit hexadecimal string.

=back

=head1 AUTHOR

Randy J. Ray <randyr@nafohq.hp.com>

=head1 SEE ALSO

L<IMS::ReleaseMgr>, perl(1).

=cut
