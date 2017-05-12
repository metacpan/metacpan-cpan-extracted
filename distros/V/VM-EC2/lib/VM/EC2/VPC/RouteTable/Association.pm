package VM::EC2::VPC::RouteTable::Association;

=head1 NAME

VM::EC2::VPC::RouteTable::Association -- The association between a route table and a subnet

=head1 SYNOPSIS

 use VM::EC2;
 my $ec2     = VM::EC2->new(...);
 my $table  = $ec2->describe_route_tables('rtb-123456');
 my @associations = $table->associations;

 foreach my $a (@associations) {
       print $a->routeTableAssociationId,"\n",
             $a->routeTableId,"\n",
             $a->subnetid,"\n",
             $a->main,"\n";
}

=head1 DESCRIPTION

This object describes the association between a EC2 Virtual Private
Cloud routing table and a particular subnet. The special "main" route
table, which is assigned to newly-created subnets by default, is
designated by an association that returns a true value for the main()
method.

=head1 METHODS

These object methods are supported:
 
 routeTableAssociationId -- An identifier representing this association.
 routeTableId            -- The ID of the associated route table.
 subnetId                -- The ID of the associated subnet.
 main                    -- Returns true if the associated route table is 
                            the VPC's main table.

In addition, the following convenience methods are provided:

 route_table       -- Return the VM::EC2::VPC::RouteTable object.

 subnet            -- Return the VM::EC2::VPC::Subnet object.

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as the
routeTableAssociationId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::VPC::RouteTable>
L<VM::EC2::VPC::Subnet>

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
    return qw(routeTableAssociationId routeTableId subnetId main);
}

sub short_name { shift->routeTableAssociationId }

sub route_table {
    my $self = shift;
    my $rt   = $self->routeTableId or return;
    return $self->aws->describe_route_tables($rt);
}

sub subnet {
    my $self = shift;
    my $sn   = $self->subnetId or return;
    return $self->aws->describe_subnets($sn);
}

sub main { shift->SUPER::main eq 'true' }

1;

