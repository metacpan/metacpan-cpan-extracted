#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Snmp.pm,v $
#            $Revision: 1.11 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library used to monitor Snmp agents,
#                       writing to Log files, and setting VBServer objects as
#                       specified.
#
#           Invoked by: vbsnmp
#
#           Depends on: VBTK::Common.pm, VBTK::Parser
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
#       $Log: Snmp.pm,v $
#       Revision 1.11  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.10  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.9  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.8  2002/02/19 19:10:42  bhenry
#       *** empty log message ***
#
#       Revision 1.7  2002/02/13 07:38:51  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#       Revision 1.6  2002/01/28 22:51:27  bhenry
#       *** empty log message ***
#
#       Revision 1.5  2002/01/28 22:48:23  bhenry
#       *** empty log message ***
#
#       Revision 1.4  2002/01/28 19:35:14  bhenry
#       Bug Fixes
#
#       Revision 1.3  2002/01/25 07:15:10  bhenry
#       Changed to inherit from Parser
#
#

package VBTK::Snmp;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK;
use VBTK::Common;
use VBTK::Parser;
use SNMP;
use Storable qw(dclone);

#$SNMP::debugging = 3;
#$SNMP::auto_init_mib = 0;
$SNMP::use_long_names = 1;

SNMP::initMib(); # parses default list of Mib modules from default dirs
SNMP::addMibDirs("/usr/local/share/snmp/mibs");

# Inherit methods from Parser and SNMP classes
our @ISA = qw(VBTK::Parser);

our $VERBOSE = $ENV{VERBOSE};

our $DEFAULT_TIMEOUT=3;
our $DEFAULT_RETRIES=1;

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members,
#               create an Snmp session, check passed Snmp labels.
#
# Input Parms:  VBTK::Snmp name/value hash
# Output Parms: Pointer to self
#-------------------------------------------------------------------------------
sub new
{
    my ($type,$self);
    
    # If we're passed a hash as the first element, then it's probably from an
    # inheriting class
    if((defined $_[0])&&(UNIVERSAL::isa($_[0], 'HASH')))
    {
        $self = shift;
    }
    # Otherwise, allocate a new hash, bless it and handle any passed parms
    else
    {
        $type = shift;
        $self = {};
        bless $self, $type;

        # Store all passed input name pairs in the object
        $self->set(@_);
    }

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval          => 60,
        Labels            => $::REQUIRED,
        Host              => $::REQUIRED,
        Port              => $::REQUIRED,
        Community         => undef,
        VBServerURI       => $::VBURI,
        VBHeader          => undef,
        VBDetail          => [ '$data' ],
        LogFile           => undef,
        LogHeader         => undef,
        LogDetail         => undef,
        RotateLogAt       => undef,
        PreProcessor      => undef,
        Timeout           => $DEFAULT_TIMEOUT,
        Retries           => $DEFAULT_RETRIES,
        ErrorStatus       => $::FAILED,
        GetMultRows       => undef
    };

    # Run the validation, setting defaults if values are not already set
    $self->validateParms($defaultParms);

    # Create a parser object, passing along all the input name/value pairs.
    # Unused name/value pairs will be ignored
    $self->SUPER::new() || return undef;

    &log("Setting up SNMP Session to $self->{Host}:$self->{Port}")
        if ($VERBOSE);

    my($label,$oid,$msg);

    # Create the SNMP object
    $self->{snmpSession} = new SNMP::Session(
        DestHost   => $self->{Host},
        Community  => $self->{Community},
        RemotePort => $self->{Port},
        Version    => '1',
        Timeout    => $self->{Timeout} * 1000000,
        Retries    => $self->{Retries});

    fatal("Can't connect to '$self->{Host}:$self->{Port}'")
        if ($self->{snmpSession} eq '');

    # Validate passed Snmp labels
    foreach $label (@{$self->{Labels}})
    {
        $oid = SNMP::translateObj($label);

        &fatal("Cannot determine oid for '$label'") if ($oid eq '');
        &log("Translated '$label' to '$oid'") if ($VERBOSE > 1);
    }

    # Add self to the list of all defined VBTK::Snmp objects
    &VBTK::register($self);
    return $self;
}

#-------------------------------------------------------------------------------
# Function:     addMibFiles
# Description:  Call the SNMP::addMibFiles method
# Input Parms:  List of Mib files to include
# Output Parms: None
#-------------------------------------------------------------------------------
sub addMibFiles
{
    SNMP::addMibFiles(@_);
    (0);
}

#-------------------------------------------------------------------------------
# Function:     addMibDirs
# Description:  Call the SNMP::addMibDirs method
# Input Parms:  List of Mib dirs to search
# Output Parms: None
#-------------------------------------------------------------------------------
sub addMibDirs
{
    SNMP::addMibDirs(@_);
    return 1;
}

#-------------------------------------------------------------------------------
# Function:     run
# Description:  Retrieve and process the specified Snmp values
# Input Parms:  None
# Output Parms: Time till next retrieval
#-------------------------------------------------------------------------------
sub run
{
    # Unload variables from the object
    my $self = shift;
    my $snmpSession   = $self->{snmpSession};
    my $Labels        = $self->{Labels};
    my $Interval      = $self->{Interval};
    my $GetMultRows   = $self->{GetMultRows};
    my $ErrorStatus   = $self->{ErrorStatus};
    my $Host      = $self->{Host};
    my $Port      = $self->{Port};

    # Define local variables
    my (@data,$value,$lastvalue,$delta,$flag,@table,$vars,@label_array,$keylabel);
    my ($label,$ptr,$sleepTime,$msg);
    my $now = time;

    # If it's not time to run yet, then return
    if(($sleepTime = $self->calcSleepTime()) > 0)
    {
        &log("Not time to check $Host:$Port, wait $sleepTime seconds")
            if ($VERBOSE > 1);
        return ($sleepTime,$::NOT_FINISHED);
    }

    &log("Constructing the varlist") if ($VERBOSE);
    # Construct a 2-dimensional array of label names.  This is the format needed
    # to make the call to SNMP::Varlist.
    foreach $label (@{$Labels})
    {
        push(@label_array, [ $label, 0 ]);
    }

    # Pull out the first label name
    $keylabel = $label_array[0][0];

    # Setup the vars object to be used in data retrieval
    &log("Retrieving SNMP values from $Host:$Port") if ($VERBOSE > 1);
    $vars = new SNMP::VarList ( @label_array );

    for(;;)
    {
        # Retrieve one row of data.  If the 'GetMultRows' option was specified
        # then keep calling getnext until you've retrieve all matching rows.
        if($GetMultRows) { @data = $snmpSession->getnext($vars); }
        else             { @data = $snmpSession->get($vars); }

        # If there are errors, then pass the error along to the parser object
        # along with the error message written in red.
        if ($snmpSession->{ErrorStr} ne '')
        {
            $msg = "Error: Can't retrieve snmp values: " . $snmpSession->{ErrorStr};
            &log($msg);
            $self->parseData(undef,$ErrorStatus,red($msg) . "\n");
            last;
        }

        if($GetMultRows)   
        {
            if($$vars[0]->tag =~ /$keylabel$/)
            {
                    &log("Retrieved " . join(":",@data)) if ($VERBOSE > 2);
                    push(@table, [ @data ]);
                    next;
            }
        }
        else
        {
            &log("Retrieved " . join(":",@data)) if ($VERBOSE > 2);
            push(@table, [ @data ]);
        }

        # Check to see if any data was retrieved, parse it appropriately
        # and then break out of the loop.
        if($table[0] eq '')
        {
            $msg = "Error: No values retrieved";
            &log($msg);
            $self->parseData(undef,$ErrorStatus,red($msg) . "\n");
        }
        else
        {
            $self->parseData(\@table);
        }
        last;
    }

    $sleepTime = $self->calcSleepTime(1);

    ($sleepTime,$::NOT_FINISHED);
}

1;
__END__

=head1 NAME

VBTK::Snmp - Snmp monitoring.

=head1 SYNOPSIS

  $stdHeader = 
      [ 'Time              Idx IfDescr                           Bytes/Sec In',
        '----------------- --- --------------------------------- ------------' ];
  $stdDetail = 
      [ '@<<<<<<<<<<<<<<<< @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>>>>>',
        '$time,            @data[0,1],                           int($delta[2]/60)' ];

  $s = new VBTK::Snmp (
    Interval          => 60,
    Labels            => [ 'ifIndex','ifDescr','ifInOctets' ],
    Host          => 'myhost',
    Port          => 161,
    VBServerURI       => 'http://myvbserver:4712',
    VBHeader          => $stdHeader,
    VBDetail          => $stdDetail,          
    LogFile           => '/var/log/snmp.myhost.log'
    LogHeader         => $stdHeader,
    LogDetail         => $stdDetail,
    RotateLogAt       => '12:00am',
    Timeout           => undef,
  );

  $s->addVBObj (
    VBObjName           => ".myhost.netio",
  );

  &VBTK::runAll;

=head1 DESCRIPTION

This perl library provides the ability to request SNMP data from a specified
host and then set the status of a VBObject based on the results of that data.

Note that the 'new VBTK::Snmp' and '$s->addVBObj' lines just initialize and 
register the objects.  It's the &VBTK::runAll which starts the monitoring.

=head1 SUB-CLASSES

There are many values to setup when declaring an SNMP monitor object.  To 
simplify things, most of these values will default appropriately.  In
addition, several sub-classes are provided which have customized defaults
for specific uses.  The following sub-classes are provided:

=over 4

=item L<VBTK::Snmp::Mib2NetIO|VBTK::Snmp::Mib2NetIO>

Defaults for monitoring network I/O.

=item L<VBTK::Snmp::Dynamo|VBTK::Snmp::Dynamo>

Defaults for monitoring a dynamo server.

=item L<VBTK::Snmp::WinNTCpu|VBTK::Snmp::WinNTCpu>

Defaults to monitoring CPU utilization on an NT server, by using the SNMP
packages in the NT resource kit.

=back

Others will follow.

=head1 PUBLIC METHODS

The following methods are available to the common user:

=over 4

=item $s = new VBTK::Snmp (<parm1> => <val1>, <parm2> => <val2>, ...)

The allowed parameters are:

=over 4

=item Interval

The interval (in seconds) on which the command should be run.  (Defaults to 60)

    Interval => 60,

=item Labels

An array of strings containing SNMP labels or oid's to be monitored.
(Required)

    Labels => [ 'ifIndex','ifDescr','ifInOctets' ],

=item Host

Hostname or IP address to monitor.

    Host => 'myhost',

=item Port

Port number on which the snmp service is listening

=item Community

The community string to use when connecting to the Snmp host.  (Default to 'public')

=item VBServerURI

A URI which specifies which VB Server to report results to.  Defaults to the 
environment variable $VBURI.

    VBServerURI => 'http://myvbserver:4712',

=item VBHeader

An array containing strings to be used as header lines when transmitting results
to the VB Server process.

  VBHeader = [ 
      'Time              Idx IfDescr                           Bytes/Sec In',
      '----------------- --- --------------------------------- ------------' ];

=item VBDetail

An array containing strings to be used to format the detail lines which will be
sent to the VB Server process.  These strings can make use of the Perl picture
format syntax.

  VBDetail => [
      '@<<<<<<<<<<<<<<<< @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>>>>>',
      '$time,            @data[0,1],                           int($delta[2]/60)' ];

The following variables will be set just before these detail lines are evaluated:

=over 4

=item $time

A datestamp of the form YYYYMMDD-HH:MM:SS

=item @data

An two-dimensional array containing the SNMP data returned.

=item @delta

An array containing the delta's calculated between the current @data and the
previous @data.  In multi-row output, the row number is used to match up 
multiple @data arrays with their previous @data values to calulate the deltas.
These deltas are most useful when monitoring the change in counters.  This is
very common in SNMP monitors.

=back

=item LogFile

A string containing the path to a file where a log file should be written.

    LogFile => '/var/log/snmp.myhost.log',

=item LogHeader

Same as VBHeader, but to be used in formatting the log file.

=item LogDetail

Same as VBDetail, but to be used in formatting the log file.

=item RotateLogAt

A string containing a date/time expression indicating when the log file should
be rotated.  When the log is rotated, the current log will have a timestamp
appended to the end of it after which logging will continue to a new file with
the original name.  The expression will be passed to L<Date::Manip|Date::Manip>
so it can be just about any recognizable date/time expression.

    RotateLogAt => '12:00am',

=item PreProcessor

A pointer to a subroutine to which incoming data should be passed for
pre-processing.  The subroutine will be passed a pointer to the @data array
as received by the Parser.  With SNMP data, the @data array will contain
an array of arrays.  The subroutine can modify this data, remove rows, 
group rows into columns, etc.  This is a fairly advanced function, so don't
use it unless you know what you're doing.

    # Filter out any rows where column 2 is less than 10
    PreProcessor = sub {
        my($data) = @_;
        @{$data} = grep($_->[2] >= 10,@{$data});
    }

=item Timeout

A number indicating the number of seconds to wait for the response from the
SNMP host before re-trying.  Be careful with setting this too
high, since the VBTK engine is single-threaded, and a long delay can delay
status reports from other objects.  (Defaults to 3)

    Timeout => 3,

=item Retries

A number indicating the number of times to retry the SNMP request before 
setting the status to 'ErrorStatus'.  Be careful with setting this too
high, since the VBTK engine is single-threaded, and a long delay can delay
status reports from other objects.  (Defaults to 1)

    Retries => 1,

=item ErrorStatus

The status to which any associated VBObjects should be set if the SNMP
request times out or fails.  (Defaults to 'Failed')

    ErrorStatus => 'Warning',

=item GetMultRows

A boolean (0 or 1) indicating whether the SNMP monitor should expect multiple
rows in the result set.  This must be set to get correct results since it 
determines whether we'll use 'get' or 'getnext' to retrieve the data.
(Defaults to 0)

    GetMultRows => 1,

=back

=item $o = $s->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

The 'addVBObj' is used to define VBObjects which will appear on the VBServer
to which status reports are transmitted.  See the L<VBTK::Parser|VBTK::Parser>
class for a list of valid parms and their descriptions.  

=item $s->addMibFiles(<file1>,...)

Add's specific Mib files into the list of MIB files to be searched when
resolving Label names to OID's.

    $s->addMibFiles('/usr/vbtk/mib/NTCPU.mib');

=item $s->addMibDirs(<dir1>,...)

Add's directories into the list of directories to search when resolving 
Label names to OID's.

    $s->addMibDirs('/usr/vbtk/mib');

=back

=head1 PRIVATE METHODS

The following private methods are used internally.  Do not try to use them
unless you know what you are doing.

To be documented...

=head1 SEE ALSO

VBTK
VBTK::Parser

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
