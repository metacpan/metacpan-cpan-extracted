package VMware::LabManager;

use warnings;
use strict;

use Time::HiRes qw(time);    #used to generate unique confignames.

=head1 NAME

VMware::LabManager - Perl module to provide basic VMware Lab Manager operations.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module provides an encapsulation of VMware Lab Manager SOAP API in 
convenient API format. Basic functionality like deploying & deleting a library 
config to & from the workspace are provided. 

A little code snippet to get you started:

    use VMware::LabManager;
    use Data::Dumper;
    
    #instantiate the LM object
    my $lm = VMware::LabManager->new('username','passwd','labManager hostname', 'org');
    
    #or if you want the XML messages dumped (i.e. verbose), pass the debug option:
    my $lm = VMware::LabManager->new('username','passwd','labManager hostname', 'org', 'debug');
    
    #deploy_config returns the config ID of the config that is deployed
    my $configID = $lm->deploy_config('my_library_config_name');
    print $configID;
    
    #get all the machines in the deployed config
    my $machineArray = $lm->get_machines($configID);
    print Dumper($machineArray);
    
    #delete the config once you are done.
    $action = $lm->delete_config($configID);
    print $action

=head1 DESCRIPTION

This module does not provide a one-to-one mapping of the Lab Manager SOAP API,
but rather it provides an API wrapper, which combines certain SOAP calls as a
meaningful single operation. Thus this module is heavily tailored for automation
purposes. But, it should also cater to the broader audience as it still does 
provide overall functionality that might be required.

Using this module, you can checkout a config & deploy it in one single method call, 
similarly undeploy & delete in a single method call. This module also provides a 
method to get the list of all machines (and their details) that a deployed 
configuration has. Apart from that the SOAP object & auth header methods are 
exposed; So if need be, they can be used to access other SOAP calls available 
through Lab Manager SOAP service. 

=head1 SUBROUTINES/METHODS

=head2 new

This function instantiates the LM object. The arguments in the B<required order> are:

=over 4

=item * Username - Your username for Lab Manager login.

=item * Password - Your password for Lab Manager login.

=item * Hostname - FQDN of the Lab Manager you are trying to log in.

=item * Organization - Organization to which you belong to in Lab Manager.

=back

This does not authenticate with the Lab Manager server yet. That happens when you
use one of the other methods.

=cut

sub new
{
 my $class = shift;
 my $uname = shift; # username for LM
 my $pass  = shift; # password for LM
 my $host  = shift; # LM hostname
 my $org   = shift; # LM organization name
 my $debug = shift; # enable debug, off by default

 # Set the debug option if passed to the constructor.
 if ( defined $debug && ( $debug eq 'debug' ) )
 {
  eval("use SOAP::Lite +trace => 'debug'");
 } else
 {
  eval("use SOAP::Lite");
 }

 my $self = {
              Username     => $uname,
              Password     => $pass,
              Hostname     => $host,
              Organization => $org
 };

 bless( $self, $class );
 return $self;
}

=head2 get_soap

This method is primary used internally, but there are situations where it could
be used for other SOAP methods that have not been exposed by this module. This
method returns SOAP::Lite object & sets the readable option on. You can use this
in conjunction with Authentication header, which you can get from get_auth_header()
method.

NOTE: Usage of this method outside the scope of this API is not recommended.

=cut

sub get_soap
{
 my $self = shift;
 my $soap = SOAP::Lite->on_action(
  sub {
   return "http://vmware.com/labmanager/" . $_[1];
  }
   )->default_ns('http://vmware.com/labmanager')
   ->proxy(
          'https://' . $self->{Hostname} . '/LabManager/SOAP/LabManager.asmx' );
 $soap->readable(1);
 return $soap;
}

=head2 get_auth_header

This method returns an authentication header wrapper that is needed for each
SOAP call that you make to Lab Manager. It uses the options you provided in the
new() method to build this header.

=cut

sub get_auth_header
{
 my $self = shift;
 my $auth_header = SOAP::Header->new(
                            name => 'AuthenticationHeader',
                            attr => { xmlns => "http://vmware.com/labmanager" },
                            value => {
                                       username         => $self->{Username},
                                       password         => $self->{Password},
                                       organizationname => $self->{Organization},
                            },
 );
 
 return $auth_header;
}

=head2 deploy_config

This method is tailored for automation. During automation, one primarily cares about 
deploying a library image. A single method call to encapsulate the whole set of 
operations is more deirable.

This method requires a config name (make sure it is unique in the system), which
it uses to: 

=over 4

=item * Checkout the config to your default workspace with a random name.

=item * Deploy the confignation in fenced mode.

=item * Return the unique numeric Config ID of the deployed config. 

=back

You have to use this config ID to undeploy & delete it at at later stage.

=cut

sub deploy_config
{
 my $self        = shift;
 my $config_name = shift; # library config name
 my $soap        = $self->get_soap();
 my $auth_header = $self->get_auth_header();
 my $res;

 # Get Configuration by Name
 $res = $soap->GetConfigurationByName(
                                       $auth_header,
                                       SOAP::Data->name(
                                                         'name' => $config_name
                                         )->type('s:string')
 );

#check for error ... there's more in the faultdetail hash, could use Dumper to examine it
 if ( $res->fault )
 {
  return
    join( ': ',
          'LabManager SOAP error', $res->faultcode,
          $res->faultstring,       $res->faultdetail );
 }

 # Get the id of the configuration
 my $configID = undef;

# LM API does not provide any direct way of getting the version it is running & the data structure
# returned for this method changed in v4.0. I am just lazy, change the statement below if you use older version.
# For previous versions of LM: $configID = $res->result->{'Configuration'}->{'id'};

 $configID = $res->result->{'Configuration'}[0]->{'id'};

 # Check out Configuration to workspace
 my $new_config_name = $config_name . time;
 $res = $soap->ConfigurationCheckout(
                                      $auth_header,
                                      SOAP::Data->name(
                                                  'configurationId' => $configID
                                        )->type('s:int'),
                                      SOAP::Data->name(
                                             'workspaceName' => $new_config_name
                                        )->type('s:string')
 );

 #check for error...
 if ( $res->fault )
 {
  return
    join( ': ',
          'LabManager SOAP error', $res->faultcode,
          $res->faultstring,       $res->faultdetail );
 }

 # Get the configID of the checked out config
 my $checked_out_config_ID = $res->result;

 # Deploy that config...
 $res = $soap->ConfigurationDeploy(
                             $auth_header,
                             SOAP::Data->name(
                                     'configurationId' => $checked_out_config_ID
                               )->type('s:int'),
                             SOAP::Data->name( 'isCached' => 'false' )
                               ->type('s:boolean'),
                             SOAP::Data->name( 'fenceMode' => 4 )->type('s:int')
 );

 #check for error...
 if ( $res->fault )
 {
  return
    join( ': ',
          'LabManager SOAP error', $res->faultcode,
          $res->faultstring,       $res->faultdetail )
    . "\n";
 }

 return $checked_out_config_ID;
}

=head2 get_machines

This method returns an array of all the Machines in the deployed config. For each
machine it includes mac address, name, internal IP, external IP, name & its id. 

=cut

sub get_machines
{
 my $self        = shift;
 my $config_ID   = shift; # config ID that we got when we deployed
 my $soap        = $self->get_soap();
 my $auth_header = $self->get_auth_header();
 my $res;

 #Get the list of machines in a given config
 $res = $soap->ListMachines(
  $auth_header,
  SOAP::Data->name(
                    'configurationId' => $config_ID
    )->type('s:int')
 );

 #check for error...
 if ( $res->fault )
 {
  return
    join( ': ',
          'LabManager SOAP error', $res->faultcode,
          $res->faultstring,       $res->faultdetail );
 }

 #return an array of all machines information.
 return $res->paramsall;
}

=head2 delete_config

This method performs two actions - 1)undeploy the configuation (if it is not undeployed)
and 2) delete the configuation. This method takes the config ID of the configuration
you deployed earlier using the deploy_config() method.

=cut

sub delete_config
{
 my $self        = shift;
 my $config_ID   = shift; # config ID that we got when we deployed
 my $soap        = $self->get_soap();
 my $auth_header = $self->get_auth_header();
 my $res;

 # Undeploy the configuration
 $res = $soap->ConfigurationUndeploy(
                                      $auth_header,
                                      SOAP::Data->name(
                                                 'configurationId' => $config_ID
                                        )->type('s:int')
 );

 #check for error...
 if ( $res->fault )
 {
  return
    join( ': ',
          'LabManager SOAP error', $res->faultcode,
          $res->faultstring,       $res->faultdetail );
 }

 # Delete the configuration
 $res = $soap->ConfigurationDelete(
                                    $auth_header,
                                    SOAP::Data->name(
                                                 'configurationId' => $config_ID
                                      )->type('s:int')
 );

 #check for error...
 if ( $res->fault )
 {
  return
    join( ': ',
          'LabManager SOAP error', $res->faultcode,
          $res->faultstring,       $res->faultdetail );
 }

 return 'Deleted';
}

=head1 AUTHOR

"Aditya Ivaturi", C<< <"ivaturi at gmail.com"> >>

=head1 BUGS

Please report any bugs or feature requests to C<ivaturi@gmail.com>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=VMware-LabManager>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VMware::LabManager


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=VMware-LabManager>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/VMware-LabManager>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/VMware-LabManager>

=item * Search CPAN

L<http://search.cpan.org/dist/VMware-LabManager/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 "Aditya Ivaturi".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of VMware::LabManager
