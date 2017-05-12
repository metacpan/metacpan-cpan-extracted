package VMware::API::LabManager;

# Workaround for self-signed certs
$ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "Net::SSL";
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

use Data::Dumper;
use SOAP::Lite; # +trace => 'debug';
use warnings;
use strict;

$VMware::API::LabManager::VERSION = '2.11';

### External methods

sub new {
  my $class = shift @_;
  my $self  = {};

  $self->{username} = shift @_;
  $self->{password} = shift @_;
  $self->{hostname}  = shift @_;
  $self->{orgname}   = shift @_;
  $self->{workspace} = shift @_;

  $self->{debug}        = 0; # Defaults to no debug info
  $self->{die_on_fault} = 1; # Defaults to die'ing on an error
  $self->{ssl_timeout}  = 3600; # Defaults to 1h

  bless($self,$class);

  my $old_debug = shift @_;

  if ( defined $old_debug ) {
    warn "Old method for setting 'debug' used. You should use config() for this.";
    $self->config('debug',$old_debug);
  }

  my $old_die_on_fault = shift @_;

  if ( defined $old_die_on_fault ) {
    warn "Old method for setting 'die_on_fault' used. You should use config() for this.";
    $self->config('die_on_fault',$old_die_on_fault);
  }

  $self->_regenerate();

  $self->_debug("Loaded VMware::API::LabManager v" . our $VERSION . "\n") if $self->{debug};
  return $self;
}

sub config {
  my $self = shift @_;

  my %input = @_;
  my @config_vals = qw/debug die_on_fault hostname orgname password ssl_timeout username workspace/;
  my %config_vals = map { $_,1; } @config_vals;

  for my $key ( keys %input ) {
    if ( $config_vals{$key} ) {
      $self->{$key} = $input{$key};
    } else {
      warn 'Config key "$key" is being ignored. Only the following options may be configured: '
         . join(", ", @config_vals ) . "\n";
    }
  }

  $self->_regenerate();

  my %out;
  map { $out{$_} = $self->{$_} } @config_vals;

  return wantarray ? %out : \%out;
}

sub getLastSOAPError {
  my $self = shift @_;
  my $error_summary;
  if ( $self->{LASTERROR} and $self->{LASTERROR}->{data} ) {
    $error_summary = "\n\nERROR: $self->{LASTERROR}->{text}\n";
    $error_summary .= "\n\nSUBMITTED XML: $self->{LASTERROR}->{xml} \n" if $self->{LASTERROR}->{xml};
    $error_summary .= "\n\nERROR DEBUG: " . Dumper($self->{LASTERROR}->{data}) if $self->{debug};
    $self->{LASTERROR} = {};
  }
  return $error_summary;
}

### Internal methods

sub _debug {
  my $self = shift @_;
  while ( my $debug = shift @_ ) {
    chomp $debug;
    print STDERR "DEBUG: $debug\n";
  }
}

sub _fault {
  my $self = shift @_;
  my $data = shift @_;
  my $soapobj;
  my $text;

  if ( ref $data ) {
    $soapobj = $data;
    $data = $soapobj->fault;
  }

  if ( ref $data and defined $data->{faultstring} ) {
    $text = $data->{faultstring};
  } elsif ( ref $data and ref $data->{detail} and defined $data->{detail}->{message}->{format} ) {
    $text = $data->{detail}->{message}->{format};
  } else {
    $text = $data;
    $data = '';
  }

  my $xml;
  $xml = $soapobj->{_context}->{_transport}->{_proxy}->{_http_response}->{_request}->{_content}
    if ref $soapobj;

  warn "\n\nERROR DETAILS:\n" . Dumper($data) if $self->{debug};
  warn "\n\nSUBMITTED XML:\n" . $xml if $xml; #if $self->{debug} and $xml;

  if ( $self->{die_on_fault} ) {
    die "\n\nERROR: $text\n";
  } else {
    $self->{LASTERROR}->{data} = $data;
    $self->{LASTERROR}->{text} = $text;
    $self->{LASTERROR}->{xml}  = $xml;
    warn "\n\nERROR: $text\n";
  }
}

sub _regenerate {
  my $self = shift @_;

  $self->{soap} = SOAP::Lite
    -> on_action(sub { return "http://vmware.com/labmanager/" . $_[1]; } )
    -> default_ns('http://vmware.com/labmanager')
    -> proxy('https://' . $self->{hostname} . '/LabManager/SOAP/LabManager.asmx', timeout => $self->{ssl_timeout} );

  $self->{soap_priv} = SOAP::Lite
    -> on_action(sub { return "http://vmware.com/labmanager/" . $_[1]; } )
    -> default_ns('http://vmware.com/labmanager')
    -> proxy('https://' . $self->{hostname} . '/LabManager/SOAP/LabManagerInternal.asmx', timeout => $self->{ssl_timeout} );

  $self->{soap}->readable(1);
  $self->{soap_priv}->readable(1);

  $self->{auth_header} = SOAP::Header->new(
		name => 'AuthenticationHeader',
		attr => { xmlns => "http://vmware.com/labmanager" },
		value => { username => $self->{username}, password => $self->{password}, organizationname => $self->{orgname}, workspacename => $self->{workspace}  },
  );
}

### Public API methods

sub ConfigurationCapture {
  my $self       = shift @_;
  my $configID   = shift @_;
  my $newLibName = shift @_;

  $self->{ConfigurationCapture} =
    $self->{soap}->ConfigurationCapture(
      $self->{auth_header},
      SOAP::Data->name('configurationId' => $configID   )->type('s:int'),
      SOAP::Data->name('newLibraryName'  => $newLibName )->type('s:string')
    );

  if ( $self->{ConfigurationCapture}->fault ) {
    $self->_fault( $self->{ConfigurationCapture} );
    return $self->{ConfigurationCapture}->fault;
  } else {
    return $self->{ConfigurationCapture}->result;
  }
}

sub ConfigurationCheckout {
  my $self       = shift @_;
  my $configID   = shift @_;
  my $configName = shift @_;

  $self->{ConfigurationCheckout} =
    $self->{soap}->ConfigurationCheckout(
		$self->{auth_header},
		SOAP::Data->name('configurationId' => $configID   )->type('s:int'),   # Config to check out
        SOAP::Data->name('workspaceName'   => $configName )->type('s:string') # New name it shall be
	);

  if ( $self->{ConfigurationCheckout}->fault ) {
    $self->_fault( $self->{ConfigurationCheckout} );
    return $self->{ConfigurationCheckout}->fault;
  } else {
    return $self->{ConfigurationCheckout}->result;
  }
}

sub ConfigurationClone {
  my $self = shift @_;
  my $configID = shift @_;
  my $newWSName = shift @_;

	$self->{ConfigurationClone} =
		$self->{soap}->ConfigurationClone($self->{auth_header},
		SOAP::Data->name('configurationId' => $configID )->type('s:int'),
        SOAP::Data->name('newWorkspaceName' => $newWSName )->type('s:string') );

  if ( $self->{ConfigurationClone}->fault ) {
    $self->_fault( $self->{ConfigurationClone} );
    return $self->{ConfigurationClone}->fault;
  } else {
    return $self->{ConfigurationClone}->result;
  }
}

sub ConfigurationDelete {
  my $self = shift @_;
  my $configID = shift @_;

  $self->{ConfigurationDelete} =
    $self->{soap}->ConfigurationDelete( $self->{auth_header},
    SOAP::Data->name('configurationId' => $configID)->type('s:int')
  );

  if ( $self->{ConfigurationDelete}->fault ) {
    $self->_fault( $self->{ConfigurationDelete} );
    return $self->{ConfigurationDelete}->fault;
  } else {
    return $self->{ConfigurationDelete}->result;
  }
}

sub ConfigurationDeploy {
  my $self      = shift @_;
  my $configID  = shift @_;
  my $fencemode = shift @_; # 1 = not fenced; 2 = block traffic in and out; 3 = allow out ; 4 allow in and out

	$self->{ConfigurationDeploy} =
		$self->{soap}->ConfigurationDeploy( $self->{auth_header},
		SOAP::Data->name('configurationId' => $configID )->type('s:int'),
		SOAP::Data->name('isCached' => "false")->type('s:boolean'),
		SOAP::Data->name('fenceMode' => $fencemode)->type('s:int') );
		
  if ( $self->{ConfigurationDeploy}->fault ) {
    $self->_fault( $self->{ConfigurationDeploy} );
    return $self->{ConfigurationDeploy}->fault;
  } else {
    return $self->{ConfigurationDeploy}->result;
  }
}

sub ConfigurationPerformAction {
  my $self     = shift @_;
  my $configID = shift @_;
  my $action   = shift @_; # 1-Pwr On, 2-Pwr off, 3-Suspend, 4-Resume, 5-Reset, 6-Snapshot

  $self->{ConfigurationPerformAction} =
    $self->{soap}->ConfigurationPerformAction( $self->{auth_header},
	SOAP::Data->name('configurationId' => $configID )->type('s:int'),
	SOAP::Data->name('action' => $action )->type('s:int') );

  if ( $self->{ConfigurationPerformAction}->fault ) {
    $self->_fault( $self->{ConfigurationPerformAction} );
    return $self->{ConfigurationPerformAction}->fault;
  } else {
    return $self->{ConfigurationPerformAction}->result;
  }
}

sub ConfigurationSetPublicPrivate {
  my $self = shift @_;
  my $conf = shift @_;
  my $bool = shift @_;

  $self->{ConfigurationSetPublicPrivate} =
    $self->{soap}->ConfigurationSetPublicPrivate( $self->{auth_header},
    SOAP::Data->name('configurationId' => $conf )->type('s:int'),
    SOAP::Data->name('isPublic'        => $bool )->type('s:boolean')
  );

  if ( $self->{ConfigurationSetPublicPrivate}->fault ) {
    $self->_fault( $self->{ConfigurationSetPublicPrivate} );
    return $self->{ConfigurationSetPublicPrivate}->fault;
  } else {
    return $self->{ConfigurationSetPublicPrivate}->result;
  }
}

sub ConfigurationUndeploy {
  my $self = shift @_;
  my $configID = shift @_;

	$self->{ConfigurationUndeploy} =
		$self->{soap}->ConfigurationUndeploy( $self->{auth_header},
		SOAP::Data->name('configurationId' => $configID )->type('s:int'));

  if ( $self->{ConfigurationUndeploy}->fault ) {
    $self->_fault( $self->{ConfigurationUndeploy} );
    return $self->{ConfigurationUndeploy}->fault;
  } else {
    return $self->{ConfigurationUndeploy}->result;
  }
}

sub GetConfiguration {
  my $self = shift @_;
  my $conf = shift @_;
		
  $self->{GetConfiguration} =
    $self->{soap}->GetConfiguration(
      $self->{auth_header},
      SOAP::Data->name('id' => $conf )->type('s:int')
    );

  if ( $self->{GetConfiguration}->fault ) {
    $self->_fault( $self->{GetConfiguration} );
    return $self->{GetConfiguration}->fault;
  } else {
    return $self->{GetConfiguration}->result;
  }
}

sub GetConfigurationByName {
  my $self = shift @_;
  my $name = shift @_;
		
  $self->{GetConfigurationByName} =
    $self->{soap}->GetConfigurationByName(
      $self->{auth_header},
      SOAP::Data->name( name => $name )->type('s:string')
    );

  if ( $self->{GetConfigurationByName}->fault ) {
    $self->_fault( $self->{GetConfigurationByName} );
    return $self->{GetConfigurationByName}->fault;
  }

  my $ret = $self->{GetConfigurationByName}->result;

  my $array = $ret ? [ $ret ] : [ ];
  $array = [ $ret->{Configuration} ] if ref $ret and ref $ret->{Configuration} eq 'HASH';
  $array =   $ret->{Configuration}   if ref $ret and ref $ret->{Configuration} eq 'ARRAY';

  return wantarray ? @$array : $array;
}

sub GetMachine {
  my $self = shift @_;
  my $id   = shift @_;

  $self->{GetMachine} =
    $self->{soap}->GetMachine(
      $self->{auth_header},
	  SOAP::Data->name('machineId' => $id)->type('s:int') # mislabeled "machineID" by PUB API docs
	);

  if ( $self->{GetMachine}->fault ) {
    $self->_fault( $self->{GetMachine} );
    return $self->{GetMachine}->fault;
  } else {
    return $self->{GetMachine}->result;
  }
}

sub GetMachineByName {
  my $self   = shift @_;
  my $config = shift @_;
  my $name   = shift @_;
		
  $self->{GetMachineByName} =
    $self->{soap}->GetMachineByName( $self->{auth_header},
    SOAP::Data->name('configurationId' => $config)->type('s:int'),
    SOAP::Data->name('name' => $name)->type('s:string'));

  if ( $self->{GetMachineByName}->fault ) {
    $self->_fault( $self->{GetMachineByName} );
    return $self->{GetMachineByName}->fault;
  } else {
    return $self->{GetMachineByName}->result;
  }
}

sub GetSingleConfigurationByName {
  my $self    = shift @_;
  my $config  = shift @_;
		
  $self->{GetSingleConfigurationByName} =
    $self->{soap}->GetSingleConfigurationByName( $self->{auth_header},
    SOAP::Data->name('name' => $config)->type('s:string'));

  if ( $self->{GetSingleConfigurationByName}->fault ) {
    $self->_fault( $self->{GetSingleConfigurationByName} );
    return $self->{GetSingleConfigurationByName}->fault;
  } else {
    return $self->{GetSingleConfigurationByName}->result;
  }
}

sub ListConfigurations {
  my $self = shift @_;
  my $type = shift @_; #1 =WorkSpace, 2=Library

  $self->_debug("LISTING CONFIGURATIONS") if $self->{debug};

  unless ($type == 1 || $type == 2 ) {
    $self->{LASTERROR} = "Configuration Type must be either 1 for Workspace or 2 for Library";
    $self->_fault( $self->{LASTERROR} );
  }

  $self->{ListConfigurations} = $self->{soap}->ListConfigurations( $self->{auth_header}, SOAP::Data->name('configurationType' => $type)->type('s:int'));

  if ( $self->{ListConfigurations}->fault ) {
    $self->_fault( $self->{ListConfigurations} );
    return $self->{ListConfigurations}->fault;
  }

  my $ret = $self->{ListConfigurations}->result;

  my $array = $ret ? [ $ret ] : [ ];
  $array = [ $ret->{Configuration} ] if ref $ret and ref $ret->{Configuration} eq 'HASH';
  $array =   $ret->{Configuration}   if ref $ret and ref $ret->{Configuration} eq 'ARRAY';

  return wantarray ? @$array : $array;
}

sub ListMachines {
  my $self   = shift @_;
  my $config = shift @_;

  $self->{ListMachines} =
    $self->{soap}->ListMachines( $self->{auth_header},
    SOAP::Data->name('configurationId' => $config)->type('s:int'));

  if ( $self->{ListMachines}->fault ) {
    $self->_fault( $self->{ListMachines} );
    return $self->{ListMachines}->fault;
  }

  my $ret = $self->{ListMachines}->result;

  my $array = [];
  $array = [ $ret->{Machine} ] if ref $ret and ref $ret->{Machine} eq 'HASH';
  $array =   $ret->{Machine}   if ref $ret and ref $ret->{Machine} eq 'ARRAY';

  return wantarray ? @$array : $array;
}

###### CHECK THIS
# Not Supported, but works (I believe)
sub GetConsoleAccessInfo {
	# Attribs: ServerAddress, ServerPort,VmxLocation,Ticket
	my($self) = shift @_;
	my($machineId) = shift @_;
	push(my(@attribs), @_);
	my @myattribs;

	$self->{GetConsoleAccessInfo} =
		$self->{soap}->GetConsoleAccessInfo( $self->{auth_header},
		SOAP::Data->name('machineId' => $machineId)->type('s:int'));

  if ( $self->{GetConsoleAccessInfo}->fault ) {
    $self->_fault( $self->{GetConsoleAccessInfo} );
    return $self->{GetConsoleAccessInfo}->fault;
  } else {
    return $self->{GetConsoleAccessInfo}->result;
  }
}	

sub LiveLink {
  my $self = shift @_;
  my $configName = shift @_;

  $self->{LiveLink} =
    $self->{soap}->LiveLink( $self->{auth_header},
    SOAP::Data->name('configName' => $configName)->type('s:string'));

  if ( $self->{LiveLink}->fault ) {
    $self->_fault( $self->{LiveLink} );
    return $self->{LiveLink}->fault;
  } else {
    return $self->{LiveLink}->result;
  }
}

sub MachinePerformAction {
  my $self     = shift @_;
  my $configID = shift @_;
  my $action   = shift @_;  # Actions: 1-Pwr On, 2-Pwr off, 3-Suspend, 4-Resume, 5-Reset, 6-Snapshot , 7-Revert, 8-Shutdown

  $self->{MachinePerformAction} =
    $self->{soap}->MachinePerformAction( $self->{auth_header},
	SOAP::Data->name('machineId' => $configID )->type('s:int'),
	SOAP::Data->name('action' => $action )->type('s:int') );

  if ( $self->{MachinePerformAction}->fault ) {
    $self->_fault( $self->{MachinePerformAction} );
    return $self->{MachinePerformAction}->fault;
  } else {
    return $self->{MachinePerformAction}->result;
  }
}

### Internal API methods

sub priv_ConfigurationAddMachineEx {
  my $self = shift @_;

  my $ipaddress  = '10.10.220.10';
  my $macAddress = '00:50:DE:AD:BE:EF';

  $_[4] = 0 unless $_[4];
  $_[5] = 0 unless $_[5];

  my $eth0 = SOAP::Data->name('NetInfo'    => \SOAP::Data->value(
               SOAP::Data->name('networkId'   => 1           )->type('s:int'),
	           SOAP::Data->name('nicId'       => 0           )->type('s:int'),
	           #SOAP::Data->name('vmxSlot'     => 1           )->type('s:int'),
	           SOAP::Data->name('macAddress'  => $macAddress )->type('s:string'),
	           SOAP::Data->name('resetMac'    => 'true'      )->type('s:boolean'),
	           SOAP::Data->name('ipAddress'   => $ipaddress  )->type('s:string'),
	           SOAP::Data->name('ipAddressingMode' => 'STATIC_MANUAL')->type('s:string'),
	           SOAP::Data->name('netmask'     => '255.255.255.0')->type('s:string'),
	           SOAP::Data->name('gateway'     => '10.10.220.1')->type('s:string'),
	           SOAP::Data->name('dns1'        => '4.2.2.1')->type('s:string'),
	           SOAP::Data->name('dns2'        => '4.2.2.2')->type('s:string'),
	           SOAP::Data->name('isConnected' => 1           )->type('s:int'),
	         ));

  $self->{ConfigurationAddMachineEx} =
    $self->{soap_priv}->ConfigurationAddMachineEx(
      $self->{auth_header},
	  SOAP::Data->name('id'         =>$_[0])->type('s:int'),
	  SOAP::Data->name('template_id'=>$_[1])->type('s:int'),
	  SOAP::Data->name('name'       =>$_[2])->type('s:string'),
	  SOAP::Data->name('desc'       =>$_[3])->type('s:string'),
	  SOAP::Data->name('boot_seq'   =>$_[4])->type('s:int'),
	  SOAP::Data->name('boot_delay' =>$_[5])->type('s:int'),
	  SOAP::Data->name('netInfo'    => \SOAP::Data->value(
          #$eth0,
	    )
	  )
	);

  if ( $self->{ConfigurationAddMachineEx}->fault ) {
    $self->_fault( $self->{ConfigurationAddMachineEx} );
    return $self->{ConfigurationAddMachineEx}->fault;
  } else {
    return $self->{ConfigurationAddMachineEx}->result;
  }
}

sub priv_ConfigurationArchiveEx {
  my $self               = shift @_;
  my $configurationId    = shift @_;
  my $archiveName        = shift @_;
  my $archiveDescription = shift @_;
  my $isFullClone        = shift @_;
  my $storageName        = shift @_;
  my $storageLeaseInMilliseconds = shift @_ || 0;

  $isFullClone = 'false' unless $isFullClone =~ /^true$/i;

  $self->{ConfigurationArchiveEx} =
    $self->{soap_priv}->ConfigurationArchiveEx(
      $self->{auth_header},
      SOAP::Data->name('configurationID'            => $configurationId            )->type('s:int'),
      SOAP::Data->name('archiveName'                => $archiveName                )->type('s:string'),
      SOAP::Data->name('archiveDescription'         => $archiveDescription         )->type('s:string'),
      SOAP::Data->name('isFullClone'                => $isFullClone                )->type('s:boolean'),
      SOAP::Data->name('storageName'                => $storageName                )->type('s:string'),
      SOAP::Data->name('storageLeaseInMilliseconds' => $storageLeaseInMilliseconds )->type('s:long')
    );

  if ( $self->{ConfigurationArchiveEx}->fault ) {
    $self->_fault( $self->{ConfigurationArchiveEx} );
    return $self->{ConfigurationArchiveEx}->fault;
  } else {
    return $self->{ConfigurationArchiveEx}->result;
  }
}

sub priv_ConfigurationCaptureEx {
  my $self               = shift @_;
  my $configurationId    = shift @_;
  my $newLibraryName     = shift @_;
  my $libraryDescription = shift @_;
  my $isGoldMaster       = shift @_;
  my $storageName        = shift @_;
  my $storageLeaseInMilliseconds = shift @_ || 0;

  $isGoldMaster = 'false' unless $isGoldMaster =~ /^true$/i;

  $self->{ConfigurationCaptureEx} =
    $self->{soap_priv}->ConfigurationCaptureEx(
      $self->{auth_header},
      SOAP::Data->name('configurationId'            => $configurationId            )->type('s:int'),
      SOAP::Data->name('newLibraryName'             => $newLibraryName             )->type('s:string'),
      SOAP::Data->name('libraryDescription'         => $libraryDescription         )->type('s:string'),
      SOAP::Data->name('isGoldMaster'               => $isGoldMaster               )->type('s:boolean'),
      SOAP::Data->name('storageName'                => $storageName                )->type('s:string'),
      SOAP::Data->name('storageLeaseInMilliseconds' => $storageLeaseInMilliseconds )->type('s:long')
    );

  if ( $self->{ConfigurationCaptureEx}->fault ) {
    $self->_fault( $self->{ConfigurationCaptureEx} );
    return $self->{ConfigurationCaptureEx}->fault;
  } else {
    return $self->{ConfigurationCaptureEx}->result;
  }
}

sub priv_ConfigurationChangeOwner {
  my $self = shift @_;
  my $conf = shift @_;
  my $own  = shift @_;

  $self->{ConfigurationChangeOwner} =
    $self->{soap_priv}->ConfigurationChangeOwner(
      $self->{auth_header},
      SOAP::Data->name('configurationId' => $conf )->type('s:int'),
      SOAP::Data->name('newOwnerId'      => $own  )->type('s:int'),
    );

  if ( $self->{ConfigurationChangeOwner}->fault ) {
    $self->_fault( $self->{ConfigurationChangeOwner} );
    return $self->{ConfigurationChangeOwner}->fault;
  } else {
    return $self->{ConfigurationChangeOwner}->result;
  }
}

sub priv_ConfigurationCopy {
  my $self        = shift @_;
  my $sg_id       = shift @_;
  my $name        = shift @_;
  my $description = shift @_;

  my $machines = shift @_;
  my $storage = shift @_;

  my @machine_data;

  for my $machine (@$machines) {
    my @elements;
    for my $element ( keys %$machine ) {
      push @elements, SOAP::Data->name( $element, $machine->{$element} );
    }
    push @machine_data, SOAP::Data->name('machine' => \SOAP::Data->value(@elements));
  }

  $self->{ConfigurationCopy} =
    $self->{soap_priv}->ConfigurationCopy(
      $self->{auth_header},
      SOAP::Data->name('sg_id'       => $sg_id       )->type('s:int'),
      SOAP::Data->name('name'        => $name        )->type('s:string'),
      SOAP::Data->name('description' => $description )->type('s:string'),
	  SOAP::Data->name('configurationCopyData' => \SOAP::Data->value(
        SOAP::Data->name('VMCopyData' => \SOAP::Data->value(
          @machine_data,
          SOAP::Data->name('storageServerName' => $storage )->type('s:string')
        ))
	  ))
    );

  if ( $self->{ConfigurationCopy}->fault ) {
    $self->_fault( $self->{ConfigurationCopy} );
    return $self->{ConfigurationCopy}->fault;
  } else {
    return $self->{ConfigurationCopy}->result;
  }
}

sub priv_ConfigurationCloneToWorkspace {
  my $self               = shift @_;
  my $destWorkspaceId    = shift @_;
  my $isNewConfiguration = shift @_;
  my $newConfigName      = shift @_;
  my $description        = shift @_;

  my $machines = shift @_;
  my $storage  = shift @_;

  my $existingConfigId           = shift @_;
  my $isFullClone                = shift @_;
  my $storageLeaseInMilliseconds = shift @_;

  $isNewConfiguration = 'false' unless $isNewConfiguration =~ /^true$/i;
  $isFullClone = 'false' unless $isFullClone =~ /^true$/i;

  my @machine_data;

  for my $machine (@$machines) {
    my @elements;
    for my $element ( keys %$machine ) {
      push @elements, SOAP::Data->name( $element, $machine->{$element} );
    }
    push @machine_data, SOAP::Data->name('machine' => \SOAP::Data->value(@elements));
  }

  $self->{ConfigurationCloneToWorkspace} =
    $self->{soap_priv}->ConfigurationCloneToWorkspace(
      $self->{auth_header},
      SOAP::Data->name('destWorkspaceId'    => $destWorkspaceId    )->type('s:int'),
      SOAP::Data->name('isNewConfiguration' => $isNewConfiguration )->type('s:bool'),
      SOAP::Data->name('newConfigName'      => $newConfigName      )->type('s:string'),
      SOAP::Data->name('description'        => $description        )->type('s:string'),
	  SOAP::Data->name('configurationCopyData' => \SOAP::Data->value(
        SOAP::Data->name('VMCopyData' => \SOAP::Data->value(
          @machine_data,
          SOAP::Data->name('storageServerName' => $storage )->type('s:string')
        ))
	  )),
      SOAP::Data->name('isFullClone' => $newConfigName )->type('s:bool'),
      SOAP::Data->name('storageLeaseInMilliseconds' => $description )->type('s:long'),	
    );

  if ( $self->{ConfigurationCloneToWorkspace}->fault ) {
    $self->_fault( $self->{ConfigurationCloneToWorkspace} );
    return $self->{ConfigurationCloneToWorkspace}->fault;
  } else {
    return $self->{ConfigurationCloneToWorkspace}->result;
  }
}

sub priv_ConfigurationCreateEx {
  my $self = shift @_;
  my $name = shift @_;
  my $desc = shift @_;

  $self->{ConfigurationCreateEx} =
    $self->{soap_priv}->ConfigurationCreateEx(
      $self->{auth_header},
	  SOAP::Data->name('name'=>$name)->type('s:string'),
	  SOAP::Data->name('desc'=>$desc)->type('s:string')
	);

  if ( $self->{ConfigurationCreateEx}->fault ) {
    $self->_fault( $self->{ConfigurationCreateEx} );
    return $self->{ConfigurationCreateEx}->fault;
  } else {
    return $self->{ConfigurationCreateEx}->result;
  }
}

sub priv_ConfigurationDeployEx2 {
   my $self = shift @_;
   my $configID = shift @_;
   my $networkId = shift @_;
   my $fenceMode = 'FenceAllowInAndOut';

   my $net_elem = SOAP::Data->name( 'FenceNetworkOption' => \SOAP::Data->value(
                        SOAP::Data->name('configuredNetID' => $networkId)->type('s:int'),
                        SOAP::Data->name('DeployFenceMode'=> $fenceMode)->type('tns:SOAPFenceMode')
                     )
                  );

   my $bridge_elem = SOAP::Data->name( 'BridgeNetworkOption' => \SOAP::Data->value(
                           SOAP::Data->name('externalNetId' => $networkId)->type('s:int')
                        )
                     );

   my @net_array;
   my @bridge_array;
   push(@net_array,$net_elem);
   push(@bridge_array,$bridge_elem);

   $self->{ConfigurationDeployEx2} =
      $self->{soap_priv}->ConfigurationDeployEx2( $self->{auth_header},
      SOAP::Data->name('configurationId' => $configID )->type('s:int'),
      SOAP::Data->name('honorBootOrders' => 1)->type('s:boolean'),
      SOAP::Data->name('startAfterDeploy' => 1)->type('s:boolean'),
      SOAP::Data->name('fenceNetworkOptions' => \SOAP::Data->value( @net_array )->type('tns:ArrayOfFenceNetworkOption')),
		#Do not uncomment unless you know how to make it work:
      #SOAP::Data->name('bridgeNetworkOptions' =>\SOAP::Data->value(  @bridge_array )->type('tns:ArrayOfBridgeNetworkOption')),
      SOAP::Data->name('isCrossHost' => 1)->type('s:boolean')
      );

  if ( $self->{ConfigurationDeployEx2}->fault ) {
    $self->_fault( $self->{ConfigurationDeployEx2} );
    return $self->{ConfigurationDeployEx2}->fault;
  } else {
    return $self->{ConfigurationDeployEx2}->result;
  }
}

sub priv_ConfigurationExport {
  my $self = shift @_;
  my $conf = shift @_;
  my $unc  = shift @_;
  my $user = shift @_;
  my $pass = shift @_;

  $self->{ConfigurationExport} =
    $self->{soap_priv}->ConfigurationExport(
      $self->{auth_header},
	  SOAP::Data->name('configId' =>$conf)->type('s:int'),
	  SOAP::Data->name('uncPath'  =>$unc )->type('s:string'),
	  SOAP::Data->name('username' =>$user)->type('s:string'),
	  SOAP::Data->name('password' =>$pass)->type('s:string'),
	);

  if ( $self->{ConfigurationExport}->fault ) {
    $self->_fault( $self->{ConfigurationExport} );
    return $self->{ConfigurationExport}->fault;
  } else {
    return $self->{ConfigurationExport}->result;
  }
}

sub priv_ConfigurationGetNetworks {
  my $self = shift @_;
  my $conf = shift @_;
  my $phys = shift @_;

  $phys = 'false' unless $phys =~ /^true$/i;

  $self->{ConfigurationGetNetworks} =
    $self->{soap_priv}->ConfigurationGetNetworks(
      $self->{auth_header},
	  SOAP::Data->name('configID'=>$conf)->type('s:int'),
	  SOAP::Data->name('physical'=>$phys)->type('s:boolean'),
    );

  if ( $self->{ConfigurationGetNetworks}->fault ) {
    $self->_fault( $self->{ConfigurationGetNetworks} );
    return $self->{ConfigurationGetNetworks}->fault;
  }

  my $ret = $self->{ConfigurationGetNetworks}->result;

  return $ret;

  #my $array = $ret ? [ $ret ] : [ ];
  #$array = [ $ret->{Network} ] if ref $ret and ref $ret->{Network} eq 'HASH';
  #$array =   $ret->{Network}   if ref $ret and ref $ret->{Network} eq 'ARRAY';

  #return wantarray ? @$array : $array;
}

sub priv_ConfigurationImport {
  my $self = shift @_;
  my $unc  = shift @_;
  my $user = shift @_;
  my $pass = shift @_;
  my $name = shift @_;
  my $desc = shift @_;
  my $stor = shift @_;

  $self->{ConfigurationImport} =
    $self->{soap_priv}->ConfigurationImport(
      $self->{auth_header},
	  SOAP::Data->name('UNCPath'     =>$unc )->type('s:string'),
	  SOAP::Data->name('dirUsername' =>$user)->type('s:string'),
	  SOAP::Data->name('dirPassword' =>$pass)->type('s:string'),
	  SOAP::Data->name('name'        =>$name)->type('s:string'),
	  SOAP::Data->name('description' =>$desc)->type('s:string'),
	  SOAP::Data->name('storageName' =>$stor)->type('s:string'),
	);

  if ( $self->{ConfigurationImport}->fault ) {
    $self->_fault( $self->{ConfigurationImport} );
    return $self->{ConfigurationImport}->fault;
  } else {
    return $self->{ConfigurationImport}->result;
  }
}

sub priv_ConfigurationMove {
  my $self  = shift @_;
  my $conf  = shift @_;
  my $dest  = shift @_;
  my $isnew = shift @_;
  my $name  = shift @_;
  my $desc  = shift @_;
  my $lease = shift @_;
  my $exist = shift @_;
  my $vmids = shift @_;
  my $del   = shift @_;

  $isnew = 'false' unless $isnew =~ /^true$/i;
  $del   = 'false' unless $del   =~ /^true$/i;

  my $vmids_xml = SOAP::Data->name('vmIds');
  $vmids_xml = SOAP::Data->name( vmIds => \SOAP::Data->name('int', @$vmids ))
    if ref $vmids;

  my @optional;
  push @optional, SOAP::Data->name('existingConfigId'           =>$exist)->type('s:int')     if $exist;
  push @optional, SOAP::Data->name('newConfigName'              =>$name )->type('s:string')  if $name;
  push @optional, SOAP::Data->name('newConfigDescription'       =>$desc )->type('s:string')  if $desc;
  push @optional, SOAP::Data->name('storageLeaseInMilliseconds' =>$lease)->type('s:long')    if $lease;
  push @optional, SOAP::Data->name('deleteOriginalConfig'       =>$del  )->type('s:boolean') if $del;

  $self->{ConfigurationMove} =
    $self->{soap_priv}->ConfigurationMove(
      $self->{auth_header},
	  SOAP::Data->name('configIdToMove'         =>$conf )->type('s:int'),
	  SOAP::Data->name('destinationWorkspaceId' =>$dest )->type('s:int'),
	  SOAP::Data->name('isNewConfiguration'     =>$isnew)->type('s:boolean'),
      @optional, $vmids_xml
	);
	
  if ( $self->{ConfigurationMove}->fault ) {
    $self->_fault( $self->{ConfigurationMove} );
    return $self->{ConfigurationMove}->fault;
  } else {
    return $self->{ConfigurationMove}->result;
  }
}

sub priv_GetAllWorkspaces {
  my $self = shift @_;
  $self->{GetAllWorkspaces} = $self->{soap_priv}->GetAllWorkspaces( $self->{auth_header} );

  if ( $self->{GetAllWorkspaces}->fault ) {
    $self->_fault( $self->{GetAllWorkspaces} );
    return $self->{GetAllWorkspaces}->fault;
  }

  my $ret = $self->{GetAllWorkspaces}->result;

  my $array = [ $ret ];
  $array = [ $ret->{Workspace} ] if ref $ret and ref $ret->{Workspace} eq 'HASH';
  $array =   $ret->{Workspace}   if ref $ret and ref $ret->{Workspace} eq 'ARRAY';

  return wantarray ? @$array : $array;
}

sub priv_GetNetworkInfo {
  my $self = shift @_;
  my $vmid = shift @_;

  $self->{GetNetworkInfo} =
    $self->{soap_priv}->GetNetworkInfo(
      $self->{auth_header},
	  SOAP::Data->name('vmID'=>$vmid)->type('s:int')
	);

  if ( $self->{GetNetworkInfo}->fault ) {
    $self->_fault( $self->{GetNetworkInfo} );
    return $self->{GetNetworkInfo}->fault;
  }

  my $ret = $self->{GetNetworkInfo}->result;

  my $array = [];
  $array = [ $ret->{NetInfo} ] if ref $ret and ref $ret->{NetInfo} eq 'HASH';
  $array =   $ret->{NetInfo}   if ref $ret and ref $ret->{NetInfo} eq 'ARRAY';

  return wantarray ? @$array : $array;
}

sub priv_GetObjectConditions {
  my $self = shift @_;
  my $objectType = shift @_;
  my $objectID   = shift @_;

  $self->{GetObjectConditions} =
    $self->{soap_priv}->GetObjectConditions(
      $self->{auth_header},
	  SOAP::Data->name('objectType'=>$objectType)->type('s:int'),
	  SOAP::Data->name('objectID'=>$objectID)->type('s:int'),
	);

  if ( $self->{GetObjectConditions}->fault ) {
    $self->_fault( $self->{GetObjectConditions} );
    return $self->{GetObjectConditions}->fault;
  } else {
    return $self->{GetObjectConditions}->result;
  }
}

sub priv_GetOrganization {
  my $self = shift @_;
  my $oid  = shift @_;

  $self->{GetOrganization} =
    $self->{soap_priv}->GetOrganization(
      $self->{auth_header},
	  SOAP::Data->name('organizationId'=>$oid)->type('s:int')
	);

  if ( $self->{GetOrganization}->fault ) {
    $self->_fault( $self->{GetOrganization} );
    return $self->{GetOrganization}->fault;
  } else {
    return $self->{GetOrganization}->result;
  }
}

sub priv_GetOrganizations {
  my $self = shift @_;
  $self->{GetOrganizations} = $self->{soap_priv}->GetOrganizations( $self->{auth_header} );

  if ( $self->{GetOrganizations}->fault ) {
    $self->_fault( $self->{GetOrganizations} );
    return $self->{GetOrganizations}->fault;
  }

  my $ret = $self->{GetOrganizations}->result;

  my $array = [ $ret ];
  $array = [ $ret->{Organization} ] if ref $ret and ref $ret->{Organization} eq 'HASH';
  $array =   $ret->{Organization}   if ref $ret and ref $ret->{Organization} eq 'ARRAY';

  return wantarray ? @$array : $array;
}

sub priv_GetOrganizationByName {
  my $self = shift @_;
  my $name = shift @_;

  $self->{GetOrganizationByName} =
    $self->{soap_priv}->GetOrganizationByName(
      $self->{auth_header},
	  SOAP::Data->name('organizationName'=>$name)->type('s:string')
	);

  if ( $self->{GetOrganizationByName}->fault ) {
    $self->_fault( $self->{GetOrganizationByName} );
    return $self->{GetOrganizationByName}->fault;
  } else {
    return $self->{GetOrganizationByName}->result;
  }
}

sub priv_GetOrganizationWorkspaces {
  my $self = shift @_;
  my $oid  = shift @_;

  $self->{GetOrganizationWorkspaces} =
    $self->{soap_priv}->GetOrganizationWorkspaces(
      $self->{auth_header},
	  SOAP::Data->name('organizationId'=>$oid)->type('s:int')
	);

  if ( $self->{GetOrganizationWorkspaces}->fault ) {
    $self->_fault( $self->{GetOrganizationWorkspaces} );
    return $self->{GetOrganizationWorkspaces}->fault;
  }

  my $ret = $self->{GetOrganizationWorkspaces}->result;

  my $array = [ $ret ];
  $array = [ $ret->{Workspace} ] if ref $ret and ref $ret->{Workspace} eq 'HASH';
  $array =   $ret->{Workspace}   if ref $ret and ref $ret->{Workspace} eq 'ARRAY';

  return wantarray ? @$array : $array;
}

sub priv_GetTemplate {
  my $self = shift @_;
  my $id  = shift @_;

  $self->{GetTemplate} =
    $self->{soap_priv}->GetTemplate(
      $self->{auth_header},
	  SOAP::Data->name('id'=>$id)->type('s:int')
	);

  if ( $self->{GetTemplate}->fault ) {
    $self->_fault( $self->{GetTemplate} );
    return $self->{GetTemplate}->fault;
  } else {
    return $self->{GetTemplate}->result;
  }
}

sub priv_GetUser {
  my $self = shift @_;
  my $name = shift @_;

  $self->{GetUser} =
    $self->{soap_priv}->GetUser(
      $self->{auth_header},
	  SOAP::Data->name('userName'=>$name)->type('s:string')
	);

  if ( $self->{GetUser}->fault ) {
    $self->_fault( $self->{GetUser} );
    return $self->{GetUser}->fault;
  } else {
    return $self->{GetUser}->result;
  }
}

sub priv_GetWorkspaceByName {
  my $self = shift @_;
  my $name = shift @_;

  $self->{GetWorkspaceByName} =
    $self->{soap_priv}->GetWorkspaceByName(
      $self->{auth_header},
	  SOAP::Data->name('workspaceName'=>$name)->type('s:string')
	);

  if ( $self->{GetWorkspaceByName}->fault ) {
    $self->_fault( $self->{GetWorkspaceByName} );
    return $self->{GetWorkspaceByName}->fault;
  } else {
    return $self->{GetWorkspaceByName}->result;
  }
}

sub priv_LibraryCloneToWorkspace {
  my $self            = shift @_;
  my $libraryid       = shift @_;
  my $destworkspaceid = shift @_;
  my $isnew           = shift @_;
  my $newname         = shift @_;
  my $description     = shift @_;

  my $machines        = shift @_;
  my $storage         = shift @_;

  my $existingconfid  = shift @_;
  my $isfullclone     = shift @_;
  my $storagelease    = shift @_;

  $isnew = 'false' unless $isnew =~ /^true$/i;
  $isfullclone = 'false' unless $isfullclone =~ /^true$/i;

  my @machine_data;

  for my $machine (@$machines) {
    my @elements;
    for my $element ( keys %$machine ) {
      push @elements, SOAP::Data->name( $element, $machine->{$element} );
    }
    push @machine_data, SOAP::Data->name('machine' => \SOAP::Data->value(@elements));
  }

  $self->{LibraryCloneToWorkspace} =
    $self->{soap_priv}->LibraryCloneToWorkspace(
      $self->{auth_header},
      SOAP::Data->name('libraryId'                  => $libraryid       )->type('s:int'),
      SOAP::Data->name('destWorkspaceId'            => $destworkspaceid )->type('s:int'),
      SOAP::Data->name('isNewConfiguration'         => $isnew           )->type('s:boolean'),
      SOAP::Data->name('newConfigName'              => $newname         )->type('s:string'),
      SOAP::Data->name('description'                => $description     )->type('s:string'),
	  SOAP::Data->name('copyData' => \SOAP::Data->value(
        SOAP::Data->name('VMCopyData' => \SOAP::Data->value(
          @machine_data,
          SOAP::Data->name('storageServerName' => $storage )->type('s:string')
        ))
	  )),
      ( $existingconfid ? SOAP::Data->name('existingConfigId'           => $existingconfid  )->type('s:int') : '' ),
      SOAP::Data->name('isFullClone'                => $isfullclone     )->type('s:boolean'),
	  SOAP::Data->name('storageLeaseInMilliseconds' => $storagelease    )->type('s:long')
    );

  if ( $self->{LibraryCloneToWorkspace}->fault ) {
    $self->_fault( $self->{LibraryCloneToWorkspace} );
    return $self->{LibraryCloneToWorkspace}->fault;
  } else {
    return $self->{LibraryCloneToWorkspace}->result;
  }
}

sub priv_ListNetworks {
  my $self = shift @_;
  $self->{ListNetworks} = $self->{soap_priv}->ListNetworks( $self->{auth_header} );

  if ( $self->{ListNetworks}->fault ) {
    $self->_fault( $self->{ListNetworks} );
    return $self->{ListNetworks}->fault;
  }

  my $ret = $self->{ListNetworks}->result;

  my $array = $ret ? [ $ret ] : [ ];
  $array = [ $ret->{Network} ] if ref $ret and ref $ret->{Network} eq 'HASH';
  $array =   $ret->{Network}   if ref $ret and ref $ret->{Network} eq 'ARRAY';

  return wantarray ? @$array : $array;
}

sub priv_ListTemplates {
  my $self = shift @_;
  $self->{ListTemplates} = $self->{soap_priv}->ListTemplates( $self->{auth_header} );

  if ( $self->{ListTemplates}->fault ) {
    $self->_fault( $self->{ListTemplates} );
    return $self->{ListTemplates}->fault;
  }

  my $ret = $self->{ListTemplates}->result;

  my $array = $ret ? [ $ret ] : [ ];
  $array = [ $ret->{Template} ] if ref $ret and ref $ret->{Template} eq 'HASH';
  $array =   $ret->{Template}   if ref $ret and ref $ret->{Template} eq 'ARRAY';

  return wantarray ? @$array : $array;
}

sub priv_ListTransportNetworksInCurrentOrg {
  my $self = shift @_;
  $self->{ListTransportNetworksInCurrentOrg} = $self->{soap_priv}->ListTransportNetworksInCurrentOrg( $self->{auth_header} );

  if ( $self->{ListTransportNetworksInCurrentOrg}->fault ) {
    $self->_fault( $self->{ListTransportNetworksInCurrentOrg} );
    return $self->{ListTransportNetworksInCurrentOrg}->fault;
  }

  return $self->{ListTransportNetworksInCurrentOrg}->result;

  #my $ret = $self->{ListTransportNetworksInCurrentOrg}->result;

  #my $array = $ret ? [ $ret ] : [ ];
  #$array = [ $ret->{Network} ] if ref $ret and ref $ret->{Network} eq 'HASH';
  #$array =   $ret->{Network}   if ref $ret and ref $ret->{Network} eq 'ARRAY';

  #return wantarray ? @$array : $array;
}

sub priv_ListUsers {
  my $self = shift @_;
  $self->{ListUsers} = $self->{soap_priv}->ListUsers( $self->{auth_header} );

  if ( $self->{ListUsers}->fault ) {
    $self->_fault( $self->{ListUsers} );
    return $self->{ListUsers}->fault;
  }

  my $ret = $self->{ListUsers}->result;

  my $array = $ret ? [ $ret ] : [ ];
  $array = [ $ret->{User} ] if ref $ret and ref $ret->{User} eq 'HASH';
  $array =   $ret->{User}   if ref $ret and ref $ret->{User} eq 'ARRAY';

  return wantarray ? @$array : $array;
}

sub priv_MachineUpgradeVirtualHardware {
  my $self = shift @_;
  my $id   = shift @_;
  $self->{MachineUpgradeVirtualHardware} =
    $self->{soap_priv}->MachineUpgradeVirtualHardware(
      $self->{auth_header},
      SOAP::Data->name('machineId'=>$id)->type('s:int'),
    );

  if ( $self->{MachineUpgradeVirtualHardware}->fault ) {
    $self->_fault( $self->{MachineUpgradeVirtualHardware} );
    return $self->{MachineUpgradeVirtualHardware}->fault;
  } else {
    return $self->{MachineUpgradeVirtualHardware}->result;
  }
}

sub priv_NetworkInterfaceCreate {
  my $self   = shift @_;
  my $vmid   = shift @_;
  my $netid  = shift @_;
  my $iptype = shift @_;
  my $ipaddr = shift @_;

  $self->{NetworkInterfaceCreate} =
    $self->{soap_priv}->NetworkInterfaceCreate(
      $self->{auth_header},
	  SOAP::Data->name('vmID'             =>$vmid   )->type('s:int'),
	  SOAP::Data->name('networkID'        =>$netid  )->type('s:int'),
	  SOAP::Data->name('IPAssignmentType' =>$iptype )->type('s:string'),
	  SOAP::Data->name('IPAddress'        =>$ipaddr )->type('s:string'),
	);

  if ( $self->{NetworkInterfaceCreate}->fault ) {
    $self->_fault( $self->{NetworkInterfaceCreate} );
    return $self->{NetworkInterfaceCreate}->fault;
  } else {
    return $self->{NetworkInterfaceCreate}->result;
  }
}

sub priv_NetworkInterfaceDelete {
  my $self  = shift @_;
  my $vmid  = shift @_;
  my $nicid = shift @_;

  $self->{NetworkInterfaceDelete} =
    $self->{soap_priv}->NetworkInterfaceDelete(
      $self->{auth_header},
	  SOAP::Data->name('vmID'  => $vmid  )->type('s:int'),
	  SOAP::Data->name('nicID' => $nicid )->type('s:int'),
	);

  if ( $self->{NetworkInterfaceDelete}->fault ) {
    $self->_fault( $self->{NetworkInterfaceDelete} );
    return $self->{NetworkInterfaceDelete}->fault;
  } else {
    return $self->{NetworkInterfaceDelete}->result;
  }
}

sub priv_NetworkInterfaceModify { ### INCOMPLETE
  my $self   = shift @_;
  my $vmid   = shift @_;
  my $netid  = shift @_;
  my $info   = shift @_;

  $self->{NetworkInterfaceModify} =
    $self->{soap_priv}->NetworkInterfaceModify(
      $self->{auth_header},
	  #SOAP::Data->name('vmID'             =>$vmid   )->type('s:int'),
	  #SOAP::Data->name('networkID'        =>$netid  )->type('s:int'),
	  #SOAP::Data->name('IPAssignmentType' =>$iptype )->type('s:string'),
	  #SOAP::Data->name('IPAddress'        =>$ipaddr )->type('s:string'),
	);

  if ( $self->{NetworkInterfaceModify}->fault ) {
    $self->_fault( $self->{NetworkInterfaceModify} );
    return $self->{NetworkInterfaceModify}->fault;
  } else {
    return $self->{NetworkInterfaceModify}->result;
  }
}

sub priv_StorageServerVMFSFindByName {
  my $self      = shift @_;
  my $storeName = shift @_;

  $self->{StorageServerVMFSFindByName} =
    $self->{soap_priv}->StorageServerVMFSFindByName(
					       $self->{auth_header},
					       SOAP::Data->name('name' => $storeName)->type(''));

  if ( $self->{StorageServerVMFSFindByName}->fault ) {
    $self->_fault( $self->{StorageServerVMFSFindByName} );
    return $self->{StorageServerVMFSFindByName}->fault;
  } else {
    #return $self->{StorageServerVMFSFindByName}->result;
	my $result = $self->{StorageServerVMFSFindByName}->result;
	my $datastore = $$result{"label"}; # Need to be fixed. Currently in use?
	return $datastore;
  }
}

sub priv_TemplateChangeOwner {
  my $self = shift @_;
  my $temp = shift @_;
  my $own  = shift @_;

  $self->{TemplateChangeOwner} =
    $self->{soap_priv}->TemplateChangeOwner(
      $self->{auth_header},
      SOAP::Data->name('templateId' => $temp )->type('s:int'),
      SOAP::Data->name('newOwnerId' => $own  )->type('s:int'),
    );

  if ( $self->{TemplateChangeOwner}->fault ) {
    $self->_fault( $self->{TemplateChangeOwner} );
    return $self->{TemplateChangeOwner}->fault;
  } else {
    return $self->{TemplateChangeOwner}->result;
  }
}

sub priv_TemplateExport {
  my $self = shift @_;
  my $temp = shift @_;
  my $unc  = shift @_;
  my $user = shift @_;
  my $pass = shift @_;

  $self->{TemplateExport} =
    $self->{soap_priv}->TemplateExport(
      $self->{auth_header},
	  SOAP::Data->name('template_id' =>$temp)->type('s:int'),
	  SOAP::Data->name('UNCPath'     =>$unc )->type('s:string'),
	  SOAP::Data->name('username'    =>$user)->type('s:string'),
	  SOAP::Data->name('password'    =>$pass)->type('s:string'),
	);

  if ( $self->{TemplateExport}->fault ) {
    $self->_fault( $self->{TemplateExport} );
    return $self->{TemplateExport}->fault;
  } else {
    return $self->{TemplateExport}->result;
  }
}

sub priv_TemplateImport {
  my $self = shift @_;
  my $unc  = shift @_;
  my $user = shift @_;
  my $pass = shift @_;
  my $name = shift @_;
  my $desc = shift @_;
  my $stor = shift @_;

  my $list = shift @_;

  # Virtualization Technology: 6 (VMware ESX Server 3.0)
  # This comes from the Private API documentation
  my $vsid = 6;

  my $paramlist = \SOAP::Data->value(

	 #SOAP::Data->name('VMParameter' => \SOAP::Data->value(
	 #  SOAP::Data->name('parameter_name' => 'VCPUCOUNT')->type(''),
     #  SOAP::Data->name('parameter_value' => '4')->type('')
     # )),

     #SOAP::Data->name('VMParameter' => \SOAP::Data->value(
     #  SOAP::Data->name('parameter_name' => 'GUESTOS')->type(''),
     #  SOAP::Data->name('parameter_value' => 'RHEL4')->type('')
     #)),

	 SOAP::Data->name('VMParameter' => \SOAP::Data->value(
       SOAP::Data->name('parameter_name' => 'HW_VERSION')->type(''),
       SOAP::Data->name('parameter_value' => $7)->type('')
     )),

  );

  $self->{TemplateImport} =
    $self->{soap_priv}->TemplateImport(
      $self->{auth_header},
	  SOAP::Data->name('UNCPath'     =>$unc )->type('s:string'),
	  SOAP::Data->name('dirUsername' =>$user)->type('s:string'),
	  SOAP::Data->name('dirPassword' =>$pass)->type('s:string'),
	  SOAP::Data->name('name'        =>$name)->type('s:string'),
	  SOAP::Data->name('description' =>$desc)->type('s:string'),
	  SOAP::Data->name('VSTypeID'   =>$vsid)->type('s:int'),
	  SOAP::Data->name('storageServerName' => $stor)->type('s:string'),
	  SOAP::Data->name('parameterList' => $paramlist )
	);

  if ( $self->{TemplateImport}->fault ) {
    $self->_fault( $self->{TemplateImport} );
    return $self->{TemplateImport}->fault;
  } else {
    return $self->{TemplateImport}->result;
  }
}

sub priv_TemplateImportFromSMB {
  my $self        = shift @_;
  my $UNCPath     = shift @_;
  my $username    = shift @_;
  my $password    = shift @_;
  my $delete      = shift @_;
  my $description = shift @_;
  my $destStore   = shift @_;
  my $destName    = shift @_;
  my $destDesc    = shift @_;

 $self->{TemplateImportFromSMB} =
   $self->{soap_priv}->TemplateImportFromSMB(
     $self->{auth_header},

     SOAP::Data->name('name' => $destName)->type(''),
     SOAP::Data->name('VSTypeID' => $delete)->type(''),
     SOAP::Data->name('description' => $description)->type(''),
     SOAP::Data->name('storageServerName' => $destStore)->type(''),

     SOAP::Data->name('UNCPath' => $UNCPath)->type(''),
     SOAP::Data->name('dirUsername' => $username)->type(''),
     SOAP::Data->name('dirPassword' => $password)->type(''),

     SOAP::Data->name('performGuestCustomization' => "1")->type(''),

     SOAP::Data->name('parameterList' =>
       \SOAP::Data->value(

	 SOAP::Data->name('VMParameter' =>
	 \SOAP::Data->value(
	  SOAP::Data->name('parameter_name' => 'VCPUCOUNT')->type(''),
         SOAP::Data->name('parameter_value' => '4')->type(''))),

	 SOAP::Data->name('VMParameter' =>
	 \SOAP::Data->value(
	  SOAP::Data->name('parameter_name' => 'GUESTOS')->type(''),
         SOAP::Data->name('parameter_value' => 'RHEL4')->type(''))),

	 SOAP::Data->name('VMParameter' =>
	 \SOAP::Data->value(
	  SOAP::Data->name('parameter_name' => 'HW_VERSION')->type(''),
         SOAP::Data->name('parameter_value' => $7)->type(''))),


			  ))
				 );

  $self->_fault( $self->{TemplateImportFromSMB} ) if $self->{TemplateImportFromSMB}->fault;
  return $self->{TemplateImportFromSMB}->result;
}

sub priv_TemplatePerformAction {
  my $self        = shift @_;
  my $template_id = shift @_;
  my $action      = shift @_;

   $self->{TemplatePerformAction} =
     $self->{soap_priv}->TemplatePerformAction( $self->{auth_header},
                SOAP::Data->name('template_id'     => $template_id )->type('s:int'),
                SOAP::Data->name('action'          => $action      )->type('s:int') );

   if ($self->{TemplatePerformAction}->fault) {
     $self->_fault( $self->{TemplatePerformAction} );
     return $self->{TemplatePerformAction}->fault;
   }

   return $self->{TemplatePerformAction}->result;
}

sub priv_WorkspaceCreate {
  my $self        = shift @_;
  my $name        = shift @_;
  my $ismain      = shift @_;
  my $description = shift @_;
  my $storedquota = shift @_;
  my $deployquota = shift @_;

  $self->{WorkspaceCreate} =
    $self->{soap_priv}->WorkspaceCreate( $self->{auth_header},
	SOAP::Data->name('name'            => $name        )->type('s:string'),
	SOAP::Data->name('isMain'          => $ismain      )->type('s:bool'),
	SOAP::Data->name('description'     => $description )->type('s:string'),
	SOAP::Data->name('storedVMQuota'   => $storedquota )->type('s:int'),
	SOAP::Data->name('deployedVMQuota' => $deployquota )->type('s:int') );

  $self->_fault( $self->{WorkspaceCreate} ) if $self->{WorkspaceCreate}->fault;
  return $self->{WorkspaceCreate}->result;
}

1;

__END__

=head1 NAME

VMware::API::LabManager - The VMware LabManager API

=head1 SYNOPSIS

This module has been developed against VMware vCenter Lab Manager 4.0 (4.0.1.1233)

Code to checkout, deploy, undeploy and delete a configuration:

 	use VMware::API::LabManager;

    my $labman = new VMware::API::LabManager ( $username, $password, $server, $orgname, $workspace );

 	# Get the id of the config you are going to check out
 	my $config = $labman->GetSingleConfigurationByName("myConfigName");

 	# Checkout the config
 	my $checked_out_config_id  = $labman->ConfigurationCheckout($lib_config_id[0],"NEW_WORKSPACE_NAME");

 	# Deploy the config
 	my $ret = $labman->ConfigurationDeploy($checked_out_config_id,4); # The 4 is for the fencemode

 	# Undeploy the config
 	my $ret = $labman->ConfigurationUndeploy($chkd_out_id);

 	# Delete the config
 	my $ret = $labman->ConfigurationDelete($chkd_out_id); # You really should be sure before doing this :)

	# Check for last SOAP error
    print $labman->getLastSOAPError();

=head1 DESCRIPTION

This module provides a Perl interface to VMware's Labmanager SOAP interface. It
has a one-to-one mapping for most of the commands exposed in the external API as
well as a many commands exposed in the internal API.

Using this module you can checkout, deploy, undeploy and delete configurations.
You can also get lists of configurations and guest information as well.

Lab Manager is a product created by VMware that provides development and test
teams with a virtual environment to deploy systems and networks of systems in a
short period of a time.

=head1 RETURNED VALUES

Many of the methods return hash references or arrays of hash references that
contain information about a specific "object" or concept on the Lab Manager
server. This is a rough analog to the Managed Object Reference structure of
the VIPERL SDK without the generic interface for retireval.

Below are some of the commoned return value types and example values.

=head2 Config

  Need to add this example.

=head2 Machine

          {
            'configID' => '97',
            'status' => '0',
            'OwnerFullName' => 'Jones, Bob',
            'name' => 'VM0',
            'description' => '',
            'isDeployed' => 'false',
            'memory' => '16',
            'DatastoreNameResidesOn' => 'labmgr_01',
            'id' => '116'
          }


=head2 Network Interface (NIC)

          {
            'isConnected' => 'true',
            'macAddress' => '00:50:56:0a:00:aa',
            'networkId' => '63',
            'nicId' => '221',
            'vmxSlot' => '0',
            'ipAddressingMode' => 'DHCP',
            'resetMac' => 'false'
          }

=head2 Organization

  Need to add this example.

=head2 Workspace

The following represents a workspace called "Main" that has no configurations
or resource pools.

          {
            'Configurations' => '',
            'Id' => '8',
            'ResourcePools' => '',
            'BucketType' => '3',
            'StoredVMQuota' => '0',
            'DeployedVMQuota' => '0',
            'Name' => 'Main',
            'Description' => '',
            'IsEnabled' => 'false'
          };

When a workspace is associated with a given resource pool or contains a configuration,
references to those objects are returned as well.

NB: If only a single configuration or resource pool is returned, it is a direct hash
reference, as below. Otherwise, if there are multiple, an arrayref of hash references
will be present in that location.

          {
            'Configurations' => {
                                'Configuration' => {
                                                   'owner' => 'bjones',
                                                   'mustBeFenced' => 'NotSpecified',
                                                   'autoDeleteDateTime' => '9999-12-31T23:59:59.9999999',
                                                   'bucketName' => 'Main',
                                                   'name' => 'migration-test02',
                                                   'autoDeleteInMilliSeconds' => '0',
                                                   'description' => '',
                                                   'isDeployed' => 'false',
                                                   'fenceMode' => '0',
                                                   'id' => '95',
                                                   'type' => '1',
                                                   'isPublic' => 'false',
                                                   'dateCreated' => '2010-08-24T14:22:25.437'
                                                 }
                              },
            'Id' => '10',
            'ResourcePools' => {
                               'ResourcePool' => {
                                                 'ID' => '1',
                                                 'isBlackListed' => 'false',
                                                 'name' => 'DevPool1',
                                                 'rpValRefFullID' => 'resgroup-2411',
                                                 'path' => 'DC2/LAB-MGR/PAI',
                                                 'description' => '',
                                                 'isEnabled' => 'true',
                                                 'rpValRefShortID' => 'resgroup-2411'
                                               }
                             },
            'BucketType' => '3',
            'StoredVMQuota' => '0',
            'DeployedVMQuota' => '0',
            'Name' => 'Main',
            'Description' => '',
            'IsEnabled' => 'true'
          };

=head2 Network

          {
            'VlanID' => '583',
            'IsAddressingModeLocked' => 'false',
            'NetType' => 'Template',
            'IsPhysical' => 'true',
            'DnsSuffix' => '',
            'parentNetId' => '0',
            'Netmask' => '',
            'NetworkValref' => 'LM-DHCP-4LM10',
            'IsDeployFencedLocked' => 'true',
            'Gateway' => '',
            'IsNone' => 'false',
            'userId' => '0',
            'Dns2' => '',
            'DeployFencedMode' => 'Nonfenced',
            'Dns1' => '',
            'NetID' => '4',
            'DeployFenced' => 'false',
            'IPAddressingMode' => 'DHCP',
            'Description' => 'dhcp IP Pool',
            'Name' => 'LM-DHCP'
          },

=head2 User

          {
            'is_enabled' => 'true',
            'email_address' => 'bjones@company.com',
            'userId' => '3',
            'name' => 'bjones',
            'cache_mode' => '0',
            'full_name' => 'Jones, Bob',
            'fence_mode' => '0',
            'is_ldap' => 'true',
            'is_admin' => 'true',
            'stored_vm_quota' => '0',
            'deployed_vm_quota' => '0'
          },

=head1 EXAMPLE SCRIPTS

Included in the distribution of this module are several example scripts. Hopefully
they provide an example of the usage of the Lab Manager API. All scripts have
their own POD and accept command line parameters in a similar way to the VIPERL
SDK utilities and vghetto scripts.

    conditions.pl - An example displaying an objects conditions.
    delete-all.pl - Deletes every template and configuration in a given LabMan installation
    hwupgrade.pl - Performs an upgrade on the virtual hardware of the specified configuration
    list-machines.pl - Lists all machines within the specified configuration
    list-networks.pl - Lists all the networks available to the specified user.
    list-organization.pl - Lists all the organizations available to the specified user.
    list-templates.pl - Lists all the template objects available to the specified user.
    list-users.pl - Lists all information on users in the Lab Manager system.
    list-workspaces.pl - Lists all the workspaces available to the specified user.
    move.pl - An example script of moving a config between workspaces.

=head1 PERL MODULE METHODS

These methods are not direct API calls. They represent the methods that create
or  module as a "wrapper" for the Labmanager API.

=head2 new

This method creates the Labmanager object.

B<Arguments>

=over

=item * username

=item * password

=item * hostname

=item * organization

=item * workspace

=back

=head2 config

  $labman->config( debug => 1 );

=over 4

=item debug - 1 to turn on debugging. 0 for none. Defaults to 0.

=item die_on_fault - 1 to cause the program to die verbosely on a soap fault. 0 for the fault object to be returned on the call and for die() to not be called. Defaults to 1. If you choose not to die_on_fault (for example, if you are writing a CGI) you will want to check all return objects to see if they are fault objects or not.

=item ssl_timeout - seconds to wait for timeout. Defaults to 3600. (1hr) This is how long a transaction response will be waited for once submitted. For slow storage systems and full clones, you may want to up this higher. If you find yourself setting this to more than 6 hours, your Lab Manager setup is probably not in the best shape.

=item hostname, orgname, workspace, username and password - All of these values can be changed from the original settings on new(). This is handing for performing multiple transactions across organizations.

=back

=head2 getLastSOAPError

Returns and clears the last error reported by SOAP service.

=head1 PUBLIC API METHODS

This methods provide a direct mapping to the public API calls for Labmanager.

=head2 ConfigurationCapture

This method captures a Workspace configuration and saves into the library.

B<Arguments>

=over

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * New library name - The name that you want the captured config to be.

=back

B<Returns>

ID on success. Fault object on fault.

=head2 ConfigurationCheckout

This method checks out a configuration from the configuration library and moves it to the Workspace under a different name. It returns the ID of the checked out configuration in the WorkSpace.

WARNING: If you get the following SOAP Error:

=over 4

Expecting single row, got multiple rows for: SELECT * FROM BucketWithParent WHERE name = N'Main' ---> Expecting single row, got multiple rows for: SELECT * FROM BucketWithParent WHERE name = N'Main'

=back

This is because there are multiple workspaces named "Main", in different organizations. Apparently this API call doesn't limit the check for workspace name against the organization you authenticated with.

A workaround is to make sure you use this call on a uniquely name workspace or to use a private call (such as priv_LibraryCloneToWorkspace) instead.

B<Arguments>

=over

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * New workspace name - The name you want the new config in the workspace to be.

=back

=head2 ConfigurationClone

This method clones a Workspace configuration, saves it in a storage server, and makes it visible in the Workspace under the new name. Arguements:

B<Arguments>

=over

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * New workspace name - The name of the clone that is being created.

=back

=head2 ConfigurationDelete

This method deletes a configuration from the Workspace. You cannot delete a deployed configuration. Doesn't return anything. Arguments:

B<Arguments>

=over

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=back

=head2 ConfigurationDeploy

This method allows you to deploy an undeployed configuration which resides in the Workspace.

B<Arguments>

=over

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * Fencemode - 1 = not fenced; 2 = block traffic in and out; 3 = allow out ; 4 allow in and out

=back

=head2 ConfigurationPerformAction

This method performs one of the following configuration actions as indicated by the action identifier:

  1 : Power On. Turns on a configuration.
  2 : Power Off. Turns off a configuration. Nothing is saved.
  3 : Suspend. Freezes the CPU and state of a configuration.
  4 : Resume. Resumes a suspended configuration.
  5 : Reset. Reboots a configuration.
  6 : Snapshot. Saves a configuration state at a specific point in time.

B<Arguments>

=over

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * Action - use a numerical value from the list above.

=back

=head2 ConfigurationSetPublicPrivate

Use this call to set the state of a configuration to public or private. If the configuration state is public, others are able to access this configuration. If the configuration is private, only its owner can view it.

B<Arguments>

=over

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * True or False (boolean) - Accepts true | false | 1 | 0

=back

=head2 ConfigurationUndeploy

Undeploys a configuration in the Workspace. Nothing is returned.

B<Arguments>

=over

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=back

=head2 GetConfiguration

This method retruns a reference to a Configuration matching the configuration ID passed.

B<Arguments>

=over

=item * Config ID

=back

B<Returns>

A hashref to a configuration. Example keys: mustBeFenced, autoDeleteDateTime, bucketName,
name, autoDeleteInMilliSeconds, description, isDeployed, fenceMode, id, type, isPublic,
dateCreated

=head2 GetConfigurationByName

This method retruns a reference to a Configuration matching the configuration ID passed.

B<Arguments>

=over

=item * Config Name

=back

B<Returns>

An array of configurations matching this name. Example keys: mustBeFenced, autoDeleteDateTime, bucketName,
name, autoDeleteInMilliSeconds, description, isDeployed, fenceMode, id, type, isPublic,
dateCreated

=head2 GetMachine

This call takes the numeric identifier of a machine and returns its corresponding Machine object.

B<Arguments>

=over

=item * Machine ID - Use GetMachineByName to retrieve this

=back

B<Returns>

A hashref to a machine. Example elements: configID, macAddress, status, OwnerFullName,
name, description, isDeployed, internalIP, memory, DatastoreNameResidesOn, id

=head2 GetMachineByName

This call takes a configuration identifier and a machine name and returns the matching Machine object.

B<Arguments>

=over

=item * Configuration ID - Config where Guest VM lives

=item * Name of guest

=back

B<Returns>

A hashref to a machine. Example elements: configID, macAddress, status, OwnerFullName,
name, description, isDeployed, internalIP, memory, DatastoreNameResidesOn, id

=head2 GetSingleConfigurationByName

This call takes a configuration name, searches for it in both the configuration library and workspace and returns its corresponding Configuration object.

B<Arguments>

=over

=item * Configuration name

=back

B<Returns>

A hashref to a configuration. Example elements: mustBeFenced, autoDeleteDateTime,
bucketName (aka workspace), name, autoDeleteInMilliSeconds, description, isDeployed,
fenceMode, id, type, isPublic, dateCreated

=head2 ListConfigurations($type)

This method returns an array or arrayref of configuration objects for the current
workspace or library.

It depends on configuration type requested.

B<Arguments>

=over

=item * configurationType (Configuration Type must be either 1 for Workspace or 2 for Library)

=back

=head2 ListMachines

This method returns an array of type Machine. The method returns one Machine object for each virtual machine in a configuration.

B<Arguments>

=over

=item * Configuration ID

=back

=head2 LiveLink

This method allows you to create a LiveLink URL to a library configuration. Responds with a livelink URL

B<Arguments>

=over

=item * config Name

=back

=head2 MachinePerformAction

This method performs one of the following machine actions as indicated by the action identifier:

=over

=item * 1  Power on. Turns on a machine.

=item * 2  Power off. Turns off a machine. Nothing is saved.

=item * 3  Suspend. Freezes a machine CPU and state.

=item * 4  Resume. Resumes a suspended machine.

=item * 5  Reset. Reboots a machine.

=item * 6  Snapshot. Save a machine state at a specific point in time.

=item * 7  Revert. Returns a machine to a snapshot state.

=item * 8  Shutdown Guest. Shuts down a machine before turning off.

=item * 9 for Consolidate

=item * 10 for Eject CD

=item * 11 for Eject Floppy

=item * 12 for Deploy

=item * 13 for Undeploy

=item * 14 for Force Undeploy

=back

B<Arguments>

=over

=item * Machine ID

=item * Action (use numeral from list aboive)

=back

=head1 INTERNAL API METHODS

This methods provide a direct mapping to internal API calls for Labmanager.
These calls are not publically supported by VMware and may change between
releases of the Labmanager product.

=cut

=head2 priv_ConfigurationAddMachineEx

B<Arguments>

=over

=item * id - ID of the configuration.

=item * template_id - ID of the template to be used.

=item * name - The name for the virtual machine.

=item * desc - Description for the virtual machine.

=item * boot_seq - Boot sequence order (0 by default).

=item * boot_delay - Boot delay (0 by default).

=item * netInfo - Array of network information for the virtual machine.

=back

=head2 priv_ConfigurationArchiveEx

This method captures a Workspace configuration and saves into the library.

B<Arguments>

=over

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * New library name - The name that you want the captured config to be.

=item * libraryDescription

=item * isGoldMaster

=item * storageName

=item * storageLeaseInMilliseconds

=back

B<Returns>

ID on success. Fault object on fault.

=head2 priv_ConfigurationCaptureEx

This method captures a Workspace configuration and saves into the library.

B<Arguments>

=over

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * New library name - The name that you want the captured config to be.

=item * libraryDescription

=item * isGoldMaster

=item * storageName

=item * storageLeaseInMilliseconds

=back

B<Returns>

ID on success. Fault object on fault.

NB: API docs are wrong on this one. It accepts ConfigurationId and not ConfigurationID

=head2 priv_ConfigurationChangeOwner

Changes the owner of the given config.

B<Arguments>

=over

=item * configurationId

=item * newOwnerId

=back

=head2 priv_ConfigurationCopy

This method copys a configuration to a new datastore. (Full clone)

B<Arguments>

=over

=item * sg_id

=item * name

=item * description

=item * Machines array

=item * storage location

=back

=head2 priv_ConfigurationCloneToWorkspace

This method copys a configuration to a new datastore. (Full clone)

B<Arguments>

=over

=item * destWorkspaceId

=item * isNewConfiguration

=item * newConfigName

=item * description

=item * Machines array

=item * storage location

=item * existingConfigId

=item * isFullClone

=item * storageLeaseInMilliseconds

=back

=head2 priv_ConfigurationCreateEx

Creates and empty configuration.

B<Arguments>

=over

=item * Name - The name of the configuration

=item * Description - The description of the configuration

=back

B<Returns>

ID of the configuration on success.

A fault object on fault.

=head2 priv_ConfigurationDeployEx2

This method allows you to deploy an undeployed configuration which resides in the Workspace to a Distributed Virtual Switch. Arguments:

B<Arguments>

=over

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * Network ID

=item * Fencemode(string) - Choices: Nonfenced or FenceBlockInAndOut or FenceAllowOutOnly or FenceAllowInAndOut

=back

=head2 priv_ConfigurationExport

B<Arguments>

=over

=item * configId

=item * uncPath

=item * username

=item * password

=back

=head2 priv_ConfigurationGetNetworks

Returns an array of physical or virtual network IDs for the specified configuration.

B<Arguments>

=over 4

=item * configID

=item * physical - true/false

=back

This method returns an array of type Network.

=head2 priv_ConfigurationImport

B<Arguments>

=over

=item * UNCPath

=item * dirUsername

=item * dirPassword

=item * name

=item * description

=item * storageName

=back

=head2 priv_ConfigurationMove

B<Arguments>

=over

=item * configIdToMove

=item * destinationWorkspaceId

=item * isNewConfiguration

=item * newConfigName

=item * newConfigDescription

=item * storageLeaseInMilliseconds

=item * existingConfigId

=item * vmIds

=item * deleteOriginalConfig

=back

=head2 priv_GetAllWorkspaces

B<Arguments>

=over

=item NONE

=back

B<Arguments>

Returns an array of workspace objects.

=head2 priv_GetNetworkInfo

Returns the Network information for a specific VM.

B<Arguments>

=over

=item * vmID - VM id number

=back

B<Returns>

An array of Network references.

=head2 priv_GetObjectConditions

B<Arguments>

=over

=item * objectType - Integer representing the object type:

  VM = 1
  MANAGED_SERVER = 2
  RESOURCE_POOL = 3
  CONFIGURATION = 4

=item * objectID - Object id number

=back

=head2 priv_GetOrganization

B<Arguments>

=over

=item * organizationId

=back

B<Returns>

Organization object

=head2 priv_GetOrganizations

B<Arguments>

=over

=item NONE

=back

B<Arguments>

Returns an array of organization refs.

=head2 priv_GetOrganizationByName

B<Arguments>

=over

=item * organizationName

=back

=head2 priv_GetOrganizationWorkspaces

B<Arguments>

=over

=item * organizationId

=back

B<Returns>

An array of Workspace objects that are in the given organizations.

=head2 priv_GetTemplate

B<Arguments>

=over

=item * template id

=back

B<Returns>

Template object.

=head2 priv_GetUser

B<Arguments>

=over

=item * userName

=back

B<Returns>

User object.

=head2 priv_GetWorkspaceByName

B<Arguments>

=over

=item * string

=back

=head2 priv_LibraryCloneToWorkspace

=over

=item * libraryId

=item * destWorkspaceId

=item * isNewConfiguration

=item * newConfigName

=item * description

=item * copyData

=item * existingConfigId

=item * isFullClone

=item * storageLeaseInMilliseconds

=back

=head2 priv_ListNetworks

This method returns an array of type Network. The method returns one Network object for each network configured.

=head2 priv_ListTemplates

This method returns an array of type Machine. The method returns one Machine object for each virtual machine in a configuration.

=head2 priv_ListTransportNetworksInCurrentOrg

This method returns an array of type TransportNetwork. The method returns one Network object for each network configured.

=head2 priv_ListUsers

This method returns an array of type Users. The method returns one User object for
each User imported into LabMan.

=head2 priv_MachineUpgradeVirtualHardware

B<Arguments>

=over

=item * machineId - machine id number

=back

=head2 priv_NetworkInterfaceCreate

B<Arguments>

=over

=item * vmID - VM id number

=item * networkID

=item * IPAssignmentType

=item * IPAddress

=back

=head2 priv_NetworkInterfaceDelete

=over

=item * vmID - VM id number

=item * nicID

=back

=head2 priv_NetworkInterfaceModify

B<Arguments>

=over

=item * vmID - VM id number

=item * info -

=back

=head2 priv_StorageServerVMFSFindByName

=over

=item * Storename

=back

=head2 priv_TemplateChangeOwner

Changes the owner of the given template.

B<Arguments>

=over

=item * templateId

=item * newOwnerId

=back

=head2 priv_TemplateExport

Exports a template out to a UNC path for later import.

B<Arguments>

=over

=item * template_id

=item * UNCPath

=item * username

=item * password

=back

=head2 priv_TemplateImport

B<Arguments>

=over

=item * UNCPath

=item * dirUsername

=item * dirPassword

=item * name

=item * description

=item * storageName

=item * parameterList

=back

=head2 priv_TemplateImportFromSMB

B<Arguments>

=over

=item * UNCpath

=item * username

=item * password

=item * delete

=item * description

=item * destStore

=item * destName

=item * destDesc

=back

=head2 priv_TemplatePerformAction

B<Arguments>

=over

=item * Template ID

=item * Action

The action is a number representing any of the following:

  1 for Deploy
  2 for Undeploy in Discard State
  3 for Delete
  4 for Reset
  5 for Make Shared
  6 for Make Private
  7 for Publish
  8 for Unpublish
  9 for Undeploy in Save State

=back

=head2 priv_WorkspaceCreate

B<Arguments>

=over

=item * name

=item * isMain

=item * description

=item * storedVMQuota

=item * deployedVMQuota

=back

=head1 BUGS AND LIMITATIONS

=head2 Authentication and latentcy

The API is designed by VMware to require an authentication header with every
SOAP action. This means that you are re-autneticated on each action you perform.
As stated in the VMware Lab Manager SOAP API Guide v2.4, pg 13:

  Client applications must provide valid credentials - a Lab Manager user account
  and password - with each Lab Manager Web service method call. The user account
  must have Administrator privileges on the Lab Manager Server. The Lab Manager
  Server authenticates these credentials.

If your Lab Manager is configured for remote authentication and is slow to log-in,
this means you will see a performance drop in the speed of this API. Every method
call on this module (a method call in this module representing an API SOAP method call)
will take the same amount of time it takes you to initially log into the Lab Manager
interface plus the actual processing time of the action.

This is complicated by a known issue that some complex API calls will internally
perform several actions in Lab Manager, and you might pay that authentication call
4 or 5 times as the action processes. This known issue, is slated to be resolved
on the next major release of Lab Manager.

The web interface to Lab Manager allows you to cache credentials after initial
login. The web API does not. (See above quote.) You will pay for authentication
time on all API calls.

One potential workaround is to use a local user account for API actions. Local
accounts can be created and co-exist while remote (LDAP/AD) authentication is
used. Local user accounts authenticate much quicker than other forms.

=head2 priv_ConfigurationAddMachineEx()

This call does not currently build the correct Ethernet driver information.

=head2 ConfigurationCheckout() API errors.

If you get the following SOAP Error:

=over 4

Expecting single row, got multiple rows for: SELECT * FROM BucketWithParent WHERE name = N'Main' ---> Expecting single row, got multiple rows for: SELECT * FROM BucketWithParent WHERE name = N'Main'

=back

This is because there are multiple workspaces named "Main", in different organizations. Apparently this API call doesn't limit the check for workspace name against the organization you authenticated with.

A workaround is to make sure you use this call on a uniquely name workspace or to use a private call (such as priv_LibraryCloneToWorkspace) instead.

This is a known issue with LabManager 4.

=head2 priv_ConfigurationCaptureEx()

The API documents for these calls have a typo. The parameter accepted by the SOAP call is ConfigurationId and not ConfigurationID. Reviewing the WSDL shows the correct parameters accepted by ther server.

=head1 CONFUSING ERROR CODES

By design, the textual error codes presented by this module are directly passed
from Lab Manager. They are not generated by this library.

That being said, sometimes Lab Manager does not provide the clearest error
description. Hopefully the following hints can help you save time when debugging:

=head3 "The configuration you were looking at is no longer accessible."

This means that the config ID you used references a non-existant configuration.
This is commonly caused by a mistake in what ID you are using on a given call.
(A machine id accidentally used in place of a config id, etc.)

=head3 "Server was unable to read the request. There is an error in XML document."

This bit of engrish most commonly crops up when the wrong data type is used as a
parameter in a call. A good example is using a configuration name when a
configuration ID is expected. (String vs Int causing the server to refuse the XML
document.)

=head3 "Object reference not set to an instance of an object."

This lovely gem usually pops up when a required parameter is missing in a
given SOAP call. This probably reflects a typo or capitalization error in the
underlying wrapper call. (AKA: A mistake that I made.) Let me know if you figure
out what is up. As is referenced in the BUGS AND LIMITATIONS section, the
documentation for the API is incorrect in some places. The WSDL on the server
is considered authorative and I'd check that first for resolution.

=head1 WISH LIST

If someone from VMware is reading this, and has control of the API, I would
dearly love a few changes, that might help things:

* A way to submit multiple actions, or to cache credentials for speed. See
"Authentication and latentcy" under the BUGS section.

* A way to look up a VM's vsphere name. This information is displayed in the
UI but is unavailable in the API.

* Originating template for a VM. This information is displayed in the UI but
is unavailable in the API.

* The template object should reference "owner" and not "ownerFullName." All
ownership in the rest of the API is associated with the username, which is
unique. To figure out who owns a template you have to crosswalk the full name
back to username and the full name is not guarenteed to be unique.

* The template object should list the organization it is based in. Short of
doing a list of all templates in each organization and diffing them, there is
no quick way to determine if a template belongs only to this group, or is
global and shared. (Oh, and if you do diff them for that information, a template
in global shared to only one organization looks exactly the same as a template
that exists only in one organization. So it's not a foolproof workaround.)

* LabManagerInternal.UserPerformAction()

It would be really nice if there was an list of what the action's this method
accepts. An anonymous friend in VMware did an opengrok search for me and found
these possible values in use for this call:

  1 == Enable, 2 == Disable, 3 == Delete.

Official confirmation or documentation would be very helpful.

* Consistent naming and capitalization.

  UNCPath vs uncPath
  userName vs username
  configurationId vs configurationID
  templateId vs template_id

* A way to look at the underlying ID numbers for items in the Lab Manager UI.

Boy would this make my life easier to debug issues quickly.

=head1 DEPENDENCIES

  Net::SSL
  SOAP::Lite

=head1 BUGS AND SOURCE

	Bug tracking for this module: https://rt.cpan.org/Dist/Display.html?Name=VMware-API-LabManager

	Source hosting: http://www.github.com/bennie/perl-VMware-API-LabManager

=head1 VERSION

	VMware::API::LabManager v2.11 (2015/06/08)

=head1 COPYRIGHT

    (c) 2004-2015, Phillip Pollard <bennie@cpan.org>

=head1 LICENSE

This source code is released under the "Perl Artistic License 2.0," the text of
which is included in the LICENSE file of this distribution. It may also be
reviewed here: http://opensource.org/licenses/artistic-license-2.0

=head1 AUTHORSHIP

  Phillip Pollard, <bennie@cpan.org>
  David F. Kinder, Jr, <dkinder@davidkinder.net>

=head1 CONTRIBUTIONS

  John Barker, <john@johnrbarker.com>
  Cameron Berkenpas <cberkenpas@paypal.com>

=head1 SEE ALSO

 VMware Labmanger
  http://www.vmware.com/products/labmanager/

 VMware Labmanager SOAP API Guide (External API)
  http://www.vmware.com/pdf/lm40_soap_api_guide.pdf

 VMware Labmanager 4.0 Internal API documentation
  http://communities.vmware.com/docs/DOC-10608

 VMware Lab Manager: Automated Reconfiguration of Transiently Used Infrastructure
  http://www.vmware.com/files/pdf/lm_whitepaper.pdf

=cut
