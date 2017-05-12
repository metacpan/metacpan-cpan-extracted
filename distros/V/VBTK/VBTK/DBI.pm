#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/DBI.pm,v $
#            $Revision: 1.8 $
#                $Date: 2002/03/04 20:53:06 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library used to execute select statements
#                       against a database and monitor the results
#           
#          Description: This library allows for the definition of select
#                       statements which are run against a database at
#                       specified intervals.  The results sets are parsed and
#                       evaluated using a specified set of rules and the 
#                       status of corresponding VBServer objects are set 
#                       accordingly.
#           
#           Depends on: VBTK::Common.pm, VBTK::Parser.pm
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
#       $Log: DBI.pm,v $
#       Revision 1.8  2002/03/04 20:53:06  bhenry
#       *** empty log message ***
#
#       Revision 1.7  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.6  2002/03/02 00:53:54  bhenry
#       Documentation updates
#
#       Revision 1.5  2002/02/13 07:38:52  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#       Revision 1.4  2002/01/28 19:35:14  bhenry
#       Bug Fixes
#
#       Revision 1.3  2002/01/25 07:17:35  bhenry
#       Changed to inherit from Parser
#
#

package VBTK::DBI;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK;
use VBTK::Common;
use VBTK::Parser;
use Storable qw(dclone);
use DBI;

# Inherit methods from Parser class
our @ISA = qw(VBTK::Parser);

our $VERBOSE = $ENV{VERBOSE};
our %POOL_CACHE;

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members, 
#               opens a connection to the database, and validates passed values.
# Input Parms:  VBTK::Oracle name pairs hash
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my ($type,$self);
    
    # If we're passed a hash as the first element, then it's probably from an
    # inheriting class, so just use it as is.
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

    my $defaultParms = {
        Interval        => 60,
        DSN             => $::REQUIRED,
        User            => undef,
        Auth            => undef,
        Attr            => undef,
        VBHeader        => undef,
        VBDetail        => [ '$data' ],
        PreProcessor    => undef,
        VBServerURI     => $::VBURI,
        LogFile         => undef,
        LogHeader       => undef,
        LogDetail       => undef,
        RotateLogAt     => '12:00am',
        ErrorStatus     => $::FAILED,
        SqlClause       => $::REQUIRED,
    };

    # Validate the passed parameters
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Try to lookup the password from a file in the VBHOME directory if
    # it wasn't specified.
    $self->lookupPassword;

    # Create a parser object, passing along all the input name/value pairs.  
    # Unused name/value pairs will be ignored
    # Create a parser object, passing along all the corresponding name/value
    # pairs.
    $self->SUPER::new();

    &VBTK::register($self);
    return $self;
}

#-------------------------------------------------------------------------------
# Function:     connect
# Description:  Establish a connection to the specified database, closing any 
#       existing connection;
# Input Parms:  Parser Name Pairs Hash
# Output Parms: None
#-------------------------------------------------------------------------------
sub connect
{
    my $self = shift;
    my $DSN = $self->{DSN};
    my $User = $self->{User};
    my $Auth = $self->{Auth};
    my $Attr = $self->{Attr};
    my $dbh = $self->{dbh};

    # If the dbh is already set in this object, then there was some kind of
    # error and we need to drop and re-open the connection.  We also need to
    # remove the corresponding entry from the pool_cache.
    if($dbh)
    {
        $dbh->disconnect();
        $POOL_CACHE{$DSN,$User,$Auth,$Attr} = undef;
    }

    $dbh = $POOL_CACHE{$DSN,$User,$Auth,$Attr};

    if ($dbh)
    {
        &log("Using existing DB connection to '$DSN' as '$User'");
    }
    else
    {
        &log("Connecting to '$DSN' as '$User' with Attr='$Attr'");

        $dbh = DBI->connect($DSN,$User,$Auth,undef,$Attr);

        # If the connect was successful, then add it into the pool.
        if($dbh) { $POOL_CACHE{$DSN,$User,$Auth,$Attr} = $dbh; }
        else     { &error("Cannot connect"); }
    }

    $self->{dbh} = $dbh;
    $self->{sth} = undef;
}

#-------------------------------------------------------------------------------
# Function:     run
# Description:  Execute the pre-defined SQL statement, retrieve the results,
#               and pass them to the corresponding VBTK::Parser object.  Also,
#               calculate how long until the next execution needs to take
#               place
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub run
{
    my $self = shift;
    my $Interval    = $self->{Interval};
    my $lastTime    = $self->{lastTime};
    my $ErrorStatus = $self->{ErrorStatus};
    my $sth         = $self->{sth};
    my $dbh         = $self->{dbh};
    my $now         = time;
 
    my (@data,$msg,@result_array,$errstr,$sleepTime);

    $self->connect unless ($dbh);

    # If it's not time to run yet, then return
    if(($sleepTime = $self->calcSleepTime()) > 0)
    {
        &log("Not time to run SQL, wait $sleepTime seconds")
            if ($VERBOSE > 1);
        return ($sleepTime,$::NOT_FINISHED);
    }

    # If not already defined, parse and prepare the sql statement
    $sth = $self->initialize_sql() if ($sth eq '');

    # Execute the SQL
    if(($sth ne '') && ($sth->execute))
    {
        &log("Processing sql query results") if ($VERBOSE);
        while(@data = $sth->fetchrow_array)
        {
            push(@result_array, [ @data ]);
        }

        $self->parseData(\@result_array);
    }
    # Handle errors
    else
    {
        $errstr = $dbh->{errstr} if ($dbh ne '');
        $msg = "Cannot execute SQL - $errstr";
        $self->parseData(undef,$ErrorStatus,$msg);
        &error($msg);

        # Re-open the connection    
        $self->connect;
    }

    $sleepTime = $self->calcSleepTime(1);

    ($sleepTime,$::NOT_FINISHED);
}

#-------------------------------------------------------------------------------
# Function:     initialize_sql
# Description:  Prepare the specified SQL.
# Input Parms:  None
# Output Parms: DBI prepared sql pointer
#-------------------------------------------------------------------------------
sub initialize_sql
{
    my $self = shift;
    my $SqlClause = $self->{SqlClause};
    my $dbh = $self->{dbh};
 
    return undef unless ($dbh);

    my $sql = $SqlClause;

    &log("Preparing SQL:\n$sql") if ($VERBOSE);
    my $sth = $dbh->prepare($sql) || 
        &error("Cannot prepare sql '$sql' - " . $dbh->errstr);

    $self->{sth} = $sth;

    ($sth);
}

#-------------------------------------------------------------------------------
# Function:     lookupPassword
# Description:  Try to lookup the password for the specified user.  If no user 
#               was specified, then just use the first entry in the password file.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub lookupPassword
{
    my $self = shift;
    my $User = $self->{User};
    my $DSN  = $self->{DSN};
    my ($user,$pswd);

    return unless (-f $::VBPSWD);

    &log("Looking up the password in '$::VBPSWD'") if ($VERBOSE);

    # Read the password file
    my $fh = new FileHandle "< $::VBPSWD";
    my @list = <$fh>;
    chomp(@list);
    $fh->close;

    # If no user was specified, then just use the first entry    
    if(! defined $User)
    {
        ($user,$pswd) = split(/[:\s]+/,$list[0]);
        $self->{User} = $user;
    }
    # Otherwise, try to find an entry which matches the specified user
    else
    {
        ($pswd) = grep(s/^$DSN[:\s]+$User[:\s]+//,@list);
    }

    $self->{Auth} = $pswd if (! defined $self->{Auth});

    (1);
}

# Put in a stub for handleSignal
sub handleSignal  { (0); }

1;
__END__

=head1 NAME

VBTK::Http - Database Monitoring

=head1 SYNOPSIS

  $d = new VBTK::DBI (
    Interval       => 60,
    DSN            => 'myoracle.world',
    User           => 'mylogin',
    Auth           => 'mypasswd',
    Attr           => 'Oracle',
    VBHeader       => undef,
    VBDetail       => [ '$data' ],
    VBServerURI    => 'http://myvbserver:4712',
    SqlClause      => 'select count(*) from v$sessions'
  );

  $d->addVBObj (
    VBObjName         => '.oracle.db.logincount',
    Rules             => [
      '$data[0] > 20' => 'Warning',
      '$data[0] > 40' => 'Failed' ],
    ExpireAfter       => '3 min',
    Description       => qq(
      This object monitors the number of users logged into the database),
  );

  &VBTK::runAll;

=head1 DESCRIPTION

This perl library provides the ability to do simple monitoring of any database
accessible with the perl DBI module, using select statements.  It makes use of
connection pooling, so that multiple SQL statements being run against the same
database will share a single connection.

Note that the 'new VBTK::DBI' and '$d->addVBObj' lines just initialize and
register the objects.  It's the &VBTK::runAll which starts the monitoring.

=head1 SUB-CLASSES

There are many values to setup when declaring a DBI object.  To 
simplify things, most of these values will default appropriately.  In
addition, several sub-classes are provided which have customized defaults
for specific uses.  The following sub-classes are currently provided:

=over 4

=item L<VBTK::DBI::OraLogins|VBTK::DBI::OraLogins>

Defaults for monitoring connections and blocked processes in an Oracle
database.

=item L<VBTK::DBI::OraTableSpace|VBTK::DBI::OraTableSpace>

Defaults for monitoring tablespace free-space and fragmentation in an 
Oracle database.

=back

Others will follow.  If you're interested in adding your own sub-class,
just copy and modify one of the existing ones.  Eventually, I'll get around
to documenting this nicely, but it's pretty self-explanatory.

=head1 PUBLIC METHODS

The following methods are available to the common user:

=over 4

=item $s = new VBTK::DBI (<parm1> => <val1>, <parm2> => <val2>, ...)

The allowed parameters are as follows.

=over 4

=item Interval

The interval (in seconds) on which the SQL query should be attempted. (Defaults
to 60)

    Interval => 60,

=item DSN

A string containing the DSN to connect to.  See the perl DBI man pages for
details on the DSN.  This is the 1st parameter passed to new DBI. (Required)

    DSN => 'myoracle.world',

=item User

A string containing the userid to connect with.  See the perl DBI man pages for
details on the User string.  This is the 2nd parameter passed to 'new DBI(  )'.

If no value is specified, then the VBTK::DBI module will look in the file
specified by the environment variable $VBPSWD and use the first line specified
there.  $VBPSWD defaults to '$VBHOME/conf/.pswd' if not set in the environment.
The $VBPSWD file should have a format of 'dsn userid password' with one entry
per line.

    User => 'myuserid',

=item Auth

A string containing the authorization string/password to connect with.  See the
DBI man pages for details on the Auth string.  This is the 3rd parameter passed
to 'new DBI(  )'.

If no value is specified, then the VBTK::DBI module will look in the file
specified by the environment variable $VBPSWD for a row with a userid and DSN
which match those specified in 'User' and 'DSN'.  $VBPSWD defaults to
'$VBHOME/conf/.pswd' if not set in the environment.  The $VBPSWD file should
have a format of 'dsn userid password' with one entry per line.

    Auth => 'mypassword',

=item Attr

A string containing the Attribute settings to connect with.  See the DBI
man pages for details on the Attr string.  This is the 4th parameter passed
to 'new DBI(  )'.  

    Attr => 'Oracle',

=item VBHeader

An array containing strings to be used as header lines when transmitting results
to the VB Server process.  (Defaults to 'none')

     VBHeader => [ 
        'Time              Number of logins',
        '----------------- ----------------' ];

=item VBDetail

An array containing strings to be used to format the detail lines which will be
sent to the VB Server process.  These strings can make use of the Perl picture
format syntax.  Be sure to either use single-quotes or escape out the '$' vars
so that they don't get evaluated until later.

    VBDetail => [
        '@<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>>>',
        '$time             $data[0]' ],

The following variables will be set just before these detail lines are evaluated:

=over 4

=item $time

A datestamp of the form YYYYMMDD-HH:MM:SS

=item @data

An array of arrays containing the rows and columns of the data retrieved in the 
SQL query.

=item @delta

An array containing the delta's calculated between the current @data and the
previous @data.  In multi-row output, the row number is used to match up 
multiple @data arrays with their previous @data values to calulate the deltas.
These deltas are most useful when monitoring the change in counters.

=back

=item PreProcessor

A pointer to a subroutine to which incoming data should be passed for
pre-processing.  The subroutine will be passed a pointer to the @data array
as received by the Parser.  This will be an array of arrays containing the
rows and columns as retrieved from the executed SQL.  The PreProcessor
subroutine can then alter the data, remove rows, add summary rows, etc.
A common use for this would be to ignore rows you didn't want to appear
in the output.

    # Only include rows where $data[0] is > 0.
    PreProcessor = sub {
        my($data) = @_;
        @{$data} = grep($_->[0] > 0,@{$data});
    }

=item VBServerURI

A URI which specifies which VB Server to report results to.  Defaults to the 
environment variable $VBURI.

    VBServerURI => 'http://myvbserver:4712',

=item LogFile

A string containing the path to a file where a log file should be written.  
Leave blank if no log file is desired.  (Defaults to undef).

    LogFile => '/var/log/oracle.logincount.log',

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
(Defaults to 12:00am)

    RotateLogAt => '12:00am',

=item ErrorStatus

A string containing a status to which any VBObjects should be set if there
is an error while attempting to connect to the database or run the SQL.
(Defaults to Failed).

    ErrorStatus => 'Warning',

=item SqlClause

A string containing the SQL statement to execute.  The resulting rows and
columns will be loaded into the @data array for processing.

    SQL => 'select count(*) from v$session',

=back

=item $o = $s->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

The 'addVBObj' is used to define VBObjects which will appear on the VBServer
to which status reports are transmitted.  See L<VBTK::Parser> for a detailed
description of the main parameters.

=back

=head1 PRIVATE METHODS

The following private methods are used internally.  Do not try to use them
unless you know what you are doing.

To be documented...

=head1 SEE ALSO

=over 4

=item L<VBTK|VBTK>

=item L<VBTK::DBI::OraLogins|VBTK::DBI::OraLogins>

=item L<VBTK::DBI::OraTableSpace|VBTK::DBI::OraTableSpace>

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
