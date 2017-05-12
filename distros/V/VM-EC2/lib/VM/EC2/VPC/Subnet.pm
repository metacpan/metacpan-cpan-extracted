package VM::EC2::VPC::Subnet;

=head1 NAME

VM::EC2::VPC::Subnet -- A VPC subnet

=head1 SYNOPSIS

 use VM::EC2;
 my $ec2     = VM::EC2->new(...);
 my $vpc     = $ec2->create_vpc('10.0.0.0/16');
 my $subnet  = $vpc->create_subnet('10.0.0.0/24')  or die $vpc->error_str;
 @subnets    = $ec2->describe_subnets;
 
 for my $sn (@subnets) {
    print $sn->subnetId,"\n",
          $sn->state,"\n",
          $sn->vpcId,"\n",
          $sn->cidrBlock,"\n",
          $sn->availableIpAddressCount,"\n",
          $sn->availabilityZone,"\n";
 }

=head1 DESCRIPTION

This object supports the EC2 Virtual Private Cloud subnet
interface. Please see L<VM::EC2::Generic> for methods shared by all
VM::EC2 objects.

=head1 METHODS

These object methods are supported:
 
 subnetId   -- the ID of the subnet
 state      -- The current state of the subnet, either "pending" or "available"
 vpcId      -- The ID of the VPC the subnet is in.
 cidrBlock  -- The CIDR block assigned to the subnet.
 availableIpAddressCount -- The number of unused IP addresses in the subnet.
 availableZone -- This subnet's availability zone.
 defaultForAz  -- Indicates if this is the default subnet for the Availability Zone
 mapPublicIpOnLaunch -- Indicates if instances launched in this subnet automatically receive a
                        public IP address

This class supports the VM::EC2 tagging interface. See
L<VM::EC2::Generic> for information.

In addition, this object supports the following convenience methods:

 vpc()                -- Return the associated VM::EC2::VPC object.
 zone()               -- Return the associated VM::EC2::AvailabilityZone object.
 refresh()            -- Refreshes the object from its current state in EC2.
 current_state()      -- Refreshes the object and returns its current state.
 create_route_table() -- Create a new route table, associates it with this subnet, and
                         returns the corresponding VM::EC2::VPC::RouteTable
                         object.
 associate_route_table($table)
                      -- Associates a route table with this subnet, returning true if
                         sucessful.
 disassociate_route_table($table)
                      -- Removes the association of a route table with this subnet. Produces
                         a fatal error if $table is not associated with the subnet. Returns true
                         on success.
 associate_network_acl($network_acl_id)
                      -- Associates a network ACL with this subnet, returning the new
                         association ID on success.
 disassociate_network_acl()
                      -- Removes the association of a network ACL with this subnet. The subnet
                         will then be associated with the default network ACL.  Returns the
                         the association ID.

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as the
subnet ID.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2012 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use Carp 'croak';
use base 'VM::EC2::Generic';

sub valid_fields {
    my $self  = shift;
    return qw(subnetId state vpcId cidrBlock availableIpAddressCount
              availabilityZone defaultForAz mapPublicIpOnLaunch);
}

sub primary_id { shift->subnetId }

sub vpc {
    my $self = shift;
    return $self->aws->describe_vpcs($self->vpcId);
}

sub zone {
    my $self = shift;
    return $self->aws->describe_availability_zones($self->availabilityZone);
}

sub refresh {
    my $self = shift;
    my $i   = shift;
    local $self->aws->{raise_error} = 1;
    ($i) = $self->aws->describe_subnets($self->subnetId) unless $i;
    %$self  = %$i if $i;
    return defined $i;
}

sub current_state {
    my $self = shift;
    $self->refresh;
    $self->state;
}

sub associate_route_table {
    my $self = shift;
    my $rt   = shift or croak "usage: associate_route_table(\$route_table_id)";
    return $self->aws->associate_route_table(-subnet_id      => $self->subnetId,
					     -route_table_id => $rt);
}

sub disassociate_route_table {
    my $self = shift;
    my $rt   = shift or croak "usage: disassociate_route_table(\$route_table_id)";
    $rt      = $self->aws->describe_route_tables($rt) unless ref $rt;
    my ($association) = grep {$_->subnetId eq $self->subnetId} $rt->associations;
    $association or croak "$rt is not associated with this subnet";
    return $self->aws->disassociate_route_table($association);
}

sub create_route_table {
    my $self = shift;
    my $vpc  = $self->vpcId;
    my $rt   = $self->aws->create_route_table($vpc) or return;
    $self->associate_route_table($rt->routeTableId) or return;
    return $rt
}

sub disassociate_network_acl {
    my $self = shift;
    my $acl = $self->aws->describe_network_acls(-filter=>{ 'association.subnet-id' => $self->subnetId});
    if ($acl->default) {
        print "disassociate_network_acl():  Cannot disassociate subnet from default ACL";
        return;
    }
    my $default_acl = $self->aws->describe_network_acls(-filter=>{ 'default' => 'true', 'vpc-id' => $self->vpcId})
        or croak "disassociate_network_acl(): Cannot determine default ACL";
    return $self->associate_network_acl($default_acl->networkAclId);
}

sub associate_network_acl {
    my $self = shift;
    my $network_acl_id = shift or croak "usage: associate_network_acl(\$network_acl_id)";
    my $acl = $self->aws->describe_network_acls(-filter=>{ 'association.subnet-id' => $self->subnetId})
        or croak "associate_network_acl():  Cannot determine current ACL";
    my ($association) = grep { $_->subnetId eq $self->subnetId } $acl->associations;
    my $association_id = $association->networkAclAssociationId;
    return $self->aws->replace_network_acl_association(-association_id=>$association_id,-network_acl_id=>$network_acl_id);
}

sub defaultForAz {
    my $self = shift;
    my $default = $self->SUPER::defaultForAz;
    return $default eq 'true';
}

sub mapPublicIpOnLaunch {
    my $self = shift;
    my $map_ip = $self->SUPER::mapPublicIpOnLaunch;
    return $map_ip eq 'true';
}

1;

