#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Objects/Rrd.pm,v $
#            $Revision: 1.7 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common library to simplify the interface between
#                       VB and Rrd
#
#           Directions:
#
#           Invoked by: VBTK::Parser
#
#           Depends on: VBTK::Common, rrd
#
#       Copyright (C) 1996 - 2002  Brent Henry
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of version 2 of the GNU General Public
#       License as published by the Free Software Foundation available at:
#       http://http://www.gnu.org/copyleft/gpl.html
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
#       $Log: Rrd.pm,v $
#       Revision 1.7  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.6  2002/03/04 16:49:10  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.5  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.4  2002/02/08 02:14:21  bhenry
#       *** empty log message ***
#
#       Revision 1.3  2002/01/25 16:41:33  bhenry
#       Changed to use 'serPut' instead of serialize
#
#       Revision 1.2  2002/01/21 17:07:50  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#
#

package VBTK::Rrd;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::File;
use Date::Manip;

# Import global variables from package main.
our $VERBOSE=$ENV{'VERBOSE'};

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:  Parameter hash
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my $type = shift;
    my $self = {};
    bless $self, $type;

    # Load in all passed parms    
    $self->set(@_);

    # Setup a hash of default parameters
    my $defaultParms = {
        RrdDbPath      => $::REQUIRED,
        RrdDbFile      => "$self->{RrdDbPath}/RRD.db",
        RrdDbMetaFile  => "$self->{RrdDbPath}/RRD.ser",
        Interval       => undef,
        Min            => 0,
        Max            => undef,
        CF             => "AVERAGE",
        XFF            => 0.5,
        DST            => "GAUGE",
        ForkRrdUpdate  => 0,
    };

    # Run the validation, setting defaults if values are not already set
    $self->validateParms($defaultParms) || return -1;

    &log("Creating Rrd object '$self->{RrdDbFile}'") if ($VERBOSE > 1);
    
    $self->{metaFileObj} = new VBTK::File($self->{RrdDbMetaFile});

    # Load in settings from prior transmissions - Not used right now
    # $self->loadMetaData;

    # Set default member values
    $self->{dataQueue} = [];

    return $self;
}

#-------------------------------------------------------------------------------
# Function:     addGraphDbData
# Description:  Add data to the Rrd database
# Input Parms:  Graph parms
# Output Parms: None
#-------------------------------------------------------------------------------
sub addGraphDbData
{
    my $self = shift;
    my %args = @_;

    my ($key);

    my $defaultParms = {
        Min            => undef,
        Max            => undef,
        XFF            => undef,
        CF             => undef,
        DST            => undef,
        DataQueue      => $::REQUIRED,
        Interval       => undef
    };

    # Run the validation, setting defaults if values are not already set
    &validateParms(\%args,$defaultParms) || return undef;

    # Now step through each value passed and use it to override the existing
    # parameters.
    foreach $key (%args)
    {
        $self->{$key} = $args{$key} if ($args{$key} ne undef);
    }

    $self->writeRrdDb || return undef;

    # Not doing anything right now, so we'll just comment it out
    #$self->saveMetaData;

    (1);
}

#-------------------------------------------------------------------------------
# Function:     createRrdDb
# Description:  Create an RrdDb
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub createRrdDb
{
    my $self = shift;
    my $RrdDbFile = $self->{RrdDbFile};

    # Just return if the filename hasn't been defined    
    return undef if (-f $RrdDbFile);

    my $Interval  = $self->{Interval};
    my $DST       = $self->{DST};
    my $Min       = $self->{Min};
    my $Max       = $self->{Max};
    my $CF        = $self->{CF};
    my $XFF       = $self->{XFF};
    my $DataQueue = $self->{DataQueue};

    # Look at the first data element to determine some variables
    my @firstRow = split(/:/,$DataQueue->[0]);
    my $colCount = @firstRow - 1;

    if ($colCount < 1)
    {
        &log("Not enough data passed to create RRD database, waiting till next round")
            if ($VERBOSE);
        return undef;
    }

    my $startTime = $firstRow[0] - 1;

    # Setup a default structure to provide standard graph ranges
    my %RRA        = ( 1  =>     60,        # $steps => $rows for RRA
                       1  =>   1440,        # assumes max 1200 pixel graph
                       7  =>   1440,        # "1440 7($Interval) samples" weekly RRA
                      14  =>   3131,        # "3131 14($Inverval) samples" monthly RRA
                     180  =>   2922         # "2922 180($Interval) samples" yearly RRA
                     );

    my $step       = $Interval;
    my $heartbeat  = $Interval * 2;
    my ($steps,$rows,$cmd,$pos);

    # Default Min and Max to unlimited if not specified
    $Min = "U" if ($Min eq undef);
    $Max = "U" if ($Max eq undef);

    &log("Creating new RrdDbFile - $RrdDbFile with step $step") if ($VERBOSE);

    # Start forming the command
    $cmd = "$::RRDBIN create $RrdDbFile --start $startTime --step $step";

    # Formulate the string for the DS names - DS:ds-name:DST:heartbeat:min:max
    for($pos=0; $pos < $colCount; $pos++)
    {
        $cmd .= " DS:ds$pos:$DST:$heartbeat:$Min:$Max";

        # create 5 RRAs with hard-coded values per data Column
        while (($steps,$rows) = each %RRA) 
        {
            $cmd .= " RRA:$CF:$XFF:$steps:$rows";
        }
    }

    # execute the whole command
    &log("Executing '$cmd'") if ($VERBOSE > 1);
    system("$cmd");

    if($? != 0)
    {
        &error("Non-zero exit code $? while executing '$cmd' - $!");
        return undef;
    }

    # Check to make sure the db file was created
    unless (-f $RrdDbFile)
    {
        &error("RrdDb was not created");
        return undef;
    }

    (1);
}

#-------------------------------------------------------------------------------
# Function:     writeRrdDb
# Description:  Write out the passed RRD Db Data
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub writeRrdDb
{
    my $self = shift;
    my $RrdDbFile     = $self->{RrdDbFile};
    my $DataQueue     = $self->{DataQueue};
    my $ForkRrdUpdate = $self->{ForkRrdUpdate};
    my ($timestamp,$pid);

    # If the db file doesn't exist then create it an return if there are 
    # any errors
    if (! -f $RrdDbFile)
    {
        $self->createRrdDb || return undef;
    }

    # Retrieve the last timestamp in the database
    my $lastTimestamp = $self->{lastTimestamp} || $self->getLastTimestamp;

    # Clear out any entries in the dataqueue which are <= the last timestamp
    while(@{$DataQueue} > 0)
    {
        ($timestamp) = split(/:/,$DataQueue->[0]);
        last if($timestamp > $lastTimestamp);

        &log("Warning: Ignoring graph data entry - $DataQueue->[0]");
        shift(@{$DataQueue});
    }

    # Don't save if nothing has changed
    return 1 if (@{$DataQueue} == 0);

    # Start the rrd update command string
    my @cmd = ($::RRDBIN,'update',$RrdDbFile);

    # Add on all the data
    push(@cmd,@{$DataQueue});

    # Fork?
    if($ForkRrdUpdate)
    {
        # Parent process
        if($pid = fork)
        {
            &log("Forked '@cmd' - pid $pid") if ($VERBOSE > 1);
        }
        # Child process
        elsif(defined $pid)
        {
            # Insulate this process from the vbc controller process
            setpgrp(0,$$);
    
            exec @cmd || &fatal("Could not start cmd '@cmd' - $!");
        }
        else
        {
            &error("Can't fork!");
        }
    }
    else
    {
        &log("Running '@cmd'") if ($VERBOSE > 1);
        system @cmd;
        my $exitVal = $? >> 8;
        &error("Call to $::RRDBIN failed with exit code $exitVal") if ($exitVal);
    }

    # Clear the data queue and store the last timestamp.
    my $lastEntry = pop(@{$DataQueue});
    ($self->{lastTimestamp}) = split(/:/,$lastEntry);

    @{$DataQueue} = ();

    (1);
}

#-------------------------------------------------------------------------------
# Function:     saveMetaData
# Description:  Save the meta data about this object which is not stored in the RRD
#               database into a file in the vbobj directory, so that if the
#               VB server is re-started, we don't lose the important graph settings
#               like 'labels', 'title', etc.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub saveMetaData
{
    my $self = shift;
    my $metaFileObj = $self->{metaFileObj};
    my $RrdDbMetaFile = $self->{RrdDbMetaFile};

    # Commented out all elements but decided to leave this in place in case
    # we need it later on.
    my $saveStruct = { };

    &log("Writing serialized metadata to '$RrdDbMetaFile'") if ($VERBOSE > 1);

    unless($metaFileObj->serPut($saveStruct))
    {
        &error("Can't save RRD meta data to $RrdDbMetaFile");
        return undef;
    }

    (1);
}

#-------------------------------------------------------------------------------
# Function:     loadMetaData
# Description:  Load the meta data for this object
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub loadMetaData
{
    my $self = shift;
    my $metaFileObj = $self->{metaFileObj};
    my $RrdDbMetaFile = $self->{RrdDbMetaFile};

    &log("Loading RRD metadata from '$RrdDbMetaFile'") if ($VERBOSE > 1);

    my $metaStruct = $metaFileObj->serGet() || return undef;

    # Load all the values into the object
    $self->set(%{$metaStruct});

    (1);
}

#-------------------------------------------------------------------------------
# Function:     generateGraph
# Description:  Generate the gif or png for the current object
# Input Parms:  None
# Output Parms: GraphData
#-------------------------------------------------------------------------------
sub generateGraph
{
    my $self = shift;
    my %args = @_;

    # Setup some defaults
    my $defaultParms = {
        DataSourceList => [],
        Labels         => $::REQUIRED,
        LineWidth      => 1,
        Colors         => '#0000FF,#00FF00,#FF0000,#CC00FF,#000000,#CC0000,' .
                          '#00FFFF,#990000,#996600,#999999',
        CF             => 'AVERAGE',
        VLabel         => undef,
        Title          => undef,
        TimeWindow     => '1day',
        XSize          => 600,
        YSize          => 60
    };

    # Apply the defaults and verify the inputs
    &validateParms(\%args,$defaultParms) || return undef;

    # Define scope of local variables    
    my ($pos,$vName,$dsName,$color,$label,$vCmd,$GPrint,$cmd,$lCmd,$source);
    my ($sourceObj,$sourceObjName,$sourceRrdObj,$sourceRrdDbFile,$dsNum,$vnNum);

    # Calculate starting and ending times in unix time format.
    my $end = time;
    my $startTimestamp = &DateCalc("today","- $args{TimeWindow}");
    my $start = &unixdate($startTimestamp);

    # Escape out any " characters in the Title or VLabel parms
    $args{Title} =~ s/"/\\"/;
    $args{VLabel} =~ s/"/\\"/;

    # begin cmd string for rrdtool
    $cmd  = "$::RRDBIN graph - -s $start -e $end -c BACK#CCCCFF ";
    $cmd .= "-t \"$args{Title}\" " if ($args{YSize} >= 100);
    $cmd .= "-w $args{XSize} -h $args{YSize} -a PNG ";
    $cmd .= "-v \"$args{VLabel}\" " if ($args{VLabel} ne undef);
    $cmd .= "\"COMMENT:$args{Title}\:\" " if ($args{YSize} < 100);

    # Check to see if the Labels, Colors, and DataSourceList parms are array references.
    # If not then turn them it one by splitting them.
    my $Labels = (ref($args{Labels}) eq 'ARRAY') ?
        $args{Labels} : [ split(/[,]/,$args{Labels}) ];
    my $Colors = (ref($args{Colors}) eq 'ARRAY') ?
        $args{Colors} : [ split(/[,]/,$args{Colors}) ];
    my $DataSourceList = (ref($args{DataSourceList}) eq 'ARRAY') ?
        $args{DataSourceList} : [ split(/[,]/,$args{DataSourceList}) ];

    my $colCount = @{$Labels};

    # Now setup DEF and LINE attrib for each column in the database to be 
    # graphed
    foreach $pos (0..$#{$Labels}) 
    {
        $color     = $Colors->[$pos];
        $label     = $Labels->[$pos];
        $source    = $DataSourceList->[$pos];
        $dsNum     = $pos;
        $vnNum     = $pos;

        # Escape out any ' characters in the label
        $label =~ s/"/\\"/;

        if($source =~ /^(.*):(\d+)$/)
        {
            ($sourceObjName,$dsNum) = ($1,$2);
        }
        elsif($source ne undef)
        {
            &error("Invalid data source '$source' specified");
            return undef;
        }

        if($sourceObjName ne undef)
        {
            $sourceObj = &VBTK::Objects::FindObjByName($sourceObjName) || return undef;
            $sourceRrdObj = $sourceObj->getRrdObj || return undef;
            $sourceRrdDbFile = $sourceRrdObj->getRrdDbFile || return undef;
        }
        else
        {
            $sourceRrdDbFile = $self->{RrdDbFile};
        }

        if (! -f $sourceRrdDbFile)
        {
            &error("Reference to non-existant Rrd DB file '$sourceRrdDbFile'");
            return undef;
        }

        $vName     = "vn$vnNum";
        $dsName    = "ds$dsNum";

        $vCmd      = "DEF:$vName=$sourceRrdDbFile:$dsName:$args{CF} ";

        # If there's only one label, then do a line graph, otherwise, do an
        # area graph.
        $lCmd = ($colCount > 1) ?
            "\"LINE$args{LineWidth}:$vName$color:$label\" " :
            "\"AREA:$vName$color:$label\" ";

        $GPrint    = "\"GPRINT:$vName:LAST:%3.2lf%s\" ";
        $cmd .= " $vCmd $lCmd $GPrint";
    }

    # Execute the command
    &log("Executing '$cmd'") if ($VERBOSE > 1);
    my $pngData = `$cmd`;

    if($? != 0)
    {
        &error("Non-zero exit code $? while executing '$cmd' - $!");
        return undef;
    }

    ($pngData);
}

#-------------------------------------------------------------------------------
# Function:     canGraph
# Description:  Return true or false indicating if this object can generate 
#               graphs, meaning that the RrdDbFile exists.
# Input Parms:  None
# Output Parms: GraphData
#-------------------------------------------------------------------------------
sub canGraph
{
    my $self = shift;
    my $RrdDbFile     = $self->{RrdDbFile};

    # Just return if the filename hasn't been defined    
    return undef if (! -f $RrdDbFile);

    (1);
}

#-------------------------------------------------------------------------------
# Function:     getLastTimestamp
# Description:  Retrieve the last RrdDb timestamp
# Input Parms:  None
# Output Parms: Timestamp
#-------------------------------------------------------------------------------
sub getLastTimestamp
{
    my $self = shift;
    my $RrdDbFile = $self->{RrdDbFile};

    return 1 if (! -f $RrdDbFile);

    # Use 'rrdtool last' to get time stamp of most recent rrddb entry
    &log("Retrieving last timestamp from '$RrdDbFile'") if ($VERBOSE > 1);

    my $cmd = "$::RRDBIN last $RrdDbFile";
    my $lastTimestamp = `$cmd`;

    if($? != 0)
    {
        &error("Non-zero exit code $? while executing '$cmd' - $!");
        return undef;
    }

    chomp($lastTimestamp);

    &log("lastTimestamp is $lastTimestamp") if ($VERBOSE > 1);
    $self->{lastTimestamp} = $lastTimestamp;

    ($lastTimestamp);
}

# Simple Get Methods
sub getRrdDbFile     { $_[0]->{RrdDbFile}; }

1;
__END__

=head1 NAME

VBTK::Objects::Rrd - Internal module of VBTK

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This is an internal module of the VB tool kit used to handle interaction
with RRD databases.  Do not try to access this package directly.

=head1 SEE ALSO

=over 4

=item L<VBTK|VBTK>

=item L<VBTK::Objects|VBTK::Objects>

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
