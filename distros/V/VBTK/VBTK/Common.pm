#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Common.pm,v $
#            $Revision: 1.14 $
#                $Date: 2002/03/04 20:53:06 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library to store common subroutines used
#           by all of the vbsuite products.
#
#          Description: This library contains common subroutines and variables used
#           globally by all processes.
#
#           Invoked by: All VBTKSuite Modules and client processes
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
#       $Log: Common.pm,v $
#       Revision 1.14  2002/03/04 20:53:06  bhenry
#       *** empty log message ***
#
#       Revision 1.13  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.12  2002/03/02 00:53:54  bhenry
#       Documentation updates
#
#       Revision 1.11  2002/02/19 19:06:14  bhenry
#       Added deltaSec function
#
#       Revision 1.10  2002/02/13 07:38:15  bhenry
#       Moved write_pid_file functionality from Common into Controller
#
#       Revision 1.9  2002/02/09 08:45:00  bhenry
#       Improved logic from determining Date::Manip timezone
#
#       Revision 1.8  2002/02/08 02:16:04  bhenry
#       *** empty log message ***
#
#       Revision 1.7  2002/01/30 17:05:41  bhenry
#       *** empty log message ***
#
#       Revision 1.6  2002/01/26 06:15:59  bhenry
#       *** empty log message ***
#
#       Revision 1.5  2002/01/25 07:18:03  bhenry
#       Added method to check Date::Manip timezone for errors
#
#       Revision 1.4  2002/01/23 18:33:35  bhenry
#       Re-arranged OS determining code
#
#       Revision 1.3  2002/01/21 17:07:40  bhenry
#       Disabled 'uninitialized' warnings
#

# These first variables need to be in the main package
package main;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off these warnings
no warnings qw(uninitialized);

# These global variables can be set through environment variables,
# or will be defaulted appropriately.
our $VBHOME = $ENV{VBHOME} || "/usr/vbtk";
our $VBPORT = $ENV{VBPORT} || "4712";
our $VBURI  = $ENV{VBURI}  || "http://vbserver:$VBPORT";

our $VBLOGS = $ENV{VBLOGS} || "$VBHOME/logs";
our $VBOBJ  = $ENV{VBOBJ}  || "$VBHOME/vbobj";

our $RRDBIN = $ENV{RRDBIN} || "/usr/local/bin/rrdtool";

# These we can't allow environment variable overrides, because it would make
# it too hard during the sync, trying to figure out where to put everything.
our $VBCONF = "$VBHOME/conf";
our $VBBIN  = "$VBHOME/bin";

our $VBPSWD = $ENV{VBPSWD} || "$VBCONF/.pswd";


# Setup global variables
our $SUCCESS="Success";
our $WARNING="Warning";
our $TIMEOUT="Timeout";
our $FAILED="Failed";
our $EXPIRED="Expired";
our $RUNNING="Running";

our $ERROR = 1;
our $FINISHED = 0;
our $NOT_FINISHED = -1;

our %VB_STATUS_MAP = (S => $SUCCESS, "s" => $SUCCESS,
                      W => $WARNING,  w  => $WARNING,
                      T => $TIMEOUT,  t  => $TIMEOUT,
                      F => $FAILED,   f  => $FAILED,
                      E => $EXPIRED,  e  => $EXPIRED,
                      R => $RUNNING,  r  => $RUNNING);

our %VB_STATUS_RANK = ('' => 0,
                       $SUCCESS => 1,
                       $RUNNING => 2, 
                       $EXPIRED => 3, 
                       $WARNING => 4,
                       $TIMEOUT => 5, 
                       $FAILED => 6);

our $OS;
our $SL;

# Figure out what O/S we're running under
unless ($OS) {
    unless ($OS = $^O) {
    require Config;
    $OS = $Config::Config{'osname'};
    }
}

# Decide what file separator to use based on the OS.
if    ($OS=~/Win|os2|dos/i) { $SL = '\\'; }
elsif ($OS=~/^MacOS$/i)     { $SL = ':'; }
else                        { $SL = '/'; }

use FileHandle;
STDOUT->autoflush(1);

# Setup some static variables
our $REQUIRED = "$;$;::REQUIRED_PARM::$;$;";
our $MASTER_NODE = "::MASTER_NODE::";
our $VERBOSE=$ENV{VERBOSE};

use Sys::Hostname;
our $HOST = hostname();

# Enter the common package
package VBTK::Common;

use Date::Manip qw(ParseDateDelta Delta_Format);
use POSIX;

# Export all the common methods
require Exporter;

# use vars qw(@ISA);

our @ISA = qw(Exporter);
our @EXPORT = qw(log error fatal map_status find_higher_status
                 datestamp color_by_status testFork testAlarm
                 red green yellow blue bold log_datestamp validateParms set
                 unixdate deltaSec);

# Setup global package variables
our $PID_SET = 0;
our $VERBOSE=$ENV{VERBOSE} || 0;

#-------------------------------------------------------------------------------
# Function:     validateParms
# Description:  Validate the first passed hash of parameters against the second
#               passed hash.  Any keys in the first hash must exist in the 
#               second hash, and any values which are unset in the first hash  
#               will be set to the corresponding values in the second hash.
# Input Parms:  Hash to be validate, Hash with default values
# Output Parms: None
#-------------------------------------------------------------------------------
sub validateParms
{
    my ($parms,$defaults,$caller) = @_;
    my (%keyExists,$hash);

    # If the package name was not passed, then try to determine it.
    ($caller) = (caller(1))[3] if (! defined $caller);

    # Make sure both passed entries are hashes
    foreach $hash ($parms, $defaults)
    {
        &fatal("Call to validateParms must consist of two hashes")
            if (ref($hash) =~ /^$|^SCALAR$|^ARRAY$/);
    }

    # Make a list of the keys in the 'defaults' hash
    %keyExists = map { $_ => 1 } keys %{$defaults};

    # Now check to see if there are any keys in the parms hash which are not in
    # the defaults hash
    foreach my $key (keys %{$parms})
    {
        unless($keyExists{$key})
        {
            &error("Invalid parameter '$key' in call to '$caller'");
            return 0;
        }
    }

    # If we made it this far, then let's setup defaults
    foreach my $key (keys %{$defaults})
    {
        # Check to see if it's a required value
        if ((defined $defaults->{$key})&&($defaults->{$key} eq $::REQUIRED)&&
            (! defined $parms->{$key}))
        {
            &error("Must specify '$key' in call to '$caller'");
            return 0;
        }

        # Set it to the default value if it's blank
        $parms->{$key} = $defaults->{$key} 
            if ((! defined $parms->{$key})&&(defined $defaults->{$key}));
    }
    (1);
}

#-------------------------------------------------------------------------------
# Function:     set
# Description:  Set an attribute of the monitor object
# Input Parms:  Associate array of attributes and their values
# Output Parms: None
#-------------------------------------------------------------------------------
sub set
{
    my $obj = shift;
    my %args = @_;
    my ($pkg,$printVal);

    $pkg = caller;

    foreach (keys %args)
    {
        if($VERBOSE > 2)
        {
            $printVal = (defined $args{$_}) ? "'$args{$_}'" : 'undef';
            &log("Setting $pkg" . "{$_} to $printVal ");
        }
        $obj->{$_} = $args{$_};
    }
}

#-------------------------------------------------------------------------------
# Function:     unixdate
# Description:  Parse the input string and convert it to the unix date integer
# Input Parms:  Date String
# Output Parms: Unix date
#-------------------------------------------------------------------------------
sub unixdate
{
    my($timeStr) = @_;
    my($time);

    # If it's a known pattern, then try to do it ourselves, since the 
    # Date::Manip::UnixDate routine is very slow.
    if($timeStr =~ /^(\d{4})(\d{2})(\d{2})-?(\d{2}):(\d{2}):(\d{2})\s*$/)
    {
        $time = mktime($6,$5,$4,$3,($2-1),($1-1900),undef,undef,-1);
        &log("Used mktime to convert '$timeStr' to '$time'") if ($VERBOSE > 3);
    }
    else
    {
        $time = &Date::Manip::UnixDate($timeStr, "%s");
        &log("Used UnixDate to convert '$timeStr' to '$time'") if ($VERBOSE > 3);
    }

    $time;
}

#-------------------------------------------------------------------------------
# Function:     checkDateManipTZ
# Description:  Run a test of DateManip and make sure that it's not going to 
#               crash the program if it can't find the timezone.
# Input Parms:  None
# Output Parms: 1 or 0
#-------------------------------------------------------------------------------
sub checkDateManipTZ
{
    my ($tz);
    
    eval { $tz = &Date::Manip::Date_TimeZone; };
    
    &log("Date::Manip timezone is $tz") if ($VERBOSE);
    
    if (($@)||(! $tz))
    {
        &log("Date::Manip can't determine timezone, attempting to parse from \$TZ")
            if($VERBOSE);
        
        if($ENV{'TZ'} =~ /^([A-Z]{3,3})/)
        {
            &log("Attempting to set Date::Manip timezone to '$1'") if ($VERBOSE);
            &Date::Manip::Date_Init("TZ=$1");
        }
        
        eval { $tz = &Date::Manip::Date_TimeZone; };
        
        if (($@)||(! $tz))
        {
            &log("Can't determine timezone, setting to GMT") if ($VERBOSE);
            &Date::Manip::Date_Init("TZ=GMT");
        }
    }

    (1);
}

#-------------------------------------------------------------------------------
# Function:     find_higher_status
# Description:  Compare two status values and return the higher one
# Input Parms:  Status 1, Status 2
# Output Parms: Higher of the two statuses
#-------------------------------------------------------------------------------
sub find_higher_status
{
    my ($status_1,$status_2) = @_;

    $status_1 = &map_status($status_1);
    $status_2 = &map_status($status_2);

    if($::VB_STATUS_RANK{$status_1} > $::VB_STATUS_RANK{$status_2})
    {
        ($status_1);
    }
    else
    {
        ($status_2);
    }
}

#-------------------------------------------------------------------------------
# Function:     testFork
# Description:  Check to see if this platform supports forking.
# Input Parms:  
# Output Parms: 
#-------------------------------------------------------------------------------
sub testFork
{
    &log("Testing fork operation") if ($VERBOSE);

    my($pid);

    if($pid = fork)
    {
        &log("Fork was successful, enabling forking") if ($VERBOSE);
        return 1;
    }
    elsif(defined $pid)
    {
        exit 0;
    }

    &log("Fork failed, disabling forking") if ($VERBOSE);
    (0);
}

#-------------------------------------------------------------------------------
# Function:     testAlarm
# Description:  Check to see if this platform supports alarm
# Input Parms:  
# Output Parms: 
#-------------------------------------------------------------------------------
sub testAlarm
{
    &log("Testing alarm operation") if ($VERBOSE);

    # Test to see if alarm is supported on this platform
    eval { alarm 0; };

    if ($@ eq '')
    {
        &log("Alarm was successful, enabling alarm") if ($VERBOSE);
        return 1
    }

    &log("Alarm failed, disabling alarm");
    (0);
}

#-------------------------------------------------------------------------------
# Function:     map_status
# Description:  Map the passed word to one of the pre-defined status values,
#               based on the first character.
# Input Parms:  Unformatted status
# Output Parms: Pre-defined status
#-------------------------------------------------------------------------------
sub map_status
{
    my($in_status) = shift;
    my($first_char) = substr($in_status,0,1);
    my($out_status) = $::VB_STATUS_MAP{$first_char};
    &error("Invalid status '$in_status' specified") if ($out_status eq '');
    ($out_status);
}

#-------------------------------------------------------------------------------
# Function:     log_datestamp
# Description:  Return the current datestamp in YYYYMMDD-HH:MM:SS format
# Input Parms:  None
# Output Parms: DateStamp
#-------------------------------------------------------------------------------
sub log_datestamp
{
    my($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
    $year += 1900;
    ++$mon;
    sprintf "%04d%02d%02d-%02d:%02d:%02d",$year,$mon,$mday,$hour,$min,$sec;
}

#-------------------------------------------------------------------------------
# Function:     deltaSec
# Description:  Evaluate the passed string and return the number of seconds it
#               represents.
# Input Parms:  String
# Output Parms: Seconds
#-------------------------------------------------------------------------------
sub deltaSec
{
    my ($str) = @_;
    
    my $delta    = &ParseDateDelta($str) || return undef;
    my $deltaSec = &Delta_Format($delta,0,'%st') || return undef;

    int($deltaSec);
}

#-------------------------------------------------------------------------------
# Function:     gmtdatestamp
# Description:  Return the current datestamp in YYYYMMDDHH:MM:SS format.  This
#               is used by internal functions to generate Date::Manip compatible
#       timestamps.  Do not change the format!!
# Input Parms:  None
# Output Parms: Datestamp
#-------------------------------------------------------------------------------
sub gmtdatestamp
{
    my $time = shift || time;
    my($sec,$min,$hour,$mday,$mon,$year) = gmtime($time);
    $year += 1900;
    ++$mon;
    sprintf "%04d%02d%02d%02d:%02d:%02d",$year,$mon,$mday,$hour,$min,$sec;
}

#-------------------------------------------------------------------------------
# Function:     datestamp
# Description:  Return the current datestamp in YYYYMMDDHH:MM:SS format.  This
#               is used by internal functions to generate Date::Manip compatible
#       timestamps.  Do not change the format!!
# Input Parms:  None
# Output Parms: Datestamp
#-------------------------------------------------------------------------------
sub datestamp
{
    my $time = shift || time;
    my($sec,$min,$hour,$mday,$mon,$year) = localtime($time);
    $year += 1900;
    ++$mon;
    sprintf "%04d%02d%02d%02d:%02d:%02d",$year,$mon,$mday,$hour,$min,$sec;
}

#-------------------------------------------------------------------------------
# Function:     log
# Description:  Print to STDOUT with a timestamp.  If a reference to an array is
#               passed, the message will also be pushed onto the array.
# Input Parms:  Msg
# Output Parms: None
#-------------------------------------------------------------------------------
sub log
{
    my($msg,$ptr,$suppress_stdout,$suppress_messages) = @_;
    my($date) = &log_datestamp;

    push(@{$ptr},"$date - $msg\n")
        if (defined($ptr) && !defined($suppress_messages));
    print STDERR "$date - $msg\n" unless defined($suppress_stdout);
    
    (1);
}

#-------------------------------------------------------------------------------
# Function:     error
# Description:  Print to STDOUT with a timestamp with the message 'Error'
# Input Parms:  Msg
# Output Parms: None
#-------------------------------------------------------------------------------
sub error
{
    my($msg,$ptr,$suppress_stdout,$suppress_messages) = @_;

    &log("Error: $msg",$ptr,$suppress_stdout,$suppress_messages);

    (1);
}

#-------------------------------------------------------------------------------
# Function:     fatal
# Description:  Print to STDOUT with a timestamp with the message 'Error' and exit
# Input Parms:  Msg
# Output Parms: None
#-------------------------------------------------------------------------------
sub fatal
{
    &error(@_);
    exit 1;
}

#-------------------------------------------------------------------------------
# Function:     red, green, blue, bold
# Description:  Return the passed string enclosed in a HTML font statement
#               which will produce the color or text format of the function name.
# Input Parms:  Text
# Output Parms: Formatted text
#-------------------------------------------------------------------------------
sub red   { ("<FONT COLOR='#FF0000'>" . $_[0] . "</FONT>"); }
sub green { ("<FONT COLOR='#00FF00'>" . $_[0] . "</FONT>"); }
sub blue  { ("<FONT COLOR='#0000FF'>" . $_[0] . "</FONT>"); }
sub yellow { ("<FONT COLOR='#FF6633'>" . $_[0] . "</FONT>"); }
sub bold  { ("<B>" . $_[0] . "</B>"); }

#-------------------------------------------------------------------------------
# Function:     color_by_status
# Description:  Map the passed word to one of the pre-defined status values,
#               based on the first character.
# Input Parms:  status, text
# Output Parms: Html
#-------------------------------------------------------------------------------
sub color_by_status
{
    my($status,$text) = @_;

    if($status eq $::SUCCESS)    { green($text); }
    elsif($status eq $::WARNING) { yellow($text); }
    elsif($status eq $::FAILED)  { red($text); }
    else                         { ($text); }
}

1;

__END__

=head1 NAME

VBTK::Common - Internal module of VBTK

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This is an internal module of the VB tool kit used to gather together misc
subroutines into a common area.  Do not try to access this package
directly.

=head1 SEE ALSO

=over 4

=item L<VBTK|VBTK>

=item L<VBTK::Parser|VBTK::Parser>

=item L<VBTK::ClientObject|VBTK::ClientObject>

=item L<VBTK::Server|VBTK::Server>

=back

=head1 AUTHOR

Brent Henry, vbtk@yahoo.com

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
