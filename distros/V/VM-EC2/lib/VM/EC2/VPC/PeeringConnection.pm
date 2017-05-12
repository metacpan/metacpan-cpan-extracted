package VM::EC2::VPC::PeeringConnection;

=head1 NAME

VM::EC2::VPC::PeeringConnection - Virtual Private Cloud Peering Connection

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2   = VM::EC2->new(...);
 my $pcx = $ec2->describe_vpc_peering_connections(-vpc_peering_connection_id=>'pcx-12345678');
 my $status = $pcx->status;

=head1 DESCRIPTION

This object represents an Amazon EC2 VPC peering connection, and is returned by
VM::EC2->describe_vpc_peering_connections(), create_vpc_peering_connection(), and
accept_vpc_peering_connection().

=head1 METHODS

These object methods are supported:

 vpcPeeringConnectionId    -- The ID of the VPC peering connection
 requesterVpcInfo          -- Information about the requester VPC
 accepterVpcInfo           -- Information about the accepter VPC
 status                    -- The status of the VPC peering connection
 expirationTime            -- The time that an unaccepted VPC peering
                              connection will expire
 tagSet                    -- Tags assigned to the resource.

The following convenience methods are provided:

 accept                    -- Accepts the peering connection request.
                              NOTE: must be in the 'pending-acceptance'
                              state to be successful

 reject                    -- Rejects the peering connection request.
                              NOTE: must be in the 'pending-acceptance'
                              state to be successful

 refresh                   -- Refreshes the object

 current_status            -- Refreshes the object and returns the
                              status.  Useful for checking status
                              after calling reject() or accept()

The object also supports the tags() method described in
L<VM::EC2::Generic>:

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
vpcPeeringConnectionId

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Tag>
L<VM::EC2::VPC>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2014 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';
use VM::EC2::VPC::PeeringConnection::VpcInfo;
use VM::EC2::VPC::PeeringConnection::StateReason;
use Carp 'croak';

sub primary_id { shift->vpcPeeringConnectionId }

sub valid_fields {
    my $self  = shift;
    return qw(vpcPeeringConnectionId requesterVpcInfo accepterVpcInfo
	      status expirationTime tagSet);
}

sub requesterVpcInfo {
    my $self = shift;
    my $info = $self->SUPER::requesterVpcInfo or return;
    return VM::EC2::VPC::PeeringConnection::VpcInfo->new($info,$self->aws);
}

sub accepterVpcInfo {
    my $self = shift;
    my $info = $self->SUPER::accepterVpcInfo or return;
    return VM::EC2::VPC::PeeringConnection::VpcInfo->new($info,$self->aws);
}

sub status {
    my $self = shift;
    my $status = $self->SUPER::status or return;
    return VM::EC2::VPC::PeeringConnection::StateReason->new($status,$self->aws);
}

sub accept {
    my $self = shift;
    return $self->aws->accept_vpc_peering_connection(-vpc_peering_connection_id => $self->vpcPeeringConnectionId);
}

sub reject {
    my $self = shift;
    return $self->aws->reject_vpc_peering_connection(-vpc_peering_connection_id => $self->vpcPeeringConnectionId);
}

sub refresh {
    my $self = shift;
    local $self->aws->{raise_error} = 1;
    my ($pcx) = $self->aws->describe_vpc_peering_connections(-vpc_peering_connection_id => $self->vpcPeeringConnectionId);
    %$self  = %$pcx if $pcx;
    return defined $pcx;
}

sub current_status {
    my $self = shift;
    my $retry = 0;
    until ($self->refresh) {
        if (++$retry > 10) {
            croak "invalid peering connection: ",$self->vpcPeeringConnectionId;
        }
        sleep 2;
    }
    return $self->status;
}

1;
