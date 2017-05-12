#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/File.pm,v $
#            $Revision: 1.12 $
#                $Date: 2002/03/04 20:53:06 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A perl library used to handle interaction with
#                       files.
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
#       $Log: File.pm,v $
#       Revision 1.12  2002/03/04 20:53:06  bhenry
#       *** empty log message ***
#
#       Revision 1.11  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.10  2002/03/02 00:53:54  bhenry
#       Documentation updates
#
#       Revision 1.9  2002/02/20 19:25:18  bhenry
#       *** empty log message ***
#
#       Revision 1.8  2002/02/19 19:06:44  bhenry
#       *** empty log message ***
#
#       Revision 1.7  2002/02/13 07:41:43  bhenry
#       *** empty log message ***
#
#       Revision 1.6  2002/02/09 08:46:28  bhenry
#       Added several methods to assist in syncing files
#
#       Revision 1.5  2002/02/08 02:15:26  bhenry
#       Stopped closing STDOUT, so output wouldn't get chopped off
#
#       Revision 1.4  2002/01/25 07:17:15  bhenry
#       Added serPut and serGet methods
#
#

require 5.004;

package VBTK::File;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use FileHandle;
use Algorithm::Diff qw(diff);
use File::Basename;
use File::Path;
use Storable qw(store retrieve);

our $VERBOSE=$ENV{'VERBOSE'};

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

    my ($fileName) = @_;

    log("Setting up FileCache object for '$fileName'") if ($VERBOSE > 3);

    # Store the file name    
    $self->setFileName($fileName);
    $self->{basePath} = $::VBHOME;

    return $self;
}

#-------------------------------------------------------------------------------
# Function:     getCache
# Description:  Retrieve the contents of the associated file, using cached data
#               if possible.
# Input Parms:  None
# Output Parms: Contents of file
#-------------------------------------------------------------------------------
sub getCache
{
    my $self = shift;

    $self->load() || return undef;
    $self->{contents};
}

#-------------------------------------------------------------------------------
# Function:     load
# Description:  Load the file contents into the object, only after checking to 
#               see if it changed since the last time.
# Input Parms:  None
# Output Parms: Return code 1 - Success, or 0 - Failure
#-------------------------------------------------------------------------------
sub load
{
    my $self = shift;
    my $fileName  = $self->{fileName};
    my $contents  = $self->{contents};
    my $mtime     = $self->{mtime};
    my $size      = $self->{size};

    my ($currSize,$currMtime) = (stat($fileName))[7,9];

    # Check for file access error
    if (! defined $currSize)
    {
        &error("Can't stat file '$fileName'");
        return 0;
    }

    # If the file has changed, or the contents were never loaded, then reload 
    # the contents
    if ((! defined $contents)||($currMtime != $mtime)||($currSize != $size))
    {
        $contents = $self->get;
        return 0 if (! defined $contents);

        $self->{contents} = $contents;
        $self->{mtime} = $currMtime;
        $self->{size} = $currSize;
    }

    1;
}

#-------------------------------------------------------------------------------
# Function:     loadStat
# Description:  Run stat and retrieve the size and mtime of the file.  Store them
#               in the object.
# Input Parms:  None
# Output Parms: size, mtime
#-------------------------------------------------------------------------------
sub loadStat
{
    my $self = shift;
    my $fileName = $self->{fileName};
    
    my ($size,$mtime) = (stat($fileName))[7,9];
    
    $self->{mtime} = $mtime;
    $self->{size} = $size;
    
    ($size,$mtime);
}

#-------------------------------------------------------------------------------
# Function:     hasChanged
# Description:  Run stat and compare the current mtime and size with the stored
#               mtime and size.
# Input Parms:  None
# Output Parms: 1 or 0.
#-------------------------------------------------------------------------------
sub hasChanged
{
    my $self = shift;
    my $fileName = $self->{fileName};

    # Try to load the file now, if it's not already loaded
    if (! defined $self->{mtime}) 
    {
        $self->loadStat() || return 0;
    }
 
    my $mtime   = $self->{mtime};
    my $size     = $self->{size};
    my $target  = shift || $fileName;
    my $dirName = &dirname($target);

    &log("Checking to see if '$target' has changed") if ($VERBOSE > 2);
    
    my ($currSize,$currMtime) = (stat($target))[7,9];

    if(($currSize != $size)||($currMtime != $mtime))
    {
        &log("File '$target' has changed or does not exist") if ($VERBOSE > 2);
        (1);
    }
    else
    {
        (0);
    }
}

#-------------------------------------------------------------------------------
# Function:     isNewer
# Description:  Run stat and compare the current mtime with the stored mtime.
# Input Parms:  None
# Output Parms: 1 or 0.
#-------------------------------------------------------------------------------
sub isNewer
{
    my $self = shift;
    my $fileName = $self->{fileName};
    my $mtime    = $self->{mtime};

    &log("Checking to see if '$fileName' is newer") if ($VERBOSE > 2);
    
    my ($currSize,$currMtime) = (stat($fileName))[7,9];

    if($currMtime > $mtime)
    {
        &log("File '$fileName' is newer than original file") if ($VERBOSE > 2);
        (1);
    }
    else
    {
        (0);
    }
}

#-------------------------------------------------------------------------------
# Function:     exists
# Description:  Check to see if the associated file exists
# Input Parms:  None
# Output Parms: Contents of file
#-------------------------------------------------------------------------------
sub exists
{
    my $self = shift;
    my $fileName  = $self->{fileName};

    (-f $fileName);
}

#-------------------------------------------------------------------------------
# Function:     get
# Description:  Retrieve the contents of the associated file.
# Input Parms:  None
# Output Parms: Contents of file
#-------------------------------------------------------------------------------
sub get
{
    my $self = shift;
    my $fileName  = $self->{fileName};
    my ($fh);

    $fh = new FileHandle "< $fileName";

    unless (defined $fh)
    {
        &error("Can't open file '$fileName'");
        return undef;
    }

    # Slurp mode
    local $/;

    my $contents = <$fh>;
    $fh->close;

    ($contents);
}

#-------------------------------------------------------------------------------
# Function:     serGet
# Description:  Retrieve data from the specified file and attempt to thaw it into
#               a reference.
# Input Parms:  None
# Output Parms: Reference to thawed structure
#-------------------------------------------------------------------------------
sub serGet
{
    my $self = shift;
    my $fileName = $self->{fileName};
    
    my $ref = retrieve($fileName);
    
    ($ref);
}

#-------------------------------------------------------------------------------
# Function:     put
# Description:  Write out the passed text to the associated file.
# Input Parms:  File text
# Output Parms: None
#-------------------------------------------------------------------------------
sub put
{
    my $self = shift;
    my $fileName  = $self->{fileName};
    my $baseName  = $self->{baseName};
    my $dirName   = $self->{dirName};

    my (@data) = @_;

    my $suffix=$$;
    my ($tmpFile);
    
    # Come up with a non-existant tempfile name
    do { $tmpFile = "$dirName/.tmp$baseName." . $suffix++; } while (-f $tmpFile);

    &log("Writing to '$tmpFile'") if ($VERBOSE > 2);

    # Open the filehandle
    my $fh = new FileHandle "> $tmpFile";

    # Check for errors
    unless ($fh)
    {
        &error("Can't write to file '$tmpFile'");
        return undef;
    }

    # Step through each data element passed, dumping it out
    # to a file.
    foreach (@data)
    {
        print $fh (ref($_)) ? join('',@{$_}) : $_;
    }

    $fh->close;        

    &log("Renaming '$tmpFile' to '$fileName'") if ($VERBOSE > 2);

    # Now rename the temp file to the original filename    
    unless( rename $tmpFile, $fileName )
    {
        &error("Can't rename '$tmpFile' to '$fileName'");
        return undef;
    }

    # Clear out the object members related to the file    
    $self->{contents} = undef;
    $self->{mtime} = undef;
    $self->{size} = undef;

    (1);
}

#-------------------------------------------------------------------------------
# Function:     sync
# Description:  Sync the local file using the data in the object structure.  This
#               includes updating the contents and mtime.
# Input Parms:  None
# Output Parms: Success - 1 or Failure - 0
#-------------------------------------------------------------------------------
sub sync
{
    my $self = shift;
    my $fileName  = $self->{fileName};

    # Try to load the file now, if it's not already loaded
    if (! defined $self->{mtime} || ! defined $self->{contents}) 
    {
        $self->load() || return 0;
    }

    my $mtime   = $self->{mtime};
    my $target  = shift || $fileName;
    my $dirName = &dirname($target);

    my ($fh);

    &log("Attempting to sync '$target'") if ($VERBOSE > 1);

    if((! -d $dirName)&&(mkpath([$dirName]))&&(! -d $dirName))
    {
        &error("Can't create directory '$dirName'");
        return 0;
    }

    # Dump the contents of the object to the file    
    unless($fh = new FileHandle "> $target")
    {
        &error("Can't write to '$target', skipping sync");
        return 0;
    }
    
    print $fh $self->{contents};
    $fh->close();

    # Now update the mtime on the file
    unless( utime $mtime, $mtime, $target )
    {
        &error("Can't update mtime on '$target'");
        return 0;
    }

    1;
}

#-------------------------------------------------------------------------------
# Function:     serPut
# Description:  Serialize the passed reference and write the result out to the
#               specified file.
# Input Parms:  Reference to data structure
# Output Parms: None
#-------------------------------------------------------------------------------
sub serPut
{
    my $self = shift;
    my $fileName  = $self->{fileName};
    my $baseName  = $self->{baseName};
    my $dirName   = $self->{dirName};

    my ($ref) = @_;

    my $suffix=$$;
    my ($tmpFile);

    # Come up with a non-existant tempfile name
    do { $tmpFile = "$dirName/.tmp$baseName." . $suffix++; } while (-f $tmpFile);

    &log("Writing to '$tmpFile'") if ($VERBOSE > 2);

    # Open the filehandle
    unless(&store ($ref,$tmpFile))
    {
        &error("Can't write to file '$tmpFile'");
        return undef;
    }

    &log("Renaming '$tmpFile' to '$fileName'") if ($VERBOSE > 2);

    # Now rename the temp file to the original filename    
    unless( rename $tmpFile, $fileName )
    {
        &error("Can't rename '$tmpFile' to '$fileName'");
        return undef;
    }

    # Clear out the object members related to the file    
    $self->{contents} = undef;
    $self->{mtime} = undef;
    $self->{size} = undef;

    (1);
}

#-------------------------------------------------------------------------------
# Function:     unlink
# Description:  Delete the associated file.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub unlink
{
    my $self = shift;
    my $fileName = $self->{fileName};

    unlink $fileName;
}

#-------------------------------------------------------------------------------
# Function:     doDiff
# Description:  Run a unix diff between this object's file and the passed text
# Input Parms:  Text to compare with
# Output Parms: Output of diff
#-------------------------------------------------------------------------------
sub doDiff
{
    my $self = shift;
    my $cmpText = shift;
    my $objText = $self->get || return undef;
    my ($chunk,$line,$diffText,$sign,$lineno,$text);

    my @objLines = split(/\n/,$objText);
    my @cmpLines = split(/\n/,$cmpText);

    my $diffList = diff(\@objLines, \@cmpLines);

    foreach $chunk (@$diffList) 
    {
        foreach $line (@$chunk) 
        {
            ($sign, $lineno, $text) = @$line;
            $diffText .= sprintf "%4d$sign %s\n", $lineno+1, $text;
        }
        $diffText .= "--------\n";
    }
    $diffText;
}    

#-------------------------------------------------------------------------------
# Function:     setFileName
# Description:  Override the filename of the object to be the passed value.
# Input Parms:  FileName
# Output Parms: None
#-------------------------------------------------------------------------------
sub setFileName
{
    my $self = shift || return undef;
    my $fileName = shift || return undef;

    $self->{fileName} = $fileName;
    $self->{baseName} = &basename($fileName);
    $self->{dirName} = &dirname($fileName);
    
    (1);
}

#-------------------------------------------------------------------------------
# Function:     setBasePath
# Description:  Store a base path for the file
# Input Parms:  Base Path
# Output Parms: None
#-------------------------------------------------------------------------------
sub setBasePath
{
    my $self = shift || return undef;
    $self->{basePath} = shift || return undef;
    
    (1);
}

#-------------------------------------------------------------------------------
# Function:     changeBasePath
# Description:  Check to see if the passed base path is the same as the original
#               base path.  If not, then change the path of the filename to use
#               the new base path.
# Input Parms:  New Base Path
# Output Parms: None
#-------------------------------------------------------------------------------
sub changeBasePath
{
    my $self = shift;
    my $newBasePath = shift;
    my $origBasePath = $self->{basePath};
    my $fileName = $self->{fileName};
    
    return 1 if ($newBasePath eq $origBasePath);
    
    unless($origBasePath)
    {
        &error("Can't change base path when origBasePath was never set!");
        return undef;
    }
    
    unless($fileName =~ s/^$origBasePath/$newBasePath/)
    {
        &error("Invalid base path '$origBasePath' specified for '$fileName'");
        return undef;
    }

    # Store the original filename as well as the new
    $self->{origFileName} = $self->{fileName};
    $self->setFileName($fileName);
    
    &log("Altered base path from '$self->{origFileName}' to '$fileName'") 
        if ($VERBOSE > 2);   

    (1);
}

# Simple get methods
sub getBaseName     { $_[0]->{baseName}; }
sub getDirName      { $_[0]->{dirName}; }
sub getFileName     { $_[0]->{fileName}; }
sub getOrigFileName { $_[0]->{origFileName} || $_[0]->{fileName}; }
sub getMtime        { $_[0]->{mtime}; }
sub getSize         { $_[0]->{size}; }
sub getContents     { $_[0]->{contents}; }

1;
__END__

=head1 NAME

VBTK::File - Internal module of VBTK

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This is an internal module of the VB tool kit used to read/write meta-data
files in the VBOBJ database area.  Do not try to access this package
directly.

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
