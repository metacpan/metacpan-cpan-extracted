package Tuxedo::Admin;

our $VERSION = '0.08';

use Carp;
use strict;
use Tuxedo::Admin::ud32;
use Tuxedo::Admin::ExportedResource;
use Tuxedo::Admin::Group;
use Tuxedo::Admin::LocalAccessPoint;
use Tuxedo::Admin::ImportedResource;
use Tuxedo::Admin::Resources;
use Tuxedo::Admin::RemoteAccessPoint;
use Tuxedo::Admin::Server;
use Tuxedo::Admin::Service;
use Tuxedo::Admin::TDomain;
use Data::Dumper;

sub new
{
  my $pkg = shift;
  my $self = { @_ };

  $self->{'TUXDIR'}    = $ENV{'TUXDIR'}    if exists $ENV{'TUXDIR'};
  $self->{'TUXCONFIG'} = $ENV{'TUXCONFIG'} if exists $ENV{'TUXCONFIG'};
  $self->{'BDMCONFIG'} = $ENV{'BDMCONFIG'} if exists $ENV{'BDMCONFIG'};
  $self->{'APP_PW'}    = $ENV{'APP_PW'}    if exists $ENV{'APP_PW'};

  croak("Missing TUXDIR parameter!")    unless exists $self->{'TUXDIR'};
  croak("Missing TUXCONFIG parameter!") unless exists $self->{'TUXCONFIG'};
  croak("Missing BDMCONFIG parameter!") unless exists $self->{'BDMCONFIG'};

  $self->{client} = 
    new Tuxedo::Admin::ud32
      (
        'TUXDIR'    => $self->{'TUXDIR'},
        'TUXCONFIG' => $self->{'TUXCONFIG'},
        'BDMCONFIG' => $self->{'BDMCONFIG'},
        'APP_PW'    => $self->{'APP_PW'}
      );

  bless($self, $pkg);

  return $self;
}

sub _tmib_get
{
  my ($self, $input_buffer) = @_;
  my (%buffer, $field, $occurrence, $error, %output_buffer);
  $input_buffer->{'TA_OPERATION'} = [ 'GET' ];
  do
  {
    ($error, %buffer) = $self->{client}->tpcall('.TMIB', $input_buffer);
    if ($buffer{'TA_OCCURS'}[0] ne '0')
    {
      foreach $field (keys %buffer)
      {
        foreach $occurrence (@{ $buffer{$field} })
        {
          if (exists $output_buffer{$field})
          {
            push @{ $output_buffer{$field} }, $occurrence;
          }
          else
          {
            $output_buffer{$field}[0] = $occurrence;
          }
        }
      }
    }
    $input_buffer->{'TA_CURSOR'}[0]    = $buffer{'TA_CURSOR'}[0];
    $input_buffer->{'TA_OPERATION'}[0] = 'GETNEXT';
  } 
  while (exists $buffer{'TA_MORE'} and ($buffer{'TA_MORE'}[0] ne '0'));
  return ($error, %output_buffer);
}

sub _tmib_set
{
  my ($self, $input_buffer) = @_;
  my ($error, %output_buffer);
  $input_buffer->{'TA_OPERATION'} = [ 'SET' ];
  ($error, %output_buffer) = $self->{client}->tpcall('.TMIB', $input_buffer);
  return ($error, %output_buffer);
}

sub status
{
  my $self = shift;
  return $self->{client}->status();
}

sub print_status
{
  my $self = shift;
  my $filehandle = shift;
  if (defined $filehandle)
  {
    print $filehandle $self->status(), "\n";
  }
  else
  {
    print STDOUT $self->status(), "\n";
  }
}

sub resources
{
  my $self = shift;

  my (%input_buffer, $error, %output_buffer);
  my ($field, $methodname, %info, $resources);

  $input_buffer{'TA_CLASS'}     = [ 'T_DOMAIN' ];
  $input_buffer{'TA_FLAGS'}     = [ '65536' ]; # MIB_LOCAL

  ($error, %output_buffer) = $self->_tmib_get(\%input_buffer);

  delete $output_buffer{'TA_OCCURS'};
  delete $output_buffer{'TA_ERROR'};
  delete $output_buffer{'TA_MORE'};
  delete $output_buffer{'TA_CLASS'};
  delete $output_buffer{'TA_STATUS'};

  foreach $field (keys %output_buffer)
  {
    $methodname = $field;
    $methodname =~ s/^TA_//;
    $methodname =~ tr/A-Z/a-z/;
    $info{$methodname} = $output_buffer{$field}[0];
  }

  $resources = new Tuxedo::Admin::Resources($self, %info);
  return $resources;
}

sub server
{
  croak "Invalid parameters" unless (@_ == 3);
  my ($self, $svrgrp, $svrid) = @_;
  return new Tuxedo::Admin::Server($self, $svrgrp, $svrid);
}

sub server_list
{
  my $self = shift;

  my (%input_buffer, $error, %output_buffer, $filter);
  my ($server, $methodname, %info, @servers);
  my ($i, $count, $field);

  # Add filter fields
  if (@_ != 0)
  {
    my $filter = shift;
    #print Dumper($filter);
    croak "Filter must be a _reference_ to a hash" unless ref $filter;
    foreach $methodname (keys %{ $filter })
    {
      $field = "ta_$methodname";
      $field =~ tr/a-z/A-Z/;
      $input_buffer{$field} = [ $filter->{$methodname} ];
    }
  }

  $input_buffer{'TA_CLASS'}     = [ 'T_SERVER' ];
  $input_buffer{'TA_FLAGS'}     = [ '65536' ]; # MIB_LOCAL
  ($error, %output_buffer) = $self->_tmib_get(\%input_buffer);
  croak($self->status() . "\n") if ($error < 0);

  $count = $output_buffer{'TA_OCCURS'}[0];

  delete $output_buffer{'TA_OCCURS'};
  delete $output_buffer{'TA_ERROR'};
  delete $output_buffer{'TA_MORE'};
  delete $output_buffer{'TA_CLASS'};
  delete $output_buffer{'TA_STATUS'};

  for ($i=0;$i<$count;$i++)
  {
    $server = new Tuxedo::Admin::Server(
                $self, 
                $output_buffer{TA_SRVGRP}[$i],
                $output_buffer{TA_SRVID}[$i]
              );
    $servers[$i] = $server;
  }
  return @servers;
}

sub group
{
  croak "Invalid parameters" unless (@_ == 2);
  my ($self, $svrgrp) = @_;
  return new Tuxedo::Admin::Group($self, $svrgrp);
}

sub group_list
{
  my $self = shift;
  my (%input_buffer, $error, %output_buffer);
  my ($group, $methodname, %info, @groups);
  my ($i, $count, $field);

  # Add filter fields
  if (@_ != 0)
  {
    my $filter = shift;
    croak "Filter must be a _reference_ to a hash" unless ref $filter;
    foreach $methodname (keys %{ $filter })
    {
      $field = "ta_$methodname";
      $field =~ tr/a-z/A-Z/;
      $input_buffer{$field} = [ $filter->{$methodname} ];
    }
  }

  $input_buffer{'TA_CLASS'} = [ 'T_GROUP' ];
  ($error, %output_buffer) = $self->_tmib_get(\%input_buffer);
  croak($self->status() . "\n") if ($error < 0);

  $count = $output_buffer{'TA_OCCURS'}[0];

  delete $output_buffer{'TA_OCCURS'};
  delete $output_buffer{'TA_ERROR'};
  delete $output_buffer{'TA_MORE'};
  delete $output_buffer{'TA_CLASS'};
  delete $output_buffer{'TA_STATUS'};

  for ($i=0;$i<$count;$i++)
  {
    $group = new Tuxedo::Admin::Group(
               $self, 
               $output_buffer{TA_SRVGRP}[$i]
             );
    $groups[$i] = $group;
  }
  return @groups;
}

sub service
{
  croak "Invalid parameters" unless (@_ == 3);
  my ($self, $servicename, $svrgrp) = @_;
  return new Tuxedo::Admin::Service($self, $servicename, $svrgrp);
}

sub service_list
{
  my $self = shift;
  my (%input_buffer, $error, %output_buffer);
  my ($service, $methodname, %info, @services);
  my ($i, $count, $field);

  # Add filter fields
  if (@_ != 0)
  {
    my $filter = shift;
    croak "Filter must be a _reference_ to a hash" unless ref $filter;
    foreach $methodname (keys %{ $filter })
    {
      $field = "ta_$methodname";
      $field =~ tr/a-z/A-Z/;
      $input_buffer{$field} = [ $filter->{$methodname} ];
    }
  }

  #%input_buffer = $_[0]->fields() if (@_ == 1);
  $input_buffer{'TA_CLASS'} = [ 'T_SVCGRP' ];
  ($error, %output_buffer) = $self->_tmib_get(\%input_buffer);
  croak($self->status() . "\n") if ($error < 0);

  $count = $output_buffer{'TA_OCCURS'}[0];

  delete $output_buffer{'TA_OCCURS'};
  delete $output_buffer{'TA_ERROR'};
  delete $output_buffer{'TA_MORE'};
  delete $output_buffer{'TA_CLASS'};
  delete $output_buffer{'TA_STATUS'};

  for ($i=0;$i<$count;$i++)
  {
    $service = new Tuxedo::Admin::Service(
                 $self, 
                 $output_buffer{TA_SERVICENAME}[$i],
                 $output_buffer{TA_SRVGRP}[$i]
               );
    $services[$i] = $service;
  }
  return @services;
}

sub local_access_point
{
  croak "Invalid parameters" unless (@_ == 2);
  my ($self, $access_point) = @_;
  return new Tuxedo::Admin::LocalAccessPoint($self, $access_point);
}

sub local_access_point_list
{
  my $self = shift;
  my (%input_buffer, $error, %output_buffer);
  my ($local_access_point, $methodname, %info, @local_access_points);
  my ($i, $count, $field);

  # Add filter fields
  if (@_ != 0)
  {
    my $filter = shift;
    croak "Filter must be a _reference_ to a hash" unless ref $filter;
    foreach $methodname (keys %{ $filter })
    {
      $field = "ta_$methodname";
      $field =~ tr/a-z/A-Z/;
      $input_buffer{$field} = [ $filter->{$methodname} ];
    }
  }

  $input_buffer{'TA_CLASS'} = [ 'T_DM_LOCAL' ];
  ($error, %output_buffer) = $self->_tmib_get(\%input_buffer);
  croak($self->status() . "\n") if ($error < 0);

  $count = $output_buffer{'TA_OCCURS'}[0];

  delete $output_buffer{'TA_OCCURS'};
  delete $output_buffer{'TA_ERROR'};
  delete $output_buffer{'TA_MORE'};
  delete $output_buffer{'TA_CLASS'};
  delete $output_buffer{'TA_STATUS'};

  for ($i=0;$i<$count;$i++)
  {
    $local_access_point = new Tuxedo::Admin::LocalAccessPoint(
                            $self, 
                            $output_buffer{TA_DMACCESSPOINT}[$i]
                          );
    $local_access_points[$i] = $local_access_point;
  }
  return @local_access_points;
}

sub remote_access_point
{
  croak "Invalid parameters" unless (@_ == 2);
  my ($self, $access_point_name) = @_;
  return new Tuxedo::Admin::RemoteAccessPoint($self, $access_point_name);
}

sub remote_access_point_list
{
  my $self = shift;
  my (%input_buffer, $error, %output_buffer);
  my ($remote_access_point, $methodname, %info, @remote_access_points);
  my ($i, $count, $field);

  # Add filter fields
  if (@_ != 0)
  {
    my $filter = shift;
    croak "Filter must be a _reference_ to a hash" unless ref $filter;
    foreach $methodname (keys %{ $filter })
    {
      $field = "ta_$methodname";
      $field =~ tr/a-z/A-Z/;
      $input_buffer{$field} = [ $filter->{$methodname} ];
    }
  }

  $input_buffer{'TA_CLASS'} = [ 'T_DM_REMOTE' ];
  ($error, %output_buffer) = $self->_tmib_get(\%input_buffer);
  croak($self->status() . "\n") if ($error < 0);

  $count = $output_buffer{'TA_OCCURS'}[0];

  delete $output_buffer{'TA_OCCURS'};
  delete $output_buffer{'TA_ERROR'};
  delete $output_buffer{'TA_MORE'};
  delete $output_buffer{'TA_CLASS'};
  delete $output_buffer{'TA_STATUS'};

  for ($i=0;$i<$count;$i++)
  {
    $remote_access_point = new Tuxedo::Admin::RemoteAccessPoint(
                             $self, 
                             $output_buffer{TA_DMACCESSPOINT}[$i]
                           );
    $remote_access_points[$i] = $remote_access_point;
  }
  return @remote_access_points;
}

sub tdomain
{
  croak "Invalid parameters" unless (@_ == 3);
  my ($self, $dmaccesspoint, $dmnwaddr) = @_;
  return new Tuxedo::Admin::TDomain($self, $dmaccesspoint, $dmnwaddr);
}

sub tdomain_list
{
  my $self = shift;
  my (%input_buffer, $error, %output_buffer);
  my ($tdomain, $methodname, %info, @tdomains);
  my ($i, $count, $field);

  # Add filter fields
  if (@_ != 0)
  {
    my $filter = shift;
    croak "Filter must be a _reference_ to a hash" unless ref $filter;
    foreach $methodname (keys %{ $filter })
    {
      $field = "ta_$methodname";
      $field =~ tr/a-z/A-Z/;
      $input_buffer{$field} = [ $filter->{$methodname} ];
    }
  }

  $input_buffer{'TA_CLASS'} = [ 'T_DM_TDOMAIN' ];
  ($error, %output_buffer) = $self->_tmib_get(\%input_buffer);
  croak($self->status() . "\n") if ($error < 0);

  $count = $output_buffer{'TA_OCCURS'}[0];

  delete $output_buffer{'TA_OCCURS'};
  delete $output_buffer{'TA_ERROR'};
  delete $output_buffer{'TA_MORE'};
  delete $output_buffer{'TA_CLASS'};
  delete $output_buffer{'TA_STATUS'};

  for ($i=0;$i<$count;$i++)
  {
    $tdomain = new Tuxedo::Admin::TDomain(
                             $self, 
                             $output_buffer{TA_DMACCESSPOINT}[$i],
                             $output_buffer{TA_DMNWADDR}[$i]
                           );
    $tdomains[$i] = $tdomain;
  }
  return @tdomains;
}

sub exported_resource
{
  croak "Invalid parameters" unless (@_ == 2);
  my ($self, $dmresourcename) = @_;
  return new Tuxedo::Admin::ExportedResource($self, $dmresourcename);
}

sub exported_resource_list
{
  my $self = shift;
  my (%input_buffer, $error, %output_buffer);
  my ($exported_resource, $methodname, %info, @exported_resources);
  my ($i, $count, $field);

  # Add filter fields
  if (@_ != 0)
  {
    my $filter = shift;
    croak "Filter must be a _reference_ to a hash" unless ref $filter;
    foreach $methodname (keys %{ $filter })
    {
      $field = "ta_$methodname";
      $field =~ tr/a-z/A-Z/;
      $input_buffer{$field} = [ $filter->{$methodname} ];
    }
  }

  $input_buffer{'TA_CLASS'} = [ 'T_DM_EXPORT' ];
  ($error, %output_buffer) = $self->_tmib_get(\%input_buffer);
  croak($self->status() . "\n") if ($error < 0);

  $count = $output_buffer{'TA_OCCURS'}[0];

  delete $output_buffer{'TA_OCCURS'};
  delete $output_buffer{'TA_ERROR'};
  delete $output_buffer{'TA_MORE'};
  delete $output_buffer{'TA_CLASS'};
  delete $output_buffer{'TA_STATUS'};

  for ($i=0;$i<$count;$i++)
  {
    $exported_resource = new Tuxedo::Admin::ExportedResource(
                             $self, 
                             $output_buffer{TA_DMRESOURCENAME}[$i]
                           );
    $exported_resources[$i] = $exported_resource;
  }
  return @exported_resources;
}

sub imported_resource
{
  croak "Invalid parameters" unless (@_ == 2);
  my ($self, $dmresourcename) = @_;
  return new Tuxedo::Admin::ImportedResource($self, $dmresourcename);
}

sub imported_resource_list
{
  my $self = shift;
  my (%input_buffer, $error, %output_buffer);
  my ($imported_resource, $methodname, %info, @imported_resources);
  my ($i, $count, $field);

  # Add filter fields
  if (@_ != 0)
  {
    my $filter = shift;
    croak "Filter must be a _reference_ to a hash" unless ref $filter;
    foreach $methodname (keys %{ $filter })
    {
      $field = "ta_$methodname";
      $field =~ tr/a-z/A-Z/;
      $input_buffer{$field} = [ $filter->{$methodname} ];
    }
  }

  $input_buffer{'TA_CLASS'} = [ 'T_DM_IMPORT' ];
  ($error, %output_buffer) = $self->_tmib_get(\%input_buffer);
  croak($self->status() . "\n") if ($error < 0);

  $count = $output_buffer{'TA_OCCURS'}[0];

  delete $output_buffer{'TA_OCCURS'};
  delete $output_buffer{'TA_ERROR'};
  delete $output_buffer{'TA_MORE'};
  delete $output_buffer{'TA_CLASS'};
  delete $output_buffer{'TA_STATUS'};

  for ($i=0;$i<$count;$i++)
  {
    $imported_resource = new Tuxedo::Admin::ImportedResource(
                             $self, 
                             $output_buffer{TA_DMRESOURCENAME}[$i]
                           );
    $imported_resources[$i] = $imported_resource;
  }
  return @imported_resources;
}

sub debug
{
  my $self = shift;
  $self->{client}->debug($_[0]) if (@_ == 1);
  return $self->{client}->debug();
}

=pod

Tuxedo::Admin - Runtime Tuxedo administration

=head1 SYNOPSIS

  use Tuxedo::Admin;

  $admin = new Tuxedo::Admin(
             'TUXDIR'    => '/opt/bea/tuxedo8.1',
             'TUXCONFIG' => '/home/keith/runtime/TUXCONFIG',
             'BDMCONFIG' => '/home/keith/runtime/BDMCONFIG'
           );

  foreach $server ($admin->server_list())
  {
    print server->servername(), "\n";
  }

=head1 DESCRIPTION

This module aims to make runtime administration of a Tuxedo environment
simpler and less error-prone than the usual method of navigating the tmadmin,
dmadmin and qmadmin menus or writing multiple adhoc ud32 scripts to make TMIB
calls.

It provides a simple object-oriented Perl interface to the Tuxedo MIBs
allowing the caller to query, add or update the various components of the
Tuxedo environment, such as servers, groups, access points etc.

=head2 INITIALISATION

Certain environment variables need to be set in order to access a Tuxedo
environment.  These are:

  TUXDIR
  TUXCONFIG
  BDMCONFIG
  APP_PW

These can either be set in the environment itself or they can be passed as
parameters to the Tuxedo::Admin constructor.  (Note that APP_PW need only be
set if application passwords are being used.)

  $admin = new Tuxedo::Admin(
             'TUXDIR'    => '/opt/bea/tuxedo8.1',
             'TUXCONFIG' => '/home/keith/runtime/TUXCONFIG',
             'BDMCONFIG' => '/home/keith/runtime/BDMCONFIG'
           );

or just:

  $admin = new Tuxedo::Admin;

if the required variables are set in the environment.

=head1 METHODS

=head2 resources

Retrieves the resource settings for the current Tuxedo application.

  $resources = $admin->resources();

where $resources is a reference to a Tuxedo::Admin::Resources object.

=head2 server

Retrieves information about a specific server instance.

  $server = $admin->server($group_name, $server_id);

where $group_name is the name of the group the server is in and $server_id is
the server's identifier in this server group.  Together these parameters
uniquely identify a server.  $server is a reference to a Tuxedo::Admin::Server
object.

=head2 server_list

Retrieves a list of server instances.

  @servers = $admin->server_list(\%filter)

where %filter is an optional reference to a hash that specifies attributes
that each server instance in the returned list must have and @servers is a
list of references to Tuxedo::Admin::Server objects that match the filter.

For example:

  @servers = $admin->server_list( { 'servername' => 'GWTDOMAIN', 
                                    'restart'    => 'Y' } );

=head2 group

Retrieves information about a specific group.

  $group = $admin->group($group_name);

where $group_name is the name of the group and $group is a reference to a
Tuxedo::Admin::Group object.

=head2 group_list

Retrieves a list of groups.

  @groups = $admin->group_list(\%filter);

where %filter is an optional reference to a hash that specifies attributes
that each group in the returned list must have and @groups is a list of
references to Tuxedo::Admin::Group objects that match the filter.

=head2 service

Retrieves information about a specific service.

  $service = $admin->service($service_name, $group_name);

where $service_name is the name of the service and $group_name is the name of
the group that the server that advertised this service is in.  $service is a
reference to a Tuxedo::Admin::Service object.

=head2 service_list

Retrieves a list of services.

  @services = $admin->service_list(\%filter);

where %filter is an optional reference to a hash that specifies attributes
that each service in the returned list must have and @services is a list of
references to Tuxedo::Admin::Service objects that match the filter.

=head2 local_access_point

Retrieves information about a specific local access point.

  $local_access_point = 
    $admin->local_access_point($access_point_name,
                               $access_point_id,
                               $group_name);

where $access_point_name is the local name of the access point,
$access_point_id is the external identifier for the access point and
$group_name is the name of the server group to which the local access point
server instances belong.  These parameters uniquely identify a local access
point.  $local_access_point is a reference to a
Tuxedo::Admin::LocalAccessPoint object.

=head2 local_access_point_list

Retrieves a list of local access points.

  @local_access_points = $admin->local_access_point_list(\%filter);

where %filter is an optional reference to a hash that specifies attributes
that each local access point in the returned list must have and
@local_access_points is a list of references to
Tuxedo::Admin::LocalAccessPoint objects that match the filter.

=head2 remote_access_point

Retrieves information about a specific remote access point.

  $remote_access_point = 
    $admin->remote_access_point($access_point_name, $access_point_id);

where $access_point_name is the local name for the remote access point and
$access_point_id is the external identifier for the remote access point.
These parameters uniquely identify a remote access point.
$remote_access_point is a reference to a Tuxedo::Admin::RemoteAccessPoint
object.

=head2 remote_access_point_list

Retrieves a list of remote access points.

  @remote_access_points = $admin->remote_access_point_list(\%filter);

where %filter is an optional reference to a hash that specifies attributes
that each remote access point in the returned list must have and
@remote_access_points is a list of references to
Tuxedo::Admin::RemoteAccessPoint objects that match the filter.

=head2 tdomain

Retrieves the TDomain configuration for a specific access point.

  $tdomain = $admin->tdomain($access_point_name, $network_address);

where $access_point_name is the local name for the access point that this
TDomain configuration is for and $network_address is the network address (host
and port) for this access point.  $tdomain is a reference to a
Tuxedo::Admin::TDomain object.

=head2 tdomain_list

Retrieves a list of TDomain configurations.

  @tdomains = $admin->tdomain_list(\%filter);

where %filter is an optional reference to a hash that specifies attributes
that each TDomain configuration in the returned list must have and @tdomains
is a list of references to Tuxedo::Admin::TDomain objects that match the
filter.

=head2 imported_resource

Retrieves information about a specific imported resource.

  $imported_resource = 
    $admin->imported_resource($resource_name);

where $resource_name is the name of the imported resource.  $imported_resource
is a reference to a Tuxedo::Admin::ImportedResource object.

=head2 imported_resource_list

Retrieves a list of imported resources.

  @imported_resources = $admin->imported_resource_list(\%filter);

where %filter is an optional reference to a hash that specifies attributes
that each imported resource in the returned list must have and
@imported_resources is a list of references to Tuxedo::Admin::ImportedResource
objects that match the filter.

=head2 exported_resource

Retrieves information about a specific exported resource.

  $exported_resource = $admin->exported_resource($resource_name);

where $resource_name is the name of the exported resource.  $exported_resource
is a reference to a Tuxedo::Admin::ExportedResource object.

=head2 exported_resource_list

Retrieves a list of exported resources.

  @exported_resources = $admin->exported_resource_list(\%filter);

where %filter is an optional reference to a hash that specifies attributes
that each exported resource in the returned list must have and
@exported_resources is a list of references to Tuxedo::Admin::ExportedResource
objects that match the filter.

=head2 status

Returns a description of the status of the last call that changed the current
Tuxedo application.

  $status = $admin->status();

=head2 print_status

Prints a description of the status of the last call that changed the current
Tuxedo application to the given file handle, or to STDOUT if no file handle is
given.

  $admin->print_status(*STDERR);

  $admin->print_status();

=cut

1;

