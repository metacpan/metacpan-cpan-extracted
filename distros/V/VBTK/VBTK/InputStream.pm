#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/InputStream.pm,v $
#            $Revision: 1.5 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A perl library used to access data streams in the
#                       form of a file, a list of files, or a unix command.
#                       If the follow mode is used, the read command will
#                       never return EOF, but will always try to get more
#                       data out of the last file in the list, including
#                       checking to see if that file's inode has changed and
#                       if so, restarting the datastream from the beginning
#                       of the new file.
#
#          Description:
#
#           Directions: The call to  new VBTK::InputStream should look like:
#
#               $fh = new VBTK::InputStream(
#                           SourceList  => [ "file1", "file2" ... ],
#                           Follow      => < 1 | 0 >,
#                           ReadTimeout => <Timeout in seconds>,
#                           MaxReadTime => <Max total read time>);
#
#               The read timeout is how long to block waiting for more I/O
#               on the file being read before returning from the 'read' call.
#               The MaxReadTime is the total amount of time allowed before
#               returning from the 'read' call, even if there is more data
#               coming in.  This is used to prevent a slow but steady data
#               stream from monopolizing the 'read' call and never returning
#               control.
#
#           Invoked by:
#
#           Depends on: VBTK::Common
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
#       $Log: InputStream.pm,v $
#       Revision 1.5  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.4  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.3  2002/03/02 00:53:54  bhenry
#       Documentation updates
#
#       Revision 1.2  2002/01/21 17:07:40  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#
#

package VBTK::InputStream;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use FileHandle;

# commented out to test grapher
our $VERBOSE=$ENV{'VERBOSE'};

our $DEFAULT_TIMEOUT = 0;
our $DEFAULT_MAX_READ_TIME = 7;
our $BUFFER_SIZE = 10240;

our $prog_name = 'VBTK::InputStream.pm';

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:  Configuration filename
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my $type = shift;
    my $self = {};
    bless $self, $type;

    log("Setting up InputStream object") if ($VERBOSE > 1);

    # Store the passed input variables
    $self->set(@_);

    # Set defaults if not specified
    $self->{ReadTimeout} = $DEFAULT_TIMEOUT if ($self->{ReadTimeout} eq '');
    $self->{MaxReadTime} = $DEFAULT_MAX_READ_TIME if ($self->{MaxReadTime} eq '');

    # Make sure something was passed in the SourceList parm.
    my $SourceList = $self->{SourceList};
    return undef if ($SourceList eq '');

    # If the value passed in the SourceList parm is not a reference to an array
    # then create an anonymous array and store the string into it.  If the string
    # does not end in '|' (a unix command), then look for whitespace in the string
    # and split it up, storing the resulting array.
    if (ref($SourceList) ne 'ARRAY')
    {
        if ($SourceList =~ /\|\s*$/)
        {
            $self->{SourceList} = [ $SourceList ];
        }
        else
        {
            $self->{SourceList} = [ split(/\s+/,$SourceList) ];
        }
    }
    # If the CopySourceList variable is specified, then make a copy of the
    # SourceList array so that as list items are shifted off, it doesn't alter
    # the original array referenced by SourceList.  This obviously only applied
    # if SourceList is a reference to an array to begin with.
    elsif($self->{CopySourceList})
    {
        &log("Copying source list") if ($VERBOSE > 1);
        $self->{SourceList} = [ @{$SourceList} ];
    }

    # Open the first element in the input stream list
    $self->open || return undef;

    return $self;
}


#-------------------------------------------------------------------------------
# Function:     open
# Description:  Open up the next input source in the SourceList array.  Close the
#               previously open filehandle if it's open.  If we're already at the
#               last source file in the list, and we're in Follow mode, then check
#               to see if the inode has changed of the filesize has decreased and
#               if so, re-open the file and begin reading from the start.
# Input Parms:  None
# Output Parms: Return Value
#-------------------------------------------------------------------------------
sub open
{
    my $obj = shift;
    my $SourceList = $obj->{SourceList};
    my $Follow =     $obj->{Follow};
    my $fh =         $obj->{fh};
    my $currSource = $obj->{currSource};
    my $listSize = @{$SourceList};
    my $pid;

    my ($inode,$fsize);

    # Close the filehandle if it's open and store the return code if the
    # filehandle was really a child process.
    if (($fh ne '')&&($obj->{pid}))
    {
        &log("Closing FH for '$currSource'") if ($VERBOSE > 1);
        $fh->close;

        # An error code can appear in either the lower or the higher byte of $?.
        # By or-ing the low byte with the upper byte, we get an accurate error code.
        $obj->{retval} = ($? & 0xFF) | ($? >> 8);
        $obj->{fh} = $fh = undef;
    }

    # If there's nothing on the list, then just return an error
    return 0 if ($listSize < 1);

    # Pull off the first entry in the source list and return an error if blank
    $currSource = shift(@{$SourceList});
    return 0 if ($currSource eq '');

    # If the file handle is still open at this point, then we know it's not a
    # child process, so just close it and clear out the retval value.
    if ($fh ne '')
    {
        &log("Closing FH for '$currSource'") if ($VERBOSE > 1);
        $fh->close;
        $obj->{retval} = undef;
    }

    # Open the source and check for errors.  If it's a unix command being
    # executed, then the 'open' call will return a pid.
    &log("Opening input stream '$currSource'") if ($VERBOSE);
    $fh = new FileHandle;
    $pid = $fh->open("$currSource");

    unless ($pid)
    {
        &error("Cannot open input stream '$currSource'");
        $obj->{currSource} = undef;
        $obj->{rinVec} = undef;
        $obj->{pid} = undef;
        $fh->close();
        return 0;
    }

    # If this is really a child process being executed, then store the PID
    if($currSource =~ /\|\s*$/)
    {
        $obj->{pid} = $pid;
    }
    else
    {
        $obj->{pid} = undef;
    }

    # If this is the last file, and we're using Follow mode, and the source
    # is a file, then store the inode and fsize.
    if(($listSize == 1)&&($Follow)&&(-f $currSource))
    {
        ($inode,$fsize) = (stat $currSource)[1,7];
        $obj->{lastInode} = $inode;
        $obj->{lastFsize} = $fsize;
    }

    # Store read-ready vector for later use in 'select'ing filehandle status
    my $rinVec = "";
    vec($rinVec,fileno($fh),1) = 1;
    $obj->{rinVec} = $rinVec;

    # Store the other variables into the object
    $obj->{fh} = $fh;
    $obj->{currSource} = $currSource;

    (1);
}


#-------------------------------------------------------------------------------
# Function:     read
# Description:  Read as many rows as possible from the input stream.  If EOF is
#               reached, then open the next file in the source list and read
#               everything from it.  When the last file in the source list is
#               reached, keep waiting for more data if we're in Follow mode.
#               Otherwise, just return.
# Input Parms:  None
# Output Parms: Return Value
#-------------------------------------------------------------------------------
sub read
{
    my $obj = shift;
    my $fh = $obj->{fh};
    my $ReadTimeout = $obj->{ReadTimeout};
    my $MaxReadTime = $obj->{MaxReadTime};
    my $Follow = $obj->{Follow};
    my $rinVec = $obj->{rinVec};
    my $lastInode =  $obj->{lastInode};
    my $lastFsize =  $obj->{lastFsize};
    my $currSource = $obj->{currSource};
    my $line = $obj->{leftover};
    my $start_time = time;
    my $rows = [];

    my ($buf,$found_eof,$num_rows,$inode,$fsize);

    return 0 if (($fh eq '')||($rinVec eq ''));

    # Check to see if there's data ready to be read on the filehandle.
    my ($nfound, $timeleft) = select($rinVec, undef, undef, $ReadTimeout);

    # Keep reading data, as long as there's data to read, until we reach
    # the MaxReadTime value.
    while(($nfound > 0)&&(($start_time + $MaxReadTime) > time))
    {
        sysread($fh,$buf,$BUFFER_SIZE);

        # If nothing was returned, there we're at EOF
        if($buf eq '')
        {
            &log("No more data to read from '$currSource'") if ($VERBOSE > 1);

            # Try to open the next element in the source list.  If there isn't
            # another, then you're done.
            if($obj->open)
            {
                $fh = $obj->{fh};
                $rinVec = $obj->{rinVec};
                $currSource = $obj->{currSource};
            }
            # If we're in follow mode, and there's a lastInode value, then check
            # the inode and filesize.  If they've changed, then push the currSource
            # file back onto the SourceList array, set the EOF flag, and break out.
            elsif(($Follow)&&($lastInode ne ''))
            {
                ($inode,$fsize) = (stat $currSource)[1,7];
                if (($lastInode != $inode)||($lastFsize > $fsize))
                {
                    unshift(@{$obj->{SourceList}},$currSource);
                    $found_eof = 1;
                }

                $obj->{lastInode} = $inode;
                $obj->{lastFsize} = $fsize;
                last;
            }
            # Otherwise, set EOF if this is a child process or we're not in
            # follow mode, and then break out.
            else
            {
                $found_eof = 1 if (($obj->{pid})||(! $Follow));
                last;
            }
            last;
        }

        $line .= $buf;

        &log("Read from '$currSource':\n$buf") if ($VERBOSE > 3);
        ($nfound, $timeleft) = select($rinVec, undef, undef, $ReadTimeout);
    }

    # Split the retrieved data blob into rows
    @{$rows} = split(/\n/,$line . " ");
    $num_rows = @{$rows} - 1;

    # If we received only part of a line at the end of the data blob, then
    # save the rest for next time
    my $leftover = pop(@{$rows});
    $leftover =~ s/\s$//;
    $obj->{leftover} = $leftover;

    &log("Text leftover: $leftover") if (($VERBOSE > 1) && ($leftover ne ''));

    # Add the \n back onto the end of each line
    grep(s/$/\n/,@{$rows});

    ($rows,$found_eof);
}

# Simple get methods
sub getPid        { $_[0]->{pid}; }
sub getRetVal     { $_[0]->{retval}; }
sub getCurrSource { $_[0]->{currSource}; }

1;
__END__

=head1 NAME

VBTK::InputStream - Internal module of VBTK

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This is an internal module of the VB tool kit used to read from lists of files,
tail files, and run and capture the output from commands.  Do not try to access
this package directly.

=head1 SEE ALSO

=over 4

=item L<VBTK|VBTK>

=item L<VBTK::Parser|VBTK::Parser>

=item L<VBTK::ClientObject|VBTK::ClientObject>

=item L<VBTK::Server|VBTK::Server>

=back

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
