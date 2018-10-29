use vars qw( $VERSION );
use Win32::Lanman;
use Getopt::Long;

$VERSION = 20040806;

# By default the Services Database is specified by an "" string
my $SERVICES_DATABASE = "";

%SERVICE_FLAGS = (
  start =>  {
    &SERVICE_AUTO_START   =>  "SERVICE_AUTO_START",
  	&SERVICE_BOOT_START   =>  "SERVICE_BOOT_START",
  	&SERVICE_DEMAND_START =>  "SERVICE_DEMAND_START",
  	&SERVICE_DISABLED     =>  "SERVICE_DISABLED",
  	&SERVICE_SYSTEM_START =>  "SERVICE_SYSTEM_START",
  },
  status  =>  {
    0                         =>  "Undefined",
    &SERVICE_CONTINUE_PENDING =>  "Continuing",
    &SERVICE_PAUSE_PENDING    =>  "Pausing",
    &SERVICE_PAUSED           =>  "Paused",
    &SERVICE_RUNNING          =>  "Running",
    &SERVICE_START_PENDING    =>  "Starting",
    &SERVICE_STOPPED          =>  "Stopped",
    &SERVICE_STOP_PENDING     =>  "Stopping",  
  },
);

%SERVICE_BITMASKS = (
  type  =>  {
    &SERVICE_FILE_SYSTEM_DRIVER   =>  "SERVICE_FILE_SYSTEM_DRIVER",
    &SERVICE_INTERACTIVE_PROCESS  =>  "SERVICE_INTERACTIVE_PROCESS",
    &SERVICE_KERNEL_DRIVER        =>  "SERVICE_KERNEL_DRIVER",
    &SERVICE_WIN32_OWN_PROCESS    =>  "SERVICE_WIN32_OWN_PROCESS",
    &SERVICE_WIN32_SHARE_PROCESS  =>  "SERVICE_WIN32_SHARE_PROCESS",
  },

  control =>  {
    &SERVICE_CONTROL_CONTINUE     =>  "SERVICE_CONTROL_CONTINUE",
    &SERVICE_CONTROL_INTERROGATE  =>  "SERVICE_CONTROL_INTERROGATE",
    &SERVICE_CONTROL_PAUSE        =>  "SERVICE_CONTROL_PAUSE",
    &SERVICE_CONTROL_SHUTDOWN     =>  "SERVICE_CONTROL_SHUTDOWN",
    &SERVICE_CONTROL_STOP         =>  "SERVICE_CONTROL_STOP",

#    &SERVICE_ACCEPT_STOP                  =>  "SERVICE_ACCEPT_STOP",
#  	&SERVICE_ACCEPT_PAUSE_CONTINUE        =>  "SERVICE_ACCEPT_PAUSE_CONTINUE",
#  	&SERVICE_ACCEPT_SHUTDOWN              =>  "SERVICE_ACCEPT_SHUTDOWN",
#  	&SERVICE_ACCEPT_PARAMCHANGE           =>  "SERVICE_ACCEPT_PARAMCHANGE",
#  	&SERVICE_ACCEPT_NETBINDCHANGE         =>  "SERVICE_ACCEPT_NETBINDCHANGE",
#  	&SERVICE_ACCEPT_HARDWAREPROFILECHANGE =>  "SERVICE_ACCEPT_HARDWAREPROFILECHANGE",
#  	&SERVICE_ACCEPT_POWEREVENT            =>  "SERVICE_ACCEPT_POWEREVENT",
  },
);

my @ServiceList = ();
Configure( \%Config );
if( $Config{help} )
{
  Syntax();
  exit;
}
print "Collecting service information for $Config{machine}...\n";
if( Win32::Lanman::EnumServicesStatus( $Config{machine}, $SERVICES_DATABASE, SERVICE_WIN32, SERVICE_STATE_ALL, \@ServiceList ) )
{
  if( $Config{list} )
  {
    local $iCount = 0;
    $~ = "LIST_SERVICE_HEADER";
    write;
    $~ = "LIST_SERVICE_NAME";
    foreach $Service ( sort( { $a->{$Config{sort}} cmp $b->{$Config{sort}} } @ServiceList ) )
    {
      $iCount++;
      write;
    }
  }
  elsif( "" ne $Config{action} )
  {  
    my %ServiceControl = (
      start   =>  \&Win32::Lanman::StartService,
      stop    =>  \&Win32::Lanman::StopService,
      pause   =>  \&Win32::Lanman::PauseService,
      continue=>  \&Win32::Lanman::ContinueService,
      delete  =>  \&Win32::Lanman::DeleteService,
      install =>  \&InstallService,
      restart =>  \&ResetService,
      display =>  \&DisplayService,
      config  =>  \&ConfigService
    );
    # We get here unless we are listing the services...
    if( defined $ServiceControl{$Config{action}} )
    {
      print "Machine: $Config{machine}\nService: $Config{$Config{action}}\nAction: $Config{action}\n\n";
      foreach $Service ( map{ $_ if( lc $_->{display} eq lc $Config{display} || lc $_->{name} eq lc $Config{display} ) } @ServiceList )
      {
        next unless( "HASH" eq ref $Service );
        # If the user specified the service's descriptive name then replace it with
        # the actual service name.
        $Config{display} = $Service->{name};
        $Config{service_status} = $Service;
        last;
      }
      
      $Result = &{$ServiceControl{$Config{action}}}( $Config{machine}, $SERVICES_DATABASE, $Config{$Config{action}} );
      if( $Result )
      {
        print "\nSuccessful.\n";
      }
      else
      {
        print "\nFailed.\n";
        print "Error: ";
        print Win32::Lanman::GetLastError() . ": ";
        print Win32::FormatMessage( Win32::Lanman::GetLastError() );
      }
    }
  }
}

sub InstallService 
{
  my( $Machine, $ServiceDatabase, $Service ) = @_;
  # Setup default config values
  my %ServiceConfig = (
    account =>  "localsystem",
    control =>  &SERVICE_ERROR_IGNORE,
    
  );
  UpdateServiceConfig( $Service, \%ServiceConfig ); 
  print "Machine: $Machine\n";
  print "Service Name: $ServiceConfig{name}\n";
  print "Display Name: $ServiceConfig{display}\n";
  print "Type: $ServiceConfig{type}\n";
  print "Start: $ServiceConfig{start}\n";
  print "Path: $ServiceConfig{filename}\n";
  return( Win32::Lanman::CreateService( $Machine, $ServiceDatabase, \%ServiceConfig ) );
}

sub UpdateServiceConfig
{
  my( $Service, $ServiceConfig ) = @_;
  $ServiceConfig->{name}    = $Service;
  $ServiceConfig->{display} = $Config{service_display} if( defined $Config{service_display} );
  $ServiceConfig->{type}    = &SERVICE_WIN32_SHARE_PROCESS | ( $Config{service_interactive} * &SERVICE_INTERACTIVE_PROCESS ) if( defined $Config{service_interactive} );
  $ServiceConfig->{start}   = $Config{service_start} if( defined $Config{service_start} );
#  $ServiceConfig->{control} = &SERVICE_ERROR_IGNORE unless( defined $Config{control} );
  $ServiceConfig->{filename}= $Config{service_path} if( defined $Config{service_path} );
  $ServiceConfig->{group}   = $Config{service_group} if( defined $Config{service_group} );
#  $ServiceConfig->{tagid}   = undef unless( defined $Config{tagid} );
  $ServiceConfig->{account} = $Config{service_account} if( defined $Config{service_account} );
  $ServiceConfig->{password}= $Config{service_password} if( defined $Config{service_password} );
  $ServiceConfig->{dependencies}  = \@{$Config{service_dependencies}} if( defined $Config{service_dependencies} );
  
  return;
}


sub ResetService
{
  my( $Machine, $ServiceDatabase, $Service ) = @_;
  Win32::Lanman::StopService( $Machine, $ServiceDatabase, $Service );
  sleep( 3 );
  return( Win32::Lanman::StartService( $Machine, $ServiceDatabase, $Service ) );
}

sub DisplayService
{
  my( $Machine, $ServiceDatabase, $Service ) = @_;
  my %ServiceConfig;
  my $Result = Win32::Lanman::QueryServiceConfig( $Machine, $ServiceDatabase, $Service, \%ServiceConfig );
  if( $Result )
  {
    local( $PropertyName, $PropertyValue );
    if( defined $Config{service_status} )
    {
      $ServiceConfig{status} = $Config{service_status}->{state};
    }
    print "\n    Details:\n    " . "-" x 73 . "\n";

    foreach my $Key ( sort( keys( %ServiceConfig ) ) )
    {
      ( $PropertyName, $PropertyValue ) = ( $Key, $ServiceConfig{$Key} );
      $~ = "LIST_SERVICE_DETAILS";
      if( "ARRAY" eq ref( $ServiceConfig{$Key} ) )
      {
        local( $iEntryCount ) = ( 0 );
        $PropertyValue = "...";
        write;
        foreach $PropertyValue ( sort( @{$ServiceConfig{$Key}} ) )
        {
          $iEntryCount++;

          $~ = "LIST_SERVICE_DETAILS_ARRAY";
          write;
        }
      }
      else
      {
        if( defined $SERVICE_FLAGS{$PropertyName} )
        {
          $PropertyValue = $SERVICE_FLAGS{$PropertyName}->{$PropertyValue};
        }
        elsif( defined $SERVICE_BITMASKS{$PropertyName} )
        {
          my @FlagList;
          foreach my $BitMask ( keys( %{$SERVICE_BITMASKS{$PropertyName}} ) )
          {
            push( @FlagList, $SERVICE_BITMASKS{$PropertyName}->{$BitMask} ) if( $BitMask & $PropertyValue );
          }
          $PropertyValue = join( " | ", @FlagList );
        }
        $PropertyValue = "---" if( "" eq $PropertyValue );
        
        write;
      }
    }
    # Check if any services depend upon this service...
    if( Win32::Lanman::EnumDependentServices( $Machine, $ServiceDatabase, $Service, &SERVICE_STATE_ALL, \@DependentServices ) )
    {
      local  $iEntryCount = 0;
      $PropertyName = "Dependencies";
      $PropertyValue = "Services depending upon '$Service' ($ServiceConfig{display}):";
      write;
      
      $~ = "LIST_SERVICE_DETAILS_ARRAY";
      foreach my $Dependent ( sort @DependentServices )
      {
        $iEntryCount++;
        $PropertyValue = "$Dependent->{name} ($Dependent->{display}) : " . $SERVICE_FLAGS{status}->{$Dependent->{state}};
        write;
      }
    }
  }
  return( $Result );
}

sub ConfigService
{
  my( $Machine, $ServiceDatabase, $Service ) = @_;
  my %ServiceConfig;
  my $Result = Win32::Lanman::QueryServiceConfig( $Machine, $ServiceDatabase, $Service, \%ServiceConfig );
  if( $Result )
  {
    UpdateServiceConfig( $Service, \%ServiceConfig );
    $Result = Win32::Lanman::ChangeServiceConfig( $Machine, $ServiceDatabase, $Service, \%ServiceConfig );

  }
  return( $Result );
}

sub Configure 
{
  my( $Config ) = @_;
  my $fResult = 0;
  my %SERVICE_START = ( 
    auto    =>  SERVICE_AUTO_START,
    demand  =>  SERVICE_DEMAND_START,
    disabled =>  SERVICE_DISABLED
  );
  Getopt::Long::Configure( "prefix_pattern=(-|\/)" );
  $Config->{machine} = Win32::NodeName();
  $fResult = GetOptions( $Config,
                        qw(
                          list
                          stop=s
                          start=s
                          pause=s 
                          delete=s 
                          config=s 
                          install=s
                          continue=s
                          restart=s
                          display=s
                          sort|s=s

                          service_interactive|sinteract|si
                          service_account|sa=s
                          service_password|sp=s
                          service_display|sdisplay|sd=s
                          service_description|description|sdesc=s
                          service_name|sname|sn=s
                          service_dependencies|sdepend=s@
                          service_path|spath|sp=s
                          service_group|sgroup|sg=s
                          service_start|sstart|ss=s

                          help|?
                        ) );

  $Config->{machine} = shift @ARGV || "";
  map{ $Config->{action} = $_ if( defined $Config->{$_} ); } qw( start stop pause continue restart delete config install display );
  $Config->{service_start} = $SERVICE_START{lc $Config->{service_start}} || SERVICE_AUTO_START;
  $Config->{list} = 1 unless( "" ne $Config->{action} );
  $Config->{help} = 1 unless( $fResult );
  return( $fResult );
}

sub Syntax 
{
  my( $Path, $File ) = ( Win32::GetFullPathName( $0 ) =~ /(.*)([^\\]*)$/ );
  my $Line = "-" x length( $File );
  my $Machine = Win32::NodeName();
  print <<EOT

$File
$Line
  Lists all services running on a specified machine.
  
  $File [Machine] [list [-s <name|display|state>] 
                  [-stop|-start|-pause|-delete|-install|-restart|
                   -config|-display <ServiceName>]
                  [install options]
  Machine.......Name of machine whos services are listed.
                Default value is localhost ($Machine).
  -s <option>...Sort order. <Option> can be:
                  name......The service name.
                  display...The service display name.
                  state.....The state of services (e.g. running)            
  
  Install options:
      spath...........Full path (and any options) to the service .exe file.
      sname...........Name of the service (required).
      sinteract.......Indicates if the service should be seen by users.
      sa..............User account the service runs under.
                      Default: LocalSystem
      sp..............Password the service uses.
      sdisplay........The display name of the service.
      sdesc...........Description of the service.
      sdepend.........Dependency. Name of a dependent service. 
                      Repeat this option for all dependencies.
      sgroup..........Group name of the service.
      sstart..........When the service starts:
                        AUTO.......Auto starts when required (default).
                        DEMAND.....Manual start required by a user.
                        DISABLED...Never start.
                                   
                                   
  By default output is sorted by service name.
  
  Version $VERSION.
EOT
}

format LIST_SERVICE_HEADER =
    Service Name        State     Display Name
    ------------------  --------- -------------------------------------------
.

format LIST_SERVICE_NAME =
@<< @<<<<<<<<<<<<<<<<<  @<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$iCount, $Service->{name},   $SERVICE_FLAGS{status}->{$Service->{state}}, $Service->{display}
~                                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                  $Service->{display}
~                                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                  $Service->{display}
~                                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                  $Service->{display}
.

format LIST_SERVICE_DETAILS =
    @<<<<<<<<<<<<: ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    "\u$PropertyName", $PropertyValue
~                  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                   $PropertyValue
~                  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                   $PropertyValue
~                  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                   $PropertyValue
~                  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                   $PropertyValue
~                  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                   $PropertyValue
~                  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                   $PropertyValue
~                  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                   $PropertyValue
~                  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                   $PropertyValue
~                  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                   $PropertyValue
~                  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                   $PropertyValue
.

format LIST_SERVICE_DETAILS_ARRAY =
                 @>>>) ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$iEntryCount,          $PropertyValue,                    
~                      ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                       $PropertyValue,
~                      ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                       $PropertyValue,
~                      ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                       $PropertyValue,
~                      ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                       $PropertyValue,
.

__END__

History:
  20010519 rothd
    -Added support to sort output by status and description.
    -Restructured quite a bit.
    -Added passed in parameter support

  20010520 rothd
    -Fixed bug: could not pass in a machine name

  20010526 rothd
    -Fixed bug: Counter was incrimented twice when enumerating each service.

  20030625 rothd
    -Corrected syntax.

  20040806 rothd
    -Modified display support.
     
