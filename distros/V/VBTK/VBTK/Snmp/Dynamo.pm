#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Snmp/Dynamo.pm,v $
#            $Revision: 1.9 $
#                $Date: 2002/03/04 20:53:08 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: An extension of the VBTK::Snmp library which defaults
#                       to common settings used in monitoring dynamo
#
#           Depends on: VBTK::Common, VBTK::Snmp
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
#       $Log: Dynamo.pm,v $
#       Revision 1.9  2002/03/04 20:53:08  bhenry
#       *** empty log message ***
#
#       Revision 1.8  2002/03/04 16:49:10  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.7  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.6  2002/02/20 20:41:35  bhenry
#       *** empty log message ***
#
#       Revision 1.5  2002/02/19 19:13:59  bhenry
#       Changed to use inheritance
#
#       Revision 1.4  2002/02/13 08:01:57  bhenry
#       *** empty log message ***
#
#       Revision 1.3  2002/02/13 07:36:43  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#       Revision 1.2  2002/01/21 17:07:53  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#

package VBTK::Snmp::Dynamo;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::Snmp;

# Inherit methods from VBTK::Snmp;
our @ISA=qw(VBTK::Snmp);

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

    # Setup the header and detail formats for the pmobjects and log
    my $stdHeader = [ 'Time              Reqs Avg ms New Sess Val Sess  Total KB   Free KB Status',
                      '----------------- ---- ------ -------- -------- --------- --------- -----------------------' ];
    my $stdDetail = [ '@<<<<<<<<<<<<<<<< @>>> @>>>>> @>>>>>>> @>>>>>>> @>>>>>>>> @>>>>>>>> @<<<<<<<<<<<<<<<<<<<<<<',
                      '$time,$delta[0],($delta[0] > 0) ? ($delta[1]/($delta[0])) : 0,$delta[2],$data[3],int($data[4]/1024),int($data[5]/1024),$data[6]' ];

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval          => 60,
        Labels            => [
            'drpTotalReqsServed',
            'drpTotalReqTime',
            'stCreatedSessionCnt',
            'stValidSessionCnt',
            'sysTotalMem',
            'sysFreeMem',
            'sysStatus' ],
        Host              => 'localhost',
        Port              => '8870',
        Community         => undef,
        VBServerURI       => undef,
        VBHeader          => $stdHeader,
        VBDetail          => $stdDetail,
        LogFile           => undef,
        LogHeader         => $stdHeader,
        LogDetail         => $stdDetail,
        RotateLogAt       => "12:00am",
        Timeout           => 5,
        Retries           => 1,
        ErrorStatus       => 'Warn',
        GetMultRows       => 0
    };

    # Run a validation on the passed parms, using the default parms        
    $self->validateParms($defaultParms);

    # Add in the dynamo-specific MIB
    VBTK::Snmp::addMibFiles("$::VBHOME/mib/Dynamo3Mib.mib");

    # Initialize an snmp object.
    $self->SUPER::new() || return undef;

    # Store the defaults for later
    $self->{defaultParms} = $defaultParms;

    ($self);
}

#-------------------------------------------------------------------------------
# Function:     addVBObj
# Description:  Add rules to the wrapper object.
# Input Parms:
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub addVBObj
{
    my $self = shift;
    my $Host = $self->{Host};
    my $Port = $self->{Port};
    my $Interval   = $self->{Interval};

    my %args = @_;

    # Setup some reasonable thresholds        
    my $expireAfterSec = int($Interval * 3);
    my $description = qq( 
        This object uses SNMP to monitor a dynamo instance.
    );

    # Remove any '.' chars from the Host string, so we don't confuse
    # the object's position in the hierarchy.
    $Host =~ s/\./-/g;

    # Setup a hash of default rules to be returned
    my $defaultRules = {
        VBObjName          => ".$Host.dynamo.$Port",
        TextHistoryLimit    => 100,
        ReverseText         => 1,
        # Warn if % free memory < 10%
        Rules              => {
            '($data[5]/($data[4]+.01)) < .10' => 'Warn' },
        Requirements       => undef,
        StatusHistoryLimit  => 30,
        StatusChangeActions => undef,
        StatusUpgradeRules  => 
            "Upgrade to Failed if Warning occurs 2 times in $expireAfterSec seconds",
        ExpireAfter         => "$expireAfterSec seconds",
        Description         => $description,
        BaselineDiffStatus  => undef,
        RrdTimeCol          => undef,
        RrdColumns          => 
             # Pages Srvd, New Sess,   Curr Sess, Free Mem,  Tot Mem  
            [ '$delta[0]','$delta[2]','$data[3]','$data[5]','$data[4]' ],
        RrdFilter           => undef,
        RrdMin              => undef,
        RrdMax              => undef,
        RrdXFF              => undef,
        RrdCF               => undef,
        RrdDST              => undef,
    };

    # Run the validation    
    &validateParms(\%args,$defaultRules);

    # Add the rule
    my $vbObj = $self->SUPER::addVBObj(%args);

    return undef if ($vbObj eq undef);

    # Now define what graphs to show on this object's page
    $vbObj->addGraphGroup (
        GroupNumber    => 1,
        DataSourceList => ':0',
        Labels         => 'pageViews',
        Title          => "$Host:$Port dynamo",
    );

    # Now define what graphs to show on this object's page
    $vbObj->addGraphGroup (
        GroupNumber    => 2,
        DataSourceList => ':1,:2',
        Labels         => 'new sessions,valid sessions',
        Title          => "$Host:$Port dynamo",
    );

    # Now define what graphs to show on this object's page
    $vbObj->addGraphGroup (
        GroupNumber    => 3,
        DataSourceList => ':3,:4',
        Labels         => 'freeMem,totMem',
        Title          => "$Host:$Port dynamo",
    );

    $self->{defaultRules} = $defaultRules;

    ($vbObj);
}

1;
__END__

=head1 NAME

VBTK::Snmp::Dynamo - Monitoring of ATG Dynamo process through SNMP

=head1 SYNOPSIS

  # If you like all the defaults, then there's no need to over-ride them.
  $o = new VBTK::Snmp::Dynamo (
      Host => 'myhost',
      Port => 8870,
  );
  $vbObj = $o->addVBObj ();

  &VBTK::runAll;

=head1 DESCRIPTION

This perl module is a front-end to the L<VBTK::Snmp|VBTK::Snmp> package. 
It supports the same public methods as the VBTK::DBI package, but with common
defaults to simplify the setup of a process to monitor an ATG Dynamo process
through SNMP.

=head1 PUBLIC METHODS

The following methods are available to the common user.

=over 4

=item $o = new VBTK::Snmp::Dynamo (<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls 'new L<VBTK::Snmp|VBTK::Snmp>' after defaulting
the parameters to best monitor an ATG Dynamo process.  For a detailed
description of the parameters, see L<VBTK::Snmp>.  The
defaults are as follows.  If you like all the defaults then you don't have to
pass in any parms, except for the Host and Port parameters, which are 
required.  Not all allowed parameters are listed here, just those which are
defaulted by this package.

=over 4

=item Interval

    Interval => 60,

=item Labels

    Labels => [
        'drpTotalReqsServed',
        'drpTotalReqTime',
        'stCreatedSessionCnt',
        'stValidSessionCnt',
        'sysTotalMem',
        'sysFreeMem',
        'sysStatus' ],

=item Host

Required.

    Host => 'myhost',

=item Port

Required.

    Port => 8870,

=item VBHeader

    VBHeader => [
        'Time              Reqs Avg ms New Sess Val Sess  Total KB   Free KB Status',
        '----------------- ---- ------ -------- -------- --------- --------- -----------------------' ],

=item VBDetail

    VBDetail => [
        '@<<<<<<<<<<<<<<<< @>>> @>>>>> @>>>>>>> @>>>>>>> @>>>>>>>> @>>>>>>>> @<<<<<<<<<<<<<<<<<<<<<<',
        '$time,$delta[0],($delta[0] > 0) ? ($delta[1]/($delta[0])) : 0,$delta[2],$data[3],int($data[4]/1024),int($data[5]/1024),$data[6]' ];

=item LogHeader

Same as VBHeader, but used for the log.

=item LogDetail

Same as VBDetail, but used for the log.

=item RotateLogAt

    RotateLogAt => '12:00am',

=item Timeout

    Timeout => 5,

=item Retries

    Retries => 1,

=item GetMultRows

    GetMultRows => 0,

=back

=item $vbObj = $o->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls VBTK::Snmp::addVBObj after defaulting unspecified
parameters to best monitor ATG Dynamo processes.
For a detailed description of the addVBObj parameters, 
see L<VBTK::Parser>.  The defaults are as follows.
If you like all the defaults then you don't have to pass in any parms.

=over 4

=item VBObjName

Construct a VBObjName using the Host and Port strings.  Note that the
Host string is checked for '.' characters and any found are converted
to '-', so that we don't mess up the object's place in the hierarchy.

    VBObjName => ".<Host>.dynamo.<Port>",

=item TextHistoryLimit

    TextHistoryLimit => 100,

=item ReverseText

    ReverseText => 1,

=item Rules

If warn if free memory in the JVM falls below 10%

    Rules => { '($data[5]/$data[4]) < .10' => 'Warn' },

=item StatusHistoryLimit

Limit to storing the last 30 status changes

    StatusHistoryLimit => 30,

=item StatusUpgradeRules

    StatusUpgradeRules => 
        'Upgrade to Failed if Warning occurs 2 times in <Interval * 3> seconds'

=item ExpireAfter

    ExpireAfter => (<Interval> * 3) seconds

=item Description

    Description = qq(
        This object uses SNMP to monitor a dynamo instance. );

=item RrdColumns

Setup the list of values to store in the Rrd database

    RrdColumns          => 
         # Pages Srvd, New Sess,   Curr Sess, Free Mem (MB),       Tot Mem (MB)  
        [ '$delta[0]','$delta[2]','$data[3]','$data[5]/1024/1024','$data[4]/1024/1024' ],

=back

In addition to passing these defaults on in a call to VBTK::Parser::addVBObj,
this method captures the resulting VBTK::ClientObject pointer ($vbObj) and 
makes the following calls to '$vbObj->addGraphGroup':

  $vbObj->addGraphGroup (
    GroupNumber    => 1,
    DataSourceList => ':0',
    Labels         => 'pageViews',
    Title          => "<Host>:<Port> dynamo",
  );

  $vbObj->addGraphGroup (
    GroupNumber    => 2,
    DataSourceList => ':1,:2',
    Labels         => 'new sessions,valid sessions',
    Title          => "$Host:$Port dynamo",
  );

  $vbObj->addGraphGroup (
    GroupNumber    => 3,
    DataSourceList => ':3,:4',
    Labels         => 'freeMemMB,totMemMB',
    Title          => "$Host:$Port dynamo",
  );

This defines three graphGroups for the VBObject.  See L<VBTK::ClientObject> for
details on the 'addGraphGroup' method.

=back

=head1 SEE ALSO

=over 4

=item L<VBTK|VBTK>

=item L<VBTK::DBI|VBTK::DBI>

=item L<VBTK::Server|VBTK::Server>

=item L<VBTK::Parser|VBTK::Parser>

=item L<VBTK::ClientObject|VBTK::ClientObject>

=back

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
