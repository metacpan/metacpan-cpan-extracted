package VM::EC2::VPC::NetworkAcl::Association;

=head1 NAME

VM::EC2::VPC::NetworkAcl::Association - The association between a network acl
and a subnet

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2      = VM::EC2->new(...);
 my $acl      = $ec2->describe_network_acls(-network_acl_id=>'acl-12345678');
 my @assoc    = $acl->associations;

 foreach my $a (@assoc) {
     print $a->networkAclAssociationId,"\n",
           $a->networkAclId,"\n",
           $a->subnetId,"\n";
 }

=head1 DESCRIPTION

This object represents an Amazon EC2 VPC network ACL association

=head1 METHODS

These object methods are supported:

 networkAclAssociationId -- An identifier representing the 
                            association between a network ACL 
                            and a subnet.
 networkAclId            -- The ID of the network ACL in the
                            association.
 subnetId                -- The ID of the subnet in the association.

The following convenience methods are supported:

 network_acl             -- A VM::EC2::VPC::NetworkAcl object

 subnet                  -- A VM::EC2::VPC::Subnet object

The object also supports the tags() method described in
L<VM::EC2::Generic>:

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
subnetId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Tag>
L<VM::EC2::VPC>
L<VM::EC2::VPC::NetworkAcl>
L<VM::EC2::VPC::Subnet>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2012 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';
use Carp 'croak';

sub primary_id    { shift->subnetId }

sub valid_fields {
    my $self  = shift;
    return qw(networkAclAssociationId networkAclId subnetId);
}

sub network_acl {
    my $self = shift;
    my $acl  = $self->networkAclId or return;
    return $self->aws->describe_network_acls($acl);
}

sub subnet {
    my $self = shift;
    my $sn   = $self->subnetId or return;
    return $self->aws->describe_subnets($sn);
}

1;

