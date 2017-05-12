package VM::EC2::ELB;

=head1 NAME

VM::EC2::ELB -- Object describing an Elastic Load Balancer

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  $lb = $ec2->create_load_balancer(%args);
    or
  $lb = $ec2->describe_load_balancers(-load_balancer_name=>'my-lb');

  @zones        = $lb->AvailabilityZones;
  $created      = $lb->CreatedTime;
  $dns_name     = $lb->DNSName;
  $health_check = $lb->HealthCheck;
  @instances    = $lb->Instances;
  @list_desc    = $lb->ListenerDescriptions;
  $name         = $lb->LoadBalancerName;
  @policies_obj = $lb->Policies;
  @policies     = $lb->describe_policies(-policy_names=>'mypolicy'); 
  $scheme	= $lb->Scheme;
  $sg_name      = $lb->SourceSecurityGroup;
  $success      = $lb->create_load_balancer_listeners(%args);
  $success      = $lb->enable_availability_zones_for_load_balancer(@zones);
  @list         = $lb->register_instances_with_load_balancer(-instances => 'i-12345678');
  $state        = $lb->describe_instance_health(-instances => 'i-12345678')
  $success      = $lb->delete_load_balancer;

=head1 DESCRIPTION

This object represents an Amazon Elastic Load Balancer and is returned by
VM::EC2->describe_load_balancers() and VM::EC2->create_load_balancer(). 
In addition to methods to query the ELB's attributes, there are methods that
manage the ELB's lifecycle and properties.

=head1 METHODS

The following object methods are supported:
 
 AvailabilityZones         -- The enabled availability zones for the ELB in the
                              form of an array of L<VM::EC2::AvailabilityZone>
                              objects.
 BackendServerDescriptions -- The backend server descriptions.
 CreatedTime               -- The creation date of the ELB.
 DNSName                   -- The DNS name of the ELB.
 HealthCheck               -- The health check associated with the ELB in the
                              form of a L<VM::EC2::ELB::HealthCheck> object.
 Instances                 -- The instances that the ELB points to, in the form
                              of an array of L<VM::EC2::Instance> objects.
 ListenerDescriptions      -- An array of L<VM::EC2::ELB::ListenerDescription>
                              objects.
 LoadBalancerName          -- The name of the ELB
 Policies                  -- The policies of the ELB in the form of a
                              L<VM::EC2::ELB::Policies> object.
 Scheme                    -- Specifies the type of ELB ('internal' is for VPC
                              only.)
 SecurityGroups            -- The security groups the ELB is a member of (VPC
                              only) in the form of L<VM::EC2::SecurityGroup>
                              objects.
 SourceSecurityGroup       -- The security group that the ELB is a member of
 Subnets                   -- Provides an array of VPC subnet objects
                              (L<VM::EC2::VPC::Subnet>) that the ELB is part of.
 VPCId                     -- Provides the ID of the VPC attached to the ELB.

"Unimplemented/untested" object methods related to Route 53 (return raw data/
data structures):

 CanonicalHostedZoneName   -- The name of the Amazon Route 53 hosted zone that
                              is associated with the ELB.
 CanonicalHostedZoneNameID -- The ID of the Amazon Route 53 hosted zone name
                              that is associated with the ELB.

The following convenience methods are supported;

 active_policies           -- Returns the policies that are actively in use by
                              the ELB in the form of L<VM::EC2::ELB::PolicyDescription>
                              objects.
 all_policies              -- Returns all policies that are associated with the
                              ELB in the form of L<VM::EC2::ELB::PolicyDescription>
                              objects.
 listeners                 -- Provides the L<VM::EC2::ELB::Listener> objects
                              associated with the ELB

=head1 LIFECYCLE METHODS

=head2 $success = $elb->delete_load_balancer
=head2 $success = $elb->delete

This method deletes the ELB.  Returns true on success.

=head2 $success = $elb->create_app_cookie_stickiness_policy(-cookie_name=>$cookie_name,-policy_name=>$policy_name)

Generates a stickiness policy with sticky session lifetimes that follow that of
an application-generated cookie. This policy can be associated only with
HTTP/HTTPS listeners.  Returns true on success.

=head2 $success = $elb->create_lb_cookie_stickiness_policy(-cookie_expiration_period=>$secs,-policy_name=>$name)

Generates a stickiness policy with sticky session lifetimes controlled by the
lifetime of the browser (user-agent) or a specified expiration period. This
policy can be associated only with HTTP/HTTPS listeners.  Returns true on
success.

=head2 $success = $elb->create_load_balancer_listeners(-listeners=>\%listener_hash);
=head2 $success = $elb->create_listeners(\%listener_hash);

Creates one or more listeners on a ELB for the specified port. If a listener 
with the given port does not already exist, it will be created; otherwise, the
properties of the new listener must match the properties of the existing
listener.  Returns true on success.

The passed argument must either be a L<VM::EC2::ELB:Listener> object (or arrayref of
objects) or a hash (or arrayref of hashes) containing the following keys:

 Protocol            -- Value as one of: HTTP, HTTPS, TCP, or SSL
 LoadBalancerPort    -- Value in range 1-65535
 InstancePort        -- Value in range 1-65535
  and optionally:
 InstanceProtocol    -- Value as one of: HTTP, HTTPS, TCP, or SSL
 SSLCertificateId    -- Certificate ID from AWS IAM certificate list

=head2 $success = $elb->delete_load_balancer_listeners(-load_balancer_ports=>\@ports)
=head2 $success = $elb->delete_listeners(@ports)

Deletes listeners from the ELB for the specified port.  Returns true on
success.

=head2 @zones = $elb->disable_availability_zones_for_load_balancer(-zones=>\@zones)
=head2 @zones = $elb->disable_availability_zones(@zones)
=head2 @zones = $elb->disable_zones(@zones)

Removes the specified EC2 Availability Zones from the set of configured
Availability Zones for the ELB.  Returns a series of L<VM::EC2::AvailabilityZone>
objects now associated with the ELB.

=head2 @zones = $elb->enable_availability_zones_for_load_balancer(-zones=>\@zones)
=head2 @zones = $elb->enable_availability_zones(@zones)
=head2 @zones = $elb->enable_zones(@zones)

Adds the specified EC2 Availability Zones to the set of configured
Availability Zones for the ELB.  Returns a series of L<VM::EC2::AvailabilityZone>
objects now associated with the ELB.

=head2 @instance_ids = $elb->register_instances_with_load_balancer(-instances=>\@instance_ids)
=head2 @instance_ids = $elb->register_instances(@instance_ids)

Adds new instances to the ELB.  If the instance is in an availability zone that
is not registered with the ELB will be in the OutOfService state.  Once the zone
is added to the ELB the instance will go into the InService state. Returns an
array of instance IDs now associated with the ELB.

=head2 @instance_ids = $elb->deregister_instances_from_load_balancer(-instances=>\@instance_ids)
=head2 @instance_ids = $elb->deregister_instances(@instance_ids)

Deregisters instances from the ELB. Once the instance is deregistered, it will
stop receiving traffic from the ELB.  Returns an array of instance IDs now
associated with the ELB.

=head2 @states = $elb->describe_instance_health(-instances=>\@instance_ids)
=head2 @states = $elb->describe_instance_health(@instance_ids)

Provides the current state of the instances of the specified LoadBalancer. If no
instances are specified, the state of all the instances for the ELB is returned.
Returns an array of L<VM::EC2::ELB::InstanceState> objects.

=head2 $success = $elb->create_load_balancer_policy(-policy_name=>$name,-policy_type_name=>$type_name,-policy_attributes=>\@attrs)
=head2 $success = $elb->create_policy(-policy_name=>$name,-policy_type_name=>$type_name,-policy_attributes=>\@attrs)

Creates a new policy that contains the necessary attributes depending on the
policy type. Policies are settings that are saved for your ELB and that can be
applied to the front-end listener, or the back-end application server,
depending on your policy type.  Returns true on success.

=head2 $success = $elb->delete_load_balancer_policy(-policy_name=>$policy_name)
=head2 $success = $elb->delete_policy($policy_name)

Deletes a policy from the ELB.  The specified policy must not be enabled for any
listeners.  Returns true on success.

=head1 CONFIGURATION METHODS

=head2 $health_check = $elb->configure_health_check(-healthy_threshold=>$cnt,-interval=>$secs,-target=>$target,-timeout=>$secs,-unhealthy_threshold=>$cnt)

This method configures the health check for a particular target service.

-target must be in the format Protocol:Port[/PathToPing]:
 - Valid Protocol types are: HTTP, HTTPS, TCP, SSL
 - Port must be in range 0-65535
 - PathToPing is only applicable to HTTP or HTTPS protocol
   types and must be 1024 characters long or fewer.

 ex: HTTP:80/index.html

=head2 $success = $elb->create_policy(-policy_name=>$name,-policy_type_name=>$type_name)

Creates a new policy that contains the necessary attributes depending on the
policy type.  Returns true on success.

=head2 $success = $elb->set_load_balancer_listener_ssl_certificate(-port=>$port,-cert_id=>$cert_id)

Sets the certificate that terminates the specified listener's SSL connections.
The specified certificate replaces any prior certificate that was used on the
same ELB and port.  Returns true on success.

=head2 $success = $elb->set_load_balancer_policies_of_listener(-port=>$port,-policy_names=>\@names)
=head2 $success = $elb->set_policies_of_listener(-port=>$port,-policy_names=>\@names)

Associates, updates, or disables a policy with a listener on the ELB.  Multiple
policies may be associated with a listener.  Returns true on success.

=head2 @groups = $elb->apply_security_groups_to_load_balancer(-security_groups=>\@groups)
=head2 @groups = $elb->apply_security_groups(@groups)

Associates one or more security groups with your ELB in VPC.  The provided
security group IDs will override any currently applied security groups.
Returns a list of L<VM::EC2::SecurityGroup> objects.

=head2 @subnets = $elb->attach_load_balancer_to_subnets(-subnets=>\@subnets)
=head2 @subnets = $elb->attach_to_subnets(@subnets)

Adds one or more subnets to the set of configured subnets for the ELB.
Returns a series of L<VM::EC2::VPC::Subnet> objects corresponding to the
subnets the ELB is now attached to.

=head2 @subnets = $elb->detach_load_balancer_from_subnets(-subnets=>\@subnets)
=head2 @subnets = $elb->detach_from_subnets(@subnets)

Removes subnets from the set of configured subnets in the VPC for the ELB.
Returns a series of L<VM::EC2::VPC::Subnet> objects corresponding to the
subnets the ELB is now attached to.

=head2 $success = $elb->set_load_balancer_policies_for_backend_server(-port=>$port,-policy_names=>$names)
=head2 $success = $elb->set_policies_for_backend_server(-port=>$port,-policy_names=>$names)

Replaces the current set of policies associated with a port on which the back-
end server is listening with a new set of policies. After the policies have 
been created, they can be applied here as a list.  At this time, only the back-
end server authentication policy type can be applied to the back-end ports;
this policy type is composed of multiple public key policies.  Returns true on
success.

=head2 $success = $elb->add_tags({ Name => Value[, Name => Value,...]);
=head2 $success = $elb->add_tags(\%tags);

Adds tags to the ELB.  Up to ten tags can be applied.

=head1 INFORMATION METHODS

=head2 $state = $lb->describe_instance_health(-instances=>\@instances)
=head2 $state = $lb->describe_instance_health(@instances)
=head2 $state = $lb->describe_instance_health

Returns the current state of the instances registered with the ELB.

=head2 @policies = $lb->describe_load_balancer_policies(-policy_names=>\@names)
=head2 @policies = $lb->describe_load_balancer_policies;

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
Elastic Load Balancer Name.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::ELB::HealthCheck>
L<VM::EC2::ELB::ListenerDescription>
L<VM::EC2::ELB::BackendServerDescription>
L<VM::EC2::ELB::Policies>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2012-2014 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut


use strict;
use base 'VM::EC2::Generic';
use VM::EC2::ELB::HealthCheck;
use VM::EC2::ELB::ListenerDescription;
use VM::EC2::ELB::BackendServerDescription;
use VM::EC2::ELB::Policies;

use overload 
    '""'     => sub {
	my $self = shift;
	return $self->LoadBalancerName},
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(AvailabilityZones BackendServerDescriptions CanonicalHostedZoneName CanonicalHostedZoneNameID CreatedTime DNSName HealthCheck Instances ListenerDescriptions LoadBalancerName Policies Scheme SecurityGroups SourceSecurityGroup Subnets VPCId);
}

# object methods

sub AvailabilityZones {
    my $self = shift;
    my $zones = $self->SUPER::AvailabilityZones or return;
    return $self->aws->describe_availability_zones(@{$zones->{member}});
}

sub BackendServerDescriptions {
    my $self = shift;
    my $descs = $self->SUPER::BackendServerDescriptions or return;
    return map { VM::EC2::ELB::BackendServerDescription->new($_,$self->aws) } @{$descs->{member}};
}

sub HealthCheck {
    my $self = shift;
    my $hc = $self->SUPER::HealthCheck or return;
    return VM::EC2::ELB::HealthCheck->new($hc,$self->aws);
}

sub Instances {
    my $self = shift;
    my $instances = $self->SUPER::Instances or return;
    my @i = map { $_->{InstanceId} } @{$instances->{member}};
    return $self->aws->describe_instances(@i);
}

sub ListenerDescriptions {
    my $self = shift;
    my $listener_descs = $self->SUPER::ListenerDescriptions or return;
    return map { VM::EC2::ELB::ListenerDescription->new($_,$self->aws) } @{$listener_descs->{member}};
}

sub Policies {
    my $self = shift;
    my $policies = $self->SUPER::Policies or return;
    return VM::EC2::ELB::Policies->new($policies,$self->aws);
}

sub SecurityGroups {
    my $self = shift;
    my $sg = $self->SUPER::SecurityGroups or return;
    return $self->aws->describe_security_groups(@{$sg->{member}});
}

sub SourceSecurityGroup {
    my $self = shift; 
    my $ssg = $self->SUPER::SourceSecurityGroup or return;
    return $ssg->{OwnerAlias} . '/' . $ssg->{GroupName};
}

sub Subnets {
    my $self = shift;
    my $sn = $self->SUPER::Subnets or return;
    return $self->aws->describe_subnets(@{$sn->{member}});
}

# convenience methods

sub listeners {
    my $self = shift;
    return map { $_->Listener } $self->ListenerDescriptions;
}

sub active_policies {
    my $self = shift;
    my @policies;
    foreach ($self->ListenerDescriptions) {
	push @policies,$_->PolicyNames;
    }
    my @p = keys %{{ map { $_ => 1 } @policies }};
    return $self->aws->describe_load_balancer_policies(-load_balancer_name=>$self->LoadBalancerName,-policy_names=>\@p);
}

sub all_policies {
    my $self = shift;
    return $self->aws->describe_load_balancer_policies(-load_balancer_name=>$self->LoadBalancerName);
}

sub delete_load_balancer {
    my $self = shift;
    return $self->aws->delete_load_balancer($self->LoadBalancerName);
}

sub delete { shift->delete_load_balancer }

sub configure_health_check {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->configure_health_check(%args);
}

sub create_app_cookie_stickiness_policy {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->create_app_cookie_stickiness_policy(%args);
}

sub create_lb_cookie_stickiness_policy {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->create_lb_cookie_stickiness_policy(%args);
}

sub create_load_balancer_listeners {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->create_load_balancer_listeners(%args);
}

sub create_listeners { shift->create_load_balancer_listeners(@_) }

sub delete_load_balancer_listeners {
    my $self = shift;
    my %args = $self->args('-load_balancer_ports',@_);
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->delete_load_balancer_listeners(%args);
}

sub delete_listeners { shift->delete_load_balancer_listeners(@_) }

sub disable_availability_zones_for_load_balancer {
    my $self = shift;
    my %args = $self->args('-availability_zones',@_);
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->disable_availability_zones_for_load_balancer(%args);
}

sub disable_availability_zones { shift->disable_availability_zones_for_load_balancer(@_) }
sub disable_zones { shift->disable_availability_zones_for_load_balancer(@_) }

sub enable_availability_zones_for_load_balancer {
    my $self = shift;
    my %args = $self->args('-availability_zones',@_);
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->enable_availability_zones_for_load_balancer(%args);
}

sub enable_availability_zones { shift->enable_availability_zones_for_load_balancer(@_) }
sub enable_zones { shift->enable_availability_zones_for_load_balancer(@_) }

sub register_instances_with_load_balancer {
    my $self = shift;
    my %args = $self->args('-instances',@_);
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->register_instances_with_load_balancer(%args);
}

sub register_instances { shift->register_instances_with_load_balancer(@_) }

sub deregister_instances_from_load_balancer {
    my $self = shift;
    my %args = $self->args('-instances',@_);
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->deregister_instances_from_load_balancer(%args);
}

sub deregister_instances { shift->deregister_instances_from_load_balancer(@_) }

sub set_load_balancer_listener_ssl_certificate {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->set_load_balancer_listener_ssl_certificate(%args);
}

sub set_listener_ssl_certificate { shift->set_load_balancer_listener_ssl_certificate(@_) }
sub set_ssl_certificate { shift->set_load_balancer_listener_ssl_certificate(@_) }

sub describe_instance_health {
    my $self = shift;
    my %args = $self->args('-instances',@_);
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->describe_instance_health(%args);
}

sub create_load_balancer_policy {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->create_load_balancer_policy(%args);
}

sub create_policy { shift->create_load_balancer_policy(@_) }

sub delete_load_balancer_policy {
    my $self = shift;
    my %args = $self->args('-policy_name',@_);
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->delete_load_balancer_policy(%args);
}

sub delete_policy { shift->delete_load_balancer_policy(@_) }

sub describe_load_balancer_policies {
    my $self = shift;
    my %args = $self->args('-policy_names',@_);
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->describe_load_balancer_policies(%args);
}

sub describe_policies { shift->describe_load_balancer_policies(@_) }

sub set_load_balancer_policies_of_listener {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->set_load_balancer_policies_of_listener(%args);
}

sub set_policies_of_listener { shift->set_load_balancer_policies_of_listener(@_) }
sub set_policies { shift->set_load_balancer_policies_of_listener(@_) }

sub apply_security_groups_to_load_balancer {
    my $self = shift;
    my %args = $self->args('-security_groups',@_);
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->apply_security_groups_to_load_balancer(%args);
}

sub apply_security_groups { shift->apply_security_groups_to_load_balancer(@_) } 

sub attach_load_balancer_to_subnets {
    my $self = shift;
    my %args = $self->args('-subnets',@_);
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->attach_load_balancer_to_subnets(%args);
}

sub attach_to_subnets { shift->attach_load_balancer_to_subnets(@_) }

sub detach_load_balancer_from_subnets {
    my $self = shift;
    my %args = $self->args('-subnets',@_);
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->detach_load_balancer_from_subnets(%args);
}

sub detach_from_subnets { shift->detach_load_balancer_from_subnets(@_) }

sub set_load_balancer_policies_for_backend_server {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} = $self->LoadBalancerName;
    return $self->aws->set_load_balancer_policies_for_backend_server(%args);
}

sub set_policies_for_backend_server { shift->set_load_balancer_policies_for_backend_server(@_) }

sub args {
    my $self = shift;
    my $default_param_name = shift;
    return unless @_;
    return @_ if $_[0] =~ /^-/;
    return ($default_param_name => \@_);
}

# the following functions override Generic
sub add_tags {
    my $self = shift;
    my $tags = ref $_[0] && ref $_[0] eq 'HASH' ? shift : {@_};
    return $self->aws->add_load_balancer_tags(-load_balancer_names => $self->LoadBalancerName, -tags => $tags);
}

sub tags {
    my $self = shift;
    my $tags = $self->aws->describe_load_balancer_tags(-load_balancer_names => $self->LoadBalancerName);
    return $tags->{$self->LoadBalancerName};
}

sub delete_tags {
    my $self = shift;
    my $tags = shift;
    return $self->aws->remove_load_balancer_tags(-load_balancer_names => $self->LoadBalancerName, -tags => $tags);
}


1;
