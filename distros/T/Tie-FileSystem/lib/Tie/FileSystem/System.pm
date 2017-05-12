#-----------------------------------------------------------------------
# Copyright 2003-2007 Vadim V. Kouevda,
#                     "KAITS, Inc."                All rights reserved.
#-----------------------------------------------------------------------
# $Id: System.pm,v 2.13 2007/03/21 00:11:01 vadim Exp $
#-----------------------------------------------------------------------
# Authors:    Vadim V. Kouevda   initdotd@gmail.com
#-----------------------------------------------------------------------
# Description: This is an add-on definitions for file processing.
#         It is supposed to handle files, which can be classified as
#         "system".
#-----------------------------------------------------------------------

package         Tie::FileSystem::System;

use             vars qw($VERSION @ISA @EXPORT);
use             strict;
use             Exporter;
use             Data::Dumper;

#-----------------------------------------------------------------------

$VERSION        = sprintf("%d.%d", q$Revision: 2.13 $ =~ /(\d+)\.(\d+)/);
@ISA            = qw(Exporter);
@EXPORT         = qw(passwd);

#-----------------------------------------------------------------------
# Define file handlers
#-----------------------------------------------------------------------

sub passwd {
    #-------------------------------------------------------------------
    # Process /etc/passwd file - this function is "an example"
    #-------------------------------------------------------------------
    my ($file, $dbg, $size_limit) = @_;
    my %contents;
    my @columns = qw/login passwd uid gid comment home shell/;
    open FILE, "<$file" or return(undef);
    while (my $line=<FILE>) {
        chomp($line);
        my @fields = split(/:/, $line);
        foreach my $idx (1 .. 6) {
            $contents{$fields[0]}{$columns[$idx]} = $fields[$idx];
        }
    }
    close(FILE);
    return(\%contents);
}

#-----------------------------------------------------------------------
# Plain Old Documentation
#-----------------------------------------------------------------------

=head1 NAME

Tie::FileSystem::System - Helper functions for reading in and processing
of system files in the Tie::FileSystem framework.

=head1 SYNOPSIS

This module is not used separately from Tie::FileSystem.

=head1 DESCRIPTION

Tie::FileSystem represents file system as a Perl hash. Each hash key
corresponds to name of a directory or a file. For example, for a file
"/etc/passwd" it will be $data{'etc'}{'passwd'}. Contents of the file
"/etc/passwd" becomes a value corresponding to the
$data{'etc'}{'passwd'}.

Standard handling procedure for directories is to store a listing of
files in the directory as keys. Standard procedure for files is to store
a contents of the file in the scalar value.

For certain files with known structure it is possible to define
subroutines for special handling. Tie::FileSystem::System" defines
subroutines for handling system files and, for starters, has 'passwd'
handling subroutine. "/etc/passwd" can be represented asa hash with
following structure: $data{'etc'}{'passwd'}{$username}{$field}.

=head1 USING THE MODULE

This modules is used internally by Tie::FileSystem.

=head1 BUGS

None known.

=head1 AUTHOR

Vadim V. Kouevda, initdotd@gmail.com

=head1 LICENSE and COPYRIGHT

Copyright (c) 2003-2007, Vadim V. Kouevda, "KAITS, Inc."

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

These terms are your choice of any of (1) the Perl Artistic Licence, or
(2) version 2 of the GNU General Public License as published by the
Free Software Foundation, or (3) any later version of the GNU General
Public License.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along
with this library program; it should be in the file COPYING. If not,
write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111 USA

For licensing inquiries, contact the author at initdotd@gmail.com

=head1 WARRANTY

Module comes with ABSOLUTELY NO WARRANTY. For details, see the license.

=head1 AVAILABILITY

The latest version can be obtained from CPAN

=head1 SEE ALSO

Tie::FileSystem(3)

=cut

#-----------------------------------------------------------------------
# $Id: System.pm,v 2.13 2007/03/21 00:11:01 vadim Exp $
#-----------------------------------------------------------------------
# $Log: System.pm,v $
# Revision 2.13  2007/03/21 00:11:01  vadim
# Cleaning POD from KA::Tie::Dir references
#
# Revision 2.11  2007/03/20 21:17:08  vadim
# Convert to Tie:FileSystem name space
#-----------------------------------------------------------------------
1;
