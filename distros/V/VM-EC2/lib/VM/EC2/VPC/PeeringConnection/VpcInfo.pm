package VM::EC2::VPC::PeeringConnection::VpcInfo;

=head1 NAME

VM::EC2::VPC::PeeringConnection::VpcInfo - Virtual Private Cloud Peering
Connection VPC Information

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2   = VM::EC2->new(...);
 my $pcx = $ec2->describe_vpc_peering_connections(-vpc_peering_connection_id=>'pcx-12345678');
 my $req_vpc = $pcx->requesterVpcInfo;
 my $acc_vpc = $pcx->accepterVpcInfo;
 print $req_vpc->vpcId,' requested to connect to ',$acc_vpc->vpcId,"\n";

=head1 DESCRIPTION

This object represents VPC Information from an Amazon EC2 VPC Peering
Connection.

=head1 METHODS

These object methods are supported:

 vpcId         -- The ID of the VPC
 ownerId       -- The AWS account ID of the VPC owner
 cidrBlock     -- The CIDR block for the VPC

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the VpcId

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
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
use Carp 'croak';

use overload '""' => sub { shift->vpcId },
    fallback => 1;

sub valid_fields {
    my $self  = shift;
    return qw(vpcId ownerId cidrBlock);
}

1;
