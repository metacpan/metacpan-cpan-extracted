#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Wrapper/DiskFree.pm,v $
#            $Revision: 1.10 $
#                $Date: 2002/03/04 20:53:08 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A an extension of VBTK::Wrapper used to monitor disk
#                       space on unix systems.
#
#           Depends on: VBTK::Common, VBTK::Wrapper
#
#       Copyright (C) 1996 - 2002 Brent Henry
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
#       $Log: DiskFree.pm,v $
#       Revision 1.10  2002/03/04 20:53:08  bhenry
#       *** empty log message ***
#
#       Revision 1.9  2002/03/04 16:49:10  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.8  2002/03/02 00:53:56  bhenry
#       Documentation updates
#
#       Revision 1.7  2002/02/13 08:01:57  bhenry
#       *** empty log message ***
#
#       Revision 1.6  2002/02/13 07:36:14  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#

package VBTK::Wrapper::DiskFree;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::Wrapper;
use VBTK::Parser;

# Inherit methods from VBTK::Wrapper;
our @ISA=qw(VBTK::Wrapper);

our $VERBOSE = $ENV{VERBOSE};

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my $type = shift;
    my $self = {};
    bless $self, $type;

    # Store all passed input name pairs in the object
    $self->set(@_);

    # Setup defaults
    my $stdHeader =
     [ 'Time               Mount                          MB   Used  Avail  Pct',
       '------------------ -------------------------- ------ ------ ------ ----' ];
    my $stdDetail =
     [ '@<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>> @>>>>> @>>>>> @>>>',
       '$time, $data[5], int($data[1]/1024), int($data[2]/1024), int($data[3]/1024), $data[4]' ];

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval          => 300,
        Execute           => "df -k 2>&1",
        SourceList        => undef,
        VBServerURI       => $::VBURI,
        VBHeader          => $stdHeader,
        VBDetail          => $stdDetail,
        LogFile           => undef,
        LogHeader         => $stdHeader,
        LogDetail         => $stdDetail,
        RotateLogAt       => undef,
        RotateLogOnEOF    => undef,
        Split             => '[\s\%]+',
        Filter            => '^/dev|^[A-Za-z]:\s+',
        Ignore            => '/cdrom', 
        SkipLines         => undef,
        Timeout           => 60,
        TimeoutStatus     => 'Fail',
        Follow            => undef,
        FollowTimeout     => undef,
        FollowHeartbeat   => undef,
        NonZeroExitStatus => 'Warn',
        DebugHeader       => 'df'
    };

    # Run a validation on the passed parms, using the default parms        
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Check to see if 'df' is executable
    if($self->{Execute} =~ /^\s*(\S+).*\|\s*$/)
    {
        my $progName = $1;   
        unless (-x $progName)
        {
            &log("Can't execute '$progName', skipping");
            return undef;
        }
    }        

    # Initialize a wrapper object.
    $self->SUPER::new() || return undef;

    # Store the defaults for later
    $self->{defaultParms} = $defaultParms;

    ($self);
}

#-------------------------------------------------------------------------------
# Function:     addVBObj
# Description:  Add a VB object to the wrapper object.
# Input Parms:
# Output Parms: None
#-------------------------------------------------------------------------------
sub addVBObj
{
    my $self = shift;
    my $Interval   = $self->{Interval};
    my %args = @_;

    my $expireAfterSec = int($Interval * 3);
    my $description = qq( 
        This object uses the 'df' command to monitor the disk utilization
        on $::HOST.  It will set the status to 'Warning' or 'Failed' based on the
        amount of free disk space on the local filesystems.
    );

    # Setup a hash of default rules to be returned
    my $defaultRules = {
        VBObjName           => ".$::HOST.diskfree",
        TextHistoryLimit    => 50,
        ReverseText         => 1,
        Rules               => {
            '($data[4] > 90)' => 'Warn',
            '($data[4] > 95)' => 'Fail' },
        Requirements        => undef,
        StatusHistoryLimit  => 30,
        StatusChangeActions => undef, 
        StatusUpgradeRules  => undef,
        ExpireAfter         => "$expireAfterSec seconds",
        Description         => $description,
        BaselineDiffStatus  => undef,
        RrdTimeCol          => undef,
        RrdColumns          => [ 'int($data[4])' ],
        RrdFilter           => undef,
        RrdMin              => 0,
        RrdMax              => undef,
        RrdXFF              => undef,
        RrdCF               => 'MAX',
        RrdDST              => undef,
    };


    # Run the validation    
    &validateParms(\%args,$defaultRules) || &fatal("Exiting");

    my ($row,$fsMount,$objName,@data,$result,$vbObj);

    # Clone the wrapper object and run the clone once so we can get a look at the
    # output.
    my $clone = $self->dclone;
    $clone->set(Interval => undef);
    &VBTK::runAll($clone);
    my $lastRows = $clone->getLastRows;

    # Make sure we got some data back
    if (@{$lastRows} < 1)
    {
        &error("Can't setup objects for VBTK::Wrapper::Diskfree, because no data " .
            "was returned from call to $self->{Execute}");
        return undef;
    }

    # Store the base objectname so we can add to it
    my $baseObjName = $args{VBObjName};

    my (@dataSourceList,@labels);

    # Create one VB object for each filesystem
    foreach $row (@{$lastRows})
    {
        # Get the mount point
        $fsMount = $objName = $row->[5];

        # Convert all the '/' to '-' so we don't have any '/' in the object name
        $objName =~ s:^/::g;
        $objName =~ s:/:-:g;
        $objName = 'root' if ($objName eq '');

        # Override parms which vary between objects        
        $args{VBObjName} = "$baseObjName.$objName";
        $args{Filter} = $args{RrdFilter} = "\$data[5] eq '$fsMount'";

        # Add the rule
        $vbObj = $self->SUPER::addVBObj(%args) || return undef;

        # Now Define what graphs will show up with this object        
        $vbObj->addGraphGroup (
            GroupNumber    => 1,
            DataSourceList => undef,
            Labels         => 'pct-utilization',
            Title          => "Disk Utilization on $::HOST, $fsMount",
            CF             => 'MAX',
        );

        # Store some values to be used in graphGroup 2
        push(@dataSourceList,"$baseObjName.$objName:0");
        push(@labels,"$fsMount");
    }

    # Now make an 'addGraphGroup' call to the wrapper object.  This will pass
    # along this graph definition to all the VB objects associated with it.
    $self->addGraphGroup (
        GroupNumber     => 2,
        DataSourceList  => join(',',@dataSourceList),
        Labels          => join(',',@labels),
        Title           => "Disk Utilization on $::HOST",
        CF              => 'MAX'
    );

    $self->{defaultRules} = $defaultRules;

    (0);
}

1;
__END__

=head1 NAME

VBTK::Wrapper::DiskFree - Sun hardware disk space monitoring with 'df'

=head1 SYNOPSIS

  # If you like all the defaults, then there's no need to over-ride them.
  $o = new VBTK::Wrapper::DiskFree ();
  $vbObj = $o->addVBObj();

  VBTK::runAll;

=head1 DESCRIPTION

This perl library is a front-end to the L<VBTK::Wrapper|VBTK::Wrapper> class. 
It supports the same public methods as the VBTK::Wrapper class, but with common
defaults to simplify the setup of a 'df' monitoring process.

=head1 METHODS

The following methods are supported

=over 4

=item $o = new VBTK::Wrapper::DiskFree (<parm1> => <val1>, <parm2> => <val2>, ...)

::TBD::

This method calls 'new L<VBTK::Wrapper|VBTK::Wrapper>' after defaulting
the parameters to best monitor the 'df' command.  For a detailed description
of the parameters, see L<VBTK::Wrapper>.  The defaults are as follows.  If you
like all the defaults then you don't have to pass in any parms.

=over 4

=item Interval

    Interval => 300,

=item Execute

    Execute => '/usr/bin/df -k 2>&1',

=item VBHeader

    VBHeader => [ 
        'Time               Mount                          MB   Used  Avail  Pct',
        '------------------ -------------------------- ------ ------ ------ ----' ],

=item VBDetail

    VBDetail => [ 
        '@<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>> @>>>>> @>>>>> @>>>',
        '$time, $data[5], int($data[1]/1024), int($data[2]/1024), int($data[3]/1024), $data[4]' ],

=item LogHeader

Same as VBHeader, but used for the log file.

=item LogDetail

Same as VBDetail, but used for the log file.

=item Split

    Split => '\s+',

=item Filter

Only accept the lines which begin in '/dev' (Unix) or '<x>:' (Windows).   

    Filter => '^/dev|^[A-Za-z]:\s+',

=item Ignore

Ignore the CD-rom drive if it shows up in the output

    Ignore => '/cdrom',

=item Timeout

    Timeout => 60,

=item TimeoutStatus

    TimeoutStatus => 'Fail',

=item NonZeroExitStatus

    NonZeroExitStatus => 'Warn',

=item DebugHeader

    DebugHeader => 'prtdiag',

=back

=item $vbObj = $o->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

This method runs the above wrapper object once to determine how many filesystems
reside on the local host.  For each filesystem found, a separate VB object is
created by calling VBTK::Wrapper::addVBObj after defaulting unspecified
parameters to best monitor diskspace with the 'df' command.  For a detailed description
of the addVBObj parameters, see L<VBTK::Parser>.  The defaults are as follows.
If you like all the defaults then you don't have to pass in any parms

=over 4

=item VBObjName

Name the VBObject using the local host's name.

    VBObjName => ".<Host>.diskfree.<filesystem>",

=item TextHistoryLimit

    TextHistoryLimit => 50,

=item ReverseText

    ReverseText => 1,

=item Rules

If space used exceeds 90%, set to warn.  If above 95%, set to Failed.

    Rules => {
        '($data[4] > 90)' => 'Warn',
        '($data[4] > 95)' => 'Fail' },

=item StatusHistoryLimit

Limit to storing the last 30 status changes

    StatusHistoryLimit => 30,

=item ExpireAfter

    ExpireAfter => "(<Interval> * 3) seconds"

=item Description

    Description = qq(
        This object uses the 'df' command to monitor the disk utilization on
        $::HOST.  It will set the status to 'Warning' or 'Failed' based on the
        amount of free disk space on the local filesystems. ),

=item RrdColumns

Graph the pct utilization for each filesytem.

    RrdColumns => [ 'int($data[4])' ],

=item RrdMin

    RrdMin => 0,

=item RrdCF

Use the 'MAX' consolidation function so that we see peaks, rather than averages,
in the graphs.

    RrdCF => 'MAX',

=back

In addition to passing these defaults on in a call to VBTK::Wrapper::addVBObj,
this method captures the resulting VBTK::ClientObject pointer ($vbObj) and 
makes the following call to '$vbObj->addGraphGroup':

  $vbObj->addGraphGroup (
    GroupNumber    => 1,
    Labels         => 'pct-utilization',
    Title          => 'Disk Utilization on <Host>, <filesystem>',
    CF             => 'MAX',
  );

This defines a graphGroup for the VBObject.  See L<VBTK::ClientObject> for
details on the 'addGraphGroup' method.

A second call to 'addGraphGroup' is then made which combines all filesystems
for this host into a single graph group.

  $vbObj->addGraphGroup (
    GroupNumber    => 2,
    DataSourceList => <built from list of filesystems>,
    Labels         => <build from list of filesystems>,
    Title          => "Disk Utilization on <Host>",
    CF             => 'MAX',
  );

=back

=head1 SEE ALSO

L<VBTK|VBTK>,
L<VBTK::Wrapper|VBTK::Wrapper>,
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
http://http://www.gnu.org/copyleft/gpl.html

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
