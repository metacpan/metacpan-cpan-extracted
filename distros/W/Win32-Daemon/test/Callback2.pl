#//////////////////////////////////////////////////////////////////////////////
#//
#//  Callback2.pl
#//  Win32::Daemon Perl extension test script employing Callbacks
#//
#//  Copyright (c) 1998-2008 Dave Roth
#//  Courtesy of Roth Consulting
#//  http://www.roth.net/
#//
#//  This file may be copied or modified only under the terms of either 
#//  the Artistic License or the GNU General Public License, which may 
#//  be found in the Perl 5.0 source kit.
#//
#//  2008.03.24  :Date
#//  20080324    :Version
#//////////////////////////////////////////////////////////////////////////////

# Demonstration of an AutoStart Service using the Win32::Daemon
# Perl extension. This service will auto launch applications
# when it starts. Effectively enabling Windows to auto start
# applications at boot time, before a user ever logs on.

use Win32::Daemon;

my %List;
my $START_TIME = time();

# For DEBUG version ONLY!!
if( Win32::Daemon::IsDebugBuild() )
{
#    Win32::Daemon::DebugOutputPath( "\\\\.\\pipe\\syslog" );
}

my ( $SCRIPT_DIR, $SCRIPT_FILE_NAME ) = ( Win32::GetFullPathName( $0 ) =~ /^(.*)\\([^\\]*)$/ );
$| = 1;

#my $LOG_FILE = shift @ARGV || "$SCRIPT_DIR\\$SCRIPT_FILE_NAME.log";
my $LOG_FILE = "\\\\.\\pipe\\syslog";

if( open( LOG, ">$LOG_FILE" ) )
{
    my $StartTime = localtime( $START_TIME );
    my $BackupHandle = select( LOG );
    $| = 1;
    select( $BackupHandle );
    print LOG << "EOT"
# Service Starting
# Script: $0
# Perl: $X
# PID: $$
# Date: $StartTime
EOT
}    

Win32::Daemon::RegisterCallbacks( {
    start   =>  \&Callback_Start,
    running =>  \&Callback_Running,
    stop    =>  \&Callback_Stop,
    pause   =>  \&Callback_Pause,
    continue    =>  \&Callback_Continue,
} );

Log( "Starting service" );
%Context = (
    last_state => SERVICE_STOPPED,
    count   =>  0,
    start_time => time(),
);

Win32::Daemon::StartService( \%Context, 2000 );

Log( "Shutting down the service." );
Log( "Start time: " . localtime( $Context{start_time} ) );
Log( "End time: " . localtime() );
Log( "Total running callback count: $Context{count}" );

#
#  Define the callback routines
#
sub Callback_Running
{
    my( $State, $Context ) = @_;
    Log( "Running: '$State'\n" );
    # Make sure that he stat is SERVICE_RUNNING to
    # ensure that this event did not occur before
    # the the start event did.
    if( SERVICE_RUNNING == Win32::Daemon::State() )
    {
        $Context->{count}++;
        Log( "Running!!! Count=$Context->{count}\n" );
        Log( "Callback timer: " . Win32::Daemon::CallbackTimer() );
    }
}    

sub Callback_Start
{
    my( $State, $Context ) = @_;
    Log( "Start: '$State'\n" );
    # Initialization code
    $Context->{last_state} = SERVICE_RUNNING;
    Win32::Daemon::State( SERVICE_RUNNING );
    Log( "Service initialized. Setting state to Running." );
}


sub Callback_Pause
{
    my( $State, $Context ) = @_;
    Log( "Pause: '$State'\n" );
    $Context->{last_state} = SERVICE_PAUSED;
    Win32::Daemon::State( SERVICE_PAUSED );
    Log( "Pausing." );
}


sub Callback_Continue
{
    my( $State, $Context ) = @_;
    Log( "Continue: '$State'\n" );
    $Context->{last_state} = SERVICE_RUNNING;
    Win32::Daemon::State( SERVICE_RUNNING );
    Log( "Resuming from paused state." );
}

sub Callback_Stop
{
    my( $State, $Context ) = @_;
    Log( "Stop: '$State'\n" );
    $Context->{last_state} = SERVICE_STOPPED;
    Win32::Daemon::State( [ state => SERVICE_STOPPED, error => 1234 ] );
    Log( "Stopping service." );
    
    # We need to notify the Daemon that we want to stop callbacks and the service.
    Win32::Daemon::StopService();
}

sub Log
{
    my( $Message ) = @_;
    if( fileno( LOG ) )
    {
        print LOG "[" . localtime() . "] $Message\n";
    }   
}   