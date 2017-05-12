#//////////////////////////////////////////////////////////////////////////////
#//
#//  Callback3.pl
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

# For DEBUG version ONLY!!
if( Win32::Daemon::IsDebugBuild() )
{
#    Win32::Daemon::DebugOutputPath( "\\\\.\\pipe\\syslog" );
}

my $gTestFramework = new TestFramework;
$gTestFramework->LogStart();

Win32::Daemon::RegisterCallbacks( {
    start		=>  \&Callback_Starting,
    stop		=>  \&Callback_Stop,
    pause		=>  \&Callback_Pause,
    continue    =>  \&Callback_Continue,
    running		=>	\&Callback_Running,
    timer		=>	\&Callback_Timer,
	net_bind_disable	=>	\&Callback_NetBindingDisable,
	net_bind_enable		=>	\&Callback_NetBindingEnable,
	
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

$gTestFramework->LogClose();


#
#  Define the callback routines
#
sub Callback_Starting
{
    my( $ControlMessage, $Context ) = @_;
    Log( "Received SERVICE_CONTROL_START ($ControlMessage) message\n" );
    Log( "			We are Starting!!!" );

    # Return the updated service state
    return( SERVICE_RUNNING );
}    

sub Callback_Running
{
    my( $ControlMessage, $Context ) = @_;
    Log( "Received SERVICE_CONTROL_RUNNING ($ControlMessage) message\n" );

    # We come here only for legacy support, this is being replaced by SERVICE_CONTROL_TIMER
    $Context->{count}++;
    Log( "           Count=$Context->{count}\n" );
    Log( "           Callback timer: " . Win32::Daemon::CallbackTimer() . " milliseconds" );

    # Note that there is no need to update the state so just return (with no return value)
    return;
}


sub Callback_Timer
{
    my( $ControlMessage, $Context ) = @_;
    Log( "Received SERVICE_CONTROL_TIMER ($ControlMessage) message\n" );
    $Context->{count}++;
    Log( "           Count=$Context->{count}\n" );
    Log( "           Callback timer: " . Win32::Daemon::CallbackTimer() . " milliseconds" );

    # Note that there is no need to update the state so just return (with no return value)
    return;
}


sub Callback_Pause
{
    my( $ControlMessage, $Context ) = @_;
    Log( "Recieved SERVICE_CONTROL_PAUSE ($ControlMessage) message\n" );
    Log( "  state: " . Win32::Daemon::State() );
    if( SERVICE_PAUSED == Win32::Daemon::State() )
	{
		Log( "Already paused!" );
	}
	else
	{
		Log( "Pausing." );
                Win32::Daemon::CallbackTimer( 0 );
 	}
    return( SERVICE_PAUSED );
}


sub Callback_Continue
{
    my( $ControlMessage, $Context ) = @_;
    Log( "Received SERVICE_CONTROL_CONTINUE ($ControlMessage) message\n" );
    Log( "  state: " . Win32::Daemon::State() );
    if( SERVICE_PAUSED == Win32::Daemon::State() )
    {
		Log( "Resuming from paused state." );
		Win32::Daemon::CallbackTimer( 2000 );
    }
    else
    {
          Log( "Not already paused." );
    }
     
    # Return the updated service state
    return( SERVICE_RUNNING );
}

sub Callback_Stop
{
    my( $ControlMessage, $Context ) = @_;
    Log( "Received SERVICE_CONTROL_STOP ($ControlMessage) message\n" );
    $Context->{last_state} = SERVICE_STOPPED;
#    Win32::Daemon::State( [ state => SERVICE_STOPPED, error => 1234 ] );
    Log( "Stopping service." );
    
    # We need to notify the Daemon that we want to stop callbacks and the service.
    Win32::Daemon::StopService();

    # Return the new service state
    return( SERVICE_STOPPED );
}

sub Callback_NetBindingDisable
{
    my( $ControlMessage, $Context ) = @_;
    Log( "Net Binding Disable: '$ControlMessage'\n" );
    return;
}

sub Callback_NetBindingEnable
{
    my( $ControlMessage, $Context ) = @_;
    Log( "Net Binding Enable: '$ControlMessage'\n" );
    return;
}

sub Log
{
    my( $Message ) = @_;

    $gTestFramework->LogMessage( $Message );
}   