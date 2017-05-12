package VM::EC2::VPC::VpnGateway::Attachment;

=head1 NAME

VM::EC2::VPC::VpnGateway::Attachment -- Attachment of a vpn gateway to a VPC

=head1 SYNOPSIS

 use VM::EC2;
 my $ec2      = VM::EC2->new(...);
 my $gw = $ec2->describe_vpn_gateways('vpn-12345678');
 my @attachments = $gw->attachments;
 for my $a (@attachments) {
    print $a->vpcId,"\n",
          $a->state,"\n";
 }

=head1 DESCRIPTION

This object provides information about the attachment of a EC2 Virtual
Private Cloud internet gateway to a VPC.

=head1 METHODS

These object methods are supported:
 
 vpcId   -- the ID of the VPC
 state   -- the state of the attachment; one of "attaching", "attached",
            "detaching" and "detached"

In addition, this object supports the following convenience method:

 vpc      -- Return the VM::EC2::VPC object corresponding to the attachment.
                          check for changes in attachment state.

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as the
vpcId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::VPC>
L<VM::EC2::VPC::VpnGateway>

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
    return qw(vpcId state);
}

sub short_name { shift->vpcId }

sub vpc {
    my $self = shift;
    my $vpcId = $self->vpcId or return;
    return $self->aws->describe_vpcs($vpcId);
}

1;

