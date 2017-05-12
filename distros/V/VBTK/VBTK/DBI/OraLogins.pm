#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/DBI/OraLogins.pm,v $
#            $Revision: 1.8 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: An extension of VBTK::DBI for use in monitoring logins
#                       in an oracle database
#
#           Depends on: VBTK::Common, VBTK::DBI
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
#       $Log: OraLogins.pm,v $
#       Revision 1.8  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.7  2002/03/04 16:49:10  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.6  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.5  2002/02/13 07:36:27  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#       Revision 1.4  2002/01/28 19:35:14  bhenry
#       Bug Fixes
#
#       Revision 1.3  2002/01/25 07:13:31  bhenry
#       Changed to inherit from VBTK::DBI
#
#       Revision 1.2  2002/01/21 17:07:47  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project

package VBTK::DBI::OraLogins;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::DBI;

# Inherit methods from VBTK::DBI;
our @ISA=qw(VBTK::DBI);

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


    my $stdHeader = [
        'Sid User      MemKB     Tot IO Delta IO Cmd Blkr Blkd Stat   Host        HostUser Prog                 PID       Ser#  ',
        '--- --------- ------ --------- -------- --- ---- ---- ------ ----------- -------- -------------------- --------- ------' ];

    my $stdDetail = [
        '@>> @<<<<<<<< @>>>>> @>>>>>>>> @>>>>>>> @>> @>>> @>>> @<<<<< @<<<<<<<<<< @<<<<<<< @<<<<<<<<<<<<<<<<<<< @<<<<<<<< @>>>>>',
        '@data[0..3],$delta[3],@data[4..12]' ];

    my $sql = q(
        select sn.sid,
           sn.username,
           round(se.value/1024),
           io.block_gets,
           sn.command,
           blkr.blocks,
           blkd.blocks,
           sn.status,
           sn.machine,
           sn.osuser,
           sn.program,
           sn.process,
           sn.serial#
        from v$session sn,
             v$sesstat se,
             v$statname n,
             v$sess_io io,
             (select blocker.session_id sid,
              count(blocker.session_id) blocks
              from v$locked_object blocker, v$locked_object blocked
              where blocker.XIDUSN > 0
                and blocker.OBJECT_ID = blocked.OBJECT_ID
                and blocked.XIDUSN = 0
              group by blocker.session_id) blkr,
             (select blocked.session_id sid,
              count(blocked.session_id) blocks
              from v$locked_object blocker, v$locked_object blocked
              where blocker.XIDUSN > 0
                and blocker.OBJECT_ID = blocked.OBJECT_ID
                and blocked.XIDUSN = 0
              group by blocked.session_id) blkd
        where n.statistic# = se.statistic#
          and sn.sid = se.sid
          and n.name = 'session pga memory'
          and io.sid = sn.sid
          and sn.sid = blkr.sid(+)
          and sn.sid = blkd.sid(+)
        order by sn.sid );

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval       => 120,
        DSN            => undef,
        User           => undef,
        Auth           => undef,
        Attr           => 'Oracle',
        VBHeader       => $stdHeader,
        VBDetail       => $stdDetail,
        VBServerURI    => undef,
        LogFile        => undef,
        LogHeader      => undef,
        LogDetail      => undef,
        RotateLogAt    => undef,
        ErrorStatus    => undef,
        SqlClause      => $sql
    };

    # Run the validation, setting defaults if values are not already set
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Initialize a new DBI object
    $self->SUPER::new() || return undef

    # Store the default parms
    $self->{defaultParms} = $defaultParms;

    ($self);
}

#-------------------------------------------------------------------------------
# Function:     addVBObj
# Description:  Add a vb object to the DBI object.
# Input Parms:
# Output Parms: None
#-------------------------------------------------------------------------------
sub addVBObj
{
    my $self = shift;
    my $DSN = $self->{DSN};
    my $User = $self->{User};
    my $Interval   = $self->{Interval};
    my %args = @_;

    # Setup some reasonable thresholds        
    my $expireAfterSec = int($Interval * 3);
    my $upgradeAfterSec = int($Interval * 4);
    my $description = qq( 
        This object monitors the users logged into '$DSN'.
    );

    # Remove any '.' characters from the DNS and User names, so that we don't 
    # confuse the VBObject name.
    $DSN =~ s/\./-/g;
    $User =~ s/\./-/g;

    # Setup a hash of rules to be returned
    my $defaultRules = {
        VBObjName           => ".$::HOST.db.$User\@$DSN.logins",
        TextHistoryLimit    => undef,
        ReverseText         => undef,
        # Warn if any blocking occurs.
        Rules               => {
            '$data[5] > 0' => 'Warning' },
        Requirements        => undef,
        StatusHistoryLimit  => 30,
        StatusChangeActions => undef, 
        StatusUpgradeRules  => 
            "Upgrade to Failed if Warning occurs 3 times in $upgradeAfterSec seconds",
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

VBTK::DBI::OraLogins - Monitoring of connections and blocking processes in Oracle

=head1 SYNOPSIS

  # If you like all the defaults, then there's no need to over-ride them.
  $o = new VBTK::DBI::OraLogins (
      DSN     =>  'oracle.world',
      User    =>  'scott',
      Auth    =>  'tiger' 
  );
  $vbObj = $o->addVBObj ();

  VBTK::runAll;

=head1 DESCRIPTION

This perl module is a front-end to the L<VBTK::DBI|VBTK::DBI> class. 
It supports the same public methods as the VBTK::DBI class, but with common
defaults to simplify the setup of a process monitor connections and blocked
processes in an Oracle database.

=head1 PUBLIC METHODS

The following methods are available to the common user.

=over 4

=item $o = new VBTK::DBI::OraLogins (<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls 'new L<VBTK::DBI|VBTK::DBI>' after defaulting
the parameters to best monitor connections and blocked processes in an Oracle
database.  For a detailed description of the parameters, see L<VBTK::DBI>.  The
defaults are as follows.  If you like all the defaults then you don't have to
pass in any parms, except for the DSN, User, and Auth parameters, which are 
required.  Not all allowed parameters are listed here, just the defaults.

=over 4

=item Interval

    Interval => 120,

=item Attr

    Attr => 'Oracle',

=item VBHeader

    VBHeader => [
      'Sid User      MemKB     Tot IO Delta IO Cmd Blkr Blkd Stat   Host        HostUser Prog                 PID       Ser#  ',
      '--- --------- ------ --------- -------- --- ---- ---- ------ ----------- -------- -------------------- --------- ------' ];

=item VBDetail

    VBDetail => [
      '@>> @<<<<<<<< @>>>>> @>>>>>>>> @>>>>>>> @>> @>>> @>>> @<<<<< @<<<<<<<<<< @<<<<<<< @<<<<<<<<<<<<<<<<<<< @<<<<<<<< @>>>>>',
      '@data[0..3],$delta[3],@data[4..12]' ];

=item SqlClause

    SqlClause => q(
        select sn.sid,
           sn.username,
           round(se.value/1024),
           io.block_gets,
           sn.command,
           blkr.blocks,
           blkd.blocks,
           sn.status,
           sn.machine,
           sn.osuser,
           sn.program,
           sn.process,
           sn.serial#
        from v$session sn,
             v$sesstat se,
             v$statname n,
             v$sess_io io,
             (select blocker.session_id sid,
              count(blocker.session_id) blocks
              from v$locked_object blocker, v$locked_object blocked
              where blocker.XIDUSN > 0
                and blocker.OBJECT_ID = blocked.OBJECT_ID
                and blocked.XIDUSN = 0
              group by blocker.session_id) blkr,
             (select blocked.session_id sid,
              count(blocked.session_id) blocks
              from v$locked_object blocker, v$locked_object blocked
              where blocker.XIDUSN > 0
                and blocker.OBJECT_ID = blocked.OBJECT_ID
                and blocked.XIDUSN = 0
              group by blocked.session_id) blkd
        where n.statistic# = se.statistic#
          and sn.sid = se.sid
          and n.name = 'session pga memory'
          and io.sid = sn.sid
          and sn.sid = blkr.sid(+)
          and sn.sid = blkd.sid(+)
        order by sn.sid );    

=back

=item $vbObj = $o->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls VBTK::DBI::addVBObj after defaulting unspecified
parameters to best monitor connections and blocked processes in an Oracle
database.  For a detailed description of the addVBObj parameters, 
see L<VBTK::Parser>.  The defaults are as follows.
If you like all the defaults then you don't have to pass in any parms.

=over 4

=item VBObjName

Construct a VBObjName using the Host, User, and DSN strings.  Note that the
User and DSN strings are checked for '.' characters and any found are converted
to '-', so that we don't mess up the object's place in the hierarchy.

    VBObjName => ".<HOST>.db.<User>@<DSN>.logins",

=item Rules

If any blocking in the database, then set the status to Warning.

    Rules => {
         '$data[5] > 0' => 'Warning' },

=item StatusHistoryLimit

Limit to storing the last 30 status changes

    StatusHistoryLimit => 30,

=item StatusUpgradeRules

Two 'Warning' statuses will upgrade to 'Failed'.  Increase these values if the 
status is getting set to 'Failed' too often.

    StatusUpgradeRules =>
        'Upgrade to Failed if Warning occurs 3 times in (<Interval> * 4) seconds',

=item ExpireAfter

    ExpireAfter => (<Interval> * 3) seconds

=item Description

    Description = qq(
        This object monitors the users logged into <DSN>. );

=back

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
http://www.gnu.org/copyleft/gpl.html

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
