#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Wrapper/Metastat.pm,v $
#            $Revision: 1.8 $
#                $Date: 2002/03/04 20:53:08 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: An extension of the VBTK::Wrapper library which defaults
#                       the proper settings necessary to run a Disk Suite metastat
#                       test.
#
#           Depends on: VBTK::Common, VBTK::Wrapper
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
#       $Log: Metastat.pm,v $
#       Revision 1.8  2002/03/04 20:53:08  bhenry
#       *** empty log message ***
#
#       Revision 1.7  2002/03/04 16:49:10  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.6  2002/03/02 00:53:56  bhenry
#       Documentation updates
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

package VBTK::Wrapper::Metastat;

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

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval          => 600,
        Execute           => "metastat",
        VBServerURI       => $::VBURI,
        VBHeader          => undef,
        VBDetail          => [ '$data' ],
        LogFile           => undef,
        LogHeader         => undef,
        LogDetail         => undef,
        RotateLogAt       => undef,
        RotateLogOnEOF    => undef,
        Split             => undef,
        Filter            => undef,
        Ignore            => undef,
        SkipLines         => undef,
        Timeout           => 40,
        TimeoutStatus     => 'Fail',
        Follow            => undef,
        FollowTimeout     => undef,
        SuppressMessages  => undef,
        FollowHeartbeat   => undef,
        SetRunStatus      => undef,
        NonZeroExitStatus => undef,
        SuppressStdout    => undef,
        SuppressMessages  => undef,
        DebugHeader       => 'metastat'
    };

    # Run a validation on the passed parms, using the default parms        
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Initialize a wrapper object.
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
    my $Interval   = $self->{Interval};
    my %args = @_;

    # Setup some reasonable thresholds        
    my $expireAfterSec = int($Interval * 3);
    my $description = qq( 
        This object uses the 'metastat' command to monitor the DiskSuite volumes
        on $::HOST.  It will set the status to 'Warning' or 'Failed' based on the
        output of the 'metastat' command.
    );

    # Setup a hash of default rules to be returned
    my $defaultRules = {
        VBObjName           => ".$::HOST.md",
        TextHistoryLimit    => undef,
        ReverseText         => undef,
        Rules              => {
            '$data =~ /error|fail|maintenance/i' => 'Fail' },
        Requirements        => undef,
        StatusHistoryLimit  => 30,
        StatusChangeActions => undef, 
        StatusUpgradeRules  => undef,
        ExpireAfter         => "$expireAfterSec seconds",
        Description         => $description,
        BaselineDiffStatus  => "Warn",
        RrdTimeCol          => undef,
        RrdColumns          => undef,
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

    $self->{defaultRules} = $defaultRules;

    ($vbObj);
}

1;
__END__

=head1 NAME

VBTK::Wrapper::Metastat - DiskSuite Monitoring with 'metastat'

=head1 SYNOPSIS

  # If you like all the defaults, then there's no need to over-ride them.
  $o = new VBTK::Wrapper::Metastat ();
  $vbObj = $o->addVBObj();

  VBTK::runAll;

=head1 DESCRIPTION

This perl library is a front-end to the L<VBTK::Wrapper|VBTK::Wrapper> class. 
It supports the same public methods as the VBTK::Wrapper class, but with common
defaults to simplify the setup of a 'metastat' monitoring process.

=head1 METHODS

The following methods are supported

=over 4

=item $o = new VBTK::Wrapper::Metastat (<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls 'new L<VBTK::Wrapper|VBTK::Wrapper>' after defaulting
the parameters to best monitor the 'metastat' command.  For a detailed description
of the parameters, see L<VBTK::Wrapper>.  The defaults are as follows.  If you
like all the defaults then you don't have to pass in any parms.

=over 4

=item Interval

    Interval => 600,

=item Execute

    Execute => 'metastat',

=item VBDetail

Show the exact data as returned by the vxprint command.

    VBDetail => [ '$data' ],

=item Timeout

    Timeout => 40,

=item TimeoutStatus

    TimeoutStatus => 'Fail',

=item DebugHeader

    DebugHeader => 'metastat',

=back

=item $vbObj = $o->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls VBTK::Wrapper::addVBObj after defaulting unspecified
parameters to best monitor the 'vxprint' command.  For a detailed description
of the addVBObj parameters, see L<VBTK::Parser>.  The defaults are as follows.
If you like all the defaults then you don't have to pass in any parms

=over 4

=item VBObjName

Name the VBObject using the local host's name.

    VBObjName => ".$::HOST.md",

=item Rules

If we see the words error or fail in the output, then set the status to 'Failed'.

    Rules => {
         '$data =~ /error|fail|maintenance/i' => 'Fail' },

=item StatusHistoryLimit

Limit to storing the last 30 status changes

    StatusHistoryLimit => 30,

=item ExpireAfter

    ExpireAfter => (<Interval> * 3) seconds

=item Description

    Description = qq(
        This object uses the 'metastat' command to monitor the DiskSuite volumes
        on $::HOST.  It will set the status to 'Warning' or 'Failed' based on the
        output of the 'metastat' command. ),

=item BaselineDiffStatus

Set the status to 'Warning' if the returned text differs from the baseline.

    BaselineDiffStatus => 'Warn',

=back

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
