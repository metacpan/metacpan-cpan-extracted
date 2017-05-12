package LabmanSoap;
use strict;
use SOAP::Lite ( maptype => {} );
use Data::Dumper;

=head1 NAME

VMWare::LabmanSoap - access Vmware Labmanager SOAP API 

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

This module has been tested using Labmanger 4.0 (4.0.1.1233). 


Code to checkout, deploy, undeploy and delete a configuration:

 	use LabmanSoapInternal;
 	$libraryConfigName = "lib_config_name";
 
	$mySoapObj = LabmanSoapInternal->new('LM_Username','LM_Password','LM_Hostname','Organization_Name','WorkSpace_Name');

 	#Get the id of the config you are going to check out 
 	@lib_config_id = $mySoapObj->GetSingleConfigurationByName("${libraryConfigName}","id");

 	#Checkout the config
 	$checked_out_config_id  = $mySoapObj->ConfigurationCheckout($lib_config_id[0],"NEW_WORKSPACE_NAME");

 	#Deploy the config
 	$mySoapObj->ConfigurationDeploy($checked_out_config_id,4); # The 4 is for the fencemode

	#Deploy the config to DVS
	$mySoapObj->ConfigurationDeployEx2($checked_out_config_id,2); # 2 is the id of the network

 	#Undeploy the config
 	$mySoapObj->ConfigurationUndeploy($chkd_out_id);

 	#Delete the config
 	$mySoapObj->ConfigurationDelete($chkd_out_id);

	#Check for last SOAP error
	if ($mySoapObj->{'LASTERROR'}->{'detail'}->{'message'}->{'format'}) { print };

=head1 DESCRIPTION

This module provides a Perl interface to VMWare's Labmanager SOAP interface. It has a one-to-one mapping for most of the commands exposed in the external API as well as a few commands exposed in the internal API. The most useful Internal API command is ConfigurationDeployEx2 which allows you to deploy to distributed virtual switches.  

Using this module you can checkout, deploy, undeploy and delete configurations. You can also get lists of configurations and guest information as well.

Lab Manager is a product created by VMWare that provides development and test teams with a virtual environment to deploy systems and networks of systems in a short period of a time. 

=head1 METHODS

=head2 new

This method creates the Labmanager object.

=head3 Arguments

=over 4

=item * username

=item * password

=item * hostname

=item * organization

=item * workspace

=back

=cut

sub new
{
	my($class) = shift;
	my($self) = {};
	my($username) = shift;
	my($password) = shift;
	my($hostname) = shift;
	my($orgname) = shift;
	my($workspace) = shift;
	$self->{'soap'} = SOAP::Lite
		-> on_action(sub { return "http://vmware.com/labmanager/" . $_[1]; } )
		-> default_ns('http://vmware.com/labmanager')
		-> proxy('https://' . $hostname . '/LabManager/SOAP/LabManagerInternal.asmx');

	$self->{'soap'}->readable(1);
	$self->{'auth_header'} = SOAP::Header->new(
		name => 'AuthenticationHeader',
		attr => { xmlns => "http://vmware.com/labmanager" },
		value => { username => $username, password => $password, organizationname => $orgname, workspacename => $workspace  },
		);

	if ($self->{'soap'}->fault){ $self->{'LASTERROR'} = $self->{'soap'}->fault }

	bless($self, $class);
	return($self)
}

=head2 ConfigurationCapture


This method captures a Workspace configuration and saves it to a specified Lab Manager storage server with a name.  

=head3 Arguments

=over 4

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * New library name - The name that you want the captured config to be.

=back

=cut


sub ConfigurationCapture
{
	my($self) = shift;
	my($configID) = shift;
	my($newLibName) = shift;

	$self->{'ConfigurationCapture'} = 
		$self->{'soap'}->ConfigurationCapture( 
			$self->{'auth_header'}, 
			SOAP::Data->name('configurationId' => $configID )->type('s:int'),
	 		SOAP::Data->name('newLibraryName' => "${newLibName}")->type('s:string')
		 );

	if ($self->{'ConfigurationCapture'}->fault){ $self->{'LASTERROR'} = $self->{'ConfigurationCapture'}->fault }

	return $self->{'ConfigurationCapture'}->result;
}


=head2 ConfigurationCheckout

This method checks out a configuration from the configuration library and moves it to the Workspace under a different name. It returns the ID of the checked out configuration in the WorkSpace.

=head3 Arguments

=over 4

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * New workspace name - The name you want the new config in the workspace to be.

=back

=cut

sub ConfigurationCheckout
{
	my($self) = shift;
	my($configID) = shift;
   my($configName) = shift; 


	$self->{'ConfigurationCheckout'} = 
	$self->{'soap'}->ConfigurationCheckout( 
		$self->{'auth_header'}, SOAP::Data->name('configurationId' => $configID )->type('s:int'),
        SOAP::Data->name('workspaceName' => ${configName} )->type('s:string') 
		);

	if ($self->{'ConfigurationCheckout'}->fault){ $self->{'LASTERROR'} = $self->{'ConfigurationCheckout'}->fault }
   	return $self->{'ConfigurationCheckout'}->result;
}

=head2 ConfigurationClone

This method clones a Workspace configuration, saves it in a storage server, and makes it visible in the Workspace under the new name. Arguements:

=head3 Arguments

=over 4

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * New workspace name - The name of the clone that is being created.

=back

=cut

sub ConfigurationClone
{
	my($self) = shift;
	my($configID) = shift;
	my($newWSName) = shift;

	$self->{'ConfigurationClone'} =
		$self->{'soap'}->ConfigurationClone($self->{'auth_header'}, 
		SOAP::Data->name('configurationId' => $configID )->type('s:int'),
        SOAP::Data->name('newWorkspaceName' => "${newWSName}" )->type('s:string') );

	if ($self->{'ConfigurationClone'}->fault){ $self->{'LASTERROR'} = $self->{'ConfigurationClone'}->fault }
	return $self->{'ConfigurationClone'}->result;
 }

=head2 ConfigurationDelete

This method deletes a configuration from the Workspace. You cannot delete a deployed configuration. Doesn't return anything. Arguments:

=head3 Arguments

=over 4

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=back

=cut


sub ConfigurationDelete
{
	my($self) = shift;
	my($configID) = shift;

	$self->{'ConfigurationDelete'} = 
		$self->{'soap'}->ConfigurationDelete( $self->{'auth_header'}, 
		SOAP::Data->name('configurationId' => $configID)->type('s:int') );

	if ($self->{'ConfigurationDelete'}->fault){ $self->{'LASTERROR'} = $self->{'ConfigurationDelete'}->fault }
	$self->{'ConfigurationDelete'}->result ? return $self->{'ConfigurationDelete'}->result : return $self->{'LASTERROR'};
}


=head2 ConfigurationDeploy

This method allows you to deploy an undeployed configuration which resides in the Workspace.

=head3 Arguments

=over 4

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * Fencemode - 1 = not fenced; 2 = block traffic in and out; 3 = allow out ; 4 allow in and out

=back

=cut

sub ConfigurationDeploy
{
	my($self) = shift;
	my($configID) = shift;
	my($fencemode) = shift; # 1 = not fenced; 2 = block traffic in and out; 3 = allow out ; 4 allow in and out

	$self->{'ConfigurationDeploy'} = 
		$self->{'soap'}->ConfigurationDeploy( $self->{'auth_header'}, 
		SOAP::Data->name('configurationId' => $configID )->type('s:int'),
		SOAP::Data->name('isCached' => "false")->type('s:boolean'), 
		SOAP::Data->name('fenceMode' => "${fencemode}")->type('s:int') );

	if ($self->{'ConfigurationDeploy'}->fault){ $self->{'LASTERROR'} = $self->{'ConfigurationDeploy'}->fault }
	return $self->{'ConfigurationDeploy'}->result;
	
}

=head2 ConfigurationDeployEx2

This method allows you to deploy an undeployed configuration which resides in the Workspace to a Distributed Virtual Switch. Arguments:

=head3 Arguments

=over 4

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it. 

=item * Network ID

=item * Fencemode(string) - Choices: Nonfenced or FenceBlockInAndOut or FenceAllowOutOnly or FenceAllowInAndOut

=back

=cut

sub ConfigurationDeployEx2
{
   my $self = shift;
   my $configID = shift;
   my $networkId = shift;
	my $fenceMode = 'FenceAllowInAndOut';

   my $net_elem = SOAP::Data->name( 'FenceNetworkOption' => \SOAP::Data->value(
                        SOAP::Data->name('configuredNetID' => ${networkId})->type('s:int'),
                        SOAP::Data->name('DeployFenceMode'=> ${fenceMode})->type('tns:SOAPFenceMode')
                     )
                  );

   my $bridge_elem = SOAP::Data->name( 'BridgeNetworkOption' => \SOAP::Data->value(
                           SOAP::Data->name('externalNetId' => "${networkId}")->type('s:int')
                        )
                     );
  
   my @net_array;
   my @bridge_array;
   push(@net_array,$net_elem);
   push(@bridge_array,$bridge_elem);

   $self->{'ConfigurationDeployEx2'} =
      $self->{'soap'}->ConfigurationDeployEx2( $self->{'auth_header'},
      SOAP::Data->name('configurationId' => $configID )->type('s:int'),
      SOAP::Data->name('honorBootOrders' => 1)->type('s:boolean'),
      SOAP::Data->name('startAfterDeploy' => 1)->type('s:boolean'),
      SOAP::Data->name('fenceNetworkOptions' => \SOAP::Data->value( @net_array )->type('tns:ArrayOfFenceNetworkOption')),
		#Do not uncomment unless you know how to make it work:
      #SOAP::Data->name('bridgeNetworkOptions' =>\SOAP::Data->value(  @bridge_array )->type('tns:ArrayOfBridgeNetworkOption')),
      SOAP::Data->name('isCrossHost' => 1)->type('s:boolean')
      );

   if ($self->{'ConfigurationDeployEx2'}->fault){ $self->{'LASTERROR'} = $self->{'ConfigurationDeployEx2'}->fault }
   return $self->{'ConfigurationDeployEx2'}->result;

}

=head2 ConfigurationPerformAction

This method performs one of the following configuration actions as indicated by the action identifier:

=over 4

=item	1 Power On. Turns on a configuration.

=item	2 Power Off. Turns off a configuration. Nothing is saved.

=item	3 Suspend. Freezes the CPU and state of a configuration.

=item	4 Resume. Resumes a suspended configuration.

=item	5 Reset. Reboots a configuration.

=item	6 Snapshot. Saves a configuration state at a specific point in time.

=back

=head3 Arguments

=over 4

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * Action - use a numerical value from the list above.

=back

=cut

sub ConfigurationPerformAction
{
   	my($self) = shift;
   	my($configID) = shift;
	my($action) = shift; # 1-Pwr On, 2-Pwr off, 3-Suspend, 4-Resume, 5-Reset, 6-Snapshot
	$self->{'ConfigurationPerformAction'} = 
		$self->{'soap'}->ConfigurationPerformAction( $self->{'auth_header'}, 
		SOAP::Data->name('configurationId' => $configID )->type('s:int'),
		SOAP::Data->name('action' => $action )->type('s:int') );

	if ($self->{'ConfigurationPerformAction'}->fault){ $self->{'LASTERROR'} = $self->{'ConfigurationPerformAction'}->fault }
}

=head2 ConfigurationSetPublicPrivate

Use this call to set the state of a configuration to public” or private.” If the configuration state is public, others are able to access this configuration. If the configuration is private, only its owner can view it.

=head3 Arguments

=over 4

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=item * True or False (boolean) - Accepts true | false | 1 | 0

=back

=cut

sub ConfigurationSetPublicPrivate  
{

	my($self) = shift;
	my($configID) = shift;
	my($trueOrFalse) =shift;

	$self->{'ConfigurationSetPublicPrivate'} = 
		$self->{'soap'}->ConfigurationSetPublicPrivate( $self->{'auth_header'}, 
		SOAP::Data->name('configurationId' => $configID )->type('s:int'),
        SOAP::Data->name('isPublic' => $trueOrFalse)->type('s:boolean') );

	if ($self->{'ConfigurationSetPublicPrivate'}->fault){ $self->{'LASTERROR'} = $self->{'ConfigurationSetPublicPrivate'}->fault }
}

=head2 ConfigurationUndeploy

Undeploys a configuration in the Workspace. Nothing is returned.

=head3 Arguments

=over 4

=item * Configuration ID - Use the GetConfigurationByName method to retrieve this if you do not know it.

=back

=cut

sub ConfigurationUndeploy
{
	my($self) = shift;
	my($configID) = shift;

	$self->{'ConfigurationUndeploy'} = 
		$self->{'soap'}->ConfigurationUndeploy( $self->{'auth_header'}, 
		SOAP::Data->name('configurationId' => $configID )->type('s:int'));
																	
	if ($self->{'ConfigurationUndeploy'}->fault){ $self->{'LASTERROR'} = $self->{'ConfigurationUndeploy'}->fault }
}

=head2 GetConfiguration

This method prints a list of attributes of a Configuration matching the configuration ID passed. It will return an array if you specify which attributes you would like to access

=head3 Arguments

=over 4

=item * Config Name

=item * Attribute(s) (optional) - if left blank, prints out and returns an array of all attributes.

=back

=head3 Attributes

=over 4

=item * 	mustBeFenced

=item *	autoDeleteDateTime

=item * 	bucketName

=item * 	name

=item *	autoDeleteInMilliSeconds

=item * 	description

=item * 	isDeployed

=item * 	fenceMode

=item * 	id

=item * 	type

=item * 	isPublic

=item * 	dateCreated

=back

=cut


sub GetConfiguration
{
	my($self) = shift;
	my($config) = shift;
	push(my(@attribs), @_);
	my @myattribs;
		
	$self->{'GetConfiguration'} = 
		$self->{'soap'}->GetConfiguration( $self->{'auth_header'}, 
		SOAP::Data->name('id' => ${config})->type('s:int'));

	if ($self->{'GetConfiguration'}->fault){ $self->{'LASTERROR'} = $self->{'GetConfiguration'}->fault }

	my($r) = $self->{'GetConfiguration'}->result;

	if (!@attribs) #If nothing is passed to this method, print everything
	{
		foreach my $key ( keys(%$r) )
   		{
      		print "$key: $$r{$key}\n ";
				push(@myattribs,$$r{$key});
   		}
	}
	else
	{
		foreach my $key ( @attribs )
		{
			push(@myattribs,$$r{$key});
		}
		return (@myattribs);
	}
}

=head2 GetMachine

This call takes the numeric identifier of a machine and returns its corresponding Machine object.

=head3 Arguments

=over 4

=item * Machine ID - Use GetMachineByName to retrieve this

=item * Attribute(s) (optional) - if left blank, prints out and returns an array of all attributes.

=back

=head3 Attributes

=over 4

=item * configID

=item * macAddress

=item * status

=item * OwnerFullName

=item * name

=item * description

=item * isDeployed

=item * internalIP

=item * memory

=item * DatastoreNameResidesOn

=item * id

=back

=cut

sub GetMachine
{
	my($self) = shift;
   	my($config) = shift;
	push(my(@attribs), @_);
	my @myattribs;

	$self->{'GetMachine'} = 
		$self->{'soap'}->GetMachine( $self->{'auth_header'}, 
		SOAP::Data->name('machineId' => ${config})->type('s:int'));

	if ($self->{'GetMachine'}->fault){ $self->{'LASTERROR'} = $self->{'GetMachine'}->fault }
	my($r) = $self->{'GetMachine'}->result;

   	if (!@attribs) #If nothing is passed to this method, print everything
   	{
   	   foreach my $key ( keys(%$r) )
   	   {
   	      print "$key: $$r{$key}\n ";
				push(@myattribs,$$r{$key});
   	   }
   	}
   	else
   	{
   	   foreach my $key ( @attribs )
   	   {
   	      push(@myattribs,$$r{$key});
   	   }
   	   return (@myattribs);
   	}
}


=head2 GetMachineByName

This call takes a configuration identifier and a machine name and returns the matching Machine object.

=head3 Arguments

=over 4 

=item * Configuration ID - Config where Guest VM lives

=item * Name of guest

=item * Attribute(s) (optional) - if left blank, prints out and returns an array of all attributes.

=back

=head3 Attributes

=over 4

=item * configID

=item * macAddress

=item * status

=item * OwnerFullName

=item * name

=item * description

=item * isDeployed

=item * internalIP

=item * memory

=item * DatastoreNameResidesOn

=item * id

=back

=cut

sub GetMachineByName
{
	my($self) = shift;
	my($config) = shift;
	my($name) = shift;
	push(my(@attribs), @_);
	my @myattribs;
		
	$self->{'GetMachineByName'} = 
		$self->{'soap'}->GetMachineByName( $self->{'auth_header'}, 
		SOAP::Data->name('configurationId' => ${config})->type('s:int'),
		SOAP::Data->name('name' => ${name})->type('s:string'));
		
	if ($self->{'GetMachineByName'}->fault){ $self->{'LASTERROR'} = $self->{'GetMachineByName'}->fault }

	my($r) = $self->{'GetMachineByName'}->result;


	if (!@attribs) #If nothing is passed to this method, print everything
	{
		foreach my $key ( keys(%$r) )
   	{
      	print "$key: $$r{$key}\n ";
			push(@myattribs,$$r{$key});
   	}
	}
	else
	{
		foreach my $key ( @attribs )
		{
			push(@myattribs,$$r{$key});
		}
		return (@myattribs);
	}
}

=head2 GetSingleConfigurationByName

This call takes a configuration name, searches for it in both the configuration library and workspace and returns its corresponding Configuration object. Returns an array of attributes or one or more specified attributes.

=head3 Arguments

=over 4

=item * Configuration name 

=item * Attribute(s) (optional) - if left blank, prints out and returns an array of all attributes.

=back

=head3 Attributes

=over 4

=item * mustBeFenced

=item * autoDeleteDateTime

=item * bucketName  (aka workspace)

=item * name

=item * autoDeleteInMilliSeconds

=item * description

=item * isDeployed

=item * fenceMode

=item * id

=item * type

=item * isPublic

=item * dateCreated

=back

=cut


sub GetSingleConfigurationByName
{
	my($self) = shift;
	my($config) = shift;
	push(my(@attribs), @_);
	my @myattribs;
		
	$self->{'GetSingleConfigurationByName'} = 
		$self->{'soap'}->GetSingleConfigurationByName( $self->{'auth_header'}, 
		SOAP::Data->name('name' => ${config})->type('s:string'));

	if ($self->{'GetSingleConfigurationByName'}->fault){ $self->{'LASTERROR'} = $self->{'GetSingleConfigurationByName'}->fault }
		

		
	my($r) = $self->{'GetSingleConfigurationByName'}->result;
	getLastSOAPError();

	if (!@attribs) #If nothing is passed to this method, print all the info for the config
	{
		foreach my $key ( keys(%$r) )
   	{
      	print "$key: $$r{$key}\n ";
			push( @myattribs,$$r{$key});
   	}
	}
	else
	{
		foreach my $key ( @attribs )
		{
			push( @myattribs,$$r{$key});
		}
		return ( @myattribs);
	}
}

=head2 ListConfigurations

This method prints a list of Type Configuration. Depending on configuration type requested, one object is returned for each configuration in the configuration library or each configuration in the workspace. 

=head3 Arguments

=over 4

=item * configurationType (Configuration Type must be either 1 for Workspace or 2 for Library) 

=back

=cut


sub ListConfigurations
{
	my($self) = shift;
	my($configType) = shift; #1 =WorkSpace, 2=Library 
	unless($configType == 1 || $configType == 2 )
	{
		$self->{'LASTERROR'} = "Configuration Type must be either 1 for Workspace or 2 for Library";
	}
	$self->{'ListConfigurations'} = $self->{'soap'}->ListConfigurations( $self->{'auth_header'}, SOAP::Data->name('configurationType' => $configType)->type('s:int'));
	if ($self->{'ListConfigurations'}->fault){ $self->{'LASTERROR'} = $self->{'ListConfigurations'}->fault }
	my($r) = $self->{'ListConfigurations'}->result;
	my($array) = $$r{'Configuration'}; # returns a reference to an array

 	if ( $array ) {
		for (my $i=0;$i<scalar(@$array);$i++)
		{
	
			my $hash = $$array[$i]; #returns a reference to a hash
			foreach my $k (keys(%$hash))
			{
				print "\n$k: $$hash{$k}";
			} 
			print "\n*********************\n";
		}
	}
	
}

=head2 ListMachines

This method returns an array of type Machine. The method returns one Machine object for each virtual machine in a configuration.

=head3 Arguments

=over 4

=item * Configuration ID

=back

=cut


sub ListMachines # Works but Not completely. Need to test with a config with more than one VM 
{
   	my($self) = shift;
	my($config) = shift;
   	$self->{'ListMachines'} = 
		$self->{'soap'}->ListMachines( $self->{'auth_header'}, 
		SOAP::Data->name('configurationId' => $config)->type('s:int'));

	if ($self->{'ListMachines'}->fault){ $self->{'LASTERROR'} = $self->{'ListMachines'}->fault }
	
	my($r) = $self->{'ListMachines'}->result;
	#print keys %{$$r{'Machine'}};
	#print $$r{'Machine'}{'configID'};
   	my($attribs) = $$r{'Machine'}; # returns a hash


	foreach my $k (keys(%$attribs))
     {
        print "\n$k: $$attribs{$k}";
     }
     print "\n*********************\n";

	return %$attribs;
   

}

# Not Supported, but works (I believe)
sub GetConsoleAccessInfo
{
	# Attribs: ServerAddress, ServerPort,VmxLocation,Ticket
	my($self) = shift;
	my($machineId) = shift;
	push(my(@attribs), @_);
	my @myattribs;

	$self->{'GetConsoleAccessInfo'} = 
		$self->{'soap'}->GetConsoleAccessInfo( $self->{'auth_header'}, 
		SOAP::Data->name('machineId' => $machineId)->type('s:int'));

	if ($self->{'GetConsoleAccessInfo'}->fault){ $self->{'LASTERROR'} = $self->{'GetConsoleAccessInfo'}->fault }
	my($r) = $self->{'GetConsoleAccessInfo'}->result;
	my($attribs) = $r; # returns a hash

	if (!@attribs) #If nothing is passed to this method, print all the info for the config
   {
      foreach my $key ( keys(%$r) )
      {
         print "$key: $$r{$key}\n ";
      }
   }
   else
   {
      foreach my $key ( @attribs )
      {
         push( @myattribs,$$r{$key});
      }
      return ( @myattribs);
   }
}	


=head2 LiveLink

This method allows you to create a LiveLink URL to a library configuration. Responds with a livelink URL

=head3 Arguments

=over 4

=item * config Name

=back

=cut

sub LiveLink
{
	my($self) = shift;
	my($configName) = shift;
	$self->{'LiveLink'} = 
		$self->{'soap'}->LiveLink( $self->{'auth_header'}, 
		SOAP::Data->name('configName' => $configName)->type('s:string'));

	if ($self->{'LiveLink'}->fault){ $self->{'LASTERROR'} = $self->{'LiveLink'}->fault }
	my($r) = $self->{'LiveLink'}->result;
	return $r;
}

=head2 MachinePerformAction

This method performs one of the following machine actions as indicated by the action identifier:

=over 4

=item 1  Power on. Turns on a machine.

=item 2  Power off. Turns off a machine. Nothing is saved.

=item 3  Suspend. Freezes a machine CPU and state.

=item 4  Resume. Resumes a suspended machine.

=item 5  Reset. Reboots a machine.

=item 6  Snapshot. Save a machine state at a specific point in time.

=item 7  Revert. Returns a machine to a snapshot state.

=item 8  Shutdown. Shuts down a machine before turning off.

=back

=head3 Arguments

=over 4

=item * Action (use numeral from list aboive)

=item * Machine ID

=back

=cut

sub MachinePerformAction
{

	my($self) = shift;
   	my($configID) = shift;
   	# Actions: 1-Pwr On, 2-Pwr off, 3-Suspend, 4-Resume, 5-Reset, 6-Snapshot , 7-Revert, 8-Shutdown
   	my($action) = shift;
   	$self->{'MachinePerformAction'} = 
		$self->{'soap'}->MachinePerformAction( $self->{'auth_header'}, 
		SOAP::Data->name('machineId' => $configID )->type('s:int'),
        SOAP::Data->name('action' => $action )->type('s:int') );

	if ( $self->{'MachinePerformAction'}->fault ){ $self->{'LASTERROR'} = $self->{'MachinePerformAction'}->fault }
}

=head3 getLastSOAPError

Returns last error reported by SOAP service.

=cut

sub getLastSOAPError
{
	my($self) = shift;
	if ( $self->{'LASTERROR'} )
	{
		return join(': ', 'LabManager SOAP error', 
			$self->{'LASTERROR'}->faultcode, 
			$self->{'LASTERROR'}->faultstring, 
			$self->{'LASTERROR'}->faultdetail
		) . "\n";
	}
}




return(1);


=head1 AUTHOR

David F. Kinder, Jr, dkinder@davidkinder.net

=head1 DEPENDENCIES

SOAP::Lite;

=head1 SEE ALSO

VMWare Labamanger L<http://www.vmware.com/products/labmanager/>
VMWare Labmanager SOAP API Guide http://www.vmware.com/pdf/lm40_soap_api_guide.pdf
VMWare Lab Manager: Automated Reconfiguration of Transiently Used Infrastructure http://www.vmware.com/files/pdf/lm_whitepaper.pdf

=cut
