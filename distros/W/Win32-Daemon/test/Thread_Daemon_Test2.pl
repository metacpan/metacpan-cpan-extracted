#!/user/bin/perl 
#
#  Thread_Daemon_Test2.pl
#  ---------------------
#  This is a script to test that Win32::Daemon can 
#  work correctly even if it is spawning new threads.
#
#	This particular test validates that a call to StartService()
#	can occur on a different thread than the main Perl process 
#	thread.
#  
#  2008.03.24 rothd

use Getopt::Long;
use Win32::Daemon;
use threads;
use threads::shared;
use Win32::Sound;
use vars qw( $VERSION %STATE %EVENT );

$VERSION = 20060901;

###########################
#
#	Declare shared globals
my $gfPaused : shared = 0;
my $gfContinue : shared = 1;

my $gServiceThread = 0;
my $gWorkerThread = 0;

%STATE = ( 
    eval( SERVICE_NOT_READY )      => 'SERVICE_NOT_READY',
    eval( SERVICE_STOPPED )        => 'SERVICE_STOPPED',
    eval( SERVICE_RUNNING )        => 'SERVICE_RUNNING',
    eval( SERVICE_PAUSED )         => 'SERVICE_PAUSED',
    eval( SERVICE_START_PENDING )  => 'SERVICE_START_PENDING',
    eval( SERVICE_STOP_PENDING )   => 'SERVICE_STOP_PENDING',
    eval( SERVICE_CONTINUE_PENDING )  => 'SERVICE_CONTINUE_PENDING',
    eval( SERVICE_PAUSE_PENDING )  => 'SERVICE_PAUSE_PENDING',
);

%EVENT = (
    eval( SERVICE_START_PENDING )  => 'SERVICE_START_PENDING',
    eval( SERVICE_STOP_PENDING )   => 'SERVICE_STOP_PENDING',
    eval( SERVICE_CONTINUE_PENDING )  => 'SERVICE_CONTINUE_PENDING',
    eval( SERVICE_PAUSE_PENDING )  => 'SERVICE_PAUSE_PENDING',
);

my %Config = (
   service_name      => "PerlThreadTest",
   service_display   => "Perl: Win32::Deamon Thread Test Service",
   service_desc      => "Perl Win32::Daemon test service to validate Perl threading support",
);

# For DEBUG version ONLY!!
if( Win32::Daemon::IsDebugBuild() )
{
    Win32::Daemon::DebugOutputPath( "\\\\.\\pipe\\syslog" );
}

Configure( \%Config );
if( $Config{help} )
{
   Syntax();
   exit();
}
elsif( $Config{install} )
{
   InstallService();
   exit();
}
elsif( $Config{remove} )
{
   RemoveService();
   exit();
}



# Common Code Library to determine log file path
my ( $SCRIPT_PATH ) = Win32::GetLongPathName( scalar Win32::GetFullPathName( $0 ) );
my ( $SCRIPT_DIR ) = ( ( $SCRIPT_PATH ) =~ /^(.*)\\[^\\]*$/ );
my ( $SCRIPT_NAME ) = ( ( $SCRIPT_PATH ) =~ /([^\\]*)\..*$/ );
#my $LogFile = "$SCRIPT_DIR\\$SCRIPT_NAME.log";
my $LogFile = "\\\\.\\pipe\\syslog2";

if( open( LOG, ">$LogFile" ) )
{
    my $TempSelect = select( LOG );
    $| = 1;
    select( $TempSelect );
    print LOG "# Software: $0\n";
    print LOG "# Date: " . localtime() . "\n";
}

$gServiceThread = threads->new( \&ServiceThread );
$gServiceTID = $gServiceThread->tid();

my $Thread = threads->self->tid;
Log( "Thread $Thread: Entering main loop" );

do
{
	Log( "Thread $Thread: Main loop running.\n" );
	sleep( 2 );
} while( threads->object( $gServiceTID ) );

Log( "Thread $Thread: Terminating script" );
TerminateScript();


sub ServiceThread
{
	ReportLog( EVENTLOG_INFORMATION_TYPE, "Starting the $SERVICE_NAME service at " . localtime() );

	Log( "ServiceThread: Starting $SERVICE_NAME Daemon...\n" );

	# Register for callbacks...
	Win32::Daemon::RegisterCallbacks( \&CallbackRoutine );

	# Start the service.
	# It will stay in StartService() until the callback routine tells the SCM
	# to terminate.
	# Pass in 0 for the callback timer. This way we won't call into the 
	# callback routine unless the SCM tells us to. We can reset the callback
	# timer to another value once we start the service...
	if( ! Win32::Daemon::StartService( { start => time() }, 2000 ) )
	{
		my $String = "Failed to start this script as a Win32 service.\nError: " . GetError();
		Log( $String );
		ReportLog( EVENTLOG_ERROR_TYPE, $String );
		exit();
	}
	# We get here only if StartService() was successful and there was a termination request
	# from the callback routine...
	Win32::Daemon::StopService();
	ReportLog( EVENTLOG_INFORMATION_TYPE, "Shutting down $SERVICE_NAME service" );
}

sub CallbackRoutine 
{
   my( $Event, $Context ) = @_;
   my $State = Win32::Daemon::State();
   my $ReportState;
   my $Thread = threads->self->tid();
   
   # Increase the iteration count so that we can track how often the callback routine
   # is called.
   $Context->{iteration}++;
   
   Log( "Thread $Thread: Received event: '$EVENT{$Event}' ($Event): iteration '$Context->{iteration}'...current state: '$STATE{$State}' ($State)" );

#   if( SERVICE_NOT_STARTED == Win32::Daemon::State() )
#   {
#      return();
#   }
	# Process the event...   
	if( SERVICE_START_PENDING == $State )
	{
		# Starting...
		Log( "Thread $Thread: Starting!" );

		# Create our worker thread...
		$gWorkerThread = threads->new( \&WorkerThread );
		$ReportState = SERVICE_RUNNING;		
   }
   elsif( SERVICE_PAUSE_PENDING == $State )
   {
		# Starting...
		Log( "Thread $Thread:     Pausing!" );
		$gfPaused = 1;
		$ReportState = SERVICE_PAUSED;

		# Configure how often to call the callback routine wiht the "running" 
		# event (in milliseconds)...
		Win32::Daemon::CallbackTimer( 8000 );
   }
   elsif( SERVICE_CONTINUE_PENDING == $State )
   {
		# Starting...
		Log( "Thread $Thread:     UN-Pausing!" );
		$gfPaused = 0;
		$ReportState = SERVICE_RUNNING;
   }
   elsif( SERVICE_STOP_PENDING == $State )
   {
      Log( "Thread $Thread: Calling StopService()..." );
      $gfContinue = 0;
      $ReportState = SERVICE_STOPPED;
      my $iResult = Win32::Deamon::StopService();
      Log( "Thread $Thread: StopService() returned '$iResult'" );
   }
   elsif( SERVICE_RUNNING == $Event )
   {
      Log( "Thread $Thread:     running event" );
      $Context->{running}++;

   }
   else
   {
      # This is the catch-all block...
      # Take care of unhandled states by setting the State()
      # to whatever the last state was we set...
      Log( "Thread $Thread:     unknown event" );
      $ReportState = $Context->{previous_state};
   }

   $Context->{previous_event} = $Event;
   $Context->{previous_state} = $State;

   return( $ReportState );
}

##########################################################
#
#
#
#
sub WorkerThread
{
	my $SoundFile = "c:\\windows\\Media\\chimes.wav";
	my $Thread = threads->self->tid;
	while( $gfContinue )
	{
		my $String = "Thread $Thread: !!!!!!!!! HEY WORKER THREAD ";
		$String .= "( IN PAUSED MODE )" if( $gfPaused );
		$String .= " !!!!!!!!!!";
		Log( $String );

		if( ! $gfPaused )
		{
			Win32::Sound::Play( $SoundFile );
	
		}	
		sleep( 1 );
	}
}



##########################################################
#
#
#
#
sub GetServiceConfig
{
    my $ScriptPath = join( "", Win32::GetFullPathName( $0 ) );
    my %Hash = (
        name    =>      $Config{service_name},
        display =>      $Config{service_display},
        path    =>      $^X,
        user    =>      $Config{account},
        password   =>   $Config{password},
        parameters =>   "\"$ScriptPath\"",
        description =>  $Config{service_desc},
    );
    $Hash{parameters} .= " -debug" if( $Config{debug} );
    $Hash{parameters} .= " -console" if( $Config{console} );
#    $Hash{parameters} .= " -nopage" if( $Config{nopage} );
    return( \%Hash );
}

sub InstallService
{
  my $ServiceConfig = GetServiceConfig();
  
  if( Win32::Daemon::CreateService( $ServiceConfig ) )
  {
    print "The $ServiceConfig->{display} was successfully installed.\n";
  }
  else
  {
    print "Failed to add the $ServiceConfig->{display} service.\nError: " . GetError() . "\n";
  }
}

sub RemoveService
{
  my $ServiceConfig = GetServiceConfig();
  
  if( Win32::Daemon::DeleteService( $ServiceConfig->{name} ) )
  {
    print "The $ServiceConfig->{display} was successfully removed.\n";
  }
  else
  {
    print "Failed to remove the $ServiceConfig->{display} service.\nError: " . GetError() . "\n";
  }
}


sub ReportLog
{
  my( $EventType, $Message ) = @_;
  
  Log( "Report: $Message" );
}

sub Log
{
  my( $Message ) = @_;

  print LOG "$Message\n" if( fileno( LOG ) );
}

sub TerminateScript 
{
  Log( "Shutting down $SERVICE_NAME service" );
  close( LOG ) if( fileno( LOG ) );
  $Server->Close();
  undef $Server;
}

sub Configure
{
    my( $Config ) = @_;
    my $fResult = 0;
    Getopt::Long::Configure( "prefix_pattern=(-|\/)" );
    $fResult = GetOptions( $Config, 
                          qw( 
                            console|c
                            debug|d
                            nopage|n
                            install|i
                            remove|delete|r|d
                            help|?
                          ) );

    $Config->{help} = 1 unless( $fResult );
    return( $fResult );
}

sub Syntax
{
    my( $Script ) = ( $0 =~ m#([^\\/]+)$# );
    my $Line = "-" x length( $Script );
    print STDERR << "EOT";

    $Script
    $Line
    Tests the Win32::Deamon extension with threads.
    Version: $VERSION
    Syntax: $0 [-cdn] [-p Number]
      c.............Run from the console, not as a service.
                    Use this to run the script from a command line.
      d.............Run in debug mode.
      install.......Installs the service.
      remove........Uninstalls the service.

EOT
}



END
{
  print STDERR "\nQuitting...\n";
  undef $Server;
}

__END__

History
  20060901 rothd
   -Created.
   
   
