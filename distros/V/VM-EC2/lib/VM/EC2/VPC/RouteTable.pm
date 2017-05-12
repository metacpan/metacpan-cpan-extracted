package VM::EC2::VPC::RouteTable;

=head1 NAME

VM::EC2::VPC::RouteTable -- A VPC route table

=head1 SYNOPSIS

 use VM::EC2;
 my $ec2     = VM::EC2->new(...);
 my @tables  = $ec2->describe_route_tables;
 
 for my $rt (@tables) {
    print $rt->routeTableId,"\n",
          $rt->vpcId,"\n";
    my @routes = $rt->routes;
    my @associations = $rt->associations;
 }

=head1 DESCRIPTION

This object supports the EC2 Virtual Private Cloud route table
interface, and is used to control the routing of packets within and
between subnets.

=head1 METHODS

These object methods are supported:
 
 routeTableId   -- the ID of the route table
 vpcId          -- The ID of the VPC the route table is in.
 routes         -- An array of VM::EC2::VPC::Route objects,
                   each describing a routing rule in the
                   table.
 associations   -- An array of VM::EC2::RouteTable::Association
                   objects, each describing the association 
                   between the route table and a subnet.

This class supports the VM::EC2 tagging interface. See
L<VM::EC2::Generic> for information.

In addition, this object supports the following convenience methods:

 vpc                            -- The VPC object for this route table.
 main                           -- Returns true if this is the VPC's current "main" 
                                   route table
 associate($subnet)             -- Associate the route table with a subnet ID or object.
 disassociate($subnet)          -- Disassociate the route table with a subnet ID or object.
 refresh                        -- Refreshes the object from its current state in EC2.
 create_route($dest=>$target)   -- Create a route in the route table
 delete_route($dest)            -- Delete a route in the route table
 replace_route($dest=>$target)  -- Replace a route in the route table

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as the
route table ID.

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
use VM::EC2::VPC::Route;
use VM::EC2::VPC::RouteTable::Association;

sub valid_fields {
    my $self  = shift;
    return qw(routeTableId vpcId routeSet associationSet);
}

sub primary_id { shift->routeTableId }

sub vpc {
    my $self = shift;
    return $self->aws->describe_vpcs($self->vpcId);
}

sub routes {
    my $self = shift;
    my $set  = $self->routeSet or return;
    return map {VM::EC2::VPC::Route->new($_,$self->aws)} @{$set->{item}};
}

sub main {
    my $self = shift;
    my @a    = grep {$_->main} $self->associations;
    return scalar @a;
}

sub associations {
    my $self = shift;
    my $set  = $self->associationSet or return;
    return map {VM::EC2::VPC::RouteTable::Association->new($_,$self->aws)} @{$set->{item}};
}

sub associate {
    my $self = shift;
    my $subnet = shift;
    $self->aws->associate_route_table($subnet=>$self);
}

sub disassociate {
    my $self   = shift;
    my $subnet = shift;
    my @associations = $self->associations;
    my ($ass)  = grep {$_->subnetId eq $subnet} @associations;
    return unless $ass;
    $self->aws->disassociate_route_table($ass->routeTableAssociationId);
}

sub refresh {
    my $self = shift;
    my $i   = shift;
    local $self->aws->{raise_error} = 1;
    ($i) = $self->aws->describe_subnets($self->subnetId) unless $i;
    %$self  = %$i if $i;
    return defined $i;
}

sub create_route {
    my $self = shift;
    return $self->aws->create_route($self->routeTableId, @_);
}

sub replace_route {
    my $self = shift;
    return $self->aws->replace_route($self->routeTableId, @_);
}

sub delete_route {
    my $self = shift;
    return $self->aws->delete_route($self->routeTableId, @_);
}

1;

