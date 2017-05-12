#//////////////////////////////////////////////////////////////////////////////
#//
#//  Callback.pl
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

BEGIN
{
        my ( $SCRIPT_DIR, $SCRIPT_FILE_NAME ) = ( Win32::GetFullPathName( $0 ) =~ /^(.*)\\([^\\]*)$/ );
        push( @INC, $SCRIPT_DIR );
}

use Win32::Daemon;
use TestFramework;

my %List;
my $START_TIME = time();
my $DEFAULT_CALLBACK_TIMER = 2000;

# For DEBUG version ONLY!!
if( Win32::Daemon::IsDebugBuild() )
{
#    Win32::Daemon::DebugOutputPath( "\\\\.\\pipe\\syslog" );
}

my ( $SCRIPT_DIR, $SCRIPT_FILE_NAME ) = ( Win32::GetFullPathName( $0 ) =~ /^(.*)\\([^\\]*)$/ );
$| = 1;

#my $LOG_FILE = shift @ARGV || "$SCRIPT_DIR\\$SCRIPT_FILE_NAME.log";
my $LOG_FILE = "\\\\.\\pipe\\syslog";

my $gTestFramework = new TestFramework;
$gTestFramework->LogStart();

Win32::Daemon::RegisterCallbacks( \&CallbackRoutine );

Log( "Starting service" );
%Context = (
    last_state => SERVICE_STOPPED,
    count   =>  0,
    start_time => time(),
);

Win32::Daemon::StartService( \%Context, 5000 );

Log( "Shutting down the service." );
Log( "Start time: " . localtime( $Context{start_time} ) );
Log( "End time: " . localtime() );
Log( "Total running callback count: $Context{count}" );

$gTestFramework->LogClose();

#
#  Define the callback routine
#
sub CallbackRoutine
{
    my( $ControlCommand, $Context ) = @_;
    my $Return = undef;
    
    if( SERVICE_CONTROL_INTERROGATE == $ControlCommand )
    {
		# Someone is querying for the state of this service.
		# This usually occurs if an app is querying to discover the
		# current state. It should simply report what the current 
		# state is.
		# Example of this occuring is if someone used the net.exe to
		# start the service (as in: net start fooservice). If the service
		# does not start reasonably quickly it issues an interrogate
		# query until it starts or stops.
		
 		Log( "Received SERVICE_CONTROL_INTERROGATE ($ControlCommand)\n" );
 		$Return = Win32::Daemon::State();
    }   
    elsif( SERVICE_CONTROL_RUNNING == $ControlCommand )
    {
 		Log( "Received SERVICE_CONTROL_RUNNING ($ControlCommand)\n" );

    } 
    elsif( SERVICE_CONTROL_TIMER == $ControlCommand )
    {
 		Log( "Received SERVICE_CONTROL_TIMER ($ControlCommand)\n" );
    } 
    elsif( SERVICE_CONTROL_START == $ControlCommand )
    {
 		Log( "Received SERVICE_CONTROL_START ($ControlCommand)\n" );

        # Initialization code
        $Return = $Context->{last_state} = SERVICE_RUNNING;
#        Win32::Daemon::CallbackTimer( $DEFAULT_CALLBACK_TIMER );

        Log( "Service initialized. Setting state to Running." );
    }
    elsif( SERVICE_CONTROL_PAUSE == $ControlCommand )
    {
 		Log( "Received SERVICE_CONTROL_PAUSE ($ControlCommand)\n" );

        $Return = $Context->{last_state} = SERVICE_PAUSED;
        Win32::Daemon::CallbackTimer( 0 );
        Log( "Pausing." );
    }
    elsif( SERVICE_CONTROL_CONTINUE == $ControlCommand )
    {
 		Log( "Received SERVICE_CONTROL_CONTINUE ($ControlCommand)\n" );

        $Return = $Context->{last_state} = SERVICE_RUNNING;
        Win32::Daemon::CallbackTimer( $DEFAULT_CALLBACK_TIMER );
        Log( "Resuming from paused state." );
    }
    elsif( SERVICE_CONTROL_STOP == $ControlCommand )
    {
 		Log( "Received SERVICE_CONTROL_STOP ($ControlCommand)\n" );

        $Context->{last_state} = SERVICE_STOPPED;
        Win32::Daemon::State( [ state => SERVICE_STOPPED, error => 1234 ] );
        Log( "Stopping service." );
        
        # We need to notify the Daemon that we want to stop callbacks and the service.
        Win32::Daemon::StopService();
    }
    elsif( SERVICE_EVENT_SHUTDOWN == $ControlCommand )
    {
 		Log( "Received SERVICE_EVENT_SHUTDOWN ($ControlCommand)\n" );

		Log( "Event: SHUTTING DOWN!  *** Stopping this service ***" );
		# We need to notify the Daemon that we want to stop callbacks and the service.
		Win32::Daemon::StopService();
    }
    elsif( SERVICE_EVENT_PRESHUTDOWN == $ControlCommand )
    {
 		Log( "Received SERVICE_EVENT_PRESHUTDOWN ($ControlCommand)\n" );

		Log( "Event: Preshutdown!" );
    }
    elsif( SERVICE_EVENT_INTERROGATE == $ControlCommand )			
    {
 		Log( "Received SERVICE_EVENT_INTERROGATE ($ControlCommand)\n" );

		Log( "Event: Interrogation!" );
    }
    elsif( SERVICE_EVENT_NETBINDADD == $ControlCommand )			
    {
 		Log( "Received SERVICE_EVENT_NETBINDADD ($ControlCommand)\n" );

		Log( "Event: Adding a network binding!" );
    }
    elsif( SERVICE_EVENT_NETBINDREMOVE == $ControlCommand )			
    {
 		Log( "Received SERVICE_EVENT_NETBINDREMOVE ($ControlCommand)\n" );

		Log( "Event: Removing a network binding!" );
    }
    elsif( SERVICE_EVENT_NETBINDENABLE == $ControlCommand )			
    {
 		Log( "Received SERVICE_EVENT_NETBINDENABLE ($ControlCommand)\n" );

		Log( "Event: Network binding has been enabled!" );
    }
    elsif( SERVICE_EVENT_NETBINDDISABLE == $ControlCommand )		
    {
 		Log( "Received SERVICE_EVENT_NETBINDDISABLE ($ControlCommand)\n" );

		Log( "Event: Network binding has been disabled!" );
    }
    elsif( SERVICE_EVENT_DEVICEEVENT == $ControlCommand )			
    {
 		Log( "Received SERVICE_EVENT_DEVICEEVENT ($ControlCommand)\n" );

		Log( "Event: A device has issued some event of some sort!" );
    }
    elsif( SERVICE_EVENT_HARDWAREPROFILECHANGE == $ControlCommand )	
    {
 		Log( "Received SERVICE_EVENT_HARDWAREPROFILECHANGE ($ControlCommand)\n" );

		Log( "Event: Hardware profile has changed!" );
    }
    elsif( SERVICE_EVENT_POWEREVENT == $ControlCommand )			
    {
 		Log( "Received SERVICE_EVENT_POWEREVENT ($ControlCommand)\n" );

		Log( "Event: Some power event has occured!" );
    }
    elsif( SERVICE_EVENT_SESSIONCHANGE == $ControlCommand )			
    {
 		Log( "Received SERVICE_EVENT_SESSIONCHANGE ($ControlCommand)\n" );

		Log( "Event: User session has changed!" );
    }
    else
    {
        # Take care of unhandled states by setting the State()
        # to whatever the last state was we set...
 		Log( "Received an unknown state ($ControlCommand)\n" );


		$Return = $Context->{last_state};
	}
    
    return( $Return );
}

sub Log
{
    my( $Message ) = @_;

    $gTestFramework->LogMessage( $Message );
}  