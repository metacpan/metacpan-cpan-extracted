#//////////////////////////////////////////////////////////////////////////////
#//
#//  Daemon_Template.pl
#//  Win32::Daemon Perl extension template script
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


use Win32::Daemon;
my $SLEEP_TIMEOUT = 1000; # This value is in milliseconds
my $START_TIME = time();
my ( $DB_DIR, $DB_FILE_NAME ) = ( Win32::GetFullPathName( $0 ) =~ /^(.*)\\([^\\]*)$/ );
$DB_FILE_NAME =~ s/\..*?$/.log/;
my $LogFile = "$DB_DIR\\$DB_FILE_NAME";
# You could log to a named pipe, very cool!
#$LogFile = "\\\\.\\pipe\\syslog";
if( open( LOG, ">$LogFile" ) )
{
    my $StartTime = localtime( $START_TIME );
    my $BackupHandle = select( LOG );
    $| = 1;
    select( $BackupHandle );
    print LOG << "EOT"
# Service Starting
# Script: $0
# PID: $$
# Date: $StartTime
EOT
}    

Log( "Starting service" );
Win32::Daemon::StartService();
Log( "Entering service loop" );
$LastState = SERVICE_STOPPED;
while( SERVICE_STOPPED != ( $State = Win32::Daemon::State() ) )
{
  Log( "State: $State" );
  if( SERVICE_START_PENDING == $State )
  {
    # Initialization code
    $LastState = SERVICE_RUNNING;
#    Win32::Daemon::State( { state => SERVICE_RUNNING, error => NO_ERROR } );
    Win32::Daemon::State( SERVICE_RUNNING );
    Log( "Service initialized. Setting state to Running." );
  }
  elsif( SERVICE_PAUSE_PENDING == $State )
  {
    $LastState = SERVICE_PAUSED;
    Win32::Daemon::State( SERVICE_PAUSED );
    Log( "Pausing." );
    next;
  }
  elsif( SERVICE_CONTINUE_PENDING == $State )
  {
    $LastState = SERVICE_RUNNING;
    Win32::Daemon::State( SERVICE_RUNNING );
    Log( "Resuming from paused state." );
    next;
  }
  elsif( SERVICE_STOP_PENDING == $State )
  {
    $LastState = SERVICE_STOPPED;
    Win32::Daemon::State( { state => SERVICE_STOPPED, error => 1234 } );
    Log( "Stopping service." );
    next;
  }
  else
  {
    # Take care of unhandled states by setting the State()
    # to whatever the last state was we set...
    Win32::Daemon::State( $LastState );
  }
  Win32::Sleep( $SLEEP_TIMEOUT );
}
Log( "Stopping the service..." );
print Win32::Daemon::StopService();
Log( "Stopped." );

close( LOG ) if( fileno( LOG ) );

sub Log
{
    my( $Message ) = @_;
    if( fileno( LOG ) )
    {
        print LOG "[" . localtime() . "] $Message\n";
    }   
}   