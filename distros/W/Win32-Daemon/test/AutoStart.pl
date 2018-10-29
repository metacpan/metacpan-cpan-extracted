#//////////////////////////////////////////////////////////////////////////////
#//
#//  AutoStart.pl
#//  Win32::Daemon Perl extension test script
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
use Win32::Process;
use Win32::Console;

my %List;
my $SCRIPT_PATH = Win32::GetLongPathName( scalar Win32::GetFullPathName( $0 ) );
my ( $SCRIPT_NAME ) = ( $SCRIPT_PATH =~ /([^\\]*?)\..*?$/ );
my ( $DB_DIR ) = (  $SCRIPT_PATH =~ /^(.*)\\[^\\]*$/ );

my $DB_FILE = "$DB_DIR/$SCRIPT_NAME.ini";
my $DB_LOG = "$DB_DIR/$SCRIPT_NAME.log";
my $DB_PID = "$DB_DIR/$SCRIPT_NAME.pid";
my $SLEEP_TIMEOUT = 100; # This value is in milliseconds
my $SERVICE_BITS = USER_SERVICE_BITS_8;
my $iTotalCount = ReadDB( $DB_FILE, \%List );

# Define how long to wait before a default status update is set.
#Win32::Daemon::Timeout( 5 );

Win32::Daemon::StartService();
Win32::Daemon::SetServiceBits( $SERVICE_BITS );
Win32::Daemon::ShowService();

# Create a new Win32::Console buffer so that the service
# can display a window with text...
$Buffer = new Win32::Console();
$Buffer->Display();
$Buffer->Title( "Perl based AutoStart service" );

if( open( PID, "> $DB_PID" ) )
{
  print PID "$SCRIPT_NAME started with PID: $$\n";
  close( PID );
}

if( open( LOG, "> $DB_LOG" ) )
{
  my $BackupHandle = select( LOG );
  $| = 1;
  select( $BackupHandle );
  Log( "Service started" );
  Log( "Log file: $DB_DIR" );
  Log( "PID file: $DB_PID" );
  Log( "Database: $DB_FILE" );
}

@JobList = LaunchApps( \%List );
LogPids( @JobList );
$LastState = SERVICE_STOPPED;
while( SERVICE_STOPPED != ( $State = Win32::Daemon::State() ) )
{
  if( SERVICE_START_PENDING == $State )
  {
    # Initialization code
    $LastState = SERVICE_RUNNING;
    Win32::Daemon::State( SERVICE_RUNNING );
    foreach my $Job ( @JobList )
    {
      if( 1 == $Job->{process}->Wait( 0 ) )
      {
        # Process has terminated already.
        Log( "\t$Job->{name} [terminated]" );
      }
    }
    Log( "[" . localtime() . "] Service initialized. Setting state to Running.\n" );
  }
  elsif( SERVICE_PAUSE_PENDING == $State )
  {
    Log( "[" . localtime() . "] Pausing..." );
    foreach my $Job ( @JobList )
    {
      if( 0 == $Job->{process}->Wait( 0 ) )
      {
        Log( "\t$Job->{name}" );
        $Job->{process}->Suspend();
      }
    }
    $LastState = SERVICE_PAUSED;
    Win32::Daemon::State( SERVICE_PAUSED );
    next;
  }
  elsif( SERVICE_CONTINUE_PENDING == $State )
  {
    Log( "[" . localtime() . "] Resuming..." );
    foreach my $Job ( @JobList )
    {
      if( 0 == $Job->{process}->Wait( 0 ) )
      {
        Log( "\t$Job->{name}" );
        $Job->{process}->Resume();
      }
    }
    $LastState = SERVICE_RUNNING;
    Win32::Daemon::State( SERVICE_RUNNING );
    next;
  }
  elsif( SERVICE_STOP_PENDING == $State )
  {
    Log( "[" . localtime() . "] Stopping..." );
    foreach my $Job ( @JobList )
    {
      if( 0 == $Job->{process}->Wait( 0 ) )
      {
        Log( "\t$Job->{name}" );
        $Job->{process}->Kill( 0 );
      }
    }
    $LastState = SERVICE_STOPPED;
    Win32::Daemon::State( SERVICE_STOPPED );
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

Win32::Daemon::StopService();
undef $Buffer;

sub LaunchApps
{
my( $List ) = @_;
my @Jobs;
  foreach ( keys( %$List ) )
  {
    my $App = $List->{$_};
    if( $App->{state} =~ /disabled/i )
    {
      Log( "$App->{name} is disabled. Skipping to next entry." );
    }
    else
    {
      Log( "Launching: $App->{name}" );
      push( @Jobs, $App ) if( Launch( $App ) );
    }
  }
  return( @Jobs );
}

sub LogPids
{
  my( @Jobs ) = @_;
  
  map
  {
    Log( "$_->{name}=$_->{pid}" );
  } @Jobs ;
}

sub Launch
{
  my( $App ) = @_;
  my $Process;
  my $iResult = 0;
  my( $Flags ) =  ($App->{flags}) | ($App->{priority});
  
  Log( "\tStarting: $App->{program} $App->{params}" );
  Log( "\tFlags=$Flags" );
  if( Win32::Process::Create(
                              $Process,
                              $App->{program},
                              "$App->{program} $App->{params}",
                              0 != $App->{inherit},
                              $Flags,
                              $App->{dir} ) )
  {
    $App->{process} = $Process;
    $App->{pid} = $Process->GetProcessID();
    Log( "\t$App->{name} has been succesfully created." );
    $iResult = 1;
  }
  else
  {
    $iResult = 0;
    Log( "\tFailed to launch: " . Win32::FormatMessage( Win32::GetLastError() ) );
  }
  return( $iResult );
}

sub ReadDB
{
  my( $FileName, $List ) = @_;
  my $Section = "";
  my $iCount = 0;
  
  if( open( FILE, "< $FileName" ) )
  {
    my( $Temp, $Process );
    
    foreach $Temp ( <FILE> )
    {
      my( $Temp2, $Name, $Value );
      
      next if( $Temp =~ /^\s*?[;#]/ );
      if( ( $Temp2 ) = ( $Temp =~ /^\s*\[\s*(.*)\s*\]/ ) )
      {
        $iCount++;
        $Process = lc $Temp2;
        $List->{$Process}->{name}= $Temp2;
        next;
      }
      
      ($Name, $Value ) = ($Temp =~ /\s*(.*?)\s*?=\s*(.*)/gi);
      $List->{$Process}->{lc $Name} = $Value if( $Name );
    }
    close( FILE );
  }
  return( $iCount );
} 

sub Log
{
  my( $Message ) = @_;
  my $Date = "[" . localtime() . "]";
  print LOG "$Date $Message\n" if( fileno( LOG ) );
  print $Buffer->Write( "$Date $Message\n" ) if( defined $Buffer );
}
