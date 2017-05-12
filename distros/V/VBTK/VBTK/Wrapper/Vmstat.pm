#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Wrapper/Vmstat.pm,v $
#            $Revision: 1.9 $
#                $Date: 2002/03/04 20:53:08 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: An extension of VBTK::Wrapper for use in running vmstat
#
#           Depends on: VBTK::Common, VBTK::Wrapper
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
#       $Log: Vmstat.pm,v $
#       Revision 1.9  2002/03/04 20:53:08  bhenry
#       *** empty log message ***
#
#       Revision 1.8  2002/03/04 16:49:10  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.7  2002/03/02 00:53:56  bhenry
#       Documentation updates
#
#       Revision 1.6  2002/02/20 20:41:35  bhenry
#       *** empty log message ***
#
#       Revision 1.5  2002/02/13 07:36:14  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#       Revision 1.4  2002/01/26 06:15:15  bhenry
#       Changed to not specify absolute path
#
#       Revision 1.3  2002/01/25 07:11:52  bhenry
#       Changed to inherit from Wrapper
#
#       Revision 1.2  2002/01/21 17:07:56  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#

package VBTK::Wrapper::Vmstat;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::Wrapper;

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

    # Setup a default interval
    my $interval = 60;

    # Setup a standard header and detail line for use in the VBObject and logs.
    my $stdHeader = 
        [ '                   procs     memory            page            disk          faults      cpu',
          '        time       r b w   swap  free  re  mf pi po fr de sr s0 s6 sd sd   in   sy   cs us sy id' ];
    my $stdDetail = [ '$time $data' ];

    # Try to run psrinfo to count the number of CPU's    
    my $numCpus = 1;
    if (-x "/usr/sbin/psrinfo")
    {
        $numCpus = `/usr/sbin/psrinfo | /usr/bin/wc -l`;
        $numCpus =~ s/\s+//g;
    }

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval          => $interval,
        Execute           => "vmstat $interval",
        SourceList        => undef,
        VBServerURI       => $::VBURI,
        VBHeader          => $stdHeader,
        VBDetail          => $stdDetail,
        LogFile           => undef,
        LogHeader         => $stdHeader,
        LogDetail         => $stdDetail,
        RotateLogAt       => '12:00am',
        RotateLogOnEOF    => undef,
        Split             => '\s+',
        Filter            => '^\s*\d+[^a-zA-Z]*$',
        Ignore            => undef,
        SkipLines         => 3,
        Timeout           => undef,
        TimeoutStatus     => undef,
        Follow            => 1,
        FollowTimeout     => ((2 * $interval) + 10),
        FollowHeartbeat   => undef,
        SetRunStatus      => undef,
        NonZeroExitStatus => undef,
        SuppressStdout    => undef,
        SuppressMessages  => undef,
        DebugHeader       => 'vmstat',
        NumCpus           => $numCpus 
    };

    # Run the validation, setting defaults if values are not already set
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Temporarily remove parms which we don't want to pass on to the real wrapper.
    delete $self->{NumCpus};

    # Initialize a wrapper object.
    $self->SUPER::new() || return undef;

    # Store the default parms
    $self->{defaultParms} = $defaultParms;
    $self->{NumCpus}      = $numCpus;

    ($self);
}

#-------------------------------------------------------------------------------
# Function:     addVBObj
# Description:  Add a vb object to the wrapper object.
# Input Parms:
# Output Parms: None
#-------------------------------------------------------------------------------
sub addVBObj
{
    my $self = shift;
    my $NumCpus    = $self->{NumCpus};
    my $Interval   = $self->{Interval};
    my %args = @_;

    # Setup some reasonable thresholds        
    my $warnRunQueue = $NumCpus;
    my $failRunQueue = $NumCpus * 4;
    my $expireAfterSec = int($Interval * 3);
    my $description = qq( 
        This object uses the 'vmstat' command to monitor the CPU utilization
        on $::HOST.  It will set the status to 'Warning' or 'Failed' based on the
        value of the run queue and the CPU idle time.
    );

    # Setup a hash of rules to be returned
    my $defaultRules = {
        VBObjName           => ".$::HOST.cpu",
        TextHistoryLimit    => 100,
        ReverseText         => 1,
        Rules               => {
             "(\$data[1] > $warnRunQueue)" => 'Warn',
             "(\$data[1] > $failRunQueue)" => 'Fail' },
        Requirements        => undef,
        StatusHistoryLimit  => 30,
        StatusChangeActions => undef, 
        StatusUpgradeRules  => undef,
        ExpireAfter         => "$expireAfterSec seconds",
        Description         => $description,
        RrdTimeCol          => undef,
        RrdColumns          => [ '$data[20]', '$data[21]', '$data[1]', '$data[12]' ],
        RrdFilter           => undef,
        RrdMin              => undef,
        RrdMax              => undef,
        RrdXFF              => undef,
        RrdCF               => undef,
        RrdDST              => undef,
    };

    # Run the validation    
    &validateParms(\%args,$defaultRules) || &fatal("Exiting");

    # Add the rule
    my $vbObj = $self->SUPER::addVBObj(%args) || return undef;

    # Now define what graphs to show on this object's page
    $vbObj->addGraphGroup (
        GroupNumber    => 1,
        DataSourceList => undef,
        Labels         => 'user,system,runQueue,scanRate',
        LineWidth      => undef,
        Colors         => undef,
        VLabel         => undef,
        Title          => "$::HOST cpu",
        TimeWindowList => undef,
        CF             => undef,
        XSize          => undef,
        YSize          => undef,
        Target         => undef
    );

    ($vbObj);
}

1;
__END__

=head1 NAME

VBTK::Wrapper::Vmstat - System monitoring with 'vmstat'

=head1 SYNOPSIS

  # If you like all the defaults, then there's no need to over-ride them.
  $o = new VBTK::Wrapper::Vmstat ();
  $vbObj = $o->addVBObj ();

  VBTK::runAll;

=head1 DESCRIPTION

This perl library is a front-end to the L<VBTK::Wrapper|VBTK::Wrapper> class. 
It supports the same public methods as the VBTK::Wrapper class, but with common
defaults to simplify the setup of a 'vmstat' monitoring process.

=head1 METHODS

The following methods are supported

=over 4

=item $o = new VBTK::Wrapper::Vmstat (<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls 'new L<VBTK::Wrapper|VBTK::Wrapper>' after defaulting
the parameters to best monitor the 'vmstat' command.  For a detailed description
of the parameters, see L<VBTK::Wrapper>.  The defaults are as follows.  If you
like all the defaults then you don't have to pass in any parms.

=over 4

=item Interval

    Interval => 60,

=item Execute

Defaults to run the 'vmstat' command with an interval of 60 seconds.

    Execute => 'vmstat 60',

=item Split

Split into columns on whitespace.

    Split => '\s+',

=item Filter

Filter out all rows which don't start with numeric data.  This gets rid of the
headers from the 'vmstat' command.

    Filter => '^\s*\d+[^a-zA-Z]*$',

=item SkipLines

Skip the first 3 lines of vmstat, since they contain data from before the
interval was started.

    Skiplines => 3,

=item VBServerURI

A URI which specifies which VB Server to report results to.  Defaults to the 
environment variable $VBURI.

    VBServerURI => 'http://myvbserver:4712',

=item VBHeader

Defaults to standard vmstat headers.

=item VBDetail

Show the time with the exact text as received from vmstat.

    VBDetail => [ '$time $data' ],

=item LogHeader

Same as VBHeader

=item LogDetail

Same as VBDetail

=item RotateLogAt

Rotate at 12:00am

    RotateLogAt => '12:00am',

=item Follow

This has to run in follow mode, since the 'vmstat 60' command never terminates.

    Follow => 1,

=item FollowTimeout

    FollowTimeout => (2 * Interval) + 10,

=item DebugHeader

    DebugHeader => 'vmstat',

=item NumCpus

A number indicating how many CPU's are in the host to be monitored.  This value
is specific to the VBTK::Wrapper::Vmstat class and is not passed on to the
VBTK::Parser.  If not specified, the class will attempt to determine it by using
the 'psrinfo' command.  The value is used later on to determine 'Warning' and
'Failed' thresholds when setting defaults in the call to 'addVBObj'.
(Defaults to 1 if it can't be determined with the 'psrinfo' command)

    NumCpus => 2,

=back

=item $vbObj = $o->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls VBTK::Wrapper::addVBObj after defaulting unspecified
parameters to best monitor the 'vmstat' command.  For a detailed description
of the addVBObj parameters, see L<VBTK::Parser>.  The defaults are as follows.
If you like all the defaults then you don't have to pass in any parms

=over 4

=item VBObjName

Name the VBObject using the local host's name.

    VBObjName => ".$::HOST.cpu",

=item TextHistoryLimit

    TextHistoryLimit => 100,

=item ReverseText

Reverse the text, so that we see the most recently reported lines first.

    ReverseText => 1,

=item Rules

If run queue exceeds 'NumCpus', then set to Warning.  
If it exceeds 3 times 'NumCpus', then set to Failed.

    Rules => {
         "(\$data[1] > <NumCpus>)" => 'Warn',
         "(\$data[1] > <NumCpus * 3>)" => 'Fail' },

=item StatusHistoryLimit

Limit to storing the last 30 status changes

    StatusHistoryLimit => 30,

=item StatusUpgradeRules

    StatusUpgradeRules =>
        'Upgrade to Failed if Warning occurs 2 times in 6 min',

=item ExpireAfter

    ExpireAfter => (<Interval> * 3) seconds

=item Description

    Description = qq(
        This object uses the 'vmstat' command to monitor the CPU utilization
        on $::HOST.  It will set the status to 'Warning' or 'Failed' based on the
        value of the run queue and the CPU idle time. ),

=item RrdColumns

Save the user CPU, system CPU, run-queue, and scan-rate values into the Rrd
database so that we can graph them.

    RrdColumns => [ '$data[19]', '$data[20]', '$data[0]', '$data[11]' ],

=back

In addition to passing these defaults on in a call to VBTK::Wrapper::addVBObj,
this method captures the resulting VBTK::ClientObject pointer ($vbObj) and 
makes the following call to '$vbObj->addGraphGroup':

  $vbObj->addGraphGroup (
    GroupNumber    => 1,
    Labels         => 'user,system,runQueue,scanRate',
    Title          => "$::HOST cpu",
  );

This defines a graphGroup for the VBObject.  See L<VBTK::ClientObject> for
details on the 'addGraphGroup' method.

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
