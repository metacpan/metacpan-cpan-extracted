#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Wrapper/Ping.pm,v $
#            $Revision: 1.10 $
#                $Date: 2002/03/04 20:53:08 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: An extension of the Wrapper library which defaults the
#                       proper settings necessary to run a ping test.
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
#       $Log: Ping.pm,v $
#       Revision 1.10  2002/03/04 20:53:08  bhenry
#       *** empty log message ***
#
#       Revision 1.9  2002/03/04 16:49:10  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.8  2002/03/02 00:53:56  bhenry
#       Documentation updates
#
#       Revision 1.7  2002/02/13 07:36:14  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#

package VBTK::Wrapper::Ping;

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

    # Make sure the 'Interval' has a value before we try to do defaults, since some
    # of them depend on the interval
    $self->{Interval} ||= 60;

    # Setup formatting defaults    
    my $stdHeader =
     [ '                                                              Resp       Pkt',
       'Time               HostName                   IP              Time (ms)  Loss (%)',
       '------------------ -------------------------- --------------- ---------  --------' ];
    my $stdDetail =
     [ '@<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<< @>>>>>>>>  @>>>>>>>',
       '$time, @data[0..3]' ];


    # Define a subroutine which will parse the multi-line output of the ping 
    # command and return a single row with the hostname, ip, reponse time, and
    # packet loss.
    my $preProcessor = sub { 
        my($data) = @_;
        my($respTime,$pktLoss,$host,$ip,$msg) = (0,100);
        foreach (@{$data}) {
            if(/bytes from (\S+) \(([\d\.]+)\): icmp_seq=\d+.+time=(\d+)/) { 
                ($host,$ip,$respTime) = ($1,$2,$3); next; }
            if(/Pinging (\S+) \[([\d\.]+)\]/) { ($host,$ip) = ($1,$2); next; }
            if(/Average =\s+(\d+)ms/)         { ($respTime) = ($1); next; }
            if(/(\d+)\% (packet )?loss/)      { $pktLoss = $1; next; }
            if(/PING|^\s*$|^round-trip|Approximate|statistics|Reply from/) { next; }
        }
        # Now replace everything in the $data array with a single line
        @{$data} = ([ $host, $ip, $respTime, $pktLoss ]);
    };

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval          => 60,
        Host              => $::REQUIRED,
        Execute           => "ping -s $self->{Host} 56 1",
        SourceList        => undef,
        VBServerURI       => $::VBURI,
        VBHeader          => $stdHeader,
        VBDetail          => $stdDetail,
        LogFile           => undef,
        LogHeader         => $stdHeader,
        LogDetail         => $stdDetail,
        RotateLogAt       => undef,
        RotateLogOnEOF    => undef,
        PreProcessor      => $preProcessor,
        Filter            => undef,
        Ignore            => undef,
        Split             => undef,
        SkipLines         => undef,
        Timeout           => 20,
        TimeoutStatus     => 'Warn',
        Follow            => undef,
        FollowTimeout     => undef,
        FollowHeartbeat   => undef,
        SetRunStatus      => undef,
        NonZeroExitStatus => 'Warn',
        SuppressStdout    => undef,
        SuppressMessages  => undef,
        DebugHeader       => "Ping $self->{Host}"
    };

    # Do some O/S specific overrides
    if ($::OS =~ /win/i)
    {
        $defaultParms->{Execute} = "ping -n 1 $self->{Host}";
    }
    elsif ($::OS =~ /linux/i)
    {
        $defaultParms->{Execute} = "ping -c 1 $self->{Host}";
    }
    
    # Run a validation on the passed parms, using the default parms        
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Save the host value and then delete it out of self temporarily, so that it
    # doesn't get passed to the Wrapper object.
    my $host = $self->{Host};
    delete $self->{Host};

    # Initialize a wrapper object.
    $self->SUPER::new() || return undef;

    # Store the defaults for later
    $self->{Host} = $host;
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
    my $Interval   = $self->{Interval};
    my $Host       = $self->{Host};
    my %args = @_;

    # Setup some reasonable thresholds        
    my $expireAfterSec = int($Interval * 3);
    my $description = qq( 
        This object uses the 'ping' command to monitor '$Host'.  It will set the 
        status to 'Warning' if the ping command loses any packets or if the response
        time is greater than 250ms.
    );

    # Setup a hash of rules to be returned
    my $defaultRules = {
        VBObjName           => ".$Host.ping",
        TextHistoryLimit    => 30,
        ReverseText         => 1,
        # Set to Warn if any packets are lost or if response time > 250
        Rules               => {
            '(($data[2] > 250)||($data[3] > 0))' => 'Warn' },
        Requirements        => undef,
        StatusHistoryLimit  => 30,
        StatusChangeActions => undef, 
        StatusUpgradeRules  => [ 
            "Upgrade to Failed if Warning occurs 2 times in $expireAfterSec sec" ],
        ExpireAfter         => "$expireAfterSec seconds",
        Description         => $description,
        RrdTimeCol          => undef,
        RrdColumns          => [ '$data[2]','$data[3]' ],
        RrdFilter           => undef,
        RrdMin              => 0,
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
        DataSourceList => ':0',
        Labels         => 'Response Time (ms)',
        Title          => "Ping $Host",
        CF             => undef,
    );

    # Now define what graphs to show on this object's page
    $vbObj->addGraphGroup (
        GroupNumber    => 2,
        DataSourceList => ':1',
        Labels         => 'Packet Loss %',
        Title          => "Ping $Host",
        CF             => undef,
    );

    ($vbObj);
}

1;
__END__

=head1 NAME

VBTK::Wrapper::Ping - System monitoring with 'ping'

=head1 SYNOPSIS

  $obj = new VBTK::Wrapper::Ping( Host => 'myhost1');
  $obj->addVBObj(VBObjName => '.myhost1.ping');

  $obj = new VBTK::Wrapper::Ping( Host => 'myhost2');
  $obj->addVBObj(VBObjName => '.myhost2.ping');

  # Call this at the very end to start looping and checking everything
  VBTK::runAll;

=head1 DESCRIPTION

This perl library is a front-end to the L<VBTK::Wrapper|VBTK::Wrapper> class. 
It supports the same public methods as the VBTK::Wrapper class, but with common
defaults to simplify the setup of a 'ping' monitoring process.

=head1 METHODS

The following methods are supported

=over 4

=item $o = new VBTK::Wrapper::Ping (<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls 'new L<VBTK::Wrapper|VBTK::Wrapper>' after defaulting
the parameters to run and monitor the 'ping' command.  For a detailed description
of the parameters, see L<VBTK::Wrapper>.  Only 1 parameter 'Host' is required.
The rest are defaulted appropriately, but if you don't like the defaults, you
can override their settings.  The defaults are as follows:

=over 4

=item Host

Hostname you want to ping.  This is the one parameter which must be specified!
(Required)

    Host => 'myhost1'

=item Interval

    Interval => 60,

=item Execute

Defaults to run the 'ping' command with the parameters listed below.  You may need
to specify this instead, if your 'ping' is in a different location, or uses different
parameters.

    # On Windows or Cygwin
    Execute => "ping -n 1 <Host>",

    # On Linux
    Execute => "ping -c 1 <Host>",

    # All others
    Execute => "ping -s <Host> 56 1",

=item PreProcessor

Defaults to the following pre-processor subroutine.  This parses through all 
the output of the 'ping' command, picking out the response time and packet
loss values, and then replaces the whole array of output with a single row
of host, ip, response-time, and packet loss.

    PreProcessor = sub { 
        my($data) = @_;
        my($respTime,$pktLoss,$host,$ip,$msg) = (0,100);
        foreach (@{$data}) {
            if(/bytes from (\S+) \(([\d\.]+)\): icmp_seq=\d+.+time=(\d+)/) { 
                ($host,$ip,$respTime) = ($1,$2,$3); next; }
            if(/Pinging (\S+) \[([\d\.]+)\]/) { ($host,$ip) = ($1,$2); next; }
            if(/Average =\s+(\d+)ms/)         { ($respTime) = ($1); next; }
            if(/(\d+)\% (packet )?loss/)      { $pktLoss = $1; next; }
            if(/PING|^\s*$|^round-trip|Approximate|statistics|Reply from/) { next; }
        }
        # Now replace everything in the $data array with a single line
        @{$data} = ([ $host, $ip, $respTime, $pktLoss ]);
    };

=item VBServerURI

A URI which specifies which VB Server to report results to.  Defaults to the 
environment variable $VBURI.

    VBServerURI => $VBURI,

=item VBHeader

    VBHeader => [
      '                                                              Resp       Pkt',
      'Time               HostName                   IP              Time (ms)  Loss (%)',
      '------------------ -------------------------- --------------- ---------  --------' ],

=item VBDetail

    VBDetail => [
      '@<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<< @>>>>>>>>  @>>>>>>>',
      '$time, @data[0..3]' ],

=item LogHeader

Same as VBHeader

=item LogDetail

Same as VBDetail

=item Timeout

    Timeout => 15,

=item TimeoutStatus

    TimeoutStatus => 'Warn',

=item NonZeroExitStatus

    NonZeroExitStatus => 'Warn',

=item DebugHeader

    DebugHeader => 'Ping <Host>',

=back

=item $vbObj = $o->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls VBTK::Wrapper::addVBObj after defaulting unspecified
parameters to best monitor the 'ping' command.  For a detailed description
of the addVBObj parameters, see L<VBTK::Parser>.  The defaults are as follows.
If you like all the defaults then you don't have to pass in any parms

=over 4

=item VBObjName

    VBObjName => ".<Host>.cpu",

=item TextHistoryLimit

    TextHistoryLimit => 30,

=item ReverseText

    ReverseText => 1,

=item Rules

If the response time > 250 or packet loss > 0, then set to Warning.

    Rules => {
        '(($data[2] > 250)||($data[3] > 0))' => 'Warn' },

=item StatusHistoryLimit

    StatusHistoryLimit => 30,

=item StatusUpgradeRules

    StatusUpgradeRules =>
        'Upgrade to Failed if Warning occurs 2 times in (<Interval> * 3) sec',

=item ExpireAfter

    ExpireAfter => (<Interval> * 3) seconds

=item Description

    Description = qq(
        This object uses the 'ping' command to monitor '<Host>'.  It will set the 
        status to 'Warning' if the ping command loses any packets or if the response
        time is greater than 250ms.
    );

=item RrdColumns

Store the response time and packet loss in the rrd library.

    RrdColumns => [ '$data[2]', '$data[3]' ],

=item RrdMin

    RrdMin => 0,

=back

In addition to passing these defaults on in a call to VBTK::Wrapper::addVBObj,
this method captures the resulting VBTK::ClientObject pointer ($vbObj) and 
makes the following calls to '$vbObj->addGraphGroup':

  $vbObj->addGraphGroup (
    GroupNumber    => 1,
    DataSourceList => ':0',
    Labels         => 'Response Time (ms)',
    Title          => "Ping <Host>",
  );

  $vbObj->addGraphGroup (
    GroupNumber    => 2,
    DataSourceList => ':1',
    Labels         => 'Packet Loss %',
    Title          => "Ping <Host>",
  );

This defines two graphGroups for the VBObject.  See L<VBTK::ClientObject> for
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
