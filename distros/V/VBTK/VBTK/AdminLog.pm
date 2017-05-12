#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/AdminLog.pm,v $
#            $Revision: 1.5 $
#                $Date: 2002/03/04 20:53:06 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: Methods to handle maintenance of an administration
#                       log file.
#
#       Copyright (C) 1996 - 2002  Brent Henry
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of version 2 of the GNU General Public
#       License as published by the Free Software Foundation available at:
#       http://www.gnu.org/copyleft/gpl.html
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#############################################################################
#
#
#       REVISION HISTORY:
#
#       $Log: AdminLog.pm,v $
#       Revision 1.5  2002/03/04 20:53:06  bhenry
#       *** empty log message ***
#
#       Revision 1.4  2002/03/04 16:49:08  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.3  2002/03/02 00:53:54  bhenry
#       Documentation updates
#
#       Revision 1.2  2002/01/28 18:13:19  bhenry
#       *** empty log message ***
#
#       Revision 1.1  2002/01/23 20:32:43  bhenry
#       *** empty log message ***
#
#

package VBTK::AdminLog;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use Storable qw(store retrieve);

our $VERBOSE=$ENV{VERBOSE};

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:  Configuration filename
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my $type = shift;
    my $fileName = shift;

    my $self = retrieve($fileName) if (-f $fileName);
    $self ||= {};
    bless $self, $type;

    $self->{fileName} = $fileName;

    # If nothing was loaded, then just initialize it to an empty array
    $self->{entryList} ||= [];

    $self;
}

#-------------------------------------------------------------------------------
# Function:     write
# Description:  Write the admin log to the specified file
# Input Parms:  None
# Output Parms: Return value
#-------------------------------------------------------------------------------
sub write
{
    my $self = shift;
    my $fileName = $self->{fileName};
    
    $self->store($fileName) || return undef;
    
    1;
}

#-------------------------------------------------------------------------------
# Function:     addEntry
# Description:  Add an entry to the adminLog and write it out to the file
# Input Parms:  None
# Output Parms: Return Value
#-------------------------------------------------------------------------------
sub addEntry
{
    my $self = shift;
    my $fileName  = $self->{fileName};
    my $entryList = $self->{entryList};
    
    my $entry = [ @_ ];
    push(@{$entryList},$entry);
    
    $self->write;
}

#-------------------------------------------------------------------------------
# Function:     delEntry
# Description:  Delete the specified entry number
# Input Parms:  None
# Output Parms: Return Value
#-------------------------------------------------------------------------------
sub delEntry
{
    my $self = shift;
    my $fileName  = $self->{fileName};
    my $entryList = $self->{entryList};
    my @delPos = sort @_;
    my $delCount = 0;
    
    return undef if (@delPos < 1);
    
    foreach my $pos (@delPos)
    {
        $pos -= $delCount;
        next if (($pos < 0)||($pos >= @{$entryList}));
        splice(@{$entryList},$pos,1);
        $delCount++;
    }
    
    $self->write;
}

#-------------------------------------------------------------------------------
# Function:     getEntryList
# Description:  Retrieve the list of log entries sorted by the specified column.
# Input Parms:  None
# Output Parms: Return Value
#-------------------------------------------------------------------------------
sub getEntryList 
{ 
    my $self = shift;
    my $sortCol = shift || 0;
    my $entryList = $self->{entryList};
    my (@posMappedList,$x,$reverse,@retList);
    
    # If a negative number is specified, then reverse the sort order
    if ($sortCol =~ /^-/)
    {
        $reverse = 1;
        $sortCol = abs($sortCol);
    }
    
    # Add a 'position' column onto the beginning of all the data sets    
    for($x = 0; $x < @{$entryList}; $x++)
    {
        push(@posMappedList, [ $x, @{$entryList->[$x]} ]);
    }
    
    # If there are any non-numeric entries in the column we're trying to sort,
    # then use an alpha-numeric sort.  Otherwise use a numeric sort
    if(grep(/[^\d]/, map { $_->[$sortCol] } @posMappedList))
    {
        @retList = sort { $a->[$sortCol] cmp $b->[$sortCol]; } @posMappedList;
    }
    else
    {
        @retList = sort { $a->[$sortCol] <=> $b->[$sortCol]; } @posMappedList;
    }
    
    if($reverse) { reverse @retList; }
    else         { @retList; }
}


1;
__END__

=head1 NAME

VBTK::AdminLog - Internal module of VBTK

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This is an internal module of the VB tool kit used to maintain administration
logs through the web interface.  Do not try to access this package directly.

=head1 SEE ALSO

L<VBTK|VBTK>,
L<VBTK::Parser|VBTK::Parser>,
L<VBTK::ClientObject|VBTK::ClientObject>,
L<VBTK::Server|VBTK::Server>

=head1 AUTHOR

Brent Henry, vbtoolkit@yahoo.com

=head1 COPYRIGHT

Copyright (C) 1996-2002 Brent Henry

This program is free software; you can redistribute it and/or
modify it under the terms of version 2 of the GNU General Public
License as published by the Free Software Foundation available at:
http://www.gnu.org/copyleft/gpl.html

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
