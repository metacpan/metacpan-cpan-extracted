package VM::EC2::REST::elastic_ip;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    DescribeAddresses => 'fetch_items,addressesSet,VM::EC2::ElasticAddress',
    AssociateAddress  => sub {
	my $data = shift;
	return $data->{associationId} || ($data->{return} eq 'true');
    },
    DisassociateAddress => 'boolean',
    AllocateAddress   => 'VM::EC2::ElasticAddress',
    ReleaseAddress    => 'boolean',
    );

=head1 NAME VM::EC2::REST::elastic_ip

=head1 SYNOPSIS

 use VM::EC2 ':standard';

=head1 METHODS

The methods in this section allow you to allocate elastic IP
addresses, attach them to instances, and delete them. See
L<VM::EC2::ElasticAddress>.

Implemented:
 AllocateAddress
 AssociateAddress
 DescribeAddresses
 DissociateAddress
 ReleaseAddress

Unimplemented:
 (none)

=head2 @addr = $ec2->describe_addresses(@public_ips)

=head2 @addr = $ec2->describe_addresses(-public_ip=>\@addr,-allocation_id=>\@id,-filter->\%filters)

Queries AWS for a list of elastic IP addresses already allocated to
you. All arguments are optional:

 -public_ip     -- An IP address (in dotted format) or an arrayref of
                   addresses to return information about.
 -allocation_id -- An allocation ID or arrayref of such IDs. Only 
                   applicable to VPC addresses.
 -filter        -- A hashref of tag=>value pairs to filter the response
                   on.

The list of applicable filters can be found at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeAddresses.html.

This method returns a list of L<VM::EC2::ElasticAddress>.

=cut

sub describe_addresses {
    my $self = shift;
    my %args = $self->args(-public_ip=>@_);
    my @param;
    push @param,$self->list_parm('PublicIp',\%args);
    push @param,$self->list_parm('AllocationId',\%args);
    push @param,$self->filter_parm(\%args);
    return $self->call('DescribeAddresses',@param);
}

=head2 $address_info = $ec2->allocate_address([-vpc=>1])

Request an elastic IP address. Pass -vpc=>1 to allocate a VPC elastic
address. The return object is a VM::EC2::ElasticAddress.

=cut

sub allocate_address {
    my $self = shift;
    my %args = @_;
    my @param = $args{-vpc} ? (Domain=>'vpc') : ();
    return $self->call('AllocateAddress',@param);
}

=head2 $boolean = $ec2->release_address($addr)

Release an elastic IP address. For non-VPC addresses, you may provide
either an IP address string, or a VM::EC2::ElasticAddress. For VPC
addresses, you must obtain a VM::EC2::ElasticAddress first 
(e.g. with describe_addresses) and then pass that to the method.

=cut

sub release_address {
    my $self = shift;
    my $addr = shift or croak "Usage: release_address(\$addr)";
    my @param = (PublicIp=>$addr);
    if (my $allocationId = eval {$addr->allocationId}) {
	@param = (AllocationId=>$allocationId);
    }
    return $self->call('ReleaseAddress',@param);
}

=head2 $result = $ec2->associate_address($elastic_addr => $instance_id)

Associate an elastic address with an instance id. Both arguments are
mandatory. If you are associating a VPC elastic IP address with the
instance, the result code will indicate the associationId. Otherwise
it will be a simple perl truth value ("1") if successful, undef if
false.

If this is an ordinary EC2 Elastic IP address, the first argument may
either be an ordinary string (xx.xx.xx.xx format) or a
VM::EC2::ElasticAddress object. However, if it is a VPC elastic
IP address, then the argument must be a VM::EC2::ElasticAddress
as returned by describe_addresses(). The reason for this is that the
allocationId must be retrieved from the object in order to use in the
call.

=cut

sub associate_address {
    my $self = shift;
    @_ == 2 or croak "Usage: associate_address(\$elastic_addr => \$instance_id)";
    my ($addr,$instance) = @_;

    my @param = (InstanceId=>$instance);
    push @param,eval {$addr->domain eq 'vpc'} ? (AllocationId => $addr->allocationId)
	                                      : (PublicIp     => $addr);
    return $self->call('AssociateAddress',@param);
}

=head2 $bool = $ec2->disassociate_address($elastic_addr)

Disassociate an elastic address from whatever instance it is currently
associated with, if any. The result will be true if disassociation was
successful.

If this is an ordinary EC2 Elastic IP address, the argument may
either be an ordinary string (xx.xx.xx.xx format) or a
VM::EC2::ElasticAddress object. However, if it is a VPC elastic
IP address, then the argument must be a VM::EC2::ElasticAddress
as returned by describe_addresses(). The reason for this is that the
allocationId must be retrieved from the object in order to use in the
call.


=cut

sub disassociate_address {
    my $self = shift;
    @_ == 1 or croak "Usage: disassociate_address(\$elastic_addr)";
    my $addr = shift;

    my @param = eval {$addr->domain eq 'vpc'} ? (AssociationId => $addr->associationId)
	                                      : (PublicIp      => $addr);
    return $self->call('DisassociateAddress',@param);
}

=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut


1;
