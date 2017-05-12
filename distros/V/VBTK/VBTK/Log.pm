#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Log.pm,v $
#            $Revision: 1.7 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: An extension of VBTK::Wrapper for use in monitoring
#                       log files
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
#       $Log: Log.pm,v $
#       Revision 1.7  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.6  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.5  2002/03/02 00:53:54  bhenry
#       Documentation updates
#
#       Revision 1.4  2002/02/13 07:38:52  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#       Revision 1.3  2002/01/25 07:16:51  bhenry
#       Changed to inherit from Wrapper
#

package VBTK::Log;

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

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval          => $interval,
        SourceList        => $::REQUIRED,
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
        # This makes it jump to the end of the log file and start
        # monitoring from there.  That way we don't reprocess the whole
        # log file any time we re-start.
        SkipLines         => '-0',
        Timeout           => undef,
        TimeoutStatus     => undef,
        Follow            => 1,
        FollowTimeout     => undef,
        FollowHeartbeat   => 1,
        DebugHeader       => undef,
    };

    # Run the validation, setting defaults if values are not already set
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Initialize a wrapper object.
    $self->SUPER::new() || return undef;

    # Store the default parms
    $self->{defaultParms} = $defaultParms;

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
    my $Interval   = $self->{Interval};
    my %args = @_;

    # Setup some reasonable thresholds        
    my $expireAfterSec = int($Interval * 3);
    my $description = qq( 
        This object follows the output of the specified log file watching for 
        warnings or errors.
    );

    # Setup a hash of rules to be returned
    my $defaultRules = {
        VBObjName           => ".$::HOST.log.generic",
        TextHistoryLimit    => 200,
        ReverseText         => 1,
        Rules               => {
            '($data =~ /error|fail/i)' => 'Fail',
            '($data =~ /warn/i)'       => 'Warn' },
        Requirements        => undef,
        StatusHistoryLimit  => 30,
        StatusChangeActions => undef, 
        StatusUpgradeRules  => undef,
        ExpireAfter         => "$expireAfterSec seconds",
        Description         => $description,
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
    my $vbObj = $self->SUPER::addVBObj(%args);

    ($vbObj);
}

1;
__END__

=head1 NAME

VBTK::Log - Monitoring of sequential ASCII text logs

=head1 SYNOPSIS

  # Monitor /var/adm/messages, looking for warning or error messages.
  $obj = new VBTK::Log(
      SourceList => '/var/adm/messages');
  $obj->addVBObj(
      VBObjName => ".$::HOST.log.messages",
      Rules     => {
          '($data =~ /unix:|hardware error|panic/i)'      => 'Fail',
          '($data =~ /fail|warning|refuse/i)' => 'Warn' },
  ) if ($obj);

  &VBTK::runAll;

=head1 DESCRIPTION

This perl library is a front-end to the L<VBTK::Wrapper|VBTK::Wrapper> class. 
It supports the same public methods as the VBTK::Wrapper class, but with common
defaults to simplify the monitoring of a log file.

=head1 METHODS

The following methods are supported

=over 4

=item $o = new VBTK::Wrapper::Log (<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls 'new L<VBTK::Wrapper|VBTK::Wrapper>' after defaulting
the parameters to tail the specified log file.  For a detailed description
of the parameters, see L<VBTK::Wrapper>.  The defaults are as follows.  If you
like all the defaults then you don't have to pass in any parms.

=over 4

=item Interval

    Interval => 60,

=item SourceList

A list of files to retrieve data from.  The process will read the files in
order specified.  Usually, you only have one file in the list.  (Required)

    SourceList => '/var/adm/messages',

=item VBDetail

Just dump out the rows as they are retrieved.

    VBDetail => [ '$data' ],

=item SkipLines

    Skiplines => '-0',

=item Follow

Usually you want to run in follow mode when monitoring a log file.

    Follow => 1,

=item FollowHeartbeat

    FollowHeartbeat => 1,

=back

=item $vbObj = $o->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls VBTK::Parser::addVBObj after defaulting unspecified
parameters to best follow a log file.  For a detailed description
of the addVBObj parameters, see L<VBTK::Parser>.  The defaults are as follows.
If you like all the defaults then you don't have to pass in any parms

=over 4

=item VBObjName

Name the VBObject using the local host's name.

    VBObjName => ".$::HOST.log.generic",

=item TextHistoryLimit

    TextHistoryLimit => 200,

=item ReverseText

Reverse the text, so that we see the most recently reported lines first.

    ReverseText => 1,

=item Rules

Watch for words like 'error', 'fail', or 'warn'

    Rules => {
      '($data =~ /error|fail/i)' => 'Fail',
      '($data =~ /warn/i)'       => 'Warn' },

=item StatusHistoryLimit

Limit to storing the last 30 status changes

    StatusHistoryLimit => 30,

=item ExpireAfter

    ExpireAfter => (<Interval> * 3) seconds

=item Description

    Description = qq(
        This object follows the output of the specified log file watching for 
        warnings or errors. ),

=back

=back

=head1 SEE ALSO

=over 4

=item L<VBTK::Wrapper|VBTK::Wrapper>

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
http://http://www.gnu.org/copyleft/gpl.html

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut

