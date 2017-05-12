#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/DBI/OraTableSpace.pm,v $
#            $Revision: 1.9 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: An extension of VBTK::DBI for use in monitoring free
#                       space in oracle tablespaces.
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
#       $Log: OraTableSpace.pm,v $
#       Revision 1.9  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.8  2002/03/04 16:49:10  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.7  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.6  2002/02/13 07:36:27  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#

package VBTK::DBI::OraTableSpace;

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
        'time               tablespace             tot_mb free_mb used  max_ext',
        '------------------ --------------------- ------- ------- ---- -------' ];

    my $stdDetail = [
        '@<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<< @>>>>>> @>>>>>> @>>% @>>>>>>',
        '$time,$data[0],int($data[1]),int($data[2]),int($data[3]),int($data[4])' ];

    my $sql = q(
        select DT_TS_NAME,
               Sum_Alloc_Blocks * DB_BLOCK_FACTOR,
               Sum_Free_Blocks * DB_BLOCK_FACTOR,
               100-(100*Sum_Free_Blocks/Sum_Alloc_Blocks) AS PCT_USED,
               Max_Blocks * DB_BLOCK_FACTOR
        from 
         (select Tablespace_Name DT_TS_NAME,
                 SUM(Blocks) Sum_Alloc_Blocks
          from DBA_DATA_FILES
          group by Tablespace_Name),
         (select Tablespace_Name FS_TS_NAME,
                 MAX(Blocks)  AS Max_Blocks,
                 SUM(Blocks) AS Sum_Free_Blocks
          from DBA_FREE_SPACE
          group by Tablespace_Name),
         (select (value / 1024 / 1024) DB_BLOCK_FACTOR
          from v$parameter
          where name = 'db_block_size')
        where DT_TS_NAME = FS_TS_NAME
        order by PCT_USED DESC );

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval       => 120,
        DSN            => undef,
        User           => undef,
        Auth           => undef,
        Attr           => 'Oracle',
        VBHeader       => $stdHeader,
        VBDetail       => $stdDetail,
        VBServerURI    => $::VBURI,
        PreProcessor   => undef,
        LogFile        => undef,
        LogHeader      => undef,
        LogDetail      => $stdDetail,
        RotateLogAt    => undef,
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
    my $description = qq( 
        This object monitors the tablespaces of '$DSN'.
    );

    # Remove any '.' characters from the DNS and User names, so that we don't 
    # confuse the VBObject name.
    $DSN =~ s/\./-/g;
    $User =~ s/\./-/g;

    # Setup a hash of rules to be returned
    my $defaultRules = {
        VBObjName           => ".$::HOST.db.$User\@$DSN.dbspace",
        TextHistoryLimit    => 50,
        ReverseText         => 1,
        Rules               => undef,
        Requirements        => undef,
        StatusHistoryLimit  => 30,
        StatusChangeActions => undef, 
        StatusUpgradeRules  => undef,
        ExpireAfter         => "$expireAfterSec seconds",
        Description         => $description,
        RrdTimeCol          => undef,
        RrdColumns          => [ 'int($data[3])' ],
        RrdFilter           => undef,
        RrdMin              => undef,
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
    &VBTK::runAll($clone,0);
    my $lastRows = $clone->getLastRows;

    # Make sure we got some data back
    if (@{$lastRows} < 1)
    {
        &error("Can't setup objects for VBTK::DBI::OraTableSpace, because no data " .
            "was returned from SQL");
        return undef;
    }

    # Store the base objectname so we can add to it
    my $baseObjName = $args{VBObjName};

    my(@dataSourceList,$labels,$tablespace,$warnPct,$failPct);
    my(@labels);

    # Create one VB object for each filesystem
    foreach $row (@{$lastRows})
    {
        # Get the mount point
        $tablespace = $row->[0];

        # Setup warn and fail thresholds based on the type of tablespace
        ($warnPct,$failPct) = ($tablespace =~ /TEMP/) ? (30,40) : (90,95);

        # Override parms which vary between objects
        $args{VBObjName} = "$baseObjName.$tablespace";
        $args{Filter} = $args{RrdFilter} = "\$data[0] eq '$tablespace'";
        $args{Rules}     = {
            "(\$data[3] > $warnPct)" => 'Warn',
            "(\$data[3] > $failPct)" => 'Fail' };

        # Add the rule
        $vbObj = $self->SUPER::addVBObj(%args);

        # Create one graph group which shows only this tablespace.
        $vbObj->addGraphGroup (
            GroupNumber    => 1,
            DataSourceList => undef,
            Labels         => 'pct-full',
            Title          => "Tablespace Utilization for $DSN.$tablespace",
            CF             => 'MAX'
        );

        # Save some values to be used in graphGroup 2
        push(@dataSourceList,"$baseObjName.$tablespace:0");
        push(@labels,"$tablespace");
    }

    # Create a second graph group which shows all tablespaces together.
    $self->addGraphGroup (
        GroupNumber    => 2,
        DataSourceList => join(',',@dataSourceList),
        Labels         => join(',',@labels),
        Title          => "Tablespace Utilization for $DSN",
        CF             => 'MAX'
    );

    (undef);
}

1;
__END__

=head1 NAME

VBTK::DBI::OraTableSpace - Monitoring of Oracle database tablespaces

=head1 SYNOPSIS

  # If you like all the defaults, then there's no need to over-ride them.
  $o = new VBTK::DBI::OraTableSpace (
      DSN     =>  'oracle.world',
      User    =>  'scott',
      Auth    =>  'tiger' 
  );
  $vbObj = $o->addVBObj ();

  VBTK::runAll;

=head1 DESCRIPTION

This perl module is a front-end to the L<VBTK::DBI|VBTK::DBI> class. 
It supports the same public methods as the VBTK::DBI class, but with common
defaults to simplify the setup of a process to monitor tablespace usage in
an Oracle database.

=head1 METHODS

The following methods are supported

=over 4

=item $o = new VBTK::DBI::OraTableSpace (<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls 'new L<VBTK::DBI|VBTK::DBI>' after defaulting
the parameters to best monitor tablespace usage in an Oracle
database.  For a detailed description of the parameters, see L<VBTK::DBI>.  The
defaults are as follows.  If you like all the defaults then you don't have to
pass in any parms, except for the DSN, User, and Auth parameters, which are 
required.  Not all allowed parameters are listed here, just those which are 
defaulted.

=over 4

=item Interval

    Interval => 120,

=item Attr

    Attr => 'Oracle',

=item VBHeader

    VBHeader => [
        'time               tablespace             tot_mb free_mb used  max_ext',
        '------------------ --------------------- ------- ------- ---- -------' ],

=item VBDetail

    VBDetail => [
        '@<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<< @>>>>>> @>>>>>> @>>% @>>>>>>',
        '$time,$data[0],int($data[1]),int($data[2]),int($data[3]),int($data[4])' ],

=item LogDetail

Same as VBDetail, but for the log file.

=item SqlClause

    SqlClause => q(
        select DT_TS_NAME,
               Sum_Alloc_Blocks * DB_BLOCK_FACTOR,
               Sum_Free_Blocks * DB_BLOCK_FACTOR,
               100-(100*Sum_Free_Blocks/Sum_Alloc_Blocks) AS PCT_USED,
               Max_Blocks * DB_BLOCK_FACTOR
        from 
         (select Tablespace_Name DT_TS_NAME,
                 SUM(Blocks) Sum_Alloc_Blocks
          from DBA_DATA_FILES
          group by Tablespace_Name),
         (select Tablespace_Name FS_TS_NAME,
                 MAX(Blocks)  AS Max_Blocks,
                 SUM(Blocks) AS Sum_Free_Blocks
          from DBA_FREE_SPACE
          group by Tablespace_Name),
         (select (value / 1024 / 1024) DB_BLOCK_FACTOR
          from v\$parameter
          where name = 'db_block_size')
        where DT_TS_NAME = FS_TS_NAME
        order by PCT_USED DESC ),

=back

=item $vbObj = $o->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

This method calls VBTK::DBI::addVBObj after defaulting unspecified
parameters to best monitor tablespace usage in an Oracle
database.  For a detailed description of the addVBObj parameters, 
see L<VBTK::Parser>.  The defaults are as follows.
If you like all the defaults then you don't have to pass in any parms.  Note
that in this case, a separate VBObject is setup for each tablespace.

=over 4

=item VBObjName

Construct a VBObjName using the Host, User, and DSN strings.  Note that the
User and DSN strings are checked for '.' characters and any found are converted
to '-', so that we don't mess up the object's place in the hierarchy.

    VBObjName => ".<HOST>.db.<User>@<DSN>.dbspace.<tablespace-name>",

=item TextHistoryLimit

    TextHistoryLimit => 50,

item ReverseText

    ReverseText => 1,

=item Filter

Only show the rows for the current tablespace.

    Filter => '$data[0] eq <tablespace-name>',

=item Rules

If the tablespace contains the work 'TEMP', then the following defaults are
applied.  Temp tablespace should never get very full, so we set the thresholds
lower.

    Rules => {
        '$data[3] > 30' => 'Warn',
        '$data[3] > 40' => 'Fail' },

Otherwise the following defaults are applied:

    Rules => {
        '$data[3] > 92' => 'Warn',
        '$data[3] > 94' => 'Fail' },

=item StatusHistoryLimit

Limit to storing the last 30 status changes

    StatusHistoryLimit => 30,

=item ExpireAfter

    ExpireAfter => '(<Interval> * 3) seconds',

=item Description

    Description = qq(
        This object monitors the tablespaces in <DSN>. );

=item RrdColumns

Store the pct utiliziation in the Rrd db, so that it can be graphed.

    RrdColumns => [ 'int($data[3])' ],

=item RrdCF

Use the 'MAX' consolidation function.

    RrdCF => 'MAX',

=back

In addition to passing these defaults on in a call to VBTK::Wrapper::addVBObj,
this method captures the resulting VBTK::ClientObject pointer ($vbObj) and 
makes the following calls to '$vbObj->addGraphGroup':

  $vbObj->addGraphGroup (
    GroupNumber    => 1,
    Labels         => 'pct-full',
    Title          => "Tablespace Utilization for <DSN>.<tablespace-name>",
    CF             => 'MAX',
  );

Finally, a second graph group is added which combines all the tablespace
usage into a single graph.

  $vbObj->addGraphGroup (
    GroupNumber    => 2,
    DataSourceList => <list of tablespace-utilization object names>,
    Labels         => <list of tablespace names>,
    Title          => "Tablespace Utilization for <DSN>",
    CF             => 'MAX',
  );

This defines two graphGroups for the VBObject.  See L<VBTK::ClientObject> for
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
http://www.gnu.org/copyleft/gpl.html

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
